return LibStdShim.embed("bit32", function(Std)
	local _bit = bit
	local MASK = 4294967295

	local function u32(n)
		n = n % (MASK + 1)
		if n < 0 then
			n = n + (MASK + 1)
		end
		return n
	end

	local bit32 = {}
	local function band(a, b)
		if _bit then
			return u32(_bit.band(a, b))
		end
		error("LibStdShim: bit32 requires WoW's bit library", 2)
	end
	local function bor(a, b)
		return u32(_bit.bor(a, b))
	end
	local function bxor(a, b)
		return u32(_bit.bxor(a, b))
	end

	function bit32.band(...)
		local n = select("#", ...)
		if n == 0 then return MASK end
		local r = select(1, ...)
		for i = 2, n do
			r = band(r, select(i, ...))
		end
		return u32(r)
	end
	function bit32.bor(...)
		local n = select("#", ...)
		if n == 0 then return 0 end
		local r = select(1, ...)
		for i = 2, n do
			r = bor(r, select(i, ...))
		end
		return u32(r)
	end
	function bit32.bxor(...)
		local n = select("#", ...)
		if n == 0 then return 0 end
		local r = select(1, ...)
		for i = 2, n do
			r = bxor(r, select(i, ...))
		end
		return u32(r)
	end
	function bit32.bnot(x)
		return u32(_bit.bnot(x))
	end
	function bit32.lshift(x, disp)
		disp = math.floor(disp)
		if disp < 0 then return bit32.rshift(x, -disp) end
		return u32(_bit.lshift(u32(x), disp))
	end
	function bit32.rshift(x, disp)
		disp = math.floor(disp)
		if disp < 0 then return bit32.lshift(x, -disp) end
		return u32(_bit.rshift(u32(x), disp))
	end
	function bit32.arshift(x, disp)
		disp = math.floor(disp)
		if _bit.arshift then
			return u32(_bit.arshift(x, disp))
		end
		return bit32.rshift(x, disp)
	end
	function bit32.lrotate(x, disp)
		disp = math.floor(disp) % 32
		x = u32(x)
		return u32(_bit.bor(_bit.lshift(x, disp), _bit.rshift(x, 32 - disp)))
	end
	function bit32.rrotate(x, disp)
		return bit32.lrotate(x, -disp)
	end
	function bit32.btest(...)
		return bit32.band(...) ~= 0
	end
	function bit32.extract(n, field, width)
		width = width or 1
		return bit32.rshift(u32(n), field) % (2 ^ width)
	end
	function bit32.replace(n, v, field, width)
		width = width or 1
		v = u32(v) % (2 ^ width)
		n = u32(n)
		n = n - (n % (2 ^ (field + width))) + (n % (2 ^ field)) + v * (2 ^ field)
		return u32(n)
	end

	return bit32
end)
