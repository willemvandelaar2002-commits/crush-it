--!strict
-- The central factory plaza (Willem's "hub reference", 22 Oct): a stepped round
-- stage with the big animated Mega Crusher in the middle, and five stations
-- round it facing the centre: Daily Spin, Top Crushers, Quests, Boosts and
-- Special Crushers. The stations are placeholders ("COMING SOON") until their
-- gameplay exists. Everything is built in world space round (0, floorY, 0);
-- +Z is the south spoke (spawn side).
local CollectionService = game:GetService("CollectionService")
local W = require(script.Parent.Kit.CrusherWorkshop)
local Style = require(game:GetService("ReplicatedStorage").Shared.Kit.Style)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PressBuilder = require(script.Parent.PressBuilder)

local HubPlaza = {}
local V = Vector3.new
local C = Color3.fromRGB
local RED, ORANGE, CHROME = C(222, 52, 52), C(245, 140, 30), C(196, 208, 222)
local GOLD, BLACK = C(255, 196, 40), C(28, 30, 40)
local TOY = { W.Yellow, W.Green, W.Blue, C(230, 69, 77), ORANGE, W.Purple }

HubPlaza.Stage = { 50, 43, 36 } -- tier radii; each tier is 1.4 high
HubPlaza.MegaScale = 1.45
HubPlaza.MegaMeshScale = 1.35 -- AI mesh version
HubPlaza.TruckScale = 1.7
HubPlaza.ModelScale = 1.8 -- Willem's MegaCrusherModel
HubPlaza.StationScale = 1.8
-- Stations spread evenly round the Mega Crusher (every 72 degrees) and all face
-- it. The north walkway is gone (a station stands there); the narrowest
-- stations sit beside the east/west walkways.
HubPlaza.Stations = { -- angle in degrees (0 = south spoke), radius, scale
	-- backs toward the railway (ring road starts at Config.Loop.Inner = 134)
	Quests = { 36, 104 }, DailySpin = { 108, 104 }, Special = { 180, 104 },
	Boosts = { 252, 104 }, TopCrushers = { 324, 104, 1.45 },
}
HubPlaza.Spokes = { 0, 90, 270 } -- walkways (no north one)

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
local function megaParts(parent: Instance, o: CFrame): Model
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

-- Mesh version (place-only AI meshes in ServerStorage.HubMeshes: MegaFrame,
-- MegaRam, MegaTruck; pivots at their bottom centre, fronts facing +Z). The
-- frame carries BedTop / BarBottom attributes (studs above its bottom).
-- Willem's own model (HubMeshes.MegaCrusherModel): Frame_*/Platform_* parts stay,
-- "Ram" moves, "PistonRod" stretches between the top beam and the ram.
local function megaModel(parent: Instance, o: CFrame, t: Model): Model
	local m = t:Clone()
	m.Name = "MegaCrusher"
	local S = HubPlaza.ModelScale
	m:ScaleTo(m:GetScale() * S)
	m:PivotTo(o * CFrame.Angles(0, (t:GetAttribute("FrontYaw") :: number?) or 0, 0))
	local ram = m:FindFirstChild("Ram") :: BasePart
	local rod = m:FindFirstChild("PistonRod") :: BasePart?
	if rod then
		local stretch = Instance.new("Folder")
		stretch.Name = "RamStretch"
		stretch.Parent = m
		rod.Parent = stretch
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			local moving = p == ram or p == rod
			p.CanCollide = not moving
			p.CanTouch = false
		end
	end
	local bedTop = o.Position.Y + ((t:GetAttribute("BedTop") :: number?) or 5.7) * S
	-- toy truck on the bed, sized to fit under the raised ram
	local folder = game:GetService("ServerStorage"):FindFirstChild("HubMeshes")
	local truckT = folder and folder:FindFirstChild("MegaTruck")
	local toy = Instance.new("Model")
	toy.Name = "Toy"
	toy.Parent = m
	if truckT then
		local truck = truckT:Clone()
		local _, ts = truck:GetBoundingBox()
		local room = (ram.Position.Y - ram.Size.Y / 2) - bedTop
		truck:ScaleTo(truck:GetScale() * math.min(room * 0.8 / ts.Y, 20 / ts.Z))
		truck:PivotTo(CFrame.new(o.Position.X, bedTop, o.Position.Z) * CFrame.Angles(0, math.rad(90), 0))
		for _, p in truck:GetDescendants() do
			if p:IsA("BasePart") then p.CanCollide = false p.CanTouch = false p.CanQuery = false p.Parent = toy end
		end
		truck:Destroy()
	end
	local toyTop = bedTop
	for _, p in toy:GetChildren() do
		if p:IsA("BasePart") then toyTop = math.max(toyTop, p.Position.Y + p.Size.Y / 2) end
	end
	m:SetAttribute("BedTop", bedTop)
	m:SetAttribute("RestY", ram.Position.Y)
	m:SetAttribute("HitY", bedTop + (toyTop - bedTop) * 0.35 + ram.Size.Y / 2)
	m:SetAttribute("Period", 7)
	m:SetAttribute("OwnSign", true)
	m.Parent = parent
	CollectionService:AddTag(m, "MegaCrusher")
	return m
end

local function megaCrusher(parent: Instance, o: CFrame): Model
	local folder = game:GetService("ServerStorage"):FindFirstChild("HubMeshes")
	local own = folder and folder:FindFirstChild("MegaCrusherModel")
	if own and own:IsA("Model") then return megaModel(parent, o, own) end
	local frameT = folder and folder:FindFirstChild("MegaFrame")
	local ramT = folder and folder:FindFirstChild("MegaRam")
	local truckT = folder and folder:FindFirstChild("MegaTruck")
	if not (frameT and ramT and truckT) then return megaParts(parent, o) end
	local m = Instance.new("Model")
	m.Name = "MegaCrusher"
	m.Parent = parent
	local S = HubPlaza.MegaMeshScale
	local bedOffset = ((frameT:GetAttribute("BedTop") :: number?) or 5) * S
	local barOffset = ((frameT:GetAttribute("BarBottom") :: number?) or 37) * S
	local frame = frameT:Clone()
	frame.Name = "Frame"
	frame:ScaleTo(S)
	frame:PivotTo(o)
	frame.Parent = m
	-- the ram's single mesh part is the moving "Ram" the client animates
	local ramModel = ramT:Clone()
	ramModel:ScaleTo(S)
	local _, ramSize = ramModel:GetBoundingBox()
	ramModel:PivotTo(o * CFrame.new(0, barOffset - ramSize.Y - 0.3, 0))
	local ram = ramModel:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	ram.Name = "Ram"
	ram.CanCollide = false ram.CanTouch = false ram.CanQuery = false
	ram.Parent = m
	ramModel:Destroy()
	local toy = Instance.new("Model")
	toy.Name = "Toy"
	toy.Parent = m
	local truck = truckT:Clone()
	truck:ScaleTo(S * HubPlaza.TruckScale)
	truck:PivotTo(o * CFrame.new(0, bedOffset, 0) * CFrame.Angles(0, math.rad(-20), 0))
	for _, p in truck:GetDescendants() do
		if p:IsA("BasePart") then p.CanCollide = false p.CanTouch = false p.CanQuery = false p.Parent = toy end
	end
	truck:Destroy()
	local bedTop = o.Position.Y + bedOffset
	local toyTop = bedTop
	for _, p in toy:GetChildren() do
		if p:IsA("BasePart") then toyTop = math.max(toyTop, p.Position.Y + p.Size.Y / 2) end
	end
	m:SetAttribute("BedTop", bedTop)
	m:SetAttribute("RestY", ram.Position.Y)
	-- the ram's mesh includes its rod, so its bottom is RestY - Size.Y/2
	m:SetAttribute("HitY", bedTop + (toyTop - bedTop) * 0.35 + ram.Size.Y / 2)
	m:SetAttribute("Period", 7)
	CollectionService:AddTag(m, "MegaCrusher")
	return m
end

-- Station mesh (place-only, ServerStorage.HubMeshes.Station_<Name>, pivot at the
-- bottom centre, front facing +Z) placed on frame f; nil when there is none.
local Widths = { DailySpin = 14, TopCrushers = 27, Quests = 17, Boosts = 14 } -- fit to each base
local function hubMesh(name: string): Model?
	local folder = game:GetService("ServerStorage"):FindFirstChild("HubMeshes")
	local t = folder and folder:FindFirstChild(name)
	return if t and t:IsA("Model") then t else nil
end
local function stationMesh(m: Model, name: string, f: CFrame, offset: CFrame?): Model?
	local t = hubMesh("Station_" .. name)
	if not t then return nil end
	local c = t:Clone()
	c.Name = "Mesh"
	local _, size = c:GetBoundingBox()
	if Widths[name] then c:ScaleTo(c:GetScale() * Widths[name] / size.X) end
	c:PivotTo(f * (offset or CFrame.new()))
	for _, p in c:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = true p.CanTouch = false end
	end
	c.Parent = m
	return c
end

-- Station builders. f: frame on the plaza floor, +Z facing the centre.
local function spinControl(m: Model, f: CFrame)
	local plate = W.part(m, "SpinControl", V(9, 2, 0.4), f * CFrame.new(0, 2.6, 5.1), W.Purple)
	local gui = W.sign(plate)
	W.text(gui, "OpenSpin", "DAILY SPIN  [E]", UDim2.fromScale(.04,.1), UDim2.fromScale(.92,.8))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DailySpinPrompt" prompt.ActionText = "Open" prompt.ObjectText = "Daily Spin"
	prompt.HoldDuration = 0 prompt.MaxActivationDistance = 14 prompt.RequiresLineOfSight = false
	prompt.Parent = plate CollectionService:AddTag(prompt, "DailySpinPrompt")
end
local function dailySpin(m: Model, f: CFrame)
	-- Separate imported meshes let the client turn the rotor without moving the stand.
	local template = hubMesh("DailySpinWheel")
	local rotor = template and template:FindFirstChild("Rotor")
	if template and rotor and rotor:IsA("BasePart") then
		local wheel = template:Clone()
		wheel.Name = "DailySpinWheel"
		local _, size = wheel:GetBoundingBox()
		wheel:ScaleTo(wheel:GetScale() * Widths.DailySpin / size.X)
		wheel:PivotTo(f * CFrame.new(0, 1.2, 0))
		for _, p in wheel:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false
			end
		end
		wheel.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		CollectionService:AddTag(wheel, "DailySpinWheel")
		wheel.Parent = m
		base(m, f, 16, 10) header(m, f * CFrame.new(0, 23, 0), "DAILY SPIN", RED, 12) spinControl(m, f) return
	end
	if stationMesh(m, "DailySpin", f * CFrame.new(0, 1.2, 0)) then
		base(m, f, 16, 10) header(m, f * CFrame.new(0, 23, 0), "DAILY SPIN", RED, 12) spinControl(m, f) return
	end
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
	spinControl(m, f)
end
-- Leaderboard screens on the Top Crushers boards (filled by server/TopBoards).
-- One SurfaceGui per screen: title, then rows (rank, name, score). Tag "TopBoard",
-- attribute BoardId = which board. Sizes in unscaled station studs.
HubPlaza.Boards = {
	{ id = "Cash", title = "RICHEST" },
	{ id = "Crushed", title = "MOST CRUSHED" },
	{ id = "Collection", title = "COLLECTION" },
}
HubPlaza.BoardRows = 8
local function boardScreen(m: Model, cf: CFrame, w: number, h: number, board: any)
	local screen = W.part(m, "LeaderboardScreen", V(w, h, 0.1), cf, C(16, 18, 36))
	screen.Transparency = 1 -- the mesh's own screen shows behind the text
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Board" gui.Face = Enum.NormalId.Back gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(260, math.floor(260 * h / w)) -- low canvas = big, readable text gui.LightInfluence = 0 gui.MaxDistance = 260
	gui.Parent = screen
	local H = gui.CanvasSize.Y
	local title = W.text(gui, "Title", board.title, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 34))
	title.TextColor3 = GOLD
	local rowH = (H - 44) / HubPlaza.BoardRows
	for i = 1, HubPlaza.BoardRows do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Position = UDim2.fromOffset(4, 40 + (i - 1) * rowH)
		row.Size = UDim2.new(1, -8, 0, rowH - 3)
		row.BackgroundColor3 = if i == 1 then C(120, 92, 20) elseif i == 2 then C(90, 96, 112) elseif i == 3 then C(110, 66, 36) else C(30, 36, 66)
		row.BackgroundTransparency = 0.15
		row.BorderSizePixel = 0
		row.Parent = gui
		local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6) corner.Parent = row
		local rank = W.text(row, "Rank", "#" .. i, UDim2.fromScale(0.01, 0.1), UDim2.fromScale(0.14, 0.8))
		rank.TextColor3 = if i == 1 then GOLD elseif i == 2 then C(220, 226, 236) elseif i == 3 then C(240, 160, 90) else C(200, 210, 240)
		local name = W.text(row, "PlayerName", "", UDim2.fromScale(0.16, 0.1), UDim2.fromScale(0.52, 0.8))
		name.TextXAlignment = Enum.TextXAlignment.Left
		local score = W.text(row, "Score", "", UDim2.fromScale(0.68, 0.1), UDim2.fromScale(0.31, 0.8))
		score.TextXAlignment = Enum.TextXAlignment.Right
		score.TextColor3 = C(140, 255, 120)
	end
	screen:SetAttribute("BoardId", board.id)
	CollectionService:AddTag(screen, "TopBoard")
