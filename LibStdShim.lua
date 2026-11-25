--[[
  LibStdShim-1.0
  Lua 5.1 standard-library shims for World of Warcraft.
]]

local MAJOR, MINOR = "LibStdShim-1.0", 1
local MODULES = { "os", "io", "debug", "bit32", "load", "table" }

local function installed(std, key)
	if key == "load" then
		if not std.load then
			return nil
		end
		return { load = std.load, loadfile = std.loadfile, dofile = std.dofile }
	end
	return std[key]
end

local function embed(key, build)
	local libstub = _G.LibStub
	local std = (libstub and libstub(MAJOR, true)) or _G.LibStdShim
	if not std or (libstub and (std.minor or 0) > MINOR) then
		return std and installed(std, key) or nil
	end
	if libstub then
		local have = installed(std, key)
		if have ~= nil then
			return have
		end
	end
	local mod = build(std)
	if libstub then
		if key == "load" then
			std.load = mod.load
			std.loadfile = mod.loadfile
			std.dofile = mod.dofile
		else
			std[key] = mod
		end
	end
	return mod
end

local function init(std)
	std.minor = MINOR
	std.MAJOR = MAJOR
	std.MINOR = MINOR
	std.fs = std.fs or {}
	std.embed = embed
	function std.unavailable(name)
		return function()
			error("LibStdShim: " .. name .. " is not available in WoW", 2)
		end
	end
	function std.unshimmed()
		return nil
	end
end

local function mount(std, libstub)
	for i = 1, #MODULES do
		local name = MODULES[i]
		local mod = require("LibStdShim." .. name)
		if not libstub and mod ~= nil then
			if name == "load" then
				std.load = mod.load
				std.loadfile = mod.loadfile
				std.dofile = mod.dofile
			else
				std[name] = mod
			end
		end
	end
end

local libstub = _G.LibStub
local Std

-- When required as a module (e.g. busted), companions are pulled in here.
-- In WoW, lib.xml loads them as separate Scripts; each calls LibStdShim.embed.
local loaded_as_module = select("#", ...) >= 1 and type((...)) == "string"

if not libstub then
	Std = {}
	init(Std)
	_G.LibStdShim = Std
	if loaded_as_module then
		mount(Std, false)
	end
	return Std
end

Std = libstub:NewLibrary(MAJOR, MINOR)
if not Std then
	return
end

init(Std)
_G.LibStdShim = Std

if loaded_as_module then
	mount(Std, true)
end

return Std
