#!/usr/bin/lua

-- show actual error messages (or not)
local verbose = os.getenv( "VERBOSE" )

package.path = [[../src/?.lua;]] .. package.path
-- for testing different lpeg versions:
package.cpath = [[./?.so;./?.dll;]] .. package.cpath

local annotate = require( "annotate" )
local check = require( "annotate.check" )

check.enabled = true
check.arguments = true
check.return_values = true

-- type checking function for custom type
function check.types.mytable( v )
  return type( v ) == "table" and v.is_mytable
end

-- create values of custom type
local function mytable_new()
  return { is_mytable = true }
end


-- testing functions
local function succeeds( what, f, ... )
  print( "", ">>>>", what )
  local ok, msg = pcall( f, ... )
  if not ok then
    error( msg:gsub( "%s*$", "" ), 0 )
  elseif verbose then
    print( "", "", "ok." )
  end
end

local function fails( what, epattern, f, ... )
  print( "", ">>>>", what )
  local ok, msg = pcall( f, ... )
  if ok then
    error( "unexpected success", 0 )
  elseif not msg:match( epattern ) then
    error( "unexpected error: " .. msg:gsub( "%s*$", "" ), 0 )
  elseif verbose then
    print( "", "", (msg:gsub( "%s*$", "" )) )
  end
end

local function test_all( what, testf )
  print( ">>>> testing", what )
  local ok, msg = pcall( testf )
  if not ok then
    print( "[FAIL]", (msg:gsub( "%s*$", "" )) )
  else
    print( "[ ok ]" )
  end
end

local function test_error( what, epattern, testf )
  print( ">>>> testing", what )
  local ok, msg = pcall( testf )
  if ok then
    print( "[FAIL] test did not raise an error at all!" )
  elseif not msg:match( epattern ) then
    print( "[FAIL] unexpected error message:\n", msg )
  elseif verbose then
    print( "[ ok ]", (msg:gsub( "%s*$", "" )) )
  else
    print( "[ ok ]" )
  end
end



-- some incorrect type specifications
test_error( "missing type specification", "does not contain type spec",  function()
local func = annotate[=[
Some text.

But no type specification!
]=] .. function() end
end )

test_error( "undefined argument", "argument.*not defined", function()
local func = annotate[=[
func( a ) => number
]=] .. function() end
end )

test_error( "undefined return value type", "type.*is undefined", function()
local func = annotate[=[
func( number ) => n
]=] .. function() end
end )

test_error( "argument name reused", "argument.*multiple times", function()
local func = annotate[=[
func( a, a ) => number
  a: number
]=] .. function() end
end )

test_error( "argument type redefined", "argument.*redefined", function()
local func = annotate[=[
func( a ) => number
  a: number
  a: integer
]=] .. function() end
end )

test_error( "undefined argument type", "type.*is undefined", function()
local func = annotate[=[
func( a ) => number
  a: abc
]=] .. function() end
end )


