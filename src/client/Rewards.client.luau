--!strict
-- REWARDS gift button (next to INDEX and SHOP) and its panel, styled after the
-- reference game: a purple header with a big gift poking out of the corner,
-- Skip All and a red X; six bright gift cards (reward on top, icon on white
-- rays, a green CLAIM or red countdown bar at the bottom) and the grand prize
-- in a wide rainbow bar with a big countdown. The stud pattern on the header,
-- cards and bar drifts slowly (Style.flowingStuds).
--   Playtime  six gifts + a grand prize that unlock after minutes in this session
--   Daily     7-day check-in; day 7 is the grand prize; missing a day starts over
-- The server decides everything (server/Rewards.luau); this only shows its
-- state and counts down. Click a ready card to claim it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local CrusherIcon = require(script.Parent.CrusherIcon)

local player = Players.LocalPlayer
local Claim = Net.event("ClaimReward")

local C = Color3.fromRGB
local INK = C(12, 14, 20)
local BODY = C(44, 48, 54)
local HEADER = C(205, 44, 235)
local CASH = C(118, 222, 58)
local RED = C(228, 36, 44)
local GREEN = C(70, 226, 50)
local GREY = C(120, 124, 134)
local GOLD = C(255, 228, 40)

local COLS, TILE_W, TILE_H, GAP = 3, 250, 186, 12
local PAD = 18
local W = PAD * 2 + COLS * TILE_W + (COLS - 1) * GAP
local GRID_Y = 104
local GRAND_Y = GRID_Y + 2 * TILE_H + GAP + 14
local GRAND_H = 124
local H = GRAND_Y + GRAND_H + 46

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
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, outline or 3)
	local o = l:FindFirstChild("TextOutline") :: UIStroke?
	if o then o.Color = INK end
	return l
end
-- card fill: darker edges, bright middle (like the reference cards)
local function cardFill(parent: GuiObject, color: Color3)
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	make("UIGradient", {
		Name = "Fill", Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Style.darken(color, 0.08)),
			ColorSequenceKeypoint.new(0.45, Style.lighten(color, 0.22)),
			ColorSequenceKeypoint.new(1, Style.darken(color, 0.22)),
		}),
	}, parent)
end
-- a flat bar (CLAIM / timer): solid colour, darker bottom half, black outline
local function paintBar(bar: GuiObject, color: Color3)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	local g = bar:FindFirstChild("Fill") :: UIGradient?
	if not g then
		g = make("UIGradient", { Name = "Fill", Rotation = 90 }, bar)
	end
	(g :: UIGradient).Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Style.lighten(color, 0.1)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(0.56, Style.darken(color, 0.12)),
		ColorSequenceKeypoint.new(1, Style.darken(color, 0.2)),
	})
end
local function shake(g: GuiObject)
	local x = g.Rotation
	for _, d in { -4, 4, -3, 3, 0 } do
		TweenService:Create(g, TweenInfo.new(0.04), { Rotation = x + d }):Play()
		task.wait(0.04)
	end
end

local gui = make("ScreenGui", { Name = "RewardsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

local button, badge = Style.iconButton(gui, {
	name = "RewardsButton", icon = "🎁", image = Icons.Rewards, label = "REWARDS", a = C(200, 120, 255), b = C(120, 50, 220),
})
Style.placeHudButton(button, 2)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(button, 2) end)

-- Panel ----------------------------------------------------------------------------
local panel = make("Frame", {
	Name = "RewardsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 20), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = BODY, Visible = false, ZIndex = 5,
}, gui)
corner(panel, 6)
stroke(panel, 5)
Style.modal(panel)
-- tabs on the left (160px) and the gift poking out of the top (50px)
panel:SetAttribute("FitWidth", W + 340)
panel:SetAttribute("FitHeight", H + 90)
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 90), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, panel)
corner(header, 6)
stroke(header, 5)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C(226, 92, 255)), ColorSequenceKeypoint.new(0.5, HEADER), ColorSequenceKeypoint.new(1, C(160, 24, 205)),
}) }, header)
local headerStuds = Style.flowingStuds(header, 34, 0.72, panel)
headerStuds.ImageColor3 = C(255, 200, 255)
local gift = Style.image(header, Icons.Rewards, { Name = "Gift", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(44, 30),
	Size = UDim2.fromOffset(150, 150), Rotation = -10, ZIndex = 9 })
