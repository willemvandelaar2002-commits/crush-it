--!strict
-- The world: 8 plots in two rows of 4 facing a central walkway, each with a
-- floor, an owner sign, a conveyor and a hydraulic press sized for the
-- player's current tier (Config.pressWidth). Plots.buildPress rebuilds the
-- press when the tier changes, so it visibly grows.
--
-- Plot local space: origin at the press centre (floor height), +Z points to the
-- hub. The island runs from z = -Config.Plots.Back (toy factory hall, conveyor
-- start, Mini Press yards) to z = +Config.Plots.Front (bridge, gate, scrap shop,
-- upgrade pads, scrap pile).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local PressBuilder = require(script.Parent.PressBuilder)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local RobuxSigns = require(script.Parent.RobuxSigns)
local ScrapShop = require(script.Parent.ScrapShop)
local Moat = require(script.Parent.Moat)
local PlotDecor = require(script.Parent.PlotDecor)
local Pads = require(script.Parent.Pads)

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
	shop: ScrapShop.Shop, -- the scrap shop inside the gate
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

-- Plots stand round the toy train loop, between the 4 hub walkways (at 0/90/180/270
-- degrees), each one's +Z pointing at the centre.
function Plots.angleFor(index: number): number
	return math.rad(22.5 + (index - 1) * 45)
end

function Plots.originFor(index: number): CFrame
	local P = Config.Plots
	local a = Plots.angleFor(index)
	local out = Vector3.new(math.sin(a), 0, math.cos(a))
	local pos = Vector3.new(0, FLOOR_Y, 0) + out * (P.Ring + P.Front)
	return CFrame.lookAt(pos, pos + out) -- -Z points away from the centre, so +Z faces the hub
end

-- Props (Decor children: heap, crane, bales, boiler, crates, pipe) that the
-- current press overlaps are parked in ServerStorage, and come back when the
-- press is smaller again (after a rebirth). The biggest press is ~104 x 64 studs.
local ServerStorage = game:GetService("ServerStorage")
local function localBox(model: Model, origin: CFrame): (Vector2, Vector2)
	local cf, size = model:GetBoundingBox()
	local lo, hi = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
	for _, sx in { -0.5, 0.5 } do
		for _, sz in { -0.5, 0.5 } do
			local p = origin:PointToObjectSpace((cf * CFrame.new(size.X * sx, 0, size.Z * sz)).Position)
			lo = Vector2.new(math.min(lo.X, p.X), math.min(lo.Y, p.Z))
			hi = Vector2.new(math.max(hi.X, p.X), math.max(hi.Y, p.Z))
		end
	end
	return lo, hi
end

