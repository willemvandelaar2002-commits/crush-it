--!strict
-- Big-number formatting: 1234 -> "1.23K", 5.6e9 -> "5.6B".
local Format = {}
local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.compact(n: number): string
	if n ~= n or n == math.huge then
		return "∞"
	end
	local neg = n < 0
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUFFIX do
		n /= 1000
		i += 1
	end
	local s
	if i == 1 then
		s = tostring(math.floor(n))
	elseif n >= 100 then
		s = string.format("%d", math.floor(n))
	elseif n >= 10 then
		s = string.format("%.1f", math.floor(n * 10) / 10)
	else
		s = string.format("%.2f", math.floor(n * 100) / 100)
	end
	s = s:gsub("%.0+$", ""):gsub("(%.%d-)0+$", "%1")
	return (if neg then "-" else "") .. s .. SUFFIX[i]
end

function Format.cash(n: number): string
	return "$" .. Format.compact(n)
end

return Format