Style.wobble(gift, 4, 1.6)
local headerTitle = label(header, "Rewards", UDim2.fromOffset(122, 8), UDim2.fromOffset(330, 74), 5)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left

local close = make("TextButton", {
	Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(66, 66),
	Text = "", AutoButtonColor = false, ZIndex = 8,
}, header)
corner(close, 4)
stroke(close, 4)
paintBar(close, RED)
Style.feedback(close)
label(close, "X", UDim2.fromScale(0.14, 0.08), UDim2.fromScale(0.72, 0.84), 4).ZIndex = 9

-- Skip All (Robux): every playtime gift unlocks now. Product id 0 = not set up yet.
local Store = require(ReplicatedStorage.Shared.Store)
local skipProduct
for _, p in Store.Products do if p.id == "SkipRewards" then skipProduct = p end end
local skip = make("TextButton", { Name = "SkipAll", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -92, 0.5, 0), Size = UDim2.fromOffset(200, 66),
	Text = "", AutoButtonColor = false, ZIndex = 8 }, header)
corner(skip, 4)
stroke(skip, 4)
paintBar(skip, GOLD)
Style.feedback(skip)
label(skip, "Skip All!", UDim2.fromOffset(8, 2), UDim2.new(1, -16, 0, 42), 4).ZIndex = 9
local skipPrice = label(skip, if skipProduct and skipProduct.productId ~= 0 then "R$ " .. skipProduct.price else "Coming soon", UDim2.fromOffset(8, 42), UDim2.new(1, -16, 0, 20), 2.5)
skipPrice.ZIndex = 9
skip.Activated:Connect(function()
	if skipProduct and skipProduct.productId ~= 0 then
		game:GetService("MarketplaceService"):PromptProductPurchase(player, skipProduct.productId)
		return
	end
	shake(skip)
end)

-- Tabs: a short column on the left of the panel ---------------------------------------
local tabs: { [string]: TextButton } = {}
local function tab(name: string, y: number, color: Color3)
	local t = make("TextButton", {
		Name = name .. "Tab", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(-10, y), Size = UDim2.fromOffset(150, 60),
		Text = "", AutoButtonColor = false, ZIndex = 6,
	}, panel)
	corner(t, 4)
	stroke(t, 4)
	paintBar(t, color)
	Style.feedback(t)
	label(t, name, UDim2.fromScale(0.08, 0.14), UDim2.fromScale(0.84, 0.72), 3).ZIndex = 7
	t:SetAttribute("Color", color)
	tabs[name] = t
	return t
end
tab("Playtime", GRID_Y, HEADER)
tab("Daily", GRID_Y + 72, C(40, 150, 255))

-- Cards ----------------------------------------------------------------------------
type Tile = { button: TextButton, title: TextLabel, sub: TextLabel, icon: ImageLabel, iconSize: UDim2, bar: Frame, barText: TextLabel,
	dim: Frame, outline: UIStroke, ready: boolean, reward: any, amount: TextLabel? }

local function colorFor(r: any): Color3
	if r.kind == "crusher" then
		local rarity = Config.Crushers.rarity(r.rarity)
		return if rarity then rarity.color else CASH
	end
	return CASH
end

-- the icon: the cash stack, or a crusher portrait of that rarity
local function iconFor(parent: GuiObject, r: any, pos: UDim2, cashSize: number, crusherSize: Vector2): (ImageLabel, UDim2)
	local size = if r.kind == "crusher" then UDim2.fromOffset(crusherSize.X, crusherSize.Y) else UDim2.fromOffset(cashSize, cashSize)
	local icon = make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundTransparency = 1,
		Image = if r.kind == "crusher" then "" else Icons.Cash, ScaleType = Enum.ScaleType.Fit, ZIndex = 7,
	}, parent)
	if r.kind == "crusher" then
		-- representative portrait; the server still picks a random crusher of that rarity
		local rarity = Config.Crushers.rarity(r.rarity)
		if rarity then CrusherIcon.new(icon, rarity.types[1], { zIndex = 7 }) end
	end
	return icon, size
end