end
local function topCrushers(m: Model, f: CFrame)
	-- (the imported mesh is turned ~10.6 degrees inside its template: square it up)
	if stationMesh(m, "TopCrushers", f * CFrame.new(0, 1.2, -1) * CFrame.Angles(0, -0.185, 0)) then
		base(m, f, 30, 11) header(m, f * CFrame.new(0, 18.5, -1), "TOP CRUSHERS", W.Navy, 16)
		-- the mesh's three screens (measured by raycasts; centres in station studs)
		for i, x in { -8.62, -0.28, 8.28 } do
			boardScreen(m, f * CFrame.new(x, 7.93, 3.78), 5.6, 6.2, HubPlaza.Boards[i])
		end
		return
	end
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
-- Quests booth: a blue plate with an [E] prompt that opens the Quests window.
local function questControl(m: Model, cf: CFrame)
	local plate = W.part(m, "QuestsControl", V(9, 1.6, 0.4), cf, W.Blue)
	local gui = W.sign(plate)
	W.text(gui, "OpenQuests", "QUESTS  [E]", UDim2.fromScale(.04,.1), UDim2.fromScale(.92,.8))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "QuestsPrompt" prompt.ActionText = "Open" prompt.ObjectText = "Quests"
	prompt.HoldDuration = 0 prompt.MaxActivationDistance = 14 prompt.RequiresLineOfSight = false
	prompt.Parent = plate CollectionService:AddTag(prompt, "QuestsPrompt")
