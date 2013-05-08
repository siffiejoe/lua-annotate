local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local string = require( "string" )
local s_gsub = assert( string.gsub )
local s_match = assert( string.match )
local s_rep = assert( string.rep )
local _VERSION = assert( _VERSION )
local type = assert( type )
local pairs = assert( pairs )
local select = assert( select )
local tostring = assert( tostring )
local tonumber = assert( tonumber )
local print = assert( print )
local pcall = assert( pcall )
local setmetatable = assert( setmetatable )

local _G, bit32, coroutine, debug, io, math, os, package, table =
      _G, bit32, coroutine, debug, io, math, os, package, table

local V = assert( tonumber( s_match( _VERSION, "^Lua%s+(%d+%.%d+)$" ) ) )


local docstring_cache = {}
setmetatable( docstring_cache, { __mode="k" } )

local function docstring_callback( v, docstring )
  docstring_cache[ v ] = s_gsub( docstring, "^%s*(.-)%s*$", "%1" )
end
annotate:register( docstring_callback )

----------------------------------------------------------------------

local function check( t, name, cond )
  if cond == nil then cond = true end -- default is true
  if type( cond ) == "number" then -- minimum version specified
    cond = (V >= cond) and (V < 5.3)
  end
  return cond and type( t ) == "table" and t[ name ] ~= nil
end

local _ -- dummy variable

----------------------------------------------------------------------
-- base library

if check( _G, "_G", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                         Lua Base Library                         ##

The Lua standard base library defines the following global functions:

*   `assert` -- Raise an error if a condition is false.
*   `collectgarbage` -- Control the Lua garbage collector.
*   `dofile` -- Load and run a Lua file.
*   `error` -- Raise an error.
*   `getfenv` -- Get a function's environment.
*   `getmetatable` -- Get a table's/userdata's metatable.
*   `ipairs` -- Iterate over array elements in order.
*   `load` -- Generic function for loading Lua code.
*   `loadfile` -- Load Lua code from a file.
*   `loadstring` -- Load Lua code from a string.
*   `module` -- Declare a Lua module.
*   `next` -- Query next key/value from a table.
*   `pairs` -- Iterator over all elements in a table.
*   `pcall` -- Call Lua function catching all errors.
*   `print` -- Show Lua values on console.
*   `rawequal` -- Compare values without invoking metamethods.
*   `rawget` -- Get a value for a key without invoking metamethods.
*   `rawset` -- Set a value for a key without invoking metamethods.
*   `require` -- Load a module.
*   `select` -- Extract length/elements of varargs (`...`).
*   `setfenv` -- Set environment of functions.
*   `setmetatable` -- Set metatable on a tables/userdata.
*   `tonumber` -- Convert a string to a Lua number.
*   `tostring` -- Convert any Lua value to a string.
*   `type` -- Query the type of a Lua value.
*   `unpack` -- Converts an array to multiple values (vararg).
*   `xpcall` -- Like `pcall`, but providing stack traces for errors.

]=] .. _G
end

if check( _G, "_G", 5.2 ) then
  _ = annotate[=[
##                         Lua Base Library                         ##

The Lua standard base library defines the following global functions:

*   `assert` -- Raise an error if a condition is false.
*   `collectgarbage` -- Control the Lua garbage collector.
*   `dofile` -- Load and run a Lua file.
*   `error` -- Raise an error.
*   `getmetatable` -- Get a table's/userdata's metatable.
*   `ipairs` -- Iterate over array elements in order.
*   `load` -- Generic function for loading Lua code.
*   `loadfile` -- Load Lua code from a file.
*   `next` -- Query next key/value from a table.
*   `pairs` -- Iterator over all elements in a table.
*   `pcall` -- Call Lua function catching all errors.
*   `print` -- Show Lua values on console.
*   `rawequal` -- Compare values without invoking metamethods.
*   `rawget` -- Get a value for a key without invoking metamethods.
*   `rawlen` -- Get length without invoking metamethods.
*   `rawset` -- Set a value for a key without invoking metamethods.
*   `require` -- Load a module.
*   `select` -- Extract length/elements of varargs (`...`).
*   `setmetatable` -- Set metatable on a tables/userdata.
*   `tonumber` -- Convert a string to a Lua number.
*   `tostring` -- Convert any Lua value to a string.
*   `type` -- Query the type of a Lua value.
*   `xpcall` -- Like `pcall`, but providing stack traces for errors.

]=] .. _G
end

if check( _G, "assert", 5.1 ) then
  _ = annotate[=[
##                       The `assert` Function                      ##

    assert( cond, ... ) ==> any*
      cond: any       -- evaluated as a condition
      ... : any*      -- additional arguments (first may serve as
                      -- error message)

If `assert`'s first argument evaluates to a true value (anything but
`nil` or `false`), `assert` passes all arguments as return values. If
the first argument is `false` or `nil`, `assert` raises an error using
the second argument as an error message. If there is no second
argument, a generic error message is used.

###                            Examples                            ###

    > =assert( true, 1, "two", {} )
    true    1       two     table: ...
    > =assert( false, "my error message", {} )
    stdin:1: my error message
    stack traceback:
            ...
    > function f() return nil end
    > assert( f() )
    stdin:1: assertion failed!
    stack traceback:
            ...

]=] .. _G.assert
end

