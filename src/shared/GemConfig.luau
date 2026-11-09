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

-- 8 Nov: Willem's art. The Image ids behind his decal uploads (InsertService:LoadAsset(decal)
-- -> Decal.Texture), so they show for every player; the decal id is in each comment.
local function art(n: string): string return "rbxassetid://" .. n end
G.Art = {
	Icon = art("112913909423142"), -- decal 113909316355113: one gem
	Pile = art("129834324837306"), -- decal 77094412241926: a pile of gems (rebirth payout)
	Card = art("108447205790507"), -- decal 91253976184327: pink framed card (Gem Crate background)
	Banner = art("81713506028869"), -- decal 83889563134831: blue framed banner (Gem Shop background)
	Crate = art("123864848157453"), -- decal 132339925831398: the Gem Crate
	Gate = art("131395997076419"), -- decal 101919176235230: locked sign (Annex gate, Gem Crusher stand)
	Crusher = art("83451761817246"), -- decal 136649559216027: the Gem Crusher (Index icon)
	Awakened = art("112011297282058"), -- decal 140060527339386: the Awakened Gem Crusher
	Concept = art("81563709177293"), -- decal 138446926529109: concept art (grey background, reference only)
	Upgrades = {
		Cash = art("79785191119846"), -- decal 124725494999959
		Luck = art("94629274904889"), -- decal 125402540072740
		Rolls = art("119021304569499"), -- decal 76405017429071 (stopwatch)
		Pedestal = art("89027718081950"), -- decal 77978521877906
		HeadStart = art("90818789034514"), -- (the REBIRTH icon until Willem draws one)
		NestEgg = art("98244872810376"), -- (the cash icon until Willem draws one)
	},
}
G.Icon = G.Art.Icon
-- What rebirths unlock (the rebirth panel shows the next one; 8 Nov)
G.Milestones = {
	{ rebirths = 1, text = "GEM SHOP", art = G.Art.Icon },
	{ rebirths = 3, text = "THE ANNEX", art = G.Art.Gate },
	{ rebirths = 5, text = "GEM CRUSHER", art = G.Art.Crusher },
	{ rebirths = 10, text = "AWAKENED GEM CRUSHER", art = G.Art.Awakened },
}
function G.nextMilestone(rebirths: number): any
	for _, m in G.Milestones do if m.rebirths > rebirths then return m end end
	return nil
end
G.Emoji = "💎"
G.UnlockRebirths = 1 -- the Gem Shop opens after this many rebirths

-- Gems for reaching rebirth n (1, 2, 3, ...): 10, 15, 20, ... 55 at rebirth 10.
-- 9 Nov (vault: time to afford): the first rebirth pays FirstBonus extra (25), so the
-- first Gem Shop visit can buy something (cheapest: an upgrade 15, the crate 25).
G.FirstBonus = 15
function G.forRebirth(n: number): number
	return 10 + 5 * (math.max(1, n) - 1) + (if n == 1 then G.FirstBonus else 0)
end
-- Where Gems come from (shown in the Gem Shop; vault: show where a currency comes from)
G.HowToEarn = "Earn Gems: REBIRTH · Exotic or better crushers in a bay · the GEM CRUSHER"

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
	-- 9 Nov (rebirth data: 170 players at rebirth 1, 66 at rebirth 2: starting over is where
	-- players stop; vault: Progression and Pacing - a rebirth keeps "fast travel to the start
	-- of the furthest region"). HEAD START: each level, a rebirth starts one Factory further
	-- with the bays before it already open (lv 1: FACTORY II + 12 bays; lv 2: FACTORY III + 24).
	-- Never past the factory before the rebirth one (Rebirth.MinPlot), so a rebirth always
	-- needs a run. NEST EGG: start each rebirth with 1% of its price per level (max 5%).
	{ id = "HeadStart", title = "Head Start", line = "Rebirth 1 Factory further on", per = 1, max = 2, base = 40, growth = 3 },
	{ id = "NestEgg", title = "Nest Egg", line = "Rebirth with +1% of its price", per = 0.01, max = 5, base = 25, growth = 1.6 },
	{ id = "Rolls", title = "Quick Rolls", line = "Rolls 0.25 s faster per level", per = 0.25, max = 4, base = 20, growth = 2 },
	-- 8 Nov: a 6th roll pedestal (the purple one in front of the roll machine)
	{ id = "Pedestal", title = "Gem Pedestal", line = "+1 pedestal: 6 choices per roll", per = 1, max = 1, base = 60, growth = 1 },
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
function G.extraPedestals(s: any): number return (s.gemUps and s.gemUps.Pedestal) or 0 end
function G.headStart(s: any): number return (s.gemUps and s.gemUps.HeadStart) or 0 end
function G.nestEgg(s: any): number return 0.01 * ((s.gemUps and s.gemUps.NestEgg) or 0) end

return G
