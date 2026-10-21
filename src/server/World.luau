--!strict
-- Bright scrapyard backdrop: sandy apron, grassy stepped cliffs and sparse
-- shipping-container yards. The lower apron retains the old rescue surface.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local YardProps = require(script.Parent.Kit.YardProps)

local World = {}
local C = Color3.fromRGB
local V = Vector3.new
local GRASS = C(109, 186, 79)
local SAND = C(190, 173, 143)
local GROUND_Y = Config.World.SeaY - 3
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local function sandyFloor(parent: Instance)
	local floor = Build.block(parent, "YardFloor", V(2048, 1, 2048), CFrame.new(0, Config.World.SeaY - 0.5, 0), SAND, {})
	floor.Material = Enum.Material.Sand
	floor.CanCollide = true
	floor.CanQuery = false
	floor.CanTouch = false
	floor.CastShadow = false
	-- Sparse matte patches beyond the islands; no animated textures or glow.
	local rng = Random.new(91)
	for i = 1, 24 do
		local side = if i % 2 == 0 then 1 else -1
		local p = Build.block(parent, "SandPatch", V(rng:NextNumber(20, 48), 0.04, rng:NextNumber(12, 26)),
			CFrame.new(rng:NextNumber(-365, 365), Config.World.SeaY + 0.02, side * rng:NextNumber(235, 320))
				* CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0),
			if i % 3 == 0 then C(183, 168, 140) else C(198, 181, 151), {})
		p.Material = Enum.Material.Sand
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
	end
end

local function cliff(parent: Instance, cf: CFrame, width: number, rng: Random, theme: { [string]: Color3 }, grove: boolean)
	local m = Instance.new("Model")
	m.Name = "GrassyCliff"
	local depth = rng:NextNumber(36, 58)
	local tiers = rng:NextInteger(2, 4)
	local y, back = 0, 0
	local topWidth, topDepth = width, depth
	for tier = 1, tiers do
		local h = if tier == 1 then rng:NextNumber(22, 32) else rng:NextNumber(10, 19)
		local w = width - (tier - 1) * 4
		local d = depth - back
		local x = if tier == 1 then 0 else rng:NextNumber(-2, 2)
		Build.block(m, "Cliff", V(w, h, d), cf * CFrame.new(x, y + h / 2, back + d / 2),
			if tier % 2 == 0 then theme.cliffDark else theme.cliff, ALL)
		Build.block(m, "GrassCap", V(w + 0.8, 1.2, d + 0.8), cf * CFrame.new(x, y + h + 0.3, back + d / 2), GRASS)
		Build.block(m, "GrassLip", V(rng:NextNumber(4, 8), 2, 0.5),
			cf * CFrame.new(rng:NextNumber(-w / 3, w / 3), y + h - 0.7, back - 0.25), GRASS, {})
		y += h
		topWidth, topDepth = w, d
		if tier < tiers then back += rng:NextNumber(5, 8) end
	end
	if grove then
		for i = 1, rng:NextInteger(2, 3) do
			local x = (i - 2) * math.min(9, topWidth / 4) + rng:NextNumber(-1, 1)
			Build.tree(m, cf * CFrame.new(x, y + 0.9, back + topDepth / 2), rng:NextNumber(0.9, 1.5), theme, rng)
		end
	end
	m.Parent = parent
end

local function skyline(parent: Instance, theme: { [string]: Color3 })
	local rng = Random.new(218)
	local colors = { C(47, 111, 201), C(49, 161, 154), C(212, 83, 75) }
	-- Outside all plot/shop tabs, with generous gaps between stations.
	local stations = {
		V(-255, 0, -270), V(-75, 0, -290), V(185, 0, -272),
		V(-225, 0, 274), V(70, 0, 290), V(258, 0, 268),
		V(-345, 0, 110), V(345, 0, -110),
	}
	for i, pos in stations do
		local cf = CFrame.new(pos.X, Config.World.SeaY, pos.Z) * CFrame.Angles(0, if i % 2 == 0 then 0.22 else -0.3, 0)
		YardProps.container(parent, cf, colors[(i - 1) % 3 + 1])
		if i % 3 == 1 then
			YardProps.container(parent, cf * CFrame.new(2, 10, 0) * CFrame.Angles(0, 0.08, 0), colors[i % 3 + 1])
		end
		YardProps.bales(parent, cf * CFrame.new(20, 0, 2), 1.5)
		YardProps.vehicle(parent, cf * CFrame.new(-19, 0, -3) * CFrame.Angles(0, 0.4, 0), colors[i % 3 + 1])
		for k = 1, 2 do
			local rock = Build.rock(parent, cf * CFrame.new(-16 + k * 12, 0, 13 + k * 2), rng:NextNumber(1, 1.5), theme, rng)
			for _, p in rock:GetDescendants() do
				if p:IsA("BasePart") then
					p.CanCollide = false
					p.CanTouch = false
					p.CanQuery = false
				end
			end
		end
		task.wait()
	end
	YardProps.crane(parent, CFrame.new(-325, Config.World.SeaY, -225) * CFrame.Angles(0, -0.3, 0))
	YardProps.crane(parent, CFrame.new(325, Config.World.SeaY, 225) * CFrame.Angles(0, math.pi - 0.3, 0))
end

function World.create()
	local theme = Style.theme(Config.Look.Theme)
	local rng = Random.new(Config.Look.PropSeed or 7)
	local folder = Instance.new("Model")
	folder.Name = "World"
	folder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	-- Parent while empty, then insert small batches to keep Studio responsive.
	folder.Parent = Workspace
	sandyFloor(folder)
	local X, Z = 400, 340
	local sides = {
		{ from = V(-X, 0, -Z), dir = V(1, 0, 0), len = 2 * X, facing = 0 },
		{ from = V(X, 0, Z), dir = V(-1, 0, 0), len = 2 * X, facing = math.pi },
		{ from = V(-X, 0, Z), dir = V(0, 0, -1), len = 2 * Z, facing = math.pi / 2 },
		{ from = V(X, 0, -Z), dir = V(0, 0, 1), len = 2 * Z, facing = -math.pi / 2 },
	}
	local count = 0
	for _, side in sides do
		local d = 0
		while d < side.len do
			local w = rng:NextNumber(38, 55)
			local pos = side.from + side.dir * (d + w / 2) + V(0, GROUND_Y, 0)
			local cf = CFrame.new(pos) * CFrame.Angles(0, side.facing + math.pi, 0)
			count += 1
			-- Overlapping base blocks preserve enclosure; upper ledges vary.
			cliff(folder, cf, w + 6, rng, theme, count % 3 == 0)
			d += w
			if count % 4 == 0 then task.wait() end
		end
	end
	skyline(folder, theme)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 590, GROUND_Y, math.sin(a) * 590) * CFrame.Angles(0, -a, 0)
		local h = rng:NextNumber(65, 110)
		for tier = 1, 3 do
			local w, d = 180 - tier * 28, 120 - tier * 18
			local top = h * tier / 3
			Build.block(folder, "DistantHill", V(w, h / 3, d), cf * CFrame.new(0, top - h / 6, 0), theme.cliff)
			Build.block(folder, "HillCap", V(w + 2, 2, d + 2), cf * CFrame.new(0, top, 0), GRASS:Lerp(C(170, 195, 139), 0.35))
		end
	end
end

return World