if check( _G, "pairs", 5.1 ) then
  _ = annotate[=[

]=] .. _G.pairs
end

----------------------------------------------------------------------
-- bit32 library

if check( _G, "bit32", 5.2 ) then
  _ = annotate[=[
##                        Bitwise Operations                        ##

]=] .. bit32
end

if check( bit32, "arshift", 5.2 ) then
  _ = annotate[=[

]=] .. bit32.arshift
end

----------------------------------------------------------------------
-- coroutine library

if check( _G, "coroutine", 5.1 ) then
  _ = annotate[=[
##                      Coroutine Manipulation                      ##

]=] .. coroutine
end

if check( coroutine, "create", 5.1 ) then
  _ = annotate[=[

]=] .. coroutine.create
end

----------------------------------------------------------------------
-- debug library

if check( _G, "debug", 5.1 ) then
  _ = annotate[=[
##                         The Debug Library                        ##

]=] .. debug
end

if check( debug, "debug", 5.1 ) then
  _ = annotate[=[

]=] .. debug.debug
end

----------------------------------------------------------------------
-- io library

if check( _G, "io", 5.1 ) then
  _ = annotate[=[
##                    Input and Output Facilities                   ##

]=] .. io
end

if check( io, "close", 5.1 ) then
  _ = annotate[=[

]=] .. io.close
end

----------------------------------------------------------------------
-- math library

if check( _G, "math", 5.1 ) then
  _ = annotate[=[
##                      Mathematical Functions                      ##

]=] .. math
end

if check( math, "abs", 5.1 ) then
  _ = annotate[=[

]=] .. math.abs
end

----------------------------------------------------------------------
-- os library

if check( _G, "os", 5.1 ) then
  _ = annotate[=[
##                    Operating System Facilities                   ##

]=] .. os
end

if check( os, "clock", 5.1 ) then
  _ = annotate[=[

]=] .. os.clock
end

----------------------------------------------------------------------
-- package table

if check( _G, "package", 5.1 ) then
  _ = annotate[=[
##                         The Package Table                        ##

]=] .. package
end

if check( package, "config", 5.1 ) then
  _ = annotate[=[

]=] .. package.config
end

----------------------------------------------------------------------
-- string library

if check( _G, "string", 5.1 ) then
  _ = annotate[=[
##                        String Manipulation                       ##

]=] .. string
end

if check( string, "byte", 5.1 ) then
  _ = annotate[=[

]=] .. string.byte
end

----------------------------------------------------------------------
-- table library

if check( _G, "table", 5.1 ) then
  _ = annotate[=[
##                        Table Manipulation                        ##

]=] .. _G.table
end

if check( table, "concat", 5.1 ) then
  _ = annotate[=[
##                    The `table.concat` Function                   ##

    table.concat( list [, sep [, i [, j]]] ) ==> string
        list: table     -- an array of strings or numbers
        sep : string    -- a separator, defaults to ""
        i   : integer   -- starting index, defaults to 1
        j   : integer   -- end index, defaults to #list

###                            Examples                            ###

    > t = { 1, 2, "3", 4, 5 }
    > =table.concat( t )
    12345
    > =table.concat( t, "+" )
    1+2+3+4+5
    > =table.concat( t, ",", 3 )
    3,4,5
    > =table.concat( t, "|", 2, 4 )
    2|3|4

]=] .. table.concat
end

----------------------------------------------------------------------

local M = {}

local function try_require( str, ... )
  local ok, v = pcall( require, str )
  if ok then
    for i = 1, select( '#', ... ) do
      local n = select( i, ... )
      if type( v ) == "table" then
        v = v[ n ]
      else
        v = nil
        break
      end
    end
  end
  if v ~= nil and docstring_cache[ v ] then
    return docstring_cache[ v ]
  end
  local s, n = s_match( str, "^([%a_][%w_%.]*)%.([%a_][%w_]*)$" )
  return s and try_require( s, n, ... )
end

local function lookup( v )
  local s = docstring_cache[ v ]
  if s ~= nil then
    return s
  end
  if type( v ) == "string" then
    return try_require( v )
  end
end


local function wrap( self, fun, writer )
  if self ~= M then
    self, fun, writer = M, self, fun
  end
  writer = writer or function( s ) print( s ) end
  return function( ... )
    local s = lookup( ... )
    if s then
      writer( s, ... )
    else
      fun( ... )
    end
  end
end


local delim = s_rep( "-", 70 )

local function search( self, s )
  if self ~= M then
    self, s = M, self
  end
  local first_match = true
  for v,ds in pairs( docstring_cache ) do
    if s_match( ds, s ) then
      if not first_match then
        print( delim )
      end
      print( ds )
      first_match = false
    end
  end
  if first_match then
    print( "no result found for `"..s.."'" )
  end
end


local M_meta = {
  __index = {
    wrap = wrap,
    search = search,
  },
  __call = function( _, topic )
    print( lookup( topic ) or
           "no help available for "..tostring( topic ) )
  end,
}

setmetatable( M, M_meta )
return M

