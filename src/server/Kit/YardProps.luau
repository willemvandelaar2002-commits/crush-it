--!strict
-- Static toy scrapyard set dressing. Every new part is anchored and cannot
-- block walking, raycasts or touch triggers. No animation loops or particles.
local Build = require(script.Parent.Build)
local YardProps = {}
local C = Color3.fromRGB
local V = Vector3.new
local DARK = C(42, 54, 69)
local STEEL = C(173, 187, 198)
local YELLOW = C(255, 193, 36)
local COLORS = { C(33, 95, 206), C(25, 155, 142), C(216, 62, 49) }
local SIDES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back }

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("EnvironmentProp", true)
	return m
end

local function part(m: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, studs: boolean?): Part
	local p = Build.block(m, name, size, cf, color, if studs then SIDES else {})
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

-- Scale around the supplied ground anchor, not the bounding-box centre.
local function finish(m: Model, parent: Instance, cf: CFrame, scale: number?): Model
	m.WorldPivot = cf
	if scale and scale ~= 1 then m:ScaleTo(scale) end
	m.Parent = parent
	return m
end

local function cylinder(m: Instance, name: string, diameter: number, height: number, cf: CFrame, color: Color3): Part
	local p = part(m, name, V(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.pi / 2), color)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function cube(m: Instance, cf: CFrame, size: number, color: Color3)
	part(m, "CrushedCube", V(size, size * 0.85, size), cf * CFrame.new(0, size * 0.425, 0), color, true)
	for _, x in { -0.27, 0.27 } do
		part(m, "ScrapBand", V(size * 0.08, size * 0.86, size + 0.06), cf * CFrame.new(size * x, size * 0.425, 0), DARK)
	end
end

function YardProps.bales(parent: Instance, cf: CFrame, scale: number?): Model
	local m = model("SortedScrap")
	local s = scale or 1
	part(m, "Pallet", V(7, 0.5, 4) * s, cf * CFrame.new(0, 0.25 * s, 0), STEEL, true)
	cube(m, cf * CFrame.new(-1.65 * s, 0.5 * s, 0), 2.8 * s, COLORS[1])
	cube(m, cf * CFrame.new(1.65 * s, 0.5 * s, 0), 2.8 * s, COLORS[2])
	cube(m, cf * CFrame.new(-1.3 * s, 2.88 * s, 0) * CFrame.Angles(0, 0.12, 0), 2.6 * s, COLORS[3])
	m.Parent = parent
	return m
end

function YardProps.container(parent: Instance, cf: CFrame, color: Color3, scale: number?): Model
	local m = model("ShippingContainer")
	part(m, "Body", V(22, 10, 9), cf * CFrame.new(0, 5, 0), color, true)
	for _, z in { -4.6, 4.6 } do
		for x = -9, 9, 3 do
			part(m, "Rib", V(0.45, 9.3, 0.25), cf * CFrame.new(x, 5, z), color:Lerp(Color3.new(1, 1, 1), 0.16))
		end
		for _, y in { 0.4, 9.6 } do
			part(m, "Rail", V(22.4, 0.65, 0.4), cf * CFrame.new(0, y, z), DARK)
		end
	end
	for _, z in { -2.2, 2.2 } do
		part(m, "Door", V(0.2, 8.3, 4.1), cf * CFrame.new(11.12, 5, z), color:Lerp(STEEL, 0.2))
		part(m, "Latch", V(0.35, 6.5, 0.22), cf * CFrame.new(11.3, 5, z), STEEL)
	end
	return finish(m, parent, cf, scale)
end

