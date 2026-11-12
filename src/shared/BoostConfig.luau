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
	{ id = "Luck", title = "2x Luck", desc = "2x luck on crusher rolls for 15 min (stacks with the Lucky pass)", color = Color3.fromRGB(60, 190, 90), icon = "Lucky", product = "BoostLuck", minutes = 15 },
	{ id = "Super", title = "Super Boost", desc = "2x Cash and 2x Luck together", color = Color3.fromRGB(160, 80, 235), icon = "Golden", product = "BoostSuper", minutes = 15 },
}
-- 12 Nov (funnel: every "Fill N bays" goal lost 16-24% of players, all waiting for cash):
-- the STARTER BOOST, 2x cash for a new player's first Minutes of play after the tutorial.
-- Counts play time only (server/Boosts: d.starterLeft seconds), so it doesn't run out
-- while you're away. Stacks with the 2x Cash boost. Not sold, not in B.List.
B.Starter = { id = "Starter", title = "Starter Boost", color = Color3.fromRGB(255, 170, 40), icon = "DoubleCash", minutes = 30 }
function B.find(id: any): any
	for _, b in B.List do if b.id == id then return b end end
	return nil
end
-- Player attribute holding a boost's end time (server time).
function B.attr(id: string): string return "Boost_" .. id end
-- Is a boost effect on? (Super counts for both Cash and Luck.)
-- the starter boost (attribute Boost_Starter = the end time while you play)
function B.starter(player: Player, now: number): boolean
	return ((player:GetAttribute(B.attr("Starter")) :: number?) or 0) > now
end
function B.active(player: Player, effect: string, now: number): boolean
	local function on(id: string) return ((player:GetAttribute(B.attr(id)) :: number?) or 0) > now end
	return on(effect) or on("Super")
end

return B
