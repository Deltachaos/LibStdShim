local helper = require("tests.helper")

describe("Std.bit32", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
	end)

	it("band / bor / bxor / bnot", function()
		assert.equals(0, Std.bit32.band(1, 2))
		assert.equals(3, Std.bit32.bor(1, 2))
		assert.equals(3, Std.bit32.bxor(1, 2))
		assert.equals(4294967294, Std.bit32.bnot(1))
	end)

	it("shifts and rotates", function()
		assert.equals(4, Std.bit32.lshift(1, 2))
		assert.equals(1, Std.bit32.rshift(4, 2))
		assert.equals(2, Std.bit32.lrotate(1, 1))
		assert.equals(2 ^ 31, Std.bit32.rrotate(1, 1))
	end)

	it("btest / extract / replace", function()
		assert.is_true(Std.bit32.btest(1, 1))
		assert.is_false(Std.bit32.btest(1, 2))
		assert.equals(15, Std.bit32.extract(0xF0, 4, 4))
		assert.equals(0x0F, Std.bit32.replace(0xFF, 0, 4, 4))
	end)

	it("band with no args is all bits set", function()
		assert.equals(4294967295, Std.bit32.band())
	end)
end)
