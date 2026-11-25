local helper = require("tests.helper")

describe("Std.os", function()
	local Std

	before_each(function()
		Std = helper.fresh_std()
		helper.clear_fs(Std)
		_G.GetLocale = nil
		_G.GetOSLocale = nil
	end)

	after_each(function()
		_G.GetLocale = nil
		_G.GetOSLocale = nil
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

	it("setlocale returns nil without GetLocale", function()
		_G.GetLocale = nil
		_G.GetOSLocale = nil
		assert.is_nil(Std.os.setlocale())
	end)

	it("setlocale queries GetLocale as a POSIX name", function()
		_G.GetLocale = function()
			return "enUS"
		end
		assert.equals("en_US", Std.os.setlocale())
		assert.equals("en_US", Std.os.setlocale(nil, "time"))
		assert.equals("en_US", Std.os.setlocale("en_US"))
		assert.equals("en_US", Std.os.setlocale("enUS"))
		assert.equals("en_US", Std.os.setlocale("en_US.UTF-8"))
		assert.equals("en_US", Std.os.setlocale("en_US.utf8"))
		assert.is_nil(Std.os.setlocale("de_DE"))
		assert.is_nil(Std.os.setlocale(nil, "nope"))
		_G.GetLocale = nil
	end)

	it("setlocale falls back to GetOSLocale", function()
		_G.GetOSLocale = function()
			return "deDE"
		end
		assert.equals("de_DE", Std.os.setlocale())
	end)

	it("setlocale leaves a non-four-letter locale unchanged", function()
		_G.GetLocale = function()
			return "C"
		end
		assert.equals("C", Std.os.setlocale())
		assert.equals("C", Std.os.setlocale("C"))
	end)

	it("setlocale converts other Blizzard locale codes", function()
		_G.GetLocale = function()
			return "zhCN"
		end
		assert.equals("zh_CN", Std.os.setlocale())
		assert.equals("zh_CN", Std.os.setlocale("zhCN"))
		_G.GetLocale = function()
			return "ptBR"
		end
		assert.equals("pt_BR", Std.os.setlocale())
		_G.GetLocale = nil
	end)

	it("execute returns nil", function()
		assert.is_nil(Std.os.execute("true"))
	end)

	it("marks exit as unavailable", function()
		local ok, err = pcall(function()
			Std.os.exit(0)
		end)
		assert.is_false(ok)
		assert.matches("os%.exit is not available in WoW", err)
	end)
end)
