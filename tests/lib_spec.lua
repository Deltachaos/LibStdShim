describe("LibStdShim bootstrap", function()
	local helper = require("tests.helper")

	it("returns a table with companions when LibStub is absent", function()
		helper.clear_loaded()
		_G.LibStub = nil
		local Std = require("LibStdShim")
		assert.is_table(Std)
		assert.equals("LibStdShim-1.0", Std.MAJOR)
		assert.equals(1, Std.MINOR)
		assert.is_table(Std.fs)
		assert.is_function(Std.unavailable)
		assert.is_table(Std.io)
		assert.is_table(Std.os)
		assert.is_table(Std.debug)
		assert.is_table(Std.bit32)
		assert.is_function(Std.load)
		assert.is_table(Std.table)
	end)

	it("registers with LibStub and self-registers companions", function()
		helper.clear_loaded()
		local stub, libs = helper.make_libstub()
		_G.LibStub = stub

		local Std = require("LibStdShim")
		assert.is_table(Std)
		assert.equals(libs["LibStdShim-1.0"], Std)
		assert.equals(stub("LibStdShim-1.0"), Std)
		assert.is_table(Std.io)
		assert.is_table(Std.os)
	end)

	it("does not overwrite an already-registered companion under LibStub", function()
		helper.clear_loaded()
		local stub, libs = helper.make_libstub()
		local sentinel = { sentinel = true }
		libs["LibStdShim-1.0"] = { io = sentinel }
		_G.LibStub = stub

		local Std = require("LibStdShim")
		assert.equals(sentinel, Std.io)
		assert.is_table(Std.os)
	end)
end)
