return LibStdShim.embed("debug", function(Std)
	local _debugstack = debugstack
	local unavailable = Std.unavailable

	local debug_lib = {}
	function debug_lib.traceback(message, level)
		if type(message) == "thread" then
			message = level
			level = nil
		end
		if type(message) == "number" then
			level = message
			message = nil
		end
		local stack = _debugstack((level or 1) + 1)
		if message ~= nil then
			return tostring(message) .. "\n" .. stack
		end
		return stack
	end
	debug_lib.getinfo = unavailable("debug.getinfo")
	debug_lib.getlocal = unavailable("debug.getlocal")
	debug_lib.setlocal = unavailable("debug.setlocal")
	debug_lib.getupvalue = unavailable("debug.getupvalue")
	debug_lib.setupvalue = unavailable("debug.setupvalue")
	debug_lib.sethook = unavailable("debug.sethook")
	debug_lib.gethook = unavailable("debug.gethook")
	function debug_lib.getmetatable(t)
		return getmetatable(t)
	end
	function debug_lib.setmetatable(t, mt)
		return setmetatable(t, mt)
	end
	if getfenv then
		debug_lib.getfenv = getfenv
	else
		debug_lib.getfenv = unavailable("debug.getfenv")
	end
	if setfenv then
		debug_lib.setfenv = setfenv
	else
		debug_lib.setfenv = unavailable("debug.setfenv")
	end
	debug_lib.getregistry = unavailable("debug.getregistry")
	debug_lib.debug = unavailable("debug.debug")
	setmetatable(debug_lib, {
		__index = function(_, k)
			return unavailable("debug." .. tostring(k))
		end,
	})

	return debug_lib
end)
