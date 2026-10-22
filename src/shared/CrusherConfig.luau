--!strict
-- Collectible crusher economy. Legacy Config numbers remain for save recovery.
local C = {
	Enabled = true, Schema = 2, MaxBays = 3, MaxInventory = 80, MaxLevel = 40,
	MaxGlobal = 20, MaxMoney = 1e300, RollCost = 30, StartCash = 20,
	BayCosts = { 0, 180, 900 }, BayX = { -34, 0, 34 }, BayZ = -38,
	InputDelay = 0.8, Tick = 0.05, RequestInterval = 0.08,
	BaseRollSeconds = 3, MinRollSeconds = 0.65, RollSpeedFactor = 0.93,
	MaxPressEmitters = 1, PressParticleRate = 2,
	LevelDamage = 1.12, LevelYield = 1.10, DamageFactor = 1.35, SpeedFactor = 0.94,
	YieldPerLevel = 0.2, LuckPerLevel = 0.12, AutoCrushDamage = 1.25,
	GoldenYield = 10, AutoCollectInterval = 2,
	CashPacks = { CashSmall = 60, CashMedium = 300, CashLarge = 1200 },
}
C.Types = {
	{ id = "Bumper", name = "Bumper Press", tier = 1, input = 1, damage = 3, hp = 12, value = 8, cycle = 1.4 },
	{ id = "Steel", name = "Steel Stamp", tier = 3, input = 2, damage = 4, hp = 18, value = 13, cycle = 1.5 },
	{ id = "Cobalt", name = "Cobalt Crusher", tier = 5, input = 2, damage = 7, hp = 28, value = 24, cycle = 1.5 },
	{ id = "Mega", name = "Mega Piston", tier = 7, input = 3, damage = 12, hp = 48, value = 48, cycle = 1.6 },
	{ id = "Titan", name = "Titan Hydraulic", tier = 9, input = 3, damage = 22, hp = 80, value = 100, cycle = 1.7 },
	{ id = "Quantum", name = "Quantum Press", tier = 11, input = 3, damage = 40, hp = 120, value = 220, cycle = 1.8 },
}
C.Rarities = {
	{ name = "Common", weight = 70, rank = 0, types = { "Bumper", "Steel" }, mult = 1, color = Color3.fromRGB(155, 179, 203) },
	{ name = "Uncommon", weight = 22, rank = 1, types = { "Cobalt" }, mult = 1.15, color = Color3.fromRGB(99, 210, 132) },
	{ name = "Rare", weight = 6, rank = 2, types = { "Mega" }, mult = 1.35, color = Color3.fromRGB(75, 148, 255) },
	{ name = "Epic", weight = 1.8, rank = 3, types = { "Titan" }, mult = 1.65, color = Color3.fromRGB(187, 105, 246) },
	{ name = "Legendary", weight = 0.2, rank = 4, types = { "Quantum" }, mult = 2, color = Color3.fromRGB(255, 200, 55) },
}
C.Modifiers = {
	{ name = "Standard", weight = 80, mult = 1 }, { name = "Rusty", weight = 14, mult = 1.15 },
	{ name = "Polished", weight = 5, mult = 1.5 }, { name = "Charged", weight = 1, mult = 2 },
}
C.Upgrades = {
	Damage = { name = "Damage", group = "Production", base = 20, growth = 1.65 },
	Speed = { name = "Strike speed", group = "Production", base = 30, growth = 1.7 },
	Yield = { name = "Scrap yield", group = "Production", base = 25, growth = 1.65 },
	Luck = { name = "Luck", group = "Rolling", base = 50, growth = 1.75 },
	RollSpeed = { name = "Rolling speed", group = "Rolling", base = 35, growth = 1.7 },
}
C.UpgradeOrder = { "Damage", "Speed", "Yield", "Luck", "RollSpeed" }
C.IndividualBase = 16
C.IndividualGrowth = 1.38
C.Tutorial = {
	"Your starter crusher works automatically. Collect scrap at the blue bin.",
	"Sell carried scrap at the green seller to earn cash.",
	"Use the roll station to buy a crusher roll ($30). Keep collecting and selling if you need cash.",
	"Open CRUSHERS, select your rolled machine and equip it in a working bay.",
	"Buy a global upgrade at the PRODUCTION board. Collect and sell to afford it.",
	"Buy Luck or Rolling Speed at the ROLLING board.",
	"Level up an individual crusher in CRUSHERS. Its level belongs to that instance.",
	"Keep collecting, selling and rolling. Unlock another working bay for more production!",
}
function C.typeById(id) for _,v in C.Types do if v.id == id then return v end end end
function C.rarity(name) for _,v in C.Rarities do if v.name == name then return v end end end
function C.modifier(name) for _,v in C.Modifiers do if v.name == name then return v end end end
function C.money(n) return math.clamp(math.floor(n * 100 + 0.5) / 100, 0, C.MaxMoney) end
function C.globalCost(id, level) local u = C.Upgrades[id] return math.floor(u.base * u.growth ^ level) end
function C.individualCost(item) return math.floor(C.IndividualBase * C.IndividualGrowth ^ (item.level - 1) * C.rarity(item.rarity).mult) end
function C.rollSeconds(level) return math.max(C.MinRollSeconds, C.BaseRollSeconds * C.RollSpeedFactor ^ level) end
return C
