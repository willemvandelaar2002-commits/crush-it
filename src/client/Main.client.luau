--!strict
-- Crush It HUD: cash, the object on your press (name + HP bar), a big CRUSH
-- button (hold it, or hold F / gamepad R2), and the upgrade cards (Power,
-- Speed, Value, Size). Plus the feel: press sounds, sparks, camera shake on
-- your own press and floating "+$X" when something gets flattened.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Objects = require(ReplicatedStorage.Shared.Objects)

local player = Players.LocalPlayer
local CrushRemote = Net.event("Crush")
local BuyRemote = Net.event("BuyUpgrade")

local FONT = Enum.Font.FredokaOne
local DARK = Color3.fromRGB(28, 30, 38)
local GREEN = Color3.fromRGB(80, 200, 110)
local RED = Color3.fromRGB(230, 80, 70)
local GREY = Color3.fromRGB(110, 112, 120)
local GOLD = Color3.fromRGB(255, 200, 50)

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local i = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(i :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = i
	end
	if props.Parent then
		i.Parent = props.Parent
	end
	return i
end

local function corner(r: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(t: number): UIStroke
	return make("UIStroke", { Thickness = t, Color = Color3.new(0, 0, 0), Transparency = 0.2 })
end

local gui = make("ScreenGui", { Name = "CrushHud", ResetOnSpawn = false, IgnoreGuiInset = false, Parent = player:WaitForChild("PlayerGui") })

-- Cash (top centre) ----------------------------------------------------------
local cashLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(260, 50),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = GREEN, Text = "$0", Parent = gui,
}, { stroke(3) })

local multLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 4, 0.5, 0), Size = UDim2.fromOffset(90, 24),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = GOLD, Text = "", Parent = cashLabel,
}, { stroke(2) })

-- Object + HP bar (under the cash) -------------------------------------------
local objFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(260, 44),
	BackgroundTransparency = 1, Parent = gui,
})
local objName = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = objFrame,
}, { stroke(2) })
local hpBack = make("Frame", {
	Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = DARK, Parent = objFrame,
}, { corner(8), stroke(2) })
local hpFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = RED, Parent = hpBack }, { corner(8) })

-- CRUSH button (bottom right) -------------------------------------------------
local crushButton = make("TextButton", {
	Name = "CrushButton",
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(150, 150),
	BackgroundColor3 = RED, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "CRUSH",
	AutoButtonColor = false, Parent = gui,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 5, Color = Color3.fromRGB(120, 20, 20) }), make("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }) })
local keyHint = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(150, 18),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "hold  [F]",
	Parent = crushButton,
}, { stroke(1.5) })
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	keyHint.Visible = false
	crushButton.Position = UDim2.new(1, -16, 1, -110)
	crushButton.Size = UDim2.fromOffset(120, 120)
end

-- Holding ---------------------------------------------------------------------
local holds = 0 -- button / key / gamepad can all hold at once
local function setHold(delta: number)
	holds = math.max(0, holds + delta)
	crushButton.BackgroundColor3 = if holds > 0 then Color3.fromRGB(190, 50, 45) else RED
end
crushButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setHold(1)
		local c
		c = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				c:Disconnect()
				setHold(-1)
			end
		end)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
		setHold(1)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
		setHold(-1)
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	holds = 0
	setHold(0)
end)
task.spawn(function()
	while true do
		if holds > 0 then
			CrushRemote:FireServer() -- the server enforces the Speed cooldown
		end
		task.wait(0.1)
	end
end)

