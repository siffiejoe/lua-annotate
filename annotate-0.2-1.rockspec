package = "annotate"
version = "0.2-1"
source = {
  url = "${SRCURL}",
}
description = {
  summary = "A decorator for docstrings and type checking",
  detailed = [[
    This Lua module provides a decorator that allows to associate Lua
    values with docstrings. Plugins for typechecking using function
    signatures, interactive help, and simple unit testing are included.
  ]],
  homepage = "${HPURL}",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, < 5.3",
  "lpeg >= 0.6"
}
build = {
  type = "builtin",
  modules = {
    [ "annotate" ] = "src/annotate.lua",
    [ "annotate.check" ] = "src/annotate/check.lua",
    [ "annotate.help" ] = "src/annotate/help.lua",
    [ "annotate.test" ] = "src/annotate/test.lua",
  }
}

