return LibStdShim.embed("math", function(Std)
	-- WoW numbers are IEEE doubles, so a Lua 5.3 integer is a finite value with
	-- nothing after the radix point that still fits in a signed 64-bit integer.
	-- 2^63-1 is not itself a double; the next lower double is 2^63-1024.
	local TWO63 = 2 ^ 63
	local MIN_INTEGER = -TWO63
	local MAX_INTEGER = TWO63 - 1024

	local function is_space(byte)
		return byte == 32 or byte == 9 or byte == 10 or byte == 13 or byte == 11 or byte == 12
	end

	local function hex_value(byte)
		if byte >= 48 and byte <= 57 then
			return byte - 48
		end
		if byte >= 65 and byte <= 70 then
			return byte - 55
		end
		if byte >= 97 and byte <= 102 then
			return byte - 87
		end
		return nil
	end

	-- One Lua numeral, with the surrounding spaces Lua's converters accept.
	-- Returns nil when the text is not a numeral. "inf" and "nan" are rejected.
	local function parse_numeral(text)
		local n = #text
		local i = 1
		while i <= n and is_space(text:byte(i)) do
			i = i + 1
		end
		if i > n then
			return nil
		end

		local sign = 1
		local byte = text:byte(i)
		if byte == 43 then
			i = i + 1
		elseif byte == 45 then
			sign = -1
			i = i + 1
		end
		if i > n then
			return nil
		end

		local function finish(value)
			while i <= n and is_space(text:byte(i)) do
				i = i + 1
			end
			if i <= n then
				return nil
			end
			if sign < 0 then
				value = -value
			end
			return value
		end

		byte = text:byte(i)
		local hex = byte == 48 and i + 1 <= n and (text:byte(i + 1) == 88 or text:byte(i + 1) == 120)
		if hex then
			i = i + 2
			local magnitude = 0
			local digits = 0
			local fraction = 0
			local exact = true
			local function take_digit(digit)
				local scaled = magnitude * 16
				if exact and scaled ~= math.huge then
					local _, exponent = math.frexp(scaled == 0 and 1 or scaled)
					local unit = 2 ^ (exponent - 53)
					if unit > 1 and digit % unit ~= 0 then
						exact = false
					end
				else
					exact = false
				end
				magnitude = scaled + digit
			end
			while true do
				local digit = hex_value(text:byte(i) or 0)
				if not digit then
					break
				end
				take_digit(digit)
				digits = digits + 1
				i = i + 1
			end
			if text:byte(i) == 46 then
				i = i + 1
				while true do
					local digit = hex_value(text:byte(i) or 0)
					if not digit then
						break
					end
					take_digit(digit)
					digits = digits + 1
					fraction = fraction + 1
					i = i + 1
				end
			end
			if digits == 0 or not exact then
				return nil
			end
			local shift = -4 * fraction
			byte = text:byte(i)
			if byte == 80 or byte == 112 then
				i = i + 1
				local exp_sign = 1
				byte = text:byte(i)
				if byte == 43 then
					i = i + 1
				elseif byte == 45 then
					exp_sign = -1
					i = i + 1
				end
				local exp = 0
				local exp_digits = 0
				while i <= n do
					byte = text:byte(i)
					if byte < 48 or byte > 57 then
						break
					end
					exp = exp * 10 + (byte - 48)
					exp_digits = exp_digits + 1
					i = i + 1
				end
				if exp_digits == 0 then
					return nil
				end
				shift = shift + exp_sign * exp
			elseif fraction > 0 then
				return nil
			end
			if shift > 1100 then
				return finish(math.huge)
			end
			if shift < -1100 then
				return finish(0)
			end
			return finish(math.ldexp(magnitude, shift))
		end

		local rest = text:sub(i)
		local token = rest:match("^(%d+%.?%d*[eE][%+%-]?%d+)")
			or rest:match("^(%d*%.%d+[eE][%+%-]?%d+)")
			or rest:match("^(%d+%.?%d*)")
			or rest:match("^(%d*%.%d+)")
		if not token or token == "." then
			return nil
		end
		i = i + #token
		local value = tonumber(token)
		if value == nil then
			return nil
		end
		-- A long decimal integer can round to a different double. Refuse it
		-- instead of returning that other integer.
		if token:match("^%d+$") then
			local digits = token:gsub("^0+", "")
			if digits == "" then
				digits = "0"
			end
			if digits ~= string.format("%.0f", value) then
				return nil
			end
		end
		return finish(value)
	end

	local function as_integer(value)
		if type(value) ~= "number" or value ~= value then
			return nil
		end
		if value < MIN_INTEGER or value > MAX_INTEGER or value % 1 ~= 0 then
			return nil
		end
		if value == 0 then
			return 0
		end
		return value
	end

	-- "integer", or nil plus "repr" when a number has no integer form,
	-- or nil plus "type" when the value is not numeric.
	local function coerce(value)
		local kind = type(value)
		if kind == "number" then
			local integer = as_integer(value)
			if integer == nil then
				return nil, "repr"
			end
			return integer
		end
		if kind == "string" then
			local parsed = parse_numeral(value)
			if parsed == nil then
				return nil, "type"
			end
			local integer = as_integer(parsed)
			if integer == nil then
				return nil, "repr"
			end
			return integer
		end
		return nil, "type"
	end

	if math.maxinteger == nil then
		math.maxinteger = MAX_INTEGER
	end
	if math.mininteger == nil then
		math.mininteger = MIN_INTEGER
	end

	if math.type == nil then
		function math.type(value)
			if type(value) ~= "number" then
				return nil
			end
			-- Negative zero is a float. Every other exact in-range whole number
			-- is reported as an integer, because a double has no integer subtype.
			if value == 0 and 1 / value < 0 then
				return "float"
			end
			if as_integer(value) ~= nil then
				return "integer"
			end
			return "float"
		end
	end

	if math.tointeger == nil then
		function math.tointeger(...)
			if select("#", ...) == 0 then
				error("bad argument #1 to 'tointeger' (value expected)", 2)
			end
			local integer = coerce((...))
			return integer
		end
	end

	if math.ult == nil then
		local function argument(index, ...)
			if select("#", ...) < index then
				error("bad argument #" .. index .. " to 'ult' (number expected, got no value)", 3)
			end
			local value = select(index, ...)
			local integer, why = coerce(value)
			if integer ~= nil then
				return integer
			end
			if why == "repr" then
				error("bad argument #" .. index .. " to 'ult' (number has no integer representation)", 3)
			end
			error("bad argument #" .. index .. " to 'ult' (number expected, got " .. type(value) .. ")", 3)
		end

		-- Signed order matches unsigned order while the sign bits agree.
		-- A negative value is the high half of the unsigned 64-bit range.
		function math.ult(...)
			local left = argument(1, ...)
			local right = argument(2, ...)
			if left < 0 then
				if right < 0 then
					return left < right
				end
				return false
			end
			if right < 0 then
				return true
			end
			return left < right
		end
	end

	local log = math.log
	local log10 = math.log10
	local function log_accepts_base()
		local ok, result = pcall(log, 100, 10)
		return ok and type(result) == "number" and result > 1.9 and result < 2.1
	end
	if log and not log_accepts_base() then
		function math.log(value, ...)
			if select("#", ...) == 0 then
				return log(value)
			end
			local base = ...
			if base == 10 and log10 then
				return log10(value)
			end
			return log(value) / log(base)
		end
	end

	local atan = math.atan
	local atan2 = math.atan2
	local function atan_accepts_two()
		local ok, two = pcall(atan, 1, 0)
		local ok_one, one = pcall(atan, 1)
		return ok and ok_one and two ~= one
	end
	if atan and atan2 and not atan_accepts_two() then
		function math.atan(y, ...)
			if select("#", ...) == 0 then
				return atan(y)
			end
			return atan2(y, (...))
		end
	end

	return math
end)