-- Upgrades (left side) ------------------------------------------------------
local panel = make("Frame", {
	Name = "Upgrades",
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(230, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
local panelScale = make("UIScale", { Parent = panel })
local function fitPanel()
	local h = Workspace.CurrentCamera.ViewportSize.Y
	panelScale.Scale = math.clamp((h - 150) / 400, 0.55, 1)
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
fitPanel()

type Card = { frame: Frame, title: TextLabel, info: TextLabel, buy: TextButton, id: string }
local cards: { Card } = {}

local function makeCard(id: string, order: number): Card
	local frame = make("Frame", { Name = "Card_" .. id, Size = UDim2.fromOffset(230, 70), BackgroundColor3 = DARK, BackgroundTransparency = 0.15, LayoutOrder = order, Parent = panel }, { corner(10), stroke(2) })
	local title = make("TextLabel", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -110, 0, 26), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Parent = frame })
	local info = make("TextLabel", { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -110, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 210), Parent = frame })
	local buy = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(92, 52), BackgroundColor3 = GREEN, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true, Parent = frame }, { corner(8), stroke(2), make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
	local confirmUntil = 0
	buy.Activated:Connect(function()
		if id == "Rebirth" then
			-- Two taps: the first one asks "SURE?".
			if os.clock() > confirmUntil then
				confirmUntil = os.clock() + 3
				buy.Text = "SURE?"
				task.delay(3, function()
					if os.clock() >= confirmUntil then
						buy.Text = ""
						buy:SetAttribute("Refresh", os.clock())
					end
				end)
				return
			end
			confirmUntil = 0
			buy.Text = ""
		end
		BuyRemote:FireServer(id)
	end)
	local card = { frame = frame, title = title, info = info, buy = buy, id = id }
	table.insert(cards, card)
	return card
end

for i, u in Config.Upgrades do
	makeCard(u.id, i)
end
makeCard("Size", #Config.Upgrades + 1)
local rebirthCard = makeCard("Rebirth", #Config.Upgrades + 2)
rebirthCard.title.TextColor3 = GOLD

local function fmtEffect(id: string, v: number): string
	if id == "Power" then
		return (if v < 100 then string.format("%.1f", v) else Format.compact(v)) .. " dmg"
	elseif id == "Speed" then
		return string.format("%.2fs", v)
	else
		return string.format("x%.1f", v)
	end
end

local function refresh()
	local cash = (player:GetAttribute("Cash") :: number?) or 0
	local tier = (player:GetAttribute("Tier") :: number?) or 1
	cashLabel.Text = Format.cash(cash)
	for _, card in cards do
		local cost: number?
		if card.id == "Rebirth" then
			local r = (player:GetAttribute("Rebirths") :: number?) or 0
			local need = Config.Rebirth.RequiredTier(r)
			card.title.Text = "Rebirth" .. (if r > 0 then "  (" .. r .. ")" else "")
			if card.buy.Text == "SURE?" then
				continue
			end
			if tier >= need then
				card.info.Text = string.format("Cash x%.1f → x%.1f", Config.rebirthMult(r), Config.rebirthMult(r + 1))
				card.buy.Text = "REBIRTH"
				card.buy.BackgroundColor3 = GOLD
			else
				card.info.Text = "Reach the " .. Config.Objects[need].name
				card.buy.Text = "LOCKED"
				card.buy.BackgroundColor3 = GREY
			end
			continue
		elseif card.id == "Size" then
			local maxed = tier >= Config.MaxTier
			card.title.Text = "Bigger Press"
			card.info.Text = if maxed then "Biggest press!" else "Next: " .. Config.Objects[tier + 1].name
			cost = if maxed then nil else Config.SizeCost(tier)
		else
			local u
			for _, x in Config.Upgrades do
				if x.id == card.id then
					u = x
				end
			end
			local lv = (player:GetAttribute(card.id .. "Lv") :: number?) or 0
			card.title.Text = u.title .. "  Lv " .. lv
			if lv >= u.max then
				card.info.Text = fmtEffect(u.id, u.effect(lv)) .. " (max)"
				cost = nil
			else
				local now, nxt = fmtEffect(u.id, u.effect(lv)), fmtEffect(u.id, u.effect(lv + 1))
				card.info.Text = string.gsub(now, " dmg", "") .. " → " .. nxt
				cost = u.cost(lv)
			end
		end
		if cost then
			card.buy.Text = Format.cash(cost)
			card.buy.BackgroundColor3 = if cash >= cost then GREEN else GREY
			card.buy.Active = true
		else
			card.buy.Text = "MAX"
			card.buy.BackgroundColor3 = GREY
			card.buy.Active = false
		end
	end
	local hp = (player:GetAttribute("Hp") :: number?) or 0
	local maxHp = (player:GetAttribute("MaxHp") :: number?) or 1
	local variant = (player:GetAttribute("ObjVariant") :: string?) or "Normal"
	local vdef = Config.VariantById[variant]
	objName.Text = (if variant ~= "Normal" then string.upper(variant) .. " " else "") .. ((player:GetAttribute("ObjName") :: string?) or "") .. "  " .. Format.compact(math.ceil(hp)) .. " HP"
	objName.TextColor3 = if vdef and vdef.text then vdef.text else Color3.new(1, 1, 1)
	local mult = (player:GetAttribute("CashMult") :: number?) or 1
	multLabel.Text = if mult > 1.001 then string.format("x%.2f", mult) else ""
	TweenService:Create(hpFill, TweenInfo.new(0.12), { Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1) }):Play()
end

for _, name in { "Cash", "Tier", "PowerLv", "SpeedLv", "ValueLv", "Hp", "MaxHp", "ObjName", "ObjVariant", "Rebirths", "CashMult" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
rebirthCard.buy:GetAttributeChangedSignal("Refresh"):Connect(refresh)

-- Cash pop when it goes up
local lastCash = (player:GetAttribute("Cash") :: number?) or 0
player:GetAttributeChangedSignal("Cash"):Connect(function()
	local cash = (player:GetAttribute("Cash") :: number?) or 0
	if cash > lastCash then
		cashLabel.Size = UDim2.fromOffset(300, 58)
		TweenService:Create(cashLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(260, 50) }):Play()
	end
	lastCash = cash
end)

-- Notices -------------------------------------------------------------------
local noticeLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(320, 30),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(255, 220, 90), Text = "",
	TextTransparency = 1, Parent = gui,
}, { stroke(2) })
local noticeStroke = noticeLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
Net.event("Notice").OnClientEvent:Connect(function(msg)
	noticeLabel.Text = msg.text
	noticeLabel.TextTransparency = 0
	noticeStroke.Transparency = 0.2
	task.delay(1.5, function()
		TweenService:Create(noticeLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(noticeStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end)

-- Effects -------------------------------------------------------------------
local fxFolder = Instance.new("Folder")
fxFolder.Name = "CrushFx"
fxFolder.Parent = Workspace

local function sound(id: string, pos: Vector3, volume: number, pitch: number): Sound
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 200
	s.Parent = anchor
	s:Play()
	Debris:AddItem(anchor, 6)
	return s
end

-- A sound from Config.Sounds by name.
local function sfx(key: string, pos: Vector3, volume: number, pitch: number): Sound?
	local id = Config.Sounds[key]
	if not id then
		return nil
	end
	return sound("rbxassetid://" .. id, pos, volume, pitch)
end

task.spawn(function()
	local list = {}
	for _, id in Config.Sounds do
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. id
		table.insert(list, s)
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(list)
	end)
end)

local function burst(pos: Vector3, color: Color3, count: number, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size, 0)
	e.Lifetime = NumberRange.new(0.3, 0.7)
	e.Speed = NumberRange.new(size * 8, size * 16)
	e.SpreadAngle = Vector2.new(80, 80)
	e.Acceleration = Vector3.new(0, -60, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = anchor
	e:Emit(count)
	Debris:AddItem(anchor, 1.5)
end

type EmitOpts = {
	color: ColorSequence,
	count: number,
	size: NumberSequence,
	lifetime: NumberRange,
	speed: NumberRange,
	spread: number?,
	gravity: number?,
	light: number?,
	transparency: NumberSequence?,
	drag: number?,
	rot: boolean?,
}

local function emit(pos: Vector3, o: EmitOpts)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Color = o.color
	e.Size = o.size
	e.Lifetime = o.lifetime
	e.Speed = o.speed
	local spread = o.spread or 80
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Acceleration = Vector3.new(0, -(o.gravity or 60), 0)
	e.LightEmission = o.light or 0
	e.Transparency = o.transparency or NumberSequence.new(0)
	e.Drag = o.drag or 0
	if o.rot then
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-120, 120)
	end
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = anchor
	e:Emit(o.count)
	Debris:AddItem(anchor, o.lifetime.Max + 0.5)
end

local shake = 0
RunService:BindToRenderStep("CrushShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake > 0.01 then
		local cam = Workspace.CurrentCamera
		local r = shake
		cam.CFrame = cam.CFrame * CFrame.Angles((math.random() - 0.5) * r * 0.05, (math.random() - 0.5) * r * 0.05, 0)
		shake = math.max(0, shake - dt * 4)
	end
end)

local function floatText(pos: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local bb = make("BillboardGui", { Size = UDim2.fromOffset(200, 60), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 2, 0), Parent = anchor })
	local label = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = color, Text = text, Parent = bb }, { stroke(3) })
	TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), { TextTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.3)
