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

-- disable type checking temporarily
local ARG_C, RET_C = false, false
if type( package ) == "table" then
  local p_loaded = package.loaded
  if type( p_loaded ) == "table" then
    local c = p_loaded[ "annotate.check" ]
    if type( c ) == "table" then
      ARG_C, RET_C = c.arguments, c.return_values
      c.arguments, c.return_values = false, false
    end
  end
end

local A

----------------------------------------------------------------------
-- base library

if check( _G, "_G", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  assert( A == _G, "_G modified by annotate plugin" )
end

if check( _G, "_G", 5.2 ) then
  A = annotate[=[
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
  assert( A == _G, "_G modified by annotate plugin" )
end

if check( _G, "assert", 5.1 ) then
  A = annotate[=[
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
    ...: my error message
    stack traceback:
            ...
    > function f() return nil end
    > assert( f() )
    ...: assertion failed!
    stack traceback:
            ...
]=] .. _G.assert
  if A ~= _G.assert then _G.assert = A end
end

if check( _G, "collectgarbage", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                   The `collectgarbage` Function                  ##

    collectgarbage( [opt [, arg]] ) ==> number/boolean
        opt: string   -- one of a set of commands
        arg: integer
]=] .. _G.collectgarbage
  if A ~= _G.collectgarbage then _G.collectgarbage = A end
end

if check( _G, "collectgarbage", 5.2 ) then
  A = annotate[=[
##                   The `collectgarbage` Function                  ##

    collectgarbage( [opt [, arg]] ) ==> number, integer
                                    ==> integer
                                    ==> boolean
        opt: string   -- one of a set of commands
        arg: integer
]=] .. _G.collectgarbage
  if A ~= _G.collectgarbage then _G.collectgarbage = A end
end

if check( _G, "dofile", 5.1 ) then
  A = annotate[=[
##                       The `dofile` Function                      ##

    dofile( [filename] ) ==> any*
        filename: string  -- file name to load and run
]=] .. _G.dofile
  if A ~= _G.dofile then _G.dofile = A end
end

if check( _G, "error", 5.1 ) then
  A = annotate[=[
##                       The `error` Function                       ##

    error( message [, level] )
        message: any      -- an error message (typically a string)
        level  : integer  -- stack level where the error is raised
]=] .. _G.error
  if A ~= _G.error then _G.error = A end
end

if check( _G, "getfenv", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                      The `getfenv` Function                      ##

    getfenv( [f] ) ==> table/nil
        f: function/integer  -- a function or a stack index
]=] .. _G.getfenv
  if A ~= _G.getfenv then _G.getfenv = A end
end

if check( _G, "getmetatable", 5.1 ) then
  A = annotate[=[
##                    The `getmetatable` Function                   ##

    getmetatable( object ) ==> table/nil
]=] .. _G.getmetatable
  if A ~= _G.getmetatable then _G.getmetatable = A end
end

if check( _G, "ipairs", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                       The `ipairs` Function                      ##

    ipairs( table ) ==> function, (any, any?)?
]=] .. _G.ipairs
  if A ~= _G.ipairs then _G.ipairs = A end
end

if check( _G, "ipairs", 5.2 ) then
  A = annotate[=[
##                       The `ipairs` Function                      ##

    ipairs( object ) ==> function, (any, any?)?
]=] .. _G.ipairs
  if A ~= _G.ipairs then _G.ipairs = A end
end

if check( _G, "load", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                        The `load` Function                       ##

    load( func [, chunkname] ) ==> function     -- on success
                               ==> nil, string  -- in case of error
        func     : function  -- function to produce Lua code
        chunkname: string    -- name to use in error messages
]=] .. _G.load
  if A ~= _G.load then _G.load = A end
end

if check( _G, "load", 5.2 ) then
  A = annotate[=[
##                        The `load` Function                       ##

    load( ld [, source [, mode [, env]]] ) ==> function     -- success
                                           ==> nil, string  -- error
        ld    : function/string  -- (function producing) Lua code
        source: string           -- name of the chunk for messages
        mode  : string           -- allow text/binary Lua code
        env   : table            -- the environment to load in
]=] .. _G.load
  if A ~= _G.load then _G.load = A end
end

