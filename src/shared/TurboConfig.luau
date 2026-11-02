--!strict
-- 2 Nov: TURBO fuel (Sell Ores' Growth Gems, Willem's "making the game faster"
-- doc: always something to buy). Bought with CASH at the Turbo pump on your plot.
-- A turbo multiplies all your cash for a while; only the strongest running turbo
-- counts (they don't multiply each other), buying the same one again adds time.
-- Price = `cost` seconds of your income (without turbo), so it is worth buying at
-- every stage and always costs a real share. 2 Nov evening (Willem: way too long a
-- wait): 40% cheaper, x2 for 5 min now pays back over 3x its price.
-- Stronger turbos unlock with the factory level (`plot`).
local M = {}

M.List = {
	{ id = "Turbo", title = "TURBO", mult = 2, minutes = 5, cost = 90, plot = 0, color = Color3.fromRGB(255, 160, 40) },
	{ id = "MegaTurbo", title = "MEGA TURBO", mult = 3, minutes = 10, cost = 360, plot = 1, color = Color3.fromRGB(255, 90, 60) },
	{ id = "HyperTurbo", title = "HYPER TURBO", mult = 5, minutes = 15, cost = 1080, plot = 2, color = Color3.fromRGB(230, 60, 200) },
	{ id = "UltraTurbo", title = "ULTRA TURBO", mult = 8, minutes = 15, cost = 2160, plot = 3, color = Color3.fromRGB(80, 200, 255) },
}
M.MaxMinutes = 60 -- one turbo can't be stacked past this
M.MinCost = 50 -- never cheaper than this

function M.find(id: any): any
	for _, t in M.List do if t.id == id then return t end end
	return nil
end
function M.attr(id: string): string return "Turbo_" .. id end
-- price for a player whose income (without turbo) is `cps` cash per second
function M.price(t: any, cps: number): number
	return math.max(M.MinCost, math.floor((cps or 0) * t.cost))
end
-- (strongest running multiplier, its seconds left) from the player's attributes
function M.active(player: Player, now: number): (number, number)
	local best, left = 1, 0
	for _, t in M.List do
		local ends = (player:GetAttribute(M.attr(t.id)) :: number?) or 0
		if ends > now and t.mult > best then best, left = t.mult, math.floor(ends - now) end
	end
	return best, left
end

return M
