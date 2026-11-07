--!strict
-- 7 Nov (Willem, reference video of an "Auto Roller" window; "without clicking specific
-- crushers"): AUTO ROLL is an Auto Roller window.
--   HUD: Willem's AUTO ROLL button (blue = off, glowing green = running), bottom, just
--        left of the crusher hotbar; it opens the window.
--   Window: title bar (dice, "Auto Roller", X); rarity tabs on the left, each with a TICK
--        box (Auto Roll stops on / Auto Buy buys any ticked rarity; Legendary and up by
--        default); tapping a tab shows that rarity's crushers with their odds (??? for
--        ones you haven't discovered); START / STOP; the AUTO BUY box (game pass: price
--        button, then ON / OFF).
-- server/AutoRoll does the rolling (free, after the tutorial). Attributes AutoRoll /
-- AutoRollPicks / AutoBuy. Art can be swapped in later (ART).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.CrusherConfig)
local Store = require(RS.Shared.Store)
local CrusherIcons = require(RS.Shared.CrusherIcons)

local me = Players.LocalPlayer
local remote = Net.event("AutoRoll")
local INK = Style.Colors.Ink
local WHITE = Color3.new(1, 1, 1)
local function rgb(r: number, g: number, b: number) return Color3.fromRGB(r, g, b) end
local ART = {
	Off = "rbxassetid://118340677613688", -- 1023 x 682, the button is x 36-987, y 138-543
	On = "rbxassetid://111686894944891",
}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, max: number, stroke: number?, z: number?): TextLabel
	local t = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z or 8 }, parent)
	Style.text(t, stroke or 3)
	make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = max }, t)
	return t
end
local function commas(n: number): string
	if n == math.huge then return "?" end
	local text = tostring(math.max(1, math.floor(n + 0.5)))
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- latest state from the server (luck for the odds, the Index for ???)
local state: any = nil
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) == "table" and v.upgrades then state = v end
end)

local function picks(): { [string]: boolean }
	local set = {}
	local text = me:GetAttribute("AutoRollPicks")
	if type(text) == "string" then for name in text:gmatch("[^,]+") do set[name] = true end
	else for _, name in C.AutoRoll.Default do set[name] = true end end
	return set
end
local function pickList(set: { [string]: boolean }): { string }
	local list = {} for _, name in C.AutoRoll.Rarities do if set[name] then table.insert(list, name) end end
	return list
end
local function running(): boolean return me:GetAttribute("AutoRoll") == true end
local function buying(): boolean return me:GetAttribute("AutoBuy") == true end
local function send(on: boolean, set: { [string]: boolean }, buy: boolean) remote:FireServer(on, pickList(set), buy) end

local gui = make("ScreenGui", { Name = "AutoRollHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))

-- HUD button --------------------------------------------------------------------------
-- (left of the crusher hotbar, so it never covers the notices above it)
local hud = make("ImageButton", { Name = "AutoRollButton", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -162, 1, -12), Size = UDim2.fromOffset(176, 75),
	BackgroundTransparency = 1, Image = ART.Off, ImageRectOffset = Vector2.new(36, 138), ImageRectSize = Vector2.new(951, 405), ScaleType = Enum.ScaleType.Stretch }, gui)
Style.feedback(hud)
Style.phoneFit(hud, { scale = 0.62, anchor = Vector2.new(1, 1), position = UDim2.new(0.5, -106, 1, -8) })
local hudText = words(hud, "AUTO ROLL", UDim2.fromScale(0.08, 0.18), UDim2.fromScale(0.84, 0.64), 30, 3)

-- the window --------------------------------------------------------------------------
local W, H = 740, 450
local panel = make("Frame", { Name = "AutoRollerPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	Visible = false, ZIndex = 5 }, gui)
Style.panel(panel, rgb(46, 40, 96), rgb(26, 22, 58))
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 20) panel:SetAttribute("FitHeight", H + 20)
-- title bar
local titleBar = make("Frame", { Name = "TitleBar", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 56), ZIndex = 6 }, panel)
Style.panel(titleBar, rgb(150, 70, 230), rgb(105, 40, 180))
words(titleBar, "🎲", UDim2.fromOffset(10, 4), UDim2.fromOffset(48, 48), 44, 2, 7)
words(titleBar, "Auto Roller", UDim2.fromOffset(64, 6), UDim2.new(1, -150, 0, 44), 38, 4, 7).TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { Name = "Close", Text = "", Position = UDim2.new(1, -60, 0, 4), Size = UDim2.fromOffset(48, 48), ZIndex = 7 }, titleBar)
Style.button(close, rgb(228, 36, 44))
words(close, "X", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8), 30, 3, 9)

