local helper = require("tests.helper")

describe("Std.debug", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
	end)

	it("traceback returns a stack string", function()
		local tb = Std.debug.traceback("boom")
		assert.matches("boom", tb)
		assert.is_string(tb)
	end)

	it("passes a thread through traceback", function()
		local co = coroutine.create(function() end)
		local seen
		local old = _G.debugstack
		_G.debugstack = function(a, b)
			seen = { a, b }
			return "stack"
		end
		local tb = Std.debug.traceback(co, "boom", 1)
		_G.debugstack = old
		assert.equals(co, seen[1])
		assert.equals(2, seen[2])
		assert.matches("boom", tb)
		assert.matches("stack", tb)
	end)

	it("getmetatable / setmetatable work", function()
		local t = {}
		local mt = {}
		Std.debug.setmetatable(t, mt)
		assert.equals(mt, Std.debug.getmetatable(t))
	end)

	local function with_stack(stack, fn)
		local old = _G.debugstack
		_G.debugstack = function()
			return stack
		end
		local ok, err = pcall(fn)
		_G.debugstack = old
		if not ok then
			error(err)
		end
	end

	it("returns nil for getinfo of a function", function()
		assert.is_nil(Std.debug.getinfo(function() end))
	end)

	it("returns nil from unshimmed inspectors", function()
		assert.is_nil(Std.debug.getlocal(1, 1))
		assert.is_nil(Std.debug.setlocal(1, 1, nil))
		assert.is_nil(Std.debug.getupvalue(function() end, 1))
		assert.is_nil(Std.debug.setupvalue(function() end, 1, nil))
		assert.is_nil(Std.debug.gethook())
		assert.is_nil(Std.debug.getregistry())
	end)

	it("marks sethook as unavailable", function()
		local ok, err = pcall(function()
			Std.debug.sethook(function() end, "l")
		end)
		assert.is_false(ok)
		assert.matches("debug%.sethook is not available in WoW", err)
	end)

	it("parses a named Lua frame", function()
		with_stack("Interface\\AddOns\\Foo\\Bar.lua:42: in function `MyFunc'\n", function()
			local info = Std.debug.getinfo(1)
			assert.equals("@Interface\\AddOns\\Foo\\Bar.lua", info.source)
			assert.equals("Interface\\AddOns\\Foo\\Bar.lua", info.short_src)
			assert.equals(42, info.currentline)
			assert.equals("Lua", info.what)
			assert.equals("MyFunc", info.name)
			assert.equals("", info.namewhat)
			assert.equals(-1, info.linedefined)
			assert.equals(-1, info.lastlinedefined)
			assert.is_nil(info.func)
			assert.is_nil(info.nups)
		end)
	end)

	it("parses double-quoted and unquoted function names", function()
		with_stack('file.lua:2: in function "a"\n', function()
			assert.equals("a", Std.debug.getinfo(1).name)
		end)
		with_stack("file.lua:5: in function b\n", function()
			assert.equals("b", Std.debug.getinfo(1).name)
		end)
	end)

	it("fills linedefined from an anonymous frame", function()
		with_stack("Interface\\AddOns\\Foo\\Bar.lua:98: in function <Interface\\AddOns\\Foo\\Bar.lua:90>\n", function()
			local info = Std.debug.getinfo(1, "Sn")
			assert.equals(90, info.linedefined)
			assert.is_nil(info.name)
			assert.is_nil(info.currentline)
		end)
	end)

	it("parses C, main, string, and tail frames", function()
		with_stack("[C]: in function `pcall'\n", function()
			local info = Std.debug.getinfo(1)
			assert.equals("=[C]", info.source)
			assert.equals("[C]", info.short_src)
			assert.equals("C", info.what)
			assert.equals("pcall", info.name)
			assert.equals(-1, info.currentline)
		end)
		with_stack('[string "chunk"]:1: in main chunk\n', function()
			local info = Std.debug.getinfo(1)
			assert.equals("chunk", info.source)
			assert.equals('[string "chunk"]', info.short_src)
			assert.equals("main", info.what)
			assert.equals(1, info.currentline)
		end)
		with_stack("(tail call): ?\n", function()
			local info = Std.debug.getinfo(1)
			assert.equals("tail", info.what)
			assert.equals("(tail call)", info.short_src)
			assert.equals(-1, info.currentline)
		end)
	end)

	it("returns nil for a stack level with no frame", function()
		with_stack("", function()
			assert.is_nil(Std.debug.getinfo(99))
		end)
	end)

	it("passes a thread to debugstack from getinfo", function()
		local co = coroutine.create(function() end)
		local seen
		local old = _G.debugstack
		_G.debugstack = function(a, b, c, d)
			seen = { a, b, c, d }
			return "file.lua:1: in function `f'\n"
		end
		Std.debug.getinfo(co, 0)
		_G.debugstack = old
		assert.equals(co, seen[1])
		assert.equals(1, seen[2])
		assert.equals(1, seen[3])
		assert.equals(0, seen[4])
	end)
end)
