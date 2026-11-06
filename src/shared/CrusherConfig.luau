--!strict
-- Collectible crusher economy. Legacy Config numbers remain for save recovery.
local C = {
	Enabled = true, Schema = 2, MaxInventory = 80, MaxLevel = 40,
	MaxGlobal = 20, MaxMoney = 1e300, StartCash = 20,
	BayCosts = { 0, 100 }, -- bay 3+ below (1 Nov)
	InputDelay = 0.8, Tick = 0.05, RequestInterval = 0.08,
	PlacingFloor = 0.7, -- 31 Oct: Strike Speed also shortens toy placing (InputDelay x SpeedFactor^level), down to 70%
	CrushedLinger = 0.45, -- 31 Oct: seconds a flattened toy stays on the bed under the next one (visual only)
	-- Rolling is free: it fills your unlocked pedestals with offers you can buy.
	RollSeconds = 3, StartPedestals = 1, MaxPedestals = 5,
	MaxPressEmitters = 1, PressParticleRate = 2,
	LevelDamage = 1.12, LevelYield = 1.10, DamageFactor = 1.35, SpeedFactor = 0.94,
	YieldPerLevel = 0.25, LuckPerLevel = 0.3, AutoCrushDamage = 1.25, -- 31 Oct: Yield 0.2 -> 0.25 per level; 2 Nov: Luck 0.12 -> 0.3 (Willem: way too weak)
	LuckGrowth = 1.015, -- on top of LuckPerLevel, each Luck level also multiplies rare weights by LuckGrowth^rank, so late levels still count (2 Nov: was 1.01)
	OverkillBonus = 0.065, -- 31 Oct: +6.5% scrap per doubling (was 5%) of damage beyond a one-hit crush (Damage keeps paying late game)
	GoldenYield = 10, AutoCollectInterval = 2,
	CameraMaxZoom = 75, ControlsMaxDistance = 170, -- zoom-out limit; how far board/plaque text shows
	QuietLabelDistance = 30, -- 30 Oct: LOCKED pedestal hints and EMPTY bay words only show within this many studs
	TrimPostSpacing = 24, -- 30 Oct: studs between the trim kit's road posts (was 12)
	ScrapCounter = { Width = 11, Height = 2.6, Above = 12, MaxDistance = 80 }, -- 30 Oct: ticking number over your bin, in studs
	-- 31 Oct: Robux signs on every plot (plot-local; yaw turns the sign face toward the walkway)
	RobuxSignSize = Vector2.new(6, 4),
	RobuxSignSpots = {
		-- 31 Oct: right beside the walkway (Willem: they blocked the way to the roller)
		-- (31 Oct, later: Auto Collect beside the bin, 2x Cash beside Sell, Lucky
		-- by the road; no Production Boost sign)
		{ x = -58, z = 78, yaw = math.pi / 2, perks = { "AutoCollect" } },
		-- (5 Nov: the 2x Cash sign beside Sell is gone: Willem; the cash passes are a
		-- ladder now, sold from the button on the right)
		{ x = 13, z = 74, yaw = -math.pi / 2, perks = { "Lucky" } },
		-- (5 Nov: the time-skip signs are gone again: Willem didn't like them by the road;
		-- RobuxSigns can still build product signs if a better spot comes up)
	},
	FloorColors = { [4] = Color3.fromRGB(200, 38, 38) }, -- 31 Oct: plot floor colour per plot level (4 = Factory V: red; a bit deeper so the studs show)
	FloorChecker = { [4] = true }, -- 31 Oct: checkerboard texture on the plot floor (Factory V); look in Config.World.Checker
	FloorStudTile = { [4] = 2 }, -- 31 Oct: floor studs twice as big on Factory V so the pattern shows from afar
	PlaqueDetailDistance = 16, -- 30 Oct: bay plaques show full detail (rarity, LV a > b, MAX, REMOVE) within this many studs
	TravelCooldown = 1.5, HubTravelZ = 62, -- top travel buttons; hub arrival in front of the Mega Crusher
	CashPacks = { CashSmall = 60, CashMedium = 300, CashLarge = 1200 },
	-- Complete one physical six-bay row with a single rarity. Scrap only;
	-- applies to that row, never stacks across rows or changes roll odds.
	RowBonuses = { Common=.05, Uncommon=.10, Rare=.15, Epic=.25, Legendary=.40, Secret=.48, Divine=.54, Mythic=.60 },
}
-- Stadium banks: ground bays open to the plaza, the upper row steps back on
-- top of them (its walkway is the ground bays' roof). Local plot coordinates,
-- +Z points to the plot entrance. Left wing first, then the right; ground
-- floor first, then the upper floors (bought per wing as a "new floor").
C.Layout = { Wings=2, Tiers=2, PerWing=6, WingX=40, Pitch=10, BayWidth=9.6,
	BayZ=-12, BayDepth=12, UpperBack=12, TierHeight=14, WingTilt=0.25,
	StairX=64, StairWidth=10, StairRun=34,
	MachineWidth=8.6, MachineDepth=8, MachineHeight=9.4, MachineZ=2.5, Pedestal=2.4, InteractionDistance=22 }
C.Layout.WalkFront=C.Layout.BayZ+C.Layout.BayDepth/2+1 -- front edge of the upper walkway
C.Layout.StairFront=C.Layout.WalkFront+C.Layout.StairRun
-- Roll pedestals, station-local (x, z) with +z out of the machine's front, in
-- unlock order: centre first, then outwards. #PedestalSpots = MaxPedestals.
C.PedestalSpots = { Vector2.new(0,23), Vector2.new(-11,21), Vector2.new(11,21), Vector2.new(-20.5,15.5), Vector2.new(20.5,15.5) }
C.BaseMaxBays = C.Layout.Wings*C.Layout.Tiers*C.Layout.PerWing
-- Five plot stages (plot level 0..4), bay layout v2 (25 Oct):
--   bays  1..24  Starter Workshop: two floors per wing
--   bays 25..36  Factory II third floor (left wing, then right)
--   bays 37..48  Factory III rear yard banks, ground floor (left, then right)
--   bays 49..54  Factory IV rear yard upper floor, left
--   bays 55..60  Factory V rear yard upper floor, right
-- The rear yard banks copy the wing banks, shifted back by RearShift, untilted.
-- (Layout v1 had a 6-bay rear row at 25..30; CrusherRules.migrate converts.)
C.LayoutVersion = 2
C.TopFirst = C.BaseMaxBays+1
C.RearFirst = C.TopFirst+C.Layout.Wings*C.Layout.PerWing
C.MaxBays = C.RearFirst-1+2*C.Layout.Wings*C.Layout.PerWing
C.Layout.RearShift = -78 -- rear yard banks: ground bays at BayZ+RearShift
C.Layout.RoadHalf = 6 -- central road half-width (rear yard banks keep clear of it)
C.LegacyTypes={"Bumper","Steel","Cobalt","Mega","Titan","Quantum"}
-- 1 Nov: the first 24 bays are much cheaper (funnel: only 5.5% reached Factory II),
-- bay 3 = $250, x1.36 each (bay 24 ~$159K, was $2.2M).
-- 2 Nov (funnel: 71% left between the tutorial and 6 bays): bays 3-6 almost free
-- ($50/$80/$120/$180), then x1.45 blending into the 1 Nov curve by bay 18; and
-- Factory II/III's bays blend back to the old curve (900 x 1.45^(i-3)) over 24
-- bays (by bay 48, was by 36), so Factory III comes much sooner. Factory IV/V and
-- their bays are unchanged.
C.EarlyBayStart, C.EarlyBayGrowth = 250, 1.36
C.FlatBayCurve = true
C.StarterBays = { [3]=50, [4]=80, [5]=120, [6]=180 }
for i=3,C.MaxBays do
	local old=900*1.45^(i-3)
	local curve=C.EarlyBayStart*C.EarlyBayGrowth^(i-3)
	local early=C.StarterBays[i] or (function()
		local w=math.clamp((i-6)/12,0,1) -- 0 at bay 6, 1 from bay 18
		return (180*1.45^(i-6))^(1-w)*curve^w
	end)()
	-- 2 Nov evening (Willem's "making the game faster" doc: the price walls): no
	-- blend back to the old x1.45 curve any more; x1.36 per bay all the way
	-- (bay 36 ~$6.4M was $35M, bay 60 ~$10B was $1.4T)
	local w=if C.FlatBayCurve then 0 else math.clamp((i-C.BaseMaxBays)/24,0,1)
	C.BayCosts[i]=math.floor(early^(1-w)*old^w)
end
-- Caps[n] = upgrade caps from plot level n on: factory/roll upgrades (global)
-- and each crusher's level. Below plot level 1 the base MaxGlobal/MaxLevel apply.
-- 2 Nov (Willem): the starting factory is only the ground floor (C.StartBays =
-- 12); the upper floor became Factory II, so there are 6 factories:
-- Level 1 = Factory II (+12 upper floor), 2 = Factory III (+12 third floor,
-- Coating Lab), 3 = Factory IV (+12 rear yard, fusion), 4 = Factory V (+6 rear
-- upper left), 5 = Factory VI (+6 rear upper right). Costs[n] = 10x the price of
-- its first new bay, with the older discounts kept (Factory III $5M, IV-VI x0.8 /
-- x0.7 / x0.6). Old saves moved up one level (CrusherRules.migrate, plotsV).
C.StartBays = C.Layout.Wings*C.Layout.PerWing -- ground floor: 12 bays
C.PlotUpgrade = {MaxLevel=5,
	-- 2 Nov evening: every factory = 10x its first new bay (no hand-set exceptions):
	-- ~$39K, $2.2M, $87M, $3.5B, $22B (was $39K, $5M, $452M, $167B, $1.33T)
	Costs={math.floor(C.BayCosts[C.StartBays+1]*10),math.floor(C.BayCosts[C.TopFirst]*10),math.floor(C.BayCosts[C.RearFirst]*10),
		math.floor(C.BayCosts[C.RearFirst+12]*10),math.floor(C.BayCosts[C.RearFirst+18]*10)},
	Names={"FACTORY II","FACTORY III","FACTORY IV","FACTORY V","FACTORY VI"},
	Titles={"UPPER FLOOR","REINFORCED WORKSHOP","FUSION WORKSHOP","ADVANCED FACTORY","MASTER FACTORY"},
	Adds={12,12,12,6,6},
	-- what each upgrade adds besides bays (cutscene text) and its accent colour
	Sections={"UPPER FLOOR","3RD FLOOR","REAR YARD","REAR UPPER LEFT","REAR UPPER RIGHT"},
	Unlocks={"COATING LAB",nil,"FUSION MACHINE",nil,"MASTER FACTORY LOOK"},
	Accents={Color3.fromRGB(80,190,255),Color3.fromRGB(255,222,24),Color3.fromRGB(255,140,40),Color3.fromRGB(205,215,228),Color3.fromRGB(255,210,68)},
	-- 2 Nov evening (doc: a capped-out player had nothing to buy for hours): much
	-- higher caps; prices keep rising (x1.65 / x1.38 per level), so it stays a choice
	Caps={{global=30,level=60},{global=40,level=80},{global=55,level=110},{global=70,level=140},{global=90,level=180}}}
-- plot levels where things unlock (2 Nov: each one level later than before)
C.CoatingPlotLevel = 1 -- 2 Nov evening: the Coating Lab comes with Factory II (was III)
-- 2 Nov evening: MERGE was live for a short while and is removed again (Willem:
-- the fuser already does this). Crushers merged in that time keep their stars
-- (item.stars, x Mult cash each); nothing can add stars any more.
C.Merge = { MaxStars = 3, Mult = 1.5 }
-- 2 Nov evening: REBIRTH (long loop; vault: Rebirth and Prestige, doc wave 3).
-- From Factory IV (MinPlot) with Cost x Growth^rebirths cash. Each rebirth adds
-- to a permanent income multiplier (Mult ^ rebirths).
-- 3 Nov (vault: Progression and Pacing, "linear multiplier against exponential cost
-- is the most common mistake"): cash x1.5 per rebirth (x1.5, x2.25, x3.4...), cost x4
-- (Willem, 3 Nov; was x3), so each run takes about 2.7x as long as the one before (was ~5x with +0.5 / x8).
-- (x2 / x4 was tried first: Willem found x32 at 5 rebirths way too much)
C.Rebirth = { MinPlot = 3, Cost = 150e6, Growth = 4, Mult = 1.5, LuckPer = 0.25, StartCash = 1000 }
function C.rebirthCost(n) return math.floor(C.Rebirth.Cost*C.Rebirth.Growth^(n or 0)) end
function C.rebirthMult(n) return C.Rebirth.Mult^(n or 0) end
-- 2 Nov evening (Willem): each rebirth also +25% luck (multiplies the rare-or-better odds, like the Lucky pass)
function C.rebirthLuck(n) return 1+C.Rebirth.LuckPer*(n or 0) end
-- 2 Nov: SMASH + FRENZY (the player's own verb; vault: active play should earn
-- 1.5x-3x idle). Each SMASH tap pays TapPay seconds of your income (at most
-- MaxTaps counted per second) and fills the meter; a full meter (Meter taps)
-- starts FRENZY: every crusher works Speed x faster for Seconds. The meter
-- drains (Drain taps per second) after Idle seconds without tapping.
C.Frenzy = { Meter = 25, Seconds = 10, Speed = 2, TapPay = 0.25, MaxTaps = 4, Idle = 2, Drain = 4, MinTapCash = 1 }
-- 2 Nov: golden toys (doc + Grow a Garden's surprise layer): every 25-45 s one
-- lands at one of your bays for Life seconds; grab it for Seconds of income
-- (at least MinCash), BoostChance of a short boost instead.
C.GoldenToys = { Min = 25, Max = 45, Life = 12, Seconds = { 30, 60 }, MinCash = 25, BoostChance = 0.12, BoostMinutes = 2, FirstDelay = 40 }
-- the old structure levels (third floor = 1, rear yard = 2, ...) for the plot
-- decor / stages built before the split: structural = plot level - 1
function C.structureLevel(plotLevel) return math.max(0,(plotLevel or 0)-1) end
C.PlotUpgrade.Cost=C.PlotUpgrade.Costs[1]
function C.plotCost(level) return C.PlotUpgrade.Costs[level] end
function C.bayCapacity(level)
	if type(level)~="number" or level~=level or level==math.huge then level=0 end
	local n=C.StartBays
	for i=1,math.min(math.floor(level),C.PlotUpgrade.MaxLevel) do n+=C.PlotUpgrade.Adds[i] end
	return n
end
function C.bayLayout(index)
	local l=C.Layout local n=index-1 local perTier=l.Wings*l.PerWing
	if index>=C.RearFirst then
		local k=index-C.RearFirst local tier=math.floor(k/perTier) local j=k%perTier
		local wing=math.floor(j/l.PerWing) local row=j%l.PerWing
		local side=if wing==0 then -1 else 1
		return {x=side*(l.WingX+(row-(l.PerWing-1)/2)*l.Pitch),y=tier*l.TierHeight,z=l.BayZ+l.RearShift-tier*l.UpperBack,
			yaw=0,tier=tier+1,wing=wing+1,row=row+1,side=side,rear=true}
	end
	if index>=C.TopFirst then
		local k=index-C.TopFirst local wing=math.floor(k/l.PerWing) local row=k%l.PerWing
		local side=if wing==0 then -1 else 1
		return {x=side*(l.WingX+(row-(l.PerWing-1)/2)*l.Pitch),y=2*l.TierHeight,z=l.BayZ-2*l.UpperBack,yaw=0,tier=3,wing=wing+1,row=row+1,side=side,top=true}
	end
	-- left wing fills first (inner to outer), then the right; ground, then upper
	local tier=math.floor(n/perTier) local k=n%perTier
	local wing=math.floor(k/l.PerWing) local row=k%l.PerWing
	local side=if wing==0 then -1 else 1
	-- row 1 sits next to the centre walkway, row PerWing at the outer stairs
	local x=side*(l.WingX+(row-(l.PerWing-1)/2)*l.Pitch)
	return {x=x,y=tier*l.TierHeight,z=l.BayZ-tier*l.UpperBack,yaw=0,tier=tier+1,wing=wing+1,row=row+1,side=side}
end
-- Each wing turns about its inner front corner so the outer end comes forward
-- (an open "V" toward the entrance, like the reference). Plot-local CFrame.
function C.wingFrame(side)
	if side==0 then return CFrame.new() end
	local l=C.Layout local ix=side*(l.WingX-(l.PerWing*l.Pitch+2)/2) local pz=l.BayZ+l.BayDepth/2
	return CFrame.new(ix,0,pz)*CFrame.Angles(0,-side*l.WingTilt,0)*CFrame.new(-ix,0,-pz)
end
-- Plot-local frame a bay's x/y/z are given in: wings are turned, the rear row
-- and rear yard banks are not.
function C.bayFrame(layout)
	if layout.rear or layout.side==0 then return CFrame.new() end
	return C.wingFrame(layout.side)
end
-- First bay of a rear yard bank (tier 1 = Factory IV ground, 2 = Factory V upper).
function C.rearStart(tier,wing) return C.RearFirst+(tier-1)*C.Layout.Wings*C.Layout.PerWing+(wing-1)*C.Layout.PerWing end
-- First bay of an upper wing (buying it builds that wing's upper floor).
function C.floorStart(tier,wing) local l=C.Layout
	if tier>=3 then return C.TopFirst+(wing-1)*l.PerWing end
	return (tier-1)*l.Wings*l.PerWing+(wing-1)*l.PerWing+1
end
function C.bayName(index)
	local v=C.bayLayout(index)
	if v.rear then return "Rear "..(if v.tier==2 then "upper " else "")..(if v.wing==1 then "left" else "right").." "..v.row end
	return (if v.tier==1 then "Ground" elseif v.tier==2 then "Upper" else "Top").." "..(if v.wing==1 then "left" else "right").." "..v.row
end
function C.nextBenefit(id,lv)
	local nextLv=math.min(C.MaxGlobal,lv+1)
	if id=="Damage" then return string.format("Damage x%.2f > x%.2f",C.DamageFactor^lv,C.DamageFactor^nextLv) end
	if id=="Speed" then return string.format("Cycle x%.2f > x%.2f",C.SpeedFactor^lv,C.SpeedFactor^nextLv) end
	if id=="Yield" then return string.format("Scrap x%.1f > x%.1f",1+C.YieldPerLevel*lv,1+C.YieldPerLevel*nextLv) end
	if id=="Luck" then return string.format("Rare weights +%d%% > +%d%% / rank",math.floor(C.LuckPerLevel*lv*100),math.floor(C.LuckPerLevel*nextLv*100)) end
	return string.format("Pedestals %d > %d",C.pedestals(lv),C.pedestals(math.min(C.upgradeMax(id),lv+1)))
end
-- Short effect step for the world boards, e.g. "x1.35 > x1.82".
function C.shortBenefit(id,lv)
	local n=math.min(C.MaxGlobal,lv+1)
	if id=="Damage" then return string.format("x%.2f > x%.2f",C.DamageFactor^lv,C.DamageFactor^n) end
	if id=="Speed" then return string.format("%d%% > %d%% faster",math.floor((1-C.SpeedFactor^lv)*100+.5),math.floor((1-C.SpeedFactor^n)*100+.5)) end
	if id=="Yield" then return string.format("x%.1f > x%.1f",1+C.YieldPerLevel*lv,1+C.YieldPerLevel*n) end
	if id=="Luck" then return string.format("+%d%% > +%d%% rares",math.floor(C.LuckPerLevel*lv*100),math.floor(C.LuckPerLevel*n*100)) end
	return string.format("%d > %d pedestals",C.pedestals(lv),C.pedestals(math.min(C.upgradeMax(id),lv+1)))
end
C.Types = {
	{ id = "Bumper", name = "Bumper Press", tier = 1, input = 1, damage = 3, hp = 12, value = 8, cycle = 1.4 },
	{ id = "Steel", name = "Steel Stamp", tier = 3, input = 2, damage = 4, hp = 18, value = 13, cycle = 1.5 },
	{ id = "Cobalt", name = "Cobalt Crusher", tier = 5, input = 2, damage = 7, hp = 28, value = 24, cycle = 1.5 },
	{ id = "Mega", name = "Mega Piston", tier = 7, input = 3, damage = 12, hp = 48, value = 48, cycle = 1.6 },
	{ id = "Titan", name = "Titan Hydraulic", tier = 9, input = 3, damage = 22, hp = 80, value = 100, cycle = 1.7 },
	{ id = "Quantum", name = "Quantum Press", tier = 11, input = 3, damage = 40, hp = 120, value = 220, cycle = 1.8 },
	-- Imported specials use the same production bands and upgrade formulas.
	{ id = "TwinTitan", name = "Twin Titan", template="TwinTitan", tier=9, input=3, damage=22, hp=80, value=100, cycle=1.7 },
	{ id = "RocketPress", name = "Rocket Press", template="RocketPress", tier=5, input=2, damage=7, hp=28, value=24, cycle=1.5 },
	{ id = "Magnetron", name = "Magnetron", template="Magnetron", tier=7, input=3, damage=12, hp=48, value=48, cycle=1.6 },
	{ id = "GoldenKing", name = "Golden King", template="GoldenKing", tier=11, input=3, damage=40, hp=120, value=220, cycle=1.8 },
	{ id = "Toyzilla", name = "Toyzilla", template="Toyzilla", tier=11, input=3, damage=40, hp=120, value=220, cycle=1.8 },
}
C.Rarities = {
	{ name = "Common", price = 30, weight = 69.9912, rank = 0, types = { "Bumper", "Steel" }, mult = 1, color = Color3.fromRGB(155, 179, 203) },
	{ name = "Uncommon", price = 150, weight = 22, rank = 1, types = { "Cobalt", "RocketPress" }, mult = 1.15, color = Color3.fromRGB(99, 210, 132) },
	{ name = "Rare", price = 900, weight = 6, rank = 2, types = { "Mega", "Magnetron" }, mult = 1.35, color = Color3.fromRGB(75, 148, 255) },
	{ name = "Epic", price = 6000, weight = 1.8, rank = 3, types = { "Titan", "TwinTitan" }, mult = 1.65, color = Color3.fromRGB(187, 105, 246) },
	{ name = "Legendary", price = 60000, weight = 0.2, rank = 4, types = { "Quantum", "GoldenKing", "Toyzilla" }, mult = 2, color = Color3.fromRGB(255, 200, 55) },
	-- 6 Nov (Willem's Lucky Weekend pack): LIMITED. Only rollable while the LUCKY WEEKEND
	-- is on (Shared/WeekendConfig; the roll passes `limited`): then eventWeight gives
	-- about 1 in 5,000 rolls for one of its three crushers (1 in 15,000 per crusher),
	-- before luck. Willem: as strong as a Secret (C.LimitedTypes). rank 4.5: between
	-- Legendary and Secret for luck and pity, no big-roll cinematic. Once owned they
	-- stay (ownership, equipping and production don't care about the weekend).
	{ name = "Limited", price = 750000, weight = 0, eventWeight = 0.02, event = "LuckyWeekend", rank = 4.5, types = {}, mult = 2.2, color = Color3.fromRGB(70, 215, 95) },
	-- Chase tiers above Legendary (29 Oct): rollable but very rare, and luck helps
	-- them most (luck scales with rank). Weights give 1 in 50,000 (Secret) and
	-- 1 in 500,000 (Divine) per crusher with four crushers each; Common was
	-- trimmed by the same amount so the total stays 100. Their crushers are in
	-- C.ChaseTypes below.
	{ name = "Secret", price = 750000, weight = 0.008, rank = 5, types = {}, mult = 2.2, color = Color3.fromRGB(120, 122, 150) },
	{ name = "Divine", price = 7500000, weight = 0.0008, rank = 6, types = {}, mult = 2.4, color = Color3.fromRGB(110, 225, 255) },
	-- Mythic: never rolled (weight 0). Only from the Robux shop, a rare Daily
	-- Spin prize, crates and rare playtime/daily reward drops. 3x Legendary
	-- output, still the strongest tier. Keep it LAST in this list.
	{ name = "Mythic", price = 600000, weight = 0, rank = 7, types = {}, mult = 2, color = Color3.fromRGB(255, 70, 190), exclusive = true },
}
-- Extend the real roll catalogue, not just the Index. Each rarity now contains
-- eight types. Existing definitions and legacy migration order are unchanged.
for _, entry in require(script.Parent.CrusherRoster) do
	local band
	for _, existing in C.Types do if existing.id==entry.band then band=existing break end end
	assert(band,"Missing production band for "..entry.id)
	local def=table.clone(band)
	def.id=entry.id def.name=entry.name def.design=entry.design def.accent=entry.color
	def.template=nil
	table.insert(C.Types,def)
	for _, rarity in C.Rarities do if rarity.name==entry.rarity then table.insert(rarity.types,entry.id) break end end
end
-- Mythic specials: Willem's Blender models (ServerStorage.SpecialCrusherMeshes),
-- the Legendary band with 3x the value per input. Appended last so the
-- legacy type order stays the same.
C.Mythics = {
	{ id = "JackpotPress", name = "Jackpot Press" },
	{ id = "SeraphPress", name = "Seraph Press" },
	{ id = "PrismMech", name = "Prism Mech" },
	{ id = "PhantomPirate", name = "Phantom Pirate" },
	{ id = "CandyColossus", name = "Candy Colossus" },
}
for _, m in C.Mythics do
	table.insert(C.Types, { id = m.id, name = m.name, template = m.id, tier = 11, input = 3, damage = 40, hp = 120, value = 660, cycle = 1.8 })
	table.insert(C.Rarities[#C.Rarities].types, m.id)
end
-- Crate crushers (27 Oct Blender pack, assets/crate-crushers): crate-only, so
-- they are NOT in their rarity's roll list (normal rolls, odds and free random
-- drops stay exactly as before). def.rarity names their tier; each copies an
-- existing production band like the roster types do. Tiers are provisional.
C.CrateTypes = {
	{ id = "DuckyDynamo", name = "Ducky Dynamo", rarity = "Epic", band = "Titan" },
	{ id = "WindUpWrecker", name = "Wind-Up Wrecker", rarity = "Epic", band = "Titan" },
	{ id = "GumballGobbler", name = "Gumball Gobbler", rarity = "Epic", band = "Titan" },
	{ id = "ArcadeClaw", name = "Arcade Claw", rarity = "Legendary", band = "Quantum" },
	{ id = "DiscoDestroyer", name = "Disco Destroyer", rarity = "Mythic", band = "JackpotPress" },
	{ id = "KrakenClamp", name = "Kraken Clamp", rarity = "Mythic", band = "JackpotPress" },
}
for _, entry in C.CrateTypes do
	local band
	for _, existing in C.Types do if existing.id == entry.band then band = existing break end end
	assert(band, "Missing production band for " .. entry.id)
	local def = table.clone(band)
	def.id = entry.id def.name = entry.name def.template = entry.id def.design = nil
	def.rarity = entry.rarity def.crate = true
	table.insert(C.Types, def)
end
-- Chase crushers (29 Oct): four Secret and four Divine, rollable. Willem's
-- models live in ServerStorage.SpecialCrusherMeshes (template = id); motion in
-- Shared/ChaseCrusherAssets. A type without a model can borrow a code-built rig
-- with design = "<rig id>" and color instead of template. value: production per input (Legendary is 220, Mythic 660).
C.ChaseTypes = {
	{ id = "ShadowShredder", name = "Shadow Shredder", rarity = "Secret", template = "ShadowShredder" },
	{ id = "VoidVise", name = "Void Vise", rarity = "Secret", template = "VoidVise" },
	{ id = "EclipseEngine", name = "Eclipse Engine", rarity = "Secret", template = "EclipseEngine" },
	{ id = "NightRipper", name = "Night Ripper", rarity = "Secret", template = "NightRipper" },
	{ id = "HaloHammer", name = "Halo Hammer", rarity = "Divine", template = "HaloHammer" },
	{ id = "CelestialCrusher", name = "Celestial Crusher", rarity = "Divine", template = "CelestialCrusher" },
	{ id = "ArchangelAnvil", name = "Archangel Anvil", rarity = "Divine", template = "ArchangelAnvil" },
	{ id = "AuroraPress", name = "Aurora Press", rarity = "Divine", template = "AuroraPress" },
}
C.ChaseValue = { Secret = 330, Divine = 500 }
do
	local band
	for _, existing in C.Types do if existing.id == "Quantum" then band = existing break end end
	for _, entry in C.ChaseTypes do
		local def = table.clone(band)
		def.id = entry.id def.name = entry.name def.design = entry.design def.accent = entry.color
		def.template = entry.template def.value = C.ChaseValue[entry.rarity]
		table.insert(C.Types, def)
		for _, rarity in C.Rarities do if rarity.name == entry.rarity then table.insert(rarity.types, entry.id) break end end
	end
end
-- 6 Nov: the three LIMITED Lucky Weekend crushers (Willem's Blender pack, models in
-- ServerStorage.SpecialCrusherMeshes, motion in Shared/LimitedCrusherAssets). Production
-- like a Secret (Willem: "same as Secret").
C.LimitedTypes = {
	{ id = "CloverOverdrive", name = "Clover Overdrive", template = "CloverOverdrive" },
	{ id = "HorseshoeComet", name = "Horseshoe Comet", template = "HorseshoeComet" },
	{ id = "JackpotFoundry", name = "Jackpot Foundry", template = "JackpotFoundry" },
}
do
	local band
	for _, existing in C.Types do if existing.id == "Quantum" then band = existing break end end
	for _, entry in C.LimitedTypes do
		local def = table.clone(band)
		def.id = entry.id def.name = entry.name def.design = nil def.template = entry.template
		def.value = C.ChaseValue.Secret def.event = "LuckyWeekend"
		table.insert(C.Types, def)
		for _, rarity in C.Rarities do if rarity.name == "Limited" then table.insert(rarity.types, entry.id) break end end
	end
end
-- What a crusher crushes, by its rarity (29 Oct): the toy objects in
-- Config.Objects (meshes in ReplicatedStorage.ObjectMeshes). Rarer crushers get
-- bigger, cooler things; a tier with two picks one at random for each input.
-- Visual only: production and value don't change.
C.RarityObjects = {
	Common = { "Apple" },
	Uncommon = { "Teddy Bear", "Phone" },
	Rare = { "TV", "Fridge" },
	Epic = { "Car", "Truck" },
	Legendary = { "Tank" },
	Secret = { "House", "Statue" },
	Limited = { "House", "Statue" },
	Divine = { "Plane", "Ship" },
	Mythic = { "Planet" },
}
C.Modifiers = {
	-- 31 Oct: rolls only give Standard or Rusty; Polished and Charged are coatings
	-- from the Coating Lab now (weight 0 keeps old rolled ones valid). Was 80/14/5/1.
	{ name = "Standard", weight = 85, mult = 1 }, { name = "Rusty", weight = 15, mult = 1.15 },
	{ name = "Polished", weight = 0, mult = 1.5 }, { name = "Charged", weight = 0, mult = 2 },
}
-- Applied at the late-game Coating Lab only; original roll weights stay intact.
C.CraftModifiers = {{name="Frost",mult=1.65},{name="Fire",mult=1.8}}
C.Coatings = {
	{name="Polished",factor=4,color=Color3.fromRGB(215,235,250)},
	{name="Frost",factor=7,color=Color3.fromRGB(90,225,255)},
	{name="Fire",factor=10,color=Color3.fromRGB(255,120,35)},
	{name="Charged",factor=16,color=Color3.fromRGB(185,95,255)},
}
C.CoatingQuoteSeconds=20
-- Fusion (unlocks with Factory IV, plot level 3 since 2 Nov): a main crusher plus three
-- unequipped copies of the same type become one fused crusher. The main keeps
-- its id, level and coating; the three copies are used up. One tier for now.
C.Fusion = { PlotLevel=3, Copies=3, Mult=2, MachineScale=1.4, Seconds=600 } -- MachineScale: size of the fuser on the plot (28 Oct: bigger)
C.CoatingBoothScale = 1.35 -- size of the Coating Lab booth on the plot (28 Oct: bigger)
C.Upgrades = {
	Damage = { name = "Damage", group = "Production", base = 20, growth = 1.65 },
	Speed = { name = "Strike speed", group = "Production", base = 30, growth = 1.7 },
	Yield = { name = "Scrap yield", group = "Production", base = 25, growth = 1.65 },
	Luck = { name = "Luck", group = "Rolling", base = 50, growth = 1.75 },
	Pedestals = { name = "Rolling pedestals", group = "Rolling", base = 150, growth = 6, max = 4 },
}
C.UpgradeOrder = { "Damage", "Speed", "Yield", "Luck", "Pedestals" }
C.UpgradeMany = 10 -- 3 Nov: the x10 button on the FACTORY UPGRADES board
-- 3 Nov (vault: Genre Playbook - RNG and Collection Games, "pity for the long tail,
-- shown to players"): after Rolls rolls without buying a Legendary or better, one
-- pedestal of every roll shows a Legendary until you buy one. Base Legendary+ odds
-- are about 1 in 480 per pedestal at Luck 0, so this only catches bad streaks.
C.Pity = { Rolls = 200, Rarity = "Legendary", MinRank = 4 }
-- 5 Nov: big roll cinematic (BigRoll.client) for Secret and up. Hold = seconds the
-- pedestal waits after the flicker before the crusher appears (the cinematic's
-- impact lands on it; buying and the next roll wait too). Divine also gives the
-- whole server x AftershockLuck on rolls for AftershockSeconds (Willem: not Secret).
C.BigRoll = { MinRank = 5, PillarSeconds = 30,
	Secret = { Hold = 4.6 }, Divine = { Hold = 6.4, AftershockLuck = 1.5, AftershockSeconds = 30 } }
-- 5 Nov (Willem): a bay holding a Secret or Divine crusher glows (client/SpecialBayFx; 6 Nov: Limited too):
-- a light plate on the pedestal, a colour wash up the back wall, rising sparkles;
-- Divine adds two soft light shafts. Colours match the models (Secret neon purple/pink,
-- Divine gold/cyan). Phones and low graphics get half the sparkles.
C.SpecialBay = {
	Secret = { main = Color3.fromRGB(176, 70, 255), accent = Color3.fromRGB(255, 70, 200), sparkles = 7, shafts = false },
	Divine = { main = Color3.fromRGB(255, 205, 80), accent = Color3.fromRGB(120, 235, 255), sparkles = 9, shafts = true },
	-- 6 Nov: Limited (Lucky Weekend): clover green and gold
	Limited = { main = Color3.fromRGB(70, 225, 100), accent = Color3.fromRGB(255, 205, 60), sparkles = 7, shafts = false },
	PlateTransparency = { 0.5, 0.75 }, PulseSeconds = 1.6, WallHeight = 9,
	-- the bay plaque (Willem: "this stuff that changes"): a colour band sliding across,
	-- a shine sweeping over it and a glowing rim; seconds per slide / per shine
	Plaque = {
		Secret = { Color3.fromRGB(58, 18, 112), Color3.fromRGB(150, 40, 210), Color3.fromRGB(235, 60, 190), Color3.fromRGB(40, 170, 230), Color3.fromRGB(58, 18, 112) },
		Divine = { Color3.fromRGB(190, 110, 20), Color3.fromRGB(235, 165, 40), Color3.fromRGB(250, 205, 90), Color3.fromRGB(60, 150, 230), Color3.fromRGB(190, 110, 20) },
		Limited = { Color3.fromRGB(20, 110, 50), Color3.fromRGB(40, 170, 70), Color3.fromRGB(200, 160, 30), Color3.fromRGB(40, 170, 70), Color3.fromRGB(20, 110, 50) },
		SlideSeconds = 4, ShineEvery = 3.2,
	},
}
C.IndividualBase = 16
C.IndividualGrowth = 1.38
-- Guided tutorial (client/Tutorial): one step at a time, each finished by the
-- named action; target = what the path/arrow points at; reward = cash on
-- finishing the step (TutorialBonus on finishing them all).
C.TutorialSteps = {
	{ id = "Collect", title = "Collect your scrap", text = "Your crusher made scrap! Walk to the blue bin and press COLLECT.", target = "Collect", reward = 10 },
	{ id = "Sell", title = "Sell it for cash", text = "Carry it to the green counter and press SELL.", target = "Sell", reward = 10 },
	{ id = "Roll", title = "Roll a crusher", text = "Press ROLL at the purple roll machine. Rolling is free!", target = "Roll", reward = 10 },
	{ id = "Buy", title = "Buy your crusher", text = "Walk to the pedestal and press E to buy it.", target = "Pedestal", reward = 100 },
	{ id = "Unlock", title = "Unlock a new bay", text = "Press UNLOCK on the next bay's plaque.", target = "NextBay", reward = 25 },
	{ id = "Equip", title = "Place your crusher", text = "Pick it from your hotbar (bottom) and press E at the empty bay. Holding one at a busy bay swaps them.", target = "EmptyBay", reward = 25 },
	{ id = "Upgrade", title = "Upgrade production", text = "FACTORY UPGRADES boosts all your crushers. Buy an upgrade on the blue board.", target = "Production", reward = 25 },
	{ id = "Level", title = "Level up a crusher", text = "THIS CRUSHER: press LEVEL UP on its plaque. Only that crusher levels up; its level stays when swapped.", target = "LevelBay", reward = 50 },
}
C.TutorialBonus = 300 -- 2 Nov: was 100; enough for bay 3 right away
C.StarterScrap = 24 -- 1 Nov: scrap waiting in a new player's bin (three toys' worth), so step 1 is instant
-- 2 Nov: after the 8 tutorial steps the guide keeps going with GOALS up to
-- Factory II (funnel: most players left right after the tutorial). Each goal is
-- checked on the server from the save (server/CrusherGame goalTick) and pays once.
--   check: bays n (unlocked), fill n (crushers in bays), level n (any crusher),
--          upgrades n (factory upgrades bought), rolls n, gift (a playtime gift
--          claimed), index (an Index milestone claimed), row (a rarity row
--          matched), plot n (plot level)
--   reward: { cash = seconds of earnings, min = at least } | { boost = id, minutes }
--           | { crusher = rarity }
--   target: what the arrow points at (client/Tutorial)
-- 2 Nov (v3, Willem): small steps with factory upgrades and crusher levels
-- between the bay goals (they raise income the most). Since the plot split the
-- starting factory has 12 bays, so the chain ends with "Fill 12 bays" and
-- "Buy FACTORY II". "upgrades n" = total factory upgrade levels (Damage + Speed + Yield).
C.Goals2Version = 11 -- 5 Nov: after Factory II "Fill 18 bays" comes before "Coat a crusher"; Factory III prize Legendary (was Epic). 10: 5 Nov: the TURBO goal left the guide (17% churn on it; the pump stays). 9: 4 Nov: quiet goals after Factory II. 8: 3 Nov: the SMASH goal left the guide (30% churn on it; SMASH stays as a free extra)
C.Goals2 = {
	{ id="Fill3", check="fill", n=3, title="Fill 3 bays", text="Unlock bay 3, then roll a crusher and place it there.", target="NextBayOrEmpty", reward={cash=30,min=60} },
	{ id="Upgrades3", check="upgrades", n=3, title="Upgrade your factory", text="The blue FACTORY UPGRADES board makes ALL crushers better.", target="Production", reward={cash=45,min=100} },
	{ id="Fill5", check="fill", n=5, title="Fill 5 bays", text="Unlock more bays and put a crusher in each one.", target="NextBayOrEmpty", reward={cash=45,min=150} },
	{ id="Golden", check="golden", title="Grab a golden toy", text="Golden toys land at your bays every half minute. Walk into one!", target="GoldenToy", reward={cash=45,min=150} },
	{ id="Fill6", check="fill", n=6, title="Fill 6 bays", text="Unlock bay 6 and place a crusher. Prize: a FREE RARE crusher!", target="NextBayOrEmpty", reward={crusher="Rare"} },
	{ id="Level5", check="level", n=5, title="Level a crusher to Lv 5", text="Press LEVEL UP on a crusher's plaque. Higher level = more scrap.", target="LevelBay", reward={cash=60,min=250} },
	{ id="Upgrades8", check="upgrades", n=8, title="Upgrade your factory", text="Factory upgrades make every crusher earn more.", target="Production", reward={cash=60,min=300} },
	{ id="Fill9", check="fill", n=9, title="Fill 9 bays", text="Keep growing your factory!", target="NextBayOrEmpty", reward={cash=90,min=600} },
	{ id="Fill12", check="fill", n=12, title="Fill all 12 bays", text="Every bay full unlocks the FACTORY II upgrade. Prize: a FREE EPIC crusher!", target="NextBayOrEmpty", reward={crusher="Epic"} },
	{ id="Factory2", check="plot", n=1, title="Buy FACTORY II", text="Save up and press UPGRADE on the green board. Big prize!", target="PlotUpgrade", reward={crusher="Legendary"} },
	-- 4 Nov (Willem; vault FTUE "the end of the tutorial needs a successor"): after
	-- Factory II the goals go on QUIETLY (quiet=true): a small "NEXT GOAL" line, no
	-- arrows, no trail, no hints - just a little direction. Not in the funnel.
	{ id="Fill18", check="fill", n=18, quiet=true, title="Fill 18 bays", text="", reward={cash=120,min=3000} },
	{ id="Coat", check="coat", quiet=true, title="Coat a crusher", text="The Coating Lab opened with Factory II.", reward={cash=120,min=3000} },
	{ id="Upgrades20", check="upgrades", n=20, quiet=true, title="Upgrade your factory", text="", reward={cash=150,min=5000} },
	{ id="Fill24", check="fill", n=24, quiet=true, title="Fill all 24 bays", text="", reward={cash=150,min=5000} },
	{ id="Factory3", check="plot", n=2, quiet=true, title="Buy FACTORY III", text="", reward={crusher="Legendary"} },
	{ id="RowSet", check="row", quiet=true, title="Fill a row with one rarity", text="Press FILL ROW at a row's sign.", reward={cash=180,min=8000} },
	{ id="Fill36", check="fill", n=36, quiet=true, title="Fill 36 bays", text="", reward={cash=180,min=8000} },
	{ id="Factory4", check="plot", n=3, quiet=true, title="Buy FACTORY IV", text="", reward={crusher="Legendary"} },
	{ id="Fuse", check="fuse", quiet=true, title="Fuse a crusher", text="The fuser opened with Factory IV.", reward={cash=240,min=20000} },
	{ id="Rebirth1", check="rebirth", quiet=true, title="REBIRTH", text="x1.5 cash and +25% luck forever.", reward={boost="Super",minutes=15} },
}
-- earlier orders (goalsV 1 and 2): a save's goal index is moved to the same goal id
C.Goals2History = {
	{ "Bay3","Fill3","Bay5","Fill5","Gift","Fill6","Level5","Upgrades3","Rolls10","Bay9","Index","Row","Fill12","Bay18","Fill24","Factory2" },
	{ "Bay3","Fill3","Upgrades3","Bay5","Fill5","Gift","Fill6","Level5","Rolls10","Upgrades8","Bay9","Index","Level10","Fill12","Upgrades15","Row","Bay15","Level15","Upgrades24","Bay18","Fill18","Upgrades33","Level20","Bay21","Fill24","Factory2" },
	{ "Bay3","Fill3","Upgrades3","Bay5","Fill5","Gift","Fill6","Level5","Rolls10","Upgrades8","Bay9","Index","Level10","Upgrades12","Fill12","Level15","Factory2" },
	{ "Bay3","Frenzy","Fill3","Upgrades3","Bay5","Fill5","Golden","Gift","Fill6","Turbo","Level5","Rolls10","Upgrades8","Bay9","Index","Level10","Upgrades12","Fill12","Level15","Factory2" },
	{ "Bay3","Frenzy","Fill3","Upgrades3","Bay5","Fill5","Golden","Gift","Fill6","Turbo","Level5","Rolls10","Merge","Upgrades8","Bay9","Index","Level10","Upgrades12","Fill12","Level15","Factory2" },
	{ "Bay3","Frenzy","Fill3","Upgrades3","Bay5","Fill5","Golden","Gift","Fill6","Turbo","Level5","Rolls10","Upgrades8","Bay9","Index","Level10","Upgrades12","Fill12","Level15","Factory2" },
	{ "Frenzy","Fill3","Upgrades3","Fill5","Golden","Fill6","Turbo","Level5","Upgrades8","Fill9","Fill12","Factory2" },
	{ "Fill3","Upgrades3","Fill5","Golden","Fill6","Turbo","Level5","Upgrades8","Fill9","Fill12","Factory2" },
	{ "Fill3","Upgrades3","Fill5","Golden","Fill6","Turbo","Level5","Upgrades8","Fill9","Fill12","Factory2","Coat","Fill18","Upgrades20","Fill24","Factory3","RowSet","Fill36","Factory4","Fuse","Rebirth1" },
	{ "Fill3","Upgrades3","Fill5","Golden","Fill6","Level5","Upgrades8","Fill9","Fill12","Factory2","Coat","Fill18","Upgrades20","Fill24","Factory3","RowSet","Fill36","Factory4","Fuse","Rebirth1" },
}
-- Onboarding funnel step names as they appear in the Creator Dashboard
-- (Analytics > Funnels). 1 = join, 2-9 = the tutorial steps above in order,
-- 10-13 = bays unlocked after the tutorial (1 Nov), 14-17 = each plot upgrade.
-- Numbered so they sort in order.
-- 2 Nov: steps 10.. are the goals (C.Goals2; the last = Factory II), then Factory III-VI
C.FunnelNames = {
	"01 Joined the game", "02 Collected scrap", "03 Sold scrap", "04 Rolled a crusher", "05 Bought a crusher",
	"06 Unlocked a 2nd bay", "07 Placed a crusher", "08 Bought a factory upgrade", "09 Leveled up a crusher (tutorial done)",
}
-- the funnel has the main goals only (quiet goals after Factory II are not steps)
C.MainGoals = 0 for _,g in C.Goals2 do if not g.quiet then C.MainGoals+=1 end end
for i=1,C.MainGoals do table.insert(C.FunnelNames,string.format("%02d Goal: %s",9+i,C.Goals2[i].title)) end
for _,name in {"Factory III","Factory IV","Factory V","Factory VI"} do table.insert(C.FunnelNames,string.format("%02d Bought %s",#C.FunnelNames+1,name)) end
C.FunnelBays = {} -- 2 Nov: replaced by the goals
-- Goals board on the plot (reference style): like/favorite, join the group, and
-- a free time skip (SkipMinutes of your current production as cash) that needs
-- favorite-prompt confirmation + server-checked group membership, then waits SkipCooldownHours.
C.Goals = { GroupId = 264438399, SkipMinutes = 5, SkipCooldownHours = 24, MinSkipReward = 100 }
-- "1 in N" odds of rolling a type with base weights (no luck).
-- 2 Nov: THE roll weights (server roll, roll pedestal odds, Index and upgrade
-- board all use this). luck = Luck upgrade level; lucky = luck multiplier on
-- every non-Common rarity (true = 2: Lucky pass OR 2x Luck boost; 4 = both);
-- bonus = permanent Index luck (0.1 = +10%).
-- limited: the LUCKY WEEKEND is on, so event rarities (Limited) can roll (C.limitedOn)
function C.rollWeights(luck,lucky,bonus,limited)
	local mult=if type(lucky)=="number" then lucky elseif lucky then 2 else 1
	local out={} for i,v in C.Rarities do
		local base=if v.event then (if limited then v.eventWeight or 0 else 0) else v.weight
		out[i]=base*C.luckFactor(luck or 0,v.rank)*(if v.rank>0 then mult*(1+(bonus or 0)) else 1)
	end
	return out
end
-- 6 Nov: is the LUCKY WEEKEND on (so Limited crushers roll)? Same clock as the 2x weekend
-- luck. Studio: workspace attribute WeekendTest = "active" forces it (as the HUD preview).
function C.limitedOn(): boolean
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("WeekendTest") == "active" then return true end
	return require(script.Parent.WeekendConfig).on(os.time())
end
-- "1 in N" for one crusher type with your luck (nil luck = base odds)
function C.effectiveOdds(typeId,luck,lucky,bonus,limited)
	local w=C.rollWeights(luck,lucky,bonus,limited) local total=0 for _,x in w do total+=x end
	for i,r in C.Rarities do for _,t in r.types do if t==typeId then
		if w[i]<=0 then return math.huge end
		return math.max(1,math.floor(total/w[i]*#r.types+.5))
	end end end
	return 1
end
function C.oddsFor(typeId)
	local total=0 for _,r in C.Rarities do total+=r.weight end
	for _,r in C.Rarities do for _,t in r.types do if t==typeId then
		-- (event rarities: their odds while the event is on)
		if r.event and (r.eventWeight or 0)>0 then return math.max(1,math.floor((total+r.eventWeight)/r.eventWeight*#r.types+.5)) end
		if r.weight<=0 then return math.huge end -- Mythic: can't be rolled
		return math.max(1,math.floor(total/r.weight*#r.types+.5))
	end end end
	return 1
end
function C.rarityOf(typeId)
	for _,r in C.Rarities do for _,t in r.types do if t==typeId then return r end end end
	for _,v in C.Types do if v.id==typeId and v.rarity then for _,r in C.Rarities do if r.name==v.rarity then return r end end end end
end
-- Crate-only types (C.CrateTypes) can't be rolled.
function C.isCrateOnly(typeId) for _,v in C.Types do if v.id==typeId then return v.crate==true end end return false end
function C.typeById(id) for _,v in C.Types do if v.id == id then return v end end end
function C.rarity(name) for _,v in C.Rarities do if v.name == name then return v end end end
function C.modifier(name)
	for _,v in C.Modifiers do if v.name==name then return v end end
	for _,v in C.CraftModifiers do if v.name==name then return v end end
end
-- Luck multiplier on a rarity's roll weight (rank 0 = Common stays 1)
C.LuckBoardSecretFrom = 40 -- 5 Nov: the Luck board shows Secret+ odds from this level (Legendary+ before)
function C.luckFactor(luck, rank) return (1 + C.LuckPerLevel * luck * rank) * C.LuckGrowth ^ (luck * rank) end
-- seconds to place the next toy in a bay (Strike Speed shortens it, to PlacingFloor)
function C.inputDelay(speedLevel) return C.InputDelay * math.max(C.PlacingFloor, C.SpeedFactor ^ (speedLevel or 0)) end
function C.money(n) return math.clamp(math.floor(n * 100 + 0.5) / 100, 0, C.MaxMoney) end
function C.globalCost(id, level) local u = C.Upgrades[id] return math.floor(u.base * u.growth ^ level) end
function C.individualCost(item) return math.floor(C.IndividualBase * C.IndividualGrowth ^ (item.level - 1) * C.rarity(item.rarity).mult) end
function C.rollSeconds() return C.RollSeconds end
-- Caps grow with the plot upgrade (PlotUpgrade.Caps). Pedestals keep their own max.
-- Luck keeps the older, lower caps (start, Factory II..VI): its effect grows
-- with the rank of the tier, so the 2 Nov cap raise is for the cash upgrades only
C.LuckCaps={20,25,30,40,50,60}
function C.upgradeMax(id,plotLevel)
	local u=C.Upgrades[id] if u.max then return u.max end
	if id=="Luck" then return C.LuckCaps[math.clamp(math.floor(plotLevel or 0),0,#C.LuckCaps-1)+1] end
	local caps=C.PlotUpgrade.Caps[math.min(plotLevel or 0,#C.PlotUpgrade.Caps)]
	return if caps then caps.global else C.MaxGlobal
end
function C.levelCap(plotLevel)
	local caps=C.PlotUpgrade.Caps[math.min(plotLevel or 0,#C.PlotUpgrade.Caps)]
	return if caps then caps.level else C.MaxLevel
end
-- highest caps any plot can reach (save clamping)
function C.topLevelCap() return C.levelCap(C.PlotUpgrade.MaxLevel) end
function C.topUpgradeMax(id) return C.upgradeMax(id,C.PlotUpgrade.MaxLevel) end
function C.pedestals(level) return math.clamp(C.StartPedestals + (level or 0), 1, C.MaxPedestals) end
-- Price of a rolled offer on a pedestal (rarity price x modifier multiplier).
function C.offerPrice(item) return math.floor(C.rarity(item.rarity).price * C.modifier(item.modifier).mult) end
return C
