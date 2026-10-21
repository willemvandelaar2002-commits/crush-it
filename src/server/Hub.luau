--!strict
-- The service hub: concrete lanes, sparse workshop stations and a chunky
-- entrance landmark. Plot bridges, spawn and walking surfaces stay in place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local Moat = require(script.Parent.Moat)
local YardProps = require(script.Parent.Kit.YardProps)

local Hub = {}

local C = Color3.fromRGB
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

-- half sizes of the hub top
function Hub.size(): (number, number)
	local P = Config.Plots
	local hx = P.Spacing * 1.5 + 20 -- just past the outermost bridges
	local hz = P.RowOffset - P.Front - Config.World.HubGap
	return hx, hz
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

	-- Charcoal service road down the middle, branches to every bridge.
	Build.path(m, Vector3.new(-hx + 6, floorY, 0), Vector3.new(hx - 6, floorY, 0), 12)
	for _, b in bridges do
		Build.path(m, Vector3.new(b.x, floorY, 0), Vector3.new(b.x, floorY, b.side * (hz - 1)), 8)
		Build.patch(m, top * CFrame.new(b.x, 0, b.side * (hz - 9)), 18, 12, C(77, 83, 88), rng, "Landing")
	end

	-- Sparse roadside stations, with bridge mouths and the central approach clear.
	local function nearBridge(x: number, side: number): boolean
		for _, b in bridges do
			if b.side == side and math.abs(b.x - x) < 14 then return true end
		end
		return false
	end
	local station = 0
	for x = -hx + 22, hx - 22, 82 do
		for _, side in { -1, 1 } do
			if not nearBridge(x, side) and math.abs(x) > 44 then
				station += 1
				local cf = top * CFrame.new(x, 0, side * (hz - 10))
					* CFrame.Angles(0, if side > 0 then 0 else math.pi, 0)
				if station % 4 == 0 then
					local tree = Build.tree(m, cf, 0.85, pal, rng)
					for _, p in tree:GetDescendants() do
						if p:IsA("BasePart") then p.CanCollide = false; p.CanTouch = false; p.CanQuery = false end
					end
				else
					YardProps.cluster(m, cf, station, 1.5)
				end
				YardProps.workLight(m, top * CFrame.new(x, 0, side * 9)
					* CFrame.Angles(0, if side > 0 then 0 else math.pi, 0), station % 2 == 0)
			end
		end
	end

	-- Scrap display replaces the fountain's appearance. Retain its solid
	-- footprint and heights, so the spawn and routes round it do not change.
	local basin = top
	Build.block(m, "DisplayPlinth", Vector3.new(18, 2, 18), basin * CFrame.new(0, 1, 0), pal.edge, ALL)
	Build.block(m, "DisplayInset", Vector3.new(15, 0.3, 15), basin * CFrame.new(0, 2.05, 0), pal.platform, {})
	Build.block(m, "DisplayTrim", Vector3.new(15.2, 0.2, 15.2), basin * CFrame.new(0, 1.95, 0), pal.edge, {})
	Build.block(m, "DisplayPillar", Vector3.new(4, 7, 4), basin * CFrame.new(0, 5.5, 0), pal.edge, ALL)
	Build.block(m, "DisplayTop", Vector3.new(6, 1.2, 6), basin * CFrame.new(0, 9.6, 0), C(47, 111, 201), {})
	YardProps.bales(m, basin * CFrame.new(0, 10.2, 0), 0.8)
	-- Existing sign approach: posts straddle the 12-stud road; the hanging
	-- cube clears avatars by over 13 studs. All new gate pieces are decorative.
	YardProps.entrance(m, top * CFrame.new(-28, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0))

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
