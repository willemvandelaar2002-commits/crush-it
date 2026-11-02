--!strict
-- 2 Nov (Willem: "a small cutscene of that crusher and a vision"): a ~4.5 s intro
-- for brand-new players only (tutorial step 1, one crusher), once per join.
--   1. close-up of your own crusher crushing toys        "CRUSH TOYS FOR CASH"
--   2. the camera swoops up: every floor you can still build appears as a gold
--      ghost (local copies of the hidden floors)        "BUILD THE BIGGEST FACTORY!"
--   3. back behind you; the tutorial's first step shows.
-- Purely local: the game keeps running underneath (the crusher already makes
-- scrap). Skip, death or leaving the plot end it at once and restore camera,
-- controls and HUD. Funnel step 2 (Collected scrap) shows if it helps.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local GOLD = Color3.fromRGB(255, 205, 50)
local MAX_GHOSTS = if Style.lite() then 700 else 2400
local LENGTH = 4.6

local playing: any = nil
local done = false

local function controls(): any?
	local module = me:FindFirstChild("PlayerScripts") and me.PlayerScripts:FindFirstChild("PlayerModule")
	if not module then return nil end
	local ok, ctl = pcall(function() return (require(module :: any) :: any):GetControls() end)
	return if ok then ctl else nil
end

local function finish()
	local s = playing
	if not s then return end
	playing = nil
	for _, c in s.connections do c:Disconnect() end
	for _, t in s.tweens do t:Cancel() end
	if s.folder then s.folder:Destroy() end
	if s.gui then s.gui:Destroy() end
	for gui in s.guis do if gui.Parent then gui.Enabled = true end end
	local h = s.held
	if h and h.hum.Parent then
		if h.hum.WalkSpeed == 0 then h.hum.WalkSpeed = h.walk end
		if h.hum.JumpPower == 0 then h.hum.JumpPower = h.jump end
		if h.hum.JumpHeight == 0 then h.hum.JumpHeight = h.height end
	end
	local ctl = controls() if ctl then ctl:Enable() end
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
		cam.CameraSubject = hum or s.subject
		cam.FieldOfView = s.fov
	end
	me:SetAttribute("CutscenePlaying", nil)
end

local function plotModel(): Model?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	return if plot and plot:IsA("Model") then plot else nil
end

-- gold see-through copies of everything that is still hidden (floors to unlock)
local function ghosts(plot: Model, folder: Folder): { BasePart }
	local list: { BasePart } = {}
	local roots: { Instance } = {}
	local banks = plot:FindFirstChild("WorkshopBanks")
	if banks then for _, m in banks:GetChildren() do table.insert(roots, m) end end
	for _, m in plot:GetDescendants() do
		if m:IsA("Model") and m.Name:match("^WorkingBay%d+$") then table.insert(roots, m) end
	end
	for _, root in roots do
		for _, p in root:GetDescendants() do
			if #list >= MAX_GHOSTS then return list end
			if p:IsA("BasePart") and p.Transparency >= 1 then
				local base = p:GetAttribute("BaseT")
				if type(base) == "number" and base < 1 then
					local copy = Instance.new("Part")
					copy.Anchored = true copy.CanCollide = false copy.CanQuery = false copy.CanTouch = false copy.CastShadow = false
					copy.Material = Enum.Material.Neon copy.Color = GOLD copy.Size = p.Size copy.CFrame = p.CFrame
					copy.Transparency = 1 copy.Parent = folder
					table.insert(list, copy)
				end
			end
		end
	end
	return list
end

-- Style.bold keeps the label itself invisible, so the title fades as a CanvasGroup
local function text(gui: ScreenGui, y: number): (TextLabel, CanvasGroup, UIScale)
	local group = Instance.new("CanvasGroup")
	group.AnchorPoint = Vector2.new(0.5, 0.5) group.Position = UDim2.fromScale(0.5, y) group.Size = UDim2.fromScale(0.72, 0.12)
	group.BackgroundTransparency = 1 group.GroupTransparency = 1 group.ZIndex = 4 group.Parent = gui
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 0.85) l.BackgroundTransparency = 1 l.TextScaled = true l.Text = "" l.ZIndex = 4
	l.Parent = group
	Style.bold(l, 5)
	local sc = Instance.new("UIScale") sc.Scale = 0.5 sc.Parent = group
	return l, group, sc