function YardProps.vehicle(parent: Instance, cf: CFrame, color: Color3, scale: number?): Model
	local m = model("ScrapVehicle")
	part(m, "Body", V(12, 2.5, 5.5), cf * CFrame.new(0, 2.5, 0), color, true)
	part(m, "Cab", V(5.6, 1.8, 4.9), cf * CFrame.new(-0.5, 4.4, 0) * CFrame.Angles(0, 0, 0.08), color, true)
	part(m, "Glass", V(4.1, 1.1, 5), cf * CFrame.new(-0.5, 4.6, 0), C(156, 216, 229))
	part(m, "Roof", V(5.7, 0.35, 5.1), cf * CFrame.new(-0.5, 5.45, 0), color)
	for _, x in { -3.8, 3.8 } do
		for _, z in { -2.9, 2.9 } do
			cylinder(m, "Tyre", 2.7, 0.8, cf * CFrame.new(x, 1.35, z) * CFrame.Angles(math.pi / 2, 0, 0), DARK)
		end
	end
	part(m, "Bumper", V(0.45, 0.7, 5.8), cf * CFrame.new(6.1, 2.2, 0), STEEL)
	return finish(m, parent, cf, scale)
end

-- One compact station, roughly 8 x 6 studs and at most 6 studs high.
function YardProps.cluster(parent: Instance, cf: CFrame, variant: number, scale: number?): Model
	local m = model("WorkshopCluster")
	local kind = variant % 3
	if kind == 0 then
		part(m, "ToolCabinet", V(3.6, 4, 2.4), cf * CFrame.new(-1.5, 2, 0), COLORS[1], true)
		part(m, "Worktop", V(4, 0.3, 2.8), cf * CFrame.new(-1.5, 4.15, 0), STEEL)
		for y = 0.7, 3.3, 1.2 do
			part(m, "Drawer", V(3.15, 0.8, 0.12), cf * CFrame.new(-1.5, y, -1.25), COLORS[2])
			part(m, "Handle", V(1.1, 0.18, 0.2), cf * CFrame.new(-1.5, y, -1.4), STEEL)
		end
		cylinder(m, "Cable", 2.2, 1.9, cf * CFrame.new(2.3, 1.3, 0) * CFrame.Angles(math.pi / 2, 0, 0), DARK)
		for _, z in { -1.1, 1.1 } do
			cylinder(m, "ReelFlange", 2.8, 0.25, cf * CFrame.new(2.3, 1.4, z) * CFrame.Angles(math.pi / 2, 0, 0), YELLOW)
		end
	elseif kind == 1 then
		part(m, "Crate", V(3.6, 3.6, 3.6), cf * CFrame.new(-1.5, 1.8, 0), C(179, 151, 105), true)
		for _, y in { 0.5, 3.1 } do
			part(m, "CrateBand", V(3.7, 0.35, 3.7), cf * CFrame.new(-1.5, y, 0), DARK)
		end
		cylinder(m, "Barrel", 2.5, 3.6, cf * CFrame.new(2.3, 1.8, 0.8), COLORS[2])
		for _, y in { 0.5, 3.1 } do
			cylinder(m, "BarrelRing", 2.65, 0.18, cf * CFrame.new(2.3, y, 0.8), STEEL)
		end
	else
		part(m, "BinBase", V(5.2, 0.5, 3.8), cf * CFrame.new(0, 0.25, 0), DARK)
		for _, x in { -2.5, 2.5 } do
			part(m, "BinSide", V(0.3, 2.8, 3.8), cf * CFrame.new(x, 1.6, 0), COLORS[2], true)
		end
		for _, z in { -1.8, 1.8 } do
			part(m, "BinWall", V(5, 2.8, 0.3), cf * CFrame.new(0, 1.6, z), COLORS[2], true)
		end
		cube(m, cf * CFrame.new(-1.1, 1.6, 0), 1.7, STEEL)
		cube(m, cf * CFrame.new(0.9, 1.9, 0.3) * CFrame.Angles(0, 0.3, 0.1), 1.6, COLORS[3])
		part(m, "BinLabel", V(1.6, 0.5, 0.12), cf * CFrame.new(0, 1.9, -2), YELLOW)
	end
	return finish(m, parent, cf, scale)
end

