--!strict
-- 11 Nov (Willem: "make the chest reveal more special"): the GEM CHEST in the mine (server/GemMine).
--   everyone near: the lid flies open, a beam of light in the prize's colour, sparkles, then it shuts
--   the opener:    the camera turns to the chest, it shakes and glows brighter in the prize's colour,
--                  bursts open, and the crusher rises on screen on a sunburst with its rarity and name
-- Everything is local (the server only sends what came out). The bigger the rarity, the more of it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Config = require(RS.Shared.Config)
local C = require(RS.Shared.CrusherConfig)
local CrusherIcon = require(script.Parent.CrusherIcon)

local me = Players.LocalPlayer
local remote = Net.event("GemMine")

local function chestModel(): Model?
	local mine = workspace:FindFirstChild("GemMine")
	local m = mine and mine:FindFirstChild("GemChest")
	return if m and m:IsA("Model") then m else nil
end
local function sound(id: number?, volume: number, pitch: number?)
	if not id then return end
	local s = Instance.new("Sound") s.SoundId = "rbxassetid://" .. id s.Volume = volume s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(8, function() if s.Parent then s:Destroy() end end)
end
-- how big the show is: Legendary 1, Exotic 2, Secret 3, Divine (and up) 4
local function tier(rarity: string): number
	local r = C.rarity(rarity)
	local rank = r and r.rank or 4
	return if rank >= 6 then 4 elseif rank >= 5 then 3 elseif rank >= 4.25 then 2 else 1
end

-- the lid and its bands turn about the hinge (attribute Hinge); rest poses kept per part
-- (11 Nov: Willem's model: ChestLid + LidGlow; ChestHitbox is the invisible box facing the platform)
local rests: { [BasePart]: CFrame } = {}
-- (11 Nov: positive = the front edge rises; -115 swung the lid down into the box)
local OPEN_ANGLE = math.rad(100)
local opening = false
local function lidParts(m: Model): { BasePart }
	local out = {}
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "ChestLid" or p.Name == "ChestLidBand" or p.Name == "Lid" or p.Name == "LidGlow") then
			rests[p] = rests[p] or p.CFrame
			table.insert(out, p)
		end
	end
	return out
end
local function setLid(m: Model, parts: { BasePart }, angle: number)
	local hinge = m:GetAttribute("Hinge")
	if typeof(hinge) ~= "CFrame" then return end
	local turn = hinge * CFrame.Angles(angle, 0, 0) * hinge:Inverse()
	for _, p in parts do p.CFrame = turn * rests[p] end
end

