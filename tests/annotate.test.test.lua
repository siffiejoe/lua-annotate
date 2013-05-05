#!/usr/bin/lua

package.path = [[../src/?.lua;]] .. package.path

local annotate = require( "annotate" )
local test = require( "annotate.test" )


example = annotate[=[
An `annotate` docstring for the `example` function.

    example( number )

Examples:

    > print( "hallo\nwelt" )
    hallo
    welt
    > print( "ok" )
    ok

    > a, b = 3, 4
    > = a + b
    7

    > print( "[a-b]blub" )
    [a-b]...

Some other paragraph

]=] ..
function( a ) end


another = annotate[=[
##                      The `another` Function                      ##

This is just another function.

###                       Function Prototype                       ###

    another( a, b ) => boolean
        a: number
        b: string

###                            Examples                            ###

    > a = 2
    no output here
    > = 2+"x"
    ...attempt to perform arithmetic...
    > = 5
    4

]=] ..
function( a, b ) end


third = annotate[=[
Example:
    > = 2+"x"

Links:
    http://some.where.net/
]=] ..
function( x, y, z ) end


fourth = annotate[=[
Examples:

    > = nil

]=] ..
function() end

fifth = annotate[=[
Example:

    > function f()

]=] ..
function() end

sixth = annotate[=[
Example:

    > function f() return 2; return 3 end

]=] ..
function() end

test( tonumber( os.getenv( "VERBOSE" ) ) )

