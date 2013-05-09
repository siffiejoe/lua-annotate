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
  docstring_cache[ v ] = docstring
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

local _ -- dummy variable used later (a lot)

----------------------------------------------------------------------
-- base library

if check( _G, "_G", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                         Lua Base Library                         ##

Lua's base library defines the following global functions:

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
*   `unpack` -- Convert an array to multiple values (vararg).
*   `xpcall` -- Like `pcall`, but provide stack traces for errors.

Typically, the following libraries/tables are available:

*   `coroutine` -- Suspend/pause Lua code and resume it later.
*   `debug` -- Access debug information for Lua code.
*   `io` -- Input/output functions for files.
*   `math` -- Mathematical functions from C's standard library.
*   `os` -- Minimal interface to OS services.
*   `package` -- Settings/Functions for Loading Lua/C modules.
*   `string` -- Functions for manipulating strings.
*   `table` -- Functions for manipulating arrays.
]=] .. _G
elseif check( _G, "_G", 5.2 ) then
  _ = annotate[=[
##                         Lua Base Library                         ##

Lua's base library defines the following global functions:

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
*   `xpcall` -- Like `pcall`, but provide stack traces for errors.

Typically, the following libraries/tables are available:

*   `bit32` -- Bit manipulation for 32bit unsigned integers.
*   `coroutine` -- Suspend/pause Lua code and resume it later.
*   `debug` -- Access debug information for Lua code.
*   `io` -- Input/output functions for files.
*   `math` -- Mathematical functions from C's standard library.
*   `os` -- Minimal interface to OS services.
*   `package` -- Settings/Functions for Loading Lua/C modules.
*   `string` -- Functions for manipulating strings.
*   `table` -- Functions for manipulating arrays.
]=] .. _G
end

if check( _G, "assert", 5.1 ) then
  _ = annotate[=[
##                       The `assert` Function                      ##

    assert( cond, ... ) ==> any*
        cond: any     -- evaluated as a condition
        ... : any*    -- additional arguments

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
##                       The `pairs` Function                       ##

]=] .. _G.pairs
end

if check( _G, "unpack", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                       The `unpack` Function                      ##

    unpack( list [, i [, j]] ) ==> any*
        list: table    -- an array
        i   : integer  -- optional start index, defaults to 1
        j   : integer  -- optional end index, defaults to #list

The `unpack` function returns the elements of the array separately. An
optional start as well as end index can be specified. The start index
defaults to `1`, the end index to the length of the array as
determined by the length operator `#`. The array may contain holes,
but in this case explicit start and end indices must be given.

###                            Examples                            ###

    > =unpack( { 1, 2, 3, 4 } )
    1       2       3       4
    > =unpack( { 1, 2, 3, 4 }, 2 )
    2       3       4
    > =unpack( { 1, 2, 3 }, 2, 3 )
    2       3
    > =unpack( { 1, nil, nil, 4 }, 1, 4 )
    1       nil     nil     4
]=] .. _G.unpack
end

----------------------------------------------------------------------
-- bit32 library

if check( _G, "bit32", 5.2 ) then
  _ = annotate[=[
##                        Bitwise Operations                        ##

The following functions are provided by Lua's `bit32` library:

*   `bit32.arshift` -- Arithmetic bit-shift to the right.
*   `bit32.band` -- Perform bitwise and operation.
*   `bit32.bnot` -- Perform bitwise not operation.
*   `bit32.bor` -- Perform bitwise or operation.
*   `bit32.btest` -- Test if all arguments have a 1-bit in common.
*   `bit32.bxor` -- Perform bitwise exclusive or operation.
*   `bit32.extract` -- Extract a sub-range of bits.
*   `bit32.lrotate` -- Left bit-shift (bits re-enter on the right).
*   `bit32.lshift` -- Bit-shift to the left.
*   `bit32.replace` -- Replace a sub-range of bits.
*   `bit32.rrotate` -- Right bit-shift (bits re-enter on the left).
*   `bit32.rshift` -- Normal bit-shift to the right.
]=] .. bit32
end

