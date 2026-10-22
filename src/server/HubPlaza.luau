--!strict
-- The central factory plaza (Willem's "hub reference", 22 Oct): a stepped round
-- stage with the big animated Mega Crusher in the middle, and five stations
-- round it facing the centre: Daily Spin, Top Crushers, Quests, Boosts and
-- Special Crushers. The stations are placeholders ("COMING SOON") until their
-- gameplay exists. Everything is built in world space round (0, floorY, 0);
-- +Z is the south spoke (spawn side).
local CollectionService = game:GetService("CollectionService")
local W = require(script.Parent.Kit.CrusherWorkshop)
local PressBuilder = require(script.Parent.PressBuilder)

local HubPlaza = {}
local V = Vector3.new
local C = Color3.fromRGB
local RED, ORANGE, CHROME = C(222, 52, 52), C(245, 140, 30), C(196, 208, 222)
local GOLD, BLACK = C(255, 196, 40), C(28, 30, 40)
local TOY = { W.Yellow, W.Green, W.Blue, C(230, 69, 77), ORANGE, W.Purple }

HubPlaza.Stage = { 50, 43, 36 } -- tier radii; each tier is 1.4 high
HubPlaza.MegaScale = 1.45
HubPlaza.StationScale = 1.8
HubPlaza.Stations = { -- angle in degrees (0 = south spoke), radius, scale
	Boosts = { 35, 112 }, Quests = { 325, 112 }, Special = { 135, 114 },
	TopCrushers = { 215, 116, 1.45 }, DailySpin = { 250, 108 },
}

local function cyl(parent: Instance, name: string, length: number, d: number, cf: CFrame, color: Color3, solid: boolean?): BasePart
	-- cylinder whose axis is cf's X axis
	local p = W.part(parent, name, V(length, d, d), cf, color, solid)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local UP = CFrame.Angles(0, 0, math.pi / 2) -- turns a cylinder's axis upright
local function upright(parent: Instance, name: string, h: number, d: number, pos: Vector3, color: Color3, solid: boolean?): BasePart
	return cyl(parent, name, h, d, CFrame.new(pos) * UP, color, solid)
end
local function farSigns(gui: SurfaceGui) gui.MaxDistance = 420 end
-- Header sign on two posts: coloured panel with outlined text.
local function header(parent: Instance, cf: CFrame, text: string, color: Color3, width: number)
	local face, gui = W.panel(parent, cf, width, 3.4, color)
	farSigns(gui)
	W.text(gui, "Title", text, UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84))
	return face
end
local function comingSoon(parent: Instance, cf: CFrame)
	local plate = W.part(parent, "ComingSoon", V(9, 1.6, 0.4), cf, BLACK)
	local gui = W.sign(plate)
	farSigns(gui)
	local t = W.text(gui, "Soon", "COMING SOON", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8))
	t.TextColor3 = C(255, 220, 90)
end
-- Low navy base with a hazard lip and lamps on the front corners.
local function base(parent: Instance, f: CFrame, w: number, d: number)
	W.part(parent, "StationBase", V(w, 1, d), f * CFrame.new(0, 0.5, 0), W.Navy, true)
	W.part(parent, "StationTop", V(w - 1, 0.2, d - 1), f * CFrame.new(0, 1.1, 0), C(70, 120, 200), true)
	W.hazard(parent, f * CFrame.new(0, 0.5, d / 2 + 0.1), w, 0.6, 0.3)
	for _, x in { -1, 1 } do W.lamp(parent, f * CFrame.new(x * (w / 2 - 0.6), 1, d / 2 - 0.6), 2.4) end
end

