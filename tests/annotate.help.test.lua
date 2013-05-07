#!/usr/bin/lua

package.path = [[../src/?.lua;]] .. package.path

local annotate = require( "annotate" )
local help = require( "annotate.help" )
require( "annotate.check" )
-- load https://github.com/dlaurie/lua-ihelp
local ldoc_help
pcall( function() ldoc_help = require( "help" ) end )
ldoc_help = ldoc_help and help:wrap( ldoc_help )

package.preload[ "a.b" ] = function()
  return { c = { d = annotate[=[help for a.b.c.d]=]..{} } }
end


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

