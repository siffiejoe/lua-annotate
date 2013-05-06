-- cache globals and require modules
local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local table = require( "table" )
local string = require( "string" )
local io = require( "io" )
local debug = require( "debug" )
local L = require( "lpeg" )
local _G = assert( _G )
local _VERSION = assert( _VERSION )
local type = assert( type )
local tostring = assert( tostring )
local select = assert( select )
local setmetatable = assert( setmetatable )
local xpcall = assert( xpcall )
local t_concat = assert( table.concat )
local s_gsub = assert( string.gsub )
local s_match = assert( string.match )
local s_rep = assert( string.rep )
local s_sub = assert( string.sub )
local io_stderr = assert( io.stderr )
local db_traceback = assert( debug.traceback )
local lpeg_match = assert( L.match )
local loadstring = assert( loadstring or load )
local unpack = assert( unpack or table.unpack )
local eof_ender = "<eof>"
local setfenv = setfenv
if _VERSION == "Lua 5.1" then
  assert( setfenv )
  eof_ender = "'<eof>'"
end



-- table to store the tests in
local test_cache = {}


-- grammar to identify test code in docstring
local g = {}
do
  local P,R,S,V,C,Ct,Cc = L.P,L.R,L.S,L.V,L.C,L.Ct,L.Cc
  local pbreak = P"\n\n"
  local comment = P"--" * (P( 1 ) - P"\n")^0
  local ws = S" \t\r\n\v\f"
  local _ = (ws - pbreak)^0
  local _2 = ((ws + comment) - pbreak)^0
  local letter = R( "az", "AZ" ) + P"_"
  local digit = R"09"
  local id = letter * (letter+digit)^0
  local indent = P"    "
  local title = S"Ee"*S"Xx"*S"Aa"*S"Mm"*S"Pp"*S"Ll"*S"Ee"*(S"Ss"^-1) +
                S"Tt"*S"Ee"*S"Ss"*S"Tt"*(S"Ss"^-1)

  g[ 1 ] = ws^0 * Ct( (V"typespec" + (V"paragraph" - V"testspec"))^0 ) * V"testspec" * V"paragraph"^0 * P( -1 )
  g.paragraph = (P( 1 ) - pbreak)^1 * ws^0
  -- for extracting a function signature if there is one
  g.typespec = C( _2 * V"funcname" * P"(" * _2 * V"arglist" * P")" ) * V"paragraph"^-1 * ws^0
  g.funcname = id * (P"." * id)^0 * (P":" * id)^-1 * _2
  g.arglist = (id+S"[],."+((ws+comment)-pbreak)^1)^0
  -- test specification
  g.testspec = V"header" * Ct( (V"lua_line" + Ct( V"out_line"^1 ) + V"empty_line")^1 ) * ws^0
  g.header = (title*P":" + P"#"^1*(ws-P"\n")^0*title*(ws-P"\n")^0*P"#"^0) * V"empty_line"^0
  g.lua_line = indent * P">" * P">"^-1 * P" "^-1 * C( (P( 1 ) - P"\n")^0 ) * P"\n"
  g.out_line = indent * -P">" * C( (P( 1 ) - P"\n")^0 ) * P"\n"
  g.empty_line = (ws - P"\n")^0 * P"\n"

  -- compile grammar once and for all
  g = P( g )
end


local function output_pattern( lines )
  local s = t_concat( lines, "\n" )
  s = s_gsub( s, "([%]%[%^%$%%%.%*%+%-%?])", function( c )
    return "%"..c
  end )
  s = s_gsub( s, "%%%.%%%.%%%.", ".-" )
  return "^"..(s_gsub( s, "%s+", "%%s+" )).."%s*$"
end


local function xp_pack( status, ... )
  return status, { ... }, select( '#', ... )
end


local function traceback( msg )
  local t = type( msg )
  if t ~= "string" and t ~= "number" then
    return msg
  end
  return db_traceback( msg, 2 )
end

