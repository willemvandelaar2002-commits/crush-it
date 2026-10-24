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
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

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
local HEADER = C(196, 64, 245)
local TILE = {
	cash = C(58, 168, 70),
}
local RED = C(225, 45, 50)

local COLS, TILE_W, TILE_H, GAP = 4, 172, 128, 12
local ROWS = 3 -- 12 playtime gifts, like the reference
local W, H = 760, 146 + ROWS * TILE_H + (ROWS - 1) * GAP + 84 -- panel size (desktop)

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
Style.studsImage(panel, 26, 0.93).ZIndex = 5
Style.modal(panel)

local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20, 78), BackgroundColor3 = HEADER, ZIndex = 5 }, panel)
corner(header, 10)
stroke(header, 4, Style.darken(HEADER, 0.5))
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(232, 120, 255), C(170, 40, 228)) }, header)
-- big, clearly visible studs like the reference header
local headerStuds = Style.studsImage(header, 34, 0.25)
headerStuds.ZIndex = 5
headerStuds.ImageColor3 = C(215, 95, 255) -- tinted, so the studs stay bright magenta
local headerTitle = label(header, "Rewards", UDim2.new(0.5, -190, 0, 4), UDim2.fromOffset(380, 70), 5)
headerTitle.ZIndex = 7

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
type Tile = { button: TextButton, title: TextLabel, icon: ImageLabel, status: TextLabel, claim: TextButton, pill: Frame,
	badge: Frame, outline: UIStroke, dim: Frame, ready: boolean, reward: any }

local function grid(name: string): Frame
	local f = make("Frame", { Name = name, Position = UDim2.fromOffset(18, 146), Size = UDim2.fromOffset(W - 36, TILE_H * ROWS + GAP * (ROWS - 1)), BackgroundTransparency = 1, ZIndex = 5 }, panel)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE_W, TILE_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left, FillDirectionMaxCells = COLS,
	}, f)
	return f
end

-- 3D preview of a crusher type (server: CrusherPreviewModels), for crusher tiles
local function preview(parent: GuiObject, typeId: string)
	local folder = ReplicatedStorage:FindFirstChild("CrusherPreviewModels") or ReplicatedStorage:WaitForChild("CrusherPreviewModels", 10)
	local source = folder and folder:FindFirstChild(typeId)
	if not (source and source:IsA("Model")) then return end
	local vp = make("ViewportFrame", { Name = "Preview", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = parent.ZIndex + 1,
		Ambient = C(200, 210, 235), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -1) }, parent)
	local model = source:Clone()
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local cam = make("Camera", { FieldOfView = 34 }, vp)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.35, 0.18, 1).Unit * (size.Magnitude / 2) / math.sin(math.rad(17)) * 0.82, cf.Position)
	vp.CurrentCamera = cam
end

