--!strict
-- 8 Nov (Willem: "your factory keeps running" + "something that finishes overnight";
-- Shared/CrateConfig, server/OvernightCrate):
--   * Crate signs: every MysteryCrate model shows "MYSTERY CRATE" and its countdown, or
--     "READY! OPEN ME" (bouncing) once it can be opened.
--   * Cards (Willem's come-back frame, bottom middle, never blocking):
--       - the crate ARRIVED (after the tutorial): opens in 8 hours, come back
--       - the crate OPENED: what you got, next one in 20 hours
--       - AWAY card, once per session after CrateConfig.Away.AfterMinutes of play: your
--         factory keeps earning while you're away (Store.Offline) + when the crate opens
--     REMIND ME (Roblox's notification opt-in) shows when Roblox lets us ask.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Tags = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local N = require(RS.Shared.NotifyConfig)
local K = require(RS.Shared.CrateConfig)
local Store = require(RS.Shared.Store)
local Format = require(RS.Shared.Format)
local C2 = require(RS.Shared.CrusherConfig)

local me = Players.LocalPlayer
local rgb = Color3.fromRGB

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, z: number, max: number, color: Color3?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z }, parent)
	Style.text(l, 2.5)
	l.TextColor3 = color or Color3.new(1, 1, 1)
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = max }, l)
	return l
end
local function timeLeft(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h, m = seconds // 3600, (seconds % 3600) // 60
	if h > 0 then return string.format("%dh %dm", h, m) end
	return string.format("%dm %ds", m, seconds % 60)
end

-- crate signs ------------------------------------------------------------------------
local function sign(model: Instance)
	local body = model:WaitForChild("Body", 10)
	local bb = body and body:WaitForChild("Sign", 10) :: BillboardGui?
	if not bb then return end
	local title = words(bb, "MYSTERY CRATE", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.48), 2, 30, rgb(255, 215, 80))
	local timer = words(bb, "", UDim2.fromScale(0, 0.5), UDim2.fromScale(1, 0.46), 2, 28)
	local mine = model:GetAttribute("Owner") == me.UserId
	if not mine then title.Text = tostring(model:GetAttribute("OwnerName")) .. "'s CRATE" end
	task.spawn(function()
		while model.Parent do
			local at = tonumber(model:GetAttribute("ReadyAt"))
			if at then
				local left = at - Workspace:GetServerTimeNow()
				if left <= 0 then
					timer.Text = if mine then "READY! OPEN ME" else "READY!"
					timer.TextColor3 = rgb(110, 255, 120)
					bb.StudsOffsetWorldSpace = Vector3.new(0, 4.8 + math.abs(math.sin(os.clock() * 3)) * 0.6, 0)
				else
					timer.Text = "Opens in " .. timeLeft(left)
					timer.TextColor3 = Color3.new(1, 1, 1)
				end
			end
			task.wait(if at and at - Workspace:GetServerTimeNow() <= 0 then 0.05 else 1)
		end
	end)
end

-- crate animations (8 Nov, Willem: "very interesting with an animation dropping") -----
-- Everything here moves the model on this client only (the server never moves it), from
-- the attributes DropAt / OpenedAt + OpenRarity (CrateConfig.Drop / Open).
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local function rarityColor(name: string?): Color3
	local r = name and C2.rarity(name)
	return if r then r.color else rgb(255, 215, 80)
end
local function fx(class: string, props: { [string]: any }): any
	local n = make(class, props, nil)
	if n:IsA("BasePart") then n.Anchored = true n.CanCollide = false n.CanQuery = false n.CanTouch = false n.CastShadow = false end
	n.Parent = Workspace
	return n
end
local function ring(at: Vector3, color: Color3, size: number, time: number)
	local r = fx("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2), CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color, Material = Enum.Material.Neon, Transparency = 0.2 })
	TweenService:Create(r, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, size, size), Transparency = 1 }):Play()
	Debris:AddItem(r, time + 0.1)
end
local function shake(strength: number, time: number)
	if not Style.shakeOn() then return end
	local cam = Workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = 1 - (os.clock() - t0) / time
		if k <= 0 then conn:Disconnect() return end
		cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * strength * k, (math.random() - 0.5) * strength * k, 0)
	end)
end
type Crate = { home: CFrame, parts: { [BasePart]: number }, busy: boolean }
local crates: { [Model]: Crate } = {}
local function setVisible(c: Crate, on: boolean)
	for part, t in c.parts do part.LocalTransparencyModifier = if on then 0 else 1 end
	for part in c.parts do
		for _, g in part:GetChildren() do
			if g:IsA("SurfaceGui") or g:IsA("BillboardGui") then g.Enabled = on end
		end
	end
end
local function near(pos: Vector3, dist: number): boolean
	local ch = me.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - pos).Magnitude < dist
