# LibStdShim

Lua 5.1 standard-library shims for World of Warcraft.

WoW's Lua environment is missing or restricting parts of the standard library (`io`, most of `os`, `debug`, `bit32`, `load`/`loadfile`/`dofile`). LibStdShim fills those gaps with a small library you can embed in an addon. File operations use an in-memory virtual filesystem (`LibStdShim.fs`) instead of the real disk.

## Install

Copy this repository into your addon (or a libs folder) and load `meta/lib.xml` from your TOC:

```xml
<Include file="LibStdShim\meta\lib.xml"/>
```

`meta/lib.xml` loads `LibStdShim.lua` and the modules under `LibStdShim/`.

## Usage

With [LibStub](https://www.wowace.com/projects/libstub), the library registers as `LibStdShim-1.0`:

```lua
local Std = LibStub("LibStdShim-1.0")
Std.fs["notes.txt"] = "hello"
local f = Std.io.open("notes.txt", "r")
print(f:read("*a"))
f:close()
```

Without LibStub, requiring the module returns the library table:

```lua
local Std = require("LibStdShim")
```

Each module is also available on its own (`require("LibStdShim.io")` and so on). When LibStub is present, a module registers itself on the library only if that field is not already set.

### Provided modules

| Field | Contents |
| --- | --- |
| `Std.os` | `time`, `date`, `clock`, `difftime`, `remove`, `rename`, `tmpname`; `setlocale` queries `GetLocale` as `en_US` (cannot change locale); `execute` returns `nil`; `exit` raises |
| `Std.io` | `open`, `read`, `write`, `lines`, `tmpfile`, `stdin` / `stdout` / `stderr` over `Std.fs`; `popen` returns `nil` |
| `Std.debug` | `traceback`, `getinfo` (stack levels via `debugstack`), `getmetatable`, `setmetatable`; value-returning `debug.*` stubs return `nil`; `sethook` / `debug` raise |
| `Std.bit32` | Lua 5.2 `bit32` built on WoW's `bit` library |
| `Std.load` / `loadfile` / `dofile` | Text chunks and reader functions; `loadfile` and `dofile` read from `Std.fs` |
| `Std.table` | The shared `table` library, plus `pack` / `unpack` when missing |

`stdout` and `stderr` line-buffer into `print`.

## Tests

Tests use [busted](https://lunarmodules.github.io/busted/). LuaJIT already provides `bit`; PUC-Rio Lua 5.1 needs [LuaBitOp](https://luarocks.org/modules/luarocks/luabitop).

```bash
luarocks install busted
luarocks install luabitop   # skip on LuaJIT
busted
```

## License

MIT. See [LICENSE](LICENSE).
