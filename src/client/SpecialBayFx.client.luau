--!strict
-- 5 Nov (Willem: "show they are special"): a bay with a Secret or Divine crusher gets
-- its own look, on every plot: a glowing plate on the pedestal (slow pulse), a colour
-- wash up the back wall, rising sparkles, and for Divine two soft light shafts from the
-- top beam. Client-only, no lights; Style.lite() halves the sparkles. Numbers: C.SpecialBay.
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local C = require(RS.Shared.CrusherConfig)
local Style = require(RS.Shared.Kit.Style)

local LITE = Style.lite()
local S = C.SpecialBay
local plots = workspace:WaitForChild("Plots")
local active: { [Model]: { rarity: string, folder: Folder, plaque: Frame? } } = {}
local RunService = game:GetService("RunService")

-- the plaque: a moving colour band behind the plaque text, a shine sweep, a glowing rim
-- the plaque you see on your own plot is a SurfaceGui in PlayerGui adorned to the bay's
-- Panel (so its buttons click); other plots show the Panel's own WorkshopControls
local adorned: { [Instance]: SurfaceGui } = {}
local function plaqueGui(bay: Model): Instance?
	local panel = bay:FindFirstChild("Panel")
	if not panel then return nil end
	local own = adorned[panel]
	if own and own.Parent and own.Enabled then return own end
	local gui = panel:FindFirstChild("WorkshopControls")
	if gui and gui:IsA("SurfaceGui") and gui.Enabled then return gui end
	return own or gui
end
local function plaque(bay: Model, rarity: string): Frame?
	local gui = plaqueGui(bay)
	if not gui then return nil end
	local colors = S.Plaque[rarity]
	local keys = {}
	for i, c in colors do keys[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c) end
	local back = Instance.new("Frame") back.Name = "SpecialPlaque" back.Size = UDim2.fromScale(1, 1)
	back.BorderSizePixel = 0 back.BackgroundColor3 = Color3.new(1, 1, 1) back.ZIndex = 0
	local grad = Instance.new("UIGradient") grad.Name = "Slide" grad.Color = ColorSequence.new(keys) grad.Rotation = 20 grad.Parent = back
	local shine = Instance.new("Frame") shine.Name = "Shine" shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Size = UDim2.fromScale(0.16, 2) shine.Rotation = 20 shine.Position = UDim2.fromScale(-0.3, 0.5)
	shine.BackgroundColor3 = Color3.new(1, 1, 1) shine.BorderSizePixel = 0 shine.ZIndex = 0
	local sg = Instance.new("UIGradient") sg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1) }) sg.Parent = shine
	shine.Parent = back
	back.ClipsDescendants = true
	local rim = Instance.new("UIStroke") rim.Name = "Rim" rim.Thickness = 10 rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = Color3.new(1, 1, 1)
	local rg = Instance.new("UIGradient") rg.Color = ColorSequence.new(keys) rg.Parent = rim
	rim.Parent = back
	back.Parent = gui
	return back
end
local started = os.clock()
RunService.Heartbeat:Connect(function()
	local t = os.clock() - started
	local slide = (t / S.Plaque.SlideSeconds) % 2 - 1 -- -1 .. 1, the band keeps travelling
	local shineX = ((t % S.Plaque.ShineEvery) / S.Plaque.ShineEvery) * 1.8 - 0.4
	for _, entry in active do
		local back = entry.plaque
		if back and back.Parent then
			(back :: any).Slide.Offset = Vector2.new(slide, 0)
			local rim = (back :: any).Rim:FindFirstChildOfClass("UIGradient")
			if rim then rim.Rotation = (t * 60) % 360 end
			if not LITE then (back :: any).Shine.Position = UDim2.fromScale(shineX, 0.5) end
		end
	end
end)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Transparency = transparency
	p.Material = Enum.Material.Neon p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Parent = parent
	return p
end

