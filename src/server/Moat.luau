--!strict
-- Islands (after the Yuzu onsen and Destroy a Vault): every plot is a thick island
-- standing in the lava sea (World.luau), joined to the hub island in the middle
-- by a chunky wooden bridge, with its scrap shop island behind it over a second
-- bridge (ScrapShop.luau uses Moat.bridge). Island body: Build.island (dirt
-- band, studded stone sides, rocks, a stone curb along the edge with gaps at the
-- bridges). Also: trees, bushes, lamps and barrels along the free edges, and
-- the lava rescue (fall in -> back on your plot).
-- (File name kept from the old lava moat so nothing else had to change.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Net = require(ReplicatedStorage.Shared.Net)
local Build = require(script.Parent.Kit.Build)

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

-- Trees, bushes, lamps and barrels along the free edges of a plot.
local function edgeProps(m: Instance, origin: CFrame, rng: Random)
	local F = Config.Plots.FloorSize
	local half = F / 2
	local pal = palette()
	local function at(x: number, z: number): CFrame
		return origin * CFrame.new(x, 0, z) * CFrame.Angles(0, rng:NextNumber() * 6, 0)
	end
	local spots = {
		{ -half + 5, -38, "tree" }, { -half + 5, -26, "bush" }, { -half + 5, -14, "tree" }, { -half + 5, -4, "lamp" },
		{ half - 5, -30, "tree" }, { half - 5, -8, "bush" },
		{ -40, -half + 5, "tree" }, { -27, -half + 5, "bush" }, { -14, -half + 5, "lamp" },
		{ 13, -half + 5, "lamp" }, { 24, -half + 5, "tree" },
		{ -half + 5, 30, "bush" }, { 30, half - 5, "bush" }, { 44, half - 5, "tree" },
	}
	for _, s in spots do
		local x, z, kind = s[1] :: number, s[2] :: number, s[3] :: string
		if kind == "tree" then
			Build.tree(m, at(x, z), rng:NextNumber(1.4, 1.9), pal, rng)
		elseif kind == "bush" then
			Build.bush(m, at(x, z), rng:NextNumber(1.1, 1.5), pal, rng)
		else
			Build.lamp(m, origin * CFrame.new(x, 0, z), pal, 10)
		end
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
	Build.island(m, origin, F, F, seaY, palette(), {
		rng = rng,
		gaps = {
			{ side = "front", at = Moat.FRONT_BRIDGE_X, width = Moat.BRIDGE_WIDTH + 1 },
			{ side = "back", at = 0, width = Moat.BRIDGE_WIDTH + 1 },
		},
	})
	-- bridge over the lava to the hub (deck from the plot edge to the hub edge)
	local gap = Config.World.HubGap
	local a = (origin * CFrame.new(Moat.FRONT_BRIDGE_X, 0, half - 1.5)).Position
	local b = (origin * CFrame.new(Moat.FRONT_BRIDGE_X, 0, half + gap + 1.5)).Position
	Build.bridge(m, a, b, Moat.BRIDGE_WIDTH, palette(), seaY)
	edgeProps(m, origin, rng)
	m.Parent = plotModel
end

-- Fall into the lava -> back on your plot (or the hub). `spawnFor(player)` gives a CFrame.
function Moat.start(spawnFor: (Player) -> CFrame)
	local Notice = Net.event("Notice")
	local limit = Config.World.SeaY + 4 -- a character standing on the lava has its root ~3 studs up
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and root.Position.Y < limit then
					root.AssemblyLinearVelocity = Vector3.zero
					character:PivotTo(spawnFor(player))
					Notice:FireClient(player, { text = "Ouch, hot lava!" })
				end
			end
		end
	end)
end

return Moat
