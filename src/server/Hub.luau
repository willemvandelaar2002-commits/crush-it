--!strict
-- The Toy Train Loop (Config.Loop): a round station hub in the middle with the
-- scrap display, the entrance landmark and workshop props; 4 walkways (at 0, 90,
-- 180 and 270 degrees) out to a ring road with rails and a toy train going round
-- (built here, driven by client/Train.client.luau); the plots stand round the
-- outside, their bridges landing on the loop (Plots.originFor, Moat.build).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local YardProps = require(script.Parent.Kit.YardProps)

local Hub = {}

local C = Color3.fromRGB
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local FLOOR_Y = 1.6
local SEGMENTS = 48
local SPOKES = { 0, 90, 180, 270 } -- walkway directions (degrees; plots sit at 22.5 + 45 k)

local function at(angle: number, r: number, y: number): CFrame
	-- a point on the ground at `angle` (radians, 0 = +Z) and radius r, local -Z pointing at the centre
	return CFrame.new(math.sin(angle) * r, y, math.cos(angle) * r) * CFrame.Angles(0, angle, 0)
end

local function nearAngle(angle: number, list: { number }, within: number): boolean
	for _, d in list do
		local diff = math.abs((math.deg(angle) - d + 180) % 360 - 180)
		if diff < within then
			return true
		end
	end
	return false
end

