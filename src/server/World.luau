--!strict
-- The world round the plots (after the Yuzu game's valley): a ring of chunky
-- stepped rock cliffs with grassy, studded tops closes the map in; every few
-- cliffs a lava fall pours down the face into a small lava pool; bigger
-- mountains fill the horizon behind. Seeded, so every server looks the same.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)

local World = {}

local C = Color3.fromRGB
local GROUND_Y = 0.05
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local function lavaFall(parent: Instance, top: Vector3, bottomY: number, facing: CFrame, width: number)
	-- facing: rotation whose -Z points out of the cliff face (toward the map)
	local h = top.Y - bottomY
	local mid = CFrame.new(top.X, bottomY + h / 2, top.Z) * facing
	local fall = Build.block(parent, "LavaFall", Vector3.new(width, h, 1.2), mid, C(255, 110, 20), {})
	fall.Material = Enum.Material.Neon
	fall.CanCollide = false
	local edge = Build.block(parent, "LavaFallCore", Vector3.new(width * 0.5, h, 1.4), mid * CFrame.new(0, 0, -0.1), C(255, 210, 90), {})
	edge.Material = Enum.Material.Neon
	edge.CanCollide = false
	-- flowing pattern on the front face
	local tex = Instance.new("Texture")
	tex.Texture = Style.Studs.Texture
	tex.Face = Enum.NormalId.Front
	tex.StudsPerTileU = 3
	tex.StudsPerTileV = 3
	tex.Color3 = C(140, 30, 10)
	tex.Transparency = 0.5
	tex:SetAttribute("FlowV", -8)
	CollectionService:AddTag(tex, "FlowTexture")
	tex.Parent = fall
	-- lava pool at the bottom, out in front of the face
	local poolCf = CFrame.new(top.X, 0.45, top.Z) * facing * CFrame.new(0, 0, -5)
	local _, floor = Build.lava(parent, poolCf, width + 8, 9, { lights = true })
	local _ = floor
	local light = Instance.new("PointLight")
	light.Color = C(255, 130, 40)
	light.Range = 24
	light.Brightness = 2
	light.Parent = fall
	-- steam where it lands
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Rate = 4
	steam.Lifetime = NumberRange.new(2, 3)
	steam.Speed = NumberRange.new(2, 4)
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	steam.Color = ColorSequence.new(C(255, 220, 200))
	steam.EmissionDirection = Enum.NormalId.Top
	local att = Instance.new("Attachment")
	att.WorldPosition = Vector3.new(top.X, 1, top.Z)
	att.Parent = Workspace.Terrain
	steam.Parent = att
end

-- One cliff: 2-3 stepped rock tiers with grass on each top. `cf` = ground centre
-- of the front edge, -Z pointing at the map.
local function cliff(parent: Instance, cf: CFrame, width: number, rng: Random, theme: { [string]: Color3 }, fall: boolean)
	local depth = 34
	local tiers = rng:NextInteger(2, 3)
	local y = 0
	local back = 0
	local firstH = 0
	for t = 1, tiers do
		local h = (if t == 1 then rng:NextNumber(26, 38) else rng:NextNumber(14, 24))
		local w = width - (t - 1) * rng:NextNumber(4, 10)
		local rock = Build.block(parent, "Cliff", Vector3.new(w, h, depth - back), cf * CFrame.new(0, y + h / 2, back + (depth - back) / 2),
			if t % 2 == 0 then theme.cliffDark else theme.cliff, ALL)
		rock.Material = Enum.Material.SmoothPlastic
		-- a darker band near the bottom of each tier
		Build.block(parent, "CliffBand", Vector3.new(w + 0.2, 2, depth - back + 0.2), cf * CFrame.new(0, y + 1.5, back + (depth - back) / 2), theme.cliffDark, {})
		-- grass on top, overhanging a little
		Build.block(parent, "CliffGrass", Vector3.new(w + 1.2, 1.6, depth - back + 1.2), cf * CFrame.new(0, y + h + 0.6, back + (depth - back) / 2), theme.grass)
		-- a few grass drips down the front
		for _ = 1, rng:NextInteger(1, 3) do
			local dw = rng:NextNumber(2, 5)
			local dh = rng:NextNumber(1.5, 4)
			Build.block(parent, "GrassDrip", Vector3.new(dw, dh, 0.8), cf * CFrame.new(rng:NextNumber(-w / 2 + dw, w / 2 - dw), y + h - dh / 2 + 0.2, back - 0.2), theme.grass, {})
		end
		if t == 1 then
			firstH = h
		end
		y += h
		back += rng:NextNumber(8, 14)
	end
	local topY, topZ = y, back
	if fall then
		-- pours over the front edge of the lowest tier
		local top = (cf * CFrame.new(rng:NextNumber(-width / 4, width / 4), firstH, -0.7)).Position
		lavaFall(parent, top, GROUND_Y, cf - cf.Position, rng:NextNumber(5, 8))
	end
	-- a tree or two on the top
	if rng:NextNumber() < 0.6 then
		Build.tree(parent, cf * CFrame.new(rng:NextNumber(-width / 3, width / 3), topY + 1.2, topZ - back / 2 + 4), rng:NextNumber(2, 3), theme, rng)
	end
