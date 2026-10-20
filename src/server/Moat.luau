--!strict
-- Lava moat round every plot (like the river round the Yuzu game's onsen):
-- the plot is an island; a steel bridge crosses from the walkway to the plot
-- (front, right of the conveyor) and another from the plot to its scrap shop
-- (back, ScrapShop.luau uses Moat.bridge). Basalt banks on the outer side,
-- except where the bridges land. Falling in bounces you back to the side you
-- came from. Width: Config.Plots.Moat.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Kit.Build)

local Moat = {}

local C = Color3.fromRGB
local YELLOW = C(245, 190, 40)
local BLACK = C(30, 30, 34)
local STEEL = C(96, 102, 118)
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

Moat.SURFACE_Y = 0.45 -- lava surface, world Y (ground top is 0.05, plot floors 1.6)
Moat.FRONT_BRIDGE_X = 16 -- local X of the walkway bridge (the conveyor is at 0, spawn at 8)

-- A steel bridge over the moat. `cf` is the deck centre on the plot-floor height,
-- its Z axis running across the moat; `length` along Z.
function Moat.bridge(parent: Instance, cf: CFrame, length: number, width: number?)
	local w = width or 10
	local deck = Build.block(parent, "BridgeDeck", Vector3.new(w, 0.6, length), cf * CFrame.new(0, -0.3, 0), STEEL)
	deck.Material = Enum.Material.DiamondPlate
	-- cross beams underneath
	for i = -1, 1 do
		Build.block(parent, "BridgeBeam", Vector3.new(w + 0.6, 0.5, 0.8), cf * CFrame.new(0, -0.8, i * length / 3), BLACK, {})
	end
	for _, x in { -1, 1 } do
		Build.block(parent, "BridgeRail", Vector3.new(0.5, 0.5, length), cf * CFrame.new(x * (w / 2 - 0.25), 1.5, 0), YELLOW, ALL)
		for i = 0, 3 do
			local z = -length / 2 + 0.5 + i * (length - 1) / 3
			Build.block(parent, "RailPost", Vector3.new(0.7, 1.5, 0.7), cf * CFrame.new(x * (w / 2 - 0.25), 0.75, z), if i % 2 == 0 then BLACK else YELLOW, ALL)
		end
	end
	-- hazard stripes on both ends of the deck
	for _, z in { -1, 1 } do
		for i = 0, 5 do
			Build.block(parent, "BridgeStripe", Vector3.new(w / 6, 0.05, 0.7), cf * CFrame.new(-w / 2 + (i + 0.5) * w / 6, 0.02, z * (length / 2 - 0.4)),
				if i % 2 == 0 then YELLOW else BLACK, {})
		end
	end
end

-- Builds the moat round one plot. Returns nothing; everything goes in plotModel.Moat.
function Moat.build(plotModel: Model, origin: CFrame)
	local F = Config.Plots.FloorSize
	local M = Config.Plots.Moat
	local half = F / 2
	local floorY = origin.Position.Y
	local m = Instance.new("Model")
	m.Name = "Moat"
	-- local frame at lava-surface height
	local base = CFrame.new(origin.Position.X, Moat.SURFACE_Y, origin.Position.Z) * (origin - origin.Position)
	local at = function(x: number, z: number, yaw: number?): CFrame
		return base * CFrame.new(x, 0, z) * CFrame.Angles(0, yaw or 0, 0)
	end

	local floors: { Part } = {}
	-- front and back strips run along X (full width incl. corners), sides along Z
	for _, side in { -1, 1 } do
		local _, f1 = Build.lava(m, at(0, side * (half + M / 2)), F + 2 * M, M)
		table.insert(floors, f1)
		local _, f2 = Build.lava(m, at(side * (half + M / 2), 0, math.rad(90)), F, M, { lights = true })
		table.insert(floors, f2)
	end

	-- basalt banks on the outer edge, open where the bridges land
	local bankH = 0.75
	local gapHalf = 6
	local function bankRun(x0: number, x1: number, z: number)
		if x1 - x0 > 0.5 then
			Build.bank(m, at((x0 + x1) / 2, z), x1 - x0, bankH)
		end
	end
	local outer = half + M + 0.7
	local fb = Moat.FRONT_BRIDGE_X
	-- front: gap at the walkway bridge
	bankRun(-outer, fb - gapHalf, outer)
	bankRun(fb + gapHalf, outer, outer)
	-- back: gap at the shop bridge (x = 0)
	bankRun(-outer, -gapHalf, -outer)
	bankRun(gapHalf, outer, -outer)
	-- sides
	for _, side in { -1, 1 } do
		local b = Build.bank(m, at(side * outer, 0, math.rad(90)), 2 * outer, bankH)
		local _ = b
	end

	-- the walkway bridge (front), deck at plot-floor height
	local deckY = floorY - Moat.SURFACE_Y
	Moat.bridge(m, base * CFrame.new(fb, deckY, half + M / 2), M + 3)

	-- falling in: bounce back to whichever side you were closest to
	local function bounce(hit: BasePart)
		local character = hit.Parent
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or root:GetAttribute("Bouncing") then
			return
		end
		root:SetAttribute("Bouncing", true)
		local p = origin:PointToObjectSpace(root.Position)
		local function push(v: number): number
			local a = math.abs(v)
			if a <= half then
				return v
			end
			local sign = if v < 0 then -1 else 1
			-- nearer the plot edge -> back onto the plot, else out to the far bank
			return if a < half + M / 2 then sign * (half - 3) else sign * (half + M + 3)
		end
		local target = origin * CFrame.new(push(p.X), 3, push(p.Z))
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(target.Position) * (root.CFrame - root.CFrame.Position)
		task.delay(0.5, function()
			root:SetAttribute("Bouncing", nil)
		end)
	end
	for _, f in floors do
		f.Touched:Connect(bounce)
	end
	m.Parent = plotModel
end

return Moat
