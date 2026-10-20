--!strict
-- Decoration around the plots, built from the kit props (Build.tree/bush/rock/
-- fence/lamp). Seeded, so the world looks the same every server.
--
--   * a white fence behind each row's scrap shops and down both ends (walkway left open)
--   * lamp, bush, tree and rock in every gap between two plots
--   * lamps at both ends of the walkway
--   * a band of trees, bushes and rocks outside the fence
--
-- Layout numbers come from Config.Plots, so it follows if the plots move.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)

local Decor = {}

local GROUND_Y = 0.05

local function at(x: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, GROUND_Y, z) * CFrame.Angles(0, yaw or 0, 0)
end

function Decor.create()
	if Config.Look.Props == false then
		return
	end
	local palette = Style.theme(Config.Look.Theme)
	local rng = Random.new(Config.Look.PropSeed or 7)
	local P = Config.Plots
	local F = P.FloorSize
	local halfX = P.Spacing * 1.5 + F / 2 + P.Moat -- outer side of the end plots' moats
	local backZ = P.RowOffset + F / 2 -- back edge of each row
	local walkZ = P.RowOffset - F / 2 - P.Moat -- edge of the walkway (the moat starts here)

	local root = Instance.new("Folder")
	root.Name = "Decor"

	-- Fences: behind the scrap shop islands of both rows and down both ends, leaving the walkway open.
	local shopDepth = Config.Plots.Moat + Config.ScrapShop.Depth
	local fz = backZ + shopDepth + 7
	local fx = halfX + 10
	for _, side in { -1, 1 } do
		Build.fence(root, Vector3.new(-fx, GROUND_Y, side * fz), Vector3.new(fx, GROUND_Y, side * fz), palette.fence)
		for _, ex in { -1, 1 } do
			Build.fence(root, Vector3.new(ex * fx, GROUND_Y, side * fz), Vector3.new(ex * fx, GROUND_Y, side * (walkZ + 6)), palette.fence)
		end
	end

	-- Gaps between neighbouring plots: lamp near the walkway, then bush, tree, rock
	-- (only if there is ground between the moats).
	local gapWidth = P.Spacing - F - 2 * (P.Moat or 0)
	for col = 1, if gapWidth >= 10 then 3 else 0 do
		local x = (col - 2) * P.Spacing
		for _, side in { -1, 1 } do
			local z0 = walkZ + 6
			local depth = backZ - z0
			Build.lamp(root, at(x, side * z0), palette)
			Build.bush(root, at(x, side * (z0 + depth * 0.25), rng:NextNumber() * 6), 1, palette, rng)
			Build.tree(root, at(x, side * (z0 + depth * 0.55), rng:NextNumber() * 6), 1.7, palette, rng)
			Build.rock(root, at(x, side * (z0 + depth * 0.85)), 0.9, palette, rng)
		end
	end

	-- Lamps where the walkway ends.
	for _, ex in { -1, 1 } do
		for _, side in { -1, 1 } do
			Build.lamp(root, at(ex * (halfX + 28), side * (walkZ - 6)), palette, 12)
		end
	end

	-- A band of nature outside the fence (behind both rows and past both ends).
	local function scatter(x: number, z: number)
		local cf = at(x + rng:NextNumber(-6, 6), z + rng:NextNumber(-6, 6), rng:NextNumber() * 6)
		local roll = rng:NextNumber()
		if roll < 0.6 then
			Build.tree(root, cf, rng:NextNumber(1.7, 2.6), palette, rng)
		elseif roll < 0.8 then
			Build.bush(root, cf, rng:NextNumber(1, 1.5), palette, rng)
		else
			Build.rock(root, cf, rng:NextNumber(0.8, 1.6), palette, rng)
		end
	end
	local step = 26
	local outerX = fx + 60
	local outerZ = fz + 90
	for _, side in { -1, 1 } do
		for x = -outerX, outerX, step do
			for z = fz + 18, outerZ, step do
				scatter(x, side * z)
			end
		end
	end
	for _, ex in { -1, 1 } do
		for x = fx + 18, outerX, step do
			for z = -(fz + 4), fz + 4, step do
				-- keep the view down the walkway clear
				if math.abs(z) > walkZ + 4 then
					scatter(ex * x, z)
				end
			end
		end
	end

	root.Parent = Workspace
end

return Decor