function YardProps.workLight(parent: Instance, cf: CFrame, lit: boolean?): Model
	local m = model("WorkLight")
	part(m, "Base", V(2.5, 0.6, 2.5), cf * CFrame.new(0, 0.3, 0), DARK, true)
	part(m, "Post", V(0.65, 5.5, 0.65), cf * CFrame.new(0, 3.1, 0), STEEL)
	part(m, "Housing", V(3.4, 1.8, 1), cf * CFrame.new(0, 6, 0), COLORS[1], true)
	local lens = part(m, "Lens", V(2.8, 1.1, 0.12), cf * CFrame.new(0, 6, -0.56), C(255, 245, 208))
	if lit then
		local light = Instance.new("PointLight")
		light.Color = lens.Color
		light.Range = 14
		light.Brightness = 0.45
		light.Shadows = false
		light.Parent = lens
	end
	m.Parent = parent
	return m
end

function YardProps.crane(parent: Instance, cf: CFrame, scale: number?, carLoad: boolean?): Model
	local m = model("SkylineCrane")
	part(m, "Base", V(11, 2, 10), cf * CFrame.new(0, 1, 0), DARK, true)
	part(m, "Mast", V(4, 32, 4), cf * CFrame.new(0, 18, 0), YELLOW, true)
	part(m, "MastRail", V(1.2, 32, 1.2), cf * CFrame.new(3.5, 18, 0), YELLOW, true)
	for y = 7, 29, 11 do
		part(m, "Collar", V(4.3, 0.7, 4.3), cf * CFrame.new(0, y, 0), DARK)
		part(m, "Brace", V(1, 11.5, 1), cf * CFrame.new(1.8, y + 3, 0) * CFrame.Angles(0, 0, -0.3), YELLOW)
	end
	part(m, "Cab", V(8, 6, 7), cf * CFrame.new(0, 34, 0), COLORS[1], true)
	part(m, "Window", V(8.1, 2.8, 6), cf * CFrame.new(0, 34.5, 0), C(165, 218, 232))
	part(m, "Boom", V(36, 2.6, 3.5), cf * CFrame.new(10, 39, 0), YELLOW, true)
	part(m, "BoomTop", V(36, 0.8, 1), cf * CFrame.new(10, 43, 0), YELLOW)
	for x = -3, 23, 6.5 do
		part(m, "BoomBrace", V(0.8, 6.8, 0.8), cf * CFrame.new(x, 41, 0) * CFrame.Angles(0, 0, -0.95), YELLOW)
	end
	part(m, "Counterweight", V(6, 5, 5), cf * CFrame.new(-7, 35.5, 0), DARK, true)
	part(m, "Cable", V(0.3, 17, 0.3), cf * CFrame.new(25, 29, 0), DARK)
	cylinder(m, "Magnet", 6, 1.2, cf * CFrame.new(25, 20, 0), STEEL)
	if carLoad then
		YardProps.vehicle(m, cf * CFrame.new(25, 13.5, 0) * CFrame.Angles(0, 0.15, 0.08), COLORS[3])
	else
		cube(m, cf * CFrame.new(25, 15, 0), 5, COLORS[3])
	end
	return finish(m, parent, cf, scale)
end

function YardProps.cableReel(parent: Instance, cf: CFrame, scale: number?): Model
	local m = model("CableReel")
	local axis = CFrame.Angles(math.pi / 2, 0, 0)
	cylinder(m, "Cable", 6.4, 4.7, cf * CFrame.new(0, 4, 0) * axis, DARK)
	for _, z in { -2.6, 2.6 } do
		cylinder(m, "Flange", 8, 0.65, cf * CFrame.new(0, 4, z) * axis, C(203, 148, 60))
		cylinder(m, "Hub", 2.3, 0.8, cf * CFrame.new(0, 4, z) * axis, STEEL)
	end
	return finish(m, parent, cf, scale)
end

