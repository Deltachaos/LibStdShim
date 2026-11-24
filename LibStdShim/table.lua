return LibStdShim.embed("table", function(Std)
	local _unpack = unpack

	if table.unpack == nil and _unpack then
		table.unpack = _unpack
	end
	if table.pack == nil then
		function table.pack(...)
			return { n = select("#", ...), ... }
		end
	end

	return table
end)