end

function World.create()
	local theme = Style.theme(Config.Look.Theme)
	if not theme.cliff then
		return
	end
	local rng = Random.new(Config.Look.PropSeed or 7)
	-- a Model that always streams in, so the backdrop is visible from every plot
	local folder = Instance.new("Model")
	folder.Name = "World"
	folder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local X, Z = 400, 340 -- inner faces of the cliff ring
	-- each side: walk along it placing cliffs of random width
	local sides = {
		{ from = Vector3.new(-X, 0, -Z), dir = Vector3.new(1, 0, 0), len = 2 * X, facing = 0 }, -- back (z = -Z), faces +Z
		{ from = Vector3.new(X, 0, Z), dir = Vector3.new(-1, 0, 0), len = 2 * X, facing = math.pi }, -- front, faces -Z
		{ from = Vector3.new(-X, 0, Z), dir = Vector3.new(0, 0, -1), len = 2 * Z, facing = math.pi / 2 }, -- left
		{ from = Vector3.new(X, 0, -Z), dir = Vector3.new(0, 0, 1), len = 2 * Z, facing = -math.pi / 2 }, -- right
	}
	local count = 0
	for _, side in sides do
		local d = 0
		while d < side.len + 20 do
			local w = rng:NextNumber(34, 52)
			local pos = side.from + side.dir * (d + w / 2) + Vector3.new(0, GROUND_Y, 0)
			-- rotation: local -Z (front) faces the map centre
			local face = CFrame.Angles(0, side.facing + math.pi, 0)
			local jitter = rng:NextNumber(-6, 6)
			local cf = CFrame.new(pos) * face * CFrame.new(0, 0, jitter) * CFrame.Angles(0, rng:NextNumber(-0.08, 0.08), 0)
			count += 1
			cliff(folder, cf, w + 4, rng, theme, count % 4 == 2)
			d += w
		end
	end
	-- mountains on the horizon
	for i = 1, 26 do
		local a = (i / 26) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local r = rng:NextNumber(560, 660)
		local w = rng:NextNumber(120, 200)
		local h = rng:NextNumber(90, 170)
		local base = CFrame.new(math.cos(a) * r, GROUND_Y, math.sin(a) * r) * CFrame.Angles(0, -a + math.pi / 2, 0)
		Build.block(folder, "Mountain", Vector3.new(w, h, 90), base * CFrame.new(0, h / 2, 0), theme.cliffDark:Lerp(C(150, 160, 190), 0.35), ALL)
		local off = rng:NextNumber(-w / 6, w / 6)
		Build.block(folder, "MountainTop", Vector3.new(w * 0.6, h * 0.35, 70), base * CFrame.new(off, h + h * 0.175, 0), theme.cliff:Lerp(C(160, 170, 200), 0.3), ALL)
		Build.block(folder, "MountainGrass", Vector3.new(w * 0.6 + 2, 3, 72), base * CFrame.new(off, h * 1.35 + 1, 0), theme.grass:Lerp(C(150, 180, 160), 0.3))
	end
	folder.Parent = Workspace
end

return World
