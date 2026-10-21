--!strict
-- Set dressing on every plot (after the Yuzu game's onsen gate + boiler barrel
-- and Destroy a Vault's plots):
--   * entrance gate where the walkway bridge lands: steel pillars with hazard
--     feet, an I-beam, the owner's name plate and two hanging banners in the
--     plot colour, lamps on top          -> returns the name TextLabel
--   * a big boiler tank (back right): banded tank, porthole glow, gauge,
--     valve wheel, pipes into the floor, steam
--   * the toy factory hall at the far end (the conveyor comes out of its door)
--   * beside the press: a scrap heap with a slowly swinging magnet crane, crates,
--     bales of crushed scrap with a forklift
--   (PlotDecor.pipe is unused since the 21 Oct layout but kept for later)
-- Plot local space: origin at the press centre, +Z to the hub, floor top at origin.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)

local PlotDecor = {}

local C = Color3.fromRGB
local YELLOW = C(250, 196, 46)
local BLACK = C(30, 30, 34)
local STEEL = C(110, 116, 130)
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local function cyl(parent: Instance, name: string, length: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	-- cylinder along the CFrame's Y axis
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(length, d, d)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function surfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3, stroke: number?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	Style.text(label, stroke or 4)
	label.TextColor3 = color
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = label
	return label
end

-- The entrance gate. `cf` = ground centre between the pillars, facing +Z (out to the bridge).
function PlotDecor.gate(parent: Instance, cf: CFrame, width: number, accent: Color3, theme: { [string]: Color3 }): TextLabel
	local m = Instance.new("Model")
	m.Name = "Gate"
	local h = 14
	for _, x in { -1, 1 } do
		local px = x * (width / 2 + 1.4)
		Build.block(m, "GateFoot", Vector3.new(3.6, 1.2, 3.6), cf * CFrame.new(px, 0.6, 0), BLACK, ALL)
		Build.block(m, "GatePillar", Vector3.new(2.6, h, 2.6), cf * CFrame.new(px, h / 2, 0), theme.edge, ALL)
		-- hazard bands on the lower part
		for i = 0, 3 do
			Build.block(m, "Hazard", Vector3.new(2.7, 0.8, 2.7), cf * CFrame.new(px, 1.6 + i * 0.8, 0), if i % 2 == 0 then YELLOW else BLACK, {})
		end
		-- rivets
		for i = 1, 4 do
			local r = cyl(m, "Rivet", 0.2, 0.5, cf * CFrame.new(px, 5 + i * 2, 1.35) * CFrame.Angles(math.rad(90), 0, 0), STEEL, Enum.Material.Metal)
			local _ = r
		end
		-- lamp on top
		Build.block(m, "LampBase", Vector3.new(2, 0.6, 2), cf * CFrame.new(px, h + 2.2, 0), BLACK, ALL)
		local lamp = Build.block(m, "Lamp", Vector3.new(1.4, 1.4, 1.4), cf * CFrame.new(px, h + 3.2, 0), C(255, 170, 60), {})
		lamp.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color = C(255, 170, 60)
		light.Range = 16
		light.Brightness = 1.2
		light.Parent = lamp
	end
	-- I-beam across the top
	local beamW = width + 7
	Build.block(m, "BeamTop", Vector3.new(beamW, 0.6, 3.4), cf * CFrame.new(0, h + 1.6, 0), BLACK, ALL)
	Build.block(m, "BeamWeb", Vector3.new(beamW - 0.6, 1.6, 1.2), cf * CFrame.new(0, h + 0.5, 0), theme.edge, {})
	Build.block(m, "BeamBottom", Vector3.new(beamW, 0.6, 3.4), cf * CFrame.new(0, h - 0.6, 0), BLACK, ALL)
	-- name plate hanging under the beam (both faces)
	local plate = Build.block(m, "NamePlate", Vector3.new(width + 1, 3.2, 0.6), cf * CFrame.new(0, h - 2.6, 0), accent, {})
	Build.block(m, "PlateFrame", Vector3.new(width + 1.8, 4, 0.4), cf * CFrame.new(0, h - 2.6, 0), BLACK, {})
	local label = surfaceText(plate, Enum.NormalId.Back, "Free plot", Color3.new(1, 1, 1))
	label.Name = "OwnerName" -- Zone.client reads it
	local back = surfaceText(plate, Enum.NormalId.Front, "Free plot", Color3.new(1, 1, 1))
	label:GetPropertyChangedSignal("Text"):Connect(function()
		back.Text = label.Text
	end)
	-- two hanging banners with a gear
	for _, x in { -1, 1 } do
		local banner = Build.block(m, "Banner", Vector3.new(2.6, 5.5, 0.2), cf * CFrame.new(x * (width / 2 - 1.2), h - 7.4, 0), accent, {})
		Build.block(m, "BannerBar", Vector3.new(3, 0.3, 0.4), cf * CFrame.new(x * (width / 2 - 1.2), h - 4.5, 0), BLACK, {})
		surfaceText(banner, Enum.NormalId.Back, "⚙", Color3.new(1, 1, 1), 2)
		surfaceText(banner, Enum.NormalId.Front, "⚙", Color3.new(1, 1, 1), 2)
	end
	m.Parent = parent
	return label
end

-- Big boiler tank. `cf` = ground centre.
function PlotDecor.boiler(parent: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Boiler"
	local r, h = 6.5, 16
	Build.block(m, "BoilerBase", Vector3.new(r * 2 + 3, 1.2, r * 2 + 3), cf * CFrame.new(0, 0.6, 0), BLACK, ALL)
	cyl(m, "Tank", h, r * 2, cf * CFrame.new(0, 1.2 + h / 2, 0), C(214, 92, 50), Enum.Material.SmoothPlastic)
	for _, y in { 2.4, h * 0.5 + 1.2, h - 0.4 } do
		cyl(m, "Band", 1, r * 2 + 0.5, cf * CFrame.new(0, y, 0), C(245, 236, 220))
	end
	-- domed top
	local dome = Instance.new("Part")
	dome.Name = "Dome"
	dome.Shape = Enum.PartType.Ball
	dome.Anchored = true
	dome.Size = Vector3.new(r * 2, r * 2, r * 2)
	dome.CFrame = cf * CFrame.new(0, 1.2 + h - r * 0.45, 0)
	dome.Color = C(190, 78, 42)
	dome.Parent = m
	-- porthole glow (faces +Z)
	local port = cyl(m, "Porthole", 0.6, 4.2, cf * CFrame.new(0, 7, r - 0.1) * CFrame.Angles(math.rad(90), 0, 0), BLACK)
	local _ = port
	local glow = cyl(m, "PortGlow", 0.7, 3.2, cf * CFrame.new(0, 7, r) * CFrame.Angles(math.rad(90), 0, 0), C(255, 170, 60), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = C(255, 150, 60)
	light.Range = 14
	light.Parent = glow
	-- pressure gauge
	cyl(m, "Gauge", 0.5, 2.2, cf * CFrame.new(-3.6, 12, r - 1.1) * CFrame.Angles(math.rad(90), math.rad(-30), 0), C(245, 245, 245))
	-- chimney + steam
	local stack = cyl(m, "Stack", 7, 1.8, cf * CFrame.new(2.5, 1.2 + h + 3, -1), C(70, 74, 86), Enum.Material.Metal)
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Rate = 5
	steam.Lifetime = NumberRange.new(2, 3.5)
	steam.Speed = NumberRange.new(3, 5)
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	steam.Color = ColorSequence.new(C(235, 235, 240))
	steam.EmissionDirection = Enum.NormalId.Right
	steam.Parent = stack
	-- pipes from the side down into the floor
	for _, z in { -2, 2 } do
		cyl(m, "Pipe", 5, 1.2, cf * CFrame.new(r + 2.4, 6, z) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
		cyl(m, "PipeDown", 6, 1.2, cf * CFrame.new(r + 4.6, 3, z), STEEL, Enum.Material.Metal)
		cyl(m, "PipeRing", 0.5, 1.6, cf * CFrame.new(r + 4.6, 5, z), YELLOW)
	end
	-- valve wheel
	cyl(m, "Valve", 0.4, 2.4, cf * CFrame.new(-r - 0.6, 4, 0) * CFrame.Angles(0, 0, math.rad(90)), C(220, 50, 50))
	m.Parent = parent
end

-- A small stack of crates. `cf` = ground centre.
function PlotDecor.crates(parent: Instance, cf: CFrame, rng: Random)
	local m = Instance.new("Model")
	m.Name = "Crates"
	local wood, wood2 = C(186, 132, 74), C(150, 100, 56)
	local function crate(size: number, at: CFrame)
		local c = Build.block(m, "Crate", Vector3.new(size, size, size), at, if rng:NextNumber() < 0.5 then wood else wood2, ALL)
		local _ = c
		for _, y in { -1, 1 } do
			Build.block(m, "CrateBand", Vector3.new(size + 0.1, 0.35, size + 0.1), at * CFrame.new(0, y * (size / 2 - 0.4), 0), C(90, 62, 36), {})
		end
	end
	crate(3.6, cf * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, rng:NextNumber() * 0.6, 0))
	crate(3.2, cf * CFrame.new(3.8, 1.6, 0.6) * CFrame.Angles(0, rng:NextNumber() * 0.8, 0))
	crate(2.8, cf * CFrame.new(1.6, 3.6 + 1.4, 0.2) * CFrame.Angles(0, rng:NextNumber() * 1.2, 0))
	-- an oil drum
	cyl(m, "Drum", 3.4, 2.4, cf * CFrame.new(-3, 1.7, 1.5), C(60, 110, 200))
	cyl(m, "DrumRing", 0.3, 2.55, cf * CFrame.new(-3, 2.6, 1.5), C(40, 70, 140))
	m.Parent = parent
end

-- A heap of junk waiting to be crushed: stepped dirt mound with wrecked car
-- bodies, crushed cubes, tyres and sheets on top. `cf` = ground centre.
function PlotDecor.scrapHeap(parent: Instance, cf: CFrame, rng: Random): Model
	local m = Instance.new("Model")
	m.Name = "ScrapHeap"
	local mound = { C(118, 96, 78), C(98, 82, 70), C(132, 112, 92) }
	for i, layer in { { 13, 1.2 }, { 9.5, 1.2 }, { 6, 1.1 } } do
		local w, h = layer[1], layer[2]
		local y = (i - 1) * 1.2 + h / 2
		Build.block(m, "Mound", Vector3.new(w, h, w * 0.85), cf * CFrame.new(rng:NextNumber(-0.6, 0.6), y, rng:NextNumber(-0.6, 0.6)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), mound[i], ALL)
	end
	local junk = { C(70, 150, 200), C(220, 70, 60), C(150, 156, 168), C(240, 190, 60), C(90, 180, 110), C(170, 110, 70) }
	-- wrecked car bodies (flattened boxes with a squashed cabin)
	for i = 1, 2 do
		local a = rng:NextNumber() * math.pi * 2
		local at = cf * CFrame.new(math.cos(a) * 2.5, 3.2 + i * 0.9, math.sin(a) * 2.2) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber() * 6, rng:NextNumber(-0.4, 0.4))
		local col = junk[rng:NextInteger(1, #junk)]
		Build.block(m, "CarBody", Vector3.new(6, 1.4, 3), at, col, ALL)
		Build.block(m, "CarCabin", Vector3.new(3, 0.9, 2.6), at * CFrame.new(-0.4, 1.1, 0) * CFrame.Angles(0, 0, 0.25), col:Lerp(Color3.new(0, 0, 0), 0.2), ALL)
		Build.block(m, "CarGlass", Vector3.new(0.2, 0.7, 2.2), at * CFrame.new(1.1, 1.05, 0) * CFrame.Angles(0, 0, 0.6), C(150, 210, 240), {})
	end
	-- crushed cubes, tyres, sheets scattered over the mound
	for _ = 1, 9 do
		local a = rng:NextNumber() * math.pi * 2
		local r = rng:NextNumber(1, 5.5)
		local y = 3.6 - r * 0.45
		local at = cf * CFrame.new(math.cos(a) * r, y + 0.6, math.sin(a) * r) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber() * 6, rng:NextNumber(-0.6, 0.6))
		local roll = rng:NextNumber()
		if roll < 0.45 then
			local sz = rng:NextNumber(1.2, 2)
			Build.block(m, "Cube", Vector3.new(sz, sz, sz), at, junk[rng:NextInteger(1, #junk)], ALL)
		elseif roll < 0.7 then
			cyl(m, "Tyre", 0.9, 2.2, at, C(36, 36, 40))
		else
			Build.block(m, "Sheet", Vector3.new(rng:NextNumber(2.5, 4), 0.25, rng:NextNumber(1.5, 2.5)), at, C(150, 156, 168), {}).Material = Enum.Material.Metal
		end
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = p.Name == "Mound" -- walk over the mound, through the junk
		end
	end
	m.Parent = parent
	return m
end

-- A magnet crane that slowly swings over the scrap heap (the client turns
-- Models tagged PressSpin round their "Axis" attribute). `cf` = mast foot.
function PlotDecor.crane(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Crane"
	local mastH = 15
	Build.block(m, "CraneBase", Vector3.new(6, 1, 6), cf * CFrame.new(0, 0.5, 0), BLACK, ALL)
	for i = 0, 5 do
		Build.block(m, "Mast", Vector3.new(2, mastH / 6, 2), cf * CFrame.new(0, 1 + (i + 0.5) * mastH / 6, 0), if i % 2 == 0 then YELLOW else BLACK, ALL)
	end
	local top = Instance.new("Model")
	top.Name = "Swing"
	local y = 1 + mastH
	Build.block(top, "Cab", Vector3.new(3.6, 3, 3.6), cf * CFrame.new(0, y + 1.5, 0), YELLOW, ALL)
	Build.block(top, "CabWindow", Vector3.new(3.7, 1.2, 2.6), cf * CFrame.new(0, y + 2, 0), C(150, 210, 240), {})
	local boomLen = 12
	Build.block(top, "Boom", Vector3.new(boomLen, 1.2, 1.4), cf * CFrame.new(boomLen / 2, y + 3.6, 0), YELLOW, ALL)
	Build.block(top, "BoomStripe", Vector3.new(boomLen, 0.3, 1.5), cf * CFrame.new(boomLen / 2, y + 3.3, 0), BLACK, {})
	Build.block(top, "CounterJib", Vector3.new(5, 1.2, 1.4), cf * CFrame.new(-2.5, y + 3.6, 0), YELLOW, ALL)
	Build.block(top, "Counterweight", Vector3.new(2.4, 2.4, 2.4), cf * CFrame.new(-4.4, y + 2.2, 0), C(70, 74, 86), ALL)
	Build.block(top, "Cable", Vector3.new(0.25, 7, 0.25), cf * CFrame.new(boomLen - 1, y + 3 - 3.5, 0), BLACK, {})
	cyl(top, "Magnet", 0.9, 3.4, cf * CFrame.new(boomLen - 1, y - 4.4, 0), C(60, 62, 70), Enum.Material.Metal)
	cyl(top, "MagnetRim", 0.4, 3.6, cf * CFrame.new(boomLen - 1, y - 4.7, 0), C(220, 50, 50))
	local held = Build.block(top, "HeldCube", Vector3.new(1.8, 1.8, 1.8), cf * CFrame.new(boomLen - 1, y - 6, 0) * CFrame.Angles(0.2, 0.5, 0.1), C(70, 150, 200), ALL)
	local _ = held
	for _, p in top:GetChildren() do
		if p:IsA("BasePart") then
			p.CanCollide = false
		end
	end
	top:SetAttribute("Speed", 0.22)
	top:SetAttribute("Axis", cf.Position)
	CollectionService:AddTag(top, "PressSpin")
	top.Parent = m
	m.Parent = parent
	return m
end

-- Bales of crushed scrap on pallets, and a forklift. `cf` = ground centre.
function PlotDecor.bales(parent: Instance, cf: CFrame, rng: Random): Model
	local m = Instance.new("Model")
	m.Name = "Bales"
	local colors = { C(200, 80, 60), C(70, 140, 210), C(150, 156, 168), C(90, 170, 100), C(230, 180, 60) }
	local function bale(at: CFrame)
		Build.block(m, "Bale", Vector3.new(3, 3, 3), at, colors[rng:NextInteger(1, #colors)], ALL)
		for _, x in { -0.8, 0.8 } do
			Build.block(m, "Strap", Vector3.new(0.3, 3.08, 3.08), at * CFrame.new(x, 0, 0), BLACK, {})
		end
	end
	for _, pz in { -2, 2 } do
		Build.block(m, "Pallet", Vector3.new(7, 0.5, 3.4), cf * CFrame.new(0, 0.25, pz), C(176, 128, 74), ALL)
		for i, px in { -1.6, 1.6 } do
			bale(cf * CFrame.new(px, 2, pz) * CFrame.Angles(0, rng:NextNumber(-0.08, 0.08), 0))
			if pz < 0 or i == 1 then
				bale(cf * CFrame.new(px, 5, pz) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0))
			end
		end
	end
	bale(cf * CFrame.new(0, 8, -2) * CFrame.Angles(0, 0.3, 0))
	-- forklift in front of the stack
	local f = cf * CFrame.new(-8, 0, 0)
	Build.block(m, "LiftBody", Vector3.new(4, 2, 3.4), f * CFrame.new(-0.8, 1.6, 0), YELLOW, ALL)
	Build.block(m, "LiftSeat", Vector3.new(1.6, 1.2, 1.8), f * CFrame.new(-1.4, 3.2, 0), BLACK, ALL)
	Build.block(m, "LiftRoof", Vector3.new(2.6, 0.3, 3), f * CFrame.new(-1, 5.6, 0), BLACK, {})
	for _, z in { -1.3, 1.3 } do
		Build.block(m, "LiftPost", Vector3.new(0.3, 3, 0.3), f * CFrame.new(-2.1, 4.1, z), BLACK, {})
		Build.block(m, "LiftPostF", Vector3.new(0.3, 3, 0.3), f * CFrame.new(0.1, 4.1, z), BLACK, {})
		Build.block(m, "Mast", Vector3.new(0.4, 5, 0.4), f * CFrame.new(1.4, 2.5, z * 0.8), C(60, 62, 70), {})
		Build.block(m, "Fork", Vector3.new(2.6, 0.25, 0.5), f * CFrame.new(2.8, 0.6, z * 0.8), C(60, 62, 70), {})
		for _, x in { -2.2, 0.8 } do
			cyl(m, "Wheel", 0.7, 1.6, f * CFrame.new(x, 0.8, z * 1.35) * CFrame.Angles(math.rad(90), 0, 0), C(36, 36, 40))
		end
	end
	m.Parent = parent
	return m
end

-- An overhead pipe on posts (walk under it) through the given ground points.
function PlotDecor.pipe(parent: Instance, points: { Vector3 }, y: number, color: Color3)
	local m = Instance.new("Model")
	m.Name = "Pipe"
	for i = 1, #points - 1 do
		local a = points[i] + Vector3.new(0, y, 0)
		local b = points[i + 1] + Vector3.new(0, y, 0)
		local len = (b - a).Magnitude
		local mid = CFrame.lookAt((a + b) / 2, b)
		local p = cyl(m, "PipeRun", len + 1.2, 1.2, mid * CFrame.Angles(math.rad(90), 0, 0), color, Enum.Material.Metal)
		local _ = p
		cyl(m, "Joint", 1.4, 1.6, CFrame.new(a), YELLOW)
		local n = math.max(1, math.floor(len / 12))
		for k = 0, n do
			local at = a:Lerp(b, k / n)
			if k > 0 and k < n or i == 1 and k == 0 then
				Build.block(m, "PipePost", Vector3.new(0.6, y, 0.6), CFrame.new(at.X, at.Y - y / 2, at.Z), BLACK, {})
			end
		end
	end
	cyl(m, "Joint", 1.4, 1.6, CFrame.new(points[#points] + Vector3.new(0, y, 0)), YELLOW)
	-- down into the floor at the end
	local last = points[#points]
	cyl(m, "PipeDown", y, 1.2, CFrame.new(last + Vector3.new(0, y / 2, 0)), color, Enum.Material.Metal)
	m.Parent = parent
end

-- The toy factory hall at the far end of the plot: the conveyor comes out of its
-- door, so everything you crush is "made" here. Cream walls with a dark base
-- band, a row of windows, a striped door frame, a colourful sawtooth roof, two
-- banded chimneys with smoke and a "TOY FACTORY" sign. `cf` = ground centre,
-- facing +Z (toward the press).
function PlotDecor.factory(parent: Instance, cf: CFrame, accent: Color3): Model
	local m = Instance.new("Model")
	m.Name = "FactoryHall"
	local W, D, H = 72, 10, 12
	local doorW, doorH = 12, 8
	local WALL = C(242, 234, 216)
	local side = (W - doorW) / 2
	for _, sx in { -1, 1 } do
		local x = sx * (doorW / 2 + side / 2)
		Build.block(m, "Wall", Vector3.new(side, H, D), cf * CFrame.new(x, H / 2, 0), WALL, ALL)
		Build.block(m, "BaseBand", Vector3.new(side + 0.1, 1.4, D + 0.1), cf * CFrame.new(x, 0.7, 0), C(70, 74, 88), {})
		-- windows on the front face
		for i = 0, 3 do
			local wx = x - side / 2 + 4 + i * (side - 8) / 3
			Build.block(m, "WindowFrame", Vector3.new(4.2, 4.2, 0.3), cf * CFrame.new(wx, 6.5, D / 2 + 0.1), C(70, 74, 88), {})
			local glass = Build.block(m, "Window", Vector3.new(3.4, 3.4, 0.3), cf * CFrame.new(wx, 6.5, D / 2 + 0.2), C(120, 200, 255), {})
			glass.Material = Enum.Material.Neon
			glass.Transparency = 0.25
		end
	end
	Build.block(m, "Lintel", Vector3.new(doorW, H - doorH, D), cf * CFrame.new(0, doorH + (H - doorH) / 2, 0), WALL, ALL)
	Build.block(m, "DoorDark", Vector3.new(doorW, doorH, 0.5), cf * CFrame.new(0, doorH / 2, -D / 2 + 0.5), C(20, 20, 26), {})
	-- black/yellow door frame
	for _, sx in { -1, 1 } do
		for i = 0, 5 do
			Build.block(m, "DoorStripe", Vector3.new(1, doorH / 6, 1), cf * CFrame.new(sx * (doorW / 2 + 0.5), (i + 0.5) * doorH / 6, D / 2), if i % 2 == 0 then YELLOW else BLACK, {})
		end
	end
	Build.block(m, "DoorTop", Vector3.new(doorW + 2, 1, 1), cf * CFrame.new(0, doorH + 0.5, D / 2), YELLOW, {})
	-- sign over the door
	local sign = Build.block(m, "FactorySign", Vector3.new(26, 4.6, 0.6), cf * CFrame.new(0, H + 2.6, D / 2 - 0.6), accent, {})
	Build.block(m, "SignFrame", Vector3.new(27, 5.4, 0.4), cf * CFrame.new(0, H + 2.6, D / 2 - 0.9), BLACK, {})
	surfaceText(sign, Enum.NormalId.Front, "TOY FACTORY", C(255, 255, 255), 5)
	-- sawtooth roof: colourful teeth along the width
	local teeth = { C(235, 80, 70), C(250, 196, 46), C(70, 150, 235), C(90, 190, 100) }
	local n = 4
	local tw = W / n
	for i = 0, n - 1 do
		local tooth = Instance.new("WedgePart")
		tooth.Name = "RoofTooth"
		tooth.Anchored = true
		tooth.Size = Vector3.new(D, 5, tw)
		tooth.CFrame = cf * CFrame.new(-W / 2 + (i + 0.5) * tw, H + 2.5, 0) * CFrame.Angles(0, math.rad(90), 0)
		tooth.Color = teeth[i % #teeth + 1]
		tooth.TopSurface = Enum.SurfaceType.Smooth
		tooth.BottomSurface = Enum.SurfaceType.Smooth
		tooth.Parent = m
		Style.studs(tooth)
	end
	-- chimneys with red/white bands and smoke
	for _, sx in { -1, 1 } do
		local base = cf * CFrame.new(sx * (W / 2 - 8), 0, -1)
		cyl(m, "Chimney", 9, 3.2, base * CFrame.new(0, H + 4.5 + 2, 0), C(200, 60, 55), Enum.Material.SmoothPlastic)
		for _, y in { H + 4, H + 8 } do
			cyl(m, "ChimneyBand", 1, 3.4, base * CFrame.new(0, y + 2, 0), C(245, 245, 245))
		end
		local top = cyl(m, "ChimneyTop", 0.8, 3.8, base * CFrame.new(0, H + 11.4, 0), C(60, 62, 70))
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Rate = 5
		smoke.Lifetime = NumberRange.new(3, 5)
		smoke.Speed = NumberRange.new(3, 5)
		smoke.SpreadAngle = Vector2.new(10, 10)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color = ColorSequence.new(C(235, 235, 240))
		smoke.EmissionDirection = Enum.NormalId.Right -- the cylinder's X axis points up
		smoke.Parent = top
	end
	m.Parent = parent
	return m
end

-- Scales a prop model about its centre and stands it back on the floor (y = floorY).
local function grow(model: Model, scale: number, floorY: number)
	model:ScaleTo(scale)
	local lowest = math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			lowest = math.min(lowest, p.Position.Y - p.Size.Y / 2)
		end
	end
	model:PivotTo(model:GetPivot() + Vector3.new(0, floorY - lowest, 0))
end

-- Everything for one plot; returns the gate's name label.
function PlotDecor.build(plotModel: Model, origin: CFrame, accent: Color3, theme: { [string]: Color3 }, index: number): TextLabel
	local F = Config.Plots.FloorSize
	local half = F / 2
	local m = Instance.new("Model")
	m.Name = "Decor"
	local rng = Random.new(100 + index)
	local P = Config.Plots
	local label = PlotDecor.gate(m, origin * CFrame.new(0, 0, P.Front - 2.2), 11, accent, theme)
	-- the toy factory hall at the far end (the conveyor comes out of its door)
	PlotDecor.factory(m, origin * CFrame.new(0, 0, -(P.Back - 5)), accent)
	-- beside the press (props the biggest press would overlap get parked: Plots.clearProps)
	local floorY = origin.Position.Y
	PlotDecor.boiler(m, origin * CFrame.new(46, 0, 22) * CFrame.Angles(0, math.rad(-120), 0))
	grow(PlotDecor.bales(m, origin * CFrame.new(49, 0, -6) * CFrame.Angles(0, math.rad(90), 0), rng), 1.5, floorY)
	grow(PlotDecor.scrapHeap(m, origin * CFrame.new(-46, 0, -8), rng), 1.4, floorY)
	local crane = PlotDecor.crane(m, origin * CFrame.new(-54, 0, -25) * CFrame.Angles(0, math.rad(60), 0))
	grow(crane, 1.5, floorY)
	local swing = crane:FindFirstChild("Swing") :: Model
	swing:SetAttribute("Axis", (crane:FindFirstChild("CraneBase") :: BasePart).Position)
	PlotDecor.crates(m, origin * CFrame.new(-50, 0, 28) * CFrame.Angles(0, math.rad(90), 0), rng)
	local _ = half
	m.Parent = plotModel
	return label
end

return PlotDecor
