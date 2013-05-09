#!/usr/bin/lua

package.path = [[../src/?.lua;]] .. package.path

if _VERSION == "Lua 5.1" then
  bit32 = {}
end

local annotate = require( "annotate" )
local check = require( "annotate.check" )
local test = require( "annotate.test" )
check.enabled = false
local help = require( "annotate.help" )
check.enabled = true

-- load https://github.com/dlaurie/lua-ihelp
local ldoc_help
pcall( function() ldoc_help = require( "help" ) end )
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
help:search( "getfenv", help.ansi_highlight )
print( delim )

test( tonumber( os.getenv( "VERBOSE" ) ) )