-- rarity tabs with tick boxes
local TAB_W, TAB_H, TAB_GAP = 172, 39, 3
local viewing = "Legendary"
local tabs: { [string]: { tab: TextButton, tick: TextButton, mark: TextLabel } } = {}
local list = make("Frame", { Name = "Tabs", Position = UDim2.fromOffset(14, 72), Size = UDim2.fromOffset(TAB_W, #C.AutoRoll.Rarities * (TAB_H + TAB_GAP)), BackgroundTransparency = 1, ZIndex = 6 }, panel)
-- the crusher grid
local GX = 14 + TAB_W + 12
local head = words(panel, "", UDim2.fromOffset(GX, 72), UDim2.new(1, -GX - 14, 0, 30), 26, 3, 7)
local grid = make("ScrollingFrame", { Name = "Grid", Position = UDim2.fromOffset(GX, 104), Size = UDim2.new(1, -GX - 14, 0, 210), BackgroundColor3 = rgb(18, 16, 40),
	BackgroundTransparency = 0.2, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, grid)
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, grid)
make("UIGridLayout", { CellSize = UDim2.fromOffset(98, 92), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)

local function showGrid()
	for _, c in grid:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	local r = C.rarity(viewing)
	if not r then return end
	head.Text = viewing .. " Crushers" head.TextColor3 = r.color:Lerp(WHITE, 0.3)
	local seen = {}
	if state then
		for _, id in (if state.index then state.index.seen else {}) do seen[id] = true end
		for _, item in state.items or {} do seen[item.type] = true end
	end
	for i, id in r.types do
		local def = C.typeById(id)
		local known = seen[id] == true
		local card = make("Frame", { Name = id, LayoutOrder = i, BackgroundColor3 = r.color:Lerp(INK, 0.55), ZIndex = 7 }, grid)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
		make("UIStroke", { Color = r.color, Thickness = 2 }, card)
		local icon = CrusherIcons.image(id)
		if icon then
			make("ImageLabel", { Image = icon, Position = UDim2.fromOffset(19, 4), Size = UDim2.fromOffset(60, 52), BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit, ImageColor3 = if known then WHITE else rgb(0, 0, 0), ZIndex = 8 }, card)
		else
			-- (no icon uploaded yet, e.g. the Lucky Weekend crushers)
			words(card, if r.event then "🍀" else "?", UDim2.fromOffset(24, 8), UDim2.fromOffset(50, 44), 40, 2, 8)
		end
		if r.event then
			local tag = words(card, "WEEKEND", UDim2.fromOffset(2, 2), UDim2.new(1, -4, 0, 12), 11, 2, 10)
			tag.TextColor3 = rgb(140, 255, 150)
		end
		words(card, if known and def then def.name else "???", UDim2.fromOffset(4, 54), UDim2.new(1, -8, 0, 16), 14, 2, 9)
		local odds = if state and state.upgrades then C.effectiveOdds(id, state.upgrades.Luck, state.rollLucky, state.index and state.index.luck, r.event ~= nil) else C.oddsFor(id)
		local o = words(card, "1 in " .. commas(odds), UDim2.fromOffset(4, 71), UDim2.new(1, -8, 0, 16), 14, 2, 9)
		o.TextColor3 = rgb(255, 230, 120)
	end
end

local function refreshTabs()
	local set = picks()
	for name, t in tabs do
		t.mark.Text = if set[name] then "✓" else ""
		local stroke = t.tab:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = if name == viewing then WHITE else INK stroke.Thickness = if name == viewing then 4 else 3 end
	end
end
for i, name in C.AutoRoll.Rarities do
	local r = C.rarity(name)
	local color = if r then r.color else WHITE
	local tab = make("TextButton", { Name = name, Text = "", Position = UDim2.fromOffset(0, (i - 1) * (TAB_H + TAB_GAP)), Size = UDim2.fromOffset(TAB_W, TAB_H), ZIndex = 7 }, list)
	Style.button(tab, color:Lerp(INK, 0.1))
	words(tab, name, UDim2.fromOffset(44, 5), UDim2.new(1, -52, 1, -10), 24, 3, 9).TextXAlignment = Enum.TextXAlignment.Left
	local tick = make("TextButton", { Name = "Tick", Text = "", Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(TAB_H - 10, TAB_H - 10),
		BackgroundColor3 = WHITE, AutoButtonColor = true, ZIndex = 9 }, tab)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, tick)
	make("UIStroke", { Color = INK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, tick)
	local mark = make("TextLabel", { Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.FredokaOne,
		TextColor3 = rgb(40, 170, 60), ZIndex = 10 }, tick)
	tabs[name] = { tab = tab, tick = tick, mark = mark }
	tab.Activated:Connect(function() viewing = name refreshTabs() showGrid() end)
	tick.Activated:Connect(function()
		local set = picks()
		set[name] = not set[name] or nil
		send(running(), set, buying())
	end)
end

-- START / STOP
local BY = 326
local start = make("TextButton", { Name = "Start", Text = "", Position = UDim2.fromOffset(GX, BY), Size = UDim2.fromOffset(150, 74), ZIndex = 7 }, panel)
Style.button(start, rgb(60, 200, 80))
words(start, "START", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 26), 24, 3, 9)
words(start, "▶", UDim2.fromOffset(8, 30), UDim2.new(1, -16, 0, 38), 34, 3, 9)
local stop = make("TextButton", { Name = "Stop", Text = "", Position = UDim2.fromOffset(GX + 158, BY), Size = UDim2.fromOffset(150, 74), ZIndex = 7 }, panel)
Style.button(stop, rgb(240, 120, 40))
words(stop, "STOP", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 26), 24, 3, 9)
words(stop, "■", UDim2.fromOffset(8, 30), UDim2.new(1, -16, 0, 38), 34, 3, 9)
local status = words(panel, "", UDim2.fromOffset(GX, BY + 80), UDim2.fromOffset(308, 32), 18, 2, 7)
status.TextXAlignment = Enum.TextXAlignment.Left

-- AUTO BUY box
local box = make("Frame", { Name = "AutoBuyBox", Position = UDim2.fromOffset(GX + 320, BY), Size = UDim2.new(1, -(GX + 320) - 14, 0, 110), ZIndex = 6 }, panel)
Style.panel(box, rgb(30, 40, 100), rgb(16, 22, 64))
make("UIStroke", { Color = rgb(255, 200, 60), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, box)
words(box, "🤖 Auto Buy", UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 28), 24, 3, 7)
words(box, "Buys what it stops on, keeps rolling", UDim2.fromOffset(10, 34), UDim2.new(1, -20, 0, 30), 14, 2, 7).TextWrapped = true
local buy = make("TextButton", { Name = "Buy", Text = "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.new(1, -40, 0, 38), ZIndex = 7 }, box)
Style.button(buy, rgb(60, 200, 80))
local buyText = words(buy, "", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8), 22, 3, 9)

local livePrice: number? = nil
local function refresh()
	local on = running()
	hud.Image = if on then ART.On else ART.Off
	hudText.Text = if on then "AUTO: ON" else "AUTO ROLL"
	Style.setButtonColor(start, if on then rgb(40, 140, 60) else rgb(60, 200, 80))
	Style.setButtonColor(stop, if on then rgb(240, 120, 40) else rgb(130, 110, 100))
	local list = pickList(picks())
	status.Text = if on then "Rolling... stops on " .. (if #list > 0 then table.concat(list, ", ") else "nothing") else "Stops on: " .. (if #list > 0 then table.concat(list, ", ") else "tick a rarity")
	local pass = Store.passByPerk("AutoBuy")
	if Store.hasPass(me, "AutoBuy") then
		buyText.Text = if buying() then "ON" else "OFF"
		Style.setButtonColor(buy, if buying() then rgb(60, 200, 80) else rgb(110, 116, 140))
	elseif pass and pass.gamePassId ~= 0 then
		buyText.Text = "R$ " .. tostring(livePrice or pass.price)
		Style.setButtonColor(buy, rgb(60, 200, 80))
	else
		buyText.Text = "SOON"
		Style.setButtonColor(buy, rgb(110, 116, 140))
	end
	refreshTabs()
end
do
	local pass = Store.passByPerk("AutoBuy")
	if pass and pass.gamePassId ~= 0 then Store.livePrice("pass", pass.gamePassId, pass.price, function(n) livePrice = n refresh() end) end
end
for _, a in { "AutoRoll", "AutoRollPicks", "AutoBuy", Store.passAttr("AutoBuy") } do me:GetAttributeChangedSignal(a):Connect(refresh) end

hud.Activated:Connect(function()
	if panel.Visible then Style.setOpen(panel, false) return end
	refresh() showGrid()
	Style.setOpen(panel, true)
end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)
start.Activated:Connect(function()
	if running() then return end
	send(true, picks(), buying())
	Style.setOpen(panel, false) -- back to the game while it rolls
end)
stop.Activated:Connect(function() if running() then send(false, picks(), buying()) end end)
buy.Activated:Connect(function()
	if Store.hasPass(me, "AutoBuy") then send(running(), picks(), not buying()) return end
	local pass = Store.passByPerk("AutoBuy")
	if pass and pass.gamePassId ~= 0 then
		Net.event("ShopOpened"):FireServer("AutoBuyButton")
		pcall(function() MarketplaceService:PromptGamePassPurchase(me, pass.gamePassId) end)
	end
end)
refresh()

-- follow the Shop button (hidden during the first tutorial steps)
task.spawn(function()
	while true do
		local shop = me.PlayerGui:FindFirstChild("ShopButton", true)
		local sg = shop and shop:FindFirstAncestorOfClass("ScreenGui")
		hud.Visible = sg ~= nil and sg.Enabled and (shop :: GuiObject).Visible
		-- just left of the crusher hotbar, which grows with the crushers you own
		local bar = me.PlayerGui:FindFirstChild("CrusherHotbar")
		bar = bar and bar:FindFirstChild("Bar")
		local y = if Style.compact() then -8 else -12
		if bar and (bar :: GuiObject).Visible then
			hud.Position = UDim2.new(0, math.max((bar :: GuiObject).AbsolutePosition.X - 8, hud.AbsoluteSize.X + 4), 1, y)
		end
		task.wait(0.5)
	end
end)