if check( bit32, "arshift", 5.2 ) then
  _ = annotate[=[
##                   The `bit32.arshift` Function                   ##

]=] .. bit32.arshift
end

----------------------------------------------------------------------
-- coroutine library

if check( _G, "coroutine", 5.1 ) then
  _ = annotate[=[
##                      Coroutine Manipulation                      ##

The `coroutine` table, which is part of Lua's base library, contains
the following functions:

*   `coroutine.create` -- Create new coroutines.
*   `coroutine.resume` -- Resume coroutine where it last `yield`ed.
*   `coroutine.running` -- Get currently running coroutine.
*   `coroutine.status` -- Query status of a coroutine value.
*   `coroutine.wrap` -- Create coroutines, disguise them as functions.
*   `coroutine.yield` -- Suspend execution of current coroutine.
]=] .. coroutine
end

if check( coroutine, "create", 5.1 ) then
  _ = annotate[=[
##                  The `coroutine.create` Function                 ##

]=] .. coroutine.create
end

----------------------------------------------------------------------
-- debug library

if check( _G, "debug", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                         The Debug Library                        ##

Lua's `debug` library provides the following functions:

*   `debug.debug` -- Start a simple interactive prompt for debugging.
*   `debug.getfenv` -- Get environment for function or userdata.
*   `debug.gethook` -- Get current hook settings of a thread.
*   `debug.getinfo` -- Get general information about a function.
*   `debug.getlocal` -- Get name and value of a local variable.
*   `debug.getmetatable` -- Get metatable for any Lua object.
*   `debug.getregistry` -- Get reference to the Lua registry.
*   `debug.getupvalue` -- Get name and value of a function's upvalue.
*   `debug.setfenv` -- Set environment for function or userdata.
*   `debug.sethook` -- Register hook function for Lua code.
*   `debug.setlocal` -- Set the value of a local variable.
*   `debug.setmetatable` -- Set metatable on any Lua object.
*   `debug.setupvalue` -- Set the value of an upvalue for a function.
*   `debug.traceback` -- Traceback generator for `xpcall`
]=] .. debug
elseif check( _G, "debug", 5.2 ) then
  _ = annotate[=[
##                         The Debug Library                        ##

Lua's `debug` library provides the following functions:

*   `debug.debug` -- Start a simple interactive prompt for debugging.
*   `debug.getuservalue` -- Get the value associated with a userdata.
*   `debug.gethook` -- Get current hook settings of a thread.
*   `debug.getinfo` -- Get general information about a function.
*   `debug.getlocal` -- Get name and value of a local variable.
*   `debug.getmetatable` -- Get metatable for any Lua object.
*   `debug.getregistry` -- Get reference to the Lua registry.
*   `debug.getupvalue` -- Get name and value of a function's upvalue.
*   `debug.setuservalue` -- Associate a value with a userdata.
*   `debug.sethook` -- Register hook function for Lua code.
*   `debug.setlocal` -- Set the value of a local variable.
*   `debug.setmetatable` -- Set metatable on any Lua object.
*   `debug.setupvalue` -- Set the value of an upvalue for a function.
*   `debug.traceback` -- Traceback generator for `xpcall`
*   `debug.upvalueid` -- Uniquely identify an upvalue.
*   `debug.upvaluejoin` -- Make upvalue of function refer to another.
]=] .. debug
end

if check( debug, "debug", 5.1 ) then
  _ = annotate[=[
##                    The `debug.debug` Function                    ##

]=] .. debug.debug
end

----------------------------------------------------------------------
-- io library

