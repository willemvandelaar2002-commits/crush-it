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
-- 27 Oct: a HEXAGONAL hall, so all six plots get the same room around them.
-- The six walls stand between the plots (wall i faces angle (i-1)*60; plots sit
-- at 30 + k*60), so every plot's back points into a corner with the same gap.
-- REAR = the deepest plot part (rear yard, plot-local -Z); plot back corners must
-- stay CLEARANCE studs from the walls. Never derive train positions here.
local REAR = 116
local CLEARANCE = 70
local BACK_RADIUS = Config.Plots.Ring + Config.Plots.Front + REAR
local PLOT_ENVELOPE = math.sqrt(BACK_RADIUS ^ 2 + (Config.Plots.FloorSize / 2) ^ 2)
-- distance from a plot back corner to the nearest wall line = APOTHEM - (r*cos30 + w/2*sin30)
local APOTHEM = math.ceil((BACK_RADIUS * math.cos(math.rad(30)) + Config.Plots.FloorSize / 4 + CLEARANCE) / 10) * 10
local WALL_LENGTH = 2 * APOTHEM * math.tan(math.rad(30))
local HALF = math.ceil(APOTHEM / math.cos(math.rad(30))) -- corner radius: the roof covers this square
local HEIGHT = 150
local WALLS = 6

-- Frame on wall `index` (1..6): origin on the wall's inner line at FLOOR_Y, local
-- -Z points to the centre, X runs along the wall.
local function wallFrame(index: number): CFrame
	local a = (index - 1) * math.rad(360 / WALLS)
	return CFrame.new(math.sin(a) * APOTHEM, FLOOR_Y, math.cos(a) * APOTHEM) * CFrame.Angles(0, a, 0)
end

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
	-- Large, subtle floor panels give the factory scale without tiny litter:
	-- a service lane along every wall (short of the corners behind the plots).
	for i = 1, WALLS do
		local f = wallFrame(i) * CFrame.new(0, 0, -40)
		local length = WALL_LENGTH - 180
		local lane = part(parent, "PerimeterServiceLane", V(length, 0.05, 46), f * CFrame.new(0, 0.03, 0), P.Navy)
		lane.CastShadow = false
		for _, side in { -1, 1 } do
			part(parent, "LanePaint", V(length, 0.06, 0.8), f * CFrame.new(0, 0.06, side * 22), P.Yellow).CastShadow = false
		end
	end
end

local function wall(parent: Instance, cf: CFrame, index: number)
	local m = group(parent, "FactoryWall" .. index)
	local width = WALL_LENGTH / 8
	for i = 0, 7 do
		local x = -WALL_LENGTH / 2 + width * (i + 0.5)
		local bay = cf * CFrame.new(x, 0, 0)
		local panel = part(m, "BoundaryWall", V(width + 0.2, 52, 4), bay * CFrame.new(0, 26, 0), P.Cream)
		panel.CanCollide = true
		part(m, "BlueWainscot", V(width + 0.2, 19, 1), bay * CFrame.new(0, 9.5, -2.6), P.Blue)
		part(m, "WallStripe", V(width + 0.2, 2, 1.2), bay * CFrame.new(0, 20, -2.8), P.Teal)
		part(m, "WindowSill", V(width, 6, 13), bay * CFrame.new(0, 53, -3), P.Yellow)
		local window = part(m, "Window", V(width - 7, 66, 0.6), bay * CFrame.new(0, 88, 0), P.Glass)
		window.Transparency = 0.72
		window.CastShadow = false
		window.CanCollide = true
		for _, dx in { -width / 2 + 3, 0, width / 2 - 3 } do
			part(m, "WindowMullion", V(1.7, 67, 2), bay * CFrame.new(dx, 88, -0.8), P.Blue)
		end
		part(m, "WindowMullion", V(width - 4, 1.7, 2), bay * CFrame.new(0, 86, -0.8), P.Blue)
		part(m, "UpperWall", V(width + 0.2, 28, 4), bay * CFrame.new(0, 136, 0), P.Cream)
		part(m, "HighYellowBand", V(width + 0.2, 10, 9), bay * CFrame.new(0, 124, -4), P.Yellow)
	end
	for i = 0, 8 do
		local x = -WALL_LENGTH / 2 + i * width
		-- the middle column of wall 1 stood right behind the CRUSH IT sign: leave it out
		if index == 1 and i == 4 then continue end
		part(m, "RedColumn", V(14, HEIGHT, 16), cf * CFrame.new(x, HEIGHT / 2, -5), P.Red)
		part(m, "ColumnBoot", V(22, 18, 24), cf * CFrame.new(x, 9, -5), P.Navy)
		part(m, "ColumnJoint", V(20, 14, 22), cf * CFrame.new(x, HEIGHT - 14, -5), P.Yellow)
		for _, dx in { -5, 5 } do
			part(m, "JointBolt", V(2.3, 2.3, 1.5), cf * CFrame.new(x + dx, HEIGHT - 14, -17), P.Navy)
		end
		FactoryProps.beam(m, "RoofKnee", (cf * CFrame.new(x, HEIGHT - 27, -4)).Position,
			(cf * CFrame.new(x, HEIGHT - 5, -33)).Position, 8, P.Red)
	end