-- Stepped round stage (walkable: each tier is a 1.4 step) with a yellow rail
-- round the top, open toward the four spokes.
local function stage(m: Model, o: CFrame)
	for i, r in HubPlaza.Stage do
		local y = i * 1.4
		local tier = upright(m, "StageTier" .. i, 1.4, r * 2, (o * CFrame.new(0, y - 0.7, 0)).Position, if i % 2 == 1 then W.Navy else W.Blue, true)
		tier.Material = Enum.Material.SmoothPlastic
		-- yellow edge line round each tier (segments, so the top stays blue)
		local n = math.floor(r * 2 * math.pi / 5)
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			W.part(m, "StageEdge", V(r * 2 * math.pi / n + 0.1, 0.12, 0.7), o * CFrame.Angles(0, a, 0) * CFrame.new(0, y + 0.06, r - 0.4), W.Yellow).CastShadow = false
		end
	end
	local top = HubPlaza.Stage[#HubPlaza.Stage]
	local topY = #HubPlaza.Stage * 1.4
	for k = 0, 23 do
		local a = (k + 0.5) / 24 * math.pi * 2
		local open = false
		for _, s in { 0, 90, 180, 270 } do
			if math.abs((math.deg(a) - s + 180) % 360 - 180) < 12 then open = true end
		end
		if not open then
			local cf = o * CFrame.Angles(0, a, 0) * CFrame.new(0, topY, top - 0.6)
			W.part(m, "StageRail", V(top * 2 * math.pi / 24 + 0.3, 0.4, 0.4), cf * CFrame.new(0, 2.6, 0), W.Yellow, true)
			W.part(m, "StageRailPost", V(0.5, 2.8, 0.5), cf * CFrame.new(0, 1.4, 0), W.Navy, true)
			if k % 3 == 1 then W.beacon(m, cf * CFrame.new(0, 2.9, 0)) end
		end
	end
	return topY
end

-- The Mega Crusher: navy towers, chrome guide pillars, orange hydraulics, a red
-- top beam with a gear, a moving ram (tag MegaCrusher, client/Mega.client).
local function megaCrusher(parent: Instance, o: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "MegaCrusher"
	m.Parent = parent
	local bedTop = o.Position.Y + 2.4
	W.part(m, "Bed", V(26, 2.4, 18), o * CFrame.new(0, 1.2, 0), W.Blue, true)
	W.hazard(m, o * CFrame.new(0, 1.2, 9.1), 26, 1, 0.3)
	local beamY = 32
	for _, x in { -1, 1 } do
		W.part(m, "Tower", V(6, beamY, 12), o * CFrame.new(x * 16, beamY / 2, 0), W.Navy, true)
		W.part(m, "TowerTrim", V(6.4, 1, 12.4), o * CFrame.new(x * 16, 4, 0), W.Yellow, true)
		for _, z in { -1, 1 } do
			upright(m, "GuidePillar", beamY - 2.4, 2.4, (o * CFrame.new(x * 11, 2.4 + (beamY - 2.4) / 2, z * 5)).Position, CHROME, true).Material = Enum.Material.Metal
		end
		-- Orange hydraulic cylinder with a chrome rod on the outside of each tower.
		upright(m, "Hydraulic", 14, 4, (o * CFrame.new(x * 21, 20, 0)).Position, ORANGE, true)
		upright(m, "HydraulicRod", 8, 1.6, (o * CFrame.new(x * 21, 9, 0)).Position, CHROME).Material = Enum.Material.Metal
		upright(m, "HydraulicCap", 1.2, 4.6, (o * CFrame.new(x * 21, 27.4, 0)).Position, W.Navy)
		for i = 0, 3 do -- blue hose arching from the cylinder into the beam
			local a = i / 3 * math.pi / 2
			W.part(m, "Hose", V(1.4, 1.4, 1.4), o * CFrame.new(x * (21 - math.sin(a) * 4), 28 + math.sin(a) * 2.2 + (1 - math.cos(a)) * 1.5, 2.6), C(60, 120, 230))
		end
	end
	W.part(m, "TopBeam", V(40, 6, 10), o * CFrame.new(0, beamY + 3, 0), RED, true)
	W.part(m, "BeamStripe", V(40.4, 0.8, 10.4), o * CFrame.new(0, beamY + 0.4, 0), W.Navy, true)
	for _, x in { -17, 17 } do
		local bolt = W.part(m, "BeamBolt", V(1.6, 1.6, 1.6), o * CFrame.new(x, beamY + 3, 5.1), W.Yellow)
		bolt.Shape = Enum.PartType.Ball
	end
	-- Gear on the front of the beam.
	local gear = o * CFrame.new(0, beamY + 3, 5.6)
	cyl(m, "Gear", 0.8, 7, gear * CFrame.Angles(0, math.pi / 2, 0), W.Yellow)
	cyl(m, "GearHub", 1, 3, gear * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.pi / 2, 0), RED)
	for k = 0, 7 do
		W.part(m, "GearTooth", V(1.6, 1.6, 0.8), gear * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, 3.8, 0), W.Yellow)
	end
	upright(m, "TopCylinder", 5, 8, (o * CFrame.new(0, beamY + 8.5, 0)).Position, W.Navy, true)
	upright(m, "TopCap", 1.2, 9, (o * CFrame.new(0, beamY + 11.4, 0)).Position, ORANGE)
	for _, x in { -1, 1 } do W.beacon(m, o * CFrame.new(x * 16, beamY + 6, 0)) end
	-- Ram: a big navy head with a hazard band; the rod moves with it.
	local restY = 19
	local ram = W.part(m, "Ram", V(20, 5, 14), o * CFrame.new(0, restY, 0), W.Navy)
	local follow = Instance.new("Model")
	follow.Name = "RamParts"
	follow.Parent = m
	W.hazard(follow, o * CFrame.new(0, restY - 0.6, 7.1), 20, 1.8, 0.3)
	upright(follow, "RamRod", 12, 6, (o * CFrame.new(0, restY + 8.5, 0)).Position, CHROME).Material = Enum.Material.Metal
	W.part(follow, "RamPlate", V(21, 0.8, 15), o * CFrame.new(0, restY - 2.9, 0), C(50, 56, 70))
	-- Oversized toy dump truck plus loose bricks on the bed (they squash).
	local toy = Instance.new("Model")
	toy.Name = "Toy"
	toy.Parent = m
	local tb = o * CFrame.new(0, 2.4, 0)
	W.part(toy, "TruckChassis", V(5, 1.4, 14), tb * CFrame.new(0, 1.9, 0), C(70, 75, 90))
	W.part(toy, "TruckCab", V(6, 4.4, 4.4), tb * CFrame.new(0, 4.8, 4.8), C(225, 50, 45))
	W.part(toy, "TruckWindow", V(5.2, 1.8, 0.3), tb * CFrame.new(0, 5.6, 7.05), C(150, 210, 245))
	W.part(toy, "TruckBed", V(6.4, 3.6, 8.6), tb * CFrame.new(0, 4.4, -2.2), W.Yellow)
	for _, x in { -1, 1 } do for _, z in { 4.6, -0.6, -4.6 } do
		cyl(toy, "TruckWheel", 1.4, 3, tb * CFrame.new(x * 3.1, 1.5, z), BLACK)
	end end
	for i, p in { V(-9, 0, 4), V(9, 0, -3), V(-8.5, 0, -5), V(9.5, 0, 5) } do
		W.brick(toy, tb * CFrame.new(p) * CFrame.Angles(0, i * 0.7, 0), 2, if i % 2 == 0 then 2 else 1, TOY[i])
	end
	-- the brick models are nested; flatten their parts into Toy so each squashes
	for _, b in toy:GetChildren() do
		if b:IsA("Model") then for _, p in b:GetChildren() do p.Parent = toy end b:Destroy() end
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and (p:IsDescendantOf(toy) or p:IsDescendantOf(follow) or p == ram) then
			p.CanCollide = false
		end
	end
	local toyTop = bedTop
	for _, p in toy:GetChildren() do
		if p:IsA("BasePart") then toyTop = math.max(toyTop, p.Position.Y + p.Size.Y / 2) end
	end
	m.WorldPivot = o
	m:ScaleTo(HubPlaza.MegaScale)
	local bed = m:FindFirstChild("Bed") :: BasePart
	bedTop = bed.Position.Y + bed.Size.Y / 2
	toyTop = bedTop
	for _, p in toy:GetChildren() do
		if p:IsA("BasePart") then toyTop = math.max(toyTop, p.Position.Y + p.Size.Y / 2) end
	end
	m:SetAttribute("BedTop", bedTop)
	m:SetAttribute("RestY", ram.Position.Y)
	m:SetAttribute("HitY", bedTop + (toyTop - bedTop) * 0.3 + ram.Size.Y / 2 + 1.2)
	m:SetAttribute("Period", 7)
	CollectionService:AddTag(m, "MegaCrusher")
	return m