if check( _G, "loadfile", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                      The `loadfile` Function                     ##

    loadfile( [filename] ) ==> function     -- on success
                           ==> nil, string  -- in case of error
        filename: string  -- file name to load
]=] .. _G.loadfile
  if A ~= _G.loadfile then _G.loadfile = A end
end

if check( _G, "loadfile", 5.2 ) then
  A = annotate[=[
##                      The `loadfile` Function                     ##

    loadfile( [filename [, mode [, env ]]] ) ==> function     -- ok
                                             ==> nil, string  -- error
        filename: string  -- file name to load
        mode    : string  -- allow text/binary Lua code
        env     : table   -- the environment to load in
]=] .. _G.loadfile
  if A ~= _G.loadfile then _G.loadfile = A end
end

if check( _G, "loadstring", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                     The `loadstring` Function                    ##

    loadstring( string [, chunkname] ) ==> function     -- on success
                                       ==> nil, string  -- on error
        chunkname: string  -- name used in error messages
]=] .. _G.loadstring
  if A ~= _G.loadstring then _G.loadstring = A end
end

if check( _G, "module", V >= 5.1 and V < 5.3 ) then
  A = annotate[=[
##                       The `module` Function                      ##

    module( name [, ...] )
        name: string     -- the module name as passed to require
        ... : function*  -- options/modifiers for the module
]=] .. _G.module
  if A ~= _G.module then _G.module = A end
end

if check( _G, "next", 5.1 ) then
  A = annotate[=[
##                        The `next` Function                       ##

    next( table [, index] ) ==> any, any?
        index: any  -- current key in table, defaults to nil
]=] .. _G.next
  if A ~= _G.next then _G.next = A end
end

if check( _G, "pairs", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                       The `pairs` Function                       ##

    pairs( table ) ==> function, (any, any?)?
]=] .. _G.pairs
  if A ~= _G.pairs then _G.pairs = A end
end

if check( _G, "pairs", 5.2 ) then
  A = annotate[=[
##                       The `pairs` Function                       ##

    pairs( object ) ==> function, (any, any?)?
]=] .. _G.pairs
  if A ~= _G.pairs then _G.pairs = A end
end

if check( _G, "pcall", 5.1 ) then
  A = annotate[=[
##                       The `pcall` Function                       ##

    pcall( function, ... ) ==> boolean, any*
        ...: any*  -- arguments for the function
]=] .. _G.pcall
  if A ~= _G.pcall then _G.pcall = A end
end

if check( _G, "print", 5.1 ) then
  A = annotate[=[
##                       The `print` Function                       ##

    print( ... )
        ...: any*  -- values to print
]=] .. _G.print
  if A ~= _G.print then _G.print = A end
end

if check( _G, "rawequal", 5.1 ) then
  A = annotate[=[
##                      The `rawequal` Function                     ##

    rawequal( v1, v2 ) ==> boolean
        v1: any
        v2: any
]=] .. _G.rawequal
  if A ~= _G.rawequal then _G.rawequal = A end
end

if check( _G, "rawget", 5.1 ) then
  A = annotate[=[
##                       The `rawget` Function                      ##

    rawget( table, index ) ==> any
        index: any  -- key to query table for
]=] .. _G.rawget
  if A ~= _G.rawget then _G.rawget = A end
end

if check( _G, "rawlen", 5.2 ) then
  A = annotate[=[
##                       The `rawlen` Function                      ##

    rawlen( v ) ==> integer
      v: string/table
]=] .. _G.rawlen
  if A ~= _G.rawlen then _G.rawlen = A end
end

if check( _G, "rawset", 5.1 ) then
  A = annotate[=[
##                       The `rawset` Function                      ##

    rawset( table, index, value )
        index: any  -- key to use
        value: any  -- value to add to the table
]=] .. _G.rawset
  if A ~= _G.rawset then _G.rawset = A end
end

if check( _G, "require", 5.1 ) then
  A = annotate[=[
##                      The `require` Function                      ##

    require( modname ) ==> any
        modname: string  -- the name of the module to load
]=] .. _G.require
  if A ~= _G.require then _G.require = A end
end

if check( _G, "select", 5.1 ) then
  A = annotate[=[
##                       The `select` Function                      ##

    select( index, ... ) ==> any*
        index: string/integer  -- index to select or `"#"`
        ...  : any*            -- varargs
]=] .. _G.select
  if A ~= _G.select then _G.select = A end
