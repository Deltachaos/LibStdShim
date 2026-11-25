return LibStdShim.embed("os", function(Std)
	local _time = time
	local _date = date
	local _debugprofilestop = debugprofilestop
	local unavailable = Std.unavailable
	local fs = Std.fs
	local _tostring = tostring
	local _format = string.format

	local os = {}
	function os.time(...)
		return _time(...)
	end
	function os.date(...)
		return _date(...)
	end
	function os.difftime(t2, t1)
		return t2 - t1
	end
	function os.clock()
		return _debugprofilestop() / 1000
	end
	function os.getenv()
		return nil
	end

	function os.remove(filename)
		filename = _tostring(filename)
		if fs[filename] == nil then
			return nil, _format("%s: No such file or directory", filename)
		end
		fs[filename] = nil
		return true
	end

	function os.rename(oldname, newname)
		oldname = _tostring(oldname)
		newname = _tostring(newname)
		if fs[oldname] == nil then
			return nil, _format("%s: No such file or directory", oldname)
		end
		fs[newname] = fs[oldname]
		fs[oldname] = nil
		return true
	end

	local tmp_seq = 0
	function os.tmpname()
		tmp_seq = tmp_seq + 1
		return _format("/tmp/lua_%d", tmp_seq)
	end

	local CATEGORIES = {
		all = true,
		collate = true,
		ctype = true,
		monetary = true,
		numeric = true,
		time = true,
	}

	local function wow_locale()
		local get = _G.GetLocale or _G.GetOSLocale
		if type(get) == "function" then
			return get()
		end
		return nil
	end

	local function to_posix(code)
		if type(code) ~= "string" then
			return nil
		end
		if #code == 4 then
			local lang = string.lower(string.sub(code, 1, 2))
			local region = string.upper(string.sub(code, 3, 4))
			if string.match(lang, "^[a-z][a-z]$") and string.match(region, "^[A-Z][A-Z]$") then
				return lang .. "_" .. region
			end
		end
		return code
	end

	local function requested_posix(locale)
		local base = string.match(locale, "^([^%.]+)") or locale
		if #base == 4 then
			return to_posix(base)
		end
		local lang, region = string.match(base, "^([A-Za-z][A-Za-z])_([A-Za-z][A-Za-z])$")
		if lang then
			return string.lower(lang) .. "_" .. string.upper(region)
		end
		return base
	end

	function os.setlocale(locale, category)
		category = category or "all"
		if not CATEGORIES[category] then
			return nil
		end
		local current = wow_locale()
		if current == nil then
			return nil
		end
		local posix = to_posix(current)
		if locale == nil then
			return posix
		end
		if requested_posix(tostring(locale)) == posix then
			return posix
		end
		return nil
	end

	os.execute = Std.unshimmed
	os.exit = unavailable("os.exit")
	setmetatable(os, {
		__index = function(_, k)
			return unavailable("os." .. tostring(k))
		end,
	})

	return os
end)