if check( _G, "io", 5.1 ) then
  _ = annotate[=[
##                    Input and Output Facilities                   ##

Lua's `io` library contains the following fields/functions:

*   `io.close` -- Close a file or the default output stream.
*   `io.flush` -- Flush buffers for the default output stream.
*   `io.input` -- Get/Set the default input stream.
*   `io.lines` -- Iterate over the lines of the given file.
*   `io.open` -- Open a file for reading and/or writing.
*   `io.output` -- Get/set the default output stream.
*   `io.popen` -- Run program, read its output or write to its input.
*   `io.read` -- Read from the default input stream.
*   `io.stderr` -- File object for the standard error stream.
*   `io.stdin` -- File object for the standard input stream.
*   `io.stdout` -- File object for the standard output stream.
*   `io.tmpfile` -- Get a handle for a temporary file.
*   `io.type` -- Check if a value is a file object.
*   `io.write` -- Write to the default output stream.

Lua file handles have the following methods:

*   `file:close` -- Close the file object.
*   `file:flush` -- Flush output buffers for the file object.
*   `file:lines` -- Iterate over the lines of the given file object.
*   `file:read` -- Read bytes/lines from the file object
*   `file:seek` -- Set/get the file position where to read/write.
*   `file:setvbuf` -- Set buffering mode for an output file object.
*   `file:write` -- Write strings (or numbers) to a file object.
]=] .. io
end

if check( io, "close", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                      The `io.close` Function                     ##

]=] .. io.close
end

if check( io, "close", 5.2 ) then
  _ = annotate[=[
##                      The `io.close` Function                     ##

]=] .. io.close
end

if check( io, "flush", 5.1 ) then
  _ = annotate[=[
##                      The `io.flush` Function                     ##

]=] .. io.flush
end

if check( io, "stderr", 5.1 ) then
  _ = annotate[=[
##                    The `io.stderr` File Object                   ##

The `io.stderr` file object represents the `stderr` file stream of C
programs and is intended for error messages. Typically it is connected
to a console/terminal.

It supports the following methods:

*   `file:close` -- Close the file object.
*   `file:flush` -- Flush output buffers for the file object.
*   (`file:seek` -- Set/get the file position where to read/write.)
*   `file:setvbuf` -- Set buffering mode for an output file object.
*   `file:write` -- Write strings (or numbers) to a file object.

(The methods for input are available too, but make no sense for an
output file object.)
]=] .. io.stderr
end

if check( io, "stdin", 5.1 ) then
  _ = annotate[=[
##                    The `io.stdin` File Object                   ##

The `io.stdin` file object represents the `stdin` file stream of C
programs and is intended for user input. Typically it is connected to
a console/terminal.

It supports the following methods:

*   `file:close` -- Close the file object.
*   `file:lines` -- Iterate over the lines of the given file object.
*   `file:read` -- Read bytes/lines from the file object
*   (`file:seek` -- Set/get the file position where to read/write.)

(The methods for output are available too, but make no sense for an
input file object.)
]=] .. io.stdin
end

if check( io, "stdout", 5.1 ) then
  _ = annotate[=[
##                    The `io.stdout` File Object                   ##

The `io.stdout` file object represents the `stdout` file stream of C
programs and is intended for normal program output. By default it is
connected to a console/terminal.

It supports the following methods:

*   `file:close` -- Close the file object.
*   `file:flush` -- Flush output buffers for the file object.
*   (`file:seek` -- Set/get the file position where to read/write.)
*   `file:setvbuf` -- Set buffering mode for an output file object.
*   `file:write` -- Write strings (or numbers) to a file object.

(The methods for input are available too, but make no sense for an
output file object.)
]=] .. io.stdout
end

-- get access to file methods
local file
if type( debug ) == "table" and type( io ) == "table" then
  local getmeta = debug.getmetatable
  local handle = io.stdout or io.stderr or io.stdin
  if type( getmeta ) == "function" and
     type( handle ) == "userdata" then
    local m = getmeta( handle )
    if m and type( m.__index ) == "table" then
      file = m.__index
    end
  end
end

if check( file, "close", 5.1 ) then
  if io.close ~= file.close then
    _ = annotate[=[
##                     The `file:close()` Method                    ##

]=] .. file.close
  end
end

if check( file, "flush", 5.1 ) then
  if io.flush ~= file.flush then
    _ = annotate[=[
##                     The `file:flush()` Method                    ##

]=] .. file.flush
  end
end

----------------------------------------------------------------------
-- math library

