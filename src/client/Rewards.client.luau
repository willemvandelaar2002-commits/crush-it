--!strict
-- REWARDS gift button (next to BOOK and SHOP) and its panel, styled after the
-- reference game: purple studded header, a grid of chunky reward tiles (reward
-- on top, big icon, timer / CLAIM! at the bottom, red "!" when ready).
--   Playtime  8 gifts that unlock after 2..90 minutes in this session
--   Daily     7-day check-in; claim once per day, missing a day starts over
-- The server decides everything (server/Rewards.luau); this only shows its
-- state and counts down. Click a ready tile to claim it.

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

local C = Color3.fromRGB
local INK = Style.Colors.Ink
local BODY = C(24, 28, 46)
local HEADER = C(176, 62, 232)
local TILE = {
	cash = C(58, 168, 70),
	golden = C(232, 150, 32),
	big = C(128, 60, 205),
}
local RED = C(225, 45, 50)

local W, H = 760, 548 -- panel size (desktop)
local COLS, TILE_W, TILE_H, GAP = 4, 172, 150, 12

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
local function stroke(parent: Instance, thickness: number, color: Color3?): UIStroke
	return make("UIStroke", { Thickness = thickness, Color = color or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, outline: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 6 }, parent)
	Style.text(l, outline or 3)
	return l
end
local function shade(parent: GuiObject, color: Color3)
	-- lighter top, darker bottom, like the reference tiles
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Style.lighten(color, 0.12), Style.darken(color, 0.38)),
	}, parent)
end

local gui = make("ScreenGui", { Name = "RewardsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

local button, badge = Style.iconButton(gui, {
	name = "RewardsButton", icon = "🎁", image = Icons.Rewards, label = "REWARDS", a = C(200, 120, 255), b = C(120, 50, 220),
})
Style.placeHudButton(button, 2)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(button, 2) end)

-- Panel ----------------------------------------------------------------------------
local panel = make("Frame", {
	Name = "RewardsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = BODY, Visible = false, ZIndex = 5,
}, gui)
corner(panel, 14)
stroke(panel, 5)
Style.modal(panel)

local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20, 78), BackgroundColor3 = HEADER, ZIndex = 5 }, panel)
corner(header, 10)
stroke(header, 3, Style.darken(HEADER, 0.45))
Style.studsImage(header, 26, 0.8).ZIndex = 5
label(header, "Rewards", UDim2.new(0.5, -170, 0, 8), UDim2.fromOffset(340, 62), 4)

local close = make("TextButton", {
	Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(62, 62),
	BackgroundColor3 = RED, Text = "", AutoButtonColor = false, ZIndex = 6,
}, header)
corner(close, 6)
stroke(close, 3)
shade(close, RED)
Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.1), UDim2.fromScale(0.7, 0.8), 3).ZIndex = 7

-- Tabs -----------------------------------------------------------------------------
local tabs: { [string]: TextButton } = {}
local function tab(name: string, x: number)
	local t = make("TextButton", {
		Name = name .. "Tab", Position = UDim2.fromOffset(x, 98), Size = UDim2.fromOffset(150, 38), Text = "", AutoButtonColor = false, ZIndex = 6,
	}, panel)
	Style.button(t, HEADER)
	label(t, name, UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.84, 0.76), 2.5).ZIndex = 7
	tabs[name] = t
	return t
end
tab("Playtime", 18)
tab("Daily", 180)

-- Tiles ----------------------------------------------------------------------------
type Tile = { button: TextButton, title: TextLabel, icon: ImageLabel, status: TextLabel, badge: Frame, outline: UIStroke }

local function grid(name: string): Frame
	local f = make("Frame", { Name = name, Position = UDim2.fromOffset(18, 146), Size = UDim2.fromOffset(W - 36, TILE_H * 2 + GAP), BackgroundTransparency = 1, ZIndex = 5 }, panel)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE_W, TILE_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left, FillDirectionMaxCells = COLS,
	}, f)
	return f
end

