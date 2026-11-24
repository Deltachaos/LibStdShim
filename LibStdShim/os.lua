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

	os.execute = unavailable("os.execute")
	os.exit = unavailable("os.exit")
	os.setlocale = unavailable("os.setlocale")
	setmetatable(os, {
		__index = function(_, k)
			return unavailable("os." .. tostring(k))
		end,
	})

	return os
end)
