--!strict
-- The scrap shop on every plot, just inside the entrance gate: a "SCRAP SHOP"
-- gate into a dark floor with the smelter (hopper, glowing furnace, smoking
-- chimney, spinning gear), a conveyor, the Deposit / Collect Cash / Smelt Speed /
-- Finish Now pads and the Smelting board (server/Scrap.luau runs them).
--
-- Built in its own frame: the entrance line runs through `frame` along its X,
-- the shop extends into the frame's -Z. Sizes in Config.ScrapShop.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local Pads = require(script.Parent.Pads)

local ScrapShop = {}

local C = Color3.fromRGB
local YELLOW = C(245, 190, 40)
local BLACK = C(30, 30, 34)
local STEEL = C(96, 102, 118)
local FIRE = C(255, 130, 40)

local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

export type Shop = {
	model: Model,
	pad: BasePart, -- Deposit Scrap pad (stand on it: your scrap goes into the smelter)
	collect: BasePart, -- Collect Cash pad (smelted cash waits here)
	speed: BasePart, -- + Smelt Speed pad (cash upgrade)
	finish: BasePart, -- Finish Now pad (Robux product)
	board: Instance, -- SurfaceGui "Smelting" with labels Head / Amount / Rate and Bar.Fill
	furnace: BasePart, -- glowing mouth (flares when you collect)
	hopper: BasePart, -- top of the smelter (deposited scrap flies in here)
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

function ScrapShop.build(plotModel: Model, frame: CFrame, theme: { [string]: Color3 }): Shop
	local S = { Depth = Config.ScrapShop.Depth, Width = Config.ScrapShop.Width }
	local islandFront = 0
	local islandMid = islandFront - S.Depth / 2
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end

	local m = Instance.new("Model")
	m.Name = "ScrapShop"

	-- dark asphalt floor
	Build.block(m, "ShopFloor", Vector3.new(S.Width, 0.1, S.Depth), at(0, 0.05, islandMid), theme.pad).CanCollide = false
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

	-- Pads (Yuzu stand style): Deposit right behind the gate, Collect Cash left,
	-- + Smelt Speed right, Finish Now next to the smelter.
	local padZ = islandFront - 7.5
	local pad = Pads.make(m, at(0, 0, padZ), "Deposit", C(255, 214, 70), "Deposit Scrap")
	pad.Name = "SellPadFill" -- (name kept: the guide arrows look for it)
	local collect = Pads.make(m, at(-13, 0, padZ), "Collect", C(110, 230, 80), "Collect Cash")
	collect.Name = "CollectPadFill"
	local speed = Pads.make(m, at(13, 0, padZ), "SmeltSpeed", C(255, 120, 60), "+ Smelt Speed")
	local finish = Pads.make(m, at(-16.5, 0, islandFront - 19), "FinishSmelt", C(255, 160, 40), "Finish Now", 6)

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

	-- "Smelting" board (the Yuzu stand's "Selling Yuzu 9.98K / 1 Yuzu/Sec" sign)
	local boardModel, face = Build.signFrame(m, at(16, 0, islandFront - 20) * CFrame.Angles(0, math.rad(-20), 0), 11, 7, theme.dark)
	boardModel.Name = "SmeltBoard"
	face.Color = C(250, 236, 190)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Smelting"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = face
	local function line(name: string, y: number, h: number, color: Color3, stroke: number, text: string)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Position = UDim2.fromScale(0.05, y)
		l.Size = UDim2.fromScale(0.9, h)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Text = text
		l.Parent = gui
		Style.text(l, stroke)
		l.TextColor3 = color
	end
	line("Head", 0.04, 0.22, C(255, 196, 60), 4, "Smelting Scrap")
	line("Amount", 0.27, 0.3, C(130, 255, 90), 5, "$0")
	line("Rate", 0.58, 0.16, C(120, 200, 255), 3, "Deposit scrap to smelt it")
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromScale(0.08, 0.8)
	bar.Size = UDim2.fromScale(0.84, 0.12)
	bar.BackgroundColor3 = C(40, 40, 48)
	bar.Parent = gui
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0)
	barCorner.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = C(255, 150, 40)
	fill.Parent = bar
	local fillCorner = barCorner:Clone()
	fillCorner.Parent = fill

	m.Parent = plotModel
	return { model = m, pad = pad, collect = collect, speed = speed, finish = finish, board = gui, furnace = furnace, hopper = hopper }
end

return ScrapShop
