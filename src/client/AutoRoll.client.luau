--!strict
-- 7 Nov (Willem, reference video of an "Auto Roller" window): AUTO ROLL is an Auto
-- Roller window, on Willem's art (backplate, tabs, cards, START/STOP, Auto Buy panel).
-- Later the same day (Willem: "make the crushers individually clickable anyway"): tap a
-- crusher card to target just that crusher; the rarity box still targets all of them.
--   HUD: Willem's AUTO ROLL button (blue = off, glowing green = running), bottom, just
--        left of the crusher hotbar; it opens the window.
--   Window: header (dice, AUTO ROLLER, X); rarity tabs on the left, each with a TICK
--        box (= every crusher of that rarity; Legendary and up by default; a number = how
--        many single crushers are picked); tapping a tab shows that rarity's crushers as
--        cards with their odds (??? for ones you haven't discovered); tapping a card
--        targets / untargets it; START / STOP; the AUTO BUY panel (game pass: price
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
	-- 7 Nov: Willem's window art (uploads are 1023 px wide, so rects are in those pixels)
	Backplate = "rbxassetid://88560195984273", -- 1023 x 640
	Tab = "rbxassetid://89940482051531", -- 1023 x 341 grey, tinted per rarity
	Card = "rbxassetid://109318241376424", -- 819 x 1023 grey, tinted per rarity
	Start = "rbxassetid://137227985984200",
	Stop = "rbxassetid://122128869328114",
	AutoBuy = "rbxassetid://112110722481101",
	Close = "rbxassetid://86950187561147", -- the red close sprite (Rebirth / First Buy cards)
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
	local list = {}
	for _, name in C.AutoRoll.Rarities do
		if set[name] then table.insert(list, name) end
		local r = C.rarity(name)
		for _, id in (if r then r.types else {}) do if set[id] then table.insert(list, id) end end
	end
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

-- the window (7 Nov: Willem's art, CrushIt-AutoRoller-Component-Art) -------------------
-- Positions are fractions of the backplate (measured on its pixels): header y .01-.13,
-- rarity column x .05-.21, crusher area x .23-.95 / y .13-.80, footer y .81-.98.
local W, H = 960, 600
local panel = make("Frame", { Name = "AutoRollerPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, gui)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 20) panel:SetAttribute("FitHeight", H + 20)
make("ImageLabel", { Name = "Backplate", Image = ART.Backplate, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 5 }, panel)
-- (one tap area per piece of art; the label and icon are children so they press with it)
local function artButton(name: string, image: string, rectOffset: Vector2, rectSize: Vector2, pos: UDim2, size: UDim2, parent: Instance, z: number?): ImageButton
	local b = make("ImageButton", { Name = name, Image = image, ImageRectOffset = rectOffset, ImageRectSize = rectSize, Position = pos, Size = size,
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = z or 7 }, parent)
	Style.feedback(b)
	return b
end

-- header: dice + AUTO ROLLER + close
local dice = words(panel, "🎲", UDim2.fromScale(0.215, 0.012), UDim2.fromScale(0.08, 0.115), 60, 2, 8)
local title = words(panel, "AUTO ROLLER", UDim2.fromScale(0.3, 0.02), UDim2.fromScale(0.45, 0.095), 60, 5, 8)
title.TextXAlignment = Enum.TextXAlignment.Left
local close = make("ImageButton", { Name = "Close", Image = ART.Close, Position = UDim2.fromScale(0.875, 0.018), Size = UDim2.fromOffset(62, 62),
	BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, panel)
Style.feedback(close)
words(close, "X", UDim2.fromScale(0.18, 0.12), UDim2.fromScale(0.64, 0.7), 40, 4, 9)
task.spawn(function() -- the dice idles a little; the text stays still
	local t = 0
	while true do t += task.wait() dice.Rotation = math.sin(t * 2) * 8 end
end)

-- rarity tabs (the tick box = stop on every crusher of that rarity)
local viewing = "Legendary"
local tabs: { [string]: { tab: ImageButton, tick: TextButton, mark: TextLabel, outline: Frame } } = {}
local TAB_Y, TAB_H = 0.16, 0.71 / #C.AutoRoll.Rarities
-- the crusher area
local head = words(panel, "", UDim2.fromScale(0.25, 0.145), UDim2.fromScale(0.69, 0.06), 40, 4, 8)
local sub = words(panel, "Tap crushers to target them", UDim2.fromScale(0.25, 0.2), UDim2.fromScale(0.69, 0.04), 22, 3, 8)
local grid = make("ScrollingFrame", { Name = "Grid", Position = UDim2.fromScale(0.245, 0.25), Size = UDim2.fromScale(0.69, 0.49), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = rgb(120, 230, 255), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 7 }, panel)
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6) }, grid)
make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 136), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
local status = words(panel, "", UDim2.fromScale(0.25, 0.75), UDim2.fromScale(0.69, 0.045), 24, 3, 8)

-- picks: rarity names (whole rarity) and crusher ids (just that crusher)
local function typesOf(name: string): { string }
	local r = C.rarity(name)
	return if r then r.types else {}
end
local function targetCount(set: { [string]: boolean }): number
	local n = 0
	for _, name in C.AutoRoll.Rarities do
		for _, id in typesOf(name) do if set[name] or set[id] then n += 1 end end
	end
	return n
end
local function toggleRarity(name: string)
	local set = picks()
	local on = not set[name]
	set[name] = on or nil
	for _, id in typesOf(name) do set[id] = nil end -- the box replaces single picks
	send(running(), set, buying())
end
local function toggleCrusher(rarity: string, id: string)
	local set = picks()
	if set[rarity] then
		-- the whole rarity was ticked: keep the others, drop this one
		set[rarity] = nil
		for _, other in typesOf(rarity) do if other ~= id then set[other] = true end end
	else
		set[id] = not set[id] or nil
		local all = #typesOf(rarity) > 0
		for _, other in typesOf(rarity) do if not set[other] then all = false end end
		if all then -- every crusher picked = the rarity
			for _, other in typesOf(rarity) do set[other] = nil end
			set[rarity] = true
		end
	end
	send(running(), set, buying())
end

local cards: { [string]: { frame: Frame, rarity: string } } = {}
local function refreshCards()
	local set = picks()
	for id, c in cards do
		local on = set[c.rarity] == true or set[id] == true
		local sel = c.frame:FindFirstChild("Selected") :: Frame
		local check = c.frame:FindFirstChild("Check") :: TextLabel
		if sel then sel.Visible = on end
		if check then check.Visible = on end
	end
end
local function showGrid()
	for _, c in grid:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	table.clear(cards)
	local r = C.rarity(viewing)
	if not r then return end
	head.Text = string.upper(viewing) .. " CRUSHERS" head.TextColor3 = r.color:Lerp(WHITE, 0.45)
	local seen = {}
	if state then
		for _, id in (if state.index then state.index.seen else {}) do seen[id] = true end
		for _, item in state.items or {} do seen[item.type] = true end
	end
	if #r.types == 0 then
		words(grid, "No crushers here yet", UDim2.new(), UDim2.new(1, 0, 0, 40), 24, 3, 8)
	end
	for i, id in r.types do
		local def = C.typeById(id)
		local known = seen[id] == true
		local frame = make("Frame", { Name = id, LayoutOrder = i, BackgroundTransparency = 1, ZIndex = 7 }, grid)
		local card = artButton("Card", ART.Card, Vector2.new(9, 15), Vector2.new(801, 1000), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), frame, 8)
		card.ScaleType = Enum.ScaleType.Slice card.SliceCenter = Rect.new(90, 95, 720, 925) card.SliceScale = 0.24
		card.ImageColor3 = r.color:Lerp(WHITE, 0.15)
		local icon = CrusherIcons.image(id)
		if icon then
			make("ImageLabel", { Image = icon, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromScale(0.62, 0.56),
				BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageColor3 = if known then WHITE else rgb(0, 0, 0), ZIndex = 9 }, card)
		else
			-- (no icon uploaded yet, e.g. the Lucky Weekend crushers)
			words(card, if r.event then "🍀" else "?", UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0.4, 0.5), 60, 2, 9)
		end
		if r.event then
			local tag = words(card, "WEEKEND", UDim2.fromScale(0.06, 0.05), UDim2.fromScale(0.4, 0.12), 16, 2, 11)
			tag.TextColor3 = rgb(140, 255, 150) tag.TextXAlignment = Enum.TextXAlignment.Left
		end
		words(card, if known and def then def.name else "???", UDim2.fromScale(0.05, 0.6), UDim2.fromScale(0.9, 0.17), 24, 3, 10)
		local pill = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.7, 0.14),
			BackgroundColor3 = rgb(20, 24, 70), BackgroundTransparency = 0.15, ZIndex = 9 }, card)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
		local odds = if state and state.upgrades then C.effectiveOdds(id, state.upgrades.Luck, state.rollLucky, state.index and state.index.luck, r.event ~= nil) else C.oddsFor(id)
		local o = words(pill, "1 in " .. commas(odds), UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), 18, 2, 10)
		o.TextColor3 = rgb(255, 230, 120)
		-- target state: green outline + tick (the outline sits over the art, it doesn't change it)
		local sel = make("Frame", { Name = "Selected", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 11 }, frame)
		make("UICorner", { CornerRadius = UDim.new(0, 18) }, sel)
		make("UIStroke", { Color = rgb(90, 255, 80), Thickness = 4 }, sel)
		local check = words(frame, "✓", UDim2.new(1, -40, 0, -6), UDim2.fromOffset(40, 40), 40, 3, 12)
		check.Name = "Check" check.TextColor3 = rgb(90, 255, 80) check.Visible = false
		card.Activated:Connect(function() toggleCrusher(viewing, id) end)
		cards[id] = { frame = frame, rarity = viewing }
	end
	refreshCards()
end

local function refreshTabs()
	local set = picks()
	for name, t in tabs do
		local some = 0
		for _, id in typesOf(name) do if set[id] then some += 1 end end
		t.mark.Text = if set[name] then "✓" elseif some > 0 then tostring(some) else ""
		t.mark.TextColor3 = if set[name] then rgb(40, 170, 60) else rgb(60, 90, 200)
		t.outline.Visible = name == viewing
	end
end
for i, name in C.AutoRoll.Rarities do
	local r = C.rarity(name)
	local color = if r then r.color else WHITE
	local tab = artButton(name, ART.Tab, Vector2.new(0, 22), Vector2.new(1023, 299), UDim2.fromScale(0.048, TAB_Y + (i - 1) * TAB_H), UDim2.fromScale(0.166, TAB_H * 0.94), panel, 7)
	tab.ImageColor3 = color:Lerp(WHITE, 0.12)
	words(tab, string.upper(name), UDim2.fromScale(0.3, 0.16), UDim2.fromScale(0.64, 0.64), 26, 3, 9).TextXAlignment = Enum.TextXAlignment.Left
	-- (the box sits inside the tab art; it's its own button so viewing and ticking stay separate)
	local tick = make("TextButton", { Name = "Tick", Text = "", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.07, 0.5), Size = UDim2.fromScale(0.19, 0.62),
		BackgroundColor3 = WHITE, AutoButtonColor = true, ZIndex = 10 }, tab)
	make("UIAspectRatioConstraint", { AspectRatio = 1 }, tick)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, tick)
	make("UIStroke", { Color = INK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, tick)
	local mark = make("TextLabel", { Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.FredokaOne,
		TextColor3 = rgb(40, 170, 60), ZIndex = 11 }, tick)
	local outline = make("Frame", { Name = "Viewing", Position = UDim2.fromScale(0.01, 0.02), Size = UDim2.fromScale(0.98, 0.96), BackgroundTransparency = 1, Visible = false, ZIndex = 12 }, tab)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, outline)
	make("UIStroke", { Color = rgb(255, 235, 60), Thickness = 4 }, outline)
	tabs[name] = { tab = tab, tick = tick, mark = mark, outline = outline }
	tab.Activated:Connect(function() viewing = name refreshTabs() showGrid() end)
	tick.Activated:Connect(function() toggleRarity(name) end)
