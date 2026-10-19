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
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local PressBuilder = require(script.Parent.PressBuilder)

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

-- Rebuilds this plot's press for `tier` (bigger and fancier every tier: PressBuilder).
function Plots.buildPress(plot: Plot, tier: number)
	if plot.press then
		plot.press:Destroy()
	end
	local built = PressBuilder.build(plot.origin, tier)
	built.model.Parent = plot.model
	plot.press = built.model
	plot.ram = built.ram
	plot.bedTop = built.bedTop
	plot.ramRestY = built.restBottom
	plot.tier = tier
end

-- The freshly built press rises out of the floor (used when buying a bigger press).
function Plots.riseIn(plot: Plot, duration: number)
	local press = plot.press
	if not press then
		return
	end
	local _, size = press:GetBoundingBox()
	local depth = size.Y + 2
	for _, p in press:GetDescendants() do
		if p:IsA("BasePart") and p.Anchored then
			local target = p.CFrame
			p.CFrame = target - Vector3.new(0, depth, 0)
			local delay = if p.Name == "Bed" then 0 else 0.08
			TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay), { CFrame = target }):Play()
		end
	end
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
