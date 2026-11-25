local helper = require("tests.helper")

describe("Std.io", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
		helper.clear_fs(Std)
	end)

	it("opens, writes, and reads a virtual file", function()
		local f = assert(Std.io.open("hello.txt", "w"))
		assert.equals(f, f:write("hello\nworld"))
		assert.is_true(f:close())

		f = assert(Std.io.open("hello.txt", "r"))
		assert.equals("hello", f:read("*l"))
		assert.equals("world", f:read("*l"))
		assert.is_nil(f:read("*l"))
		f:close()
	end)

	it("fails to open missing files for reading", function()
		local f, err = Std.io.open("missing.txt", "r")
		assert.is_nil(f)
		assert.matches("No such file", err)
	end)

	it("supports seek and append modes", function()
		Std.fs["a.txt"] = "abc"
		local f = assert(Std.io.open("a.txt", "a"))
		f:write("def")
		f:close()
		assert.equals("abcdef", Std.fs["a.txt"])

		f = assert(Std.io.open("a.txt", "r"))
		assert.equals(3, f:seek("set", 3))
		assert.equals("def", f:read("*a"))
		f:close()
	end)

	it("tmpfile stores data in memory", function()
		local f = Std.io.tmpfile()
		f:write("tmp")
		f:seek("set", 0)
		assert.equals("tmp", f:read("*a"))
		f:close()
	end)

	it("io.type reports file state", function()
		local f = assert(Std.io.open("t.txt", "w"))
		assert.equals("file", Std.io.type(f))
		f:close()
		assert.equals("closed file", Std.io.type(f))
		assert.is_nil(Std.io.type({}))
	end)

	it("lines iterates file contents", function()
		Std.fs["lines.txt"] = "one\ntwo\n"
		local out = {}
		for line in Std.io.lines("lines.txt") do
			out[#out + 1] = line
		end
		assert.same({ "one", "two" }, out)
	end)

	it("stdout write goes through print", function()
		local printed = {}
		local old_print = _G.print
		_G.print = function(msg)
			printed[#printed + 1] = msg
		end
		Std.io.stdout:write("line1\nline2")
		Std.io.stdout:flush()
		_G.print = old_print
		assert.same({ "line1", "line2" }, printed)
	end)

	it("popen returns nil", function()
		assert.is_nil(Std.io.popen("echo"))
	end)
end)
