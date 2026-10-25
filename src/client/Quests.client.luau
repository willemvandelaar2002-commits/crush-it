--!strict
-- Quests window (reference style): gold studded header with a ticket, tabs on
-- the left (Daily / Weekly / Shop) above "Your Tokens", and on the right the
-- "Refreshes in ..." line with quest rows (icon, title, progress bar, token
-- reward, Claim) or the token shop. Opens from the QUESTS button or the
-- Quests booth in the hub (tag "QuestsPrompt"). The server decides everything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local CrusherIcon = require(script.Parent.CrusherIcon)
local Format = require(ReplicatedStorage.Shared.Format)
local QC = require(ReplicatedStorage.Shared.QuestConfig)

local me = Players.LocalPlayer
local action = Net.event("QuestAction")
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local GOLD, GOLD_DARK = C(240, 196, 52), C(150, 110, 20)
local BODY = C(40, 34, 22)
local GREY = C(120, 124, 136)
local GREEN = Style.GREEN
local RED = C(225, 60, 50)
local W, H = 780, 520

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(p: Instance, text: string, pos: UDim2, size: UDim2, outline: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, p)
	Style.text(l, outline or 2.5)
	return l
end
local function gradient(p: Instance, a: Color3, b: Color3)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(a, b) }, p)
end
-- A gold ticket with a star (the token icon)
local function ticket(parent: Instance, pos: UDim2, size: UDim2): Frame
	local t = make("Frame", { Name = "Ticket", Position = pos, Size = size, BackgroundColor3 = GOLD, Rotation = -14, ZIndex = 9 }, parent)
	corner(t, 4) stroke(t, 2.5) gradient(t, C(255, 230, 120), C(225, 160, 20))
	local s = label(t, "★", UDim2.fromScale(0.2, 0.05), UDim2.fromScale(0.6, 0.9), 1.5)
	s.ZIndex = 10 s.TextColor3 = C(255, 250, 220)
	return t
end
-- chunky button look; call again only to recolour (corner/outline are made once)
local function goldButton(b: TextButton, color: Color3)
	local g = b:FindFirstChild("Fill") :: UIGradient?
	if not g then
		b.AutoButtonColor = false b.BackgroundColor3 = Color3.new(1, 1, 1)
		corner(b, 6) stroke(b, 3)
		g = make("UIGradient", { Name = "Fill", Rotation = 90 }, b)
	end
	(g :: UIGradient).Color = ColorSequence.new(Style.lighten(color, 0.25), Style.darken(color, 0.2))
end
-- 1234567 -> "1,234,567"
local function commas(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- Window -------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "QuestsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local hudButton, hudBadge = Style.iconButton(gui, { name = "QuestsButton", image = Icons.Trophy, label = "QUESTS", a = C(255, 214, 80), b = C(220, 140, 20) })
Style.placeHudButton(hudButton, 3)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(hudButton, 3) end)

local panel = make("Frame", { Name = "QuestsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = BODY, Visible = false, ZIndex = 5 }, gui)
corner(panel, 10) stroke(panel, 5)
gradient(panel, C(70, 58, 30), C(30, 26, 18))
Style.modal(panel)

local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(W - 16, 62), BackgroundColor3 = GOLD, ZIndex = 6 }, panel)
corner(header, 6) stroke(header, 3, GOLD_DARK)
gradient(header, C(255, 220, 90), C(222, 168, 30))
local hs = Style.studsImage(header, 30, 0.35) hs.ZIndex = 6 hs.ImageColor3 = C(255, 214, 70)
ticket(header, UDim2.fromOffset(10, 8), UDim2.fromOffset(58, 40))
local title = label(header, "Quests", UDim2.fromOffset(74, 6), UDim2.fromOffset(240, 50), 3.5)
title.TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(48, 48), Text = "", ZIndex = 8 }, header)
goldButton(close, RED) Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 2.5).ZIndex = 9

