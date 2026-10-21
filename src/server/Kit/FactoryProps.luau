--!strict
-- Reusable, static toy-factory scenery. Ground anchors use local -Z as front.
-- Decoration never participates in train movement, collisions or raycasts.
local Build = require(script.Parent.Build)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local FactoryProps = {}
local V = Vector3.new
local C = Color3.fromRGB
local P = {
	Cream = C(247, 231, 196), Floor = C(229, 186, 91), Blue = C(45, 114, 207),
	Navy = C(30, 54, 88), Red = C(232, 80, 66), Yellow = C(255, 202, 53),
	Teal = C(37, 179, 183), Green = C(105, 196, 77), White = C(250, 248, 234),
	Glass = C(154, 222, 244), Dark = C(34, 43, 59), Brown = C(172, 108, 59),
}
FactoryProps.Colors = P
local TOY_COLORS = { P.Red, P.Yellow, P.Blue, P.Green, P.Teal }
local FACES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back }

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("EnvironmentProp", true)
	m.Parent = parent
	return m
end

function FactoryProps.part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, studs: boolean?): Part
	local p = Build.block(parent, name, size, cf, color, if studs then FACES else {})
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end
local part = FactoryProps.part

local function ball(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = part(parent, name, size, cf, color)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(parent: Instance, name: string, diameter: number, height: number, cf: CFrame, color: Color3): Part
	local p = part(parent, name, V(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.pi / 2), color)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function FactoryProps.beam(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3): Part
	return part(parent, name, V(width, width, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
end

function FactoryProps.sign(parent: Instance, cf: CFrame, width: number, height: number, text: string, color: Color3): Part
	part(parent, "SignBorder", V(width + 2.4, height + 2.4, 1.8), cf, P.Navy)
	local face = part(parent, "FactorySign", V(width, height, 0.5), cf * CFrame.new(0, 0, -1), color)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "FactoryLabel"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 12
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = face
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.94, 0.88)
	label.Position = UDim2.fromScale(0.03, 0.06)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	Style.text(label, 2)
	label.Parent = gui
	return face
end

-- A handful of physical knobs on large toy bricks; small-scale surfaces still
-- use the shared texture helper rather than one part per surface stud.
function FactoryProps.brick(parent: Instance, cf: CFrame, size: Vector3, color: Color3): Model
	local m = model(parent, "ToyBrick")
	part(m, "Body", size, cf * CFrame.new(0, size.Y / 2, 0), color)
	local d = math.min(size.X, size.Z) * 0.24
	for _, x in { -0.25, 0.25 } do
		for _, z in { -0.25, 0.25 } do
			cylinder(m, "Knob", d, d * 0.35, cf * CFrame.new(size.X * x, size.Y + d * 0.175, size.Z * z), color)
		end
	end
	return m
end

function FactoryProps.car(parent: Instance, cf: CFrame, scale: number, color: Color3): Model
	local m = model(parent, "ToyCar")
	local function block(name: string, size: Vector3, pos: Vector3, paint: Color3)
		part(m, name, size * scale, cf * CFrame.new(pos * scale), paint)
	end
	block("Body", V(9, 2.2, 5), V(0, 2, 0), color)
	block("Windows", V(4.4, 2.1, 4.5), V(-0.5, 4.1, 0), P.Glass)
	block("Roof", V(4.8, 0.55, 4.9), V(-0.5, 5.4, 0), color)
	for _, x in { -2.8, 2.8 } do
		for _, z in { -2.55, 2.55 } do
			local wheelCf = cf * CFrame.new(x * scale, 1.35 * scale, z * scale) * CFrame.Angles(math.pi / 2, 0, 0)
			cylinder(m, "Wheel", 2.7 * scale, 0.8 * scale, wheelCf, P.Dark)
		end
	end
	for _, z in { -1.45, 1.45 } do
		block("Headlight", V(0.15, 0.7, 1), V(4.55, 2.4, z), P.White)
	end
	return m
end

function FactoryProps.duck(parent: Instance, cf: CFrame, scale: number): Model
	local m = model(parent, "ToyDuck")
	ball(m, "Body", V(7, 5, 8) * scale, cf * CFrame.new(0, 2.5 * scale, 0), P.Yellow)
	ball(m, "Head", V(4.8, 4.8, 4.8) * scale, cf * CFrame.new(0, 6 * scale, -2 * scale), P.Yellow)
	part(m, "Beak", V(3, 0.85, 2.8) * scale, cf * CFrame.new(0, 5.5 * scale, -4.7 * scale), C(255, 139, 39))
	for _, side in { -1, 1 } do
		ball(m, "Eye", V(0.65, 0.85, 0.65) * scale, cf * CFrame.new(side * 1.55 * scale, 6.45 * scale, -3.55 * scale), P.Dark)
		ball(m, "Wing", V(1.2, 2.8, 4.5) * scale, cf * CFrame.new(side * 3.1 * scale, 2.8 * scale, 0.3 * scale), C(247, 179, 37))
	end
	return m
end

function FactoryProps.crate(parent: Instance, cf: CFrame, size: number, color: Color3, filled: boolean?): Model
	local m = model(parent, "ToyCrate")
	local h = size * 0.7
	part(m, "Base", V(size, 1, size), cf * CFrame.new(0, 0.5, 0), P.Navy)
	for _, side in { -1, 1 } do
		part(m, "Side", V(1, h, size), cf * CFrame.new(side * size / 2, h / 2 + 1, 0), color, true)
		part(m, "End", V(size, h, 1), cf * CFrame.new(0, h / 2 + 1, side * size / 2), color, true)
		part(m, "TopRail", V(size + 2, 1.2, 1.8), cf * CFrame.new(0, h + 1, side * size / 2), P.Yellow)
	end
	if filled then
		for i = 1, 3 do
			FactoryProps.brick(m, cf * CFrame.new((i - 2) * size * 0.26, h * 0.8, (i % 2 - 0.5) * size * 0.35)
				* CFrame.Angles(0, (i - 2) * 0.22, 0), V(size * 0.4, size * 0.3, size * 0.42), TOY_COLORS[i])
		end
	end
	return m
end

function FactoryProps.shelf(parent: Instance, cf: CFrame, variant: number): Model
	local m = model(parent, "ToyShelf")
	for _, x in { -39, 39 } do
		for _, z in { -10, 10 } do
			part(m, "Upright", V(3.2, 69, 3.2), cf * CFrame.new(x, 34.5, z), P.Blue)
		end
	end
	for level = 0, 2 do
		local y = 4 + level * 23
		part(m, "Shelf", V(84, 2.5, 24), cf * CFrame.new(0, y, 0), P.Navy)
		part(m, "ShelfLip", V(84, 3, 1.3), cf * CFrame.new(0, y, -12), if level % 2 == 0 then P.Yellow else P.Red)
		for slot = -1, 1 do
			local anchor = cf * CFrame.new(slot * 26, y + 1.25, 0)
			local kind = (variant + level + slot + 3) % 3
			if kind == 0 then
				FactoryProps.car(m, anchor, 2, TOY_COLORS[(variant + level) % #TOY_COLORS + 1])
			elseif kind == 1 then
				FactoryProps.duck(m, anchor, 1.8)
			else
				FactoryProps.brick(m, anchor, V(19, 9, 15), TOY_COLORS[(variant + slot + 5) % #TOY_COLORS + 1])
				FactoryProps.brick(m, anchor * CFrame.new(2, 10.6, 0) * CFrame.Angles(0, 0.15, 0), V(12, 6, 11), P.Green)
			end
		end
	end
	return m
end

function FactoryProps.bear(parent: Instance, cf: CFrame, scale: number): Model
	local m = model(parent, "FactoryTeddy")
	local tan, cream = C(187, 120, 65), C(247, 210, 153)
	local function round(name: string, size: Vector3, pos: Vector3, color: Color3)
		ball(m, name, size * scale, cf * CFrame.new(pos * scale), color)
	end
	round("Body", V(10, 12, 7), V(0, 8, 0), tan)
	round("Belly", V(7, 8, 1.2), V(0, 7.5, -3.25), cream)
	round("Head", V(10, 9, 7.8), V(0, 17, -0.6), tan)
	round("Muzzle", V(5.6, 3.7, 2), V(0, 15.9, -4.15), cream)
	round("Nose", V(1.7, 1.2, 0.9), V(0, 16.8, -5.1), P.Dark)
	for _, side in { -1, 1 } do
		round("Ear", V(3.5, 3.5, 2.7), V(side * 4.1, 20.8, -0.4), tan)
		round("EarInset", V(2.1, 2.1, 0.6), V(side * 4.1, 20.8, -1.8), cream)
		round("Eye", V(0.8, 1.1, 0.7), V(side * 2.1, 18, -4.2), P.Dark)
		round("EyeGlint", V(0.22, 0.25, 0.16), V(side * 2.1 - 0.12, 18.2, -4.55), P.White)
		round("Arm", V(4, 8, 4.5), V(side * 6, 8, -0.2), tan)
		round("Foot", V(5.5, 5, 7), V(side * 4, 2.5, -3), tan)
		round("Paw", V(3.4, 3.4, 0.7), V(side * 4, 2.7, -6.5), cream)
		part(m, "Bow", V(3, 2.8, 1.5) * scale, cf * CFrame.new(side * 1.7 * scale, 12.2 * scale, -4 * scale)
			* CFrame.Angles(0, 0, side * 0.2), P.Red)
	end
	round("BowKnot", V(1.9, 2, 1.7), V(0, 12.2, -4.2), P.Red)
	return m
end

-- Stationary perimeter belt: no extra heartbeat connections or moving parts.
function FactoryProps.conveyor(parent: Instance, cf: CFrame, length: number): Model
	local m = model(parent, "ToySupplyConveyor")
	part(m, "Belt", V(length, 2.5, 14), cf * CFrame.new(0, 25, 0), P.Dark)
	for _, z in { -7.6, 7.6 } do
		part(m, "Rail", V(length + 2, 3, 1.6), cf * CFrame.new(0, 26, z), P.Blue)
	end
	for x = -length / 2 + 10, length / 2 - 5, 28 do
		part(m, "Support", V(2.5, 24, 9), cf * CFrame.new(x, 12, 0), P.Navy)
		FactoryProps.brick(m, cf * CFrame.new(x, 26.3, 0), V(12, 7, 10), TOY_COLORS[math.floor((x + length / 2) / 28) % #TOY_COLORS + 1])
		-- Chunky chevrons on the outward-facing rail.
		for _, side in { -1, 1 } do
			part(m, "Arrow", V(3, 0.8, 0.2), cf * CFrame.new(x, 26 + side * 0.75, -8.5)
				* CFrame.Angles(0, 0, side * math.pi / 6), P.Yellow)
		end
	end
	return m
end

function FactoryProps.crane(parent: Instance, cf: CFrame): Model
	local m = model(parent, "FactoryGantry")
	for _, x in { -98, 98 } do
		part(m, "Tower", V(5, 100, 7), cf * CFrame.new(x, 50, 0), P.Blue)
		part(m, "Foot", V(14, 4, 17), cf * CFrame.new(x, 2, 0), P.Navy)
	end
	for _, y in { 93, 103 } do
		part(m, "GantryBeam", V(210, 3, 8), cf * CFrame.new(0, y, 0), P.Yellow)
	end
	for x = -98, 84, 14 do
		FactoryProps.beam(m, "Truss", (cf * CFrame.new(x, 94, -3)).Position,
			(cf * CFrame.new(x + 14, 102, -3)).Position, 1.3, P.Yellow)
	end
	part(m, "Trolley", V(19, 6, 14), cf * CFrame.new(22, 91, 0), P.Blue)
	for _, x in { 19, 25 } do
		part(m, "Cable", V(0.6, 35, 0.6), cf * CFrame.new(x, 70.5, 0), P.Dark)
	end
	part(m, "LiftingBar", V(24, 2, 3), cf * CFrame.new(22, 53, 0), P.Yellow)
	FactoryProps.crate(m, cf * CFrame.new(22, 37, 0), 20, P.Red, true)
	return m
end

function FactoryProps.packingBooth(parent: Instance, cf: CFrame): Model
	local m = model(parent, "PackingBooth")
	part(m, "Counter", V(32, 10, 15), cf * CFrame.new(0, 5, 0), P.Blue, true)
	part(m, "Worktop", V(34, 1, 17), cf * CFrame.new(0, 10.5, 0), P.Cream)
	for _, x in { -16, 16 } do
		part(m, "Post", V(2, 23, 2), cf * CFrame.new(x, 11.5, 3), P.Navy)
	end
	for i = 0, 7 do
		part(m, "AwningStripe", V(4.5, 1.5, 22), cf * CFrame.new(-15.75 + i * 4.5, 24, -2)
			* CFrame.Angles(math.rad(-10), 0, 0), if i % 2 == 0 then P.Red else P.White)
	end
	FactoryProps.sign(m, cf * CFrame.new(0, 19.5, -5), 27, 5, "TOY PACKING", P.Blue)
	FactoryProps.crate(m, cf * CFrame.new(-26, 0, 2), 13, P.Yellow, true)
	FactoryProps.crate(m, cf * CFrame.new(27, 0, 5), 16, P.Teal, true)
	return m
end

return FactoryProps