if check( _G, "math", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                      Mathematical Functions                      ##

The following functions/values are available in Lua's `math` library:

*   `math.abs` -- Get positive value of a number.
*   `math.acos` -- Get arc cosine of a number (in radians).
*   `math.asin` -- Get arc sine of a number (in radians).
*   `math.atan` -- Get arc tangent of a number (in radians).
*   `math.atan2` -- Get arc tangent of y/x.
*   `math.ceil` -- Get nearest integer `>=` a number.
*   `math.cos` -- Get cosine of a number (in radians).
*   `math.cosh` -- Get hyperbolic cosine of a number (in radians).
*   `math.deg` -- Convert an angle from radians to degrees.
*   `math.exp` -- Calculate `e^x`.
*   `math.floor` -- Get nearest integer `<=´ a number.
*   `math.fmod` -- Calculate remainder of a division.
*   `math.frexp` -- Get significand and exponent of a Lua number.
*   `math.huge` -- Largest representable number (typically infinity).
*   `math.ldexp` -- Generate Lua number from significand and exponent.
*   `math.log` -- Calculate natural logarithm of a number.
*   `math.log10` -- Calculate base-10 logarithm of a number.
*   `math.max` -- Find maximum of a given set of numbers.
*   `math.min` -- Find minimum of a given set of numbers.
*   `math.modf` -- Get integral and fractional part of a Lua number.
*   `math.pi` -- The number PI.
*   `math.pow` -- Calculate `x^y`.
*   `math.rad` -- Convert an angle from degrees to radians.
*   `math.random` -- Generate pseudo-random number.
*   `math.randomseed` -- Initialize pseudo-random number generator.
*   `math.sin` -- Get sine of a number (in radians).
*   `math.sinh` -- Get hyperbolic sine of a number (in radians).
*   `math.sqrt` -- Calculate the square root of a number.
*   `math.tan` -- Get tangent of a number (in radians)
*   `math.tanh` -- Get hyperbolic tangent of a number (in radians).
]=] .. math
elseif check( _G, "math", 5.2 ) then
  _ = annotate[=[
##                      Mathematical Functions                      ##

The following functions are available in Lua's `math` library:

*   `math.abs` -- Get positive value of a number.
*   `math.acos` -- Get arc cosine of a number (in radians).
*   `math.asin` -- Get arc sine of a number (in radians).
*   `math.atan` -- Get arc tangent of a number (in radians).
*   `math.atan2` -- Get arc tangent of y/x.
*   `math.ceil` -- Get nearest integer `>=` a number.
*   `math.cos` -- Get cosine of a number (in radians).
*   `math.cosh` -- Get hyperbolic cosine of a number (in radians).
*   `math.deg` -- Convert an angle from radians to degrees.
*   `math.exp` -- Calculate `e^x`.
*   `math.floor` -- Get nearest integer `<=´ a number.
*   `math.fmod` -- Calculate remainder of a division.
*   `math.frexp` -- Get significand and exponent of a Lua number.
*   `math.huge` -- Largest representable number (typically infinity).
*   `math.ldexp` -- Generate Lua number from significand and exponent.
*   `math.log` -- Calculate logarithm of a number for a given base.
*   `math.max` -- Find maximum of a given set of numbers.
*   `math.min` -- Find minimum of a given set of numbers.
*   `math.modf` -- Get integral and fractional part of a Lua number.
*   `math.pi` -- The number PI.
*   `math.pow` -- Calculate `x^y`.
*   `math.rad` -- Convert an angle from degrees to radians.
*   `math.random` -- Generate pseudo-random number.
*   `math.randomseed` -- Initialize pseudo-random number generator.
*   `math.sin` -- Get sine of a number (in radians).
*   `math.sinh` -- Get hyperbolic sine of a number (in radians).
*   `math.sqrt` -- Calculate the square root of a number.
*   `math.tan` -- Get tangent of a number (in radians)
*   `math.tanh` -- Get hyperbolic tangent of a number (in radians).
]=] .. math
end

if check( math, "abs", 5.1 ) then
  _ = annotate[=[
##                      The `math.abs` Function                     ##

]=] .. math.abs
end

----------------------------------------------------------------------
-- os library