end
local function quests(m: Model, f: CFrame)
	if stationMesh(m, "Quests", f * CFrame.new(0, 1.2, 0)) then
		base(m, f, 20, 14) header(m, f * CFrame.new(0, 17, 1), "QUESTS", W.Blue, 12) questControl(m, f * CFrame.new(0, 2.6, 7.1)) return
	end
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
	questControl(m, f * CFrame.new(0, 3, 4.15))
end
-- Boosts booth: a purple plate with an [E] prompt that opens the Boosts window.
local function boostControl(m: Model, cf: CFrame)
	local plate = W.part(m, "BoostsControl", V(9, 1.6, 0.4), cf, W.Purple)
	local gui = W.sign(plate)
	W.text(gui, "OpenBoosts", "BOOSTS  [E]", UDim2.fromScale(.04,.1), UDim2.fromScale(.92,.8))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoostsPrompt" prompt.ActionText = "Open" prompt.ObjectText = "Boosts"
	prompt.HoldDuration = 0 prompt.MaxActivationDistance = 14 prompt.RequiresLineOfSight = false
	prompt.Parent = plate CollectionService:AddTag(prompt, "BoostsPrompt")
end
local function boosts(m: Model, f: CFrame)
	if stationMesh(m, "Boosts", f * CFrame.new(0, 1.2, -1)) then
		base(m, f, 18, 10) header(m, f * CFrame.new(0, 18.4, -1), "BOOSTS", W.Purple, 12) boostControl(m, f * CFrame.new(0, 2.6, 5.1)) return
	end
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
	boostControl(m, f * CFrame.new(0, 2.6, 5.1))