local function makeTile(parent: Frame, order: number, color: Color3, image: string, onClick: () -> ()): Tile
	local b = make("TextButton", { Name = "Tile" .. order, LayoutOrder = order, BackgroundColor3 = color, Text = "", AutoButtonColor = false, ZIndex = 5 }, parent)
	corner(b, 8)
	local outline = stroke(b, 3)
	shade(b, color)
	Style.studsImage(b, 22, 0.86).ZIndex = 5
	Style.feedback(b)
	local title = label(b, "", UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 30), 3)
	local icon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.fromOffset(66, 66), BackgroundTransparency = 1,
		Image = image, ScaleType = Enum.ScaleType.Fit, ZIndex = 6,
	}, b)
	local status = label(b, "", UDim2.new(0, 8, 1, -40), UDim2.new(1, -16, 0, 32), 3)
	local mark = make("Frame", {
		Name = "Ready", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = RED, Visible = false, ZIndex = 8,
	}, b)
	corner(mark, 5)
	stroke(mark, 3)
	label(mark, "!", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 2).ZIndex = 9
	b.Activated:Connect(onClick)
	return { button = b, title = title, icon = icon, status = status, badge = mark, outline = outline }
end

local function colorFor(r: any, last: boolean): Color3
	if last then return TILE.big end
	return if r.kind == "golden" then TILE.golden else TILE.cash
end
local function imageFor(r: any): string
	return if r.kind == "golden" then Icons.Golden else Icons.Cash
end

local playGrid = grid("PlaytimeGrid")
local playTiles: { Tile } = {}
for i, r in Config.Rewards.Playtime do
	playTiles[i] = makeTile(playGrid, i, colorFor(r, i == #Config.Rewards.Playtime), imageFor(r), function()
		Claim:FireServer("playtime", i)
	end)
end
local dailyGrid = grid("DailyGrid")
local dailyTiles: { Tile } = {}
for i, r in Config.Rewards.Daily do
	dailyTiles[i] = makeTile(dailyGrid, i, colorFor(r, i == #Config.Rewards.Daily), imageFor(r), function()
		Claim:FireServer("daily")
	end)
end

local footer = label(panel, "", UDim2.fromOffset(22, H - 70), UDim2.fromOffset(W - 44, 52), 4)
footer.TextXAlignment = Enum.TextXAlignment.Left

local function showTab(name: string)
	playGrid.Visible = name == "Playtime"
	dailyGrid.Visible = name == "Daily"
	footer.Text = if name == "Playtime" then "Leaving Resets Progress!" else "Come back every day!"
	for n, t in tabs do Style.setButtonColor(t, if n == name then HEADER else C(80, 84, 104)) end
end
for n, t in tabs do t.Activated:Connect(function() showTab(n) end) end
showTab("Playtime")

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
		return string.format("%02d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

local function set(tile: Tile, title: string, status: string, ready: boolean, today: boolean?)
	tile.title.Text = title
	tile.status.Text = status
	tile.badge.Visible = ready
	tile.button.Active = ready
	tile.outline.Color = if today then Color3.new(1, 1, 1) else INK
	tile.outline.Thickness = if today then 4 else 3
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
	local anyPlay, anyDaily = false, false
	for i, r in Config.Rewards.Playtime do
		local left = r.minutes * 60 - played
		if claimed[i] then
			set(playTiles[i], amountText(r), "CLAIMED!", false)
		elseif left <= 0 then
			set(playTiles[i], amountText(r), "CLAIM!", true)
			anyPlay = true
		else
			set(playTiles[i], amountText(r), clock(left), false)
		end
	end
	local d = state.daily
	for i, r in Config.Rewards.Daily do
		local done = i < d.day or (i == d.day and not d.canClaim)
		if i == d.day and d.canClaim then
			set(dailyTiles[i], amountText(r), "CLAIM!", true, true)
			anyDaily = true
		elseif i == d.day then
			set(dailyTiles[i], amountText(r), clock(d.nextAt - now), false, true)
		elseif done then
			set(dailyTiles[i], amountText(r), "CLAIMED!", false)
		else
			set(dailyTiles[i], amountText(r), "Day " .. i, false)
		end
	end
	-- a "!" on a tab that has something to claim
	for n, t in tabs do
		local has = if n == "Playtime" then anyPlay else anyDaily
		local mark = t:FindFirstChild("Ready") :: Frame?
		if not mark then
			mark = make("Frame", { Name = "Ready", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = RED, ZIndex = 9 }, t)
			corner(mark :: Frame, 4)
			stroke(mark :: Frame, 2)
			label(mark :: Frame, "!", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 1.5).ZIndex = 10
		end
		(mark :: Frame).Visible = has
	end
	badge.Visible = anyPlay or anyDaily
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