end


-- Pieces of the object fly off on the final hit (client-only, physics, short-lived).
local function debris(pos: Vector3, tier: number, count: number, shards: boolean?)
	local def = Config.Objects[tier]
	local unit = math.clamp(def.width / 6, 0.3, 5)
	for _ = 1, count do
		local spec = def.parts[math.random(1, #def.parts)]
		local p = Instance.new("Part")
		if shards then
			p.Size = Vector3.new(unit * (0.3 + math.random() * 0.4), 0.08, unit * (0.2 + math.random() * 0.3))
			p.Color = Color3.fromRGB(200, 235, 255)
			p.Material = Enum.Material.Glass
			p.Transparency = 0.3
			p.Reflectance = 0.3
		else
			p.Size = Vector3.new(unit * (0.3 + math.random() * 0.5), unit * (0.15 + math.random() * 0.25), unit * (0.3 + math.random() * 0.5))
			p.Color = spec.color
			p.Material = spec.material or Enum.Material.SmoothPlastic
		end
		p.CanCollide = true
		p.CanQuery = false
		p.CanTouch = false
		p.CollisionGroup = "Default"
		p.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * def.width * 0.6, unit * 0.3, (math.random() - 0.5) * def.width * 0.6))
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = fxFolder
		local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
		p.AssemblyLinearVelocity = dir * (12 + math.random() * 18) * math.sqrt(unit) + Vector3.new(0, 25 + math.random() * 20, 0) * math.sqrt(unit)
		p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		task.delay(1.2 + math.random() * 0.4, function()
			TweenService:Create(p, TweenInfo.new(0.3), { Transparency = 1, Size = p.Size * 0.3 }):Play()
		end)
		Debris:AddItem(p, 2)
	end