end

-- Station builders. f: frame on the plaza floor, +Z facing the centre.
local function dailySpin(m: Model, f: CFrame)
	base(m, f, 16, 10)
	W.part(m, "WheelStand", V(4, 6, 3), f * CFrame.new(0, 4, -1.5), W.Navy, true)
	local hub = f * CFrame.new(0, 11, 0)
	cyl(m, "GearRim", 1.4, 15, hub * CFrame.Angles(0, math.pi / 2, 0), RED, true)
	for k = 0, 11 do
		W.part(m, "GearTooth", V(2.2, 2.2, 1.4), hub * CFrame.Angles(0, 0, k * math.pi / 6) * CFrame.new(0, 8, 0), RED)
	end
	-- Six coloured segments on the face, each a spoke from the hub outward.
	for k = 0, 5 do
		W.part(m, "WheelSegment", V(3.6, 5.2, 0.4), hub * CFrame.Angles(0, 0, k * math.pi / 3 + math.pi / 6) * CFrame.new(0, 3.4, 0.8), TOY[k + 1])
		local light = W.part(m, "RimLight", V(0.9, 0.9, 0.5), hub * CFrame.Angles(0, 0, k * math.pi / 3) * CFrame.new(0, 6.3, 0.8), W.Yellow)
		light.Material = Enum.Material.Neon
	end
	cyl(m, "WheelHub", 1.2, 3, hub * CFrame.new(0, 0, 1) * CFrame.Angles(0, math.pi / 2, 0), GOLD)
	W.part(m, "Pointer", V(1.6, 2.4, 1), hub * CFrame.new(0, 8.6, 1.2), GOLD)
	header(m, f * CFrame.new(0, 21, 0), "DAILY SPIN", RED, 12)
	comingSoon(m, f * CFrame.new(0, 2.6, 5.1))
