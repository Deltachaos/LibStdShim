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

	it("getmetatable / setmetatable work", function()
		local t = {}
		local mt = {}
		Std.debug.setmetatable(t, mt)
		assert.equals(mt, Std.debug.getmetatable(t))
	end)

	it("marks getinfo as unavailable", function()
		local ok, err = pcall(function()
			Std.debug.getinfo(1)
		end)
		assert.is_false(ok)
		assert.matches("debug%.getinfo is not available in WoW", err)
	end)
end)