end

-- A flat shockwave ring on the bed.
local function shockwave(pos: Vector3, radius: number, color: Color3)
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = fxFolder
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.5)
end

-- Crush styles ----------------------------------------------------------------
-- Each Config.Kinds entry names a hitFx / crushFx drawn here.
-- (pos = top of the squashed object, def = the object, s = size scale, big = final hit)

local function seq(...: Color3): ColorSequence
	local c = { ... }
	if #c == 1 then
		return ColorSequence.new(c[1])
	end
	return ColorSequence.new(c[1], c[2])
end

local SPARK_YELLOW = Color3.fromRGB(255, 230, 120)
local SPARK_ORANGE = Color3.fromRGB(255, 120, 30)

local styles: { [string]: (pos: Vector3, def: any, s: number, big: boolean) -> () } = {}

styles.droplets = function(pos, def, s, big)
	emit(pos, {
		color = seq(def.parts[1].color), count = if big then 40 else 10,
		size = NumberSequence.new(0.35 * s, 0.05), lifetime = NumberRange.new(0.4, 0.8),
		speed = NumberRange.new(10 * s, 22 * s), spread = 75, gravity = 90,
	})
end

styles.splat = function(pos, def, s, big)
	styles.droplets(pos, def, s, big)
	local disc = Instance.new("Part")
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch = true, false, false, false
	disc.Shape = Enum.PartType.Cylinder
	disc.Color = def.parts[1].color
	disc.Material = Enum.Material.SmoothPlastic
	disc.Size = Vector3.new(0.1, def.width * 0.6, def.width * 0.6)
	disc.CFrame = CFrame.new(pos.X, pos.Y - 0.05, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Parent = fxFolder
	TweenService:Create(disc, TweenInfo.new(0.15), { Size = Vector3.new(0.1, def.width * 1.8, def.width * 1.6) }):Play()
	TweenService:Create(disc, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.9), { Transparency = 1 }):Play()
	Debris:AddItem(disc, 1.6)
end

styles.fluff = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(255, 250, 240), def.parts[1].color), count = if big then 35 else 8,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3 * s), NumberSequenceKeypoint.new(1, 0.7 * s) }),
		lifetime = NumberRange.new(1.0, 1.8), speed = NumberRange.new(6 * s, 14 * s), spread = 90, gravity = 4,
		drag = 3, rot = true, transparency = NumberSequence.new(0.1, 1),
	})
end

