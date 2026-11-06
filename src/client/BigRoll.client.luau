--!strict
-- 5 Nov: the big roll cinematic for Secret and up (vault: Reward Moments and
-- Celebrations - a tier ladder; dimming the world and hiding the HUD is kept
-- for the top tiers only; the tell starts only when the roll really is that
-- rare). The server holds that pedestal back for C.BigRoll[rarity].Hold seconds
-- and fires BigRoll to everyone when the flicker ends; the impact here lands on
-- msg.revealAt, the moment the server puts the crusher on the pedestal.
--   Roller: lights out + HUD away -> the odds count up and climb the rarity
--   colours -> Secret: a giant press slams onto the pedestal; Divine: a beam
--   of light comes down with a falling star -> flash, name card, light pillar.
--   Everyone else: a light pillar over that pedestal (and the RarePull banner).
-- Skip: from the second big roll in a session. Reduced Motion: no flash, no shake.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local Config = require(RS.Shared.Config)
local C = require(RS.Shared.CrusherConfig)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)

local me = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local LADDER = { "Rare", "Epic", "Legendary", "Secret", "Divine" }

local function now(): number return workspace:GetServerTimeNow() end
local function colorOf(name: string): Color3
	local r = C.rarity(name)
	return if r then r.color else WHITE
end
local function sound(id: number?, volume: number, speed: number?)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id s.Volume = volume s.PlaybackSpeed = speed or 1
	s.Parent = SoundService s:Play()
	task.delay(6, function() s:Destroy() end)
end
local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = material or Enum.Material.Neon
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	return p
end
local function commas(n: number): string
	local text = tostring(math.max(1, math.floor(n + 0.5)))
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- A tall see-through column of light over the pedestal, seen from across the map.
local function pillar(cf: CFrame, color: Color3, seconds: number)
	-- 5 Nov (Willem: it covered the crusher): the column starts above the crusher, not on the pedestal
	local base = cf.Position + Vector3.new(0, 14, 0)
	local model = Instance.new("Model") model.Name = "BigRollPillar"
	local outer = part("Glow", Vector3.new(260, 7, 7), CFrame.new(base + Vector3.new(0, 130, 0)) * CFrame.Angles(0, 0, math.pi / 2), color)
	outer.Shape = Enum.PartType.Cylinder outer.Transparency = 0.72 outer.Parent = model
	local core = part("Core", Vector3.new(260, 2.4, 2.4), outer.CFrame, color:Lerp(WHITE, 0.6))
	core.Shape = Enum.PartType.Cylinder core.Transparency = 0.5 core.Parent = model
	model.Parent = workspace
	if not GuiService.ReducedMotionEnabled then
		TweenService:Create(outer, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.88, Size = Vector3.new(260, 9, 9) }):Play()
	end
	task.delay(seconds - 1.5, function()
		for _, p in { outer, core } do TweenService:Create(p, TweenInfo.new(1.5), { Transparency = 1 }):Play() end
	end)
	task.delay(seconds, function() model:Destroy() end)
end

local seen: { [string]: boolean } = {}
local playing = false