end
local function special(m: Model, f: CFrame)
	local pedestalTop = 2.6
	local ped = hubMesh("Prop_Pedestal")
	if ped then
		local c = ped:Clone()
		local _, size = c:GetBoundingBox()
		c:ScaleTo(c:GetScale() * 18 / size.X)
		local _, s2 = c:GetBoundingBox()
		pedestalTop = s2.Y
		c:PivotTo(f)
		c.Parent = m
		-- invisible collider so players can stand on the pedestal
		local col = upright(m, "DisplayBase", pedestalTop, 17, (f * CFrame.new(0, pedestalTop / 2, 0)).Position, W.Navy, true)
		col.Transparency = 1
	else
		upright(m, "DisplayBase", 2, 18, (f * CFrame.new(0, 1, 0)).Position, W.Navy, true)
		upright(m, "DisplayRing", 0.4, 18.6, (f * CFrame.new(0, 2, 0)).Position, W.Yellow)
		upright(m, "DisplayTop", 0.6, 15, (f * CFrame.new(0, 2.3, 0)).Position, C(70, 120, 200), true)
	end
	-- Show one of the imported special crushers (GoldenKing) when the place has them.
	local specials = game:GetService("ServerStorage"):FindFirstChild("SpecialCrusherMeshes")
	local king = specials and specials:FindFirstChild("GoldenKing")
	if king then
		local c = king:Clone()
		c.Name = "ShowcaseCrusher"
		local _, size = c:GetBoundingBox()
		c:ScaleTo(c:GetScale() * math.min(10 / size.X, 11 / size.Y, 10 / size.Z))
		-- these imports face -Z; turn to face out of the display, then sit the
		-- bounding box's bottom centre on the display top
		c:PivotTo(f * CFrame.new(0, pedestalTop, 0) * CFrame.Angles(0, math.pi, 0))
		local cf, sz = c:GetBoundingBox()
		c:PivotTo(c:GetPivot() + ((f * CFrame.new(0, pedestalTop + sz.Y / 2, 0)).Position - cf.Position))
		for _, p in c:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false end
		end
		c.Parent = m
	else
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
	end
	-- glass dome: a clear cylinder with a half-sunk ball on top, standing on the pedestal
	local dy = pedestalTop - 2.6
	local glass = upright(m, "DomeGlass", 10, 15, (f * CFrame.new(0, 7.6 + dy, 0)).Position, C(200, 230, 255))
	glass.Transparency = 0.75 glass.Material = Enum.Material.Glass glass.CastShadow = false
	local cap = W.part(m, "DomeCap", V(15, 15, 15), f * CFrame.new(0, 12.6 + dy, 0), C(200, 230, 255))
	cap.Shape = Enum.PartType.Ball cap.Transparency = 0.8 cap.Material = Enum.Material.Glass cap.CastShadow = false
	for k = 0, 15 do -- gold band where the dome meets the glass wall
		W.part(m, "DomeRim", V(3.2, 0.6, 0.6), f * CFrame.Angles(0, k * math.pi / 8, 0) * CFrame.new(0, 12.6 + dy, 7.6), GOLD)
	end
	if not ped then
		for k = 0, 5 do
			W.lamp(m, f * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 2, 8.3), 1.6)
		end
	end
	-- header on posts in front of the dome
	for _, x in { -6.5, 6.5 } do W.part(m, "SignPost", V(0.8, 16 + dy, 0.8), f * CFrame.new(x, (16 + dy) / 2, 9.8), W.Navy, true) end
	header(m, f * CFrame.new(0, 21.5 + dy, 9.8), "SPECIAL CRUSHERS", W.Navy, 16)
	comingSoon(m, f * CFrame.new(0, 3.2, 9.7))