-- left column: tabs + tokens
local side = make("Frame", { Name = "Side", Position = UDim2.fromOffset(14, 82), Size = UDim2.fromOffset(170, H - 96), BackgroundColor3 = C(24, 20, 12), BackgroundTransparency = 0.25, ZIndex = 6 }, panel)
corner(side, 6) stroke(side, 2, C(90, 72, 30))
local tabs: { [string]: TextButton } = {}
for i, name in { "Daily", "Weekly", "Shop" } do
	local t = make("TextButton", { Name = name .. "Tab", Position = UDim2.fromOffset(12, 12 + (i - 1) * 52), Size = UDim2.fromOffset(146, 42), Text = "", ZIndex = 7 }, side)
	goldButton(t, GREY) Style.feedback(t)
	label(t, name, UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.84, 0.76), 2.5).ZIndex = 8
	local mark = make("Frame", { Name = "Ready", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = RED, Visible = false, ZIndex = 10 }, t)
	corner(mark, 4) stroke(mark, 2)
	label(mark, "!", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 1.5).ZIndex = 11
	tabs[name] = t
end
label(side, "Your Tokens", UDim2.new(0, 8, 1, -108), UDim2.new(1, -16, 0, 30), 2.5)
local tokenBox = make("Frame", { Position = UDim2.new(0, 12, 1, -72), Size = UDim2.new(1, -24, 0, 56), BackgroundColor3 = C(16, 13, 8), ZIndex = 7 }, side)
corner(tokenBox, 8) stroke(tokenBox, 2, C(90, 72, 30))
ticket(tokenBox, UDim2.fromOffset(10, 12), UDim2.fromOffset(42, 30))
local tokenText = label(tokenBox, "0", UDim2.fromOffset(62, 8), UDim2.new(1, -70, 0, 40), 2.5)
tokenText.TextXAlignment = Enum.TextXAlignment.Left

-- right: content
local content = make("Frame", { Name = "Content", Position = UDim2.fromOffset(196, 82), Size = UDim2.fromOffset(W - 210, H - 96), BackgroundColor3 = C(24, 20, 12), BackgroundTransparency = 0.25, ZIndex = 6 }, panel)
corner(content, 6) stroke(content, 2, C(90, 72, 30))
local refresh = label(content, "", UDim2.fromOffset(10, 8), UDim2.new(1, -20, 0, 40), 2.5)
refresh.TextColor3 = C(255, 214, 60)
local list = make("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(10, 54), Size = UDim2.new(1, -20, 1, -64), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, ScrollBarImageColor3 = GOLD, ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 7 }, content)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }, list)
local shop = make("ScrollingFrame", { Name = "Shop", Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, ScrollBarImageColor3 = GOLD, ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, ZIndex = 7 }, content)
make("UIGridLayout", { CellSize = UDim2.fromOffset(266, 176), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, shop)
make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }, shop)

-- Rows -------------------------------------------------------------------------------
type Row = { frame: Frame, bar: Frame, barText: TextLabel, button: TextButton, buttonText: TextLabel }
local rows: { [string]: Row } = {}
local current = "Daily"
local state: any = nil

local function amountText(q: any, v: number): string
	if q.unit ~= "time" then return commas(v) end
	local m = math.floor(v / 60)
	if q.goal >= 3600 and v >= 3600 then return string.format("%dh", math.floor(v / 3600)) end
	if q.goal >= 3600 and v < 3600 then return string.format("%dm", m) end
	return m .. "m"
