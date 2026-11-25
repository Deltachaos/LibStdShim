return LibStdShim.embed("debug", function(Std)
	local unavailable = Std.unavailable
	local _type = type
	local _tostring = tostring
	local _tonumber = tonumber
	local _sub = string.sub
	local _find = string.find
	local _match = string.match
	local _gsub = string.gsub

	local function debugstack(...)
		return _G.debugstack(...)
	end

	local function first_frame(stack)
		if _type(stack) ~= "string" or stack == "" then
			return nil
		end
		for line in stack:gmatch("[^\n]+") do
			line = _gsub(line, "\r$", "")
			line = _gsub(line, "^%s+", "")
			line = _gsub(line, "%s+$", "")
			if line ~= "" and line ~= "..." then
				return line
			end
		end
		return nil
	end

	local function short_src(source)
		if _sub(source, 1, 1) == "=" then
			return _sub(source, 2, 60)
		end
		if _sub(source, 1, 1) == "@" then
			local name = _sub(source, 2)
			if #name <= 60 then
				return name
			end
			return "..." .. _sub(name, -(60 - 3))
		end
		local body = source
		if #body > 48 then
			body = _sub(body, 1, 45) .. "..."
		end
		return '[string "' .. body .. '"]'
	end

	local function parse_desc(desc, info)
		if desc == nil or desc == "" or desc == "?" then
			return
		end
		if desc == "in main chunk" then
			info.what = "main"
			return
		end
		local name = _match(desc, "^in function ['`\"](.-)['`\"]")
		if name then
			info.name = name
			return
		end
		name = _match(desc, "^in function ([%w_?]+)$")
		if name then
			info.name = name
			return
		end
		local defline = _match(desc, "^in function <.+:(%d+)>$")
		if defline then
			info.linedefined = _tonumber(defline)
		end
	end

	local function parse_frame(line)
		local info = {
			what = "Lua",
			currentline = -1,
			linedefined = -1,
			lastlinedefined = -1,
			namewhat = "",
		}

		if _find(line, "^%(tail call%)") then
			info.source = "=(tail call)"
			info.short_src = "(tail call)"
			info.what = "tail"
			return info
		end

		local rest = _match(line, "^%[C%]:%s*(.*)$")
		if rest then
			info.source = "=[C]"
			info.short_src = "[C]"
			info.what = "C"
			parse_desc(rest, info)
			return info
		end

		local chunk, lineno, desc = _match(line, '^%[string "([^"]+)"%]:(%d+):%s*(.*)$')
		if not chunk then
			chunk, lineno, desc = _match(line, "^%[string '([^']+)'%]:(%d+):%s*(.*)$")
		end
		if chunk then
			info.source = chunk
			info.short_src = short_src(info.source)
			info.currentline = _tonumber(lineno)
			parse_desc(desc, info)
			return info
		end

		local loc, line_no, desc2 = _match(line, "^(.-):(%d+):%s*(.*)$")
		if not loc then
			loc, line_no = _match(line, "^(.-):(%d+)$")
			desc2 = ""
		end
		if not loc then
			return nil
		end
		info.source = "@" .. loc
		info.short_src = short_src(info.source)
		info.currentline = _tonumber(line_no)
		parse_desc(desc2, info)
		return info
	end

	local function select_fields(info, what)
		if what == nil then
			what = "nSl"
		end
		local out = {}
		if _find(what, "n", 1, true) then
			out.name = info.name
			out.namewhat = info.namewhat
		end
		if _find(what, "S", 1, true) then
			out.source = info.source
			out.short_src = info.short_src
			out.what = info.what
			out.linedefined = info.linedefined
			out.lastlinedefined = info.lastlinedefined
		end
		if _find(what, "l", 1, true) then
			out.currentline = info.currentline
		end
		return out
	end

	local debug_lib = {}
	function debug_lib.traceback(message, level, extra)
		local thread
		if _type(message) == "thread" then
			thread = message
			message = level
			level = extra
		end
		if _type(message) == "number" then
			level = message
			message = nil
		end
		local start = (level or 1) + 1
		local stack
		if thread then
			stack = debugstack(thread, start)
		else
			stack = debugstack(start)
		end
		if stack == nil then
			stack = ""
		end
		if message ~= nil then
			return _tostring(message) .. "\n" .. stack
		end
		return stack
	end

	function debug_lib.getinfo(level, what, extra)
		local thread
		if _type(level) == "thread" then
			thread = level
			level = what
			what = extra
		end
		if _type(level) ~= "number" then
			return nil
		end
		local stack
		if thread then
			stack = debugstack(thread, level + 1, 1, 0)
		else
			stack = debugstack(level + 1, 1, 0)
		end
		local line = first_frame(stack)
		if not line then
			return nil
		end
		local info = parse_frame(line)
		if not info then
			return nil
		end
		return select_fields(info, what)
	end
	debug_lib.getlocal = Std.unshimmed
	debug_lib.setlocal = Std.unshimmed
	debug_lib.getupvalue = Std.unshimmed
	debug_lib.setupvalue = Std.unshimmed
	debug_lib.sethook = unavailable("debug.sethook")
	debug_lib.gethook = Std.unshimmed
	function debug_lib.getmetatable(t)
		return getmetatable(t)
	end
	function debug_lib.setmetatable(t, mt)
		return setmetatable(t, mt)
	end
	if getfenv then
		debug_lib.getfenv = getfenv
	else
		debug_lib.getfenv = Std.unshimmed
	end
	if setfenv then
		debug_lib.setfenv = setfenv
	else
		debug_lib.setfenv = Std.unshimmed
	end
	debug_lib.getregistry = Std.unshimmed
	debug_lib.debug = unavailable("debug.debug")
	setmetatable(debug_lib, {
		__index = function(_, k)
			return unavailable("debug." .. tostring(k))
		end,
	})

	return debug_lib
end)
