--!strict
-- The world: 8 plots in two rows of 4 facing a central walkway, each with a
-- floor, an owner sign, a conveyor and a hydraulic press sized for the
-- player's current tier (Config.pressWidth). Plots.buildPress rebuilds the
-- press when the tier changes, so it visibly grows.
--
-- Plot local space: origin at floor centre, +Z points to the walkway (the
-- front, where the conveyor starts), press bed at the plot centre.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)

local Plots = {}

export type Plot = {
	index: number,
	origin: CFrame, -- floor centre, +Z toward the walkway
	model: Model,
	press: Model?,
	ram: BasePart?,
	bedTop: number, -- world Y of the bed's top surface
	ramRestY: number, -- ram plate bottom Y at rest
	tier: number,
	owner: Player?,
	sign: TextLabel,
}

local FLOOR_Y = 0.3 -- just above a Baseplate's top (y = 0) so they don't z-fight
local BED_HEIGHT = 2
local STEEL = Color3.fromRGB(70, 74, 82)
local YELLOW = Color3.fromRGB(245, 190, 40)
local FLOOR_COLORS = {
	Color3.fromRGB(96, 160, 110), Color3.fromRGB(110, 140, 200), Color3.fromRGB(200, 140, 90), Color3.fromRGB(170, 110, 190),
	Color3.fromRGB(90, 170, 170), Color3.fromRGB(200, 110, 120), Color3.fromRGB(160, 160, 90), Color3.fromRGB(120, 120, 130),
}

local root = Instance.new("Folder")
root.Name = "Plots"
root.Parent = Workspace

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function Plots.originFor(index: number): CFrame
	local P = Config.Plots
	local col = (index - 1) % 4 -- 0..3
	local row = if index <= 4 then 1 else -1 -- +Z row faces -Z (toward the walkway), and vice versa
	local x = (col - 1.5) * P.Spacing
	local z = row * P.RowOffset
	-- +Z of the plot points at the walkway (z = 0).
	local facing = if row == 1 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	return CFrame.new(x, FLOOR_Y, z) * facing
end

-- Rebuilds this plot's press for `tier` (bigger press = bigger objects).
function Plots.buildPress(plot: Plot, tier: number)
	if plot.press then
		plot.press:Destroy()
	end
	local W = Config.pressWidth(tier)
	local objH = Config.Objects[tier].height
	local press = Instance.new("Model")
	press.Name = "Press"
	local o = plot.origin
	local bedCenter = o * CFrame.new(0, BED_HEIGHT / 2, 0)
	part({ Name = "Bed", Size = Vector3.new(W, BED_HEIGHT, W), CFrame = bedCenter, Color = STEEL, Material = Enum.Material.DiamondPlate }, press)
	part({ Name = "BedStripe", Size = Vector3.new(W + 0.2, 0.4, 0.6), CFrame = bedCenter * CFrame.new(0, BED_HEIGHT / 2 - 0.2, -W / 2), Color = YELLOW }, press)
	local clearance = objH + math.max(2, W * 0.15)
	local pillarH = BED_HEIGHT + clearance + W * 0.35 + 3
	local pillarW = math.max(1.5, W * 0.12)
	for _, side in { -1, 1 } do
		part({ Name = "Pillar", Size = Vector3.new(pillarW, pillarH, pillarW), CFrame = o * CFrame.new(side * (W / 2 + pillarW / 2 + 0.3), pillarH / 2, 0), Color = YELLOW }, press)
	end
	local beamH = math.max(2, W * 0.18)
	part({ Name = "Beam", Size = Vector3.new(W + pillarW * 2 + 0.6, beamH, pillarW * 1.6), CFrame = o * CFrame.new(0, pillarH + beamH / 2, 0), Color = YELLOW }, press)
	-- The ram: a plate plus its hydraulic rod, moved together (rod welded visually by CFrame).
	local plateH = math.max(1, W * 0.1)
	local bedTop = (bedCenter * CFrame.new(0, BED_HEIGHT / 2, 0)).Position.Y
	local restBottom = bedTop + clearance
	local ram = part({ Name = "Ram", Size = Vector3.new(W * 0.92, plateH, W * 0.92), CFrame = CFrame.new(o.Position.X, restBottom + plateH / 2, o.Position.Z) * (o - o.Position), Color = STEEL, Material = Enum.Material.Metal }, press)
	-- Hydraulic cylinder housing on the beam; the rod stays inside it over the full stroke.
	local beamTop = FLOOR_Y + pillarH + beamH
	local housingH = clearance + 1
	part({ Name = "Housing", Size = Vector3.new(W * 0.34, housingH, W * 0.34), CFrame = o * CFrame.new(0, pillarH + beamH + housingH / 2, 0), Color = STEEL, Material = Enum.Material.Metal }, press)
	local rodLen = beamTop - (restBottom + plateH) + housingH * 0.9
	local rod = part({ Name = "Rod", Size = Vector3.new(W * 0.22, rodLen, W * 0.22), CFrame = ram.CFrame * CFrame.new(0, plateH / 2 + rodLen / 2, 0), Color = Color3.fromRGB(200, 205, 210), Material = Enum.Material.Metal }, press)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ram
	weld.Part1 = rod
	weld.Parent = ram
	rod.Anchored = false
	press.Parent = plot.model
	plot.press = press
	plot.ram = ram
	plot.bedTop = bedTop
	plot.ramRestY = restBottom
	plot.tier = tier