end
local function topCrushers(m: Model, f: CFrame)
	base(m, f, 30, 9)
	for i, x in { -9.5, 0, 9.5 } do
		local b = f * CFrame.new(x, 0, -1)
		for _, sx in { -1, 1 } do W.part(m, "BoardPost", V(0.8, 6, 0.8), b * CFrame.new(sx * 3.6, 4, 0), W.Navy, true) end
		local face, gui = W.panel(m, b * CFrame.new(0, 7.8, 0), 7.4, 8, BLACK)
		farSigns(gui)
		W.text(gui, "Board", ({ "TODAY", "ALL TIME", "RAREST" })[i], UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.16))
		for row = 1, 5 do
			local line = Instance.new("Frame")
			line.Position = UDim2.fromScale(0.08, 0.23 + (row - 1) * 0.15)
			line.Size = UDim2.fromScale(0.84, 0.09)
			line.BackgroundColor3 = if row == 1 then GOLD else C(70, 90, 130)
			line.BorderSizePixel = 0
			line.Parent = gui
		end
		-- small crown on each board
		W.part(m, "Crown", V(3, 1, 1), b * CFrame.new(0, 12.6, 0), GOLD)
		for _, cx in { -1.2, 0, 1.2 } do W.part(m, "CrownPoint", V(0.6, 1, 0.6), b * CFrame.new(cx, 13.5, 0), GOLD) end
		local _ = face
	end
	-- trophy on a pedestal behind the boards
	local t = f * CFrame.new(0, 0, -5.5)
	W.part(m, "TrophyPedestal", V(5, 4, 4), t * CFrame.new(0, 3, 0), RED, true)
	upright(m, "TrophyStem", 3, 1.2, (t * CFrame.new(0, 6.5, 0)).Position, GOLD)
	upright(m, "TrophyCup", 3.6, 4, (t * CFrame.new(0, 9.6, 0)).Position, GOLD).Material = Enum.Material.Metal
	header(m, f * CFrame.new(0, 16.4, -1), "TOP CRUSHERS", W.Navy, 16)
	comingSoon(m, f * CFrame.new(0, 2.6, 4.6))
