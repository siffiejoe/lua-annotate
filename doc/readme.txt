![annotate Logo](annotate.png)

#        annotate -- Annotations and Docstrings for Lua Values       #

##                           Introduction                           ##

There are basically two ways for documenting code in a dynamically
typed programming language like Lua: you can write static
documentation like external readme files or comments that can be
extracted by specialized documentation tools, or you can annotate Lua
values with runtime information. The first approach enables you to
extract useful information without running any code, a popular tool
for this is [LDoc][1]. One well-known representative of the second
approach is [Python][2] with its [docstrings][3]. One advantage of
this approach is that you can easily process those runtime annotations
and e.g. provide interactive help, or type checking.

This module uses the ideas presented [here][4] and [here][5] to
provide a basis for docstring handling in Lua, and flexible argument
and return value checking for Lua functions.

  [1]:  https://github.com/stevedonovan/LDoc/
  [2]:  http://www.python.org/
  [3]:  https://en.wikipedia.org/wiki/Docstring
  [4]:  http://lua-users.org/wiki/DecoratorsAndDocstrings
  [5]:  http://lua-users.org/wiki/LuaTypeChecking


##                           Basic Usage                            ##

To add a docstring annotation to a Lua value (like e.g. a function)
you use the `annotate` base module:

    $ cat > test1.lua
    -- loading the module returns a callable table
    local annotate = require( "annotate" )

    -- annotated function definitions consist of a call to the
    -- annotate function concatenated to a normal (anonymous)
    -- function value
    local func = annotate[=[
    The `func` function takes a number and a string and prints them to
    the standard output stream.
    ]=] ..
    function( a, b )
      print( a, b )
    end

    func( 1, "hello" )
    ^D

The `annotate` module itself doesn't do anything with the docstrings
and Lua values, but hands both to modules like e.g. the
`annotate.check` module:

    $ cat > test2.lua
    local annotate = require( "annotate" )
    require( "annotate.check" )  -- we ignore the return value for now

    local func = annotate[=[
    The `func` function takes a number and a string and prints them to
    the standard output stream.

        func( a, b )
            a: number
            b: string
    ]=] ..
    function( a, b )
      print( a, b )
    end

    func( 1, "hello" )
    func( 2, true )        --> line 17
    ^D

When run, the above example will output:

    $ lua test2.lua
    1       hello
    lua: func: string expected for argument no. 2 (got boolean).
    stack traceback:
            [C]: in function 'error'
            [compiled_arg_check]:48: in function 'argc'
            ../src/annotate/check.lua:842: in function 'func'
            test2.lua:17: in main chunk
            [C]: in ?


##                        The annotate Module                       ##

By itself the `annotate` module does nothing except providing syntax
for associating a docstring with a Lua value. It does so using a
`__call` metamethod that takes a string and returns an object with a
`__concat` metamethod. So the general usage looks like this:

    local annotate = require( "annotate" )
    local annotated_v = annotate[[some string]] .. v

What you put into the docstrings is your business, but I suggest
[markdown][6], because it looks good as plain text, and you can
convert it to many formats, e.g. using a converter like [pandoc][7].
There are also Lua libraries for converting markdown texts.

  [6]: http://daringfireball.net/projects/markdown/
  [7]: http://johnmacfarlane.net/pandoc/

To actually do something with the annotations you need handler modules
that get registered with the `annotate` module. For this the
`annotate` module provides a `register` method:

    annotate:register( function( v, docstring ) ... end [, replace] )

