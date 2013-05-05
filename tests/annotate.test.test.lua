#!/usr/bin/lua

package.path = [[../src/?.lua;]] .. package.path

local annotate = require( "annotate" )
local test = require( "annotate.test" )


example = annotate[=[
An `annotate` docstring for the `example` function.

    example( number )

#                               Example                              #

    > print( "hallo\nwelt" )
    hallo
    welt
    > print( "ok" )
    ok

    > print( a + b )
    7

Some other paragraph

]=] ..
function( a ) end


