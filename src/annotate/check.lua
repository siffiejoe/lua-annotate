-- cache globals and require modules
local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local table = require( "table" )
local L = require( "lpeg" )
local _VERSION = assert( _VERSION )
local pairs = assert( pairs )
local ipairs = assert( ipairs )
local type = assert( type )
local select = assert( select )
local error = assert( error )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
local tinsert = assert( table.insert )
local tconcat = assert( table.concat )
local tsort = assert( table.sort )
local loadstring = assert( loadstring or load )
local unpack = assert( unpack or table.unpack )
-- optional
local print, next, io, math = print, next, io, math


----------------------------------------------------------------------
-- The argument and return value specification can be expressed as a
-- regular language. Every regular language can be recognized by a
-- deterministic finite automaton. Below code implements classes
-- for state transitions, NFAs, and DFAs, which can be compiled into
-- Lua code for argument and/or return value checking.


-- small class for NFA/DFA transitions
local transition = {}
local transition_meta = { __index = transition }

function transition:new( from, to, fname, f )
  local tr = {
    from = from, to = to, fname = fname or "#eps#", f = f
  }
  setmetatable( tr, transition_meta )
  return tr
end

-- for sorting
function transition_meta:__lt( other )
  if self.from == other.from then
    if self.to == other.to then
      return self.f ~= other.f and self.fname < other.fname
    else
      return self.to < other.to
    end
  else
    return self.from < other.from
  end
end



-- Small class for non-deterministic finite automata (NFAs).
-- Objects are constructed such that the first state is the only
-- starting state, and the last state is the only accepting final
-- state. Also the only state without outgoing transitions is the end
-- state!
local NFA = {}
local NFA_meta = { __index = NFA }