end
local function quests(m: Model, f: CFrame)
	base(m, f, 18, 12)
	W.part(m, "Counter", V(14, 4, 4), f * CFrame.new(0, 3.1, 2), W.Blue, true)
	W.part(m, "CounterTop", V(15, 0.6, 5), f * CFrame.new(0, 5.4, 2), W.Yellow, true)
	W.part(m, "BoothBack", V(16, 11, 1), f * CFrame.new(0, 6.6, -5), W.Navy, true)
	for _, x in { -7.5, 7.5 } do W.part(m, "BoothPost", V(1, 11, 1), f * CFrame.new(x, 6.6, 3.5), W.Navy, true) end
	W.part(m, "BoothRoof", V(18, 1.2, 11), f * CFrame.new(0, 12.6, -0.5), W.Yellow, true)
	-- Foreman behind the counter: hard hat, orange vest.
	local foreman = f * CFrame.new(0, 1.2, -1.5)
	W.part(m, "ForemanLegs", V(2, 2.4, 1), foreman * CFrame.new(0, 1.2, 0), C(50, 70, 140))
	W.part(m, "ForemanBody", V(2.4, 2.6, 1.2), foreman * CFrame.new(0, 3.7, 0), ORANGE)
	W.part(m, "ForemanHead", V(1.6, 1.6, 1.6), foreman * CFrame.new(0, 5.8, 0), C(250, 210, 160))
	W.part(m, "HardHat", V(2, 0.7, 2), foreman * CFrame.new(0, 6.9, 0), W.Yellow)
	-- Notice board beside the booth.
	local n = f * CFrame.new(10.8, 0, 3)
	W.part(m, "NoticePost", V(0.8, 5, 0.8), n * CFrame.new(0, 3.5, 0), W.Navy, true)
	W.part(m, "NoticeBoard", V(3.6, 4.4, 0.4), n * CFrame.new(0, 7, 0), C(240, 236, 220))
	header(m, f * CFrame.new(0, 15, 1), "QUESTS", W.Blue, 12)
	comingSoon(m, f * CFrame.new(0, 3, 4.15))
end
local function boosts(m: Model, f: CFrame)
	base(m, f, 18, 10)
	W.part(m, "Vending", V(15, 13, 6), f * CFrame.new(0, 7.6, -1), W.Purple, true)
	W.part(m, "VendingTrim", V(15.6, 0.8, 6.6), f * CFrame.new(0, 14.4, -1), W.Navy, true)
	W.part(m, "Glass", V(13, 8, 0.3), f * CFrame.new(0, 8.6, 2.1), C(30, 34, 60))
	local cans = { { C(230, 60, 60), -4.2 }, { C(60, 200, 90), 0 }, { C(170, 80, 240), 4.2 } }
	for _, c in cans do
		local can = upright(m, "BoostCan", 5.4, 2.8, (f * CFrame.new(c[2], 8.6, 1.2)).Position, c[1])
		can.Material = Enum.Material.Neon
		upright(m, "CanCap", 0.5, 2.9, (f * CFrame.new(c[2], 11.5, 1.2)).Position, CHROME)
	end
	W.part(m, "Slot", V(6, 1.2, 0.4), f * CFrame.new(0, 3.4, 2.1), BLACK)
	header(m, f * CFrame.new(0, 17.4, -1), "BOOSTS", W.Purple, 12)
	comingSoon(m, f * CFrame.new(0, 2.6, 5.1))
