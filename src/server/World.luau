--!strict
-- A bright toy factory around the existing Toy Train Loop. Only the old
-- scrapyard backdrop is replaced; plot/rail/hub geometry and rescue height stay.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Kit.Build)
local FactoryProps = require(script.Parent.Kit.FactoryProps)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local World = {}
local V = Vector3.new
local P = FactoryProps.Colors
local TOY_BAY_COLORS = { P.Blue, P.Teal, P.Red, P.Yellow }
local part = FactoryProps.part
local FLOOR_Y = Config.World.SeaY
-- All current plot corners are inside radius ~387. Keep the hall and its large
-- display furniture outside that envelope; never derive train positions here.
local PLOT_ENVELOPE = math.sqrt((Config.Plots.Ring + Config.Plots.Front + Config.Plots.Back) ^ 2
	+ (Config.Plots.FloorSize / 2) ^ 2)
local HALF = math.max(440, math.ceil((PLOT_ENVELOPE + 52) / 20) * 20)
local HEIGHT = 150

local function group(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("EnvironmentProp", true)
	m.Parent = parent
	return m
end

local function floor(parent: Instance)
	-- Same top, extent and collision as the former sandy rescue apron. This is
	-- scenery below the existing platforms, not a new player walking surface.
	local base = Build.block(parent, "YardFloor", V(2048, 1, 2048), CFrame.new(0, FLOOR_Y - 0.5, 0), P.Floor, {})
	base.CanCollide = true
	base.CanTouch = false
	base.CanQuery = false
	base.CastShadow = false
	Style.studs(base, { Enum.NormalId.Top }, 4)
	-- Large, subtle floor panels give the factory scale without tiny litter.
	for _, x in { -HALF + 65, HALF - 65 } do
		local lane = part(parent, "PerimeterServiceLane", V(46, 0.05, HALF * 2 - 50), CFrame.new(x, FLOOR_Y + 0.03, 0), P.Navy)
		lane.CastShadow = false
		for _, side in { -1, 1 } do
			part(parent, "LanePaint", V(0.8, 0.06, HALF * 2 - 50), CFrame.new(x + side * 22, FLOOR_Y + 0.06, 0), P.Yellow).CastShadow = false
		end
	end
end

local function wall(parent: Instance, cf: CFrame, index: number)
	local m = group(parent, "FactoryWall" .. index)
	local width = HALF * 2 / 8
	for i = 0, 7 do
		local x = -HALF + width * (i + 0.5)
		local bay = cf * CFrame.new(x, 0, 0)
		local panel = part(m, "BoundaryWall", V(width + 0.2, 52, 4), bay * CFrame.new(0, 26, 0), P.Cream)
		panel.CanCollide = true
		part(m, "BlueWainscot", V(width + 0.2, 19, 1), bay * CFrame.new(0, 9.5, -2.6), P.Blue)
		part(m, "WallStripe", V(width + 0.2, 2, 1.2), bay * CFrame.new(0, 20, -2.8), P.Teal)
		part(m, "WindowSill", V(width, 3, 9), bay * CFrame.new(0, 53, -2), P.Yellow)
		local window = part(m, "Window", V(width - 7, 66, 0.6), bay * CFrame.new(0, 88, 0), P.Glass)
		window.Transparency = 0.72
		window.CastShadow = false
		window.CanCollide = true
		for _, dx in { -width / 2 + 3, 0, width / 2 - 3 } do
			part(m, "WindowMullion", V(1.7, 67, 2), bay * CFrame.new(dx, 88, -0.8), P.Blue)
		end
		part(m, "WindowMullion", V(width - 4, 1.7, 2), bay * CFrame.new(0, 86, -0.8), P.Blue)
		part(m, "UpperWall", V(width + 0.2, 28, 4), bay * CFrame.new(0, 136, 0), P.Cream)
		part(m, "HighYellowBand", V(width + 0.2, 5, 2), bay * CFrame.new(0, 124, -3), P.Yellow)
	end
	for i = 0, 8 do
		local x = -HALF + i * width
		part(m, "RedColumn", V(7, HEIGHT, 9), cf * CFrame.new(x, HEIGHT / 2, -4), P.Red)
		part(m, "ColumnBoot", V(10, 13, 12), cf * CFrame.new(x, 6.5, -4), P.Navy)
		FactoryProps.beam(m, "RoofKnee", (cf * CFrame.new(x, HEIGHT - 27, -4)).Position,
			(cf * CFrame.new(x, HEIGHT - 5, -28)).Position, 4, P.Red)
	end
end

local function roof(parent: Instance)
	local m = group(parent, "SkylightRoof")
	local y = FLOOR_Y + HEIGHT
	local bayWidth = HALF / 2
	for i = 0, 4 do
		local x = -HALF + i * bayWidth
		local rib = part(m, "CreamRoofRib", V(14, 3, HALF * 2 + 14), CFrame.new(x, y + 2, 0), P.Cream)
		rib.CastShadow = false
		if i < 4 then
			local glass = part(m, "Skylight", V(bayWidth - 14, 0.5, HALF * 2), CFrame.new(x + bayWidth / 2, y + 2, 0), P.Glass)
			glass.Transparency = 0.86
			glass.CastShadow = false
		end
	end
	for i = 0, 8 do
		local z = -HALF + i * HALF / 4
		local beam = part(m, "RoofBeam", V(HALF * 2, 6, 6), CFrame.new(0, y - 2, z), P.Red)
		-- The airy roof must not turn the playing area into a dark warehouse.
		beam.CastShadow = false
		for _, x in { -HALF * 0.55, HALF * 0.55 } do
			part(m, "LampCable", V(0.5, 11, 0.5), CFrame.new(x, y - 9, z), P.Navy)
			part(m, "Pendant", V(9, 3, 9), CFrame.new(x, y - 16, z), P.Navy)
			local lens = part(m, "PendantLens", V(7.5, 0.4, 7.5), CFrame.new(x, y - 17.6, z), P.White)
			lens.Material = Enum.Material.Neon
			lens.CastShadow = false
			-- Emissive geometry only; no extra shadowed point lights over the plots.
		end
	end
end

local function loadingBay(parent: Instance, cf: CFrame, text: string)
	local m = group(parent, "LoadingBay")
	part(m, "DoorFrame", V(61, 43, 3), cf * CFrame.new(0, 21.5, 0), P.Blue)
	part(m, "Shutter", V(53, 36, 1.2), cf * CFrame.new(0, 19, -2), P.Navy)
	for y = 3, 36, 3 do
		part(m, "ShutterSlat", V(52, 0.45, 0.5), cf * CFrame.new(0, y, -2.8), P.Blue)
	end
	for _, x in { -28.5, 28.5 } do
		part(m, "SafetyPost", V(3.5, 19, 4), cf * CFrame.new(x, 9.5, -3), P.Yellow)
	end
	FactoryProps.sign(m, cf * CFrame.new(0, 47, -2), 57, 7, text, P.Blue)
end

local function displays(parent: Instance)
	local m = group(parent, "ToyDisplays")
	local inset = HALF - 25
	for i, p in {
		{ pos = V(-230, FLOOR_Y, inset), yaw = 0 }, { pos = V(230, FLOOR_Y, inset), yaw = 0 },
		{ pos = V(-230, FLOOR_Y, -inset), yaw = math.pi }, { pos = V(230, FLOOR_Y, -inset), yaw = math.pi },
		{ pos = V(inset, FLOOR_Y, -210), yaw = math.pi / 2 }, { pos = V(inset, FLOOR_Y, 210), yaw = math.pi / 2 },
		{ pos = V(-inset, FLOOR_Y, -210), yaw = -math.pi / 2 }, { pos = V(-inset, FLOOR_Y, 210), yaw = -math.pi / 2 },
	} do
		FactoryProps.shelf(m, CFrame.new(p.pos) * CFrame.Angles(0, p.yaw, 0), i)
		task.wait()
	end
	-- Large mascots sit in outer corners, wholly beyond the plot envelope.
	local bearPos = V(HALF - 91, FLOOR_Y, HALF - 91)
	local bearCf = CFrame.lookAt(bearPos, V(0, FLOOR_Y, 0))
	FactoryProps.crate(m, bearCf, 42, P.Yellow, false)
	FactoryProps.bear(m, bearCf * CFrame.new(0, 31, 0), 3.3)
	local duckPos = V(-HALF + 89, FLOOR_Y, -HALF + 89)
	local duckCf = CFrame.lookAt(duckPos, V(0, FLOOR_Y, 0))
	FactoryProps.crate(m, duckCf, 38, P.Blue, false)
	FactoryProps.duck(m, duckCf * CFrame.new(0, 28, 0), 6)
	FactoryProps.packingBooth(m, CFrame.new(-HALF + 78, FLOOR_Y, HALF - 85) * CFrame.Angles(0, -math.pi / 4, 0))
	FactoryProps.crane(m, CFrame.new(0, FLOOR_Y, HALF - 27))
	-- Supply belts hug the other walls; they never cross the train or bridges.
	FactoryProps.conveyor(m, CFrame.new(0, FLOOR_Y, -HALF + 24) * CFrame.Angles(0, math.pi, 0), 300)
	FactoryProps.conveyor(m, CFrame.new(HALF - 24, FLOOR_Y, 0) * CFrame.Angles(0, math.pi / 2, 0), 250)
	loadingBay(m, CFrame.new(-63, FLOOR_Y, HALF - 4), "TOY STORAGE")
	loadingBay(m, CFrame.new(63, FLOOR_Y, HALF - 4), "DISPATCH")
	FactoryProps.sign(m, CFrame.new(0, FLOOR_Y + 125, HALF - 7), 180, 22, "CRUSH IT", P.Blue)
	FactoryProps.sign(m, CFrame.new(-HALF + 7, FLOOR_Y + 125, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		150, 17, "TOY FACTORY", P.Teal)
end

local function toyBays(parent: Instance)
	-- The current hub already fills this space with raised commons and work
	-- bays. Keep those displays instead of burying duplicates at apron height.
	local plots = Workspace:FindFirstChild("Plots")
	local hub = plots and plots:FindFirstChild("Hub")
	if hub and hub:FindFirstChild("WorkshopCommons") then return end
	local m = group(parent, "ToySupplyBays")
	-- Four small displays between the hub spokes. All stay well inside the
	-- railway's inner curb, outside the central hub and off every walkway.
	local r = (Config.Loop.Hub + Config.Loop.Inner) / 2
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local pos = V(math.sin(a) * r, FLOOR_Y, math.cos(a) * r)
		local cf = CFrame.lookAt(pos, V(0, FLOOR_Y, 0))
		part(m, "DisplayMat", V(42, 0.15, 29), cf * CFrame.new(0, 0.08, 0), P.Navy)
		FactoryProps.crate(m, cf * CFrame.new(-10, 0.16, 0), 16, TOY_BAY_COLORS[i + 1], true)
		FactoryProps.car(m, cf * CFrame.new(11, 0.16, 0), 1.6, P.Red)
	end
end

function World.create()
	Build.lighting("FactoryDay")
	local old = Workspace:FindFirstChild("World")
	if old then old:Destroy() end
	local root = Instance.new("Model")
	root.Name = "World"
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root:SetAttribute("Theme", "ToyFactory")
	root:SetAttribute("HallHalfSize", HALF)
	root:SetAttribute("PlotEnvelope", PLOT_ENVELOPE)
	root.Parent = Workspace
	floor(root)
	for i = 0, 3 do
		local a = i * math.pi / 2
		wall(root, CFrame.new(math.sin(a) * HALF, FLOOR_Y, math.cos(a) * HALF) * CFrame.Angles(0, a, 0), i + 1)
		task.wait()
	end
	roof(root)
	displays(root)
	toyBays(root)
	-- Retain the approved imported-stud rollout and its legacy fallback.
	require(script.Parent.Kit.WorldStuds).apply()
end

return World
