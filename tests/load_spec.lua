local helper = require("tests.helper")

describe("Std.load / loadfile / dofile", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
		helper.clear_fs(Std)
	end)

	it("loads a string chunk", function()
		local fn = assert(Std.load("return 1 + 2", "chunk"))
		assert.equals(3, fn())
	end)

	it("rejects binary-only mode", function()
		local ok, err = pcall(function()
			Std.load("return 1", "x", "b")
		end)
		assert.is_false(ok)
		assert.matches("binary load is not available in WoW", err)
	end)

	it("loads a chunk from a reader function", function()
		local pieces = { "return ", "1", " + ", "2" }
		local i = 0
		local fn = assert(Std.load(function()
			i = i + 1
			return pieces[i]
		end, "reader"))
		assert.equals(3, fn())
	end)

	it("stops reading on empty string", function()
		local fn = assert(Std.load(function()
			return ""
		end, "empty"))
		assert.is_nil(fn())
	end)

	it("errors when the reader returns a non-string", function()
		local ok, err = pcall(function()
			Std.load(function()
				return 1
			end)
		end)
		assert.is_false(ok)
		assert.matches("reader function must return a string", err)
	end)

	it("loadfile reads from the virtual fs", function()
		Std.fs["script.lua"] = "return 'ok'"
		local fn = assert(Std.loadfile("script.lua"))
		assert.equals("ok", fn())
	end)

	it("loadfile reports missing files", function()
		local fn, err = Std.loadfile("missing.lua")
		assert.is_nil(fn)
		assert.matches("No such file", err)
	end)

	it("dofile executes a virtual file", function()
		Std.fs["run.lua"] = "return 42"
		assert.equals(42, Std.dofile("run.lua"))
	end)

	it("applies env via setfenv when available", function()
		if not setfenv then
			pending("setfenv not available on this Lua")
		end
		local env = { x = 7 }
		local fn = assert(Std.load("return x", "e", "t", env))
		assert.equals(7, fn())
	end)
end)