end
local function goalText(q: any): string
	if q.unit ~= "time" then return commas(q.goal) end
	return if q.goal >= 3600 then string.format("%dh", q.goal // 3600) else (q.goal // 60) .. "m"
end

local function row(period: string, q: any, order: number): Row
	local key = period .. ":" .. q.id
	local r = rows[key]
	if r then return r end
	local f = make("Frame", { Name = key, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 98), BackgroundColor3 = C(60, 48, 22), ZIndex = 8 }, list)
	corner(f, 6) stroke(f, 2.5, C(20, 16, 8))
	gradient(f, C(78, 62, 28), C(42, 34, 16))
	local tile = make("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(82, 82), BackgroundColor3 = C(22, 18, 10), ZIndex = 9 }, f)
	corner(tile, 6) stroke(tile, 2, C(10, 8, 4))
	make("ImageLabel", { Image = (Icons :: any)[q.icon] or Icons.Trophy, BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(66, 66), ScaleType = Enum.ScaleType.Fit, ZIndex = 10 }, tile)
	local t = label(f, q.title, UDim2.fromOffset(102, 8), UDim2.new(1, -112, 0, 28), 2.5)
	t.TextXAlignment = Enum.TextXAlignment.Left
	local barBack = make("Frame", { Position = UDim2.fromOffset(102, 40), Size = UDim2.new(1, -112, 0, 18), BackgroundColor3 = C(14, 12, 8), ZIndex = 9 }, f)
	corner(barBack, 3)
	local bar = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, ZIndex = 10 }, barBack)
	corner(bar, 3)
	local barText = label(barBack, "", UDim2.fromScale(0, 0.05), UDim2.fromScale(1, 0.9), 1.5)
	barText.ZIndex = 11
	ticket(f, UDim2.fromOffset(112, 66), UDim2.fromOffset(32, 22))
	local reward = label(f, "+" .. q.reward, UDim2.fromOffset(150, 62), UDim2.fromOffset(70, 30), 2.5)
	reward.TextXAlignment = Enum.TextXAlignment.Left reward.TextColor3 = C(255, 220, 90)
	local b = make("TextButton", { Name = "Claim", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 63), Size = UDim2.fromOffset(120, 30), Text = "", ZIndex = 9 }, f)
	goldButton(b, GREY) Style.feedback(b)
	local bt = label(b, "Claim", UDim2.fromScale(0.08, 0.1), UDim2.fromScale(0.84, 0.8), 2)
	bt.ZIndex = 10
	b.Activated:Connect(function() action:FireServer("Claim", period, q.id) end)
	r = { frame = f, bar = bar, barText = barText, button = b, buttonText = bt }
	rows[key] = r
	return r
end

-- Shop cards -------------------------------------------------------------------------
type Card = { frame: Frame, button: TextButton, price: TextLabel, cost: number }
local cards: { [string]: Card } = {}
local function preview(parent: GuiObject, typeId: string)
	CrusherIcon.new(parent,typeId,{zIndex=parent.ZIndex+1})
