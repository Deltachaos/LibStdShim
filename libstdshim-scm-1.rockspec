rockspec_format = "3.0"
package = "libstdshim"
version = "scm-1"

source = {
  url = "git+https://github.com/Deltachaos/LibStdShim.git",
}

description = {
  summary = "Lua 5.1 standard-library shims for World of Warcraft",
  detailed = [[
    LibStdShim provides os, io, debug, bit32, load/loadfile/dofile, and table
    helpers that approximate the Lua 5.1 standard library inside WoW's sandbox,
    using a virtual filesystem and LibStub when available.
  ]],
  homepage = "https://github.com/Deltachaos/LibStdShim",
  license = "MIT",
}

dependencies = {
  "lua >= 5.1",
}

test_dependencies = {
  "busted",
  "luabitop",
}

build = {
  type = "builtin",
  modules = {
    LibStdShim = "LibStdShim.lua",
    ["LibStdShim.os"] = "LibStdShim/os.lua",
    ["LibStdShim.io"] = "LibStdShim/io.lua",
    ["LibStdShim.debug"] = "LibStdShim/debug.lua",
    ["LibStdShim.bit32"] = "LibStdShim/bit32.lua",
    ["LibStdShim.load"] = "LibStdShim/load.lua",
    ["LibStdShim.table"] = "LibStdShim/table.lua",
    ["LibStdShim.math"] = "LibStdShim/math.lua",
  },
  copy_directories = {
    "tests",
    "meta",
  },
}

test = {
  type = "busted",
}
