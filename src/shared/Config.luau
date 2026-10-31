--!strict
-- Every number in Crush It lives here. Tuned with a simulation (see
-- docs/Systems/Economy.md): next tier after ~1 min, cars ~12 min, tanks
-- ~23 min, planes ~1h20 on a first run; later tiers slow down on purpose
-- (rebirth takes over there).

local Config = {}

-- Faster travel between presses, shops and the train loop for every player.
Config.PlayerWalkSpeed = 28 -- studs per second (Roblox default: 16)

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

-- Background music plays locally and keeps looping through respawns.
Config.Music = {
	Id = 113892640002952,
	Volume = 0.25,
}

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
	-- 31 Oct: own sounds per moment (Creator Store, checked to load in Play)
	Sell = 90531793028786, -- "ka-ching" when you sell scrap
	Collect = 9113849583, -- coins thrown in when you collect the bin
	Click = 15675059323, -- every UI button (Roblox's bright click)
	Roll = 9114073627, -- dice roll when you roll the pedestals
	RevealTick = 9114215633, -- one click per pedestal as it lands
	RevealRare = 117011707307950, -- Rare reveal sparkle
	RevealEpic = 3406813517, -- Epic power-up
	RevealBig = 9067124098, -- Legendary and up: fanfare
	Equip = 9125788628, -- a crusher clunks into a bay / is bought
	CounterTick = 87437544236708, -- the money number over your bin ticking up
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

-- `luck` multiplies the rare chances (Lucky pass = 2).
function Config.rollVariant(luck: number?): string
	local r = math.random()
	local acc = 0
	for i = #Config.Variants, 2, -1 do
		acc += Config.Variants[i].chance * (luck or 1)
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

-- Scrap: crushing no longer pays cash. Each crush drops scrap pieces around
-- the press (worth what the crush used to pay); walk over them to pick them up
-- (no limit) and stand on the sell pad of your scrap shop behind the plot to
-- turn them into cash. Auto Collect pass: pieces fly to you and sell by themselves.
-- (server/Scrap.luau, server/ScrapShop.luau, client/Scrap.client.luau)
Config.Scrap = {
	PiecesMin = 3, -- pieces per crush (more for bigger objects)
	PiecesMax = 6,
	MaxOnFloor = 60, -- per plot; extra value merges into pieces already lying there
	PickupRadius = 5.5, -- studs (horizontal) from your character
	-- Pieces land on one pile behind the press (between the press and the shop);
	-- walk into the pile and you take all of it.
	SellRadius = 5, -- studs from the sell pad centre
	AutoDelay = 0.7, -- Auto Collect: seconds before landed pieces fly to you
}

-- The scrap shop island behind every plot (server/ScrapShop.luau).
Config.ScrapShop = {
	Depth = 34, -- the shop's floor, entrance to back wall
	Width = 48, -- and along its entrance (smelter, its four pads and the board)
}

-- The smelter (Yuzu stand / Destroy a Vault "Smelt"): deposited scrap is smelted
-- into cash over time and waits on the green Collect Cash pad.
-- Everything deposited at once takes SmeltSeconds(level) to finish.
Config.Smelter = {
	SmeltSeconds = function(level: number): number
		return math.max(1, 8 * 0.88 ^ level)
	end,
	SpeedCost = function(level: number): number
		return 20 * 1.7 ^ level
	end,
	SpeedMax = 17,
}

-- Helpers (Mini Presses, after the Yuzu capybaras / tank game tanks): small presses
-- on the slots of the scrap shop island that crush by themselves every Tick seconds
-- and feed what they make straight into your smelter. Buy them on the Buy pad,
-- merge 2 of the same level into 1 of the next on the Merge pad (server/Helpers.luau).
Config.Helpers = {
	Slots = 8,
	MergeCount = 2, -- this many of one level -> one of the next (with 2 you can never get stuck)
	Tick = 3,
	Names = { "Mini Press", "Bronze Press", "Silver Press", "Gold Press", "Ruby Press", "Emerald Press", "Diamond Press", "Rainbow Press" },
	Colors = {
		Color3.fromRGB(150, 156, 170), Color3.fromRGB(205, 127, 50), Color3.fromRGB(215, 222, 235), Color3.fromRGB(255, 200, 50),
		Color3.fromRGB(230, 50, 70), Color3.fromRGB(60, 210, 120), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 110, 230),
	},
	-- cash a helper of `level` makes per tick, at your current press tier
	Value = function(level: number, tier: number): number
		return Config.Economy.ObjectValue(tier) * 2.2 ^ (level - 1)
	end,
	-- price of the next helper when you own `owned` of them
	Cost = function(owned: number, tier: number): number
		return Config.SizeCost(tier) * 0.15 * 1.45 ^ owned
	end,
}

