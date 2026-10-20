--!strict
-- REWARDS gift button (next to BOOK and SHOP) and its panel:
--   Playtime  8 gifts that unlock after 2..90 minutes in this session
--   Daily     7-day check-in; claim once per day, missing a day starts over
-- The "!" badge shows whenever something can be claimed. The server decides
-- everything (server/Rewards.luau); this only shows its state and counts down.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)

local player = Players.LocalPlayer
local Claim = Net.event("ClaimReward")

local DARK = Color3.fromRGB(28, 30, 38)
local GREY = Color3.fromRGB(110, 112, 120)
local GOLD = Color3.fromRGB(255, 200, 50)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = parent
	return i
end
local function corner(parent: Instance, r: number)
	make("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local gui = make("ScreenGui", { Name = "RewardsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

local button, badge = Style.iconButton(gui, {
	name = "RewardsButton", icon = "🎁", image = Icons.Rewards, label = "REWARDS", a = Color3.fromRGB(200, 120, 255), b = Color3.fromRGB(120, 50, 220),
})
Style.placeHudButton(button, 2)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(button, 2) end)

-- Panel ----------------------------------------------------------------------------
local panel = make("Frame", {
	Name = "RewardsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0.84, 0),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.03, Visible = false, ZIndex = 5,
}, gui)
Style.workshopPanel(panel, Style.Colors.Purple)
Style.modal(panel)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 520) }, panel)
local title = make("TextLabel", {
	Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -80, 0, 36), BackgroundTransparency = 1, TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "🎁 Free Rewards",
}, panel)
Style.text(title, 2.5)
local close = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(40, 40), Text = "X", TextScaled = true,
}, panel)
Style.button(close, Color3.fromRGB(230, 80, 70))
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, close)

local scroll = make("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 1, -64), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, panel)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
Style.scroll(scroll)

local function heading(text: string, order: number)
	local l = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
		Text = text, LayoutOrder = order,
	}, scroll)
	Style.text(l, 2)
	l.TextColor3 = GOLD
end

local function grid(order: number, cell: Vector2): Frame
	local f = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order,
	}, scroll)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell.X, cell.Y), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, f)
	Style.grid(f, cell.X, cell.Y, 10)
	return f
end

type Card = { frame: Frame, icon: TextLabel, amount: TextLabel, button: TextButton, check: TextLabel }

local CASH_A, CASH_B = Color3.fromRGB(110, 230, 100), Color3.fromRGB(40, 150, 60)
local GOLD_A, GOLD_B = Color3.fromRGB(255, 225, 90), Color3.fromRGB(230, 140, 20)

local function makeCard(parent: Frame, order: number, top: string, reward: any, onClaim: () -> ()): Card
	local golden = reward.kind == "golden"
	local frame = make("Frame", { LayoutOrder = order }, parent)
	Style.panel(frame, if golden then GOLD_A else CASH_A, if golden then GOLD_B else CASH_B)
	local head = make("TextLabel", {
		Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 20), BackgroundTransparency = 1, TextScaled = true, Text = top, ZIndex = 2,
	}, frame)
	Style.text(head, 2)
	local icon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 24), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1,
		Image = if golden then Icons.Golden else Icons.Cash, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
	}, frame)
	local amount = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(1, -12, 0, 22), BackgroundTransparency = 1,
		TextScaled = true, Text = "", ZIndex = 2,
	}, frame)
	Style.text(amount, 2)
	local btn = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -14, 0, 44), Text = "", TextScaled = true, ZIndex = 3,
	}, frame)
	Style.button(btn)
	make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, btn)
	btn.Activated:Connect(onClaim)
	local check = make("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, TextScaled = true,
		Text = "✅", Visible = false, ZIndex = 6,
	}, frame)
	corner(check, 12)
	make("UIPadding", { PaddingTop = UDim.new(0.25, 0), PaddingBottom = UDim.new(0.25, 0) }, check)
	return { frame = frame, icon = icon, amount = amount, button = btn, check = check }
end

heading("⏱️ Playtime gifts", 1)
local playGrid = grid(2, Vector2.new(130, 148))
local playCards: { Card } = {}
for i, r in Config.Rewards.Playtime do
	playCards[i] = makeCard(playGrid, i, r.minutes .. " min", r, function()
		Claim:FireServer("playtime", i)
	end)
end

heading("📅 Daily check-in  (come back every day!)", 3)
local dailyGrid = grid(4, Vector2.new(110, 148))
local dailyCards: { Card } = {}
for i, r in Config.Rewards.Daily do
	dailyCards[i] = makeCard(dailyGrid, i, "Day " .. i, r, function()
		Claim:FireServer("daily")
	end)
end

-- State + refresh ------------------------------------------------------------------
local state: any = nil

local function amountText(r: any): string
	if r.kind == "golden" then
		return r.count .. " Golden"
	end
	local cps = if state then state.cps else 0
	return Format.cash(math.max(Config.Rewards.MinCash, math.floor(cps * r.seconds)))
end

local function clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

local function setButton(card: Card, text: string, color: Color3, active: boolean)
	card.button.Text = text
	card.button.Active = active
	card.button.AutoButtonColor = active
	Style.setButtonColor(card.button, color)
end

local function refresh()
	if not state then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local played = now - state.joined
	local claimed: { [number]: boolean } = {}
	for _, i in state.claimed do
		claimed[i] = true
	end
	local any = false
	for i, r in Config.Rewards.Playtime do
		local card = playCards[i]
		card.amount.Text = amountText(r)
		card.check.Visible = claimed[i] == true
		local left = r.minutes * 60 - played
		if claimed[i] then
			setButton(card, "CLAIMED", GREY, false)
		elseif left <= 0 then
			setButton(card, "CLAIM!", Style.GREEN, true)
			any = true
		else
			setButton(card, clock(left), GREY, false)
		end
	end
	local d = state.daily
	for i, r in Config.Rewards.Daily do
		local card = dailyCards[i]
		card.amount.Text = amountText(r)
		local done = i < d.day or (i == d.day and not d.canClaim)
		card.check.Visible = done
		local stroke = card.frame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if i == d.day then 5 else 3
			stroke.Color = if i == d.day then Color3.new(1, 1, 1) else Color3.fromRGB(30, 30, 30)
		end
		if i == d.day and d.canClaim then
			setButton(card, "CLAIM!", Style.GREEN, true)
			any = true
		elseif i == d.day then
			setButton(card, clock(d.nextAt - now), GREY, false)
		elseif done then
			setButton(card, "DONE", GREY, false)
		else
			setButton(card, "Day " .. i, GREY, false)
		end
	end
	badge.Visible = any
end

Net.event("Rewards").OnClientEvent:Connect(function(s)
	state = s
	refresh()
end)

button.Activated:Connect(function()
	Style.setOpen(panel, not panel.Visible)
	refresh()
end)
close.Activated:Connect(function()
	Style.setOpen(panel, false)
end)

-- Count down once a second.
task.spawn(function()
	while true do
		task.wait(1)
		refresh()
	end
end)