do
  local primitive_types = {
    [ "nil" ] = true,
    [ "boolean" ] = true,
    [ "number" ] = true,
    [ "string" ] = true,
    [ "table" ] = true,
    [ "function" ] = true,
    [ "userdata" ] = true,
    [ "thread" ] = true,
  }

  -- private local function as by itself it does not correctly
  -- handle the needs_backtracking flag
  local function add_transition( fa, from, to, fname, f )
    local trs = fa.transitions
    trs[ #trs+1 ] = transition:new( from, to, fname, f )
    if fname and not primitive_types[ fname ] then
      fa.has_user_type = true
    end
  end

  -- private local function because it isn't useful without the
  -- add_transition function above
  local function nfa_append( self, a )
    local offset = self.n
    self.n = offset + a.n
    local self_trs, a_trs = self.transitions, a.transitions
    for i = 1, #a_trs do
      local tr = a_trs[ i ]
      self_trs[ #self_trs+1 ] = transition:new( tr.from + offset,
                                                tr.to + offset,
                                                tr.fname, tr.f )
    end
    self.has_user_type = self.has_user_type or a.has_user_type
    self.is_nonlinear = self.is_nonlinear or a.is_nonlinear
    self.needs_backtracking = self.needs_backtracking or
                              a.needs_backtracking
  end

  function NFA:new( name, f )
    local a = { n = 1, transitions = {} }
    setmetatable( a, NFA_meta )
    if name and f then
      a.n = 2
      add_transition( a, 1, 2, name, f )
    end
    return a
  end

  -- add the states/transitions from another NFA as an alternative to
  -- this NFA
  function NFA:alt( a )
    local last = self.n
    nfa_append( self, a )
    add_transition( self, 1, last+1 )
    add_transition( self, last, self.n )
    self.is_nonlinear = true
    if self.has_user_type or a.has_user_type then
      self.needs_backtracking = true
    end
  end

  -- add the states/transitions from another NFA in sequence to this NFA
  function NFA:seq( a )
    local last = self.n
    nfa_append( self, a )
    add_transition( self, last, last+1 )
    if self.is_nonlinear and a.has_user_type then
      self.needs_backtracking = true
    end
  end

  -- make all transitions in this NFA optional
  function NFA:opt()
    local last = self.n
    add_transition( self, 1, self.n )
    self.is_nonlinear = true
    if self.has_user_type then
      self.needs_backtracking = true
    end
  end

  -- add repetition to this NFA
  function NFA:rep()
    add_transition( self, self.n, 1 )
    self.n = self.n + 1
    add_transition( self, self.n-1, self.n )
    self.is_nonlinear = true
    if self.has_user_type then
      self.needs_backtracking = true
    end
  end

  -- collect all states which are connected to any of the given states
  -- via epsilon transitions
  function NFA:closure( states )
    local queue, set = {}, {}
    for i in pairs( states ) do
      queue[ #queue+1 ] = i
    end
    for _,sid in ipairs( queue ) do
      set[ sid ] = true
      for i = 1, #self.transitions do
        local tr = self.transitions[ i ]
        if tr.from == sid
           and tr.f == nil
           and not set[ tr.to ] then
          queue[ #queue+1 ] = tr.to
        end
      end
    end
    return set
  end

  -- collect all states reachable from the given set of states in one
  -- step via the predicate function f
  function NFA:reachable( states, f )
    local set = {}
    for i = 1, #self.transitions do
      local tr = self.transitions[ i ]
      if states[ tr.from ] and tr.f == f then
        set[ tr.to ] = true
      end
    end
    return set
  end
end


-- small class for deterministic finite automata (DFAs)
local DFA = {}
local DFA_meta = { __index = DFA }

do
  local function set_equal( s1, s2 )
    for k,v in pairs( s1 ) do
      if s2[ k ] ~= v then
        return false
      end
    end
    for k,v in pairs( s2 ) do
      if s1[ k ] ~= v then
        return false
      end
    end
    return true
  end

  -- assign consecutive ids to sets (ids cached in list)
  local function id4set( list, set )
    for i = 1, #list do
      if set_equal( list[ i ], set ) then
        return i, true
      end
    end
    list[ #list+1 ] = set
    return #list, false
  end

  -- Constructs an equivalent DFA from the given NFA. The only states
  -- without outgoing transitions are end/accepting states.
  function DFA:new( an_nfa )
    local a = {
      n = 0,
      needs_backtracking = an_nfa.needs_backtracking,
      flags = {},
      transitions = {},
    }
    if an_nfa.n > 0 then
      local dfastates, a_trs = {}, a.transitions
      id4set( dfastates, an_nfa:closure{ true } )
      for i,st in ipairs( dfastates ) do
        if st[ an_nfa.n ] then
          a.flags[ i ] = true -- mark as accepting end state
        end
        local fs = {}
        for j = 1, #an_nfa.transitions do
          local tr = an_nfa.transitions[ j ]
          if st[ tr.from ] and tr.f and not fs[ tr.f ] then
            fs[ tr.f ] = true
            local n_st = an_nfa:closure( an_nfa:reachable( st, tr.f ) )
            local id = id4set( dfastates, n_st )
            a_trs[ #a_trs+1 ] = transition:new( i, id, tr.fname, tr.f )
          end
        end
      end
      a.n = #dfastates
    end
    setmetatable( a, DFA_meta )
    return a
  end

  -- Sorts the transitions and returns a lookup table t where
  -- t[ state_id ] is the first index in the transitions table where
  -- transitions originating from state_id are stored. This is used to
  -- speed up lookups.
  function DFA:lookup()
    local indices = {}
    tsort( self.transitions )
    local tr_index = 1
    for i = 1, self.n+1 do
      indices[ i ] = tr_index
      local curr_tr = self.transitions[ tr_index ]
      while curr_tr and curr_tr.from == i do
        tr_index = tr_index + 1
        curr_tr = self.transitions[ tr_index ]
      end
    end
    return indices
  end

  function DFA:compile()
    if self.needs_backtracking then
      return self:compile_backtracking()
    else
      return self:compile_optimized()
    end
  end

  -- create n comma separated names given the pattern
  local function n_args( n, fmt )
    local s = ""
    for i = 1, n do
      s = s .. fmt:format( i )
      if i ~= n then
        s = s .. ", "
      end
    end
    return s
  end

  -- array for passing the functions to the compiled code
  local function fcollect( trs )
    local f2id, id2f = {}, {}
    for i = 1, #trs do
      local f = trs[ i ].f
      if not f2id[ f ] then
        id2f[ #id2f+1 ] = f
        f2id[ f ] = #id2f
      end
    end
    return f2id, id2f
  end

  function DFA:compile_optimized()
    --do return self:compile_backtracking() end
    local indices = self:lookup()
    local code = "local spec, fname, etype, ioff, erroff, select, error, tconcat"
    -- pass all required checking functions
    local f2id, id2f = fcollect( self.transitions )
    if #id2f > 0 then
      -- get checkers from argument list
      code = code..", "..n_args( #id2f, "f_%d" )
    end
    code = code.." = ...\n"
    -- forward declare the state functions
    code = code.."local "..n_args( self.n, "state_%d" ).."\n"
    -- generate the state functions
    for i = 1, self.n do
      code = code..[[
function state_]]..i..[[( i, n, ... )
]]
      local types = ""
      for j = indices[ i ], indices[ i+1 ]-1 do
        if j > indices[ i ] then
          types = types.."/"
        end
        types = types..self.transitions[ j ].fname
      end
      code = code..[[
  if i > n then
]]
      if self.flags[ i ] then
        code = code..[[
    return true
]]
      else
        code = code..[[
    return false, "missing "..etype.."(s) at index "..(i+ioff)..
                  " (expected ]] .. types ..[[)"
]]
      end
      code = code..[[
  else
    local val = select( i, ... )
]]
      for j = indices[ i ], indices[ i+1 ]-1 do
        local tr = self.transitions[ j ]
        code = code..[[
    if f_]]..f2id[ tr.f ]..[[( val ) then
      return state_]]..tr.to..[[( i+1, n, ... )
    end
]]
      end
      code = code..[[
    local msg
]]
      if indices[ i ] ~= indices[ i+1 ] then
        code = code..[[
    msg =  "]]..types..[[ expected for "..etype.." no. "..
           (i+ioff).." (got "..type( val )..")"
]]
      end
      if self.flags[ i ] then
        code = code .. [[
    local s = "too many "..etype.."s (expected "..(i+ioff-1)..")"
    msg = msg and msg..",\n\tor "..s or s
]]
      end
      code = code..[[
    return false, msg or "unknown error"
  end
end
]]
    end
    code = code..[[
return function( ... )
  local n = select( '#', ... )
  local ok, msg = state_1( 1, n, ... )
  if not ok then
    error( fname..": "..msg..".", 5+erroff )
  end
  return ...
end
]]
    return code, id2f
  end

  -- returns lua code that implements the DFA
  function DFA:compile_backtracking()
    local indices = self:lookup()
    local code = "local spec, fname, etype, ioff, erroff, select, error, tconcat"
    -- pass all required checking functions
    local f2id, id2f = fcollect( self.transitions )
    if #id2f > 0 then
      -- get checkers from argument list
      code = code..", "..n_args( #id2f, "f_%d" )
    end
    code = code.." = ...\n"
    -- forward declare the state functions
    code = code.."local "..n_args( self.n, "state_%d" ).."\n"
    -- generate the state functions
    for i = 1, self.n do
      code = code..[[
function state_]]..i..[[( msg, i, n, ... )
]]
      local types = ""
      for j = indices[ i ], indices[ i+1 ]-1 do
        if j > indices[ i ] then
          types = types.."/"
        end
        types = types..self.transitions[ j ].fname
      end
      code = code..[[
  if i > n then
]]
      if self.flags[ i ] then
        code = code..[[
    return true
]]
      else
        code = code..[[
    if msg then
      msg[ #msg+1 ] = "missing "..etype.."(s) at index "..(i+ioff)..
                      " (expected ]] .. types ..[[)"
    end
]]
      end
      code = code..[[
  else
    local val, match = select( i, ... ), false
]]
      for j = indices[ i ], indices[ i+1 ]-1 do
        local tr = self.transitions[ j ]
        code = code..[[
    if f_]]..f2id[ tr.f ]..[[( val ) then
      match = true
      if state_]]..tr.to..[[( msg, i+1, n, ... ) then return true end
    end
]]
      end
      code = code..[[
    if msg then
]]
      if indices[ i ] ~= indices[ i+1 ] then
        code = code..[[
      if not match then
        msg[ #msg+1 ] = "]]..types..[[ expected for "..etype.." no. "..
                        (i+ioff).." (got "..type( val )..")"
      end
]]
      end
      if self.flags[ i ] then
        code = code .. [[
      msg[ #msg+1 ] = "too many "..etype.."s (expected "..
                      (i+ioff-1)..")"
]]
      end
      code = code..[[
    end
  end
  return false
end
]]
    end
    code = code..[[
return function( ... )
  local n = select( '#', ... )
  if not state_1( nil, 1, n, ... ) then
    local t = {}
    state_1( t, 1, n, ... ) -- rerun to collect error messages
    error( fname..": "..tconcat( t, ",\n\tor " )..".", 5+erroff )
  end
  return ...
end
]]
    return code, id2f
  end
end


local function debug_automaton( fa )
  local end_states = {}
  if fa.flags then
    for i = 1, fa.n do
      if fa.flags[ i ] then
        end_states[ #end_states+1 ] = i
      end
    end
  else
    end_states[ 1 ] = fa.n
  end
  print( "states:", fa.n, "END:", unpack( end_states ) )
  print( "needs_backtracking:", fa.needs_backtracking )
  for i,t in ipairs( fa.transitions ) do
    print( "", t.from, "-->", t.to, t.fname )
  end
end



----------------------------------------------------------------------
-- A parser for docstrings using LPeg.
--
-- Example:
-- mod.obj:func = docstring[=[
-- Some optional text (which is ignored).
--
-- mod.obj:func( a [, b [, c]], ... )
--    ==> table/userdata  -- when successful
--    ==> nil, string     -- in case of error
--  self: object          -- implicit if not specified
--     a: table/userdata  -- some table or userdata
--     b: integer         -- an optional number
--                        -- comments can span several lines
--     c: any             -- any value allowed
--  ... : (table, string)*
--
-- Some more text describing the function which is also ignored
-- by the function signature parser!
-- ]=] .. function( a, b, c, ... ) end

local g = {}
do
  local P,R,S,V,C,Cc,Ct = L.P,L.R,L.S,L.V,L.C,L.Cc,L.Ct
  local pbreak = P"\n\n"
  local comment = P"--" * (P( 1 ) - P"\n")^0
  local ws = S" \t\r\n\v\f"
  local _ = ((ws + comment) - pbreak)^0
  local letter = R( "az", "AZ" ) + P"_"
  local digit = R( "09" )
  local id = letter * (letter+digit)^0
  local varargs = C( P"..." ) *_
  local retsym = P"="^1 * P">" * _

  g[ 1 ] = _ * (V"paragraph" - V"typespec")^0 * V"typespec" * V"paragraph"^0 * P( -1 )
  g.paragraph = (P( 1 ) - pbreak)^1 * ws^0
  g.typespec = C( V"funcname" * P"(" * _ * Ct( V"arglistv" ) * P")" * _ * V"retlist" * V"paramspec" ) * ws^0
  g.funcname = C( id * (P"." * id)^0 * ((P":" * id * Cc( true )) + Cc( false )) ) * _
  -- argument list
  g.arglistv = (V"arg" + V"optargs")^0 * (P","^-1 * _ * (V"optargsv" + varargs))^-1
  g.arg = P","^-1 * _ * C( id ) * _ * P","^-1 * _
  g.optargs = P"[" * _ * Ct( (V"arg" + V"optargs")^1 ) * P"]" * _ * P","^-1 * _
  g.optargsv = P"[" * _ * Ct( V"arglistv" ) * P"]" * _
  -- return values
  g.retlist = Ct( Cc"alt" * (retsym * V"seq")^0 )
  -- argument type specifications
  g.paramspec = Ct( V"argspec"^0 * V"varargspec"^-1 * V"argspec"^0 )
  g.argspec = Ct( C( id ) * _ * P":" * _ * C( id ) * _ * (P"/" * _ * C( id ) * _)^0 )
  g.varargspec = Ct( varargs * P":" * _ * V"seq" )
  -- common to return values and vararg type specifications
  g.seq = Ct( Cc"seq" * V"alt" * (P"," * _ * V"alt")^1 ) + V"alt"
  g.alt = Ct( Cc"alt" * V"mul" * (P"/" * _ * V"mul")^1 ) + V"mul"
  g.mul = Ct( Cc"mul" * V"val" * P"*" * _ ) +
          Ct( Cc"opt" * V"val" * P"?" * _ ) + V"val"
  g.val = (C( id ) + P"(" * _ * V"seq" * P")") * _

  -- compile grammar once and for all
  g = P( g )
end


-- debug function to show some nested tables captured by lpeg
local function debug_ast( node, prefix )
  prefix = prefix or ""
  if type( node ) == "table" then
    io.stderr:write( "{" )
    if next( node ) ~= nil then
      io.stderr:write( "\n" )
      for k,v in pairs( node ) do
        io.stderr:write( prefix, "  ", tostring( k ), " = " )
        debug_ast( v, prefix.."  " )
      end
    end
    io.stderr:write( prefix, "}\n" )
  else
    io.stderr:write( tostring( node ), "\n" )
  end
end



----------------------------------------------------------------------
-- Putting it all together ...


-- generates an nfa from the given AST (seq,alt,opt,mul,val)
local function nfa_from_expr( types, expr )
  local t = type( expr )
  if t == "string" then
    local f = types[ expr ]
    if type( f ) ~= "function" then
      return nil, "type `"..expr.."' is undefined!"
    end
    return NFA:new( expr, f )
  elseif t == "table" then
    if expr[ 1 ] == "seq" then
      local n = NFA:new()
      for i = 2, #expr do
        local n2, msg = nfa_from_expr( types, expr[ i ] )
        if not n2 then return n2, msg end
        n:seq( n2 )
      end
      return n
    elseif expr[ 1 ] == "alt" then
      local n
      for i = 2, #expr do
        local n2, msg = nfa_from_expr( types, expr[ i ] )
        if not n2 then return n2, msg end
        if not n then
          n = n2
        else
          n:alt( n2 )
        end
      end
      return n or NFA:new()
    elseif expr[ 1 ] == "mul" then
      local n, msg = nfa_from_expr( types, expr[ 2 ] )
      if n then n:rep() n:opt() end
      return n, msg
    elseif expr[ 1 ] == "opt" then
      local n, msg = nfa_from_expr( types, expr[ 2 ] )
      if n then n:opt() end
      return n, msg
    else
      error( "invalid node in expression tree: " .. tostring( expr[ 1 ] ) )
    end
  else
    error( "invalid value in expression tree: " .. tostring( expr ) )
  end
end


local function arg2nfa( types, symtab, usedargs, arg )
  local t = type( arg )
  if t == "table" then
    local n = NFA:new()
    for i = 1, #arg do
      local n2, msg = arg2nfa( types, symtab, usedargs, arg[ i ] )
      if not n2 then return n2, msg end
      n:seq( n2 )
    end
    n:opt()
    return n
  elseif t == "string" then
    if symtab[ arg ] then
      if usedargs[ arg ] then
        return nil, "argument name `"..arg.."' used multiple times!"
      end
      usedargs[ arg ] = true
      return symtab[ arg ]
    elseif types[ arg ] then
      return NFA:new( arg, types[ arg ] )
    else
      return nil, "argument name `"..arg.."' not defined!"
    end
  else
    error( "invalid value in argument list: " .. tostring( arg ) )
  end
end


-- combines the argument list with the nfas from the symbol table
local function nfa_from_args( types, symtab, args )
  local usedargs = {}
  local n = NFA:new()
  for i = 1, #args do
    local n2, msg = arg2nfa( types, symtab, usedargs, args[ i ] )
    if not n2 then return n2, msg end
    n:seq( n2 )
  end
  return n
end


-- generate nfas for arg specs
local function build_symbol_table( types, is_method, argtypes, warn )
  local symtab = {}
  for i = 1, #argtypes do
    local a = argtypes[ i ][ 1 ]
    if symtab[ a ] then
      return nil, "argument `"..a.."' redefined!"
    end
    local n, msg
    if a == "..." then
      n, msg = nfa_from_expr( types, argtypes[ i ][ 2 ] )
    else
      argtypes[ i ][ 1 ] = "alt"
      n, msg = nfa_from_expr( types, argtypes[ i ] )
    end
    if not n then
      return nil, msg
    end
    symtab[ a ] = n
  end
  if is_method and not symtab.self then
    if types.object then
      symtab.self = NFA:new( "object", types.object )
    elseif types.table and types.userdata then
      local n = NFA:new( "userdata", types.userdata )
      n:alt( NFA:new( "table", types.table ) )
      symtab.self = n
    end
  end
  return symtab
end


local function compile_args_check( types, spec, name, is_method, args,
                                   argtypes, warn )
  local symtab, msg = build_symbol_table( types, is_method, argtypes,
                                          warn )
  if not symtab then
    warn( "[check]: "..msg.."\n"..spec )
    return
  end
  -- combine with arglists
  if is_method then
    tinsert( args, 1, "self" )
  end
  local n, msg = nfa_from_args( types, symtab, args )
  if not n then
    warn( "[check]: "..msg.."\n"..spec )
    return
  end
  local d = DFA:new( n )
  --debug_automaton( d )
  local source, id2f = d:compile()
  --print( source )
  local f = assert( loadstring( source, "=[compiled_arg_check]" ) )
  local off = is_method and -1 or 0
  return f( spec, name, "argument", off, 0, select, error, tconcat,
            unpack( id2f ) )
end


local function compile_return_check( types, spec, name, rets, warn )
  local n, msg = nfa_from_expr( types, rets )
  if not n then
    warn( "[check]: "..msg.."\n"..spec )
    return
  end
  local d = DFA:new( n )
  --debug_automaton( d )
  local source, id2f = d:compile()
  --print( source )
  local f = assert( loadstring( source, "=[compiled_ret_check]" ) )
  -- Lua 5.2 doesn't count tailcalls for errorlevels ...
  local erroff = _VERSION ~= "Lua 5.1" and -1 or 0
  return f( spec, name, "return value", 0, erroff, select, error,
            tconcat, unpack( id2f ) )
end


-- compiles the given string into argument and return checking functions
local function compile_typespec( input, types, do_arg, do_ret, warn )
  warn = warn or error
  local spec, name, is_method, args, rets, argtypes = L.match( g, input )
  if not spec then
    warn( "[check]: docstring does not contain type specification!" )
  else
    name = is_method and name:gsub( ":", "." ) or name
    local arg_check_func, ret_check_func
    if do_arg then
      arg_check_func = compile_args_check( types, spec, name, is_method,
                                           args, argtypes, warn )
    end
    if do_ret then
      ret_check_func = compile_return_check( types, spec, name, rets,
                                             warn )
    end
    return arg_check_func, ret_check_func
  end
end


-- primitive type checking functions
local types = {
  ["nil"] = function( val ) return val == nil end,
  boolean = function( val ) return type( val ) == "boolean" end,
  number = function( val ) return type( val ) == "number" end,
  string = function( val ) return type( val ) == "string" end,
  table = function( val ) return type( val ) == "table" end,
  userdata = function( val ) return type( val ) == "userdata" end,
  ["function"] = function( val ) return type( val ) == "function" end,
  thread = function( val ) return type( val ) == "thread" end,
  any = function( val ) return true end,
  object = function( val )
    local t = type( val )
    return t == "userdata" or t == "table"
  end,
  [ "true" ] = function( val ) return val ~= nil and val ~= false end,
  [ "false" ] = function( val ) return val == nil or val == false end,
}

-- additional type checking functions depending on optional modules
if type( io ) == "table" and type( io.type ) == "function" then
  local iotype = io.type
  types[ "file" ] = function( val )
    return iotype( val ) == "file"
  end
end
if type( math ) == "table" and type( math.floor ) == "function" then
  local mathfloor = math.floor
  types[ "integer" ] = function( val )
    return type( val ) == "number" and val == mathfloor( val )
  end
end
if type( L.type ) == "function" then
  local lpegtype = L.type
  types[ "pattern" ] = function( val )
    return lpegtype( val ) == "pattern"
  end
end



local M = {
  enabled = true,
  types = types,
  errorf = function( s ) return error( s, 0 ) end,
  arguments = true,
  return_values = true,
}


local function docstring_callback( fun, docstring )
  local newfun = fun
  if M.enabled and type( fun ) == "function" then
    local argc, retc = compile_typespec( docstring, M.types,
                                         M.arguments, M.return_values,
                                         M.errorf )
    if argc and retc then
      newfun = function( ... )
        return retc( fun( argc( ... ) ) )
      end
    elseif argc then
      newfun = function( ... )
        return fun( argc( ... ) )
      end
    elseif retc then
      newfun = function( ... )
        return retc( fun( ... ) )
      end
    end
  end
  return newfun
end

annotate:register( docstring_callback, true )

return M