local function makeTile(parent: Frame, order: number, color: Color3, image: string, reward: any, onClaim: () -> ()): Tile
	-- earlier tiles draw on top, so a tile's "!" badge is never covered by its neighbour
	local b = make("TextButton", { Name = "Tile" .. order, LayoutOrder = order, BackgroundColor3 = color, Text = "", AutoButtonColor = false, ZIndex = 40 - order }, parent)
	corner(b, 8)
	local outline = stroke(b, 3)
	shade(b, color)
	local studs = Style.studsImage(b, 26, 0.35)
	studs.ZIndex = 5
	studs.ImageColor3 = Style.lighten(color, 0.08)
	Style.feedback(b) -- every tile grows a little on hover
	local title = label(b, "", UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 30), 3)
	local icon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(58, 58), BackgroundTransparency = 1,
		Image = if reward.kind == "crusher" then "" else image, ScaleType = Enum.ScaleType.Fit, ZIndex = 6,
	}, b)
	if reward.kind == "crusher" then
		icon.Size = UDim2.fromOffset(96, 70)
		-- a crusher of that rarity, shown in 3D (the reward is a random one of the rarity)
		local r = Config.Crushers.rarity(reward.rarity)
		if r then task.spawn(preview, icon, r.types[1]) end
	end
	-- bottom: a dark pill with the timer / CLAIMED!, or a green CLAIM! button
	local pill = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -18, 0, 32),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, ZIndex = 6,
	}, b)
	corner(pill, 8)
	local status = label(pill, "", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), 2.5)
	status.ZIndex = 7
	local claim = make("TextButton", {
		Name = "Claim", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.new(1, -16, 0, 36),
		Text = "", AutoButtonColor = false, Visible = false, ZIndex = 7,
	}, b)
	Style.button(claim, Style.GREEN)
	label(claim, "CLAIM!", UDim2.fromScale(0.08, 0.1), UDim2.fromScale(0.84, 0.8), 2.5).ZIndex = 8
	make("UIScale", { Name = "Pulse" }, claim)
	local dim = make("Frame", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Visible = false, ZIndex = 9 }, b)
	corner(dim, 8)
	local mark = make("Frame", {
		Name = "Ready", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = RED, Visible = false, ZIndex = 10,
	}, b)
	corner(mark, 5)
	stroke(mark, 3)
	label(mark, "!", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 2).ZIndex = 11
	Style.wobble(mark, 10, 5)
	local tile: Tile
	local function press()
		if tile.ready then onClaim() return end
		-- not ready yet: a little shake
		local x = b.Rotation
		for _, d in { -4, 4, -3, 3, 0 } do
			TweenService:Create(b, TweenInfo.new(0.04), { Rotation = x + d }):Play()
			task.wait(0.04)
		end
	end
	b.Activated:Connect(press)
	claim.Activated:Connect(press)
	tile = { button = b, title = title, icon = icon, status = status, claim = claim, pill = pill, badge = mark, outline = outline, dim = dim, ready = false, reward = reward }
	return tile
end

local function colorFor(r: any, _last: boolean): Color3
	if r.kind == "crusher" then
		local rarity = Config.Crushers.rarity(r.rarity)
		return if rarity then Style.darken(rarity.color, 0.15) else TILE.cash
	end
	return TILE.cash
end
local function imageFor(r: any): string
	return if r.kind == "crusher" then Icons.Press else Icons.Cash
end

