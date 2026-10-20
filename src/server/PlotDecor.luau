--!strict
-- Set dressing on every plot (after the Yuzu game's onsen gate + boiler barrel
-- and Destroy a Vault's plots):
--   * entrance gate where the walkway bridge lands: steel pillars with hazard
--     feet, an I-beam, the owner's name plate and two hanging banners in the
--     plot colour, lamps on top          -> returns the name TextLabel
--   * a big boiler tank (back right): banded tank, porthole glow, gauge,
--     valve wheel, pipes into the floor, steam
--   * crate stacks and lamp posts in the corners
-- Plot local space: +Z to the walkway, floor top at origin.

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

-- Everything for one plot; returns the gate's name label.
function PlotDecor.build(plotModel: Model, origin: CFrame, accent: Color3, theme: { [string]: Color3 }, index: number): TextLabel
	local F = Config.Plots.FloorSize
	local half = F / 2
	local m = Instance.new("Model")
	m.Name = "Decor"
	local rng = Random.new(100 + index)
	local label = PlotDecor.gate(m, origin * CFrame.new(16, 0, half - 2.2), 11, accent, theme)
	PlotDecor.boiler(m, origin * CFrame.new(40, 0, -42) * CFrame.Angles(0, math.rad(-35), 0))
	PlotDecor.crates(m, origin * CFrame.new(50, 0, -18), rng)
	PlotDecor.crates(m, origin * CFrame.new(-50, 0, -50) * CFrame.Angles(0, math.rad(90), 0), rng)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			if not (x == 1 and z == 1) then -- front-right is the gate
				Build.lamp(m, origin * CFrame.new(x * (half - 5), 0, z * (half - 5)), theme, 11)
			end
		end
	end
	m.Parent = plotModel
	return label
end

return PlotDecor