end
local function card(item: any, order: number): Card
	local c = cards[item.id]
	if c then return c end
	local f = make("Frame", { Name = item.id, LayoutOrder = order, BackgroundColor3 = C(60, 48, 22), ZIndex = 8 }, shop)
	corner(f, 6) stroke(f, 2.5, C(20, 16, 8))
	gradient(f, C(78, 62, 28), C(36, 28, 14))
	local t = label(f, item.title, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 0, 28), 2.5)
	t.ZIndex = 9
	local art = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.fromOffset(110, 84), BackgroundTransparency = 1, ZIndex = 9 }, f)
	if item.kind == "crusher" then
		local r = Config.Crushers.rarity(item.rarity)
		if r then
			local glow = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(84, 84), BackgroundColor3 = r.color, BackgroundTransparency = 0.55, ZIndex = 9 }, art)
			corner(glow, 42)
			preview(art, r.types[1])
		end
	else
		make("ImageLabel", { Image = (Icons :: any)[item.icon] or Icons.Cash, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = 10 }, art)
	end
	local b = make("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(170, 38), Text = "", ZIndex = 9 }, f)
	goldButton(b, GREEN) Style.feedback(b)
	ticket(b, UDim2.fromOffset(10, 6), UDim2.fromOffset(30, 22))
	local price = label(b, "", UDim2.fromOffset(46, 4), UDim2.new(1, -54, 1, -8), 2)
	price.ZIndex = 10
	b.Activated:Connect(function() action:FireServer("Buy", item.id) end)
	c = { frame = f, button = b, price = price, cost = item.cost }
	cards[item.id] = c
	return c
end

-- Refresh ----------------------------------------------------------------------------
local function clock(seconds: number): string
	seconds = math.max(0, seconds)
	local d, h, m = seconds // 86400, (seconds % 86400) // 3600, (seconds % 3600) // 60
	if d > 0 then return string.format("%dd %dh", d, h) end
	return string.format("%dh %dm", h, m)
end
local function redraw()
	if not state then return end
	tokenText.Text = commas(state.tokens)
	for name, t in tabs do
		goldButton(t, if name == current then GOLD else GREY)
		local has = false
		local p = state.periods[name]
		if p then for _, q in p.quests do if not q.claimed and q.progress >= q.goal then has = true end end end
		(t:FindFirstChild("Ready") :: Frame).Visible = has
	end
	hudBadge.Visible = state.ready == true
	local isShop = current == "Shop"
	shop.Visible = isShop list.Visible = not isShop refresh.Visible = not isShop
	for key, r in rows do r.frame.Visible = key:sub(1, #current) == current end
	if isShop then
		for i, item in state.shop do
			local c = card(item, i)
			local afford = state.tokens >= item.cost
			c.price.Text = (commas(state.tokens)) .. " / " .. item.cost
			goldButton(c.button, if afford then GREEN else RED)
		end
		return
	end
	local p = state.periods[current]
	refresh.Text = "Refreshes in " .. clock(p.nextAt - os.time())
	for i, q in p.quests do
		local r = row(current, q, i)
		local f = q.progress / q.goal
		r.bar.Size = UDim2.fromScale(f, 1)
		r.bar.BackgroundColor3 = if f >= 1 then GREEN else GOLD
		r.barText.Text = amountText(q, q.progress) .. " / " .. goalText(q)
		if q.claimed then r.buttonText.Text = "Claimed" goldButton(r.button, GREY)
		elseif f >= 1 then r.buttonText.Text = "Claim" goldButton(r.button, GREEN)
		else r.buttonText.Text = "Claim" goldButton(r.button, GREY) end
	end
end

-- "+30 Quest Tokens!" above the window, and a toast for other messages
local coin = make("Sound", { SoundId = "rbxassetid://" .. Config.Sounds.Coin, Volume = 0.6 }, SoundService)
local function pop(text: string, good: boolean)
	local l = label(gui, text, UDim2.new(0.5, -300, 0.53, -H / 2 - 70), UDim2.fromOffset(600, 60), 4)
	l.ZIndex = 40
	l.TextColor3 = if good then Color3.new(1, 1, 1) else C(255, 220, 140)
	local s = make("UIScale", { Scale = 0.4 }, l)
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(l, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), { TextTransparency = 1 }):Play()
	task.delay(2, function() l:Destroy() end)
end

Net.event("QuestState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" then return end
	state = v
	redraw()
	if v.toast and panel.Visible then
		if v.gained then coin:Play() end
		pop(v.toast, v.gained ~= nil or v.toast:sub(1, 3) == "New" or v.toast:find("Time Skip") ~= nil)
	end
end)
for name, t in tabs do t.Activated:Connect(function() current = name list.CanvasPosition = Vector2.zero shop.CanvasPosition = Vector2.zero redraw() end) end
local function open()
	list.CanvasPosition = Vector2.zero shop.CanvasPosition = Vector2.zero
	Style.setOpen(panel, true)
	action:FireServer("State")
	redraw()
end
hudButton.Activated:Connect(function() if panel.Visible then Style.setOpen(panel, false) else open() end end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)
local function bindPrompt(prompt: Instance)
	if prompt:IsA("ProximityPrompt") then prompt.Triggered:Connect(open) end
end
for _, p in CollectionService:GetTagged("QuestsPrompt") do bindPrompt(p) end
CollectionService:GetInstanceAddedSignal("QuestsPrompt"):Connect(bindPrompt)
task.spawn(function()
	while true do task.wait(20) if panel.Visible then redraw() end end
end)
