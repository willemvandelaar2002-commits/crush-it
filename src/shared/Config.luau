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
	kind: string, -- crush style, see Config.Kinds
	parts: { PartSpec },
	height: number, -- total height (for the ram's rest position)
	width: number, -- widest footprint side (sizes the press)
}

local C = Color3.fromRGB
local V = Vector3.new

-- One object per tier. Simple part models for now; swap in real meshes later
-- without touching game logic (Objects.build only reads `parts`).
Config.Objects = {
	{ name = "Apple", kind = "soft", height = 2.6, width = 2.2, parts = {
		{ shape = "sphere", size = V(2.2, 2.1, 2.2), pos = V(0, 1.05, 0), color = C(214, 38, 38) },
		{ shape = "sphere", size = V(0.7, 0.5, 0.5), pos = V(-0.45, 1.6, -0.75), color = C(255, 120, 120) }, -- shine
		{ shape = "cylinder", size = V(0.2, 0.6, 0.2), pos = V(0, 2.25, 0), color = C(92, 64, 40), rot = V(0, 0, 10) },
		{ shape = "sphere", size = V(0.8, 0.12, 0.45), pos = V(0.4, 2.35, 0), color = C(70, 160, 60), rot = V(0, 0, 20) },
	} },
	{ name = "Teddy Bear", kind = "fluff", height = 4.6, width = 3.2, parts = {
		{ shape = "sphere", size = V(2.8, 2.8, 2.4), pos = V(0, 1.4, 0), color = C(160, 110, 70) },
		{ shape = "sphere", size = V(1.6, 1.6, 0.6), pos = V(0, 1.4, -1.0), color = C(220, 190, 150) }, -- tummy
		{ shape = "sphere", size = V(2, 2, 2), pos = V(0, 3.4, 0), color = C(160, 110, 70) },
		{ shape = "sphere", size = V(0.8, 0.8, 0.5), pos = V(-0.8, 4.2, 0), color = C(140, 95, 60) },
		{ shape = "sphere", size = V(0.8, 0.8, 0.5), pos = V(0.8, 4.2, 0), color = C(140, 95, 60) },
		{ shape = "sphere", size = V(0.8, 0.6, 0.5), pos = V(0, 3.15, -0.85), color = C(220, 190, 150) }, -- snout
		{ shape = "sphere", size = V(0.3, 0.22, 0.2), pos = V(0, 3.3, -1.1), color = C(30, 20, 15) }, -- nose
		{ shape = "sphere", size = V(0.25, 0.3, 0.15), pos = V(-0.4, 3.7, -0.9), color = C(20, 20, 20) },
		{ shape = "sphere", size = V(0.25, 0.3, 0.15), pos = V(0.4, 3.7, -0.9), color = C(20, 20, 20) },
		{ shape = "block", size = V(1.4, 0.35, 0.3), pos = V(0, 2.55, -0.95), color = C(220, 40, 60) }, -- bow tie
	} },
	{ name = "Phone", kind = "glass", height = 5.2, width = 2.8, parts = {
		{ shape = "block", size = V(2.6, 5.2, 0.4), pos = V(0, 2.6, 0), color = C(25, 25, 30) },
		{ shape = "block", size = V(2.3, 4.6, 0.05), pos = V(0, 2.6, -0.21), color = C(40, 90, 200), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.5, 0.5, 0.06), pos = V(-0.65, 4.2, -0.24), color = C(255, 90, 90), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.5, 0.5, 0.06), pos = V(0, 4.2, -0.24), color = C(90, 230, 120), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.5, 0.5, 0.06), pos = V(0.65, 4.2, -0.24), color = C(255, 210, 70), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.5, 0.5, 0.06), pos = V(-0.65, 3.5, -0.24), color = C(200, 120, 255), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.5, 0.5, 0.06), pos = V(0, 3.5, -0.24), color = C(255, 255, 255), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.8, 0.12, 0.06), pos = V(0, 0.55, -0.24), color = C(230, 230, 230), material = Enum.Material.Neon },
		{ shape = "block", size = V(0.9, 0.9, 0.15), pos = V(-0.7, 4.4, 0.25), color = C(40, 40, 45) }, -- camera bump
	} },
	{ name = "TV", kind = "glass", height = 5.2, width = 7, parts = {
		{ shape = "block", size = V(7, 4.2, 0.5), pos = V(0, 3.0, 0), color = C(20, 20, 24) },
		{ shape = "block", size = V(6.5, 3.7, 0.05), pos = V(0, 3.0, -0.26), color = C(70, 170, 255), material = Enum.Material.Neon },
		{ shape = "sphere", size = V(2.2, 1.6, 0.06), pos = V(-1.3, 3.4, -0.29), color = C(255, 230, 120), material = Enum.Material.Neon }, -- sun on screen
		{ shape = "block", size = V(6.5, 1.0, 0.06), pos = V(0, 1.65, -0.29), color = C(80, 200, 100), material = Enum.Material.Neon }, -- grass on screen
		{ shape = "block", size = V(0.6, 1.0, 0.4), pos = V(0, 0.7, 0), color = C(35, 35, 40) },
		{ shape = "block", size = V(3, 0.3, 1.8), pos = V(0, 0.15, 0), color = C(35, 35, 40) },
	} },
	{ name = "Fridge", kind = "metal", height = 8, width = 4, parts = {
		{ shape = "block", size = V(4, 8, 4), pos = V(0, 4, 0), color = C(235, 238, 242) },
		{ shape = "block", size = V(4.02, 0.12, 4.02), pos = V(0, 5.2, 0), color = C(150, 155, 160) },
		{ shape = "block", size = V(0.25, 1.8, 0.25), pos = V(1.5, 6.4, -2.12), color = C(170, 175, 180), material = Enum.Material.Metal },
		{ shape = "block", size = V(0.25, 2.4, 0.25), pos = V(1.5, 3.6, -2.12), color = C(170, 175, 180), material = Enum.Material.Metal },
		{ shape = "block", size = V(0.6, 0.6, 0.1), pos = V(-0.8, 6.6, -2.04), color = C(255, 80, 80) }, -- magnets
		{ shape = "block", size = V(0.6, 0.6, 0.1), pos = V(-0.1, 6.2, -2.04), color = C(80, 160, 255) },
		{ shape = "block", size = V(1.4, 1.8, 0.06), pos = V(-0.6, 3.6, -2.03), color = C(255, 245, 200) }, -- drawing
		{ shape = "block", size = V(3.6, 0.3, 3.6), pos = V(0, 0.15, 0), color = C(60, 60, 65) },
	} },
	{ name = "Car", kind = "metal", height = 5, width = 11, parts = {
		{ shape = "block", size = V(5.6, 2, 11), pos = V(0, 1.9, 0), color = C(30, 110, 220) },
		{ shape = "block", size = V(5, 1.8, 5.5), pos = V(0, 3.8, 0.5), color = C(30, 110, 220) },
		{ shape = "block", size = V(5.1, 1.3, 5.2), pos = V(0, 3.8, 0.5), color = C(150, 210, 255), material = Enum.Material.Glass },
		{ shape = "block", size = V(4.6, 0.3, 0.2), pos = V(0, 2.2, -5.55), color = C(170, 175, 180), material = Enum.Material.Metal }, -- grille
		{ shape = "block", size = V(1.1, 0.6, 0.2), pos = V(-2.1, 2.4, -5.55), color = C(255, 240, 160), material = Enum.Material.Neon },
		{ shape = "block", size = V(1.1, 0.6, 0.2), pos = V(2.1, 2.4, -5.55), color = C(255, 240, 160), material = Enum.Material.Neon },
		{ shape = "block", size = V(1.1, 0.5, 0.2), pos = V(-2.1, 2.4, 5.55), color = C(255, 40, 40), material = Enum.Material.Neon },
		{ shape = "block", size = V(1.1, 0.5, 0.2), pos = V(2.1, 2.4, 5.55), color = C(255, 40, 40), material = Enum.Material.Neon },
		{ shape = "cylinder", size = V(1.8, 0.8, 1.8), pos = V(-2.9, 0.9, 3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.8, 0.8, 1.8), pos = V(2.9, 0.9, 3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.8, 0.8, 1.8), pos = V(-2.9, 0.9, -3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(1.8, 0.8, 1.8), pos = V(2.9, 0.9, -3.4), color = C(20, 20, 20), rot = V(0, 0, 90) },
	} },
	{ name = "Truck", kind = "metal", height = 9, width = 18, parts = {
		{ shape = "block", size = V(7.5, 7, 12), pos = V(0, 5, 3), color = C(225, 225, 230) },
		{ shape = "block", size = V(7.55, 1.2, 12.05), pos = V(0, 5.5, 3), color = C(240, 150, 30) }, -- stripe
		{ shape = "block", size = V(7.5, 5.5, 5), pos = V(0, 4.2, -6.2), color = C(210, 40, 40) },
		{ shape = "block", size = V(7.6, 2, 3), pos = V(0, 5.6, -7.2), color = C(150, 210, 255), material = Enum.Material.Glass },
		{ shape = "block", size = V(1.4, 0.8, 0.2), pos = V(-2.8, 2.6, -8.75), color = C(255, 240, 160), material = Enum.Material.Neon },
		{ shape = "block", size = V(1.4, 0.8, 0.2), pos = V(2.8, 2.6, -8.75), color = C(255, 240, 160), material = Enum.Material.Neon },
		{ shape = "block", size = V(7.6, 0.6, 18), pos = V(0, 1.4, -0.5), color = C(40, 40, 45) }, -- chassis
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(-3.8, 1.3, 6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(3.8, 1.3, 6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(-3.8, 1.3, 2.8), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(3.8, 1.3, 2.8), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(-3.8, 1.3, -6), color = C(20, 20, 20), rot = V(0, 0, 90) },
		{ shape = "cylinder", size = V(2.6, 1, 2.6), pos = V(3.8, 1.3, -6), color = C(20, 20, 20), rot = V(0, 0, 90) },
	} },
	{ name = "Tank", kind = "metal", height = 8, width = 16, parts = {
		{ shape = "block", size = V(10, 2.2, 16), pos = V(0, 1.1, 0), color = C(40, 40, 38), material = Enum.Material.DiamondPlate }, -- tracks
		{ shape = "block", size = V(8, 2.6, 14), pos = V(0, 3.4, 0), color = C(85, 100, 60) },
		{ shape = "wedge", size = V(8, 1.6, 2.5), pos = V(0, 3.9, -8.2), color = C(85, 100, 60) },
		{ shape = "cylinder", size = V(6.4, 2.4, 6.4), pos = V(0, 5.9, 1), color = C(95, 110, 66) },
		{ shape = "block", size = V(4.4, 1.6, 4), pos = V(0, 6.0, -1.5), color = C(95, 110, 66) },
		{ shape = "cylinder", size = V(1, 9, 1), pos = V(0, 6.0, -7), color = C(70, 82, 50), rot = V(90, 0, 0) }, -- barrel
		{ shape = "cylinder", size = V(1.6, 1.4, 1.6), pos = V(0, 6.0, -11.3), color = C(60, 70, 44), rot = V(90, 0, 0) },
		{ shape = "cylinder", size = V(1.8, 0.6, 1.8), pos = V(1.6, 7.4, 2.2), color = C(70, 82, 50) }, -- hatch
		{ shape = "block", size = V(2.4, 0.2, 1.6), pos = V(-2.5, 4.75, 4), color = C(240, 240, 240) }, -- star-ish marking
	} },
	{ name = "House", kind = "wood", height = 18, width = 16, parts = {
		{ shape = "block", size = V(16, 10, 14), pos = V(0, 5, 0), color = C(235, 220, 190) },
		{ shape = "wedge", size = V(16.6, 7, 7.4), pos = V(0, 13.5, 3.7), color = C(170, 60, 50), rot = V(0, 180, 0) },
		{ shape = "wedge", size = V(16.6, 7, 7.4), pos = V(0, 13.5, -3.7), color = C(170, 60, 50) },
		{ shape = "block", size = V(2.2, 5, 2.2), pos = V(4.5, 15.5, 2.5), color = C(130, 70, 55), material = Enum.Material.Brick }, -- chimney
		{ shape = "block", size = V(2.8, 5, 0.3), pos = V(0, 2.5, -7.1), color = C(110, 70, 40), material = Enum.Material.Wood },
		{ shape = "sphere", size = V(0.4, 0.4, 0.3), pos = V(0.9, 2.5, -7.3), color = C(230, 190, 60), material = Enum.Material.Metal },
		{ shape = "block", size = V(3, 2.6, 0.3), pos = V(-4.5, 6.5, -7.1), color = C(255, 230, 140), material = Enum.Material.Neon },
		{ shape = "block", size = V(3, 2.6, 0.3), pos = V(4.5, 6.5, -7.1), color = C(255, 230, 140), material = Enum.Material.Neon },
		{ shape = "block", size = V(3.6, 0.4, 0.5), pos = V(-4.5, 5.0, -7.2), color = C(255, 255, 255) },
		{ shape = "block", size = V(3.6, 0.4, 0.5), pos = V(4.5, 5.0, -7.2), color = C(255, 255, 255) },
		{ shape = "block", size = V(17, 0.6, 15), pos = V(0, 0.3, 0), color = C(120, 120, 125), material = Enum.Material.Concrete },
	} },
	{ name = "Plane", kind = "metal", height = 11, width = 30, parts = {
		{ shape = "cylinder", size = V(5, 24, 5), pos = V(0, 4.5, 0.5), color = C(240, 242, 245), rot = V(90, 0, 0) }, -- fuselage
		{ shape = "sphere", size = V(5, 5, 4), pos = V(0, 4.5, -11.5), color = C(240, 242, 245) }, -- nose
		{ shape = "block", size = V(3.2, 1.2, 0.2), pos = V(0, 5.6, -12.6), color = C(40, 50, 70), rot = V(-30, 0, 0) }, -- cockpit
		{ shape = "block", size = V(5.1, 0.8, 18), pos = V(0, 5.4, 0.5), color = C(40, 90, 200) }, -- window stripe
		{ shape = "block", size = V(30, 0.8, 6), pos = V(0, 3.6, 0), color = C(220, 225, 230) }, -- wings
		{ shape = "cylinder", size = V(2, 4, 2), pos = V(-7.5, 2.4, -0.5), color = C(180, 185, 195), rot = V(90, 0, 0) }, -- engines
		{ shape = "cylinder", size = V(2, 4, 2), pos = V(7.5, 2.4, -0.5), color = C(180, 185, 195), rot = V(90, 0, 0) },
		{ shape = "block", size = V(11, 0.6, 3), pos = V(0, 5.5, 11.5), color = C(220, 225, 230) }, -- tail wings
		{ shape = "wedge", size = V(0.8, 5.5, 4.5), pos = V(0, 9.2, 11.3), color = C(40, 90, 200) }, -- tail fin
		{ shape = "block", size = V(0.8, 2, 0.8), pos = V(0, 1, -7), color = C(60, 60, 65) }, -- gear
		{ shape = "block", size = V(5, 2, 0.8), pos = V(0, 1, 3), color = C(60, 60, 65) },
	} },
	{ name = "Ship", kind = "metal", height = 20, width = 36, parts = {
		{ shape = "block", size = V(12, 7, 32), pos = V(0, 4.5, 2), color = C(30, 40, 60) },
		{ shape = "wedge", size = V(12, 7, 6), pos = V(0, 4.5, -17), color = C(30, 40, 60) }, -- bow
		{ shape = "block", size = V(12.2, 1.6, 32.2), pos = V(0, 1.2, 2), color = C(170, 40, 40) },
		{ shape = "block", size = V(12.3, 0.5, 32.3), pos = V(0, 7.6, 2), color = C(240, 240, 240) },
		{ shape = "block", size = V(9, 5, 14), pos = V(0, 10.5, 5), color = C(240, 240, 240) },
		{ shape = "block", size = V(9.1, 0.8, 13), pos = V(0, 11.5, 5), color = C(255, 220, 120), material = Enum.Material.Neon }, -- windows
		{ shape = "block", size = V(7, 2.5, 7), pos = V(0, 14.2, 7), color = C(240, 240, 240) },
		{ shape = "cylinder", size = V(3, 5, 3), pos = V(0, 17.5, 3), color = C(220, 140, 40) },
		{ shape = "cylinder", size = V(3.1, 1, 3.1), pos = V(0, 19.5, 3), color = C(30, 30, 30) },
		{ shape = "cylinder", size = V(3, 5, 3), pos = V(0, 17.5, 10), color = C(220, 140, 40) },
		{ shape = "cylinder", size = V(3.1, 1, 3.1), pos = V(0, 19.5, 10), color = C(30, 30, 30) },
	} },
	{ name = "Statue", kind = "stone", height = 32, width = 14, parts = {
		{ shape = "block", size = V(14, 4, 14), pos = V(0, 2, 0), color = C(150, 150, 140), material = Enum.Material.Slate },
		{ shape = "block", size = V(10, 2, 10), pos = V(0, 5, 0), color = C(160, 160, 150), material = Enum.Material.Slate },
		{ shape = "block", size = V(6, 15, 5), pos = V(0, 13.5, 0), color = C(95, 170, 140), material = Enum.Material.Metal }, -- robe
		{ shape = "wedge", size = V(6, 3, 2), pos = V(0, 7.5, -3.5), color = C(95, 170, 140), material = Enum.Material.Metal },
		{ shape = "sphere", size = V(4.2, 4.8, 4.2), pos = V(0, 23.2, 0), color = C(95, 170, 140), material = Enum.Material.Metal },
		{ shape = "block", size = V(1.4, 10, 1.4), pos = V(4, 23, 0), color = C(95, 170, 140), material = Enum.Material.Metal, rot = V(0, 0, -15) },
		{ shape = "block", size = V(3, 4, 1), pos = V(-3.4, 15, -1.5), color = C(95, 170, 140), material = Enum.Material.Metal, rot = V(0, 0, 20) }, -- tablet
		{ shape = "cylinder", size = V(1.6, 1.4, 1.6), pos = V(5.3, 28.3, 0), color = C(200, 160, 60), material = Enum.Material.Metal },
		{ shape = "sphere", size = V(2.4, 3.4, 2.4), pos = V(5.3, 30.2, 0), color = C(255, 190, 60), material = Enum.Material.Neon },
		{ shape = "block", size = V(4.6, 1.2, 4.6), pos = V(0, 25.8, 0), color = C(95, 170, 140), material = Enum.Material.Metal }, -- crown
	} },
	{ name = "Planet", kind = "planet", height = 36, width = 36, parts = {
		{ shape = "sphere", size = V(34, 34, 34), pos = V(0, 17, 0), color = C(70, 130, 230) },
		{ shape = "sphere", size = V(20, 10, 24), pos = V(-6, 23, -7), color = C(80, 170, 90) },
		{ shape = "sphere", size = V(14, 9, 12), pos = V(9, 10, -10), color = C(80, 170, 90) },
		{ shape = "sphere", size = V(12, 4, 12), pos = V(0, 33.2, 0), color = C(245, 250, 255) }, -- ice cap
		{ shape = "cylinder", size = V(46, 0.6, 46), pos = V(0, 17, 0), color = C(230, 200, 140), rot = V(14, 0, 18) },
		{ shape = "sphere", size = V(5, 5, 5), pos = V(-15, 31, 6), color = C(200, 200, 210) }, -- moon
	} },
} :: { ObjectDef }

Config.MaxTier = #Config.Objects

-- Sound ids (all free Creator Store audio; swap freely, the client preloads them).
Config.Sounds = {
	Hiss = 9113052976, -- ram going back up
	Thud = 9116488438, -- every press stroke
	Coin = 607665037, -- cash on a crush
	LevelUp = 112485797063762, -- bigger press
	SquishHit = 90416226721742,
	SquishCrush = 116062165012558,
	SparkHit = 122898241692939,
	GlassCrush = 139826391278483,
	MetalHit = 9116771817,
	MetalCrush = 9114016018,
	WoodHit = 9120805690,
	WoodCrush = 9120828958,
	BoomHit = 140278004623742,
	BoomCrush = 138533090376585,
}

-- How each kind of object reacts. Sounds name Config.Sounds keys; the client
-- draws `hitFx` / `crushFx` (see Main.client.luau, "Crush styles").
Config.Kinds = {
	soft = { hitSound = "SquishHit", crushSound = "SquishCrush", hitFx = "droplets", crushFx = "splat" },
	fluff = { hitSound = "SquishHit", crushSound = "SquishCrush", hitFx = "fluff", crushFx = "fluff" },
	glass = { hitSound = "SparkHit", crushSound = "GlassCrush", hitFx = "zap", crushFx = "shards" },
	metal = { hitSound = "MetalHit", crushSound = "MetalCrush", hitFx = "sparks", crushFx = "sparks" },
	wood = { hitSound = "WoodHit", crushSound = "WoodCrush", hitFx = "dust", crushFx = "dust" },
	stone = { hitSound = "MetalHit", crushSound = "WoodCrush", hitFx = "dust", crushFx = "dust" },
	planet = { hitSound = "BoomHit", crushSound = "BoomCrush", hitFx = "fire", crushFx = "explosion" },
}

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
-- Rare versions of every object. Rolled when an object spawns (rarest first).
-- `mult` multiplies the cash it pays; tint/material restyle every part.
Config.Variants = {
	{ id = "Normal", chance = 1, mult = 1 },
	{ id = "Golden", chance = 0.05, mult = 10, tint = C(255, 196, 40), material = Enum.Material.Foil, text = C(255, 210, 60) },
	{ id = "Diamond", chance = 0.005, mult = 50, tint = C(150, 235, 255), material = Enum.Material.Glass, text = C(140, 230, 255) },
}
Config.VariantById = {} :: { [string]: any }
for _, v in Config.Variants do
	Config.VariantById[v.id] = v
end

function Config.rollVariant(): string
	local r = math.random()
	local acc = 0
	for i = #Config.Variants, 2, -1 do
		acc += Config.Variants[i].chance
		if r < acc then
			return Config.Variants[i].id
		end
	end
	return "Normal"
end

-- Rebirth: reset cash, press and upgrades for a permanent cash multiplier.
Config.Rebirth = {
	-- Press tier you need before you can rebirth (Car first, one more each time).
	RequiredTier = function(rebirths: number): number
		return math.min(#Config.Objects, 6 + rebirths)
	end,
	CashPer = 0.5, -- +50% cash per rebirth
}
function Config.rebirthMult(rebirths: number): number
	return 1 + Config.Rebirth.CashPer * rebirths
end

-- Collection book: crushing a version of an object for the first time adds a
-- permanent cash bonus. collection = { ["<tier>"] = { Normal = n, Golden = n, Diamond = n } }
Config.CollectionBonus = { Normal = 0.01, Golden = 0.03, Diamond = 0.1 }
function Config.collectionMult(collection: { [string]: { [string]: number } }): number
	local bonus = 0
	for _, entry in collection do
		for id, n in entry do
			if n > 0 and Config.CollectionBonus[id] then
				bonus += Config.CollectionBonus[id]
			end
		end
	end
	return 1 + bonus
end

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