end

if check( _G, "setfenv", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                      The `setfenv` Function                      ##

    setfenv( f, table ) ==> function?
        f: function/integer  -- (stack index of) function to modify
]=] .. _G.setfenv
  if A ~= _G.setfenv then _G.setfenv = A end
end

if check( _G, "setmetatable", 5.1 ) then
  A = annotate[=[
##                    The `setmetatable` Function                   ##

    setmetatable( table, metatable ) ==> table
        metatable: table/nil  -- table to use as a metatable
]=] .. _G.setmetatable
  if A ~= _G.setmetatable then _G.setmetatable = A end
end

if check( _G, "tonumber", 5.1 ) then
  A = annotate[=[
##                      The `tonumber` Function                     ##

    tonumber( v [, base] ) ==> nil/number
        v   : any     -- value to convert
        base: integer -- base for conversion if not decimal
]=] .. _G.tonumber
  if A ~= _G.tonumber then _G.tonumber = A end
end

if check( _G, "tostring", 5.1 ) then
  A = annotate[=[
##                      The `tostring` Function                     ##

    tostring( any ) ==> string
]=] .. _G.tostring
  if A ~= _G.tostring then _G.tostring = A end
end

if check( _G, "type", 5.1 ) then
  A = annotate[=[
##                        The `type` Function                       ##

    type( any ) ==> string
]=] .. _G.type
  if A ~= _G.type then _G.type = A end
end

if check( _G, "unpack", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  if A ~= _G.unpack then _G.unpack = A end
end

if check( _G, "xpcall", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                       The `xpcall` Function                      ##

    xpcall( function, err ) ==> boolean, any*
        err: function  -- error handler (for producing stack traces)
]=] .. _G.xpcall
  if A ~= _G.xpcall then _G.xpcall = A end
end

if check( _G, "xpcall", 5.2 ) then
  A = annotate[=[
##                       The `xpcall` Function                      ##

    xpcall( function, err, ... ) ==> boolean, any*
        err: function  -- error handler (for producing stack traces)
        ...: any*      -- arguments for the function
]=] .. _G.xpcall
  if A ~= _G.xpcall then _G.xpcall = A end
end

----------------------------------------------------------------------
-- bit32 library

