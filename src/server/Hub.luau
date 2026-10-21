--!strict
-- The hub island between the two rows of plot islands (the tank game's
-- "Market" island): you spawn here and cross a wooden bridge to your plot.
-- Grass top with a brick road down the middle, dark asphalt squares at the
-- bridge landings, lamps along the road, trees/bushes/crates along the edges,
-- a lava fountain and a big "CRUSH IT" sign in the middle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local Moat = require(script.Parent.Moat)

local Hub = {}

local C = Color3.fromRGB
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

-- half sizes of the hub top
function Hub.size(): (number, number)
	local P = Config.Plots
	local hx = P.Spacing * 1.5 + P.FloorSize / 2 + 20
	local hz = P.RowOffset - P.Front - Config.World.HubGap
	return hx, hz
end

local function signText(part: BasePart, face: Enum.NormalId, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = text
	l.Parent = gui
	Style.text(l, 6)
	l.TextColor3 = C(255, 210, 60)
end

-- `bridgeXs` = { { x, side } } where the plot bridges land (side +1 = +Z edge).
function Hub.create(parent: Instance, bridges: { { x: number, side: number } })
	local pal = Style.theme(Config.Look.Theme)
	local hx, hz = Hub.size()
	local floorY = 1.6
	local top = CFrame.new(0, floorY, 0)
	local m = Instance.new("Model")
	m.Name = "Hub"
	local rng = Random.new(77)

	Build.platform(m, "HubFloor", top, hx * 2, hz * 2, 1.55, pal.grass or pal.platform, pal.grassEdge or pal.edge, 2)
	local gaps = {}
	for _, b in bridges do
		table.insert(gaps, { side = if b.side > 0 then "front" else "back", at = b.x, width = Moat.BRIDGE_WIDTH + 1 })
	end
	Build.island(m, top, hx * 2, hz * 2, Config.World.SeaY, pal, { rng = rng, gaps = gaps })

	-- brick road down the middle, branches to every bridge
	Build.path(m, Vector3.new(-hx + 6, floorY, 0), Vector3.new(hx - 6, floorY, 0), 12)
	for _, b in bridges do
		Build.path(m, Vector3.new(b.x, floorY, 0), Vector3.new(b.x, floorY, b.side * (hz - 1)), 8)
		Build.patch(m, top * CFrame.new(b.x, 0, b.side * (hz - 9)), 18, 12, pal.pad, rng, "Landing")
	end

	-- lamps along the road, trees/bushes/crates along the edges between bridges
	local function nearBridge(x: number, side: number): boolean
		for _, b in bridges do
			if b.side == side and math.abs(b.x - x) < 12 then
				return true
			end
		end
		return false
	end
	for x = -hx + 14, hx - 14, 28 do
		for _, side in { -1, 1 } do
			if not nearBridge(x, side) and math.abs(x) > 26 then
				Build.lamp(m, top * CFrame.new(x, 0, side * 8.5), pal, 11)
			end
		end
	end
	for x = -hx + 8, hx - 8, 11 do
		for _, side in { -1, 1 } do
			if not nearBridge(x, side) and math.abs(x) > 30 then
				local cf = top * CFrame.new(x + rng:NextNumber(-2, 2), 0, side * (hz - 5 - rng:NextNumber(0, 6))) * CFrame.Angles(0, rng:NextNumber() * 6, 0)
				local roll = rng:NextNumber()
				if roll < 0.45 then
					Build.tree(m, cf, rng:NextNumber(1.5, 2.1), pal, rng)
				elseif roll < 0.8 then
					Build.bush(m, cf, rng:NextNumber(1.1, 1.6), pal, rng)
				else
					Build.rock(m, cf, rng:NextNumber(0.8, 1.2), pal, rng)
				end
			end
		end
	end

	-- lava fountain in the middle
	local basin = top * CFrame.new(0, 0, 0)
	Build.block(m, "FountainRim", Vector3.new(18, 2, 18), basin * CFrame.new(0, 1, 0), pal.stone or C(132, 130, 140), ALL)
	local pool = Build.block(m, "FountainLava", Vector3.new(15, 0.3, 15), basin * CFrame.new(0, 2.05, 0), C(255, 120, 30), {})
	pool.Material = Enum.Material.Neon
	Build.block(m, "FountainCrust", Vector3.new(15.2, 0.2, 15.2), basin * CFrame.new(0, 1.95, 0), C(130, 34, 12), {}).Material = Enum.Material.CrackedLava
	Build.block(m, "FountainPillar", Vector3.new(4, 7, 4), basin * CFrame.new(0, 5.5, 0), pal.stoneDark or C(102, 100, 110), ALL)
	local spout = Build.block(m, "FountainTop", Vector3.new(6, 1.2, 6), basin * CFrame.new(0, 9.6, 0), C(255, 150, 40), {})
	spout.Material = Enum.Material.Neon
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Rate = 25
	embers.Lifetime = NumberRange.new(1, 1.8)
	embers.Speed = NumberRange.new(8, 12)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Acceleration = Vector3.new(0, -14, 0)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.1) })
	embers.Color = ColorSequence.new(C(255, 230, 120), C(255, 100, 20))
	embers.LightEmission = 1
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Parent = spout
	local light = Instance.new("PointLight")
	light.Color = C(255, 140, 50)
	light.Range = 20
	light.Brightness = 1.5
	light.Parent = spout

	-- big "CRUSH IT" sign on both sides of the fountain
	for _, side in { -1, 1 } do
		local sign, face = Build.signFrame(m, top * CFrame.new(side * 28, 0, 0) * CFrame.Angles(0, side * math.rad(90), 0), 18, 6, pal.edge)
		sign.Name = "HubSign"
		face.Color = C(40, 42, 52)
		signText(face, Enum.NormalId.Back, "CRUSH IT")
	end

	-- spawn on the hub (players are moved to their plot once it's assigned)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = top * CFrame.new(0, 0.1, 14)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Neutral = true
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = m

	m.Parent = parent
	local _ = Workspace
end

return Hub