-- Friend boost: extra cash for every Roblox friend in your server (server/FriendBoost.luau).
Config.FriendBoost = { Per = 0.1, Max = 0.5 }

-- Free rewards (server/Rewards.luau, client/Rewards.client.luau).
-- kind "cash": `seconds` worth of your current earning rate (so it grows with you,
-- never less than MinCash); kind "golden": that many Golden objects in a row.
Config.Rewards = {
	MinCash = 25,
	-- kind "cash": `seconds` of your current earnings; kind "crusher": a random
	-- crusher of that rarity, straight into the backpack (cash if it is full).
	-- Playtime: unlock after `minutes` in this session (resets when you rejoin).
	-- Six gift tiles and a grand prize (the last entry, shown in the big rainbow
	-- bar). bonusSeconds: the grand prize also pays that much cash on top.
	-- 29 Oct balance: cash about a third of before, crushers one tier higher.
	Playtime = {
		{ minutes = 2, kind = "cash", seconds = 30 },
		{ minutes = 5, kind = "cash", seconds = 90 },
		{ minutes = 10, kind = "crusher", rarity = "Rare" },
		{ minutes = 15, kind = "cash", seconds = 200 },
		{ minutes = 25, kind = "crusher", rarity = "Epic" },
		{ minutes = 40, kind = "cash", seconds = 600 },
		{ minutes = 60, kind = "crusher", rarity = "Legendary", mythicChance = 0.05, bonusSeconds = 1200 },
	},
	-- Daily check-in: one claim per UTC day; missing a day restarts at day 1;
	-- after day 7 it starts over. Day 7 is the grand prize.
	Daily = {
		{ kind = "cash", seconds = 120 },
		{ kind = "cash", seconds = 240 },
		{ kind = "crusher", rarity = "Rare" },
		{ kind = "cash", seconds = 360 },
		{ kind = "cash", seconds = 480 },
		{ kind = "crusher", rarity = "Epic", mythicChance = 0.01 },
		{ kind = "crusher", rarity = "Legendary", mythicChance = 0.02, bonusSeconds = 1200 },
	},
	-- mythicChance: rare chance a crusher reward becomes a random Mythic instead
	-- crusher rewards when the inventory is full: this many seconds of earnings
	FullInventorySeconds = 240,
}

-- Client guard against falling through floors that haven't streamed in yet
-- (client/SpawnGuard): watched for WatchSeconds after spawning or a teleport.
Config.SpawnGuard = { Probe = 60, WatchSeconds = 3, TeleportJump = 40, MaxHold = 15, StreamTimeout = 10 }

-- Look: the classic Roblox stud pattern on floors, pads and boards.
Config.Look = {
	Theme = "Island", -- see shared/Kit/Style.luau (Island, Factory, Teal, Scrap)
	Props = true, -- trees, rocks, fences and lamps round the plots (server/Decor.luau)
	Sky = "Day", -- Build.lighting preset: "Day", "Sunset", "GoldenHour", "Dusk" or "Smog"
	PropSeed = 7, -- change for a different (but still fixed) layout
}

