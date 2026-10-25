--!strict
-- Timed boosts sold at the Boosts station in the hub (server/Boosts).
--   Cash   your crushers earn x2 cash
--   Luck   x2 chance of uncommon-or-better crushers when rolling
--   Super  both at once
-- Each player gets one free FreeMinutes boost of their choice per day (UTC).
-- Robux: product ids live in Shared/Store (BoostCash, BoostLuck, BoostSuper);
-- id 0 = "Coming soon". Time stacks when you buy more of the same boost.
local B = {}

B.FreeMinutes = 5
B.MaxMinutes = 240 -- a boost can't stack beyond this
B.List = {
	{ id = "Cash", title = "2x Cash", desc = "Your crushers earn double cash", color = Color3.fromRGB(230, 70, 60), icon = "DoubleCash", product = "BoostCash", minutes = 15 },
	{ id = "Luck", title = "2x Luck", desc = "Double chance of rare crushers", color = Color3.fromRGB(60, 190, 90), icon = "Lucky", product = "BoostLuck", minutes = 15 },
	{ id = "Super", title = "Super Boost", desc = "2x Cash and 2x Luck together", color = Color3.fromRGB(160, 80, 235), icon = "Golden", product = "BoostSuper", minutes = 15 },
}
function B.find(id: any): any
	for _, b in B.List do if b.id == id then return b end end
	return nil
end
-- Player attribute holding a boost's end time (server time).
function B.attr(id: string): string return "Boost_" .. id end
-- Is a boost effect on? (Super counts for both Cash and Luck.)
function B.active(player: Player, effect: string, now: number): boolean
	local function on(id: string) return ((player:GetAttribute(B.attr(id)) :: number?) or 0) > now end
	return on(effect) or on("Super")
end

return B