if check( _G, "os", 5.1 ) then
  _ = annotate[=[
##                    Operating System Facilities                   ##

Lua defines the following functions in its `os` library:

*   `os.clock` -- Calculate CPU time in seconds used by program.
*   `os.date` -- Formatting of dates/times.
*   `os.difftime` -- Calculate difference between two time values.
*   `os.execute` -- Run external programs using the OS's shell.
*   `os.exit` -- Quit currently running program.
*   `os.getenv` -- Query environment variables.
*   `os.remove` -- Remove a file in the file system.
*   `os.rename` -- Move/Rename a file in the file system.
*   `os.setlocale` -- Adapt runtime to different languages.
*   `os.time` -- Get a time value for a given date (or for now).
*   `os.tmpname` -- Get a file name usable as a temporary file.
]=] .. os
end

if check( os, "clock", 5.1 ) then
  _ = annotate[=[
##                      The `os.clock` Function                     ##

]=] .. os.clock
end

----------------------------------------------------------------------
-- package table

if check( _G, "package", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                         The Package Table                        ##

The `package` table, which is part of Lua's base library, contains the
following fields:

*   `package.config` -- Some settings from `luaconf.h`.
*   `package.cpath` -- Path template to look for C modules.
*   `package.loaded` -- Cache for already loaded modules.
*   `package.loaders` -- Functions used for finding/loading modules.
*   `package.loadlib` -- Function for loading shared libraries.
*   `package.path` -- Path template to look for Lua modules.
*   `package.preload` -- Table of loader functions for modules.
*   `package.seeall` -- Import global environment for modules.
]=] .. package
elseif check( _G, "package", 5.2 ) then
  _ = annotate[=[
##                         The Package Table                        ##

The `package` table, which is part of Lua's base library, contains the
following fields:

*   `package.config` -- Some settings from `luaconf.h`.
*   `package.cpath` -- Path template to look for C modules.
*   `package.loaded` -- Cache for already loaded modules.
*   `package.loadlib` -- Function for loading shared libraries.
*   `package.path` -- Path template to look for Lua modules.
*   `package.preload` -- Table of loader functions for modules.
*   `package.searchers` -- Functions used for finding/loading modules.
*   `package.searchpath` -- Search for a name using a path template.
]=] .. package
end

if check( package, "loaded", 5.1 ) then
  _ = annotate[=[
##                    The `package.loaded` Table                    ##

The `require` function caches every module it loads (or rather the
module's return value) in a table in the registry that is also
referenced by `package.loaded` to avoiding loading/running a module
more than once. Setting `package.loaded` to a new table has no effect
on `require`s behavior, since the cache table in the registry is
unchanged. `require` *will* return a module that you put there
manually, though.

###                            Examples                            ###

    > =package.loaded[ "annotate.help" ]
    table: ...
    > package.loaded[ "my.special.module" ] = "hello"
    > =require( "my.special.module" )
    hello
]=] .. package.loaded
end

if check( package, "loaders", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                    The `package.loaders` Table                   ##

`package.loaders` is a reference to an internal array of functions
that are used by `require` to find modules by a given name. The
default loaders in this table look for a field in `package.preload`
first, then try to find a Lua library via `package.path`/`LUA_PATH`,
and then resort to loading dynamic C libraries via `package.loadlib`
and `package.cpath`/`LUA_CPATH`. As it is just an alias, setting
`package.loaders` to a new table has no effect on module loading.
]=] .. package.loaders
end

if check( package, "loadlib", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                  The `package.loadlib` Function                  ##

    package.loadlib( libname, funcname ) ==> function    -- on success
                                         ==> nil, string -- on error
        libname : string  -- name of a DLL or shared object
        funcname: string  -- name of a lua_CFunction in the C library

The `package.loadlib` function loads and links the dynamic C library
with the given name and looks for the given function symbol in the
library. On success, the symbol is returned as a function, otherwise
nil and an error message is returned.
]=] .. package.loadlib
end

