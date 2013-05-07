local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local string = require( "string" )
local s_gsub = assert( string.gsub )
local s_match = assert( string.match )
local type = assert( type )
local select = assert( select )
local tostring = assert( tostring )
local print = assert( print )
local pcall = assert( pcall )
local setmetatable = assert( setmetatable )


local docstring_cache = {}
setmetatable( docstring_cache, { __mode="k" } )

local function docstring_callback( v, docstring )
  docstring_cache[ v ] = s_gsub( docstring, "^%s*(.-)%s*$", "%1" )
end
annotate:register( docstring_callback )


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
    return docstring_cache[ v ]
  end
  local s, n = s_match( str, "^([%a_][%w_%.]*)%.([%a_][%w_]*)$" )
  return s and try_require( s, n, ... )
end


local function lookup( v )
  local s = docstring_cache[ v ]
  if s ~= nil then
    return s
  end
  if type( v ) == "string" then
    return try_require( v )
  end
end


local M = {}
local M_meta = {
  __index = {
    wrap = function( self, fun, writer )
      writer = writer or function( s ) print( s ) end
      return function( ... )
        local s = lookup( ... )
        if s then
          writer( s, ... )
        else
          fun( ... )
        end
      end
    end,
  },
  __call = function( _, topic )
    print( lookup( topic ) or
           "no help available for "..tostring( topic ) )
  end,
}

setmetatable( M, M_meta )
return M

