--!strict
-- 8 Nov (Willem: "new currency after rebirth"; vault: Currency Architecture - one job,
-- one faucet, one sink; Rebirth and Prestige - a second layer). GEMS:
--   job     progress after the first rebirth
--   faucet  every rebirth pays Gems (more for later rebirths) + a small trickle from
--           Exotic / Mythic / Secret / Divine crushers in a bay
--   sink    the Gem Shop: the Gem Crate and permanent Gem upgrades (they survive rebirths)
-- Gems are earned in-game only (not sold for Robux), so the Gem Crate is not a paid
-- random item. Its odds are still shown in full before every open.
-- Flat numbers on purpose (vault: fixed prices live in a currency that does not grow).
local G = {}

G.Icon = "rbxassetid://0" -- Willem's Gem icon (0 = the built-in diamond until it arrives)
G.Emoji = "💎"
G.UnlockRebirths = 1 -- the Gem Shop opens after this many rebirths

-- Gems for reaching rebirth n (1, 2, 3, ...): 10, 15, 20, ... 55 at rebirth 10
function G.forRebirth(n: number): number
	return 10 + 5 * (math.max(1, n) - 1)
end

-- Gems per minute for each crusher of these rarities that sits in a bay
G.Trickle = { Exotic = 0.1, Mythic = 0.15, Secret = 0.25, Divine = 0.5 }

-- The Gem Crate: one crusher per open, rarity by these chances (they add up to 1)
G.Crate = {
	Cost = 25,
	Odds = {
		{ rarity = "Legendary", chance = 0.60 },
		{ rarity = "Exotic", chance = 0.30 },
		{ rarity = "Secret", chance = 0.08 },
		{ rarity = "Divine", chance = 0.02 },
	},
}

-- Permanent upgrades (kept through every rebirth). Cost of the next level:
-- base * growth ^ level.
G.Upgrades = {
	{ id = "Cash", title = "Gem Cash", line = "+10% cash per level", per = 0.10, max = 10, base = 15, growth = 1.5 },
	{ id = "Luck", title = "Gem Luck", line = "+10% luck per level", per = 0.10, max = 10, base = 15, growth = 1.5 },
	{ id = "Rolls", title = "Quick Rolls", line = "Rolls 0.25 s faster per level", per = 0.25, max = 4, base = 20, growth = 2 },
}
function G.upgrade(id: string): any
	for _, u in G.Upgrades do if u.id == id then return u end end
	return nil
end
function G.cost(id: string, level: number): number?
	local u = G.upgrade(id)
	if not u or level >= u.max then return nil end
	return math.floor(u.base * u.growth ^ level + 0.5)
end
-- multipliers from the saved levels (s = d.crushers)
function G.cashMult(s: any): number return 1 + 0.10 * ((s.gemUps and s.gemUps.Cash) or 0) end
function G.luckMult(s: any): number return 1 + 0.10 * ((s.gemUps and s.gemUps.Luck) or 0) end
function G.rollCut(s: any): number return 0.25 * ((s.gemUps and s.gemUps.Rolls) or 0) end

return G
