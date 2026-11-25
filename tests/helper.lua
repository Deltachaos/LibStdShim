-- Shared stubs for running LibStdShim outside World of Warcraft.

-- Minimal WoW globals used by the shims.
if not time then
	function time(t)
		if t then
			return os.time(t)
		end
		return os.time()
	end
end

if not date then
	function date(fmt, t)
		if fmt == "*t" then
			return os.date("*t", t)
		end
		return os.date(fmt or "%c", t)
	end
end

if not debugprofilestop then
	local start = (os.clock and os.clock()) or 0
	function debugprofilestop()
		return (((os.clock and os.clock()) or 0) - start) * 1000
	end
end

if not debugstack then
	function debugstack(a, b, count1)
		local thread, start
		if type(a) == "thread" then
			thread, start = a, b
		else
			start = a
		end
		start = start or 1
		count1 = count1 or 12
		local parts = {}
		local i = start
		local n = 0
		while n < count1 do
			local info
			if thread then
				info = debug.getinfo(thread, i, "Sln")
			else
				info = debug.getinfo(i + 1, "Sln")
			end
			if not info then
				break
			end
			local loc = string.format("%s:%d", info.short_src or "?", info.currentline or 0)
			if info.name then
				parts[#parts + 1] = string.format("%s: in function `%s'", loc, info.name)
			elseif info.what == "main" then
				parts[#parts + 1] = loc .. ": in main chunk"
			elseif info.what == "C" then
				parts[#parts + 1] = "[C]: ?"
			else
				parts[#parts + 1] = loc
			end
			i = i + 1
			n = n + 1
		end
		return table.concat(parts, "\n") .. "\n"
	end
end

-- WoW exposes a global `bit` library (LuaJIT / BitOp). Prefer that; otherwise
-- load BitOp from luarocks (`luabitop`).
if type(bit) ~= "table" or type(bit.band) ~= "function" then
	bit = require("bit")
end
_G.bit = bit

package.path = "./?.lua;./?/init.lua;" .. package.path

local COMPANIONS = {
	"LibStdShim.os",
	"LibStdShim.io",
	"LibStdShim.debug",
	"LibStdShim.bit32",
	"LibStdShim.load",
	"LibStdShim.table",
}

local M = {}

function M.clear_loaded()
	package.loaded.LibStdShim = nil
	for i = 1, #COMPANIONS do
		package.loaded[COMPANIONS[i]] = nil
	end
	_G.LibStdShim = nil
end

function M.make_libstub()
	local libs = {}
	local stub = {}
	function stub.NewLibrary(_, major, minor)
		local lib = libs[major]
		if not lib then
			lib = {}
			libs[major] = lib
		end
		lib._major = major
		lib._minor = minor
		return lib
	end
	setmetatable(stub, {
		__call = function(_, major, silent)
			local lib = libs[major]
			if not lib and not silent then
				error(major .. " not found", 2)
			end
			return lib
		end,
	})
	return stub, libs
end

function M.fresh_std()
	M.clear_loaded()
	_G.LibStub = nil
	return require("LibStdShim")
end

function M.clear_fs(Std)
	local fs = Std.fs
	for k in pairs(fs) do
		fs[k] = nil
	end
	return fs
end

package.loaded["tests.helper"] = M
return M
