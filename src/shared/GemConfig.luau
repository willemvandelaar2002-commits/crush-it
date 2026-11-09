--!strict
-- 8 Nov (Willem: "new currency after rebirth"; vault: Currency Architecture - one job,
-- one faucet, one sink; Rebirth and Prestige - a second layer). GEMS:
--   job     progress after the first rebirth
--   faucet  (9 Nov, Willem) only the GEM MINE: from rebirth 1 a teleporter on your plot takes
--           you to a shared mine where your own Gem Crusher crushes gems out; you walk over
--           them to pick them up (each player sees only their own gems). server/GemMine.
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
		-- 9 Nov: Gem Mine upgrades borrow icons until Willem draws theirs
		MineSpeed = art("119021304569499"), MineDrops = art("129834324837306"), MineValue = art("112913909423142"),
	},
}
G.Icon = G.Art.Icon
-- What rebirths unlock (the rebirth panel shows the next one; 8 Nov)
G.Milestones = {
	{ rebirths = 1, text = "GEM MINE", art = G.Art.Crusher },
	{ rebirths = 3, text = "THE ANNEX", art = G.Art.Gate },
	{ rebirths = 5, text = "AWAKENED GEM CRUSHER", art = G.Art.Awakened },
}
function G.nextMilestone(rebirths: number): any
	for _, m in G.Milestones do if m.rebirths > rebirths then return m end end
	return nil
end
G.Emoji = "💎"
G.UnlockRebirths = 1 -- the Gem Mine and the Gem Shop open after this many rebirths

-- Where Gems come from (shown in the Gem Shop; vault: show where a currency comes from)
G.HowToEarn = "Earn Gems in the GEM MINE: take the teleporter on your plot, pick up what your Gem Crusher crushes"

-- 9 Nov: THE GEM MINE (Willem). A shared area far from the factories (it only streams in
-- when you are there). 10 Nov: ONE big Gem Crusher in the middle that everyone uses; every
-- CrushSeconds (your own upgrades) it crushes out Drops gems worth Value each for you into the
-- glowing zone around it (each player sees only their own); they wait (up to MaxDrops) until you
-- walk within Magnet studs. Rebirth 5 awakens your crusher (x AwakenValue).
-- 10 Nov (Willem: "1 every 6 seconds seems very slow"): a crush every 2 s with 2 gems, base
-- 60 Gems a minute; every Gem price went x6 with it. The mine upgrades reach ~12x, capped.
G.Mine = {
	Origin = CFrame.new(1800, 0, 0), -- far outside the toy room (map spans +-505; streaming 1024)
	Radius = 70, -- floor radius (rocks and crystals on the rim)
	CrusherScale = 1.8, -- the one crusher, x the bay stand-in's size
	Zone = { inner = 13, radius = 25 }, -- gems land between these distances from the crusher
	PortalZ = 44, -- the portal (arrive / go home) and the GEM UPGRADES sign, in front of the crusher
	CrushSeconds = 2, Drops = 2, Value = 1, Magnet = 5,
	MaxDrops = 60,
	AwakenRebirths = 5, AwakenValue = 1.5,
	CollectSlack = 6, -- server distance tolerance (studs) over the magnet radius
	CollectPerSecond = 30, -- most pickups the server accepts per second
	Teleporter = { x = -40, z = 96 }, -- plot-local spot (front left, inside the entrance)
}

-- The Gem Crate: one crusher per open, rarity by these chances (they add up to 1)
G.Crate = {
	Cost = 1500, -- 10 Nov: the mine pays ~60-720 Gems a minute (was 250 at 10-180; 25 before the mine)
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
	-- 9 Nov: GEM MINE upgrades (group "mine", listed first): what your Gem Crusher makes
	{ id = "MineSpeed", group = "mine", title = "Crush Speed", line = "Crushes 0.25 s faster", per = 0.25, max = 4, base = 120, growth = 1.6 },
	{ id = "MineDrops", group = "mine", title = "More Gems", line = "+1 gem per crush", per = 1, max = 2, base = 360, growth = 4 },
	{ id = "MineValue", group = "mine", title = "Gem Value", line = "Gems worth +50%", per = 0.5, max = 2, base = 480, growth = 4 },
	{ id = "Magnet", group = "mine", title = "Gem Magnet", line = "Pick up from 3 studs further", per = 3, max = 5, base = 90, growth = 1.6 },
	{ id = "Cash", title = "Gem Cash", line = "+10% cash per level", per = 0.10, max = 10, base = 90, growth = 1.5 },
	{ id = "Luck", title = "Gem Luck", line = "+10% luck per level", per = 0.10, max = 10, base = 90, growth = 1.5 },
	-- 9 Nov (rebirth data: 170 players at rebirth 1, 66 at rebirth 2: starting over is where
	-- players stop; vault: Progression and Pacing - a rebirth keeps "fast travel to the start
	-- of the furthest region"). HEAD START: each level, a rebirth starts one Factory further
	-- with the bays before it already open (lv 1: FACTORY II + 12 bays; lv 2: FACTORY III + 24).
	-- Never past the factory before the rebirth one (Rebirth.MinPlot), so a rebirth always
	-- needs a run. NEST EGG: start each rebirth with 1% of its price per level (max 5%).
	{ id = "HeadStart", title = "Head Start", line = "Rebirth 1 Factory further on", per = 1, max = 2, base = 240, growth = 3 },
	{ id = "NestEgg", title = "Nest Egg", line = "Rebirth with +1% of its price", per = 0.01, max = 5, base = 150, growth = 1.6 },
	{ id = "Rolls", title = "Quick Rolls", line = "Rolls 0.25 s faster per level", per = 0.25, max = 4, base = 120, growth = 2 },
	-- 8 Nov: a 6th roll pedestal (the purple one in front of the roll machine)
	{ id = "Pedestal", title = "Gem Pedestal", line = "+1 pedestal: 6 choices per roll", per = 1, max = 1, base = 360, growth = 1 },
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
-- 9 Nov: the Gem Mine numbers for a save
local function lv(s: any, id: string): number return (s.gemUps and s.gemUps[id]) or 0 end
function G.mineCrushSeconds(s: any): number return G.Mine.CrushSeconds - 0.25 * lv(s, "MineSpeed") end
function G.mineDrops(s: any): number return G.Mine.Drops + lv(s, "MineDrops") end
function G.mineAwake(s: any): boolean return (s.rebirths or 0) >= G.Mine.AwakenRebirths end
function G.mineValue(s: any): number
	return G.Mine.Value * (1 + 0.5 * lv(s, "MineValue")) * (if G.mineAwake(s) then G.Mine.AwakenValue else 1)
end
function G.mineMagnet(s: any): number return G.Mine.Magnet + 3 * lv(s, "Magnet") end
-- Gems a minute if you pick everything up
function G.minePerMinute(s: any): number return G.mineDrops(s) * G.mineValue(s) * 60 / G.mineCrushSeconds(s) end

return G