if check( package, "loadlib", 5.2 ) then
  _ = annotate[=[
##                  The `package.loadlib` Function                  ##

    package.loadlib( libname, funcname ) ==> function    -- on success
                                         ==> nil, string -- on error
        libname : string  -- name of a DLL or shared object
        funcname: string  -- name of a lua_CFunction in the C library

The `package.loadlib` function loads and links the dynamic C library
with the given name and looks for the given function symbol in the
library. On success, the symbol is returned as a function, otherwise
nil and an error message is returned. `funcname` may be `"*"` in which
case the library is linked and can serve as a prerequisite for other
dynamic C libraries, but no function is returned.
]=] .. package.loadlib
end

if check( package, "preload", 5.1 ) then
  _ = annotate[=[
##                    The `package.preload` Table                   ##

The `package.preload` table is a table (or rather an alias for a table
in the registry) the `require` function by default looks in before
attempting to load a module from a file. The table maps module names
to loader functions, that are called by `require` to load a module.
As it is just an alias, setting `package.preload` to a new table has
no effect on module loading.

###                            Examples                            ###

    >package.preload[ "my.special.mod" ] = function( name )
    >>   print( name )
    >>   return "hello again"
    >> end
    > =require( "my.special.mod" )
    my.special.mod
    hello again
    > =require( "my.special.mod" )
    hello again
]=] .. package.preload
end

if check( package, "searchers", 5.2 ) then
  _ = annotate[=[
##                   The `package.searchers` Table                  ##

`package.searchers` is a reference to an internal array of functions
that are used by `require` to find modules by a given name. The
default searchers in this table look for a field in `package.preload`
first, then try to find a Lua library via `package.path`/`LUA_PATH`,
and then resort to loading dynamic C libraries via `package.loadlib`
and `package.cpath`/`LUA_CPATH`. As it is just an alias, setting
`package.searchers` to a new table has no effect on module loading.
]=] .. package.searchers
end

if check( package, "searchpath", 5.2 ) then
  _ = annotate[=[
##                 The `package.searchpath` Function                ##

    package.searchpath( name, path [, sep [, rep]] )
            ==> string
            ==> nil, string
        name: string  -- name to look for
        path: string  -- path template used for searching
        sep : string  -- sub-string in name to replace, "." by default
        rep : string  -- replacement for any sep occurrences in name,
                      -- the platform's directory separator by default

The `package.searchpath` function iterates the `;`-separated elements
in the `path` template, after substituting each `?` in the template
with a modified `name` where each occurrence of `sep` in `name` is
replaced by `rep`. Returns the first file that can be opened for
reading, or nil and a message listing all file paths tried. The
default value for `sep` is `"."`, the default for `rep` is the Lua
directory separator listed in `package.config` (and defined in
`luaconf.h`).

###                            Examples                            ###

    > =package.searchpath( "my.weird.f_name", "./?.x;?.t", nil, "/" )
    nil
            no file './my/weird/f_name.x'
            no file 'my/weird/f_name.t'
    > =package.searchpath( "my.weird.f_name", "?.t_t", "_", "X" )
    nil
            no file 'my.weird.fXname.t_t'
]=] .. package.searchpath
end

if check( package, "seeall", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                   The `package.seeall` Function                  ##

    package.seeall( module )
        module: table  -- the module table

The `package.seeall` function usually is not called directly, but
passed as the second argument to the `module` function to make the
global environment available inside the module's code by setting a
metatable with an `__index` metamethod for the module table.
]=] .. package.seeall
end

----------------------------------------------------------------------
-- string library

if check( _G, "string", 5.1 ) then
  _ = annotate[=[
##                        String Manipulation                       ##

Lua's `string` library provides the following functions, which by
default can also be called using method syntax:

*   `string.byte` -- Convert strings to numerical character codes.
*   `string.char` -- Convert numerical character codes to strings.
*   `string.dump` -- Dump a functions bytecode as a string.
*   `string.find` -- Find start/stop indices of a pattern match.
*   `string.format` -- Generate string according to format spec.
*   `string.gmatch` -- Iterate over matching sub-strings.
*   `string.gsub` -- Replace parts of a string.
*   `string.len` -- Get a strings length in bytes.
*   `string.lower` -- Turn uppercase letters to lowercase.
*   `string.match` -- Try to match a string to a pattern.
*   `string.rep` -- Repeat and concatenate a string `n` times.
*   `string.reverse` -- Reverse bytes in a string.
*   `string.sub` -- Extract sub-string.
*   `string.upper` -- Turn lowercase letters to uppercase.
]=] .. string
end