end
local function special(m: Model, f: CFrame)
	upright(m, "DisplayBase", 2, 18, (f * CFrame.new(0, 1, 0)).Position, W.Navy, true)
	upright(m, "DisplayRing", 0.4, 18.6, (f * CFrame.new(0, 2, 0)).Position, W.Yellow)
	upright(m, "DisplayTop", 0.6, 15, (f * CFrame.new(0, 2.3, 0)).Position, C(70, 120, 200), true)
	local built = PressBuilder.build(f * CFrame.new(0, 2.6, 0), 11)
	local _, size = built.model:GetBoundingBox()
	built.model:ScaleTo(math.min(1, 9 / size.X, 9 / size.Z, 11 / size.Y))
	built.model:PivotTo(f * CFrame.new(0, 2.6, 0))
	for _, p in built.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false p.CanTouch = false p.CanQuery = false
			if p.Color.R > 0.3 or p.Color.G > 0.3 then p.Color = GOLD p.Material = Enum.Material.Metal end
		elseif p:IsA("ParticleEmitter") or p:IsA("Light") then p.Enabled = false end
	end
	built.model.Parent = m
	-- glass dome: a clear cylinder with a half-sunk ball on top
	local glass = upright(m, "DomeGlass", 10, 15, (f * CFrame.new(0, 7.6, 0)).Position, C(200, 230, 255))
	glass.Transparency = 0.75 glass.Material = Enum.Material.Glass glass.CastShadow = false
	local cap = W.part(m, "DomeCap", V(15, 15, 15), f * CFrame.new(0, 12.6, 0), C(200, 230, 255))
	cap.Shape = Enum.PartType.Ball cap.Transparency = 0.8 cap.Material = Enum.Material.Glass cap.CastShadow = false
	for k = 0, 15 do -- gold band where the dome meets the glass wall
		W.part(m, "DomeRim", V(3.2, 0.6, 0.6), f * CFrame.Angles(0, k * math.pi / 8, 0) * CFrame.new(0, 12.6, 7.6), GOLD)
	end
	for k = 0, 5 do
		W.lamp(m, f * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 2, 8.3), 1.6)
	end
	-- header on posts in front of the dome
	for _, x in { -6.5, 6.5 } do W.part(m, "SignPost", V(0.8, 16, 0.8), f * CFrame.new(x, 8, 9.8), W.Navy, true) end
	header(m, f * CFrame.new(0, 21.5, 9.8), "SPECIAL CRUSHERS", W.Navy, 16)
	comingSoon(m, f * CFrame.new(0, 3.2, 9.7))
end

function HubPlaza.build(parent: Instance, floorY: number)
	local m = Instance.new("Model")
	m.Name = "FactoryPlaza"
	m.Parent = parent
	local o = CFrame.new(0, floorY, 0)
	local topY = stage(m, o)
	local mega = megaCrusher(m, o * CFrame.new(0, topY, 0))
	-- MEGA CRUSHER sign at the foot of the stage, facing the south spoke.
	local signCf = o * CFrame.new(0, 0, HubPlaza.Stage[1] + 6)
	for _, x in { -11, 11 } do W.part(m, "MegaSignPost", V(1.6, 9, 1.6), signCf * CFrame.new(x, 4.5, 0), W.Navy, true) end
	local face, gui = W.panel(m, signCf * CFrame.new(0, 8.6, 0), 22, 7, W.Blue)
	farSigns(gui)
	local t = W.text(gui, "Title", "MEGA\nCRUSHER", UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.92, 0.88))
	t.TextColor3 = C(255, 214, 80)
	local _ = face
	-- yellow ring line round the stage
	for k = 0, 47 do
		local a = (k + 0.5) / 48 * math.pi * 2
		local p = W.part(m, "RingLine", V(64 * 2 * math.pi / 48 * 0.7, 0.04, 1.2), o * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.03, 64), W.Yellow)
		p.CastShadow = false
	end
	local builders = { DailySpin = dailySpin, TopCrushers = topCrushers, Quests = quests, Boosts = boosts, Special = special }
	for name, spec in HubPlaza.Stations do
		local a = math.rad(spec[1])
		local pos = (o * CFrame.new(math.sin(a) * spec[2], 0, math.cos(a) * spec[2])).Position
		-- +Z faces out toward the ring road, where players arrive from their plots
		local f = CFrame.lookAt(pos, Vector3.new(0, floorY, 0))
		local sm = Instance.new("Model")
		sm.Name = name .. "Station"
		sm:SetAttribute("Placeholder", true)
		builders[name](sm, f)
		sm.WorldPivot = f
		sm:ScaleTo(spec[3] or HubPlaza.StationScale)
		sm.Parent = m
		task.wait()
	end
	return m, mega
end

return HubPlaza