-- open (everyone): beam, sparkles, the lid up for a while and back down
local function openChest(rarity: string, hold: number)
	local m = chestModel()
	if not m or opening then return end
	local body = (m:FindFirstChild("ChestHitbox") or m:FindFirstChild("ChestBody")) :: BasePart?
	if not body then return end
	opening = true
	local r = C.rarity(rarity)
	local color = r and r.color or Color3.fromRGB(255, 120, 230)
	local k = tier(rarity)
	local parts = lidParts(m)
	local top = body.Position + Vector3.new(0, body.Size.Y / 2, 0)
	-- beam: a tall neon column that grows and fades
	local beam = Instance.new("Part")
	beam.Name = "ChestBeam" beam.Anchored = true beam.CanCollide = false beam.CanQuery = false beam.CanTouch = false beam.CastShadow = false
	beam.Material = Enum.Material.Neon beam.Color = color beam.Transparency = 0.25 beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(1, 2 + k, 2 + k) beam.CFrame = CFrame.new(top) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = workspace
	local tall = 30 + k * 18
	TweenService:Create(beam, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(tall, 2.5 + k, 2.5 + k), CFrame = CFrame.new(top + Vector3.new(0, tall / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
	local light = Instance.new("PointLight") light.Color = color light.Range = 30 + k * 6 light.Brightness = 3 + k light.Parent = beam
	local att = Instance.new("Attachment") att.Parent = body att.WorldPosition = top
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0 pe.Speed = NumberRange.new(10, 18 + k * 4) pe.Lifetime = NumberRange.new(0.8, 1.6) pe.SpreadAngle = Vector2.new(40, 40)
	pe.Acceleration = Vector3.new(0, -14, 0) pe.LightEmission = 1 pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(Style.lighten(color, 0.4), color) pe.EmissionDirection = Enum.NormalId.Top
	pe.Parent = att
	pe:Emit(30 + k * 25)
	task.spawn(function()
		-- the lid: up fast, a little bounce, held, then down
		local t0 = os.clock()
		while os.clock() - t0 < 0.3 do
			local a = (os.clock() - t0) / 0.3
			setLid(m, parts, OPEN_ANGLE * (1 - (1 - a) ^ 3))
			task.wait()
		end
		setLid(m, parts, OPEN_ANGLE)
		task.wait(hold)
		TweenService:Create(beam, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
		t0 = os.clock()
		while os.clock() - t0 < 0.4 do
			local a = (os.clock() - t0) / 0.4
			setLid(m, parts, OPEN_ANGLE * (1 - a * a))
			task.wait()
		end
		setLid(m, parts, 0)
		task.wait(0.4)
		beam:Destroy() att:Destroy()
		opening = false
	end)
end

-- the opener's show ---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GemChestReveal" gui.ResetOnSpawn = false gui.DisplayOrder = 40 gui.IgnoreGuiInset = true gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = me:WaitForChild("PlayerGui")
local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1) shade.BackgroundColor3 = Color3.new(0, 0, 0) shade.BackgroundTransparency = 1 shade.ZIndex = 1 shade.Parent = gui
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1) flash.BackgroundColor3 = Color3.new(1, 1, 1) flash.BackgroundTransparency = 1 flash.ZIndex = 9 flash.Parent = gui
local stage = Instance.new("Frame")
stage.AnchorPoint = Vector2.new(0.5, 0.5) stage.Position = UDim2.fromScale(0.5, 0.48) stage.Size = UDim2.fromOffset(460, 460)
stage.BackgroundTransparency = 1 stage.ZIndex = 2 stage.Parent = gui
local stageScale = Instance.new("UIScale") stageScale.Parent = stage
local burst = Instance.new("Frame")
burst.AnchorPoint = Vector2.new(0.5, 0.5) burst.Position = UDim2.fromScale(0.5, 0.42) burst.Size = UDim2.fromScale(1.1, 1.1)
burst.BackgroundTransparency = 1 burst.ZIndex = 2 burst.Parent = stage
local iconHolder = Instance.new("Frame")
iconHolder.AnchorPoint = Vector2.new(0.5, 0.5) iconHolder.Position = UDim2.fromScale(0.5, 0.42) iconHolder.Size = UDim2.fromOffset(240, 240)
iconHolder.BackgroundTransparency = 1 iconHolder.ZIndex = 4 iconHolder.Parent = stage
local rarityText = Instance.new("TextLabel")
rarityText.AnchorPoint = Vector2.new(0.5, 0) rarityText.Position = UDim2.fromScale(0.5, 0.72) rarityText.Size = UDim2.new(1.4, 0, 0, 74)
rarityText.BackgroundTransparency = 1 rarityText.TextScaled = true rarityText.ZIndex = 5 rarityText.Parent = stage
Style.text(rarityText, 6)
local nameText = Instance.new("TextLabel")
nameText.AnchorPoint = Vector2.new(0.5, 0) nameText.Position = UDim2.fromScale(0.5, 0.88) nameText.Size = UDim2.new(1.2, 0, 0, 42)
nameText.BackgroundTransparency = 1 nameText.TextScaled = true nameText.ZIndex = 5 nameText.Parent = stage
Style.text(nameText, 4)
local fromText = Instance.new("TextLabel")
fromText.AnchorPoint = Vector2.new(0.5, 1) fromText.Position = UDim2.fromScale(0.5, 0.04) fromText.Size = UDim2.new(1, 0, 0, 34)
fromText.BackgroundTransparency = 1 fromText.TextScaled = true fromText.ZIndex = 5 fromText.Text = "GEM CHEST" fromText.Parent = stage
Style.text(fromText, 3)
fromText.TextColor3 = Color3.fromRGB(255, 170, 245)

local showing = false
local function reveal(typeId: string, rarity: string)
	if showing then return end
	showing = true
	local m = chestModel()
	local body = m and (m:FindFirstChild("ChestHitbox") or m:FindFirstChild("ChestBody")) :: BasePart?
	local r = C.rarity(rarity)
	local color = r and r.color or Color3.fromRGB(255, 120, 230)
	local k = tier(rarity)
	local def = C.typeById(typeId)
	local cam = workspace.CurrentCamera
	local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	local walk = hum and hum.WalkSpeed
	if hum then hum.WalkSpeed = 0 end
	me:SetAttribute("CutscenePlaying", true)
	-- the chest's own "GEM CHEST" label would sit over the prize: hidden meanwhile
	local tags: { BillboardGui } = {}
	if m then for _, b in m:GetDescendants() do if b:IsA("BillboardGui") and b.Enabled then b.Enabled = false table.insert(tags, b) end end end
	-- 1. the camera turns to the chest (its front is the lock side, -Z of the body)
	local camFrom = cam.CFrame
	if body then
		cam.CameraType = Enum.CameraType.Scriptable
		local eye = (body.CFrame * CFrame.new(0, 5.5, -15)).Position
		TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(eye, body.Position + Vector3.new(0, 1.5, 0)) }):Play()
	end
	-- 2. it shakes, glowing brighter in the prize's colour (longer for rarer prizes)
	local glowParts: { BasePart } = {}
	local saved: { [BasePart]: { cf: CFrame, color: Color3 } } = {}
	if m then
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") then saved[p] = { cf = p.CFrame, color = p.Color } end
			if p:IsA("BasePart") and (p.Name == "ChestGlow" or p.Name == "ChestLock" or p.Name == "LidGlow") then table.insert(glowParts, p) end
		end
	end
	sound(Config.Sounds.Roll, 0.6, 0.8)
	local shakeTime = 0.9 + k * 0.25
	local t0 = os.clock()
	task.wait(0.35)
	while m and os.clock() - t0 < shakeTime do
		local a = (os.clock() - t0) / shakeTime
		local amp = 0.06 + a * 0.22
		local off = CFrame.new((math.random() - 0.5) * amp, math.random() * amp * 0.5, (math.random() - 0.5) * amp) * CFrame.Angles(0, 0, (math.random() - 0.5) * amp * 0.12)
		for p, s in saved do if p.Parent and (rests[p] == nil or not opening) then p.CFrame = s.cf * off end end
		for _, p in glowParts do p.Color = saved[p].color:Lerp(color, a) end
		task.wait(0.03)
	end
	for p, s in saved do if p.Parent then p.CFrame = s.cf end end
	-- 3. it bursts open (the lid and beam are openChest, which the server sends everyone too)
	flash.BackgroundTransparency = 0.15
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	sound(if k >= 3 then Config.Sounds.RevealBig else Config.Sounds.RevealEpic, 0.8)
	if k >= 2 then sound(Config.Sounds.BoomHit, 0.5) end
	openChest(rarity, 2.6)
	-- 4. the crusher rises on screen
	gui.Enabled = true
	shade.BackgroundTransparency = 1
	TweenService:Create(shade, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()
	burst:ClearAllChildren()
	Style.sunburst(burst, { color = color, zIndex = 2, count = 10 + k * 2 })
	local rays = burst:FindFirstChild("Sunburst", true) :: Frame?
	for _, c in iconHolder:GetChildren() do c:Destroy() end
	CrusherIcon.new(iconHolder, typeId, { zIndex = 4 })
	rarityText.Text = string.upper(rarity) .. "!"
	rarityText.TextColor3 = Style.lighten(color, 0.2)
	nameText.Text = if def then def.name else typeId
	stageScale.Scale = 0.2
	iconHolder.Position = UDim2.fromScale(0.5, 0.75)
	TweenService:Create(stageScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(iconHolder, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.42) }):Play()
	local spin = true
	task.spawn(function()
		while spin do if rays then rays.Rotation += 0.6 + k * 0.3 end task.wait() end
	end)
	task.wait(2.2 + k * 0.3)
	-- 5. back to the game
	TweenService:Create(stageScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
	TweenService:Create(shade, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	if body then TweenService:Create(cam, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { CFrame = camFrom }):Play() end
	task.wait(0.5)
	spin = false
	gui.Enabled = false
	for p, s in saved do if p.Parent and p.Name ~= "ChestLid" and p.Name ~= "ChestLidBand" and p.Name ~= "LidGlow" then p.Color = s.color end end
	for _, p in glowParts do if saved[p] then p.Color = saved[p].color end end
	cam.CameraType = Enum.CameraType.Custom
	if hum and walk then hum.WalkSpeed = walk end
	me:SetAttribute("CutscenePlaying", nil)
	for _, b in tags do if b.Parent then b.Enabled = true end end
	showing = false
end

remote.OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" then return end
	if msg.kind == "chestReveal" and type(msg.type) == "string" and type(msg.rarity) == "string" then
		task.spawn(reveal, msg.type, msg.rarity)
	elseif msg.kind == "chestOpen" and msg.by ~= me.UserId and type(msg.rarity) == "string" then
		openChest(msg.rarity, 1.6) -- (the opener's own chest opens inside the reveal)
	end
end)