styles.zap = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(220, 245, 255), Color3.fromRGB(80, 170, 255)), count = if big then 30 else 12,
		size = NumberSequence.new(0.18 * s, 0), lifetime = NumberRange.new(0.15, 0.35),
		speed = NumberRange.new(20 * s, 40 * s), spread = 100, gravity = 30, light = 1,
	})
end

styles.shards = function(pos, def, s, big)
	styles.zap(pos, def, s, true)
	debris(pos, table.find(Config.Objects, def) or 1, 14, true)
end

styles.sparks = function(pos, def, s, big)
	emit(pos, {
		color = seq(SPARK_YELLOW, SPARK_ORANGE), count = if big then 60 else 16,
		size = NumberSequence.new(0.2 * s, 0), lifetime = NumberRange.new(0.25, 0.6),
		speed = NumberRange.new(25 * s, 50 * s), spread = 85, gravity = 120, light = 1,
	})
	if big then
		emit(pos, {
			color = seq(Color3.fromRGB(90, 90, 95)), count = 14,
			size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 * s), NumberSequenceKeypoint.new(1, 3 * s) }),
			lifetime = NumberRange.new(0.8, 1.4), speed = NumberRange.new(4 * s, 9 * s), spread = 90, gravity = -6,
			drag = 2, rot = true, transparency = NumberSequence.new(0.3, 1),
		})
	end
end

styles.dust = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(200, 185, 160), Color3.fromRGB(150, 140, 130)), count = if big then 30 else 8,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * s), NumberSequenceKeypoint.new(1, 2.6 * s) }),
		lifetime = NumberRange.new(0.8, 1.6), speed = NumberRange.new(5 * s, 14 * s), spread = 90, gravity = -2,
		drag = 2.5, rot = true, transparency = NumberSequence.new(0.2, 1),
	})
end

styles.fire = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 60, 20)), count = if big then 50 else 12,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * s), NumberSequenceKeypoint.new(1, 0) }),
		lifetime = NumberRange.new(0.3, 0.7), speed = NumberRange.new(10 * s, 25 * s), spread = 90, gravity = -10,
		light = 1, rot = true,
	})
end

styles.explosion = function(pos, def, s, big)
	styles.fire(pos, def, s * 1.6, true)
	styles.dust(pos, def, s * 1.4, true)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = def.width * 0.8
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Parent = fxFolder
end

local lastHiss = 0

Net.event("Hit").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local def = Config.Objects[msg.tier]
	local kind = Config.Kinds[def.kind]
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	local v = if mine then 1 else 0.3
	sfx("Thud", msg.position, 0.45 * v, 1.05 - scale * 0.08 + math.random() * 0.1)
	sfx(kind.hitSound, msg.position, 0.5 * v, 0.9 + math.random() * 0.2)
	local style = styles[kind.hitFx]
	if style then
		style(msg.position, def, scale, false)
	end
	if mine then
		shake = math.min(1, shake + 0.35)
		if os.clock() - lastHiss > 0.7 then
			lastHiss = os.clock()
			task.delay(0.12, function()
				local h = sfx("Hiss", msg.position + Vector3.new(0, Config.pressWidth(msg.tier), 0), 0.18, 1.25)
				if h then
					task.delay(0.35, function()
						TweenService:Create(h, TweenInfo.new(0.3), { Volume = 0 }):Play()
					end)
				end
			end)
		end
	end
end)

Net.event("Crushed").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local def = Config.Objects[msg.tier]
	local kind = Config.Kinds[def.kind]
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	local v = if mine then 1 else 0.3
	local style = styles[kind.crushFx]
	if style then
		style(msg.position, def, scale, true)
	end
	if kind.crushFx ~= "shards" then
		debris(msg.position, msg.tier, if mine then 12 else 5)
	end
	shockwave(msg.position, Config.pressWidth(msg.tier) * 0.9, Color3.fromRGB(255, 230, 160))
	sfx("Thud", msg.position, 0.8 * v, 0.6)
	sfx(kind.crushSound, msg.position, 0.8 * v, 1)
	local vdef = Config.VariantById[msg.variant or "Normal"]
	if vdef and vdef.tint then
		emit(msg.position, {
			color = seq(vdef.text, Color3.new(1, 1, 1)), count = if mine then 50 else 15,
			size = NumberSequence.new(0.6 * scale, 0), lifetime = NumberRange.new(0.6, 1.2),
			speed = NumberRange.new(15 * scale, 35 * scale), spread = 90, gravity = 25, light = 1, rot = true,
		})
		shockwave(msg.position, Config.pressWidth(msg.tier) * 1.4, vdef.text)
	end
	if mine then
		sfx("Coin", msg.position, 0.5, 1)
		if vdef and vdef.tint then
			sfx("Coin", msg.position, 0.6, 1.3)
			sfx("LevelUp", msg.position, 0.5, 1.2)
			floatText(msg.position + Vector3.new(0, 2, 0), string.upper(vdef.id) .. "!", vdef.text)
		end
		floatText(msg.position, "+" .. Format.cash(msg.value), GREEN)
		shake = 1
	end