if check( string, "byte", 5.1 ) then
  _ = annotate[=[
##                    The `string.byte` Function                    ##

]=] .. string.byte
end

----------------------------------------------------------------------
-- table library

if check( _G, "table", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                        Table Manipulation                        ##

The following functions are defined in Lua's `table` library:

*   `table.concat` -- Concatenate strings of an array int one string.
*   `table.insert` -- Insert an element anywhere in an array.
*   `table.maxn` -- Determine largest positive numerical integer key.
*   `table.remove` -- Remove one element anywhere in an array.
*   `table.sort` -- Sort the elements of an array in-place.
]=] .. _G.table
elseif check( _G, "table", 5.2 ) then
  _ = annotate[=[
##                        Table Manipulation                        ##

The following functions are defined in Lua's `table` library:

*   `table.concat` -- Concatenate strings of an array int one string.
*   `table.insert` -- Insert an element anywhere in an array.
*   `table.pack` -- Convert an argument list to an array.
*   `table.remove` -- Remove one element anywhere in an array.
*   `table.sort` -- Sort the elements of an array in-place.
*   `table.unpack` -- Convert an array to multiple values (vararg).
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

The `table.concat` function converts the elements of an array into
strings (if they are numbers) and joins them together to a single
string which is returned. An optional separator is inserted between
every element pair. Optional start and end indices allow for selecting
a sub-range of the array. If an element is encountered that is neither
number nor string, an error is raised. An empty array (or sub-range)
results in the empty string `""`. All table accesses do not trigger
metamethods.

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

if check( table, "insert", 5.1 ) then
  _ = annotate[=[
##                    The `table.insert` Function                   ##

    table.insert( list, [pos,] value )
        list : table    -- an array
        pos  : integer  -- index where to insert, defaults to #list+1
        value: any      -- value to insert

The `table.insert` function inserts a value at the given position into
an array, shifting all following array elements by one. If no position
is given (the function is called with two arguments), the value is
appended to the end of the array. All table accesses do not trigger
metamethods. The array must *not* contain holes!

###                            Examples                            ###

    > t = { 1, 2, 3 }
    > table.insert( t, 4 )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ]
    1       2       3       4
    > table.insert( t, 2, 1.5 )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ], t[ 5 ]
    1       1.5     2       3       4
]=] .. table.insert
end

if check( table, "maxn", V >= 5.1 and V < 5.2 ) then
  _ = annotate[=[
##                     The `table.maxn` Function                    ##

    table.maxn( table ) ==> number

The `table.maxn` function traverses the whole table to look for the
largest positive numeric key and returns it. If no such key is found,
`0` is returned. The table may contain holes and non-integer numeric
keys. If it doesn't, this function is equivalent to applying the
length operator (`#`) on the table.

###                            Examples                            ###

    > t = { 1, 2, 3, 4 }
    > =#t, table.maxn( t )
    4       4
    > =table.maxn( { 1, 2, 3, [ 10 ]=10, [ 12.5 ]=12.5 } )
    12.5
    > =table.maxn( { a=1 } )
    0
]=] .. table.maxn
end

if check( table, "pack", 5.2 ) then
  _ = annotate[=[
##                     The `table.pack` Function                    ##

    table.pack( ... ) ==> table

The `table.pack` function collects all its arguments in an array and
returns it. The `n` field of the returned table is set to the number
of vararg/array elements (including `nil`s). Since varargs can contain
`nil`s, the resulting table might contain holes and thus not be a
proper array.

###                            Examples                            ###

    > t = table.pack( 1, 2, 3 )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t.n
    1       2       3       3
    > t = table.pack( "a", "b", nil, "d" )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ], t.n
    a       b       nil     d       4

]=] .. table.pack
end