end
-- the owner's camera flies to the crate (8 Nov), then back to the player
local camBusy = false
local lastBurst = -100
local function lookAtCrate(c: Crate, seconds: number): (() -> ())?
	local cam = Workspace.CurrentCamera
	if camBusy or Style.hasModal() or me:GetAttribute("CutscenePlaying") == true or cam.CameraType ~= Enum.CameraType.Custom then return nil end
	camBusy = true
	me:SetAttribute("CutscenePlaying", true)
	local Q = K.Camera
	local target = c.home.Position + Vector3.new(0, 3, 0)
	-- from the player's side of the crate, so they see where it is
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local from = if root then (root.Position - target) * Vector3.new(1, 0, 1) else c.home.LookVector
	if from.Magnitude < 0.1 then from = c.home.LookVector end
	local eye = target + from.Unit * Q.Distance + Vector3.new(0, Q.Height, 0)
	local start = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(Q.Move, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(eye, target) }):Play()
	local done = false
	local function back()
		if done then return end
		done = true
		local t = TweenService:Create(cam, TweenInfo.new(Q.Move, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = start })
		t:Play()
		t.Completed:Wait()
		cam.CameraType = Enum.CameraType.Custom
		me:SetAttribute("CutscenePlaying", nil)
		camBusy = false
	end
	task.delay(seconds + 8, back) -- safety
	return back
end
local function drop(m: Model, c: Crate)
	local D = K.Drop
	c.busy = true
	setVisible(c, false)
	m:PivotTo(c.home)
	local ground = c.home.Position
	-- (the refill right after an opening stays in the normal view: one zoom is enough)
	local mine = m:GetAttribute("Owner") == me.UserId and os.clock() - lastBurst > 12
	if mine then -- (wait a little for a goal celebration / window to finish, so you see it)
		local cam = Workspace.CurrentCamera
		for _ = 1, 40 do
			if not (camBusy or Style.hasModal() or me:GetAttribute("CutscenePlaying") == true or cam.CameraType ~= Enum.CameraType.Custom) then break end
			task.wait(0.25)
		end
	end
	local back = if mine then lookAtCrate(c, D.Warn + D.Fall + 1) else nil
	if back then task.wait(K.Camera.Move * 0.7) end
	-- a warning ring where it will land
	ring(ground + Vector3.new(0, 0.2, 0), rgb(255, 215, 80), 12, D.Warn)
	local beam = fx("Part", { Size = Vector3.new(1.2, D.Height, 1.2), CFrame = CFrame.new(ground + Vector3.new(0, D.Height / 2, 0)),
		Color = rgb(255, 215, 80), Material = Enum.Material.Neon, Transparency = 0.6 })
	TweenService:Create(beam, TweenInfo.new(D.Warn + D.Fall), { Transparency = 1, Size = Vector3.new(0.2, D.Height, 0.2) }):Play()
	Debris:AddItem(beam, D.Warn + D.Fall + 0.1)
	task.wait(D.Warn)
	setVisible(c, true)
	local t0 = os.clock()
	while true do
		local k = math.min(1, (os.clock() - t0) / D.Fall)
		local y = D.Height * (1 - k * k) -- falls faster and faster
		m:PivotTo(c.home * CFrame.new(0, y, 0) * CFrame.Angles(0, (1 - k) * 4, 0))
		if k >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	-- impact: squash bounce, dust ring, shake if close
	ring(ground + Vector3.new(0, 0.3, 0), rgb(255, 255, 255), 22, 0.6)
	ring(ground + Vector3.new(0, 0.3, 0), rgb(255, 200, 60), 14, 0.45)
	if near(ground, 60) then shake(0.9, 0.35) end
	local t1 = os.clock()
	while os.clock() - t1 < 0.45 do -- two little bounces
		local k = (os.clock() - t1) / 0.45
		m:PivotTo(c.home * CFrame.new(0, math.abs(math.sin(k * math.pi * 2)) * 1.4 * (1 - k), 0))
		RunService.RenderStepped:Wait()
	end
	m:PivotTo(c.home)
	c.busy = false
	if back then task.wait(K.Camera.Hold) back() end
