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
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)

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

local FLOOR_Y = 1.6 -- top of the raised plot platforms (the ground sits at y = 0.05)
local GRASS = Color3.fromRGB(105, 200, 85)
-- each plot's rim colour
local FLOOR_COLORS = {
	Color3.fromRGB(255, 120, 110), Color3.fromRGB(110, 170, 255), Color3.fromRGB(255, 190, 70), Color3.fromRGB(200, 130, 255),
	Color3.fromRGB(80, 220, 210), Color3.fromRGB(255, 130, 200), Color3.fromRGB(170, 230, 90), Color3.fromRGB(200, 200, 215),
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

-- The stud pattern on a part's faces (Config.Look).
function Plots.studs(p: BasePart, faces: { Enum.NormalId }?)
	Style.studs(p, faces)
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
	-- the dark pad under the press grows with it
	local pad = plot.model:FindFirstChild("Pad") :: BasePart?
	if pad then
		local F = Config.Plots.FloorSize
		local size = math.clamp(Config.pressWidth(tier) * 1.9 + 14, 34, F - 16)
		pad.Size = Vector3.new(size, 0.12, size)
		pad.CFrame = plot.origin * CFrame.new(0, 0.06, 0)
		-- framed edge round the pad
		local edge = plot.model:FindFirstChild("PadEdge")
		if edge then
			edge:ClearAllChildren()
			local theme = Style.theme(Config.Look.Theme)
			for _, z in { -1, 1 } do
				Build.block(edge, "Frame", Vector3.new(size + 2, 0.3, 1), plot.origin * CFrame.new(0, 0.15, z * (size / 2 + 0.5)), theme.edge)
			end
			for _, x in { -1, 1 } do
				Build.block(edge, "Frame", Vector3.new(1, 0.3, size), plot.origin * CFrame.new(x * (size / 2 + 0.5), 0.15, 0), theme.edge)
			end
		end
	end
	-- floating name over the press
	local info = Config.Presses[tier]
	local topPart = built.model:FindFirstChild("Bed") :: BasePart?
	if topPart then
		local _, size = built.model:GetBoundingBox()
		Build.label(topPart, info.name, info.accent:Lerp(Color3.new(1, 1, 1), 0.35), size.Y + 3, Vector2.new(math.clamp(Config.pressWidth(tier), 14, 40), 4))
	end
	-- keep the upgrade board just right of the press, facing the spawn
	local board = plot.model:FindFirstChild("Board") :: Model?
	if board then
		local W = Config.pressWidth(tier)
		local F = Config.Plots.FloorSize
		local x = math.clamp(W * 0.9 + 9, 15, F / 2 - 7)
		local z = math.clamp(W * 0.3, 4, 30)
		board:PivotTo(plot.origin * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(-25), 0))
	end
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
	local theme = Style.theme(Config.Look.Theme)
	local F = Config.Plots.FloorSize
	local P = Config.Plots
	-- Ground under everything (covers the Baseplate).
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Transparency = 1
		for _, t in base:GetChildren() do
			if t:IsA("Texture") or t:IsA("Decal") then
				t.Transparency = 1
			end
		end
	end
	Build.block(root, "Ground", Vector3.new(1600, 1, 1600), CFrame.new(0, 0.05 - 0.5, 0), theme.ground)
	-- Walkway down the middle: a lower platform with an edge.
	local walkW = P.Spacing * 4 + 30
	local walkD = P.RowOffset * 2 - F + 6
	Build.platform(root, "Walkway", CFrame.new(0, 0.7, 0), walkW, walkD, 0.65, theme.path, theme.edge, 1.5)

	for i = 1, P.Count do
		local origin = Plots.originFor(i)
		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		model:SetAttribute("Index", i)
		-- Raised platform; its top is the plot floor (origin).
		Build.platform(model, "Floor", origin, F, F, origin.Position.Y - 0.05, theme.platform, theme.edge, 2)
		-- Coloured trim just inside the edge so each plot has its own colour.
		local trim = FLOOR_COLORS[i]
		for _, z in { -1, 1 } do
			Build.block(model, "Trim", Vector3.new(F - 4, 0.15, 0.8), origin * CFrame.new(0, 0.075, z * (F / 2 - 2.4)), trim)
		end
		for _, x in { -1, 1 } do
			Build.block(model, "Trim", Vector3.new(0.8, 0.15, F - 5.6), origin * CFrame.new(x * (F / 2 - 2.4), 0.075, 0), trim)
		end
		-- Framed pad under the press (resized with the press).
		local pad = Build.block(model, "Pad", Vector3.new(F - 16, 0.12, F - 16), origin * CFrame.new(0, 0.06, 0), theme.pad)
		local padEdge = Instance.new("Model")
		padEdge.Name = "PadEdge"
		padEdge.Parent = model
		local _ = pad
		-- Conveyor from the front edge to the bed.
		local beltLen = F / 2 - 4
		local belt = Build.block(model, "Conveyor", Vector3.new(8, 0.6, beltLen), origin * CFrame.new(0, 0.3, F / 2 - beltLen / 2), theme.dark)
		local _ = belt
		for _, x in { -1, 1 } do
			Build.block(model, "ConveyorRail", Vector3.new(0.8, 0.9, beltLen), origin * CFrame.new(x * 4.4, 0.45, F / 2 - beltLen / 2), Color3.fromRGB(255, 200, 60))
		end
		-- Owner sign at the front left.
		local signModel, signFace = Build.signFrame(model, origin * CFrame.new(-F / 2 + 12, 0, F / 2 - 6), 14, 4, theme.edge)
		signModel.Name = "OwnerSign"
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = signFace
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Text = "Free plot"
		label.Parent = gui
		Style.text(label, 3)
		-- Upgrade board (moved next to the press whenever the press changes size).
		local boardModel, boardFace = Build.signFrame(model, origin, 12, 16, theme.edge)
		boardModel.Name = "Board"
		boardFace.Name = "UpgradeBoard"
		Build.label(boardFace, "⬆️ Upgrades", Color3.fromRGB(255, 225, 120), 10, Vector2.new(14, 3.5))
		model.Parent = root
		local plot: Plot = { index = i, origin = origin, model = model, press = nil, ram = nil, bedTop = 0, ramRestY = 0, tier = 1, owner = nil, sign = label }
		Plots.buildPress(plot, 1)
		table.insert(plots, plot)
	end
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