end

local function roof(parent: Instance)
	local m = group(parent, "SkylightRoof")
	local y = FLOOR_Y + HEIGHT
	local bayWidth = HALF / 2
	-- Twelve open bays occupy ~47% of the hall's roof plan. Four broad opaque
	-- infills, including two above the centre, make the solid ceiling readable.
	for i = 0, 4 do
		local x = -HALF + i * bayWidth
		local rib = part(m, "CeilingPanel", V(40, 5, HALF * 2 + 40), CFrame.new(x, y + 2, 0), P.Cream)
		rib.CastShadow = false
		local cross = part(m, "CeilingPanel", V(HALF * 2 + 40, 5, 50), CFrame.new(0, y + 2, x), P.Cream)
		cross.CastShadow = false
	end
	for ix = 0, 3 do
		for iz = 0, 3 do
			local x, z = -HALF + (ix + 0.5) * bayWidth, -HALF + (iz + 0.5) * bayWidth
			local w, d = bayWidth - 40, bayWidth - 50
			if ix == iz then
				part(m, "CeilingInfill", V(w, 5, d), CFrame.new(x, y + 2, z), P.Cream).CastShadow = false
			else
				local glass = part(m, "Skylight", V(w, 0.6, d), CFrame.new(x, y + 2, z), P.Glass)
				glass.Transparency = 0.65
				glass.CastShadow = false
			end
			for _, side in { -1, 1 } do
				part(m, "SkylightFrame", V(w + 6, 5, 5), CFrame.new(x, y - 0.5, z + side * d / 2), P.White).CastShadow = false
				part(m, "SkylightFrame", V(5, 5, d), CFrame.new(x + side * w / 2, y - 0.5, z), P.White).CastShadow = false
				part(m, "SkylightMullion", V(3, 3, d), CFrame.new(x + side * w / 6, y, z), P.White).CastShadow = false
			end
		end
		task.wait()
	end
	for i = 0, 4 do
		local z = -HALF + i * bayWidth
		part(m, "RoofBeam", V(HALF * 2, 12, 14), CFrame.new(0, y - 5, z), P.Red)
		part(m, "YellowCrossbeam", V(14, 9, HALF * 2), CFrame.new(z, y - 5, 0), P.Yellow)
		for _, x in { -HALF * 0.55, HALF * 0.55 } do
			part(m, "RoofJoint", V(23, 17, 23), CFrame.new(x, y - 5, z), P.Red)
			part(m, "LampCable", V(1.2, 13, 1.2), CFrame.new(x, y - 15, z), P.Navy)
			FactoryProps.workLight(m, CFrame.new(x, y - 23, z), 1.7, i == 1 or i == 3)
		end
	end
	-- High directional casters made long, dark bars across the apron. Keep
	-- the structure visible while retaining toy/shelf/crate contact shadows.
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.CastShadow = false end
	end
end

