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
local GRASS = C(90, 182, 51)
local SAND = C(196, 147, 66)
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
			CFrame.new(rng:NextNumber(-400, 400), Config.World.SeaY + 0.02, side * rng:NextNumber(20, 400))
				* CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0),
			if i % 3 == 0 then C(183, 133, 57) else C(207, 158, 76), {})
		p.Material = Enum.Material.Sand
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
	end
end

local function scenery(m: Model): Model
	m:SetAttribute("EnvironmentProp", true)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	return m
end

local function grove(parent: Instance, cf: CFrame, theme: { [string]: Color3 }, rng: Random, scale: number)
	for i = 1, 3 do
		scenery(Build.tree(parent, cf * CFrame.new((i - 2) * 10 * scale, 0, if i == 2 then 6 else 0),
			scale * rng:NextNumber(0.95, 1.3), theme, rng))
	end
	scenery(Build.bush(parent, cf * CFrame.new(6 * scale, 0, -5 * scale), scale * 1.6, theme, rng))
end

local function cliff(parent: Instance, cf: CFrame, width: number, rng: Random, theme: { [string]: Color3 }, index: number)
	local m = Instance.new("Model")
	m.Name = "GrassyCliff"
	local depth = rng:NextNumber(80, 110)
	-- Repeated low saddles separate broad high groups; the solid base overlaps
	-- neighbouring modules even at the lowest opening, preserving the boundary.
	local profile = { 2, 2, 3, 4, 4, 3, 2 }
	local tiers = profile[(index - 1) % #profile + 1]
	local y, back = 0, 0
	local topDepth = depth
	for tier = 1, tiers do
		local h = if tier == 1 then rng:NextNumber(16, 24) else rng:NextNumber(12, 21)
		local w = width - (tier - 1) * 5
		local d = depth - back
		local x = if tier == 1 then 0 else rng:NextNumber(-4, 4)
		Build.block(m, "Cliff", V(w, h, d), cf * CFrame.new(x, y + h / 2, back + d / 2),
			if tier % 2 == 0 then theme.cliffDark else theme.cliff, ALL)
		Build.block(m, "GrassCap", V(w + 1.4, 3.5, d + 1.4), cf * CFrame.new(x, y + h + 0.5, back + d / 2), GRASS)
		if tier == 1 and index % 4 == 0 then
			grove(m, cf * CFrame.new(0, y + h + 2.25, back + 11), theme, rng, 1.25)
		elseif tier == 2 and index % 5 == 0 then
			scenery(Build.rock(m, cf * CFrame.new(0, y + h + 2.25, back + 9), 2.8, theme, rng))
		end
		y += h
		topDepth = d
		if tier < tiers then back += rng:NextNumber(15, 22) end
	end
	if index % 3 == 0 then
		grove(m, cf * CFrame.new(0, y + 2.25, back + topDepth / 2), theme, rng, 1.5)
	end
	m.Parent = parent
end

local function skyline(parent: Instance)
	-- The south-west corner established the scale. Rotate the same builder
	-- around the apron, alternating crane landmarks and lower storage groups.
	-- Since the Toy Train Loop (21 Oct) the plots stand round a ring at 22.5 + 45 k
	-- degrees; the scenes sit in the sand wedges between them, facing the centre.
	local function facingCentre(deg: number, r: number): CFrame
		local a = math.rad(deg)
		return CFrame.new(math.sin(a) * r, Config.World.SeaY, math.cos(a) * r) * CFrame.Angles(0, a, 0)
	end
	local stations = {
		{ deg = 0, variant = 0, crane = true },
		{ deg = 90, variant = 1, crane = false },
		{ deg = 180, variant = 2, crane = true },
		{ deg = 270, variant = 1, crane = false },
		{ deg = 45, variant = 2, crane = false },
		{ deg = 225, variant = 0, crane = false },
	}
	for _, station in stations do
		-- Broad framed storage aprons anchor the scenery groups in the sand.
		-- They remain noncolliding scenery below the playable island level.
		local apron = Build.platform(parent, "StorageApron", facingCentre(station.deg, 345) * CFrame.new(0, 0.08, 0),
			110, 94, 0.5, C(83, 104, 115), C(42, 57, 76), 1.5)
		scenery(apron)
		YardProps.yardScene(parent, facingCentre(station.deg, 330), station.variant, station.crane)
		task.wait()
	end
	-- The striped workshop is now part of the walkable commons in Hub.
end

function World.create()
	-- Environment mood is selected here; Config and other preset users stay intact.
	Build.lighting(if Config.Look.Sky == "Day" then "YardDay" else Config.Look.Sky)
	local theme = Style.theme(Config.Look.Theme)
	local rng = Random.new(Config.Look.PropSeed or 7)
	local folder = Instance.new("Model")
	folder.Name = "World"
	folder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	-- Parent while empty, then insert small batches to keep Studio responsive.
	folder.Parent = Workspace
	sandyFloor(folder)
	local X, Z = 440, 440 -- clear of the plots' back corners (radius ~387)
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
			cliff(folder, cf, w + 6, rng, theme, count)
			d += w
			if count % 4 == 0 then task.wait() end
		end
	end
	skyline(folder)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 590, GROUND_Y, math.sin(a) * 590) * CFrame.Angles(0, -a, 0)
		local h = rng:NextNumber(65, 110)
		for tier = 1, 3 do
			local w, d = 180 - tier * 28, 120 - tier * 18
			local top = h * tier / 3
			Build.block(folder, "DistantHill", V(w, h / 3, d), cf * CFrame.new(0, top - h / 6, 0), theme.cliff)
			Build.block(folder, "HillCap", V(w + 2, 4, d + 2), cf * CFrame.new(0, top, 0), GRASS)
		end
	end
	-- Apply the approved material finish only after environment parts are built.
	require(script.Parent.Kit.WorldStuds).apply()
end

return World