There are two kinds of callback functions, those that wrap or replace
the original value, and those that don't. For the former kind, the
`replace` argument must evaluate to a true value. Those callbacks are
called in the order of registration, and they must return the
replacement value. The non-replacing kind of callback is called after
all modifying callbacks are handled, but the order in which they are
called is unspecified (and shouldn't matter anyway). Their return
values are ignored.


##                     The annotate.check Module                    ##

The `annotate.check` module registers itself with the `annotate`
module when require'd (see above). For every function that gets
annotated, it parses the given docstring and extracts argument and
return type information from a special function signature in the
docstring. It then replaces the original function with a type checking
version. Various fields in the `annotate.check` module table can be
used to fine-tune the type checking (see below).


###                    Function Signature Syntax                   ###

The `annotate.check` module scans paragraphs (sequences of characters
delimited by `\n\n`) in the docstring and takes the first that looks
like a function signature as used in the [Lua reference manual][8].
A function signature starts with a name or function designator (module
names + function name, delimited by `.`), followed by a parameter
list in parentheses, an optional return value specification, and if
necessary a mapping of parameter names to types. You can put Lua-style
single line comments at all places where whitespace is allowed.

  [8]: http://www.lua.org/manual/5.2/manual.html#6.1


*   Function Designator:

    A function designator is either a function name (a Lua
    identifier), or a field (Lua identifier) in a table (also a Lua
    identifier), as usual separated by `.` for module functions or `:`
    for methods. The table itself can be a field in another module
    table, and so on. This is better shown by example, than explained.
    The following are valid function designators:

    *   `func`
    *   `mod.func`
    *   `mod:func`
    *   `mod1.mod2.func`
    *   `mod1.mod2:func`
    *   etc.

*   Parameter List:

    The parameter list is a sequence of names, optionally delimited by
    commas (`,`). Parts/or all of the parameter list can be enclosed
    in square brackets (`[]`) to denote optional parameters. Those
    optional parameter sublists can be nested as well. The last
    element of the parameter list can be the special vararg parameter
    `...`. The whole parameter list is enclosed in parentheses. The
    parameter names have to be mapped to type names in the parameter
    mapping section (see below), but for simple cases you can use the
    type names directly as parameter names, and omit the mapping.


*   Return Value Specification:

    If the function returns one or more values, you need one or more
    patterns for return value types. Each pattern is started by an
    arrow `=>` (you can use more than one `=`) and followed by a
    regular expression. Multiple patterns denote alternatives.

    The regular expressions are built from type names that are
    combined via the usual regular expression operators (listed in
    descending order of precedence):

    *   a type name registered in the `types` sub-table (see below)

    *   `(` pattern `)`

        for explicit grouping

    *   pattern`*` or pattern`?`

        `*` means zero or more occurrences of the pattern, `?` means
        zero or one

    *   pattern1 `/` pattern2

        an alternative, matches pattern1 _or_ pattern2

    *   pattern1 `,` pattern2

        a sequence of two patterns, matches pattern1 _and then_
        pattern2

*   Parameter Mapping:

    If the parameter list of the function has any parameter names in
    it, you need to map those names to actual types as defined in the
    `types` sub-table. This is done by specifying the parameter name,
    followed by a colon (`:`), followed by a type name or a list of
    alternative types delimited by `/` (no full regular expressions
    allowed here except for `...`). The special vararg parameter
    (`...`) can use full regular expressions as in the return value
    specifications (see above). Specifying a type for the implicit
    `self` parameter in methods is optional, the default is `object`
    which matches tables and userdata.


####                           Examples                           ####

    pcall( f [, arg1, ...] ) ==> boolean, any*
        f   : function  -- the function to call in protected mode
        arg1: any       -- first argument to f
        ... : any*      -- remaining arguments to f

    tonumber( any [, number] ) ==> nil/number

    table.concat( list [, sep [, i [, j]]] ) ==> string
        list: table     -- an array of strings
        sep : string    -- a separator, defaults to ""
        i   : integer   -- starting index, defaults to 1
        j   : integer   -- end index, defaults to #list

    table.insert( list, [pos,] value )
        list : table    -- an array
        pos  : integer  -- index where to insert (defaults to #list+1)
        value: any      -- value to insert

    io.open( filename [, mode] )
            ==> file               -- on success
            ==> nil,string,number  -- in case of error
        filename: string           -- the name of the file
        mode    : string           -- flags similar to fopen(3)

    file:read( ... ) ==> (string/number/nil)*
        ...: (string/number)*      -- format specifiers

    file:seek( [whence [, offset]] ) ==> number
                                     ==> nil, string
        self  : file               -- would default to `object`
        whence: string
        offset: number

    os.execute( [string] )
            ==> boolean
            ==> boolean/nil, string, number

    mod.obj:method( [a [, b] [, c],] [d,] ... )
            ==> boolean            -- when successful
            ==> nil, string        -- in case of error
          a: string/function       -- a string or a function
          b: userdata              -- a userdata
                                   -- don't break the paragraph!
          c: boolean               -- a boolean flag
          d: number                -- a number
        ...: ((table, string/number) / boolean)*


###               Predefined Type Checking Functions               ###

The table `check.types` (where `check` is the result of the
`require`-call) comes with some predefined type checking functions.
Those predefined type checking functions only cover basic Lua
data types, see below for how to add your own application specific
checking functions.

*   `nil`

    Matches the nil type/value.

*   `boolean`

    Matches either `true` or `false`.

*   `number`

    Matches a Lua number.

*   `string`

    Matches a Lua string.

*   `table`

    Matches a Lua table.

*   `userdata`

    Matches a userdata (light and full).

*   `function`

    Matches a Lua function (but not a callable userdata or table).

*   `thread`

    Matches a Lua coroutine.

*   `any`

    Matches any one value (including nil).

*   `object`

    Matches a Lua table or a userdata, but doesn't check for a
    metatable.

*   `true`

    Matches any Lua value except `nil` and `false`

*   `false`

    Matches only `nil` and `false`.

Some optional type checkers are defined if the necessary modules and
functions are available:

*   `integer`

    Matches numbers without fractional part. Requires `math.floor`.

*   `file`

    Matches an opened file handle. Requires `io.type`.

*   `pattern`

    Matches an [LPeg][9] pattern. Requires `LPeg.type`.

  [9]:  http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html


###                     Tuning the Type Checker                    ###

Checking for basic Lua types already helps, but typically support for
application specific data types is needed. To register a new type
simply add the type checking function to the `types` sub-table.

    local annotate = require( "annotate" )
    local check = require( "annotate.check" )
    check.types.file = function( v )
      return io.type( v ) == "file"
    end

    local func2 = annotate[=[
        func2( [fh] )
            fh: file  -- a file handle
    ]=] ..
    function( out )
      out = out or io.stdout
      out:write( "Hello World!\n" )
    end

You can disable type checking for the following function definitions
by setting the `enabled` field to false. In that case the
`annotate.check` module doesn't replace the original function.

    check.enabled = false

Previously defined functions are unaffected by this change.

You can selectively enable/disable type checking for arguments and
return values using the `arguments` and `return_values` flags. Again,
this only affects functions defined after this change.

    check.arguments = true
    check.return_values = false

By default the type checking module throws an error for undefined type
checkers, or if a docstring for a function does not have a function
signature. You can change that by providing a custom error function:

    check.errorf = function( msg ) print( msg ) end -- print warning
    -- check.errorf = function() end -- ignore completely


##                     The annotate.help Module                     ##

The `annotate.help` module registers itself with the `annotate`
module when require'd to provide interactive help for all Lua values
with an annotation. It can also wrap other help modules (like e.g.
[ihelp][10]) to delegate help requests for values *not* having a
docstring. Assuming `help` is the return value of the `require`-call:

*   `help( value )`

    Prints the annotation for the given value, or a short notice that
    no docstring could be found for that value.

*   `help:search( pattern )` or `help.search( pattern )`

    Prints all annotations that match the given pattern, or a short
    notice that no matching docstring could be found. If `highlighter`
    is a function value, it is used in a `string.gsub` call to replace
    all occurrences of the pattern with a highlighted value.

*   `help:wrap( help_func )` or `help.wrap( help_func )`

    Returns a function that first looks for an annotation for a given
    value and prints it if it exists, or falls back to the supplied
    `help_func` function.

*   `help:lookup( value )` or `help.lookup( value )`

    Tries to find a docstring for the given value and returns it.
    Returns `nil` if no docstring can be found.

*   `help:iterate() or help.iterate()`

    Returns a for-loop iterator that iterates over all values and
    their docstrings.

  [10]:  https://github.com/dlaurie/lua-ihelp/

If the argument to the `help` module (or to the `lookup` function) is
a string, `annotate.help` tries to require the string (and suitable
substrings) looking for a Lua value with an annotation using the
string as a path.


##                    The annotate.test Module                    ##

The `annotate.test` module is a simple unit testing module inspired by
Python's [doctest][11]. The idea is to provide code examples in the
docstrings using the syntax of the interactive Lua interpreter. The
code examples can be executed and verified as working Lua code by this
module. It registers itself with the `annotate` module when require'd
and stores the test code it finds in the docstrings in an internal
table for later execution. The tests are started by calling the result
of the `require( "annotate.test" )` call.

    local annotate = require( "annotate" )
    local test = require( "annotate.test" )
    -- ... some function definitions with annotations
    test( 1 ) -- parameter is output verbosity (0-3, default is 1)

  [11]:  http://en.wikipedia.org/wiki/Doctest

The test output quotes the function name, if the docstring also
contains a type signature (as for the `annotate.check` module, see
there) *before* the test code section. Test results and statistics are
written to the standard error channel.

If you want to take unit testing really seriously, the test code will
become way too big to be included in the docstrings. In this case you
should consider using a designated unit testing module for most of the
tests, and only use this module to make sure the examples in the
documentation stay correct.


###                           Test Syntax                          ###

The beginning of the test code section is denoted by a simple header
or a markdown header (in atx-style format).

*   Simple Header:
    *   One of `example`, `examples`, `test`, or `tests` at the
        beginning of a paragraph, optionally followed by a colon
        (`:`), and zero or more empty lines (containing only
        whitespace). 
    *   The case of `example`/`examples`/`test`/`tests` doesn't
        matter.

*   Markdown Header:
    *   One or more `#` followed by optional whitespace, one of
        `example`, `examples`, `test`, or `tests` (again case doesn't
        matter), and zero or more empty lines (containing only
        whitespace).
    *   The markdown header line can optionally be "closed" by
        whitespace and any number of `#`. 

After the header, any line indented 4 spaces is either a line
containing Lua code, or a line containing output of the Lua code
before. Lua code starts with "`> `" or "`>> `". Each line of Lua code
is compiled as a separate chunk if possible (like in the interactive
interpreter). All tests for a single annotation share a custom
environment containing a modified `print` function, and the global
variable `F` that refers to the value the annotation is for (useful
for testing local functions), as well as `__index` access to the
default global environment.

The output lines are matched against values returned from the Lua
chunks (via `return` or `=`), against error messages, and against the
output of the `print` function (but only if used directly in the test
code, the output of Lua's standard `print` function cannot be
matched). The string `...` in an output line is equivalent to the
string pattern `.-`, a group of one or more whitespace characters is
equivalent to `%s+`. Additionally, whitespace at the end of the output
is ignored.

An empty line (containing only whitespace) is skipped (unless it
starts with 4 spaces in which case it is considered an output line).
The test/example section ends with the first non-empty line that is
not indented at least 4 spaces.


####                           Examples                           ####

    local annotate = require( "annotate" )
    local test = require( "annotate.test" )

    func = annotate[=[
    This is function `func`.

       func( n ) ==> number
           n: number

    Examples:
        > return func( 1 )
        1
        > function f( n )
        >> return func( n )
        >> end
        > = f( 2 )
        2
        > = f( 2 ) -- this test will fail!
        3
        > print( "hello\nworld" )
        hello
        world
        > = 2+"x"
        ...attempt to perform arithmetic...

    This is the end of the test code!
    ]=] ..
    function( n )
      return n
    end

    test() -- run the tests

The result is:

    ### [++-++] function func( n )
    ### TOTAL: 4 ok, 1 failed, 5 total


##                             Changelog                            ##

*   Version 0.2 [2013/06/xx]
    *    added plugin for simple interactive help
    *    added plugin for running test code within annotations
*   Version 0.1 [2013/04/21]
    *    first public release


##                             Download                             ##

The source code (with documentation and test scripts) is available on
[github][12].

  [12]:  https://github.com/siffiejoe/lua-annotate/


##                           Installation                           ##

There are two ways to install this module, either using luarocks (if
this module already ended up in the [main luarocks repository][13]) or
manually.

Using luarocks, simply type:

    luarocks install annotate

To install the module manually just drop `annotate.lua` and
`annotate/*.lua` somewhere into your Lua `package.path`. You will
also need [LPeg][9] (at least for the type checker, and the test
module).

  [13]: http://luarocks.org/repositories/rocks/    (Main Repository)


##                             Contact                              ##

Philipp Janda, siffiejoe(a)gmx.net

Comments and feedback are always welcome.


##                             License                              ##

annotate is *copyrighted free software* distributed under the MIT
license (the same license as Lua 5.1). The full license text follows:

    annotate (c) 2013 Philipp Janda

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDER BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