end)

-- Bigger press: banner, confetti and a rising whoosh.
local banner = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(420, 110),
	BackgroundTransparency = 1, Visible = false, Parent = gui,
})
local bannerScale = make("UIScale", { Scale = 1, Parent = banner })
local bannerTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0.55, 0), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 210, 60), Text = "BIGGER PRESS!", Parent = banner,
}, { stroke(4) })
local bannerSub = make("TextLabel", {
	Position = UDim2.fromScale(0, 0.6), Size = UDim2.new(1, 0, 0.35, 0), BackgroundTransparency = 1, Font = FONT,
	TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = banner,
}, { stroke(3) })
local bannerToken = 0

local function showBanner(title: string, sub: string, color: Color3)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerTitle.TextColor3 = color
	bannerSub.Text = sub
	banner.Visible = true
	bannerScale.Scale = 0.2
	TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.4, function()
		if token ~= bannerToken then
			return
		end
		local t = TweenService:Create(bannerScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

Net.event("Upgraded").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local W = Config.pressWidth(msg.tier)
	sound("rbxasset://sounds/collide.wav", msg.position, if mine then 0.8 else 0.3, 0.3) -- low rumble as it rises
	task.delay(0.9, function()
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(255, 80, 80), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(80, 200, 255), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(255, 220, 60), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		shockwave(msg.position, W * 1.2, Color3.fromRGB(255, 210, 60))
		if mine then
			sfx("LevelUp", msg.position, 0.7, 1)
			shake = 0.8
		end
	end)
	if mine then
		showBanner("BIGGER PRESS!", "Now crushing: " .. Config.Objects[msg.tier].name, GOLD)
	end
end)

-- Rebirth: banner, gold burst ---------------------------------------------------
Net.event("Rebirthed").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	task.delay(0.9, function()
		emit(msg.position + Vector3.new(0, 6, 0), {
			color = seq(GOLD, Color3.new(1, 1, 1)), count = if mine then 80 else 20,
			size = NumberSequence.new(0.8, 0), lifetime = NumberRange.new(0.8, 1.6),
			speed = NumberRange.new(20, 45), spread = 180, gravity = 20, light = 1, rot = true,
		})
		shockwave(msg.position, 30, GOLD)
		if mine then
			sfx("LevelUp", msg.position, 0.8, 0.9)
			shake = 1
		end
	end)
	if mine then
		showBanner("REBIRTH " .. msg.rebirths .. "!", string.format("All cash x%.2f forever", msg.mult), GOLD)
	end
end)

