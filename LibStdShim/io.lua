return LibStdShim.embed("io", function(Std)
	local unavailable = Std.unavailable
	local fs = Std.fs
	local _error = error
	local _type = type
	local _tostring = tostring
	local _tonumber = tonumber
	local _select = select
	local _setmetatable = setmetatable
	local _getmetatable = getmetatable
	local _unpack = unpack
	local _sub = string.sub
	local _find = string.find
	local _byte = string.byte
	local _rep = string.rep
	local _format = string.format
	local _concat = table.concat
	local _floor = math.floor

	local FILE = {}
	FILE.__index = FILE

	local function is_file(f)
		return _type(f) == "table" and _getmetatable(f) == FILE
	end

	local function check_file(f, level)
		if not is_file(f) then
			_error("LibStdShim: file handle expected", level or 2)
		end
		if f._closed then
			_error("cannot use a closed file", level or 2)
		end
	end

	local function parse_mode(mode)
		mode = mode or "r"
		if _sub(mode, -1) == "b" then
			mode = _sub(mode, 1, -2)
		end
		if mode == "r" or mode == "w" or mode == "a" or mode == "r+" or mode == "w+" or mode == "a+" then
			return mode
		end
		return nil
	end

	local function can_read(mode)
		return mode == "r" or mode == "r+" or mode == "w+" or mode == "a+"
	end

	local function can_write(mode)
		return mode == "w" or mode == "a" or mode == "r+" or mode == "w+" or mode == "a+"
	end

	local function is_append(mode)
		return mode == "a" or mode == "a+"
	end

	local function get_content(h)
		if h._mem then
			return h._data or ""
		end
		return fs[h._name] or ""
	end

	local function set_content(h, data)
		if h._mem then
			h._data = data
		else
			fs[h._name] = data
		end
	end

	local function new_handle(name, mode, mem, data)
		return _setmetatable({
			_name = name,
			_mode = mode,
			_closed = false,
			_pos = 0,
			_mem = mem and true or false,
			_data = mem and (data or "") or nil,
		}, FILE)
	end

	-- stdout/stderr: line-buffer into WoW print (which always appends a newline).
	local function stream_emit(h, chunk)
		h._buf = (h._buf or "") .. chunk
		while true do
			local buf = h._buf
			local nl = _find(buf, "\n", 1, true)
			if not nl then
				break
			end
			local line = _sub(buf, 1, nl - 1)
			if #line > 0 and _sub(line, -1) == "\r" then
				line = _sub(line, 1, -2)
			end
			-- Resolve print at call time so tests / hosts can replace it.
			_G.print(line)
			h._buf = _sub(buf, nl + 1)
		end
	end

	local function stream_flush(h)
		local buf = h._buf or ""
		if buf ~= "" then
			_G.print(buf)
			h._buf = ""
		end
		return true
	end

	local function read_line(h, keep_nl)
		local data = get_content(h)
		local pos = h._pos
		if pos >= #data then
			return nil
		end
		local start = pos + 1
		local nl = _find(data, "\n", start, true)
		local chunk
		if not nl then
			chunk = _sub(data, start)
			h._pos = #data
			return chunk
		end
		if keep_nl then
			chunk = _sub(data, start, nl)
		else
			local last = nl - 1
			if last >= start and _sub(data, last, last) == "\r" then
				last = last - 1
			end
			if last < start then
				chunk = ""
			else
				chunk = _sub(data, start, last)
			end
		end
		h._pos = nl
		return chunk
	end

	local function read_chars(h, n)
		local data = get_content(h)
		local pos = h._pos
		if pos >= #data then
			return nil
		end
		local chunk = _sub(data, pos + 1, pos + n)
		h._pos = pos + #chunk
		return chunk
	end

	local function read_all(h)
		local data = get_content(h)
		local pos = h._pos
		if pos >= #data then
			return ""
		end
		local chunk = _sub(data, pos + 1)
		h._pos = #data
		return chunk
	end

	local function read_number(h)
		local data = get_content(h)
		local pos = h._pos
		local i = pos + 1
		local len = #data
		while i <= len do
			local b = _byte(data, i)
			if b ~= 32 and b ~= 9 and b ~= 10 and b ~= 13 and b ~= 12 then
				break
			end
			i = i + 1
		end
		if i > len then
			h._pos = len
			return nil
		end
		local j = i
		local c = _sub(data, j, j)
		if c == "+" or c == "-" then
			j = j + 1
		end
		local saw = false
		while j <= len do
			local b = _byte(data, j)
			if b >= 48 and b <= 57 then
				saw = true
				j = j + 1
			else
				break
			end
		end
		if j <= len and _sub(data, j, j) == "." then
			j = j + 1
			while j <= len do
				local b = _byte(data, j)
				if b >= 48 and b <= 57 then
					saw = true
					j = j + 1
				else
					break
				end
			end
		end
		if j <= len then
			local e = _sub(data, j, j)
			if e == "e" or e == "E" then
				local k = j + 1
				local s = _sub(data, k, k)
				if s == "+" or s == "-" then
					k = k + 1
				end
				local exp = false
				while k <= len do
					local b = _byte(data, k)
					if b >= 48 and b <= 57 then
						exp = true
						k = k + 1
					else
						break
					end
				end
				if exp then
					j = k
				end
			end
		end
		if not saw then
			h._pos = i - 1
			return nil
		end
		local token = _sub(data, i, j - 1)
		h._pos = j - 1
		return _tonumber(token)
	end

	local function read_one(h, fmt)
		if fmt == nil or fmt == "*l" or fmt == "*L" then
			return read_line(h, fmt == "*L")
		elseif fmt == "*a" or fmt == "*A" then
			return read_all(h)
		elseif fmt == "*n" or fmt == "*N" then
			return read_number(h)
		elseif _type(fmt) == "number" then
			local n = _floor(fmt)
			if n < 0 then
				_error("invalid format", 3)
			end
			if n == 0 then
				local data = get_content(h)
				if h._pos >= #data then
					return nil
				end
				return ""
			end
			return read_chars(h, n)
		else
			_error("invalid format", 3)
		end
	end

	function FILE:close()
		if not is_file(self) then
			_error("LibStdShim: file handle expected", 2)
		end
		if self._closed then
			return true
		end
		if self._stream then
			stream_flush(self)
		end
		self._closed = true
		if self._mem then
			self._data = nil
		end
		return true
	end

	function FILE:flush()
		check_file(self, 2)
		if self._stream then
			return stream_flush(self)
		end
		return true
	end

	function FILE:setvbuf()
		check_file(self, 2)
		return true
	end

	function FILE:seek(whence, offset)
		check_file(self, 2)
		whence = whence or "cur"
		offset = offset or 0
		if _type(offset) ~= "number" then
			_error("bad argument #2 to 'seek' (number expected)", 2)
		end
		local len = #get_content(self)
		local pos = self._pos
		if whence == "set" then
			pos = offset
		elseif whence == "cur" then
			pos = pos + offset
		elseif whence == "end" then
			pos = len + offset
		else
			return nil, "invalid option '" .. _tostring(whence) .. "'"
		end
		if pos < 0 then
			return nil, "invalid argument"
		end
		self._pos = pos
		return pos
	end

	function FILE:write(...)
		check_file(self, 2)
		if not can_write(self._mode) then
			return nil, "bad file descriptor"
		end
		local n = _select("#", ...)
		local parts = {}
		for i = 1, n do
			local v = _select(i, ...)
			local t = _type(v)
			if t ~= "string" and t ~= "number" then
				_error("bad argument #" .. i .. " to 'write' (string expected)", 2)
			end
			parts[i] = _tostring(v)
		end
		local chunk = _concat(parts)
		if self._stream then
			stream_emit(self, chunk)
			return self
		end
		local data = get_content(self)
		local pos
		if is_append(self._mode) then
			pos = #data
		else
			pos = self._pos
			if pos > #data then
				data = data .. _rep("\0", pos - #data)
			end
		end
		local before = _sub(data, 1, pos)
		local after = _sub(data, pos + #chunk + 1)
		data = before .. chunk .. after
		set_content(self, data)
		self._pos = pos + #chunk
		return self
	end

	function FILE:read(...)
		check_file(self, 2)
		if not can_read(self._mode) then
			return nil, "bad file descriptor"
		end
		local n = _select("#", ...)
		if n == 0 then
			return read_one(self, "*l")
		end
		local out = {}
		for i = 1, n do
			local v = read_one(self, _select(i, ...))
			out[i] = v
			if v == nil then
				return _unpack(out, 1, i)
			end
		end
		return _unpack(out, 1, n)
	end

	function FILE:lines(...)
		check_file(self, 2)
		local n = _select("#", ...)
		local fmts = { n = n, ... }
		return function()
			check_file(self, 2)
			if fmts.n == 0 then
				return read_one(self, "*l")
			end
			return self:read(_unpack(fmts, 1, fmts.n))
		end
	end

	local io = {}

	function io.type(obj)
		if not is_file(obj) then
			return nil
		end
		if obj._closed then
			return "closed file"
		end
		return "file"
	end

	function io.open(filename, mode)
		if filename == nil then
			return nil, "bad argument #1 to 'open' (string expected)"
		end
		filename = _tostring(filename)
		local m = parse_mode(mode)
		if not m then
			return nil, "invalid mode"
		end
		local exists = fs[filename] ~= nil
		if (m == "r" or m == "r+") and not exists then
			return nil, _format("%s: No such file or directory", filename)
		end
		if m == "w" or m == "w+" then
			fs[filename] = ""
		elseif (m == "a" or m == "a+") and not exists then
			fs[filename] = ""
		end
		local h = new_handle(filename, m, false)
		if is_append(m) then
			h._pos = #fs[filename]
		else
			h._pos = 0
		end
		return h
	end

	local tmp_seq = 0

	function io.tmpfile()
		tmp_seq = tmp_seq + 1
		return new_handle(nil, "w+", true, "")
	end

	io.stdin = new_handle(nil, "r", true, "")

	local function new_std_stream()
		local h = new_handle(nil, "w", true, "")
		h._stream = true
		h._buf = ""
		return h
	end

	io.stdout = new_std_stream()
	io.stderr = new_std_stream()

	local current_input = io.stdin
	local current_output = io.stdout

	function io.input(file)
		if file == nil then
			return current_input
		end
		if _type(file) == "string" then
			local h, err = io.open(file, "r")
			if not h then
				_error(err, 2)
			end
			current_input = h
			return current_input
		end
		check_file(file, 2)
		current_input = file
		return current_input
	end

	function io.output(file)
		if file == nil then
			return current_output
		end
		if _type(file) == "string" then
			local h, err = io.open(file, "w")
			if not h then
				_error(err, 2)
			end
			current_output = h
			return current_output
		end
		check_file(file, 2)
		current_output = file
		return current_output
	end

	function io.read(...)
		return current_input:read(...)
	end

	function io.write(...)
		return current_output:write(...)
	end

	function io.close(file)
		file = file or current_output
		return file:close()
	end

	function io.flush()
		return current_output:flush()
	end

	function io.lines(filename, ...)
		if filename == nil then
			return current_input:lines(...)
		end
		local h, err = io.open(filename, "r")
		if not h then
			_error(err, 2)
		end
		local n = _select("#", ...)
		local fmts = { n = n, ... }
		return function()
			if h._closed then
				return nil
			end
			local results
			if fmts.n == 0 then
				results = { n = 1, h:read("*l") }
			else
				results = { n = fmts.n, h:read(_unpack(fmts, 1, fmts.n)) }
			end
			if results[1] == nil then
				h:close()
				return nil
			end
			return _unpack(results, 1, results.n)
		end
	end

	io.popen = Std.unshimmed

	setmetatable(io, {
		__index = function(_, k)
			return unavailable("io." .. _tostring(k))
		end,
	})

	return io
end)