-- A complete perimeter composition; its centre remains outside playable plots.
function YardProps.yardScene(parent: Instance, cf: CFrame, variant: number, crane: boolean?): Model
	local m = model("PerimeterYard")
	local color = COLORS[variant % 3 + 1]
	YardProps.container(m, cf * CFrame.new(0, 0, 24), color, 1.8)
	YardProps.container(m, cf * CFrame.new(30, 0, 27) * CFrame.Angles(0, math.pi / 2, 0), COLORS[(variant + 1) % 3 + 1], 1.8)
	YardProps.container(m, cf * CFrame.new(-5, 18, 24) * CFrame.Angles(0, 0.08, 0), COLORS[(variant + 2) % 3 + 1], 1.8)
	YardProps.bales(m, cf * CFrame.new(16, 0, -10), 2.4)
	YardProps.cableReel(m, cf * CFrame.new(38, 0, -7), 1.5)
	YardProps.cableReel(m, cf * CFrame.new(43, 0, 7), 1.1)
	if crane then
		YardProps.crane(m, cf * CFrame.new(-34, 0, -8), 1.65, true)
	else
		YardProps.vehicle(m, cf * CFrame.new(-28, 0, -7) * CFrame.Angles(0, -0.2, 0), COLORS[(variant + 1) % 3 + 1], 1.8)
	end
	return finish(m, parent, cf)
end

function YardProps.workshop(parent: Instance, cf: CFrame): Model
	local m = model("PerimeterWorkshop")
	part(m, "Body", V(32, 16, 20), cf * CFrame.new(0, 8, 0), COLORS[2], true)
	part(m, "Roof", V(35, 2, 23), cf * CFrame.new(0, 17, 0), DARK, true)
	part(m, "Shutter", V(18, 12, 0.4), cf * CFrame.new(1, 6, -10.3), C(65, 79, 87), true)
	for y = 2, 10, 4 do
		part(m, "ShutterRail", V(18, 0.45, 0.6), cf * CFrame.new(1, y, -10.5), STEEL)
	end
	for x = -16, 16, 4 do
		local shade = if (x + 16) % 8 == 0 then C(248, 173, 43) else C(255, 239, 193)
		part(m, "AwningStripe", V(4, 0.8, 10), cf * CFrame.new(x, 14, -13) * CFrame.Angles(0.12, 0, 0), shade)
		part(m, "AwningValance", V(4, 2, 0.7), cf * CFrame.new(x, 12.7, -18), shade)
	end
	for _, x in { -17, 17 } do
		part(m, "AwningPost", V(1, 13, 1), cf * CFrame.new(x, 6.5, -17.5), DARK, true)
	end
	part(m, "OrangeVent", V(5, 4, 3), cf * CFrame.new(-10, 19, 3), C(232, 112, 35), true)
	YardProps.cluster(m, cf * CFrame.new(-22, 0, -6), 1, 1.8)
	YardProps.cluster(m, cf * CFrame.new(23, 0, -6), 0, 1.8)
	return finish(m, parent, cf)
end

-- Placed at the existing hub sign area, spanning its road without posts in it.
function YardProps.entrance(parent: Instance, cf: CFrame): Model
	local m = model("ScrapyardEntrance")
	for _, x in { -12, 12 } do
		part(m, "Pillar", V(3, 20, 3), cf * CFrame.new(x, 10, 0), COLORS[1], true)
		part(m, "Foot", V(4, 1.2, 4), cf * CFrame.new(x, 0.6, 0), DARK, true)
		part(m, "YellowCollar", V(3.2, 1, 3.2), cf * CFrame.new(x, 3, 0), YELLOW)
	end
	part(m, "Beam", V(29, 3, 3), cf * CFrame.new(0, 21, 0), COLORS[1], true)
	local sign = part(m, "Sign", V(20, 4.5, 3.2), cf * CFrame.new(0, 24.75, 0), DARK)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 24
		gui.LightInfluence = 0
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Text = "CRUSH IT"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Parent = gui
	end
	part(m, "Chain", V(0.35, 2.2, 0.35), cf * CFrame.new(0, 18.4, 0), DARK)
	cube(m, cf * CFrame.new(0, 13.5, 0) * CFrame.Angles(0, 0.3, 0), 4.5, COLORS[2])
	m.Parent = parent
	return m
end

return YardProps
