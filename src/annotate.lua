-- general library for Lua value annotations using docstrings

local assert = assert
local type = assert( type )
local pairs = assert( pairs )
local setmetatable = assert( setmetatable )


local M = {
  callbacks = {},
  callbacks_r = {},
}


local decorator_meta = {
  __concat = function( self, v )
    local docstring = self.docstring
    for i = 1, #self.callbacks_r do
      v = self.callbacks_r[ i ]( v, docstring )
    end
    for cb in pairs( self.callbacks ) do
      cb( v, docstring )
    end
    return v
  end
}


local M_meta = {
  __index = {
    register = function( self, fun, replace )
      assert( type( fun ) == "function",
              "docstring callback must be a function" )
      if replace then
        local cb = self.callbacks_r
        if not cb[ fun ] then
          cb[ fun ] = true
          cb[ #cb+1 ] = fun
        end
      else
        self.callbacks[ fun ] = true
      end
      return self
    end,
  },
  __call = function( self, docstring )
    assert( type( docstring ) == "string",
            "docstring must be a string" )
    local decorator = {
      docstring = docstring,
      callbacks_r = self.callbacks_r,
      callbacks = self.callbacks,
    }
    setmetatable( decorator, decorator_meta )
    return decorator
  end,
}


setmetatable( M, M_meta )
return M

