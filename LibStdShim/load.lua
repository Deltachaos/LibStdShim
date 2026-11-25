return LibStdShim.embed("load", function(Std)
	local _loadstring = loadstring
	local _setfenv = setfenv
	local fs = Std.fs

	local M = {}

	local function read_all(reader)
		local parts = {}
		while true do
			local piece = reader()
			if piece == nil or piece == "" then
				break
			end
			if type(piece) ~= "string" then
				error("reader function must return a string", 3)
			end
			parts[#parts + 1] = piece
		end
		return table.concat(parts)
	end

	function M.load(chunk, chunkname, mode, env)
		local t = type(chunk)
		if t == "function" then
			chunk = read_all(chunk)
		elseif t ~= "string" then
			error("bad argument #1 to 'load' (function expected, got " .. t .. ")", 2)
		end
		if type(mode) == "string" and string.find(mode, "b", 1, true) and not string.find(mode, "t", 1, true) then
			error("LibStdShim: binary load is not available in WoW", 2)
		end
		if type(mode) == "table" then
			env = mode
			mode = nil
		end
		local fn, err = _loadstring(chunk, chunkname)
		if not fn then
			return nil, err
		end
		if env ~= nil and _setfenv then
			_setfenv(fn, env)
		end
		return fn
	end

	function M.loadfile(filename, mode, env)
		if type(filename) ~= "string" then
			error("bad argument #1 to 'loadfile' (string expected)", 2)
		end
		local data = fs[filename]
		if data == nil then
			return nil, "cannot open " .. filename .. ": No such file or directory"
		end
		return M.load(data, "@" .. filename, mode, env)
	end

	function M.dofile(filename)
		local fn, err = M.loadfile(filename)
		if not fn then
			error(err, 2)
		end
		return fn()
	end

	return M
end)