end

local plots: { Plot } = {}

function Plots.all(): { Plot }
	return plots
end

function Plots.create()
	for i = 1, Config.Plots.Count do
		local origin = Plots.originFor(i)
		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		model:SetAttribute("Index", i)
		local F = Config.Plots.FloorSize
		part({ Name = "Floor", Size = Vector3.new(F, 1, F), CFrame = origin * CFrame.new(0, -0.5, 0), Color = FLOOR_COLORS[i], Material = Enum.Material.Concrete }, model)
		-- Conveyor from the front edge to the bed.
		local beltLen = F / 2 - 4
		part({ Name = "Conveyor", Size = Vector3.new(8, 0.6, beltLen), CFrame = origin * CFrame.new(0, 0.3, F / 2 - beltLen / 2), Color = Color3.fromRGB(35, 35, 40), Material = Enum.Material.Fabric }, model)
		-- Owner sign at the front.
		local signPost = part({ Name = "SignPost", Size = Vector3.new(14, 4, 0.6), CFrame = origin * CFrame.new(-F / 2 + 10, 6, F / 2 - 2), Color = Color3.fromRGB(30, 30, 34) }, model)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = signPost
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = "Free plot"
		label.Parent = gui
		model.Parent = root
		local plot: Plot = { index = i, origin = origin, model = model, press = nil, ram = nil, bedTop = 0, ramRestY = 0, tier = 1, owner = nil, sign = label }
		Plots.buildPress(plot, 1)
		table.insert(plots, plot)
	end
	-- Walkway + spawn in the middle.
	part({ Name = "Walkway", Size = Vector3.new(Config.Plots.Spacing * 4 + 20, 1, Config.Plots.RowOffset * 2 - Config.Plots.FloorSize), CFrame = CFrame.new(0, FLOOR_Y - 0.6, 0), Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Concrete }, root)
end

-- Where the conveyor starts / where objects wait, in world space.
function Plots.beltStart(plot: Plot): CFrame
	local F = Config.Plots.FloorSize
	return plot.origin * CFrame.new(0, 0.6, F / 2 - 4)
end

-- The bed's top centre (an object's base sits here).
function Plots.bedBase(plot: Plot): CFrame
	return CFrame.new(plot.origin.Position.X, plot.bedTop, plot.origin.Position.Z) * (plot.origin - plot.origin.Position)
end

-- Spawn point in front of the plot, facing the press.
function Plots.spawnFor(plot: Plot): CFrame
	local F = Config.Plots.FloorSize
	return plot.origin * CFrame.new(8, 3, math.min(F / 2 - 10, 14 + Config.pressWidth(plot.tier)))
end

return Plots