end
local function burst(m: Model, c: Crate, rarity: string?)
	local O = K.Open
	c.busy = true
	local color = rarityColor(rarity)
	local home = c.home
	if m:GetAttribute("Owner") == me.UserId then lastBurst = os.clock() end
	local back = if m:GetAttribute("Owner") == me.UserId then lookAtCrate(c, O.Shake + O.Burst) else nil
	if back then task.wait(K.Camera.Move * 0.7) end
	-- 1) it rattles
	local t0 = os.clock()
	while os.clock() - t0 < O.Shake do
		local k = (os.clock() - t0) / O.Shake
		m:PivotTo(home * CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(math.sin(os.clock() * 60) * 6 * k), 0, math.rad(math.cos(os.clock() * 55) * 6 * k)))
		RunService.RenderStepped:Wait()
	end
	m:PivotTo(home)
	-- 2) the lid flies off, a beam in the rarity's colour, sparks
	local lid = m:FindFirstChild("Lid") :: BasePart?
	local top = home.Position + Vector3.new(0, 6, 0)
	if lid then
		local ghost = lid:Clone()
		ghost.Anchored = true ghost.CanCollide = false
		for _, g in ghost:GetChildren() do g:Destroy() end
		ghost.Parent = Workspace
		lid.LocalTransparencyModifier = 1
		TweenService:Create(ghost, TweenInfo.new(O.Burst, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = ghost.CFrame * CFrame.new(math.random(-8, 8), 26, math.random(-8, 8)) * CFrame.Angles(math.rad(540), math.rad(300), 0), Transparency = 1 }):Play()
		Debris:AddItem(ghost, O.Burst + 0.1)
	end
	local beam = fx("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(80, 1, 1), CFrame = CFrame.new(top + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color, Material = Enum.Material.Neon, Transparency = 0.1 })
	TweenService:Create(beam, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = Vector3.new(80, 7, 7) }):Play()
	task.delay(0.35, function() TweenService:Create(beam, TweenInfo.new(O.Burst), { Size = Vector3.new(80, 0.5, 0.5), Transparency = 1 }):Play() end)
	Debris:AddItem(beam, O.Burst + 0.5)
	ring(top, color, 26, 0.7)
	local spark = fx("Part", { Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(top), Transparency = 1 })
	local emitter = make("ParticleEmitter", { Color = ColorSequence.new(color, Color3.new(1, 1, 1)), LightEmission = 1, Size = NumberSequence.new(0.9, 0),
		Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(22, 40), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -30, 0),
		Rate = 0 }, spark)
	emitter:Emit(if Style.lite() then 40 else 90)
	Debris:AddItem(spark, 2)
	if near(top, 60) then shake(0.6, 0.3) end
	-- 3) the crate is gone until the next one drops
	task.wait(0.5)
	setVisible(c, false)
	if lid then lid.LocalTransparencyModifier = 0 end
	c.busy = false
	if back then task.wait(K.Camera.Hold * 0.6) back() end
end
local function watch(m: Model)
	local body = m:WaitForChild("Body", 10)
	if not body then return end
	local c: Crate = { home = m:GetPivot(), parts = {}, busy = false }
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then c.parts[d] = d.Transparency end end
	crates[m] = c
	local lastDrop, lastOpen = 0, 0
	local function check()
		local now = Workspace:GetServerTimeNow()
		local openedAt = tonumber(m:GetAttribute("OpenedAt")) or 0
		if openedAt > lastOpen and now - openedAt < 4 then
			lastOpen = openedAt
			task.spawn(burst, m, c, m:GetAttribute("OpenRarity"))
		end
		local dropAt = tonumber(m:GetAttribute("DropAt")) or 0
		if dropAt > lastDrop and now - dropAt < 4 then
			lastDrop = dropAt
			task.spawn(function()
				while Workspace:GetServerTimeNow() < dropAt or c.busy do
					if Workspace:GetServerTimeNow() < dropAt and not c.busy then setVisible(c, false) end
					task.wait()
				end
				drop(m, c)
			end)
		end
	end
	m:GetAttributeChangedSignal("OpenedAt"):Connect(check)
	m:GetAttributeChangedSignal("DropAt"):Connect(check)
	check()
	m.AncestryChanged:Connect(function() if not m.Parent then crates[m] = nil end end)
end

for _, m in Tags:GetTagged("MysteryCrate") do task.spawn(sign, m) task.spawn(watch, m) end
Tags:GetInstanceAddedSignal("MysteryCrate"):Connect(function(m) task.spawn(sign, m) task.spawn(watch, m) end)