if check( table, "remove", 5.1 ) then
  _ = annotate[=[
##                    The `table.remove` Function                   ##

    table.remove( list [, pos] ) ==> any
        list: table    -- an array
        pos : integer  -- index of value to remove, defaults to #list

The `table.remove` function removes the value at the given position
from the array and returns it. The following array elements are
shifted by one to close the gap. If no position is given, the last
array element is removed. All table accesses do not trigger
metamethods. The array must *not* contain holes!

###                            Examples                            ###

    > t = { 1, 2, 3, 4, 5 }
    > =table.remove( t )
    5
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ], t[ 5 ]
    1       2       3       4       nil
    > =table.remove( t, 2 )
    2
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ]
    1       3       4       nil
]=] .. table.remove
end

if check( table, "sort", 5.1 ) then
  _ = annotate[=[
##                     The `table.sort` Function                    ##

    table.sort( list [, comp] )
        list: table     -- an array
        comp: function  -- comparator function, defaults to <

The `table.sort` function sorts the elements of an array in-place
using a comparator function to determine the intended order of the
elements. The comparator function takes two array elements as
arguments and should return a true value if the first array element
should end up *before* the second in the sorted array. If no
comparator function is given, Lua's `<`-operator is used. All table
accesses do not trigger metamethods, and the array must *not* contain
holes! The sort algorithm is not stable.

###                            Examples                            ###

    > t = { 3, 2, 5, 1, 2, 4 }
    > table.sort( t )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ], t[ 5 ], t[ 6 ]
    1       2       2       3       4       5
    > t = { 3, 2, 5, 1, 2, 4 }
    > table.sort( t, function( a, b ) return a > b end )
    > =t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ], t[ 5 ], t[ 6 ]
    5       4       3       2       2       1
]=] .. table.sort
end

if check( table, "unpack", 5.2 ) then
  _ = annotate[=[
##                    The `table.unpack` Function                   ##

    table.unpack( list [, i [, j]] ) ==> any*
        list: table    -- an array
        i   : integer  -- optional start index, defaults to 1
        j   : integer  -- optional end index, defaults to #list

The `table.unpack` function returns the elements of the array
separately. An optional start as well as end index can be specified.
The start index defaults to `1`, the end index to the length of the
array as determined by the length operator `#`. The array may contain
holes, but in this case explicit start and end indices must be given.

###                            Examples                            ###

    > =table.unpack( { 1, 2, 3, 4 } )
    1       2       3       4
    > =table.unpack( { 1, 2, 3, 4 }, 2 )
    2       3       4
    > =table.unpack( { 1, 2, 3 }, 2, 3 )
    2       3
    > =table.unpack( { 1, nil, nil, 4 }, 1, 4 )
    1       nil     nil     4
]=] .. table.unpack
end

----------------------------------------------------------------------

local M = {}


local function trim( s )
  return (s_gsub( s, "^%s*(.-)%s*$", "%1" ))
end


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
    return trim( docstring_cache[ v ] )
  end
  local s, n = s_match( str, "^([%a_][%w_%.]*)%.([%a_][%w_]*)$" )
  return s and try_require( s, n, ... )
end


local function lookup( self, v )
  if self ~= M then
    self, v = M, self
  end
  local s = docstring_cache[ v ]
  if s ~= nil then
    return trim( s )
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
    local s = lookup( self, ... )
    if s then
      writer( s, ... )
    else
      fun( ... )
    end
  end
end


local delim = s_rep( "-", 70 )
local ansi_high = "\027[34;40;1m"
local ansi_reset = "\027[39;49;0m"

local function ansi_highlight( v )
  return ansi_high .. v .. ansi_reset
end

local function search( self, s, hilighter )
  if self ~= M then
    self, s, hilighter = M, self, s
  end
  local first_match = true
  for v,ds in pairs( docstring_cache ) do
    if s_match( ds, s ) then
      if not first_match then
        print( delim )
      end
      if type( hilighter ) == "function" then
        print( trim( s_gsub( ds, "("..s..")" , hilighter ) ) )
      else
        print( trim( ds ) )
      end
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
    lookup = lookup,
    search = search,
    ansi_highlight = ansi_highlight,
  },
  __call = function( _, topic )
    print( lookup( M, topic ) or
           "no help available for "..tostring( topic ) )
  end,
}

setmetatable( M, M_meta )
return M

