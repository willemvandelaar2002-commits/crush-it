--!strict
-- Every number in Crush It lives here. Tuned with a simulation (see
-- docs/Systems/Economy.md): next tier after ~1 min, cars ~12 min, tanks
-- ~23 min, planes ~1h20 on a first run; later tiers slow down on purpose
-- (rebirth takes over there).

local Config = {}

export type PartSpec = {
	shape: string, -- "block" | "sphere" | "cylinder" | "wedge"
	size: Vector3, -- studs, before the object's own scale
	pos: Vector3, -- centre, relative to the object's base centre (y = 0 is the bed)
	color: Color3,
	material: Enum.Material?,
	rot: Vector3?, -- degrees
}

export type ObjectDef = {
	name: string,
	parts: { PartSpec },
	height: number, -- total height (for the ram's rest position)
	width: number, -- widest footprint side (sizes the press)
}

local C = Color3.fromRGB
local V = Vector3.new

-- One object per tier. Simple part models for now; swap in real meshes later
-- without touching game logic (Objects.build only reads `parts`).
Config.Objects = {
	{ name = "Apple", height = 2.4, width = 2.2, parts = {
		{ shape = "sphere", size = V(2.2, 2.1, 2.2), pos = V(0, 1.05, 0), color = C(214, 38, 38) },
		{ shape = "cylinder", size = V(0.2, 0.5, 0.2), pos = V(0, 2.25, 0), color = C(92, 64, 40) },
		{ shape = "block", size = V(0.6, 0.1, 0.35), pos = V(0.35, 2.3, 0), color = C(70, 160, 60), rot = V(0, 0, 20) },
	} },
	{ name = "Teddy Bear", height = 4.4, width = 3.2, parts = {
		{ shape = "sphere", size = V(2.8, 2.8, 2.4), pos = V(0, 1.4, 0), color = C(160, 110, 70) },
		{ shape = "sphere", size = V(2, 2, 2), pos = V(0, 3.4, 0), color = C(160, 110, 70) },
		{ shape = "sphere", size = V(0.8, 0.8, 0.5), pos = V(-0.8, 4.2, 0), color = C(140, 95, 60) },
		{ shape = "sphere", size = V(0.8, 0.8, 0.5), pos = V(0.8, 4.2, 0), color = C(140, 95, 60) },
		{ shape = "sphere", size = V(0.7, 0.5, 0.4), pos = V(0, 3.2, -0.9), color = C(220, 190, 150) },
	} },
	{ name = "Phone", height = 5.2, width = 2.8, parts = {
		{ shape = "block", size = V(2.6, 5.2, 0.4), pos = V(0, 2.6, 0), color = C(25, 25, 30), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(2.3, 4.6, 0.05), pos = V(0, 2.6, -0.21), color = C(70, 150, 255), material = Enum.Material.Neon },
	} },
	{ name = "TV", height = 5, width = 7, parts = {
		{ shape = "block", size = V(7, 4.2, 0.6), pos = V(0, 2.9, 0), color = C(20, 20, 24), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(6.4, 3.6, 0.05), pos = V(0, 2.9, -0.31), color = C(120, 200, 255), material = Enum.Material.Neon },
		{ shape = "block", size = V(2, 0.8, 1.6), pos = V(0, 0.4, 0), color = C(35, 35, 40) },
	} },
	{ name = "Fridge", height = 8, width = 4, parts = {
		{ shape = "block", size = V(4, 8, 4), pos = V(0, 4, 0), color = C(235, 238, 242), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(3.9, 0.08, 0.1), pos = V(0, 5.2, -2.02), color = C(150, 155, 160) },
		{ shape = "block", size = V(0.2, 1.8, 0.2), pos = V(1.5, 6.4, -2.1), color = C(170, 175, 180), material = Enum.Material.Metal },
		{ shape = "block", size = V(0.2, 1.8, 0.2), pos = V(1.5, 3.6, -2.1), color = C(170, 175, 180), material = Enum.Material.Metal },
	} },
	{ name = "Car", height = 5, width = 11, parts = {
		{ shape = "block", size = V(5.6, 2, 11), pos = V(0, 1.9, 0), color = C(30, 110, 220), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(5, 1.8, 5.5), pos = V(0, 3.8, 0.5), color = C(30, 110, 220), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(5.05, 1.4, 5), pos = V(0, 3.8, 0.5), color = C(150, 210, 255), material = Enum.Material.Glass },
		{ shape = "cylinder", size = V(1.6, 0.8, 1.6), pos = V(-2.9, 0.8, 3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.6, 0.8, 1.6), pos = V(2.9, 0.8, 3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.6, 0.8, 1.6), pos = V(-2.9, 0.8, -3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.6, 0.8, 1.6), pos = V(2.9, 0.8, -3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
	} },
	{ name = "Truck", height = 9, width = 18, parts = {
		{ shape = "block", size = V(7.5, 7, 12), pos = V(0, 5, 3), color = C(225, 225, 230), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(7.5, 5.5, 5), pos = V(0, 4.2, -6.2), color = C(210, 40, 40), material = Enum.Material.SmoothPlastic },
		{ shape = "block", size = V(7.6, 2, 3), pos = V(0, 5.6, -7.2), color = C(150, 210, 255), material = Enum.Material.Glass },
		{ shape = "cylinder", size = V(2.4, 1, 2.4), pos = V(-3.8, 1.2, 6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.4, 1, 2.4), pos = V(3.8, 1.2, 6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.4, 1, 2.4), pos = V(-3.8, 1.2, -6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.4, 1, 2.4), pos = V(3.8, 1.2, -6), color = C(20, 20, 20), rot = V(0, 0, 90) },
	} },
	{ name = "Tank", height = 8, width = 16, parts = {
		{ shape = "block", size = V(9, 3, 15), pos = V(0, 2.5, 0), color = C(85, 100, 60) },
		{ shape = "block", size = V(10, 1.6, 16), pos = V(0, 0.8, 0), color = C(40, 40, 38) },
		{ shape = "cylinder", size = V(6, 2.4, 6), pos = V(0, 5.2, 1), color = C(95, 110, 66) },
		{ shape = "cylinder", size = V(0.9, 9, 0.9), pos = V(0, 5.3, -5), color = C(70, 82, 50), rot = V(90, 0, 0) },
	} },
	{ name = "House", height = 17, width = 16, parts = {
		{ shape = "block", size = V(16, 10, 14), pos = V(0, 5, 0), color = C(235, 220, 190) },
		{ shape = "wedge", size = V(16, 7, 7), pos = V(0, 13.5, 3.5), color = C(160, 60, 50) },
		{ shape = "wedge", size = V(16, 7, 7), pos = V(0, 13.5, -3.5), color = C(160, 60, 50), rot = V(0, 180, 0) },
		{ shape = "block", size = V(2.6, 5, 0.3), pos = V(0, 2.5, -7.1), color = C(110, 70, 40) },
		{ shape = "block", size = V(3, 2.6, 0.3), pos = V(-4.5, 6, -7.1), color = C(150, 210, 255), material = Enum.Material.Glass },
		{ shape = "block", size = V(3, 2.6, 0.3), pos = V(4.5, 6, -7.1), color = C(150, 210, 255), material = Enum.Material.Glass },
	} },
	{ name = "Plane", height = 10, width = 30, parts = {
		{ shape = "cylinder", size = V(4.5, 26, 4.5), pos = V(0, 4, 0), color = C(240, 242, 245), rot = V(90, 0, 0) },
		{ shape = "block", size = V(30, 0.6, 5), pos = V(0, 3.5, 1), color = C(220, 225, 230) },
		{ shape = "block", size = V(10, 0.5, 3), pos = V(0, 4.5, 11.5), color = C(220, 225, 230) },
		{ shape = "block", size = V(0.6, 5, 3.5), pos = V(0, 8, 11.5), color = C(40, 90, 200) },
	} },
	{ name = "Ship", height = 18, width = 36, parts = {
		{ shape = "block", size = V(12, 7, 36), pos = V(0, 3.5, 0), color = C(30, 40, 60) },
		{ shape = "block", size = V(12.2, 1.5, 36.2), pos = V(0, 1, 0), color = C(170, 40, 40) },
		{ shape = "block", size = V(9, 6, 10), pos = V(0, 10, 6), color = C(240, 240, 240) },
		{ shape = "cylinder", size = V(3, 6, 3), pos = V(0, 15, 8), color = C(220, 140, 40) },
	} },
	{ name = "Statue", height = 32, width = 14, parts = {
		{ shape = "block", size = V(14, 4, 14), pos = V(0, 2, 0), color = C(150, 150, 140), material = Enum.Material.Slate },
		{ shape = "block", size = V(6, 16, 5), pos = V(0, 12, 0), color = C(95, 170, 140), material = Enum.Material.Metal },
		{ shape = "sphere", size = V(4.5, 5, 4.5), pos = V(0, 22.5, 0), color = C(95, 170, 140), material = Enum.Material.Metal },
		{ shape = "block", size = V(1.4, 10, 1.4), pos = V(4, 23, 0), color = C(95, 170, 140), material = Enum.Material.Metal, rot = V(0, 0, -15) },
		{ shape = "sphere", size = V(2.4, 3.4, 2.4), pos = V(5.3, 29.5, 0), color = C(255, 190, 60), material = Enum.Material.Neon },
	} },
	{ name = "Planet", height = 36, width = 36, parts = {
		{ shape = "sphere", size = V(34, 34, 34), pos = V(0, 17, 0), color = C(80, 140, 230) },
		{ shape = "sphere", size = V(20, 6, 24), pos = V(-6, 22, -6), color = C(80, 170, 90) },
		{ shape = "sphere", size = V(14, 5, 12), pos = V(9, 10, -10), color = C(80, 170, 90) },
		{ shape = "cylinder", size = V(52, 0.6, 52), pos = V(0, 17, 0), color = C(230, 200, 140), rot = V(0, 0, 18) },
	} },
} :: { ObjectDef }

Config.MaxTier = #Config.Objects

-- Economy (see docs/Systems/Economy.md for the simulation behind these).
Config.Economy = {
	StartCash = 0,
	ObjectHp = function(tier: number): number
		return 3 * 3.4 ^ (tier - 1)
	end,
	ObjectValue = function(tier: number): number
		return 3 * 6 ^ (tier - 1)
	end,
	BeltSeconds = 0.8, -- time for the next object to roll onto the bed
}

-- Upgrades. `effect(level)` is what the level does; `cost(level)` is the price
-- of going from `level` to `level + 1`; `max` caps the level.
Config.Upgrades = {
	{
		id = "Power", title = "Power", desc = "Damage per press",
		effect = function(l: number): number return 1.28 ^ l end,
		cost = function(l: number): number return 10 * 1.75 ^ l end,
		max = 200,
	},
	{
		id = "Speed", title = "Speed", desc = "Seconds per press",
		effect = function(l: number): number return math.max(0.3, 0.93 ^ l) end,
		cost = function(l: number): number return 15 * 1.8 ^ l end,
		max = 17, -- 0.93^17 ≈ 0.29 → the 0.3 floor
	},
	{
		id = "Value", title = "Value", desc = "Cash per object",
		effect = function(l: number): number return 1 + 0.2 * l end,
		cost = function(l: number): number return 25 * 1.9 ^ l end,
		max = 200,
	},
}

-- Bigger press = next object tier. Price of going from `tier` to `tier + 1`.
Config.SizeCost = function(tier: number): number
	return Config.Economy.ObjectValue(tier) * 10 * 1.32 ^ (tier - 1)
end

-- World layout: 8 plots in two rows of 4 facing a central walkway.
Config.Plots = {
	Count = 8,
	Spacing = 110, -- along X
	RowOffset = 75, -- each row's distance from the walkway centre (Z)
	FloorSize = 90,
}

-- The press's footprint grows with the object it crushes.
function Config.pressWidth(tier: number): number
	return math.max(6, Config.Objects[tier].width * 1.35)
end

return Config