local function loadingBay(parent: Instance, cf: CFrame, text: string)
	local m = group(parent, "LoadingBay")
	part(m, "DoorFrame", V(70, 48, 7), cf * CFrame.new(0, 24, 0), P.Blue)
	part(m, "Shutter", V(53, 36, 1.2), cf * CFrame.new(0, 19, -2), P.Navy)
	for y = 3, 36, 3 do
		part(m, "ShutterSlat", V(52, 0.45, 0.5), cf * CFrame.new(0, y, -2.8), P.Blue)
	end
	for _, x in { -28.5, 28.5 } do
		part(m, "SafetyPost", V(5, 25, 5), cf * CFrame.new(x, 12.5, -5), P.Yellow)
		for y = 3, 23, 5 do
			part(m, "SafetyStripe", V(5.8, 2.4, 0.4), cf * CFrame.new(x, y, -7.7) * CFrame.Angles(0, 0, -0.35), P.Dark)
		end
	end
	part(m, "DoorHeader", V(72, 8, 12), cf * CFrame.new(0, 44, -4), P.Blue)
	FactoryProps.sign(m, cf * CFrame.new(0, 54, -5), 62, 9, text, P.Blue)
	FactoryProps.workLight(m, cf * CFrame.new(0, 40, -11), 0.9, true)
end

local function displays(parent: Instance)
	-- One centrepiece per wall, all near the wall's middle: that is the open
	-- space between two plots (the corners are behind the plots).
	local m = group(parent, "ToyDisplays")
	local function on(wall: number, t: number, inset: number): CFrame
		return wallFrame(wall) * CFrame.new(t, 0, -inset)
	end
	-- 1 (+Z, the CRUSH IT side): gantry crane, two loading bays, brand sign
	FactoryProps.crane(m, on(1, 0, 27))
	loadingBay(m, on(1, -63, 4), "TOY STORAGE")
	loadingBay(m, on(1, 63, 4), "DISPATCH")
	FactoryProps.brandSign(m, on(1, 0, 9) * CFrame.new(0, 124, 0))
	-- 2: block shelf
	FactoryProps.shelf(m, on(2, 0, 41), 1, "Blocks")
	task.wait()
	-- 3: the bear mascot on its crate
	local bearCf = on(3, 0, 62)
	FactoryProps.crate(m, bearCf, 52, P.Red, false)
	part(m, "MascotPlinth", V(55, 3, 55), bearCf * CFrame.new(0, 38, 0), P.Yellow)
	FactoryProps.bear(m, bearCf * CFrame.new(0, 39.5, 0), 4)
	FactoryProps.sign(m, bearCf * CFrame.new(0, 18, -27.5), 43, 18, "TOY TIME", P.Red)
	task.wait()
	-- 4 (-Z): supply belt and the packing booth
	FactoryProps.conveyor(m, on(4, 0, 24), 300)
	FactoryProps.packingBooth(m, on(4, 0, 58))
	task.wait()
	-- 5: the duck mascot on its crate
	local duckCf = on(5, 0, 60)
	FactoryProps.crate(m, duckCf, 48, P.Blue, false)
	part(m, "MascotPlinth", V(51, 3, 51), duckCf * CFrame.new(0, 35, 0), P.Yellow)
	FactoryProps.duck(m, duckCf * CFrame.new(0, 36.5, 0), 8)
	task.wait()
	-- 6: car shelf under the big TOY FACTORY sign
	FactoryProps.shelf(m, on(6, 0, 41), 2, "Cars")
	FactoryProps.sign(m, on(6, 0, 7) * CFrame.new(0, 125, 0), 150, 17, "TOY FACTORY", P.Teal)
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
	root:SetAttribute("HallApothem", APOTHEM)
	root:SetAttribute("PlotEnvelope", PLOT_ENVELOPE)
	root.Parent = Workspace
	floor(root)
	for i = 1, WALLS do
		wall(root, wallFrame(i), i)
		task.wait()
	end
	roof(root)
	displays(root)
	toyBays(root)
	FactoryProps.floorFinish(root.YardFloor :: BasePart, { Enum.NormalId.Top })
	local plots = Workspace:FindFirstChild("Plots")
	local hub = plots and plots:FindFirstChild("Hub")
	local commons = hub and hub:FindFirstChild("WorkshopCommons")
	local commonsFloor = commons and commons:FindFirstChild("CommonsFloor")
	if commonsFloor and commonsFloor:IsA("BasePart") then
		FactoryProps.floorFinish(commonsFloor, { Enum.NormalId.Right })
	end
end

return World