end

-- START / STOP (Willem's buttons; the label and icon are live text on top)
local start = artButton("Start", ART.Start, Vector2.new(6, 51), Vector2.new(1011, 398), UDim2.fromScale(0.237, 0.835), UDim2.fromScale(0.175, 0.115), panel, 7)
words(start, "▶ START", UDim2.fromScale(0.08, 0.16), UDim2.fromScale(0.84, 0.62), 40, 4, 9)
local stop = artButton("Stop", ART.Stop, Vector2.new(0, 37), Vector2.new(1021, 424), UDim2.fromScale(0.425, 0.835), UDim2.fromScale(0.175, 0.115), panel, 7)
words(stop, "■ STOP", UDim2.fromScale(0.08, 0.16), UDim2.fromScale(0.84, 0.62), 40, 4, 9)

-- AUTO BUY panel
local box = make("ImageLabel", { Name = "AutoBuyBox", Image = ART.AutoBuy, ImageRectOffset = Vector2.new(9, 19), ImageRectSize = Vector2.new(1003, 584),
	Position = UDim2.fromScale(0.635, 0.818), Size = UDim2.fromScale(0.305, 0.148), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 7 }, panel)
local boxTitle = words(box, "🔒 AUTO BUY", UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.3), 28, 3, 9)
words(box, "Buys your targets, keeps rolling", UDim2.fromScale(0.1, 0.38), UDim2.fromScale(0.8, 0.16), 16, 2, 9)
local buy = artButton("Buy", ART.Tab, Vector2.new(0, 22), Vector2.new(1023, 299), UDim2.fromScale(0.2, 0.56), UDim2.fromScale(0.6, 0.32), box, 9)
local buyText = words(buy, "", UDim2.fromScale(0.1, 0.12), UDim2.fromScale(0.8, 0.72), 26, 3, 10)