local playGrid = grid("PlaytimeGrid")
local playTiles: { Tile } = {}
for i, r in Config.Rewards.Playtime do
	playTiles[i] = makeTile(playGrid, i, colorFor(r, i == #Config.Rewards.Playtime), imageFor(r), r, function()
		Claim:FireServer("playtime", i)
	end)
end
local dailyGrid = grid("DailyGrid")
local dailyTiles: { Tile } = {}
for i, r in Config.Rewards.Daily do
	dailyTiles[i] = makeTile(dailyGrid, i, colorFor(r, i == #Config.Rewards.Daily), imageFor(r), r, function()
		Claim:FireServer("daily")
	end)
end

local footer = label(panel, "", UDim2.fromOffset(22, H - 70), UDim2.fromOffset(W - 330, 52), 4)
footer.TextXAlignment = Enum.TextXAlignment.Left

-- Skip All (Robux): every playtime gift unlocks now. Product id 0 = not set up yet.
local Store = require(ReplicatedStorage.Shared.Store)
local skipProduct
for _, p in Store.Products do if p.id == "SkipRewards" then skipProduct = p end end
local GOLD = C(255, 196, 40)
local skip = make("TextButton", { Name = "SkipAll", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -14), Size = UDim2.fromOffset(270, 66),
	BackgroundColor3 = GOLD, Text = "", AutoButtonColor = false, ZIndex = 6 }, panel)
corner(skip, 10)
stroke(skip, 4)
shade(skip, GOLD)
local skipStuds = Style.studsImage(skip, 26, 0.3)
skipStuds.ZIndex = 6
skipStuds.ImageColor3 = C(255, 214, 60)
Style.feedback(skip)
label(skip, "Skip All", UDim2.fromOffset(10, 3), UDim2.new(1, -20, 0, 40), 3.5).ZIndex = 8
local skipPrice = label(skip, if skipProduct and skipProduct.productId ~= 0 then "R$ " .. skipProduct.price else "Coming soon", UDim2.fromOffset(10, 42), UDim2.new(1, -20, 0, 20), 2)
skipPrice.ZIndex = 8
skip.Activated:Connect(function()
	if skipProduct and skipProduct.productId ~= 0 then
		game:GetService("MarketplaceService"):PromptProductPurchase(player, skipProduct.productId)
		return
	end
	for _, d in { -4, 4, -3, 3, 0 } do
		TweenService:Create(skip, TweenInfo.new(0.04), { Rotation = d }):Play()
		task.wait(0.04)
	end
end)

local function showTab(name: string)
	playGrid.Visible = name == "Playtime"
	skip.Visible = name == "Playtime"
	dailyGrid.Visible = name == "Daily"
	footer.Text = if name == "Playtime" then "Leaving Resets Progress!" else "Come back every day!"
	for n, t in tabs do Style.setButtonColor(t, if n == name then HEADER else C(80, 84, 104)) end
end
for n, t in tabs do t.Activated:Connect(function() showTab(n) end) end
showTab("Playtime")

-- State + refresh ------------------------------------------------------------------
local state: any = nil

local function amountText(r: any): string
	if r.kind == "crusher" then
		return r.rarity .. " Crusher"
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

local function set(tile: Tile, title: string, status: string, ready: boolean, today: boolean?, done: boolean?)
	tile.title.Text = title
	tile.status.Text = status
	tile.ready = ready
	tile.badge.Visible = ready
	tile.claim.Visible = ready
	tile.pill.Visible = not ready
	tile.dim.Visible = done == true
	tile.outline.Color = if today or ready then Color3.new(1, 1, 1) else INK
	tile.outline.Thickness = if today or ready then 4 else 3
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
	-- tile pops: icon bounces, a white flash fades out
	local icon = tile.icon
	TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(92, 92), Rotation = -12 }):Play()
	task.delay(0.12, function()
		TweenService:Create(icon, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(62, 62), Rotation = 0 }):Play()
	end)
	local flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.15, ZIndex = 12 }, tile.button)
	corner(flash, 8)
	TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	task.delay(0.5, function() flash:Destroy() end)
	-- "+$375" floats up from the tile
	local start = centre(tile.button)
	local pop = label(gui, "+" .. amount, UDim2.fromOffset(start.X - 110, start.Y - 50), UDim2.fromOffset(220, 46), 4)
	pop.ZIndex = 60
	pop.TextColor3 = if tile.reward.kind == "crusher" then C(255, 214, 80) else C(140, 255, 120)
	TweenService:Create(pop, TweenInfo.new(1, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(start.X - 110, start.Y - 130) }):Play()
	TweenService:Create(pop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.5), { TextTransparency = 1 }):Play()
	task.delay(1.05, function() pop:Destroy() end)
	-- bundles burst out and fly into the cash counter (golden stars fly up and fade)
	local target = if tile.reward.kind == "crusher" then nil else cashTarget()
	for i = 1, 12 do
		local img = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(start.X, start.Y), Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1, Image = if tile.reward.kind == "crusher" then Icons.Press else icon.Image, Rotation = math.random(-30, 30), ZIndex = 59,
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

-- the green CLAIM! buttons breathe gently
RunService.RenderStepped:Connect(function()
	if not panel.Visible then return end
	local k = 1 + math.sin(os.clock() * 5) * 0.04
	for _, list in { playTiles, dailyTiles } do
		for _, tile in list do
			if tile.ready then (tile.claim:FindFirstChild("Pulse") :: UIScale).Scale = k end
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
		if claimed[i] then
			set(playTiles[i], amountText(r), "CLAIMED!", false, false, true)
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
			set(dailyTiles[i], amountText(r), "CLAIMED!", false, false, true)
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
			if not was[i] then table.insert(wins, { playTiles[i], playTiles[i].title.Text }) end
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
