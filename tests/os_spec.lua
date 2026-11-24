local helper = require("tests.helper")

describe("Std.os", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
		helper.clear_fs(Std)
	end)

	it("computes difftime", function()
		assert.equals(5, Std.os.difftime(10, 5))
	end)

	it("returns a number from clock", function()
		assert.is_number(Std.os.clock())
	end)

	it("getenv always returns nil", function()
		assert.is_nil(Std.os.getenv("PATH"))
	end)

	it("remove and rename operate on the virtual fs", function()
		Std.fs["old.txt"] = "data"
		assert.is_true(Std.os.rename("old.txt", "new.txt"))
		assert.is_nil(Std.fs["old.txt"])
		assert.equals("data", Std.fs["new.txt"])
		assert.is_true(Std.os.remove("new.txt"))
		assert.is_nil(Std.fs["new.txt"])
	end)

	it("remove fails for missing files", function()
		local ok, err = Std.os.remove("nope")
		assert.is_nil(ok)
		assert.matches("No such file", err)
	end)

	it("tmpname returns unique paths", function()
		local a = Std.os.tmpname()
		local b = Std.os.tmpname()
		assert.is_string(a)
		assert.not_equals(a, b)
	end)

	it("marks execute as unavailable", function()
		local ok, err = pcall(function()
			Std.os.execute("true")
		end)
		assert.is_false(ok)
		assert.matches("os%.execute is not available in WoW", err)
	end)
end)
