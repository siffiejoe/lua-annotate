#!/usr/bin/lua

package.path = [[../src/?.lua;]] .. package.path

if _VERSION == "Lua 5.1" then
  bit32 = {}
end

local annotate = require( "annotate" )
local check = require( "annotate.check" )
local test = require( "annotate.test" )
local help = require( "annotate.help" )

-- load https://github.com/dlaurie/lua-ihelp
local ldoc_help
pcall( function() ldoc_help = require( "ihelp" ) end )
ldoc_help = ldoc_help and help:wrap( ldoc_help )

package.preload[ "a.b" ] = function()
  return { c = { d = annotate[=[help for a.b.c.d]=]..{} } }
end

local delim = ("="):rep( 70 )

example = annotate[=[
An `annotate` docstring for the `example` function.

    example( number )
]=] ..
function( a ) end

--- An LDoc comment for `another` function
-- Details here ...
function another( a, b )
end


help( example )
print( "###" )
help( another )
print( "###" )
help( "a.b.c.d" )
print( "###" )

if ldoc_help then
  ldoc_help( another )
print( "###" )
  ldoc_help( example )
print( "###" )
  ldoc_help"a.b.c.d"
print( "###" )
  ldoc_help"customize"
print( "###" )
end

print( pcall( example, "not a number" ) )

print( delim )
help( bit32 )
print( delim )
help( assert )
print( delim )
help( "table.concat" )
print( delim )
print( "searching for getfenv:" )
help:search( "getfenv" )
print( delim )

local cache = {}
local pl = package.loaded
local ref_types = {
  ["function"] = true,
  ["userdata"] = true,
  ["table"] = true,
  ["thread"] = true
}

local function check_doc( name, value )
  name = name or "_G"
  value = value or _G
  local t = type( value )
  if not ref_types[ t ] then
    return
  end
  if not help:lookup( value ) then
    print( "no docstring for", name )
  end
  if t == "table" then
    cache[ value ] = true
    for k,v in pairs( value ) do
      if value ~= pl and type( k ) == "string" and
         k:match( "^[%a_][%w_]*$" ) and not cache[ v ] then
        check_doc( name.."."..k, v )
      end
    end
  end
end
check_doc()

--[[
for v,ds in help.iterate() do
  print( delim )
  print( ds )
end
--]]

print( delim )

test( tonumber( os.getenv( "VERBOSE" ) ) )