end

-- Extra props from the reference: stage stairs with rails and lamps, a yellow-
-- outlined pad under every station, toy brick clusters, potted plants and
-- crossing shelters where the spokes meet the railway.
local BRICK_COLORS = { C(230, 60, 60), W.Yellow, W.Blue, W.Green, ORANGE, W.Purple }
local function bigBrick(parent: Instance, cf: CFrame, nx: number, nz: number, color: Color3, scale: number)
	local b = W.brick(parent, CFrame.new(), nx, nz, color)
	b.WorldPivot = CFrame.new()
	b:ScaleTo(scale)
	b:PivotTo(cf)
	return b
end
-- Is plaza-local (x, z) within `margin` studs of a walkway's centre line?
-- (Also true near or past the ring road, so decorations never land on the rails.)
function HubPlaza.onWalkway(x: number, z: number, margin: number): boolean
	if math.sqrt(x * x + z * z) > Config.Loop.Inner - 6 then return true end
	for _, a in HubPlaza.Spokes do
		local d = Vector3.new(math.sin(math.rad(a)), 0, math.cos(math.rad(a)))
		local along = x * d.X + z * d.Z
		local side = math.abs(x * d.Z - z * d.X)
		if along > 0 and side < margin then return true end
	end
	return false
end
function HubPlaza.dress(m: Model, o: CFrame, mega: Model)
	local rng = Random.new(2210)
	local deco = Instance.new("Model")
	deco.Name = "PlazaDecor"
	deco.Parent = m
	-- 1) Stairs at the four stage openings: yellow nosing on every tier edge,
	--    yellow side rails and lamp posts at the foot and top.
	local outer, inner = HubPlaza.Stage[1], HubPlaza.Stage[#HubPlaza.Stage]
	local topY = #HubPlaza.Stage * 1.4
	for _, a in { 0, 90, 180, 270 } do
		local f = o * CFrame.Angles(0, math.rad(a), 0)
		for i, r in HubPlaza.Stage do
			W.part(deco, "StairNose", V(20, 0.14, 0.8), f * CFrame.new(0, i * 1.4 + 0.07, r - 0.4), W.Yellow).CastShadow = false
		end
		for _, x in { -10.5, 10.5 } do
			local bottom = (f * CFrame.new(x, 3, outer + 1)).Position
			local top = (f * CFrame.new(x, topY + 3, inner - 1)).Position
			W.part(deco, "StairRail", V(0.5, 0.5, (top - bottom).Magnitude), CFrame.lookAt((bottom + top) / 2, top), W.Yellow, true)
			W.part(deco, "StairRailPost", V(0.7, 3, 0.7), f * CFrame.new(x, 1.5, outer + 1), W.Navy, true)
			W.lamp(deco, f * CFrame.new(x, 0, outer + 2.4), 3.4)
			W.lamp(deco, f * CFrame.new(x, topY, inner - 1), 3)
		end
	end
	-- 2) A pad with a yellow outline under each station.
	local pads = {}
	for _, st in m:GetChildren() do
		if st:IsA("Model") and st.Name:match("Station$") then
			local cf, size = st:GetBoundingBox()
			local pad = CFrame.new(cf.X, o.Position.Y, cf.Z) * cf.Rotation
			local w, d = size.X + 8, size.Z + 8
			W.part(deco, "StationPad", V(w, 0.1, d), pad * CFrame.new(0, 0.05, 0), C(84, 124, 196)).CastShadow = false
			for _, side in { { V(w, 0.14, 0.8), CFrame.new(0, 0.07, d / 2) }, { V(w, 0.14, 0.8), CFrame.new(0, 0.07, -d / 2) },
				{ V(0.8, 0.14, d), CFrame.new(w / 2, 0.07, 0) }, { V(0.8, 0.14, d), CFrame.new(-w / 2, 0.07, 0) } } do
				W.part(deco, "PadEdge", side[1] :: Vector3, pad * (side[2] :: CFrame), W.Yellow).CastShadow = false
			end
			table.insert(pads, { pad, V(w, 0, d) })
			-- a few bricks and plants hugging each pad's corners
			for k, corner in { V(-1, 0, 1), V(1, 0, 1), V(-1, 0, -1), V(1, 0, -1) } do
				local p = pad * CFrame.new(corner.X * (w / 2 + 5), 0, corner.Z * (d / 2 + 4))
				local lp = o:PointToObjectSpace(p.Position)
				if HubPlaza.onWalkway(lp.X, lp.Z, 14) then continue end
				bigBrick(deco, p * CFrame.Angles(0, rng:NextNumber(0, 3), 0), 2, if k % 2 == 0 then 2 else 1, BRICK_COLORS[rng:NextInteger(1, #BRICK_COLORS)], 2.6)
				if k <= 2 then
					bigBrick(deco, p * CFrame.new(rng:NextNumber(-1, 1), 4.16, rng:NextNumber(-1, 1)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), 1, 1, BRICK_COLORS[rng:NextInteger(1, #BRICK_COLORS)], 2.6)
				end
			end
		end
	end
	-- 3) Brick clusters (2-4 big bricks, some stacked): one beside each station,
	--    on its outer side, clear of the walkways (no random scatter).
	local function cluster(cf: CFrame)
		local S = rng:NextNumber(2.6, 3.1)
		local h = 1.6 * S
		bigBrick(deco, cf, 2, 2, BRICK_COLORS[rng:NextInteger(1, #BRICK_COLORS)], S)
		bigBrick(deco, cf * CFrame.new(3.4 * S, 0, rng:NextNumber(-1, 1)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), 2, 1, BRICK_COLORS[rng:NextInteger(1, #BRICK_COLORS)], S)
		bigBrick(deco, cf * CFrame.new(rng:NextNumber(-0.5, 0.5), h, rng:NextNumber(-0.5, 0.5)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), 2, 1, BRICK_COLORS[rng:NextInteger(1, #BRICK_COLORS)], S)
	end
	for i, pad in pads do
		local cf, size = pad[1] :: CFrame, pad[2] :: Vector3
		-- alternate sides round the ring; use the other side if that one is a walkway
		for _, side in (if i % 2 == 0 then { 1, -1 } else { -1, 1 }) do
			local at = cf * CFrame.new(side * (size.X / 2 + 13), 0, -size.Z / 4)
			local lp = o:PointToObjectSpace(at.Position)
			if not HubPlaza.onWalkway(lp.X, lp.Z, 20) then
				cluster(at * CFrame.Angles(0, rng:NextNumber(0, 6), 0))
				break
			end
		end
	end
	-- (4: no bricks on the stage top; the Mega Crusher platform covers it.)
	-- 5) Potted plants (AI meshes) beside the stage stairs and stations.
	local cactus, bush = hubMesh("Prop_Cactus"), hubMesh("Prop_Bush")
	local function plant(t: Model?, cf: CFrame, scale: number)
		if not t then return end
		local c = t:Clone()
		c:ScaleTo(c:GetScale() * scale)
		c:PivotTo(cf)
		for _, p in c:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false end
		end
		c.Parent = deco
	end
	for _, a in { 0, 90, 180, 270 } do
		local f = o * CFrame.Angles(0, math.rad(a), 0)
		plant(cactus, f * CFrame.new(-15, 0, outer + 3), 2.2)
		plant(bush, f * CFrame.new(15, 0, outer + 3), 2.2)
	end
	for _, pad in pads do
		local cf, size = pad[1] :: CFrame, pad[2] :: Vector3
		for _, pair in { { cactus, 1 }, { bush, -1 } } do
			local at = cf * CFrame.new(pair[2] * (size.X / 2 + 3), 0, 0)
			local lp = o:PointToObjectSpace(at.Position)
			if not HubPlaza.onWalkway(lp.X, lp.Z, 12) then plant(pair[1], at, 2.2) end
		end
	end
	-- 6) Crossing shelters where each spoke meets the railway: yellow roof on
	--    navy posts, hazard-striped barriers and lamps.
	local rr = Config.Loop.Inner - 9 -- shelters stand on the plaza, off the road
	for _, a in HubPlaza.Spokes do
		local f = o * CFrame.Angles(0, math.rad(a), 0)
		for _, side in { -1, 1 } do
			local s = f * CFrame.new(side * 16, 0, rr)
			for _, z in { -2.5, 2.5 } do W.part(deco, "ShelterPost", V(1, 7, 1), s * CFrame.new(side * 2.5, 3.5, z), W.Navy, true) end
			for _, z in { -2.5, 2.5 } do W.part(deco, "ShelterPost", V(1, 7, 1), s * CFrame.new(-side * 2.5, 3.5, z), W.Navy, true) end
			local roof = W.part(deco, "ShelterRoof", V(8, 1.2, 8), s * CFrame.new(0, 7.6, 0), W.Yellow, true)
			Style.materialStuds(roof, true, { Enum.NormalId.Top }, 2)
			W.beacon(deco, s * CFrame.new(side * 3.4, 8.2, 3.4))
			W.hazard(deco, s * CFrame.new(-side * 5.5, 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0), 9, 0.8, 0.5)
			W.part(deco, "BarrierPost", V(1, 3, 1), s * CFrame.new(-side * 5.5, 1.5, 4.6), W.Navy, true)
			W.lamp(deco, s * CFrame.new(-side * 5.5, 0, -4.6), 3)
		end
	end
	local _ = mega
end

function HubPlaza.build(parent: Instance, floorY: number)
	local m = Instance.new("Model")
	m.Name = "FactoryPlaza"
	m.Parent = parent
	local o = CFrame.new(0, floorY, 0)
	local topY = stage(m, o)
	local mega = megaCrusher(m, o * CFrame.new(0, topY, 0))
	-- MEGA CRUSHER sign at the foot of the stage, facing the south spoke.
	if not mega:GetAttribute("OwnSign") then
		local signCf = o * CFrame.new(0, 0, HubPlaza.Stage[1] + 6)
		for _, x in { -11, 11 } do W.part(m, "MegaSignPost", V(1.6, 9, 1.6), signCf * CFrame.new(x, 4.5, 0), W.Navy, true) end
		local face, gui = W.panel(m, signCf * CFrame.new(0, 8.6, 0), 22, 7, W.Blue)
		farSigns(gui)
		local t = W.text(gui, "Title", "MEGA\nCRUSHER", UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.92, 0.88))
		t.TextColor3 = C(255, 214, 80)
		local _ = face
	end
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
		-- +Z (the model fronts) faces the Mega Crusher in the middle
		local f = CFrame.lookAt(pos, Vector3.new(o.X, floorY, o.Z)) * CFrame.Angles(0, math.pi, 0)
		local sm = Instance.new("Model")
		sm.Name = name .. "Station"
		sm:SetAttribute("Placeholder", name ~= "DailySpin")
		builders[name](sm, f)
		sm.WorldPivot = f
		sm:ScaleTo(spec[3] or HubPlaza.StationScale)
		sm.Parent = m
		task.wait()
	end
	-- Toy trees in planters and lamp posts round the plaza (AI meshes when present).
	local tree = hubMesh("Prop_Tree")
	local function drop(t: Model?, a: number, r: number, scale: number)
		if not t then return end
		local c = t:Clone()
		c:ScaleTo(c:GetScale() * scale)
		c:PivotTo(o * CFrame.new(math.sin(math.rad(a)) * r, 0, math.cos(math.rad(a)) * r) * CFrame.Angles(0, math.rad(a), 0))
		for _, p in c:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false end
		end
		c.Parent = m
	end
	for _, spec in HubPlaza.Stations do
		for _, side in { -1, 1 } do
			local a, r = spec[1] + side * 13, spec[2] - 6
			if not HubPlaza.onWalkway(math.sin(math.rad(a)) * r, math.cos(math.rad(a)) * r, 14) then drop(tree, a, r, 1.6) end
		end
	end
	-- Glowing yellow lamp posts along both sides of each spoke (like the reference).
	for _, a in HubPlaza.Spokes do
		for _, r in { 60, 85, 110 } do
			for _, side in { -1, 1 } do
				W.lamp(m, o * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(side * 11, 0, r), 3.6)
			end
		end
	end
	HubPlaza.dress(m, o, mega)
	return m, mega
end

return HubPlaza