-- The world (server/Hub.luau, Moat.luau, World.luau): the Toy Train Loop. A round
-- station hub in the middle, 4 walkways out to a ring road with a toy train on it,
-- and the 8 plot islands round the outside, each facing the centre with a short
-- bridge onto the loop.
Config.World = {
	SeaY = -3, -- the yard floor under the islands; falling down there puts you back on your plot
	HubGap = 26, -- gap between a plot island and the loop road (the plot's bridge; 27 Oct: 18 -> 26)
	-- 31 Oct: checkerboard of lighter squares over big floors (like the reference),
	-- so the ground has depth from a distance. A 2x2 checker image, so squares
	-- are StudsPerTile/2 studs. Used on the yellow yard floor and on plot floors
	-- of the levels in CrusherConfig.FloorChecker.
	Checker = {
		Image = "rbxassetid://10630078103", -- white/clear 2x2 checker (Creator Store decal 10630078134)
		StudsPerTile = 8, -- 4-stud squares
		Color = Color3.new(1, 1, 1),
		Transparency = 0.8, -- how strong the lighter squares are
	},
}

Config.Loop = {
	Hub = 56, -- radius of the station hub
	-- (25 Oct: 6 plots per server, so the loop is much smaller; 6 plots of FloorSize
	-- 156 need Plots.Ring >= ~141, see the plot-gap test in Tests/CrusherRules.spec)
	-- (27 Oct: whole map a bit bigger, everything +14: more plaza, wider plot gaps)
	Inner = 148, -- the ring road runs from this radius ...
	Outer = 174, -- ... to this one (26 wide)
	TrainRadius = 161, -- the rails' centre line
	TrainStop = 5, -- seconds a train stands at each plot's stop (shared/TrainRoute.luau)
	TrainMove = 8, -- seconds to drive on to the next stop (45 degrees)
	Trains = 2, -- toy trains on the loop, spread evenly
}

-- World layout: plots round the loop (Plots.originFor).
Config.Plots = {
	Count = 6, -- = players per server (set Players.MaxPlayers to match)
	StartAngle = 30, -- degrees of plot 1; the rest follow every 360 / Count
	Ring = Config.Loop.Outer + Config.World.HubGap, -- centre to a plot's entrance edge (200)
	FloorSize = 156, -- two low crusher banks with stairs and a broad centre aisle
	-- Plot depth, measured from the press centre (plot-local +Z points to the hub):
	--   Front: entrance from the hub bridge, scrap shop (left), upgrade pads (right), scrap pile
	--   Back:  the conveyor from the toy factory hall, Mini Press yards
	Front = 112, -- 27 Oct: 92 -> 112, a longer front yard (more room by the entrance)
	Back = 48,
	ShopX = -12, -- scrap shop entrance line (it opens toward the centre path) ...
	ShopZ = 66, -- ... and its centre along Z
}

-- Every press tier has its own name and paint; the look changes per stage:
--   1 Workshop (1-2)  rusty iron, wooden bed, hand wheel
--   2 Steel (3-5)     painted frame, hazard stripes, twin side cylinders, gauge, control panel
--   3 Industrial (6-8) I-beam pillars, beacons, oil tank + pipes, steam vents
--   4 Mega (9-11)     dark steel with neon edges, energy cells, screen, spinning ring
--   5 Titan (12-13)   black and gold, spikes, energy core with orbiting rings
-- (built by src/server/PressBuilder.luau)
Config.Presses = {
	{ name = "Rusty Press", stage = 1, accent = C(190, 110, 60) },
	{ name = "Workshop Press", stage = 1, accent = C(160, 120, 80) },
	{ name = "Steel Press", stage = 2, accent = C(245, 190, 40) },
	{ name = "Hazard Press", stage = 2, accent = C(255, 140, 30) },
	{ name = "Pro Press", stage = 2, accent = C(225, 55, 50) },
	{ name = "Industrial Press", stage = 3, accent = C(235, 120, 30) },
	{ name = "Factory Press", stage = 3, accent = C(50, 140, 230) },
	{ name = "Heavy Press", stage = 3, accent = C(80, 180, 70) },
	{ name = "Mega Press", stage = 4, accent = C(0, 225, 255) },
	{ name = "Turbo Press", stage = 4, accent = C(80, 255, 120) },
	{ name = "Hyper Press", stage = 4, accent = C(255, 60, 200) },
	{ name = "Titan Press", stage = 5, accent = C(170, 80, 255) },
	{ name = "Cosmic Press", stage = 5, accent = C(90, 210, 255) },
}

-- The press's footprint grows with the object it crushes.
-- Always at least 12% wider than the tier before, so every upgrade is visibly bigger.
local widths: { number } = {}
function Config.pressWidth(tier: number): number
	if widths[tier] then
		return widths[tier]
	end
	local prev = if tier > 1 then Config.pressWidth(tier - 1) * 1.12 else 6
	local w = math.max(6, Config.Objects[tier].width * 1.35, prev)
	widths[tier] = w
	return w
end

Config.Crushers = require(script.Parent.CrusherConfig)
-- Angle (degrees, 0 = +Z / south spoke) of plot `index` round the loop.
function Config.plotAngle(index: number): number
	return Config.Plots.StartAngle + (index - 1) * 360 / Config.Plots.Count
end

return Config
