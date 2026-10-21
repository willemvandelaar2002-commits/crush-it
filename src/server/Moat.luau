--!strict
-- Islands (after the Yuzu onsen and Destroy a Vault): every plot is a thick island
-- standing above the sandy apron (World.luau), joined to the hub in the middle
-- by a chunky concrete bridge, with the scrap shop on a tab at the back of the
-- same island (ScrapShop.luau), so the shop is a few steps from the scrap pile.
-- Island body: Build.island (dirt band, studded stone sides, rocks, a stone curb
-- along the edge with gaps at the bridge and the shop). Also: low workshop props
-- along the free edges, and the existing rescue (fall in -> back on your plot).
-- (File name kept from the old lava moat so nothing else had to change.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Net = require(ReplicatedStorage.Shared.Net)
local Build = require(script.Parent.Kit.Build)
local YardProps = require(script.Parent.Kit.YardProps)

local Moat = {}

Moat.FRONT_BRIDGE_X = 16 -- local X of the hub bridge (the conveyor is at 0, spawn at 8)
Moat.BRIDGE_WIDTH = 9

local function palette(): { [string]: Color3 }
	return Style.theme(Config.Look.Theme)
end

-- A bridge whose deck centre is `cf` (plot-floor height), running along cf's Z axis.
function Moat.bridge(parent: Instance, cf: CFrame, length: number, width: number?)
	local a = (cf * CFrame.new(0, 0, length / 2)).Position
	local b = (cf * CFrame.new(0, 0, -length / 2)).Position
	Build.bridge(parent, a, b, width or Moat.BRIDGE_WIDTH, palette(), Config.World.SeaY)
end

-- Compact workshop clusters at the free edges. They live in Decor so the
-- existing growing-press clearance code can park them when needed.
local function edgeProps(m: Instance, origin: CFrame, rng: Random)
	local F = Config.Plots.FloorSize
	local half = F / 2
	local pal = palette()
	local function at(x: number, z: number): CFrame
		return origin * CFrame.new(x, 0, z) * CFrame.Angles(0, rng:NextNumber() * 6, 0)
	end
	YardProps.cluster(m, origin * CFrame.new(-half + 5, 0, 23), 0)
	YardProps.cluster(m, origin * CFrame.new(half - 5, 0, 23) * CFrame.Angles(0, math.pi, 0), 2)
	local tree = Build.tree(m, at(-half + 5, 8), 0.7, pal, rng)
	for _, p in tree:GetDescendants() do
		if p:IsA("BasePart") then p.CanCollide = false; p.CanTouch = false; p.CanQuery = false end
	end
end

-- Island body + hub bridge + edge props for one plot.
function Moat.build(plotModel: Model, origin: CFrame)
	local F = Config.Plots.FloorSize
	local half = F / 2
	local seaY = Config.World.SeaY
	local m = Instance.new("Model")
	m.Name = "Island"
	local index = (plotModel:GetAttribute("Index") :: number?) or 1
	local rng = Random.new(200 + index)
	local S = Config.ScrapShop
	Build.island(m, origin, F, F, seaY, palette(), {
		rng = rng,
		gaps = {
			{ side = "front", at = Moat.FRONT_BRIDGE_X, width = Moat.BRIDGE_WIDTH + 1 },
			{ side = "back", at = 0, width = S.Width + 3 }, -- open into the shop tab
		},
	})
	-- the shop tab behind the plot (its front is the plot's back edge: no curb there)
	Build.island(m, origin * CFrame.new(0, 0, -half - S.Depth / 2), S.Width, S.Depth, seaY, palette(), {
		rng = rng,
		gaps = { { side = "front", at = 0, width = S.Width + 4 } },
	})
	-- bridge over the lava to the hub (deck from the plot edge to the hub edge)
	local gap = Config.World.HubGap
	local a = (origin * CFrame.new(Moat.FRONT_BRIDGE_X, 0, half - 1.5)).Position
	local b = (origin * CFrame.new(Moat.FRONT_BRIDGE_X, 0, half + gap + 1.5)).Position
	Build.bridge(m, a, b, Moat.BRIDGE_WIDTH, palette(), seaY)
	edgeProps(plotModel:FindFirstChild("Decor") or m, origin, rng)
	m.Parent = plotModel
end

-- Fall into the lava -> back on your plot (or the hub). `spawnFor(player)` gives a CFrame.
function Moat.start(spawnFor: (Player) -> CFrame)
	local Notice = Net.event("Notice")
	local limit = Config.World.SeaY + 1.2 -- feet this low = in the lava (floors are ~4.6 studs higher)
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				-- feet height (avatars differ a lot in how high their root sits)
				local feet = if root and humanoid then root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight else math.huge
				if root and feet < limit then
					root.AssemblyLinearVelocity = Vector3.zero
					character:PivotTo(spawnFor(player))
					Notice:FireClient(player, { text = "Ouch, hot lava!" })
				end
			end
		end
	end)
end

return Moat