local function build(bay: Model, rarity: string): Folder
	local look = S[rarity]
	local folder = Instance.new("Folder") folder.Name = "SpecialBayFx"
	local piv = bay:GetPivot()
	local pedestal = bay:FindFirstChild("BayPedestal") :: BasePart?
	local back = bay:FindFirstChild("LockedInset") :: BasePart?
	local top = bay:FindFirstChild("TopBeam") :: BasePart?
	-- 1. glowing plate on the pedestal top, pulsing slowly
	if pedestal then
		local cf = pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + 0.03, 0)
		local plate = part(folder, "Plate", Vector3.new(pedestal.Size.X - 0.3, 0.05, pedestal.Size.Z - 0.3), cf, look.main, S.PlateTransparency[1])
		TweenService:Create(plate, TweenInfo.new(S.PulseSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = S.PlateTransparency[2] }):Play()
		local rim = part(folder, "Rim", Vector3.new(pedestal.Size.X, 0.08, pedestal.Size.Z), cf * CFrame.new(0, -0.01, 0), look.accent, 0.35)
		rim.Material = Enum.Material.Neon
		-- sparkles rising from the plate
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(look.main:Lerp(Color3.new(1, 1, 1), 0.4), look.accent)
		e.LightEmission = 1 e.LightInfluence = 0
		e.Rate = look.sparkles * (if LITE then 0.5 else 1)
		e.Lifetime = NumberRange.new(1.4, 2.4) e.Speed = NumberRange.new(1.5, 3)
		e.Acceleration = Vector3.new(0, 0.6, 0) e.SpreadAngle = Vector2.new(10, 10)
		e.Shape = Enum.ParticleEmitterShape.Box e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.EmissionDirection = Enum.NormalId.Top e.Rotation = NumberRange.new(0, 360) e.RotSpeed = NumberRange.new(-40, 40)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = plate
	end
	-- 2. colour wash up the back wall (fades out towards the top)
	local wallCf = if back then back.CFrame else piv * CFrame.new(0, -1, -8)
	local wallSize = if back then back.Size else Vector3.new(8.4, S.WallHeight, 0.4)
	local wall = part(folder, "Wash", Vector3.new(wallSize.X, wallSize.Y, 0.05), wallCf, look.main, 1)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui") g.Face = face g.LightInfluence = 0 g.Brightness = 2 g.PixelsPerStud = 20
		local f = Instance.new("Frame") f.Size = UDim2.fromScale(1, 1) f.BorderSizePixel = 0 f.BackgroundColor3 = look.main f.Parent = g
		local grad = Instance.new("UIGradient") grad.Rotation = -90
		grad.Color = ColorSequence.new(look.main, look.accent)
		grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.6, 0.85), NumberSequenceKeypoint.new(1, 1) })
		grad.Parent = f
		g.Parent = wall
	end
	-- 3. Divine: two soft light shafts slanting down from the top beam
	if look.shafts and top and pedestal then
		for _, x in { -2.2, 2.2 } do
			local a0 = Instance.new("Attachment") a0.Parent = top a0.Position = Vector3.new(x, -top.Size.Y / 2, 0)
			local a1 = Instance.new("Attachment") a1.Parent = pedestal a1.Position = Vector3.new(x * 0.6, pedestal.Size.Y / 2, 0)
			local b = Instance.new("Beam") b.Attachment0 = a0 b.Attachment1 = a1 b.FaceCamera = true
			b.Width0 = 1.2 b.Width1 = 3 b.LightEmission = 1 b.LightInfluence = 0 b.Segments = 1
			b.Color = ColorSequence.new(Color3.new(1, 1, 1), look.main)
			b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.95) })
			b.Parent = folder
			-- attachments live on the bay parts; remember them for cleanup
			a0:SetAttribute("SpecialBayFx", true) a1:SetAttribute("SpecialBayFx", true)
		end
	end
	folder.Parent = bay
	return folder
end

local function clear(bay: Model)
	local entry = active[bay]
	if entry then entry.folder:Destroy() if entry.plaque then entry.plaque:Destroy() end end
	for _, d in bay:GetDescendants() do if d:IsA("Attachment") and d:GetAttribute("SpecialBayFx") then d:Destroy() end end
	active[bay] = nil
end

local function want(bay: Model): string?
	local plot = bay.Parent
	if plot and plot:GetAttribute("LocalEventHidden") == true then return nil end
	local m = bay:FindFirstChild("EquippedCrusher")
	local rarity = m and m:GetAttribute("Rarity")
	if type(rarity) == "string" and S[rarity] then return rarity end
	return nil
end

-- cheap scan once a second (bays change only on equip / unequip)
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
while true do
	table.clear(adorned)
	for _, g in playerGui:GetDescendants() do
		if g:IsA("SurfaceGui") and g.Adornee then adorned[g.Adornee] = g end
	end
	for _, plot in plots:GetChildren() do
		for _, bay in plot:GetChildren() do
			if bay:IsA("Model") and bay.Name:match("^WorkingBay%d+$") then
				local r = want(bay)
				local entry = active[bay]
				if r and (not entry or entry.rarity ~= r or not entry.folder.Parent) then
					clear(bay)
					active[bay] = { rarity = r, folder = build(bay, r), plaque = plaque(bay, r) }
				elseif not r and entry then
					clear(bay)
				elseif r and entry and (not entry.plaque or entry.plaque.Parent ~= plaqueGui(bay)) then
					-- the plaque gui was rebuilt or moved: put the moving background on the current one
					if entry.plaque then entry.plaque:Destroy() end
					entry.plaque = plaque(bay, r)
				end
			end
		end
	end
	for bay in active do if not bay.Parent then active[bay] = nil end end
	task.wait(1)
end
