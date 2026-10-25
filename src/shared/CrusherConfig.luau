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
	TravelCooldown = 1.5, HubTravelZ = 62, -- top travel buttons; hub arrival in front of the Mega Crusher
	CashPacks = { CashSmall = 60, CashMedium = 300, CashLarge = 1200 },
	-- Complete one physical six-bay row with a single rarity. Scrap only;
	-- applies to that row, never stacks across rows or changes roll odds.
	RowBonuses = { Common=.05, Uncommon=.10, Rare=.15, Epic=.25, Legendary=.40 },
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
C.MaxBays = C.Layout.Wings*C.Layout.Tiers*C.Layout.PerWing
C.LegacyTypes={"Bumper","Steel","Cobalt","Mega","Titan","Quantum"}
for i=4,C.MaxBays do C.BayCosts[i]=math.floor(900*1.45^(i-3)) end
function C.bayLayout(index)
	local l=C.Layout local n=index-1 local perTier=l.Wings*l.PerWing
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
	local l=C.Layout local ix=side*(l.WingX-(l.PerWing*l.Pitch+2)/2) local pz=l.BayZ+l.BayDepth/2
	return CFrame.new(ix,0,pz)*CFrame.Angles(0,-side*l.WingTilt,0)*CFrame.new(-ix,0,-pz)
end
-- First bay of an upper wing (buying it builds that wing's upper floor).
function C.floorStart(tier,wing) local l=C.Layout return (tier-1)*l.Wings*l.PerWing+(wing-1)*l.PerWing+1 end
function C.bayName(index)
	local v=C.bayLayout(index)
	return (if v.tier==1 then "Ground" else "Upper").." "..(if v.wing==1 then "left" else "right").." "..v.row
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
	{ name = "Common", price = 30, weight = 70, rank = 0, types = { "Bumper", "Steel" }, mult = 1, color = Color3.fromRGB(155, 179, 203) },
	{ name = "Uncommon", price = 150, weight = 22, rank = 1, types = { "Cobalt", "RocketPress" }, mult = 1.15, color = Color3.fromRGB(99, 210, 132) },
	{ name = "Rare", price = 900, weight = 6, rank = 2, types = { "Mega", "Magnetron" }, mult = 1.35, color = Color3.fromRGB(75, 148, 255) },
	{ name = "Epic", price = 6000, weight = 1.8, rank = 3, types = { "Titan", "TwinTitan" }, mult = 1.65, color = Color3.fromRGB(187, 105, 246) },
	{ name = "Legendary", price = 60000, weight = 0.2, rank = 4, types = { "Quantum", "GoldenKing", "Toyzilla" }, mult = 2, color = Color3.fromRGB(255, 200, 55) },
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
C.Modifiers = {
	{ name = "Standard", weight = 80, mult = 1 }, { name = "Rusty", weight = 14, mult = 1.15 },
	{ name = "Polished", weight = 5, mult = 1.5 }, { name = "Charged", weight = 1, mult = 2 },
}
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
	{ id = "Buy", title = "Buy your crusher", text = "Walk to the pedestal and press E to buy it.", target = "Pedestal", reward = 15 },
	{ id = "Unlock", title = "Unlock a new bay", text = "Press UNLOCK on the next bay's plaque.", target = "NextBay", reward = 25 },
	{ id = "Equip", title = "Place your crusher", text = "Pick it from your hotbar (bottom) and press E at the empty bay.", target = "EmptyBay", reward = 25 },
	{ id = "Upgrade", title = "Upgrade production", text = "FACTORY UPGRADES boosts all your crushers. Buy an upgrade on the blue board.", target = "Production", reward = 25 },
	{ id = "Level", title = "Level up a crusher", text = "THIS CRUSHER: press LEVEL UP on its plaque. Only that crusher levels up; its level stays when swapped.", target = "LevelBay", reward = 50 },
}
C.TutorialBonus = 100
-- Goals board on the plot (reference style): like/favorite, join the group, and
-- a free time skip (SkipMinutes of your current production as cash) that needs
-- group membership and then waits SkipCooldownHours.
C.Goals = { GroupId = 264438399, SkipMinutes = 5, SkipCooldownHours = 24, MinSkipReward = 100 }
-- "1 in N" odds of rolling a type with base weights (no luck).
function C.oddsFor(typeId)
	local total=0 for _,r in C.Rarities do total+=r.weight end
	for _,r in C.Rarities do for _,t in r.types do if t==typeId then
		return math.max(1,math.floor(total/r.weight*#r.types+.5))
	end end end
	return 1
end
function C.rarityOf(typeId) for _,r in C.Rarities do for _,t in r.types do if t==typeId then return r end end end end
function C.typeById(id) for _,v in C.Types do if v.id == id then return v end end end
function C.rarity(name) for _,v in C.Rarities do if v.name == name then return v end end end
function C.modifier(name) for _,v in C.Modifiers do if v.name == name then return v end end end
function C.money(n) return math.clamp(math.floor(n * 100 + 0.5) / 100, 0, C.MaxMoney) end
function C.globalCost(id, level) local u = C.Upgrades[id] return math.floor(u.base * u.growth ^ level) end
function C.individualCost(item) return math.floor(C.IndividualBase * C.IndividualGrowth ^ (item.level - 1) * C.rarity(item.rarity).mult) end
function C.rollSeconds() return C.RollSeconds end
function C.upgradeMax(id) return C.Upgrades[id].max or C.MaxGlobal end
function C.pedestals(level) return math.clamp(C.StartPedestals + (level or 0), 1, C.MaxPedestals) end
-- Price of a rolled offer on a pedestal (rarity price x modifier multiplier).
function C.offerPrice(item) return math.floor(C.rarity(item.rarity).price * C.modifier(item.modifier).mult) end
return C
