--!strict
-- Collectible crusher economy. Legacy Config numbers remain for save recovery.
local C = {
	Enabled = true, Schema = 2, MaxInventory = 80, MaxLevel = 40,
	MaxGlobal = 20, MaxMoney = 1e300, StartCash = 20,
	BayCosts = { 0, 100, 900 },
	InputDelay = 0.8, Tick = 0.05, RequestInterval = 0.08,
	-- Rolling is free: it fills your unlocked pedestals with offers you can buy.
	RollSeconds = 3, StartPedestals = 1, MaxPedestals = 5,
	MaxPressEmitters = 1, PressParticleRate = 2,
	LevelDamage = 1.12, LevelYield = 1.10, DamageFactor = 1.35, SpeedFactor = 0.94,
	YieldPerLevel = 0.2, LuckPerLevel = 0.12, AutoCrushDamage = 1.25,
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
		{ x = -42, z = 96, yaw = math.pi, perks = { "DoubleCash" } },
		{ x = 13, z = 74, yaw = -math.pi / 2, perks = { "Lucky" } },
	},
	FloorColors = { [4] = Color3.fromRGB(200, 38, 38) }, -- 31 Oct: plot floor colour per plot level (4 = Factory V: red; a bit deeper so the studs show)
	FloorPatchColors = { [4] = Color3.fromRGB(250, 92, 80) }, -- 31 Oct: lighter blocky floor patches per plot level (depth from afar)
	FloorPatchCell = 8, -- studs per patch cell
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
for i=4,C.MaxBays do C.BayCosts[i]=math.floor(900*1.45^(i-3)) end
-- Caps[n] = upgrade caps from plot level n on: factory/roll upgrades (global)
-- and each crusher's level. Below plot level 1 the base MaxGlobal/MaxLevel apply.
-- Level 1 = Factory II (+12 third floor, Coating Lab), 2 = Factory III (+12
-- rear yard, fusion), 3 = Factory IV (+6 rear upper left), 4 = Factory V (+6
-- rear upper right). Costs[n] = 10x the price of its first new bay; Cost =
-- Costs[1] (old name). Caps: +10 factory upgrades, +20 crusher levels each.
C.PlotUpgrade = {MaxLevel=4,
	Costs={math.floor(C.BayCosts[C.TopFirst]*10),math.floor(C.BayCosts[C.RearFirst]*10),
		math.floor(C.BayCosts[C.RearFirst+12]*10),math.floor(C.BayCosts[C.RearFirst+18]*10)},
	Names={"FACTORY II","FACTORY III","FACTORY IV","FACTORY V"},
	Titles={"REINFORCED WORKSHOP","FUSION WORKSHOP","ADVANCED FACTORY","MASTER FACTORY"},
	Adds={12,12,6,6},
	-- what each upgrade adds besides bays (cutscene text) and its accent colour
	Sections={"3RD FLOOR","REAR YARD","REAR UPPER LEFT","REAR UPPER RIGHT"},
	Unlocks={"COATING LAB","FUSION MACHINE",nil,"MASTER FACTORY LOOK"},
	Accents={Color3.fromRGB(255,222,24),Color3.fromRGB(255,140,40),Color3.fromRGB(205,215,228),Color3.fromRGB(255,210,68)},
	Caps={{global=30,level=60},{global=40,level=80},{global=50,level=100},{global=60,level=120}}}
C.PlotUpgrade.Cost=C.PlotUpgrade.Costs[1]
function C.plotCost(level) return C.PlotUpgrade.Costs[level] end
function C.bayCapacity(level)
	if type(level)~="number" or level~=level or level==math.huge then level=0 end
	local n=C.BaseMaxBays
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
	Divine = { "Plane", "Ship" },
	Mythic = { "Planet" },
}
C.Modifiers = {
	{ name = "Standard", weight = 80, mult = 1 }, { name = "Rusty", weight = 14, mult = 1.15 },
	{ name = "Polished", weight = 5, mult = 1.5 }, { name = "Charged", weight = 1, mult = 2 },
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
-- Fusion (unlocks with Factory III, plot level 2): a main crusher plus three
-- unequipped copies of the same type become one fused crusher. The main keeps
-- its id, level and coating; the three copies are used up. One tier for now.
C.Fusion = { PlotLevel=2, Copies=3, Mult=2, MachineScale=1.4, Seconds=600 } -- MachineScale: size of the fuser on the plot (28 Oct: bigger)
C.CoatingBoothScale = 1.35 -- size of the Coating Lab booth on the plot (28 Oct: bigger)
C.Upgrades = {
	Damage = { name = "Damage", group = "Production", base = 20, growth = 1.65 },
	Speed = { name = "Strike speed", group = "Production", base = 30, growth = 1.7 },
	Yield = { name = "Scrap yield", group = "Production", base = 25, growth = 1.65 },
	Luck = { name = "Luck", group = "Rolling", base = 50, growth = 1.75 },
	Pedestals = { name = "Rolling pedestals", group = "Rolling", base = 150, growth = 6, max = 4 },
}
C.UpgradeOrder = { "Damage", "Speed", "Yield", "Luck", "Pedestals" }
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
C.TutorialBonus = 100
-- Goals board on the plot (reference style): like/favorite, join the group, and
-- a free time skip (SkipMinutes of your current production as cash) that needs
-- favorite-prompt confirmation + server-checked group membership, then waits SkipCooldownHours.
C.Goals = { GroupId = 264438399, SkipMinutes = 5, SkipCooldownHours = 24, MinSkipReward = 100 }
-- "1 in N" odds of rolling a type with base weights (no luck).
function C.oddsFor(typeId)
	local total=0 for _,r in C.Rarities do total+=r.weight end
	for _,r in C.Rarities do for _,t in r.types do if t==typeId then
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
function C.money(n) return math.clamp(math.floor(n * 100 + 0.5) / 100, 0, C.MaxMoney) end
function C.globalCost(id, level) local u = C.Upgrades[id] return math.floor(u.base * u.growth ^ level) end
function C.individualCost(item) return math.floor(C.IndividualBase * C.IndividualGrowth ^ (item.level - 1) * C.rarity(item.rarity).mult) end
function C.rollSeconds() return C.RollSeconds end
-- Caps grow with the plot upgrade (PlotUpgrade.Caps). Pedestals keep their own max.
function C.upgradeMax(id,plotLevel)
	local u=C.Upgrades[id] if u.max then return u.max end
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
