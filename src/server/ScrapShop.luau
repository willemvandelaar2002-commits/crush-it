--!strict
-- The scrap shop behind every plot: across the lava moat (Moat.luau) over a steel bridge, a
-- "SCRAP SHOP" gate and a small machinery island with a smelter (hopper,
-- glowing furnace, smoking chimney, spinning gear), a conveyor and the
-- yellow SELL pad. Stand on the pad to sell your scrap (server/Scrap.luau).
--
-- Plot local space: +Z points to the walkway, the back edge is at -F/2, so
-- the island sits at -Z. Sizes in Config.ScrapShop.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local RobuxSigns = require(script.Parent.RobuxSigns)
local Moat = require(script.Parent.Moat)

local ScrapShop = {}

local C = Color3.fromRGB
local YELLOW = C(245, 190, 40)
local BLACK = C(30, 30, 34)
local STEEL = C(96, 102, 118)
local FIRE = C(255, 130, 40)

local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

export type Shop = {
	model: Model,
	pad: BasePart, -- the sell pad's fill (stand on it)
	furnace: BasePart, -- glowing mouth (flares when you sell)
	hopper: BasePart, -- top of the smelter (sold scrap flies in here)
}

local function cylinder(parent: Instance, name: string, length: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	-- a cylinder standing along the CFrame's Y axis
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.Size = Vector3.new(length, d, d)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Black/yellow bands up a block (hazard tape).
local function hazard(parent: Instance, cf: CFrame, size: Vector3, bands: number)
	local h = size.Y / bands
	for i = 0, bands - 1 do
		Build.block(parent, "Hazard", Vector3.new(size.X + 0.1, h, size.Z + 0.1), cf * CFrame.new(0, -size.Y / 2 + (i + 0.5) * h, 0),
			if i % 2 == 0 then YELLOW else BLACK, {})
	end
end

local function signText(part: BasePart, face: Enum.NormalId, text: string, color: Color3)
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
	Style.text(label, 4)
	label.TextColor3 = color
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = label
end

function ScrapShop.build(plotModel: Model, origin: CFrame, theme: { [string]: Color3 }): Shop
	local S = { Gap = Config.Plots.Moat, Depth = Config.ScrapShop.Depth, Width = Config.ScrapShop.Width }
	local F = Config.Plots.FloorSize
	local floorY = origin.Position.Y
	local back = -F / 2
	local islandFront = back - S.Gap
	local islandMid = islandFront - S.Depth / 2
	local at = function(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local m = Instance.new("Model")
	m.Name = "ScrapShop"

	-- Bridge over the lava moat (Moat.luau builds the lava itself).
	Moat.bridge(m, at(0, 0, back - S.Gap / 2), S.Gap + 3)

	-- The island: a raised slab like the plots, in darker steel.
	Build.platform(m, "Island", at(0, 0, islandMid), S.Width, S.Depth, floorY - 0.05, theme.pad, theme.edge, 2)
	-- hazard edge along the island front
	for i = 0, 11 do
		local w = S.Width - 4
		Build.block(m, "EdgeStripe", Vector3.new(w / 12, 0.12, 0.8), at(-w / 2 + (i + 0.5) * w / 12, 0.06, islandFront - 2.6),
			if i % 2 == 0 then YELLOW else BLACK, {})
	end

	-- Gate at the end of the bridge.
	local gateZ = islandFront - 2
	local gateH = 9
	for _, x in { -1, 1 } do
		local pillarCf = at(x * 6.5, gateH / 2, gateZ)
		Build.block(m, "GatePillar", Vector3.new(2, gateH, 2), pillarCf, theme.dark, ALL)
		hazard(m, pillarCf * CFrame.new(0, -gateH / 2 + 1.5, 0), Vector3.new(2, 3, 2), 4)
		local lamp = Build.block(m, "GateLamp", Vector3.new(1.2, 1.2, 1.2), at(x * 7.6, gateH + 2.4, gateZ), FIRE, {})
		lamp.Material = Enum.Material.Neon
	end
	local beam = Build.block(m, "GateBeam", Vector3.new(16, 3, 2.2), at(0, gateH + 1.5, gateZ), YELLOW, ALL)
	signText(beam, Enum.NormalId.Back, "SCRAP SHOP", C(255, 255, 255))
	signText(beam, Enum.NormalId.Front, "SCRAP SHOP", C(255, 255, 255))

	-- Sell pad (yellow, framed) with a floating label.
	local padZ = islandFront - 7.5 -- right behind the gate
	local padModel = Build.inset(m, "SellPad", at(0, 0, padZ), 8, 8, C(255, 210, 60), theme.dark)
	local pad = padModel:FindFirstChild("Fill") :: BasePart
	pad.Name = "SellPadFill"
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.25
	Build.label(pad, "SELL SCRAP", C(255, 220, 90), 3, Vector2.new(12, 2.8))

	-- Smelter at the back of the island.
	local machineZ = islandMid - 6
	Build.block(m, "MachineBase", Vector3.new(20, 1, 12), at(0, 0.5, machineZ), BLACK, ALL)
	local body = Build.block(m, "MachineBody", Vector3.new(16, 9, 9), at(0, 1 + 4.5, machineZ), STEEL, ALL)
	local _ = body
	for _, y in { 2, 9 } do
		Build.block(m, "MachineTrim", Vector3.new(16.2, 0.6, 9.2), at(0, y, machineZ), YELLOW, ALL)
	end
	-- glowing furnace mouth (faces the pad / the player)
	local mouthZ = machineZ + 4.5 + 0.12
	Build.block(m, "FurnaceFrame", Vector3.new(7.4, 4.6, 0.3), at(0, 4.6, mouthZ - 0.05), BLACK, {})
	local furnace = Build.block(m, "Furnace", Vector3.new(6, 3.4, 0.3), at(0, 4.6, mouthZ), FIRE, {})
	furnace.Material = Enum.Material.Neon
	local glow = Instance.new("PointLight")
	glow.Color = FIRE
	glow.Range = 16
	glow.Brightness = 1.6
	glow.Parent = furnace
	for i = -2, 2 do
		Build.block(m, "Grill", Vector3.new(0.3, 3.4, 0.3), at(i * 1.2, 4.6, mouthZ + 0.2), BLACK, {})
	end
	-- hopper on top
	Build.block(m, "Hopper", Vector3.new(9, 2.6, 6), at(-2, 10 + 1.3, machineZ + 0.5), C(130, 136, 150), ALL)
	local hopper = Build.block(m, "HopperMouth", Vector3.new(7.4, 0.3, 4.4), at(-2, 10 + 2.62, machineZ + 0.5), BLACK, {})
	-- chimney with smoke
	local chimney = cylinder(m, "Chimney", 9, 2.4, at(5.2, 10 + 4.5, machineZ - 2), C(70, 74, 86), Enum.Material.Metal)
	cylinder(m, "ChimneyRing", 0.6, 2.9, at(5.2, 10 + 8.7, machineZ - 2), YELLOW)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 6
	smoke.Lifetime = NumberRange.new(2.5, 4)
	smoke.Speed = NumberRange.new(3, 5)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 5) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(C(90, 90, 96), C(160, 160, 170))
	smoke.EmissionDirection = Enum.NormalId.Right -- the cylinder's X axis points up
	smoke.Parent = chimney
	-- spinning gear on the roof (the client spins Models tagged PressSpin)
	local gear = Instance.new("Model")
	gear.Name = "Gear"
	local gearCf = at(5.6, 10 + 0.6, machineZ + 2.6)
	cylinder(gear, "GearDisc", 0.8, 4.4, gearCf, YELLOW, Enum.Material.Metal)
	for i = 0, 7 do
		local a = i * math.pi / 4
		Build.block(gear, "Tooth", Vector3.new(1, 0.8, 1), gearCf * CFrame.Angles(0, a, 0) * CFrame.new(2.4, 0, 0), YELLOW, {}).Material = Enum.Material.Metal
	end
	cylinder(gear, "GearHub", 1, 1.4, gearCf, BLACK)
	gear:SetAttribute("Speed", 1.2)
	CollectionService:AddTag(gear, "PressSpin")
	gear.Parent = m
	-- conveyor from the pad into the furnace
	local beltStart = padZ - 4
	local beltEnd = mouthZ
	local beltLen = beltStart - beltEnd
	Build.block(m, "ShopBelt", Vector3.new(4.5, 0.5, beltLen), at(0, 0.25, (beltStart + beltEnd) / 2), BLACK)
	for _, x in { -1, 1 } do
		Build.block(m, "ShopBeltRail", Vector3.new(0.6, 0.8, beltLen), at(x * 2.5, 0.4, (beltStart + beltEnd) / 2), YELLOW, ALL)
	end

	-- Auto Collect sign next to the pad
	local signs = RobuxSigns.build(m, theme.edge, { "AutoCollect" })
	signs:PivotTo(at(14, 0, padZ + 1) * CFrame.Angles(0, math.rad(-25), 0))

	m.Parent = plotModel
	return { model = m, pad = pad, furnace = furnace, hopper = hopper }
end

return ScrapShop