-- examples from the readme
test_all( "pcall", function()
  annotate[=[
    pcall( f [, arg1, ...] ) ==> boolean, any*
        f   : function  -- the function to call in protected mode
        arg1: any       -- first argument to f
        ... : any*      -- remaining arguments to f
  ]=]
end )
test_all( "tonumber", function()
  annotate[=[
    tonumber( any [, number] ) ==> nil/number
  ]=]
end )
test_all( "table.concat", function()
  annotate[=[
    table.concat( list [, sep [, i [, j]]] ) ==> string
        list: table     -- an array of strings
        sep : string    -- a separator, defaults to ""
        i   : integer   -- starting index, defaults to 1
        j   : integer   -- end index, defaults to #list
  ]=]
end )
test_all( "table.insert", function()
  annotate[=[
    table.insert( list, [pos,] value )
        list : table    -- an array
        pos  : integer  -- index where to insert (defaults to #list)
        value: any      -- value to insert
  ]=]
end )
test_all( "io.open", function()
  annotate[=[
    io.open( filename [, mode] )
            ==> file               -- on success
            ==> nil,string,number  -- in case of error
        filename: string           -- the name of the file
        mode    : string           -- flags similar to fopen(3)
  ]=]
end )
test_all( "file:read", function()
  annotate[=[
    file:read( ... ) ==> (string/number/nil)*
        ...: (string/number)*      -- format specifiers
  ]=]
end )
test_all( "file:seek", function()
  annotate[=[
    file:seek( [whence [, offset]] ) ==> number
                                     ==> nil, string
        self  : file               -- would default to `object`
        whence: string
        offset: number
  ]=]
end )
test_all( "os.execute", function()
  annotate[=[
    os.execute( [string] )
            ==> boolean
            ==> boolean/nil, string, number
  ]=]
end )
test_all( "mod.obj:method", function()
  annotate[=[
    mod.obj:method( [a [, b] [, c],] [d,] ... )
            ==> boolean            -- when successful
            ==> nil, string        -- in case of error
          a: string/function       -- a string or a function
          b: userdata              -- a userdata
                                   -- don't break the paragraph!
          c: boolean               -- a boolean flag
          d: number                -- a number
        ...: ((table, string/number) / boolean)*
  ]=]
end )


-- arguments
test_all( "func( number/boolean ) ==> number", function()
  local func = annotate[[
  func( n ) ==> number
    n: number/boolean
  ]] ..
  function() return 1 end

  succeeds( "func( 12 )", func, 12 )
  succeeds( "func( false )", func, false )
  fails( "func( 12, 13 )", "too many arguments", func, 12, 13 )
  fails( "func()", "missing argument", func )
  fails( "func( 'x' )", "expected.*got string", func, "x" )
end )


-- return values
test_all( "func( number ) ==> number/string, string", function()
  local func = annotate[[
  func( number ) ==> number/string, string
  ]] ..
  function( n )
    if n == 1 then
      return 1, "nix"
    elseif n == 2 then
      return "nix", "da"
    elseif n == 3 then
      return 1, "nix", 2
    elseif n == 4 then
      return
    elseif n == 5 then
      return false
    end
  end

  succeeds( "func( 1 ) ==> 1, 'nix'", func, 1 )
  succeeds( "func( 2 ) ==> 'nix', 'da'", func, 2 )
  fails( "func( 3 ) ==> 1, 'nix', 2", "too many return values", func, 3 )
  fails( "func( 4 )", "missing return value", func, 4 )
  fails( "func( 5 ) ==> false", "expected.*got boolean", func, 5 )
end )


-- optional arguments and varargs
test_all( "func( [string [, userdata] [, boolean],] [number,] ... )", function()
  local func = annotate[=[
  func( [string [, userdata] [, boolean],] [number,] ... )
    ...: ((table, string/number) / boolean)*
  ]=] ..  function() end

  succeeds( "func()", func )
  succeeds( "func( 'a' )", func, "a" )
  succeeds( "func( 'a', io.stdout )", func, "a", io.stdout )
  succeeds( "func( 'a', true )", func, "a", true )
  succeeds( "func( 'a', io.stdout, true )", func, "a", io.stdout, true )
  succeeds( "func( 12 )", func, 12 )
  succeeds( "func( 'a', 12 )", func, "a", 12 )
  succeeds( "func( 12, {}, 'b', false, true, {}, 13 )", func, 12, {}, "b", false, true, {}, 13 )
  fails( "func( io.stdout )", "expected.*got userdata.*too many", func, io.stdout )
  fails( "func( 'a', 12, {}, false )", "expected.*got boolean", func, "a", 12, {}, false )
end )


-- methods
test_all( "obj:method( number )", function()
  local obj = {}
  obj.method = annotate[[
  obj:method( number )
  ]] .. function() end

  succeeds( "obj:method( 12 )", obj.method, obj, 12 )
  fails( "obj:method()", "missing.*index 1", obj.method, obj )
  fails( "obj.method( 12 )", "expected.*no%. 0.*got number", obj.method, 12 )
  fails( "obj.method()", "missing.*index 0", obj.method )
end )


-- custom type
test_all( "func( number [, table], mytable ) ==> (table, boolean) / (mytable, number) ", function()
  local func = annotate[[
  func( number, [table,] mytable ) ==> table, boolean
                                   ==> mytable, number
  ]] .. function( n )
    if n == 1 then
      return {}, true
    elseif n == 2 then
      return mytable_new(), 2
    else
      return mytable_new(), "bla"
    end
  end

  succeeds( "func( 1, {}, mytable_new() )", func, 1, {}, mytable_new() )
  succeeds( "func( 1, mytable_new() )", func, 1, mytable_new() )
  succeeds( "func( 2, mytable_new() )", func, 2, mytable_new() )
  fails( "func( 2, mytable_new(), {} )", "mytable expected.*got table.*too many arguments", func, 1, mytable_new(), {} )
  fails( "func( 3, mytable_new() )", "expected.*got string.*expected.*got string", func, 3, mytable_new() )
end )


-- complex example
test_all( "obj:method( a [, b [, c], ...] ) ==> boolean / (nil, string)", function()
  local obj = {}
  obj.method = annotate[=[
  Some optional text (ignored)!

  obj:method( a [, b [, c], ...] )
         ==>  boolean         -- when successful
         ==>  nil, string     -- in case of error
      a: integer              -- an integer
      b: table/userdata       -- an optional table or userdata
                              -- comments can span several lines
      c: boolean              -- a boolean flag
    ...: (number, string)*

  Some more text describing the function:
  ignored!
  ]=] .. function( self, i )
    if i == 1 then
      return true
    elseif i == 2 then
      return nil, "msg"
    elseif i == 3 then
      return nil
    elseif i == 4 then
      return 17
    else
      return "abc"
    end
  end
  succeeds( "obj:method( 1 )", obj.method, obj, 1 )
  succeeds( "obj:method( 2, {}, 4, 'four', 5, 'five' )", obj.method, obj, 2, {}, 4, "four", 5, "five" )
  succeeds( "obj:method( 2, io.stdout, true )", obj.method, obj, 2, io.stdout, true )
  fails( "obj.method( 1 )", "expected.*no%. 0.*got number", obj.method, 1 )
  fails( "obj:method( 1.5 )", "integer expected.*got number", obj.method, obj, 1.5 )
  fails( "obj:method( 2, true )", "expected.*got boolean.*too many arguments", obj.method, obj, 2, true )
  fails( "obj:method( 2, 4, 'four' )", "expected.*got number.*too many arguments", obj.method, obj, 2, 4, "four" )
  fails( "obj:method( 3 )", "missing return.*string", obj.method, obj, 3 )
  fails( "obj:method( 4 )", "expected.*return value.*got number", obj.method, obj, 4 )
  fails( "obj:method( 5 )", "expected.*return value.*got string", obj.method, obj, 5 )
end )