local function makeBar(parent: GuiObject, pos: UDim2, size: UDim2, textSize: UDim2?): (Frame, TextLabel)
	local bar = make("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 1), Position = pos, Size = size, ZIndex = 8 }, parent)
	corner(bar, 3)
	stroke(bar, 3.5)
	paintBar(bar, RED)
	make("UIScale", { Name = "Pulse" }, bar)
	local t = label(bar, "", UDim2.fromScale(0.06, 0.1), textSize or UDim2.fromScale(0.88, 0.8), 3.5)
	t.ZIndex = 9
	return bar, t
end

local function makeTile(parent: Frame, order: number, reward: any, onClaim: () -> ()): Tile
	local color = colorFor(reward)
	local b = make("TextButton", { Name = "Tile" .. order, LayoutOrder = order, Text = "", AutoButtonColor = false, ZIndex = 6 }, parent)
	corner(b, 3)
	local outline = stroke(b, 4)
	cardFill(b, color)
	local studs = Style.flowingStuds(b, 30, 0.8, panel)
	studs.ImageColor3 = Color3.new(1, 1, 1)
	Style.sunburst(b, { center = UDim2.fromScale(0.5, 0.5), alpha = 0.3, zIndex = 6, length = 0.95, width = 0.11 })
	Style.feedback(b)
	local title = label(b, "", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 38), 3.5)
	local sub = label(b, "", UDim2.new(1, -112, 0, 40), UDim2.fromOffset(104, 20), 2.5)
	sub.TextXAlignment = Enum.TextXAlignment.Right
	local icon, iconSize = iconFor(b, reward, UDim2.new(0.5, 0, 0, 92), 96, Vector2.new(170, 104))
	local bar, barText = makeBar(b, UDim2.new(0.5, 0, 1, -10), UDim2.new(1, -36, 0, 44))
	local dim = make("Frame", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Visible = false, ZIndex = 10 }, b)
	corner(dim, 3)
	local tile: Tile
	local function press()
		if tile.ready then onClaim() return end
		shake(b)
	end
	b.Activated:Connect(press)
	tile = { button = b, title = title, sub = sub, icon = icon, iconSize = iconSize, bar = bar, barText = barText, dim = dim,
		outline = outline, ready = false, reward = reward }
	return tile
end

-- The grand prize: a wide rainbow bar, prize on the left, a big countdown on the right.
local function makeGrand(name: string, reward: any, onClaim: () -> ()): Tile
	local b = make("TextButton", { Name = name, Position = UDim2.fromOffset(PAD, GRAND_Y), Size = UDim2.new(1, -PAD * 2, 0, GRAND_H),
		BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, ZIndex = 6 }, panel)
	corner(b, 3)
	local outline = stroke(b, 4)
	local rainbow = Style.rainbow(b, 0.08)
	rainbow.Rotation = 0
	local studs = Style.flowingStuds(b, 30, 0.78, panel)
	studs.ImageColor3 = Color3.new(1, 1, 1)
	Style.sunburst(b, { center = UDim2.new(0, 120, 0.55, 0), alpha = 0.35, zIndex = 6, width = 0.05, length = 1.4 })
	local title = label(b, "", UDim2.fromOffset(12, 4), UDim2.fromOffset(300, 32), 3.5)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local sub = label(b, "", UDim2.fromOffset(14, GRAND_H - 28), UDim2.fromOffset(200, 22), 2.5)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	local icon, iconSize = iconFor(b, reward, UDim2.new(0, 120, 0.56, 0), 92, Vector2.new(190, 96))
	local amount: TextLabel? = nil
	if reward.bonusSeconds then
		local plus = label(b, "+", UDim2.new(0, 238, 0.5, -30), UDim2.fromOffset(60, 70), 5)
		plus.TextColor3 = C(120, 255, 90)
		make("ImageLabel", { Name = "Cash", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 360, 0.6, 0),
			Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 1, Image = Icons.Cash, ScaleType = Enum.ScaleType.Fit, ZIndex = 7 }, b)
		amount = label(b, "", UDim2.new(0, 290, 0, 4), UDim2.fromOffset(150, 30), 3.5)
	end
	local bar, barText = makeBar(b, UDim2.new(1, -14, 1, -14), UDim2.fromOffset(280, 96))
	bar.AnchorPoint = Vector2.new(1, 1)
	local dim = make("Frame", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Visible = false, ZIndex = 10 }, b)
	corner(dim, 3)
	local tile: Tile
	b.Activated:Connect(function()
		if tile.ready then onClaim() return end
		shake(b)
	end)
	tile = { button = b, title = title, sub = sub, icon = icon, iconSize = iconSize, bar = bar, barText = barText, dim = dim,
		outline = outline, ready = false, reward = reward, amount = amount }
	return tile
end