local function cylinder(parent: Instance, name: string, height: number, diameter: number, centre: Vector3, color: Color3, material: Enum.Material?): Part
	-- a cylinder standing upright (its flat ends are the part's Left/Right faces)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(centre) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function scenery(m: Instance)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
end

-- Round station hub.
local function station(m: Model, pal: { [string]: Color3 }, rng: Random)
	local L = Config.Loop
	local seaY = Config.World.SeaY
	local h = 1.55
	local top = cylinder(m, "HubFloor", h, L.Hub * 2, Vector3.new(0, FLOOR_Y - h / 2, 0), pal.grass or pal.platform)
	Style.studs(top, { Enum.NormalId.Right })
	cylinder(m, "HubRim", h + 0.35, L.Hub * 2 + 3, Vector3.new(0, FLOOR_Y - (h + 0.35) / 2 - 0.05, 0), pal.grassEdge or pal.edge)
	cylinder(m, "HubDirt", 3, L.Hub * 2 + 3.8, Vector3.new(0, FLOOR_Y - 0.4 - 1.5 - 1.6, 0), pal.dirt or C(138, 96, 60))
	local stoneTop = FLOOR_Y - 0.4 - 3 - 1.6
	cylinder(m, "HubStone", stoneTop - (seaY - 6), L.Hub * 2 + 5, Vector3.new(0, (stoneTop + seaY - 6) / 2, 0), pal.stone or C(132, 130, 140))
	-- curb round the edge, open at the walkways
	for i = 0, 35 do
		local a = (i + 0.5) / 36 * math.pi * 2
		if not nearAngle(a, SPOKES, 9) then
			local bh = rng:NextNumber(1.3, 2.2)
			Build.block(m, "Curb", Vector3.new(L.Hub * 2 * math.pi / 36 + 0.4, bh, 1.8), at(a, L.Hub - 1, FLOOR_Y + bh / 2),
				if rng:NextNumber() < 0.3 then (pal.stoneDark or C(102, 100, 110)) else (pal.stone or C(132, 130, 140)), ALL)
		end
	end
	-- roads across the hub to the 4 walkways
	Build.path(m, Vector3.new(-L.Hub + 2, FLOOR_Y, 0), Vector3.new(L.Hub - 2, FLOOR_Y, 0), 12)
	Build.path(m, Vector3.new(0, FLOOR_Y, -L.Hub + 2), Vector3.new(0, FLOOR_Y, L.Hub - 2), 12)
	-- scrap display in the middle (Willem's world pass)
	local basin = CFrame.new(0, FLOOR_Y, 0)
	Build.block(m, "DisplayPlinth", Vector3.new(18, 2, 18), basin * CFrame.new(0, 1, 0), pal.edge, ALL)
	Build.block(m, "DisplayInset", Vector3.new(15, 0.3, 15), basin * CFrame.new(0, 2.05, 0), pal.platform, {})
	Build.block(m, "DisplayTrim", Vector3.new(15.2, 0.2, 15.2), basin * CFrame.new(0, 1.95, 0), pal.edge, {})
	Build.block(m, "DisplayPillar", Vector3.new(4, 7, 4), basin * CFrame.new(0, 5.5, 0), pal.edge, ALL)
	Build.block(m, "DisplayTop", Vector3.new(6, 1.2, 6), basin * CFrame.new(0, 9.6, 0), C(47, 111, 201), {})
	YardProps.bales(m, basin * CFrame.new(0, 10.2, 0), 0.8)
	YardProps.entrance(m, CFrame.new(-30, FLOOR_Y, 0) * CFrame.Angles(0, -math.pi / 2, 0))
	-- workshop props in the four quarters between the roads
	for k, deg in { 45, 135, 225, 315 } do
		local a = math.rad(deg)
		if k % 2 == 1 then
			YardProps.cluster(m, at(a, 36, FLOOR_Y), k, 1.3)
		else
			local tree = Build.tree(m, at(a, 36, FLOOR_Y), 0.85, pal, rng)
			scenery(tree)
		end
		YardProps.workLight(m, at(a + math.rad(20), 46, FLOOR_Y), k % 2 == 0)
	end
	-- spawn on the hub (players are moved to their plot once it's assigned)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(0, FLOOR_Y + 0.1, 14)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Neutral = true
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = m
end

-- The ring road with its rails, built from SEGMENTS straight pieces.
local function loop(m: Model, pal: { [string]: Color3 }, rng: Random)
	local L = Config.Loop
	local seaY = Config.World.SeaY
	local width = L.Outer - L.Inner
	local mid = (L.Inner + L.Outer) / 2
	local step = math.pi * 2 / SEGMENTS
	local seg = 2 * L.Outer * math.tan(step / 2) + 0.2 -- covers the outer edge; overlaps on the inside
	local plotAngles = {}
	for i = 1, Config.Plots.Count do
		table.insert(plotAngles, 22.5 + (i - 1) * 45)
	end
	local road = C(124, 135, 152)
	local rail = C(168, 174, 186)
	local sleeper = C(140, 96, 62)
	for i = 0, SEGMENTS - 1 do
		local a = (i + 0.5) * step
		local h = 1.55
		local piece = Build.block(m, "Road", Vector3.new(seg, h, width), at(a, mid, FLOOR_Y - h / 2), road)
		local _ = piece
		Build.block(m, "Dirt", Vector3.new(seg, 3, width + 0.8), at(a, mid, FLOOR_Y - 0.4 - 1.5), pal.dirt or C(138, 96, 60), ALL)
		local stoneTop = FLOOR_Y - 3.4
		Build.block(m, "Stone", Vector3.new(seg, stoneTop - (seaY - 6), width + 2), at(a, mid, (stoneTop + seaY - 6) / 2), pal.stone or C(132, 130, 140), ALL)
		-- edges: painted kerb lines, and low curbs except where walkways and plot bridges join
		for _, r in { L.Inner + 0.6, L.Outer - 0.6 } do
			Build.block(m, "EdgeLine", Vector3.new(seg * r / L.Outer, 0.12, 0.6), at(a, r, FLOOR_Y + 0.06), C(245, 245, 245), {})
		end
		if not nearAngle(a, SPOKES, 5) then
			Build.block(m, "Curb", Vector3.new(seg * L.Inner / L.Outer, rng:NextNumber(1.2, 1.8), 1.4), at(a, L.Inner - 0.2, FLOOR_Y + 0.7), pal.stone or C(132, 130, 140), ALL)
		end
		if not nearAngle(a, plotAngles, 5) then
			Build.block(m, "Curb", Vector3.new(seg, rng:NextNumber(1.2, 1.8), 1.4), at(a, L.Outer + 0.2, FLOOR_Y + 0.7), pal.stone or C(132, 130, 140), ALL)
		end
		-- rails and sleepers
		for _, r in { L.TrainRadius - 3, L.TrainRadius + 3 } do
			local railPart = Build.block(m, "Rail", Vector3.new(2 * r * math.tan(step / 2) + 0.1, 0.35, 0.5), at(a, r, FLOOR_Y + 0.33), rail, {})
			railPart.Material = Enum.Material.Metal
		end
		for _, off in { -0.25, 0.25 } do
			Build.block(m, "Sleeper", Vector3.new(1.2, 0.16, 8.4), at(a + off * step, L.TrainRadius, FLOOR_Y + 0.08), sleeper, {})
		end
	end
end

-- Toy train: an engine and four wagons with toys. Built facing -Z round a pivot
-- on the floor; the client moves every car along the rails each frame.
local function train(parent: Instance)
	local L = Config.Loop
	local m = Instance.new("Model")
	m.Name = "ToyTrain"
	m:SetAttribute("Radius", L.TrainRadius)
	m:SetAttribute("Lap", L.TrainLap)
	m:SetAttribute("FloorY", FLOOR_Y)
	local RED, YELLOW, BLUE, DARK = C(232, 86, 74), C(244, 190, 46), C(62, 143, 230), C(40, 44, 56)
	local base = CFrame.new(0, FLOOR_Y + 0.35, 0)
	local function wheels(car: Model, zs: { number }, color: Color3)
		for _, z in zs do
			for _, x in { -2.9, 2.9 } do
				local w = Instance.new("Part")
				w.Name = "Wheel"
				w.Shape = Enum.PartType.Cylinder
				w.Size = Vector3.new(0.7, 2.4, 2.4)
				w.CFrame = base * CFrame.new(x, 1.2, z)
				w.Color = color
				w.Material = Enum.Material.SmoothPlastic
				w.Anchored = true
				w.Parent = car
			end
		end
	end
	local function upright(car: Model, name: string, h: number, d: number, pos: Vector3, color: Color3): Part
		return cylinder(car, name, h, d, (base * CFrame.new(pos)).Position, color)
	end

	-- engine (12 long)
	local engine = Instance.new("Model")
	engine.Name = "Engine"
	engine:SetAttribute("Offset", 0)
	Build.block(engine, "Chassis", Vector3.new(5.6, 1.2, 12), base * CFrame.new(0, 1.9, 0), DARK, ALL)
	wheels(engine, { -4, 0, 4 }, RED)
	local boiler = Instance.new("Part")
	boiler.Name = "Boiler"
	boiler.Shape = Enum.PartType.Cylinder
	boiler.Size = Vector3.new(7.5, 4.4, 4.4)
	boiler.CFrame = base * CFrame.new(0, 4.6, -2) * CFrame.Angles(0, math.rad(90), 0)
	boiler.Color = RED
	boiler.Anchored = true
	boiler.Parent = engine
	for _, z in { -4.6, -0.4 } do
		local band = boiler:Clone()
		band.Name = "Band"
		band.Size = Vector3.new(0.5, 4.6, 4.6)
		band.CFrame = base * CFrame.new(0, 4.6, z) * CFrame.Angles(0, math.rad(90), 0)
		band.Color = YELLOW
		band.Parent = engine
	end
	upright(engine, "Stack", 3, 1.5, Vector3.new(0, 8, -4.4), DARK)
	local stackTop = upright(engine, "StackTop", 0.7, 2.3, Vector3.new(0, 9.7, -4.4), DARK)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 8
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Speed = NumberRange.new(4, 6)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3.5) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(C(245, 245, 250))
	smoke.EmissionDirection = Enum.NormalId.Right -- the cylinder's X axis points up
	smoke.Parent = stackTop
	Build.block(engine, "Cab", Vector3.new(5.4, 4.8, 4.2), base * CFrame.new(0, 4.9, 3.6), BLUE, ALL)
	Build.block(engine, "CabRoof", Vector3.new(6.2, 0.6, 5), base * CFrame.new(0, 7.6, 3.6), YELLOW, ALL)
	for _, x in { -2.75, 2.75 } do
		Build.block(engine, "CabWindow", Vector3.new(0.2, 1.8, 2.4), base * CFrame.new(x, 5.8, 3.6), C(170, 220, 255), {})
	end
	local lamp = Build.block(engine, "Headlight", Vector3.new(1.4, 1.4, 0.4), base * CFrame.new(0, 4.6, -5.95), C(255, 236, 140), {})
	lamp.Material = Enum.Material.Neon
	local catcher = Instance.new("WedgePart")
	catcher.Name = "Cowcatcher"
	catcher.Size = Vector3.new(5.6, 1.6, 1.8)
	catcher.CFrame = base * CFrame.new(0, 1.1, -6.8)
	catcher.Color = YELLOW
	catcher.Anchored = true
	catcher.Parent = engine
	engine.WorldPivot = base * CFrame.new(0, -0.35, 0)
	engine.Parent = m

	-- wagons (9 long) with toys
	local wagonColors = { YELLOW, BLUE, C(77, 184, 106), C(142, 91, 216) }
	local toyColors = { RED, YELLOW, BLUE, C(77, 184, 106), C(255, 150, 50), C(142, 91, 216) }
	for k = 1, 4 do
		local car = Instance.new("Model")
		car.Name = "Wagon" .. k
		car:SetAttribute("Offset", 12 + (k - 1) * 10.5)
		local col = wagonColors[k]
		Build.block(car, "Chassis", Vector3.new(5.4, 1, 9), base * CFrame.new(0, 1.8, 0), DARK, ALL)
		wheels(car, { -2.8, 2.8 }, RED)
		Build.block(car, "Floor", Vector3.new(5.2, 0.5, 8.6), base * CFrame.new(0, 2.55, 0), col, {})
		for _, x in { -2.45, 2.45 } do
			Build.block(car, "Side", Vector3.new(0.3, 1.8, 8.6), base * CFrame.new(x, 3.6, 0), col, ALL)
		end
		for _, z in { -4.15, 4.15 } do
			Build.block(car, "End", Vector3.new(5.2, 1.8, 0.3), base * CFrame.new(0, 3.6, z), col, ALL)
		end
		-- toys: two cubes and a ball
		Build.block(car, "ToyCube", Vector3.new(2, 2, 2), base * CFrame.new(-1, 3.8, -2) * CFrame.Angles(0, 0.4, 0), toyColors[(k % #toyColors) + 1], ALL)
		Build.block(car, "ToyCube", Vector3.new(1.6, 1.6, 1.6), base * CFrame.new(1, 3.6, 1.2) * CFrame.Angles(0, -0.3, 0.2), toyColors[((k + 2) % #toyColors) + 1], ALL)
		local ball = Instance.new("Part")
		ball.Name = "ToyBall"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(2.2, 2.2, 2.2)
		ball.CFrame = base * CFrame.new(-0.6, 3.9, 2.4)
		ball.Color = toyColors[((k + 4) % #toyColors) + 1]
		ball.Anchored = true
		ball.Parent = car
		car.WorldPivot = base * CFrame.new(0, -0.35, 0)
		car.Parent = m
	end
	scenery(m)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end
	end
	-- start on the rails (the client takes over from here)
	for _, car in m:GetChildren() do
		if car:IsA("Model") then
			local r = L.TrainRadius
			local a = -((car:GetAttribute("Offset") :: number?) or 0) / r
			local pos = Vector3.new(math.sin(a) * r, FLOOR_Y, math.cos(a) * r)
			car:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), 0, -math.sin(a))))
		end
	end
	CollectionService:AddTag(m, "ToyTrain")
	m.Parent = parent
end

function Hub.create(parent: Instance)
	local pal = Style.theme(Config.Look.Theme)
	local L = Config.Loop
	local rng = Random.new(77)
	local m = Instance.new("Model")
	m.Name = "Hub"
	station(m, pal, rng)
	loop(m, pal, rng)
	-- walkways from the hub to the loop
	for _, deg in SPOKES do
		local a = math.rad(deg)
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		Build.bridge(m, Vector3.new(0, FLOOR_Y, 0) + dir * (L.Hub - 1.5), Vector3.new(0, FLOOR_Y, 0) + dir * (L.Inner + 1.5), 12, pal, Config.World.SeaY)
	end
	train(m)
	m.Parent = parent
end

return Hub