local function cinematic(msg: any)
	playing = true
	local still = GuiService.ReducedMotionEnabled
	local rarity: string = msg.rarity
	local color = colorOf(rarity)
	local divine = rarity == "Divine"
	-- 5 Nov (Willem): skippable once you've watched this rarity's cinematic before (the server
	-- remembers it in your save); the session table also covers older servers
	local canSkip = msg.canSkip == true or seen[rarity] == true
	seen[rarity] = true
	local P = (msg.at :: CFrame).Position
	local impactIn = math.max(1.6, (msg.revealAt :: number) - now())
	local camera = workspace.CurrentCamera
	local trash: { Instance } = {}
	local conns: { RBXScriptConnection } = {}
	local finished = false

	-- 1. Lights out and the HUD away (restored at the end, whatever happens)
	-- (re-checked every frame: some HUD scripts switch their own gui back on)
	local hidden: { [ScreenGui]: boolean } = {}
	local function hideHud()
		for _, g in me.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "BigRollHud" then g.Enabled = false hidden[g] = true end
		end
	end
	hideHud()
	table.insert(conns, RunService.RenderStepped:Connect(hideHud))
	-- world signs around the pedestal (LOCKED, ??? cards) would clutter the shot
	local signs: { BillboardGui } = {}
	for _, b in workspace:GetDescendants() do
		if b:IsA("BillboardGui") and b.Enabled then
			local adornee = b.Adornee or b.Parent
			local at = if adornee and adornee:IsA("BasePart") then adornee.Position elseif adornee and adornee:IsA("Attachment") then adornee.WorldPosition else nil
			if at and (at - P).Magnitude < 70 then b.Enabled = false table.insert(signs, b) end
		end
	end
	local cc = Instance.new("ColorCorrectionEffect") cc.Name = "BigRollDim" cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.6), { Brightness = -0.32, Saturation = -0.55, Contrast = 0.1, TintColor = WHITE:Lerp(color, 0.15) }):Play()
	sound(Config.Sounds.BoomHit, 0.5, 0.6)

	local gui = Instance.new("ScreenGui") gui.Name = "BigRollHud" gui.IgnoreGuiInset = true gui.DisplayOrder = 60 gui.ResetOnSpawn = false
	gui.Parent = me.PlayerGui table.insert(trash, gui)
	local bars = {}
	for i, y in { 0, 1 } do
		local bar = Instance.new("Frame") bar.BackgroundColor3 = Color3.new(0, 0, 0) bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0, y) bar.Position = UDim2.fromScale(0, y) bar.Size = UDim2.new(1, 0, 0, 0) bar.Parent = gui
		TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, 0.11, 0) }):Play()
		bars[i] = bar
	end
	local odds = Instance.new("TextLabel") odds.Name = "Odds" odds.BackgroundTransparency = 1 odds.AnchorPoint = Vector2.new(0.5, 0.5)
	odds.Position = UDim2.fromScale(0.5, 0.36) odds.Size = UDim2.fromScale(0.8, 0.11) odds.TextScaled = true odds.Text = ""
	odds.TextColor3 = colorOf("Rare") Style.text(odds, 4) odds.Parent = gui
	local title = Instance.new("TextLabel") title.Name = "Rarity" title.BackgroundTransparency = 1 title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.24) title.Size = UDim2.fromScale(0.6, 0.09) title.TextScaled = true title.Text = string.upper(rarity)
	title.TextColor3 = color:Lerp(WHITE, 0.35) title.TextTransparency = 1 Style.text(title, 4) title.Parent = gui
	local titleScale = Instance.new("UIScale") titleScale.Scale = 0.4 titleScale.Parent = title
	local flash = Instance.new("Frame") flash.Size = UDim2.fromScale(1, 1) flash.BackgroundColor3 = WHITE flash.BackgroundTransparency = 1 flash.BorderSizePixel = 0 flash.ZIndex = 5 flash.Parent = gui
	local skip = Instance.new("TextButton") skip.Name = "Skip" skip.AnchorPoint = Vector2.new(1, 1) skip.Position = UDim2.new(1, -24, 1, -24)
	skip.Size = UDim2.fromOffset(150, 52) skip.Text = "Skip" skip.Visible = canSkip skip.ZIndex = 6 skip.Parent = gui
	Style.button(skip, Style.Colors.Gold)
	skip.TextScaled = true Style.text(skip, 2)

	-- the camera looks at the pedestal from its outer side, the roll machine behind it
	-- (from the player's side the machine itself blocks the view)
	local look = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local machine: Vector3? = if typeof(msg.machine) == "Vector3" then msg.machine else nil
	local flat = if machine then Vector3.new(P.X - machine.X, 0, P.Z - machine.Z)
		else (function() local from = if look then look.Position else camera.CFrame.Position return Vector3.new(from.X - P.X, 0, from.Z - P.Z) end)()
	flat = if flat.Magnitude > 1 then flat.Unit else Vector3.new(0, 0, 1)
	local shot = CFrame.lookAt(P + flat * 23 + Vector3.new(0, 8, 0), P + Vector3.new(0, 7, 0))
	local before = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = shot }):Play()
	local shake = 0
	table.insert(conns, RunService.RenderStepped:Connect(function()
		if shake > 0.02 and not still and camera.CameraType == Enum.CameraType.Scriptable and Style.shakeOn() then
			local t = os.clock() * 40
			camera.CFrame = shot * CFrame.new(math.sin(t) * shake, math.cos(t * 1.3) * shake, 0)
			shake *= 0.9
		end
	end))

	-- the pedestal leaks the rarity colour while it waits
	local orb = part("BigRollOrb", Vector3.new(3, 3, 3), CFrame.new(P + Vector3.new(0, 3, 0)), color)
	orb.Shape = Enum.PartType.Ball orb.Transparency = 0.15 orb.Parent = workspace table.insert(trash, orb)
	local light = Instance.new("PointLight") light.Color = color light.Range = 20 light.Brightness = 3 light.Parent = orb
	local started = os.clock()
	table.insert(conns, RunService.Heartbeat:Connect(function()
		if not orb.Parent then return end
		local t = os.clock() - started
		local amp = if still then 0 else math.min(0.6, t * 0.15)
		orb.CFrame = CFrame.new(P + Vector3.new(math.sin(t * 31) * amp, 3 + math.sin(t * 4) * 0.4, math.cos(t * 27) * amp))
		orb.Size = Vector3.one * (3 + math.sin(t * 7) * 0.4 + t * 0.15)
	end))

	-- 2. The odds count up, locking digits left to right, climbing the rarity colours
	local number = commas(tonumber(msg.odds) or 0)
	local final = "1 in " .. number
	local top = table.find(LADDER, rarity) or #LADDER
	local countFrom, countTo = 0.7, math.max(1.4, impactIn - (if divine then 2.6 else 0.9))
	local tier = 0
	table.insert(conns, RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if t < countFrom or finished then return end
		local p = math.clamp((t - countFrom) / (countTo - countFrom), 0, 1)
		local locked = math.floor(p * #number + 0.5)
		local shown = {}
		for i = 1, #number do
			local ch = number:sub(i, i)
			shown[i] = if i <= locked or not ch:match("%d") then ch else tostring(math.random(0, 9))
		end
		odds.Text = "[ 1 in " .. table.concat(shown) .. " ]"
		local nowTier = math.clamp(1 + math.floor(p * top), 1, top)
		if nowTier ~= tier then
			tier = nowTier
			odds.TextColor3 = colorOf(LADDER[tier]):Lerp(WHITE, 0.2)
			sound(Config.Sounds.RevealTick, 0.6, 0.8 + tier * 0.15)
		end
		if p >= 1 and title.TextTransparency == 1 then
			title.TextTransparency = 0
			TweenService:Create(titleScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			sound(Config.Sounds.RevealEpic, 0.7, 0.9)
		end
	end))

	local function impact()
		if orb.Parent then orb:Destroy() end
		sound(Config.Sounds.BoomCrush, 0.9, 0.8) sound(Config.Sounds.RevealBig, 0.8, 1)
		if not still then
			flash.BackgroundTransparency = 0
			TweenService:Create(flash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
			shake = 1.4
		end
		local ring = part("Shockwave", Vector3.new(0.4, 3, 3), CFrame.new(P + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), color)
		ring.Shape = Enum.PartType.Cylinder ring.Transparency = 0.1 ring.Parent = workspace table.insert(trash, ring)
		TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Size = Vector3.new(0.4, 46, 46), Transparency = 1 }):Play()
		local at = Instance.new("Attachment") at.WorldPosition = P + Vector3.new(0, 2, 0) at.Parent = workspace.Terrain table.insert(trash, at)
		local sparks = Instance.new("ParticleEmitter") sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(color:Lerp(WHITE, 0.5), color) sparks.LightEmission = 1 sparks.Rate = 0
		sparks.Speed = NumberRange.new(18, 34) sparks.SpreadAngle = Vector2.new(180, 180) sparks.Lifetime = NumberRange.new(0.6, 1.2)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) }) sparks.Drag = 3
		sparks.Parent = at sparks:Emit(if still then 30 else 90)
	end

	-- 3a. Secret: a giant hydraulic press drops from above and slams onto the pedestal
	-- 3b. Divine: a beam of light breaks through, a star falls down it
	local slamAt = started + impactIn
	if not divine then
		local press = Instance.new("Model") press.Name = "BigRollPress" press.Parent = workspace table.insert(trash, press)
		local high = P + Vector3.new(0, 70, 0)
		local head = part("Head", Vector3.new(13, 4, 13), CFrame.new(high), Color3.fromRGB(96, 100, 116), Enum.Material.DiamondPlate) head.Parent = press
		local rim = part("Rim", Vector3.new(13.6, 1, 13.6), CFrame.new(high - Vector3.new(0, 1.6, 0)), color) rim.Parent = press
		local rod = part("Rod", Vector3.new(60, 3.2, 3.2), CFrame.new(high + Vector3.new(0, 32, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 155, 165), Enum.Material.Metal)
		rod.Shape = Enum.PartType.Cylinder rod.Parent = press
		press.PrimaryPart = head
		-- it comes down into view during the count, hangs shaking over the pedestal, then slams
		local hover = P + Vector3.new(0, 12, 0)
		local value = Instance.new("CFrameValue") value.Value = CFrame.new(high) table.insert(trash, value)
		local jitter = 0
		value.Changed:Connect(function(cf) if press.Parent then press:PivotTo(cf) end end)
		table.insert(conns, RunService.Heartbeat:Connect(function()
			if jitter > 0 and press.Parent and not still then
				press:PivotTo(value.Value * CFrame.new(math.random(-10, 10) / 100 * jitter, 0, math.random(-10, 10) / 100 * jitter))
			end
		end))
		task.delay(0.8, function()
			if finished then return end
			TweenService:Create(value, TweenInfo.new(1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = CFrame.new(hover) }):Play()
			sound(Config.Sounds.Hiss, 0.6, 0.7)
			task.delay(1.3, function() jitter = 1 end)
		end)
		local drop = 0.22
		task.delay(math.max(0, impactIn - drop), function()
			if finished then return end
			jitter = 0
			local landed = CFrame.new(P + Vector3.new(0, 2.6, 0))
			TweenService:Create(value, TweenInfo.new(drop, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = landed }):Play()
			task.delay(drop, function()
				if finished then return end
				impact()
				task.delay(0.5, function()
					if not press.Parent then return end
					TweenService:Create(value, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(high) }):Play()
				end)
			end)
		end)
	else
		local beamTime = 2.4
		task.delay(math.max(0, impactIn - beamTime), function()
			if finished then return end
			local beam = part("BigRollBeam", Vector3.new(220, 0.5, 0.5), CFrame.new(P + Vector3.new(0, 110, 0)) * CFrame.Angles(0, 0, math.pi / 2), color:Lerp(WHITE, 0.3))
			beam.Shape = Enum.PartType.Cylinder beam.Transparency = 0.45 beam.Parent = workspace table.insert(trash, beam)
			TweenService:Create(beam, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = Vector3.new(220, 9, 9) }):Play()
			sound(Config.Sounds.RevealRare, 0.8, 0.6)
			local star = part("Star", Vector3.new(4, 4, 4), CFrame.new(P + Vector3.new(0, 120, 0)), WHITE)
			star.Shape = Enum.PartType.Ball star.Parent = workspace table.insert(trash, star)
			local glow = Instance.new("PointLight") glow.Color = color glow.Range = 40 glow.Brightness = 6 glow.Parent = star
			TweenService:Create(star, TweenInfo.new(beamTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(P + Vector3.new(0, 3, 0)) }):Play()
			task.delay(beamTime, function()
				if finished then return end
				star:Destroy() impact()
				TweenService:Create(beam, TweenInfo.new(1.6), { Size = Vector3.new(220, 0.2, 0.2), Transparency = 1 }):Play()
			end)
		end)
	end

	-- 4. Name card after the impact, then everything back
	local function finish()
		if finished then return end
		finished = true
		for _, c in conns do c:Disconnect() end
		TweenService:Create(cc, TweenInfo.new(0.6), { Brightness = 0, Saturation = 0, Contrast = 0, TintColor = WHITE }):Play()
		task.delay(0.7, function() cc:Destroy() end)
		camera.CFrame = before
		camera.CameraType = Enum.CameraType.Custom
		local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
		if hum then camera.CameraSubject = hum end
		for g in hidden do if g.Parent then g.Enabled = true end end
		for _, b in signs do if b.Parent then b.Enabled = true end end
		for _, x in trash do if x ~= gui then x:Destroy() end end
		gui:Destroy()
		playing = false
	end
	skip.Activated:Connect(finish)
	task.delay(impactIn + 0.25, function()
		if finished then return end
		odds.Text = "[ " .. final .. " ]" odds.TextColor3 = color:Lerp(WHITE, 0.35)
		local card = Instance.new("TextLabel") card.Name = "Card" card.BackgroundTransparency = 1 card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromScale(0.5, 0.78) card.Size = UDim2.fromScale(0.7, 0.09) card.TextScaled = true
		card.Text = tostring(msg.name) card.TextColor3 = WHITE Style.text(card, 4) card.Parent = gui
		local s = Instance.new("UIScale") s.Scale = 0.3 s.Parent = card
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		skip.Visible = true
	end)
	task.delay(impactIn + 3.4, finish)
	task.delay(impactIn + 8, finish) -- safety net
end

Net.event("BigRoll").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" or typeof(msg.at) ~= "CFrame" or type(msg.revealAt) ~= "number" then return end
	local color = colorOf(tostring(msg.rarity))
	-- everyone: the light pillar over that pedestal from the moment it lands
	task.delay(math.max(0, msg.revealAt - now()), function() pillar(msg.at, color, C.BigRoll.PillarSeconds) end)
	if msg.userId == me.UserId and not playing then
		task.spawn(cinematic, msg)
	end
end)