-- Collection book -----------------------------------------------------------
-- A grid of every object: a 3D preview (black until you've crushed one), and
-- how many Normal / Golden / Diamond ones you've crushed. Each first crush of
-- a version adds a permanent cash bonus (Config.CollectionBonus).

local collection: { [string]: { [string]: number } } = {}

local bookButton = make("TextButton", {
	Name = "BookButton",
	Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(110, 44), BackgroundColor3 = Color3.fromRGB(120, 80, 200),
	Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "BOOK", Parent = gui,
}, { corner(10), stroke(2), make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
local bookDot = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(16, 16),
	BackgroundColor3 = RED, Visible = false, Parent = bookButton,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })

local book = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0.8, 0),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.05, Visible = false, ZIndex = 10, Parent = gui,
}, { corner(14), stroke(3), make("UISizeConstraint", { MaxSize = Vector2.new(820, 560) }) })
local bookTitle = make("TextLabel", {
	Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -80, 0, 34), BackgroundTransparency = 1, Font = FONT,
	TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Text = "Collection", ZIndex = 11, Parent = book,
})
local bookSub = make("TextLabel", {
	Position = UDim2.fromOffset(16, 42), Size = UDim2.new(1, -32, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
	TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 210), ZIndex = 11, Parent = book,
	Text = string.format("First crush of each version: Normal +%d%%, Golden +%d%%, Diamond +%d%% cash forever",
		Config.CollectionBonus.Normal * 100, Config.CollectionBonus.Golden * 100, Config.CollectionBonus.Diamond * 100),
})
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = RED,
	Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "X", ZIndex = 11, Parent = book,
}, { corner(8), stroke(2) })
local grid = make("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 1, -82), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = book,
}, { make("UIGridLayout", { CellSize = UDim2.fromOffset(140, 170), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

type BookCell = { frame: Frame, view: ViewportFrame, name: TextLabel, counts: { [string]: TextLabel }, shown: string? }
local cells: { BookCell } = {}

for tier, def in Config.Objects do
	local frame = make("Frame", { BackgroundColor3 = Color3.fromRGB(45, 48, 60), LayoutOrder = tier, ZIndex = 12, Parent = grid }, { corner(10) })
	local view = make("ViewportFrame", {
		Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 100), BackgroundColor3 = Color3.fromRGB(70, 75, 95),
		Ambient = Color3.fromRGB(170, 170, 180), LightDirection = Vector3.new(-1, -2, -1), ZIndex = 12, Parent = frame,
	}, { corner(8) })
	local name = make("TextLabel", {
		Position = UDim2.fromOffset(6, 108), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1), Text = "???", ZIndex = 12, Parent = frame,
	})
	local counts = {}
	for i, v in Config.Variants do
		counts[v.id] = make("TextLabel", {
			Position = UDim2.new((i - 1) / 3, 4, 0, 136), Size = UDim2.new(1 / 3, -8, 0, 26), BackgroundColor3 = Color3.fromRGB(30, 32, 40),
			Font = FONT, TextScaled = true, TextColor3 = v.text or Color3.new(1, 1, 1), Text = "0", ZIndex = 12, Parent = frame,
		}, { corner(6), make("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }) })
	end
	cells[tier] = { frame = frame, view = view, name = name, counts = counts, shown = nil }
end

-- (Re)builds a cell's 3D preview: best version crushed so far, or a black silhouette.
local function setPreview(tier: number, mode: string)
	local cell = cells[tier]
	if cell.shown == mode then
		return
	end
	cell.shown = mode
	cell.view:ClearAllChildren()
	corner(8).Parent = cell.view
	local def = Config.Objects[tier]
	local model = Objects.build(tier, CFrame.identity, if mode == "silhouette" then "Normal" else mode, mode == "silhouette")
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	model.Parent = cell.view
	local cam = Instance.new("Camera")
	local size = math.max(def.width, def.height)
	local centre = Vector3.new(0, def.height / 2, 0)
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(size * 0.9, size * 0.6, size * 1.6), centre)
	cam.Parent = cell.view
	cell.view.CurrentCamera = cam
end

local function refreshBook()
	local found, total = 0, #Config.Objects * #Config.Variants
	for tier, def in Config.Objects do
		local entry = collection[tostring(tier)] or {}
		local cell = cells[tier]
		local best = "silhouette"
		for _, v in Config.Variants do
			local n = entry[v.id] or 0
			cell.counts[v.id].Text = Format.compact(n)
			cell.counts[v.id].TextTransparency = if n > 0 then 0 else 0.6
			if n > 0 then
				found += 1
				best = v.id
			end
		end
		cell.name.Text = if best == "silhouette" then "???" else def.name
		if book.Visible then
			setPreview(tier, best)
		end
	end
	local mult = Config.collectionMult(collection)
	bookTitle.Text = string.format("Collection  %d/%d   bonus x%.2f", found, total, mult)
end

bookButton.Activated:Connect(function()
	book.Visible = not book.Visible
	bookDot.Visible = false
	refreshBook()
end)
closeButton.Activated:Connect(function()
	book.Visible = false
end)

local gotFirst = false
Net.event("Collection").OnClientEvent:Connect(function(data)
	collection = data
	if gotFirst and not book.Visible then
		bookDot.Visible = true
	end
	gotFirst = true
	refreshBook()
end)