local function incomplete( msg )
  return msg and s_sub( msg, -#eof_ender ) == eof_ender
end


local function prepare_env( f )
  local env, out = {}, { n = 0 }
  env._G = env
  local function p( ... )
    local n = select( '#', ... )
    for i = 1, n do
      out[ out.n + 1 ] = tostring( select( i, ... ) )
      out[ out.n + 2 ] = i == n and "\n" or "\t"
      out.n = out.n + 2
    end
    if n == 0 then
      out[ out.n + 1 ] = "\n"
      out.n = out.n + 1
    end
  end
  env.print = p
  env.F = f
  setmetatable( env, { __index = _G } )
  return env, out, p
end


local function get_caption( v, sig )
  if type( v ) == "function" and sig then
    return "function " .. sig
  else
    return tostring( v )
  end
end


local function extra_output( out, errors, t, verbosity )
  local do_break = false
  if out.n > 0 then
    local s = t_concat( out, "", 1, out.n )
    if out.is_error then
      errors[ #errors+1 ] = "### ("..t..") UNEXPECTED ERROR: "..s
      do_break = true
    else
      if verbosity > 1 then
        errors[ #errors+1 ] = "### ("..t..") UNEXPECTED OUTPUT: "..s
      end
    end
    out.n, out.is_error = 0, nil
  end
  return do_break
end


local function preamble( verbosity, caption )
  if verbosity > 2 then
    io_stderr:write( "### TEST ", caption, "\n" )
  end
end

local delim = s_rep( "#", 70 )

local function report( verbosity, caption, results, errors )
  if #errors > 0 then
    io_stderr:write( delim, "\n" )
  end
  if verbosity > 0 or #errors > 0 then
    io_stderr:write( "### [", results, "] ", caption, "\n" )
  end
  if #errors > 0 then
    for i = 1, #errors do
      io_stderr:write( errors[ i ] )
    end
    io_stderr:write( delim, "\n" )
  end
end


local function run_test( test, totals, verbosity )
  local ok, fail, n = 0, 0, 0
  local results, errors = "", {}
  local caption = get_caption( test.v, test.sig )
  local env, out, p = prepare_env( test.v )
  preamble( verbosity, caption )
  local j, buffer, _ = 1, nil
  for i = 1, #test.data do
    local elem = test.data[ i ]
    if type( elem ) == "string" then -- Lua code
      if buffer then
        buffer = buffer .. "\n" .. elem
      else
        if extra_output( out, errors, j, verbosity ) then
          break
        end
        buffer = elem
        if s_sub( elem, 1, 1 ) == "=" then
          buffer = "return " .. s_sub( elem, 2 )
        end
      end
      local f, msg = loadstring( buffer, "=stdin", "t", env )
      if f then
        if _VERSION == "Lua 5.1" then
          setfenv( f, env )
        end
        buffer = nil
        local st, res, n_res = xp_pack( xpcall( f, traceback ) )
        if n_res > 0 then
          p( unpack( res, 1, n_res ) )
        end
        out.is_error = not st
      else
        if not incomplete( msg ) then -- compilation error
          errors[ #errors+1 ] = "### ("..j..") COMPILATION ERROR: "..
                                 msg.."\n"
          buffer, out.n = nil, 0
          break
        end
      end
    else -- output lines
      local s = t_concat( out, "", 1, out.n )
      out.n, out.is_error = 0, nil
      local outp = output_pattern( elem )
      if s_match( s, outp ) then
        ok = ok + 1
        results = results .. "+"
      else
        fail = fail + 1
        results = results .. "-"
        if verbosity > 1 then
          errors[ #errors+1 ] = "### ("..j..")\n### EXPECTED: "..outp..
                                "\n### GOT: >>>"..s.."<<<\n"
        end
      end
      n, j = n + 1, j + 1
    end
  end
  if buffer then -- handle incomplete Lua
    errors[ #errors+1 ] = "### ("..j..") INCOMPLETE CODE: "..buffer.."\n"
  end
  extra_output( out, errors, j, verbosity )
  totals.ok = totals.ok + ok
  totals.fail = totals.fail + fail
  totals.n = totals.n + n
  report( verbosity, caption, results, errors )
end



local function docstring_callback( v, docstring )
  local sigs, tests = lpeg_match( g, docstring )
  if sigs then
    local t = { v = v }
    if #sigs == 1 then
      t.sig = sigs[ 1 ]
    end
    t.data = tests
    test_cache[ #test_cache+1 ] = t
  end
end
annotate:register( docstring_callback )

local M = {}
local M_meta = {
  __call = function( _, verbosity )
    verbosity = type( verbosity ) == "number" and verbosity or 1
    local tests = test_cache
    test_cache = {}
    local totals = { ok = 0, fail = 0, n = 0 }
    for i = 1, #tests do
      run_test( tests[ i ], totals, verbosity )
    end
    io_stderr:write( "### TOTAL: ", totals.ok, " ok, ", totals.fail,
                     " failed, ", totals.n, " total\n")
    return totals.fail == 0
  end,
}

setmetatable( M, M_meta )
return M