-- the card ---------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "CrateHud", ResetOnSpawn = false, DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local ART = { Frame = "rbxassetid://133183009079484" } -- Willem's come-back frame (4 Nov)
local card = make("Frame", { Name = "CrateCard", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(460, 178),
	BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
make("ImageLabel", { Name = "Frame", Image = ART.Frame, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 2 }, card)
local icon = words(card, "🎁", UDim2.fromOffset(22, 30), UDim2.fromOffset(118, 118), 3, 90)
local fit = Style.phoneFit(card, { scale = 0.8, width = 0.7 })
local pop = make("UIScale", { Scale = 1 }, card)
fit.Parent = nil -- (read only: one UIScale per object)
local title = words(card, "", UDim2.fromOffset(150, 14), UDim2.fromOffset(292, 30), 3, 28, rgb(120, 220, 255))
local line1 = words(card, "", UDim2.fromOffset(150, 46), UDim2.fromOffset(292, 32), 3, 26)
local line2 = words(card, "", UDim2.fromOffset(150, 78), UDim2.fromOffset(292, 24), 3, 20, rgb(255, 225, 120))
local function button(text: string, x: number, w: number, color: Color3): TextButton
	local b = make("TextButton", { Text = "", Position = UDim2.fromOffset(x, 112), Size = UDim2.fromOffset(w, 50), ZIndex = 3 }, card)
	Style.button(b, color)
	words(b, text, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 4, 28)
	return b
end
local remind = button("REMIND ME", 150, 160, rgb(60, 200, 80))
local ok = button("OK", 318, 110, rgb(64, 140, 255))
task.spawn(function()
	while true do
		if card.Visible then icon.Rotation = math.sin(os.clock() * 2) * 6 end
		task.wait()
	end
end)

local function canPrompt(): boolean
	if N.DailyReady == "" then return false end
	local okCall, can = pcall(function() return ExperienceNotificationService:CanPromptOptInAsync() end)
	return okCall and can == true
end
local token = 0
local function hide()
	token += 1
	if not card.Visible then return end
	local t = TweenService:Create(pop, TweenInfo.new(0.15), { Scale = 0.8 * fit.Scale })
	t:Play()
	t.Completed:Once(function() card.Visible = false end)
end
local function show(emoji: string, head: string, a: string, b: string, ask: boolean)
	-- (wait while another window or the come-back card is up)
	local come = me.PlayerGui:FindFirstChild("ComeBackHud")
	for _ = 1, 60 do
		local busy = Style.hasModal() or (come ~= nil and (come:FindFirstChild("ComeBack") :: GuiObject?) ~= nil and (come:FindFirstChild("ComeBack") :: GuiObject).Visible)
		if not busy then break end
		task.wait(1)
	end
	ask = ask and canPrompt()
	icon.Text = emoji title.Text = head line1.Text = a line2.Text = b
	line1.TextColor3 = Color3.new(1, 1, 1)
	remind.Visible = ask
	ok.Position = if ask then UDim2.fromOffset(318, 112) else UDim2.fromOffset(240, 112)
	card.Visible = true
	pop.Scale = 0.7 * fit.Scale
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = fit.Scale }):Play()
	token += 1
	local mine = token
	task.delay(if ask then K.Away.Seconds * 2 else K.Away.Seconds, function() if token == mine then hide() end end)
end
ok.Activated:Connect(hide)
remind.Activated:Connect(function()
	hide()
	pcall(function() ExperienceNotificationService:PromptOptIn() end)
end)

Net.event("Crate").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" then return end
	if msg.arrived then
		task.delay(K.Drop.Warn + K.Drop.Fall + K.Camera.Move * 2 + K.Camera.Hold + 2.5, function() -- after it landed and the camera is back
			show("🎁", "A MYSTERY CRATE ARRIVED!", "It opens in " .. K.FirstHours .. " hours", "Free crusher inside, up to SECRET!", true)
		end)
	elseif type(msg.opened) == "table" then
		local o = msg.opened
		task.delay(K.Open.Shake + 0.9 + K.Camera.Move * 2 + K.Camera.Hold * 0.6, function() -- after the lid blows off and the camera is back
			show("🎉", "MYSTERY CRATE OPENED!", tostring(o.name) .. " (" .. tostring(o.rarity) .. ")", "+" .. tostring(o.cash) .. "  ·  next crate in " .. K.Hours .. "h", false)
			line1.TextColor3 = rarityColor(o.rarity):Lerp(Color3.new(1, 1, 1), 0.25)
		end)
	end
end)

-- the away card: once per session, after a while of play ---------------------------
task.spawn(function()
	local joined = os.clock()
	while os.clock() - joined < K.Away.AfterMinutes * 60 do task.wait(5) end
	-- only after the tutorial (the crate exists then)
	while me:GetAttribute("CrateReadyAt") == nil do task.wait(5) end
	while Style.hasModal() or me:GetAttribute("CutscenePlaying") == true do task.wait(2) end
	local rate = tonumber(me:GetAttribute("CashRate")) or 0
	local hours = if Store.hasPass(me, "VIP") then Store.Vip.OfflineHours else Store.Offline.MaxHours
	local most = C2.money(rate * Store.Offline.Share * hours * 3600)
	local at = tonumber(me:GetAttribute("CrateReadyAt")) or 0
	local left = at - Workspace:GetServerTimeNow()
	local crateLine = if left > 0 then "Mystery Crate opens in " .. timeLeft(left) else "Your Mystery Crate is READY to open!"
	show("🏭", "YOUR FACTORY NEVER STOPS", "Earns up to " .. Format.cash(most) .. " while you're away", crateLine, true)
end)