local livePrice: number? = nil
local GREEN, GREY = rgb(70, 220, 70), rgb(120, 124, 140)
local function refresh()
	local on = running()
	hud.Image = if on then ART.On else ART.Off
	hudText.Text = if on then "AUTO: ON" else "AUTO ROLL"
	start.ImageColor3 = if on then rgb(150, 150, 150) else WHITE
	stop.ImageColor3 = if on then WHITE else rgb(150, 150, 150)
	local set = picks()
	local n = targetCount(set)
	local names = {}
	for _, name in C.AutoRoll.Rarities do
		if set[name] then table.insert(names, name)
		else for _, id in typesOf(name) do if set[id] then local d = C.typeById(id) table.insert(names, if d then d.name else id) end end end
	end
	local what = if #names > 0 then table.concat(names, ", ") else "tick a rarity or tap a crusher"
	status.Text = (if on then "ROLLING... stops on " else n .. (if n == 1 then " TARGET · stops on " else " TARGETS · stops on ")) .. what
	local pass = Store.passByPerk("AutoBuy")
	if Store.hasPass(me, "AutoBuy") then
		boxTitle.Text = "🤖 AUTO BUY"
		buyText.Text = if buying() then "ON" else "OFF"
		buy.ImageColor3 = if buying() then GREEN else GREY
	elseif pass and pass.gamePassId ~= 0 then
		buyText.Text = "R$ " .. tostring(livePrice or pass.price)
		buy.ImageColor3 = GREEN
	else
		buyText.Text = "SOON"
		buy.ImageColor3 = GREY
	end
	refreshTabs()
	refreshCards()
end
do
	local pass = Store.passByPerk("AutoBuy")
	if pass and pass.gamePassId ~= 0 then Store.livePrice("pass", pass.gamePassId, pass.price, function(n) livePrice = n refresh() end) end
end
for _, a in { "AutoRoll", "AutoRollPicks", "AutoBuy", Store.passAttr("AutoBuy") } do me:GetAttributeChangedSignal(a):Connect(refresh) end

hud.Activated:Connect(function()
	if panel.Visible then Style.setOpen(panel, false) return end
	showGrid() refresh()
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