local function clearProps(plot: Plot, press: Model)
	local decor = plot.model:FindFirstChild("Decor")
	if not decor then
		return
	end
	local parkName = "ParkedDecor" .. plot.index
	local park = ServerStorage:FindFirstChild(parkName)
	if not park then
		park = Instance.new("Folder")
		park.Name = parkName
		park.Parent = ServerStorage
	end
	local plo, phi = localBox(press, plot.origin)
	local function overlaps(m: Model): boolean
		local lo, hi = localBox(m, plot.origin)
		return lo.X < phi.X and hi.X > plo.X and lo.Y < phi.Y and hi.Y > plo.Y
	end
	for _, m in decor:GetChildren() do
		if m:IsA("Model") and overlaps(m) then
			m.Parent = park
		end
	end
	for _, m in park:GetChildren() do
		if m:IsA("Model") and not overlaps(m) then
			m.Parent = decor
		end
	end
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
		local size = math.clamp(Config.pressWidth(tier) * 1.9 + 14, 34, math.min(F - 16, 76))
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
	-- Robux signs mirror the board on the left of the press
	local signs = plot.model:FindFirstChild("RobuxSigns") :: Model?
	if signs then
		local W = Config.pressWidth(tier)
		local F = Config.Plots.FloorSize
		local x = math.clamp(W * 0.9 + 15, 21, F / 2 - 13)
		local z = math.clamp(W * 0.3, 4, 30)
		signs:PivotTo(plot.origin * CFrame.new(-x, 0, z) * CFrame.Angles(0, math.rad(25), 0))
	end
	clearProps(plot, built.model)
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
	if Config.Crushers.Enabled then require(script.Parent.CrusherPlots).create(root, Plots) return end
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
	if base and base:IsA("BasePart") then
		-- no invisible floor in the lava sea (Humanoids stand on CanCollide=false parts that can be queried)
		base.CanCollide = false
		base.CanQuery = false
		base.CanTouch = false
		base.CFrame = CFrame.new(0, -500, 0)
	end
	-- Station hub, walkways, the loop road and the toy train (every plot's bridge lands on the loop).
	require(script.Parent.Hub).create(root)

	for i = 1, P.Count do
		local origin = Plots.originFor(i)
		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		model:SetAttribute("Index", i)
		model:SetAttribute("Origin", origin) -- press centre, +Z to the hub (Zone.client)
		local depth = P.Front + P.Back
		local mid = origin * CFrame.new(0, 0, (P.Front - P.Back) / 2)
		-- Raised platform; its top is the plot floor (origin).
		Build.platform(model, "Floor", mid, F, depth, origin.Position.Y - 0.05, theme.platform, theme.grassEdge or theme.edge, 2)
		-- dark asphalt zones (Destroy a Vault): under the upgrade pads and round the scrap pile
		local zr = Random.new(300 + i)
		Build.block(model, "PadZone", Vector3.new(48, 0.1, 30), origin * CFrame.new(35, 0.05, Pads.ROW_Z + 7), theme.pad).CanCollide = false
		Build.patch(model, origin * CFrame.new(0, 0, 30), 30, 30, theme.pad, zr, "PileZone")
		-- Yellow trim just inside the edge (Destroy a Vault style); the plot's own
		-- colour goes on its gate (PlotDecor).
		local trim = theme.trim or FLOOR_COLORS[i]
		for _, z in (if theme.grass then {} else { -1, 1 }) :: { number } do
			Build.block(model, "Trim", Vector3.new(F - 4, 0.15, 0.8), mid * CFrame.new(0, 0.075, z * (depth / 2 - 2.4)), trim)
		end
		for _, x in (if theme.grass then {} else { -1, 1 }) :: { number } do
			Build.block(model, "Trim", Vector3.new(0.8, 0.15, depth - 5.6), mid * CFrame.new(x * (F / 2 - 2.4), 0.075, 0), trim)
		end
		-- Framed pad under the press (resized with the press).
		local pad = Build.block(model, "Pad", Vector3.new(34, 0.12, 34), origin * CFrame.new(0, 0.06, 0), theme.pad)
		local padEdge = Instance.new("Model")
		padEdge.Name = "PadEdge"
		padEdge.Parent = model
		local _ = pad
		-- Conveyor from the toy factory hall at the back to the bed.
		local beltFrom, beltTo = -(P.Back - 10), -4
		local beltLen = beltTo - beltFrom
		local belt = Build.block(model, "Conveyor", Vector3.new(8, 0.6, beltLen), origin * CFrame.new(0, 0.3, (beltFrom + beltTo) / 2), theme.dark)
		local _ = belt
		for _, x in { -1, 1 } do
			Build.block(model, "ConveyorRail", Vector3.new(0.8, 0.9, beltLen), origin * CFrame.new(x * 4.4, 0.45, (beltFrom + beltTo) / 2), Color3.fromRGB(255, 200, 60))
		end
		-- Brick paths: hub bridge -> gate -> scrap pile, with branches into the shop and to the pads
		do
			local fx = Moat.FRONT_BRIDGE_X
			local function pt(x: number, z: number): Vector3
				return (origin * CFrame.new(x, 0, z)).Position
			end
			Build.path(model, pt(fx, P.Front - 1), pt(fx, 44), 7)
			Build.path(model, pt(fx, P.ShopZ), pt(P.ShopX - 1, P.ShopZ), 7)
			Build.path(model, pt(fx, Pads.ROW_Z), pt(12, Pads.ROW_Z), 7)
		end
		-- Gate with the owner's name, boiler, crates, lamps.
		local label = PlotDecor.build(model, origin, FLOOR_COLORS[i], theme, i)
		-- Walk-on buy pads + stats board.
		Pads.build(model, origin)
		-- Upgrade board (moved next to the press whenever the press changes size).
		local boardModel, boardFace = Build.signFrame(model, origin, 12, 16, theme.edge)
		boardModel.Name = "Board"
		boardFace.Name = "UpgradeBoard"
		Build.label(boardFace, "⬆️ Upgrades", Color3.fromRGB(255, 225, 120), 10, Vector2.new(14, 3.5))
		-- Robux signs (moved next to the press like the board)
		RobuxSigns.build(model, theme.edge)
		model.Parent = root
		-- Island body and the bridge to the hub
		Moat.build(model, origin)
		-- Scrap shop just inside the gate on the left, opening toward the centre path
		local shopFrame = origin * CFrame.new(P.ShopX, 0, P.ShopZ) * CFrame.Angles(0, math.rad(90), 0)
		local shop = ScrapShop.build(model, shopFrame, theme)
		require(script.Parent.Helpers).build(model, origin)
		local plot: Plot = { index = i, origin = origin, model = model, press = nil, ram = nil, bedTop = 0, ramRestY = 0, tier = 1, owner = nil, sign = label, shop = shop }
		Plots.buildPress(plot, 1)
		table.insert(plots, plot)
	end
end

-- Where the conveyor starts (at the factory hall door), in world space.
function Plots.beltStart(plot: Plot): CFrame
	return plot.origin * CFrame.new(0, 0.6, -(Config.Plots.Back - 12))
end

-- The bed's top centre (an object's base sits here).
function Plots.bedBase(plot: Plot): CFrame
	return CFrame.new(plot.origin.Position.X, plot.bedTop, plot.origin.Position.Z) * (plot.origin - plot.origin.Position)
end

-- Spawn point just inside the gate, facing the press.
function Plots.spawnFor(plot: Plot): CFrame
	return plot.origin * CFrame.new(Moat.FRONT_BRIDGE_X + 6, 3, Config.Plots.Front - 12)
end

return Plots
