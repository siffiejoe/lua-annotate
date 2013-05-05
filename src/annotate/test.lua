local assert = assert
local require = assert( require )
local annotate = require( "annotate" )
local debug = require( "debug" )
local L = require( "lpeg" )
local setmetatable = assert( setmetatable )


-- grammar to identify test code in docstring
local g = {}
do
  local P,R,S,V,C,Ct,Cc = L.P,L.R,L.S,L.V,L.C,L.Ct,L.Cc
  local pbreak = P"\n\n"
  local comment = P"--" * (P( 1 ) - P"\n")^0
  local ws = S" \t\r\n\v\f"
  local _ = (ws - pbreak)^0
  local _2 = ((ws + comment) - pbreak)^0
  local letter = R( "az", "AZ" ) + P"_"
  local digit = R"09"
  local id = letter * (letter+digit)^0
  local indent = P" "^4
  local title = S"Ee"*S"Xx"*S"Aa"*S"Mm"*S"Pp"*S"Ll"*S"Ee"*(S"Ss"^-1)

  g[ 1 ] = ws^0 * Ct( (V"typespec" + (V"paragraph" - V"testspec"))^0 ) * V"testspec" * V"paragraph"^0 * P( -1 )
  g.paragraph = (P( 1 ) - pbreak)^1 * ws^0
  -- for extracting a function signature if there is one
  g.typespec = C( _2 * V"funcname" * P"(" * _2 * V"arglist" * P")" ) * V"paragraph"^-1 * ws^0
  g.funcname = id * _2 * (P"." * _2 * id * _2)^0 * (P":" * _2 * id)^-1 * _2
  g.arglist = (letter+S"[],."+((ws+comment)-pbreak)^1)^0
  -- test specification
  g.testspec = V"header" * Ct( (V"lua_line" + Ct( V"out_line"^1 ) + V"empty_line")^1 ) * ws^0
  g.header = (title*P":" + P"#"^1*(ws-P"\n")^0*title*(ws-P"\n")^0*P"#"^0) * V"empty_line"^0
  g.lua_line = indent * P">" * P">"^-1 * P" "^-1 * C( (P( 1 ) - P"\n")^0 ) * P"\n"
  g.out_line = indent * -P">" * C( (P( 1 ) - P"\n")^0 ) * P"\n"
  g.empty_line = (ws - P"\n")^0 * P"\n"

  -- compile grammar once and for all
  g = P( g )
end


-- debug function to show some nested tables captured by lpeg
local function debug_ast( node, prefix )
  prefix = prefix or ""
  if type( node ) == "table" then
    io.stderr:write( "{" )
    if next( node ) ~= nil then
      io.stderr:write( "\n" )
      for k,v in pairs( node ) do
        io.stderr:write( prefix, "  ", tostring( k ), " = " )
        debug_ast( v, prefix.."  " )
      end
    end
    io.stderr:write( prefix, "}\n" )
  else
    io.stderr:write( tostring( node ), "\n" )
  end
end



local function docstring_callback( v, docstring )
  local sigs, tests = L.match( g, docstring )
  if sigs then
    if #sigs == 1 then
      print( sigs[ 1 ] )
    end
    debug_ast( tests )
  end

  -- TODO
end
annotate:register( docstring_callback )

local M = {}
local M_meta = {}

setmetatable( M, M_meta )
return M