local function grid(name: string): Frame
	local f = make("Frame", { Name = name, Position = UDim2.fromOffset(PAD, GRID_Y), Size = UDim2.fromOffset(W - PAD * 2, TILE_H * 2 + GAP), BackgroundTransparency = 1, ZIndex = 6 }, panel)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE_W, TILE_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left, FillDirectionMaxCells = COLS,
	}, f)
	return f
end

-- one list of rewards: the first ones become cards, the last one the grand prize
local function build(name: string, list: { any }, claimFn: (number) -> ()): ({ Tile }, Frame, Tile)
	local g = grid(name .. "Grid")
	local out: { Tile } = {}
	for i = 1, #list - 1 do
		out[i] = makeTile(g, i, list[i], function() claimFn(i) end)
	end
	local grand = makeGrand(name .. "Grand", list[#list], function() claimFn(#list) end)
	out[#list] = grand
	return out, g, grand
end

local playTiles, playGrid, playGrand = build("Playtime", Config.Rewards.Playtime, function(i) Claim:FireServer("playtime", i) end)
local dailyTiles, dailyGrid, dailyGrand = build("Daily", Config.Rewards.Daily, function() Claim:FireServer("daily") end)

local footer = label(panel, "", UDim2.fromOffset(PAD, H - 40), UDim2.new(1, -PAD * 2, 0, 32), 3)
footer.ZIndex = 7

local function showTab(name: string)
	playGrid.Visible = name == "Playtime"
	playGrand.button.Visible = name == "Playtime"
	dailyGrid.Visible = name == "Daily"
	dailyGrand.button.Visible = name == "Daily"
	skip.Visible = name == "Playtime"
	footer.Text = if name == "Playtime" then "Leaving the game resets your playtime gifts!" else "Come back every day! Missing a day starts over."
	for n, t in tabs do
		paintBar(t, if n == name then t:GetAttribute("Color") :: Color3 else GREY)
	end
end
for n, t in tabs do t.Activated:Connect(function() showTab(n) end) end
showTab("Playtime")

-- State + refresh ------------------------------------------------------------------
local state: any = nil

local function cashText(seconds: number): string
	local cps = if state then state.cps else 0
	return Format.cash(math.max(Config.Rewards.MinCash, math.floor(cps * seconds)))
end
local function amountText(r: any): string
	if r.kind == "crusher" then
		return r.rarity .. " Crusher"
	end
	return cashText(r.seconds)
end

local function clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- status: "ready" | "wait" | "done"
local function set(tile: Tile, title: string, sub: string, status: string, barText: string, highlight: boolean?)
	tile.title.Text = title
	tile.sub.Text = sub
	tile.ready = status == "ready"
	tile.barText.Text = if status == "ready" then "CLAIM" elseif status == "done" then "CLAIMED" else barText
	paintBar(tile.bar, if status == "ready" then GREEN elseif status == "done" then GREY else RED)
	tile.dim.Visible = status == "done"
	tile.outline.Color = if highlight or status == "ready" then Color3.new(1, 1, 1) else INK
	if tile.amount and tile.reward.bonusSeconds then
		tile.amount.Text = cashText(tile.reward.bonusSeconds)
	end
end

local function subFor(r: any, day: number?): string
	if r.mythicChance then return "+ Mythic chance!" end
	return ""
end

-- Claim celebration ---------------------------------------------------------------
local coin = make("Sound", { SoundId = "rbxassetid://" .. Config.Sounds.Coin, Volume = 0.6 }, SoundService)
local function centre(g: GuiObject): Vector2 return g.AbsolutePosition + g.AbsoluteSize / 2 end
local function cashTarget(): Vector2?
	local hud = player.PlayerGui:FindFirstChild("CrushHud")
	local icon = hud and hud:FindFirstChild("CashIcon", true) :: GuiObject?
	return icon and centre(icon)
end
local function celebrate(tile: Tile, amount: string)
	coin:Play()
	local icon = tile.icon
	local base = tile.iconSize
	local big = UDim2.fromOffset(base.X.Offset * 1.35, base.Y.Offset * 1.35)
	TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = big, Rotation = -12 }):Play()
	task.delay(0.12, function()
		TweenService:Create(icon, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = base, Rotation = 0 }):Play()
	end)
	local flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.15, ZIndex = 12 }, tile.button)
	corner(flash, 3)
	TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	task.delay(0.5, function() flash:Destroy() end)
	local start = centre(tile.button)
	local pop = label(gui, "+" .. amount, UDim2.fromOffset(start.X - 130, start.Y - 50), UDim2.fromOffset(260, 46), 4)
	pop.ZIndex = 60
	pop.TextColor3 = if tile.reward.kind == "crusher" then C(255, 214, 80) else C(140, 255, 120)
	TweenService:Create(pop, TweenInfo.new(1, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(start.X - 130, start.Y - 130) }):Play()
	TweenService:Create(pop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.5), { TextTransparency = 1 }):Play()
	task.delay(1.05, function() pop:Destroy() end)
	-- bundles burst out and fly into the cash counter (crusher rewards: they fly up and fade)
	local target = if tile.reward.kind == "crusher" then nil else cashTarget()
	for i = 1, 12 do
		local img = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(start.X, start.Y), Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1, Image = if tile.reward.kind == "crusher" then Icons.Press else Icons.Cash, Rotation = math.random(-30, 30), ZIndex = 59,
		}, gui)
		local a = math.random() * math.pi * 2
		local out = start + Vector2.new(math.cos(a), math.sin(a) * 0.7) * math.random(50, 140)
		TweenService:Create(img, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(out.X, out.Y) }):Play()
		task.delay(0.3 + i * 0.03, function()
			local goal = target or (out - Vector2.new(0, 120))
			local t = TweenService:Create(img, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(goal.X, goal.Y), Size = UDim2.fromOffset(22, 22), ImageTransparency = if target then 0 else 1 })
			t:Play()
			t.Completed:Once(function() img:Destroy() end)
		end)
	end