if check( _G, "bit32", 5.2 ) then
  A = annotate[=[
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
  assert( A == bit32, "bit32 table modified by annotate plugin" )
end

if check( bit32, "arshift", 5.2 ) then
  A = annotate[=[
##                   The `bit32.arshift` Function                   ##

    bit32.arshift( number [, disp] ) ==> integer
        disp: integer  -- number of bits to shift
]=] .. bit32.arshift
  if A ~= bit32.arshift then bit32.arshift = A end
end

----------------------------------------------------------------------
-- coroutine library

if check( _G, "coroutine", 5.1 ) then
  A = annotate[=[
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
  assert( A == coroutine, "coroutine table modified by annotate plugin" )
end

if check( coroutine, "create", 5.1 ) then
  A = annotate[=[
##                  The `coroutine.create` Function                 ##

    coroutine.create( function ) ==> thread
]=] .. coroutine.create
  if A ~= coroutine.create then coroutine.create = A end
end

----------------------------------------------------------------------
-- debug library

if check( _G, "debug", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  assert( A == debug, "debug table modified by annotate plugin" )
elseif check( _G, "debug", 5.2 ) then
  A = annotate[=[
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
  assert( A == debug, "debug table modified by annotate plugin" )
end

if check( debug, "debug", 5.1 ) then
  A = annotate[=[
##                    The `debug.debug` Function                    ##

    debug.debug()
]=] .. debug.debug
  if A ~= debug.debug then debug.debug = A end
end

----------------------------------------------------------------------
-- io library

if check( _G, "io", 5.1 ) then
  A = annotate[=[
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
  assert( A == io, "io table modified by annotate plugin" )
end

if check( io, "close", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                      The `io.close` Function                     ##

    io.close( [file] )
]=] .. io.close
  if A ~= io.close then io.close = A end
end

if check( io, "close", 5.2 ) then
  A = annotate[=[
##                      The `io.close` Function                     ##

    io.close( [file] ) ==> (boolean/nil, string, integer)?
]=] .. io.close
  if A ~= io.close then io.close = A end
end

if check( io, "flush", 5.1 ) then
  A = annotate[=[
##                      The `io.flush` Function                     ##

    io.flush()
]=] .. io.flush
  if A ~= io.flush then io.flush = A end
end

if check( io, "stderr", 5.1 ) then
  A = annotate[=[
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
  assert( A == io.stderr, "io.stderr modified by annotate plugin" )
end

if check( io, "stdin", 5.1 ) then
  A = annotate[=[
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
  assert( A == io.stdin, "io.stdin modified by annotate plugin" )
end

if check( io, "stdout", 5.1 ) then
  A = annotate[=[
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
  assert( A == io.stdout, "io.stdout modified by annotate plugin" )
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

if check( file, "close", V >= 5.1 and V < 5.2 ) then
  if io.close ~= file.close then
    A = annotate[=[
##                     The `file:close()` Method                    ##

    file:close()
]=] .. file.close
    if A ~= file.close then file.close = A end
  end
end

if check( file, "close", 5.2 ) then
  if io.close ~= file.close then
    A = annotate[=[
##                     The `file:close()` Method                    ##

    file:close() ==> (boolean/nil, string, integer)?
]=] .. file.close
    if A ~= file.close then file.close = A end
  end
end

if check( file, "flush", 5.1 ) then
  if io.flush ~= file.flush then
    A = annotate[=[
##                     The `file:flush()` Method                    ##

    file:flush()
]=] .. file.flush
    if A ~= file.flush then file.flush = A end
  end
end

----------------------------------------------------------------------
-- math library

if check( _G, "math", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  assert( A == math, "math table modified by annotate plugin" )
elseif check( _G, "math", 5.2 ) then
  A = annotate[=[
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
  assert( A == math, "math table modified by annotate plugin" )
end

if check( math, "abs", 5.1 ) then
  A = annotate[=[
##                      The `math.abs` Function                     ##

    math.abs( number ) ==> number
]=] .. math.abs
  if A ~= math.abs then math.abs = A end
end

----------------------------------------------------------------------
-- os library

if check( _G, "os", 5.1 ) then
  A = annotate[=[
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
  assert( A == os, "os table modified by annotate plugin" )
end

if check( os, "clock", 5.1 ) then
  A = annotate[=[
##                      The `os.clock` Function                     ##

    os.clock() ==> number
]=] .. os.clock
  if A ~= os.clock then os.clock = A end
end

----------------------------------------------------------------------
-- package table

if check( _G, "package", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  assert( A == package, "package table modified by annotate plugin" )
elseif check( _G, "package", 5.2 ) then
  A = annotate[=[
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
  assert( A == package, "package table modified by annotate plugin" )
end

if check( package, "loaded", 5.1 ) then
  A = annotate[=[
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
  assert( A == package.loaded,
          "package.loaded modified by annotate plugin" )
end

if check( package, "loaders", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                    The `package.loaders` Table                   ##

`package.loaders` is a reference to an internal array of functions
that are used by `require` to find modules by a given name. The
default loaders in this table look for a field in `package.preload`
first, then try to find a Lua library via `package.path`/`LUA_PATH`,
and then resort to loading dynamic C libraries via `package.loadlib`
and `package.cpath`/`LUA_CPATH`. As it is just an alias, setting
`package.loaders` to a new table has no effect on module loading.
]=] .. package.loaders
  assert( A == package.loaders,
          "package.loaders modified by annotate plugin" )
end

if check( package, "loadlib", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  if A ~= package.loadlib then package.loadlib = A end
end

if check( package, "loadlib", 5.2 ) then
  A = annotate[=[
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
  if A ~= package.loadlib then package.loadlib = A end
end

if check( package, "preload", 5.1 ) then
  A = annotate[=[
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
  assert( A == package.preload,
          "package.preload modified by annotate plugin" )
end

if check( package, "searchers", 5.2 ) then
  A = annotate[=[
##                   The `package.searchers` Table                  ##

`package.searchers` is a reference to an internal array of functions
that are used by `require` to find modules by a given name. The
default searchers in this table look for a field in `package.preload`
first, then try to find a Lua library via `package.path`/`LUA_PATH`,
and then resort to loading dynamic C libraries via `package.loadlib`
and `package.cpath`/`LUA_CPATH`. As it is just an alias, setting
`package.searchers` to a new table has no effect on module loading.
]=] .. package.searchers
  assert( A == package.searchers,
          "package.searchers modified by annotate plugin" )
end

if check( package, "searchpath", 5.2 ) then
  A = annotate[=[
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

    > =package.searchpath( "my.weird.f_name", "./?.x;?.t", ".", "/" )
    nil
            no file './my/weird/f_name.x'
            no file 'my/weird/f_name.t'
    > =package.searchpath( "my.weird.f_name", "?.t_t", "_", "X" )
    nil
            no file 'my.weird.fXname.t_t'
]=] .. package.searchpath
  if A ~= package.searchpath then package.searchpath = A end
end

if check( package, "seeall", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                   The `package.seeall` Function                  ##

    package.seeall( module )
        module: table  -- the module table

The `package.seeall` function usually is not called directly, but
passed as the second argument to the `module` function to make the
global environment available inside the module's code by setting a
metatable with an `__index` metamethod for the module table.
]=] .. package.seeall
  if A ~= package.seeall then package.seeall = A end
end

----------------------------------------------------------------------
-- string library

if check( _G, "string", 5.1 ) then
  A = annotate[=[
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
  assert( A == string, "string table modified by annotate plugin" )
end

if check( string, "byte", 5.1 ) then
  A = annotate[=[
##                    The `string.byte` Function                    ##

    string.byte( string [, i [, j]] ) ==> integer*
        i: integer  -- starting index for sub-string, defaults to 1
        j: integer  -- end index for sub-string, defaults to #string
]=] .. string.byte
  if A ~= string.byte then string.byte = A end
end

----------------------------------------------------------------------
-- table library

if check( _G, "table", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
##                        Table Manipulation                        ##

The following functions are defined in Lua's `table` library:

*   `table.concat` -- Concatenate strings of an array int one string.
*   `table.insert` -- Insert an element anywhere in an array.
*   `table.maxn` -- Determine largest positive numerical integer key.
*   `table.remove` -- Remove one element anywhere in an array.
*   `table.sort` -- Sort the elements of an array in-place.
]=] .. table
  assert( A == table, "table table modified by annotate plugin" )
elseif check( _G, "table", 5.2 ) then
  A = annotate[=[
##                        Table Manipulation                        ##

The following functions are defined in Lua's `table` library:

*   `table.concat` -- Concatenate strings of an array int one string.
*   `table.insert` -- Insert an element anywhere in an array.
*   `table.pack` -- Convert an argument list to an array.
*   `table.remove` -- Remove one element anywhere in an array.
*   `table.sort` -- Sort the elements of an array in-place.
*   `table.unpack` -- Convert an array to multiple values (vararg).
]=] .. table
  assert( A == table, "table table modified by annotate plugin" )
end

if check( table, "concat", 5.1 ) then
  A = annotate[=[
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
  if A ~= table.concat then table.concat = A end
end

if check( table, "insert", 5.1 ) then
  A = annotate[=[
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
  if A ~= table.insert then table.insert = A end
end

if check( table, "maxn", V >= 5.1 and V < 5.2 ) then
  A = annotate[=[
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
  if A ~= table.maxn then table.maxn = A end
end

if check( table, "pack", 5.2 ) then
  A = annotate[=[
##                     The `table.pack` Function                    ##

    table.pack( ... ) ==> table
        ...: any*  -- arguments/vararg to put into table

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
  if A ~= table.pack then table.pack = A end
end

if check( table, "remove", 5.1 ) then
  A = annotate[=[
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
  if A ~= table.remove then table.remove = A end
end

if check( table, "sort", 5.1 ) then
  A = annotate[=[
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
  if A ~= table.sort then table.sort = A end
end

if check( table, "unpack", 5.2 ) then
  A = annotate[=[
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
  if A ~= table.unpack then table.unpack = A end
end

----------------------------------------------------------------------

-- reenable type checking
if ARG_C ~= false or RET_C ~= false then
  local c = package.loaded[ "annotate.check" ]
  if ARG_C ~= false then
    c.arguments = ARG_C
  end
  if RET_C ~= false then
    c.return_values = RET_C
  end
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

