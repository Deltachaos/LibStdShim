local helper = require("tests.helper")

describe("Std.table", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
	end)

	it("exposes the shared table library", function()
		assert.equals(table, Std.table)
	end)

	it("provides table.pack", function()
		local t = Std.table.pack(1, nil, 3)
		assert.equals(3, t.n)
		assert.equals(1, t[1])
		assert.is_nil(t[2])
		assert.equals(3, t[3])
	end)

	it("provides table.unpack when missing", function()
		assert.is_function(Std.table.unpack)
		assert.same({ 1, 2 }, { Std.table.unpack({ 1, 2 }) })
	end)
end)
