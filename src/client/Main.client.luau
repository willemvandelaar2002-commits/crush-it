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

local player = Players.LocalPlayer
local CrushRemote = Net.event("Crush")
local BuyRemote = Net.event("BuyUpgrade")

local FONT = Enum.Font.FredokaOne
local DARK = Color3.fromRGB(28, 30, 38)
local GREEN = Color3.fromRGB(80, 200, 110)
local RED = Color3.fromRGB(230, 80, 70)
local GREY = Color3.fromRGB(110, 112, 120)

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
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(230, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

type Card = { frame: Frame, title: TextLabel, info: TextLabel, buy: TextButton, id: string }
local cards: { Card } = {}

local function makeCard(id: string, order: number): Card
	local frame = make("Frame", { Size = UDim2.fromOffset(230, 70), BackgroundColor3 = DARK, BackgroundTransparency = 0.15, LayoutOrder = order, Parent = panel }, { corner(10), stroke(2) })
	local title = make("TextLabel", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -110, 0, 26), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Parent = frame })
	local info = make("TextLabel", { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -110, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 210), Parent = frame })
	local buy = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(92, 52), BackgroundColor3 = GREEN, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true, Parent = frame }, { corner(8), stroke(2), make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
	buy.Activated:Connect(function()
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
		if card.id == "Size" then
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
	objName.Text = ((player:GetAttribute("ObjName") :: string?) or "") .. "  " .. Format.compact(math.ceil(hp)) .. " HP"
	TweenService:Create(hpFill, TweenInfo.new(0.12), { Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1) }):Play()
end

for _, name in { "Cash", "Tier", "PowerLv", "SpeedLv", "ValueLv", "Hp", "MaxHp", "ObjName" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

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

local function sound(id: string, pos: Vector3, volume: number, pitch: number)
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
	Debris:AddItem(anchor, 3)
end

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

Net.event("Hit").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	sound("rbxasset://sounds/collide.wav", msg.position, if mine then 0.7 else 0.25, 0.7 + math.random() * 0.2)
	burst(msg.position, Color3.fromRGB(255, 210, 120), if mine then 10 else 4, 0.3 * scale)
	if mine then
		shake = math.min(1, shake + 0.35)
	end
end)

Net.event("Crushed").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local def = Config.Objects[msg.tier]
	local color = def.parts[1].color
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	burst(msg.position, color, if mine then 30 else 10, 0.5 * scale)
	if mine then
		sound("rbxasset://sounds/electronicpingshort.wav", msg.position, 0.6, 1)
		floatText(msg.position, "+" .. Format.cash(msg.value), GREEN)
		shake = 1
	end
end)