end

local function play()
	local plot = plotModel()
	local cam = workspace.CurrentCamera
	local char = me.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local bay = plot and plot:FindFirstChild("WorkingBay1", true)
	if not plot or not cam or not root or not hum or not bay then return end
	local s: any = { connections = {}, tweens = {}, guis = {}, subject = cam.CameraSubject, fov = cam.FieldOfView }
	playing = s
	me:SetAttribute("CutscenePlaying", true)
	-- hold the character and hide the HUD (both restored in finish)
	s.held = { hum = hum, walk = hum.WalkSpeed, jump = hum.JumpPower, height = hum.JumpHeight }
	hum.WalkSpeed = 0 hum.JumpPower = 0 hum.JumpHeight = 0
	local ctl = controls() if ctl then ctl:Disable() end
	for _, g in me.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then s.guis[g] = true g.Enabled = false end
	end
	local folder = Instance.new("Folder") folder.Name = "IntroCutsceneFx" folder.Parent = workspace
	s.folder = folder

	-- UI: letterbox bars, two titles, Skip
	local gui = Instance.new("ScreenGui") gui.Name = "IntroCutscene" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling gui.Parent = me.PlayerGui
	s.gui = gui
	local function tw(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
		local tween = Tween:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		table.insert(s.tweens, tween) tween:Play()
	end
	local bars = {}
	for i, y in { 0, 1 } do
		local bar = Instance.new("Frame") bar.BorderSizePixel = 0 bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.AnchorPoint = Vector2.new(0, y) bar.Position = UDim2.fromScale(0, y) bar.Size = UDim2.fromScale(1, 0) bar.Parent = gui
		bars[i] = bar
		tw(bar, 0.3, { Size = UDim2.fromScale(1, 0.1) })
	end
	local skip = Instance.new("TextButton") skip.Text = "Skip" skip.TextSize = 30 skip.ZIndex = 5
	skip.AnchorPoint = Vector2.new(1, 1) skip.Position = UDim2.new(1, -24, 1, -22) skip.Size = UDim2.fromOffset(140, 56)
	Style.button(skip, Color3.fromRGB(255, 222, 24))
	skip.Parent = gui
	skip.Activated:Connect(finish)
	local title, titleGroup, titleScale = text(gui, 0.2)
	local function say(words: string, color: Color3)
		title.Text = words title.TextColor3 = color titleGroup.GroupTransparency = 1 titleScale.Scale = 0.5
		tw(titleGroup, 0.25, { GroupTransparency = 0 }) tw(titleScale, 0.4, { Scale = Style.popScale() }, Enum.EasingStyle.Back)
	end

	-- camera shots
	local origin = plot:GetAttribute("Origin") :: CFrame? or plot:GetPivot()
	local bayCf = (bay :: any):GetPivot() :: CFrame
	local focus = bayCf.Position + Vector3.new(0, 2.5, 0)
	local toPlayer = (root.Position - focus) * Vector3.new(1, 0, 1)
	local dir = if toPlayer.Magnitude > 1 then toPlayer.Unit else -origin.LookVector
	local close0 = CFrame.lookAt(focus + dir * 15 + Vector3.new(0, 7, 0), focus)
	local close1 = CFrame.lookAt(focus + dir * 10 + Vector3.new(0, 4.5, 0), focus)
	local plotCf, plotSize = plot:GetBoundingBox()
	local centre = plotCf.Position
	local span = math.max(plotSize.X, plotSize.Z)
	local wideAt = centre + dir * span * 0.72 + Vector3.new(0, span * 0.42, 0)
	local wide = CFrame.lookAt(wideAt, centre + Vector3.new(0, 10, 0))
	local home = CFrame.lookAt(root.Position + Vector3.new(0, 12, 0) + dir * 20, root.Position + Vector3.new(0, 2, 0))
	local startCam = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 62

	local list = ghosts(plot, folder)
	local ghostT = 1
	local function setGhosts(t: number)
		if math.abs(t - ghostT) < 0.02 then return end
		ghostT = t
		for _, p in list do p.Transparency = t end
	end
	local function ease(x: number): number x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end
	local said = 0
	local t0 = os.clock()
	table.insert(s.connections, Run.RenderStepped:Connect(function()
		if playing ~= s then return end
		local t = os.clock() - t0
		-- Studio only: player attribute IntroFreeze = seconds holds that moment (screenshots)
		local freeze = me:GetAttribute("IntroFreeze")
		if Run:IsStudio() and type(freeze) == "number" then t = freeze end
		if t < 0.35 then cam.CFrame = startCam:Lerp(close0, ease(t / 0.35))
		elseif t < 1.7 then cam.CFrame = close0:Lerp(close1, ease((t - 0.35) / 1.35))
		elseif t < 2.7 then cam.CFrame = close1:Lerp(wide, ease((t - 1.7) / 1.0))
		elseif t < 3.7 then cam.CFrame = wide * CFrame.Angles(0, math.rad(4) * math.sin((t - 2.7) * 1.5), 0)
		else cam.CFrame = cam.CFrame:Lerp(home, ease((t - 3.7) / 0.9)) end
		-- the vision: ghost floors glow in while the camera rises, fade on the way back
		if t >= 1.9 and t < 2.6 then setGhosts(1 - 0.45 * ease((t - 1.9) / 0.7))
		elseif t >= 2.6 and t < 3.6 then setGhosts(0.55 + 0.08 * math.sin((t - 2.6) * 8))
		elseif t >= 3.6 then setGhosts(0.55 + 0.45 * ease((t - 3.6) / 0.5)) end
		if said == 0 and t >= 0.3 then said = 1 say("CRUSH TOYS FOR CASH", Color3.fromRGB(140, 255, 110)) end
		if said == 1 and t >= 1.9 then
			said = 2 say("BUILD THE BIGGEST FACTORY!", GOLD)
			local snd = Instance.new("Sound") snd.SoundId = "rbxassetid://" .. Config.Sounds.LevelUp snd.Volume = 0.5 snd.Parent = SoundService
			snd:Play() task.delay(3, function() snd:Destroy() end)
		end
		if said == 2 and t >= 3.7 then
			said = 3
			tw(titleGroup, 0.25, { GroupTransparency = 1 })
			for _, bar in bars do tw(bar, 0.3, { Size = UDim2.fromScale(1, 0) }) end
		end
		if t >= LENGTH then finish() end
	end))
	table.insert(s.connections, hum.Died:Connect(finish))
	table.insert(s.connections, me.CharacterAdded:Connect(finish))
end

-- brand-new players: tutorial step 1 with just the starter crusher
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if done or type(v) ~= "table" then return end
	if v.tutorial ~= 1 or type(v.items) ~= "table" or #v.items > 1 then done = true return end
	done = true
	task.spawn(function()
		-- the character, the plot and the bay models need a moment on a fresh join
		local deadline = os.clock() + 10
		repeat task.wait(0.25)
			local plot = plotModel()
			if plot and plot:FindFirstChild("WorkingBay1", true) and me.Character and me.Character:FindFirstChild("HumanoidRootPart") then break end
		until os.clock() > deadline
		task.wait(0.8)
		if os.clock() <= deadline + 1 then pcall(play) end
		if playing and not playing.connections[1] then finish() end
	end)
end)

-- Studio only: set the player attribute IntroTest to play it again
if Run:IsStudio() then
	me:GetAttributeChangedSignal("IntroTest"):Connect(function() if playing then finish() end pcall(play) end)
end
