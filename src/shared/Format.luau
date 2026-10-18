-- Small text helpers used by both the server and the client.
local Format = {}

-- 250000 -> "$250,000"
function Format.money(n)
	local s = tostring(math.floor(n or 0))
	repeat
		local count
		s, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return "$" .. s
end

return Format