end

-- ready CLAIM bars breathe gently
RunService.RenderStepped:Connect(function()
	if not panel.Visible then return end
	local k = 1 + math.sin(os.clock() * 5) * 0.04
	for _, list in { playTiles, dailyTiles } do
		for _, tile in list do
			(tile.bar:FindFirstChild("Pulse") :: UIScale).Scale = if tile.ready then k else 1
		end
	end
end)

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
		local title, sub = amountText(r), subFor(r)
		if claimed[i] then
			set(playTiles[i], title, sub, "done", "")
		elseif left <= 0 then
			set(playTiles[i], title, sub, "ready", "")
			anyPlay = true
		else
			set(playTiles[i], title, sub, "wait", clock(left))
		end
	end
	local d = state.daily
	for i, r in Config.Rewards.Daily do
		local title, sub = amountText(r), subFor(r, i)
		if i == d.day and d.canClaim then
			set(dailyTiles[i], title, sub, "ready", "", true)
			anyDaily = true
		elseif i == d.day then
			set(dailyTiles[i], title, sub, "wait", clock(d.nextAt - now), true)
		elseif i < d.day or (i == d.day and not d.canClaim) then
			set(dailyTiles[i], title, sub, "done", "")
		else
			set(dailyTiles[i], title, sub, "wait", "Day " .. i)
		end
	end
	-- a "!" on a tab that has something to claim
	for n, t in tabs do
		local has = if n == "Playtime" then anyPlay else anyDaily
		local mark = t:FindFirstChild("Ready") :: Frame?
		if not mark then
			mark = make("Frame", { Name = "Ready", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 4, 0, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = RED, ZIndex = 9 }, t)
			corner(mark :: Frame, 4)
			stroke(mark :: Frame, 2.5)
			label(mark :: Frame, "!", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 1.5).ZIndex = 10
		end
		(mark :: Frame).Visible = has
	end
	badge.Visible = anyPlay or anyDaily
end

local function claimedSet(s: any): { [number]: boolean }
	local out = {}
	for _, i in s.claimed do out[i] = true end
	return out
end
Net.event("Rewards").OnClientEvent:Connect(function(s)
	local before = state
	state = s
	-- celebrate what was just claimed (amount text from before the claim)
	local wins = {}
	if before then
		local was = claimedSet(before)
		for i in claimedSet(s) do
			if not was[i] and playTiles[i] then table.insert(wins, { playTiles[i], playTiles[i].title.Text }) end
		end
		local d0 = before.daily
		if d0.canClaim and not s.daily.canClaim and dailyTiles[d0.day] then
			table.insert(wins, { dailyTiles[d0.day], dailyTiles[d0.day].title.Text })
		end
	end
	refresh()
	for _, w in wins do task.spawn(celebrate, w[1], w[2]) end
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
