local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local string = require( "string" )
local sgsub = assert( string.gsub )
local tostring = assert( tostring )
local print = assert( print )
local setmetatable = assert( setmetatable )


local docstring_cache = {}
setmetatable( docstring_cache, { __mode="k" } )

local function docstring_callback( v, docstring )
  docstring_cache[ v ] = sgsub( docstring, "^%s*(.-)%s*$", "%1" )
end
annotate:register( docstring_callback )

local M = {}
local M_meta = {
  __index = {
    wrap = function( self, fun, writer )
      writer = writer or function( s ) print( s ) end
      return function( ... )
        if docstring_cache[ ... ] then
          writer( docstring_cache[ ... ], ... )
        else
          fun( ... )
        end
      end
    end,
  },
  __call = function( _, topic )
    print( docstring_cache[ topic ] or
           "no help available for "..tostring( topic ) )
  end,
}

setmetatable( M, M_meta )
return M

