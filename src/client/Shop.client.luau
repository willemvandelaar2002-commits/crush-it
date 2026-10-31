--!strict
-- Robux shop: SHOP button + panel (client/ShopPanel), the AUTO switch on the
-- CRUSH button (Auto Crush pass), the offline-earnings card and a little
-- celebration when a purchase goes through. Ids/prices live in Shared/Store.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Store = require(ReplicatedStorage.Shared.Store)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)

local player = Players.LocalPlayer
local hud = player:WaitForChild("PlayerGui"):WaitForChild("CrushHud")

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
local function pad(n: number): UIPadding
	return make("UIPadding", { PaddingTop = UDim.new(0, n), PaddingBottom = UDim.new(0, n), PaddingLeft = UDim.new(0, n), PaddingRight = UDim.new(0, n) })
end

local gui = make("ScreenGui", { Name = "ShopHud", ResetOnSpawn = false, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player.PlayerGui })

local function notice(text: string)
	-- A short toast under the HUD notice line.
	local toast = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(360, 30),
		BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(255, 220, 90), Text = text, Parent = gui,
	}, { stroke(2) })
	task.delay(1.6, function()
		TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.4)
		toast:Destroy()
	end)
end

local function buyPass(perk: string)
	local pass = Store.passByPerk(perk)
	if not pass then
		return
	end
	if Store.hasPass(player, perk) then
		return
	end
	if pass.gamePassId == 0 then
		notice("Coming soon!")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
end

local function buyProduct(id: string)
	local product = Store.productById(id)
	if not product then
		return
	end
	if product.productId == 0 then
		notice("Coming soon!")
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.productId)
end

-- AUTO switch on top of the CRUSH button ---------------------------------------
local crushButton = (if Config.Crushers.Enabled then hud:WaitForChild("FactoryActions"):WaitForChild("CrushButton") else hud:WaitForChild("CrushButton")) :: TextButton
local autoButton = make("TextButton", {
	Name = "AutoButton", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = GREY, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "AUTO", Parent = crushButton,
}, { corner(10), stroke(2), pad(5) })
Style.feedback(autoButton) -- solid colours keep the label white

local function refreshAuto()
	if not Store.hasPass(player, "AutoCrush") then
		autoButton.Text = "AUTO 🔒"
		autoButton.BackgroundColor3 = GREY
	elseif player:GetAttribute("AutoOn") == true then
		autoButton.Text = "AUTO: ON"
		autoButton.BackgroundColor3 = GREEN
	else
		autoButton.Text = "AUTO: OFF"
		autoButton.BackgroundColor3 = RED
	end
end
autoButton.Activated:Connect(function()
	if not Store.hasPass(player, "AutoCrush") then
		Net.event("ShopOpened"):FireServer("AutoButton")
		buyPass("AutoCrush")
		return
	end
	Net.event("SetAuto"):FireServer(player:GetAttribute("AutoOn") ~= true)
end)
player:GetAttributeChangedSignal(Store.passAttr("AutoCrush")):Connect(refreshAuto)
player:GetAttributeChangedSignal("AutoOn"):Connect(refreshAuto)
refreshAuto()
if Config.Crushers.Enabled then autoButton.Visible = false end

-- Auto Crush works while AFK: stop Roblox's 20-minute idle kick for pass owners.
player.Idled:Connect(function()
	if Store.hasPass(player, "AutoCrush") and player:GetAttribute("AutoOn") == true then
		pcall(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.zero)
		end)
	end
end)

-- SHOP button + panel -----------------------------------------------------------
local shopButton, shopBadge = Style.iconButton(gui, {
	name = "ShopButton", icon = "🛒", image = Icons.Shop, label = "SHOP", a = Color3.fromRGB(255, 110, 130), b = Color3.fromRGB(220, 40, 70),
})
Style.placeHudButton(shopButton, 1)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(shopButton, 1) end)
shopBadge.Visible = true -- until the shop has been opened once this session

-- The window itself (tabs, offer banners, details, crate reveal): ShopPanel.
local shopPanel = require(script.Parent.ShopPanel).build(gui, { notice = notice, buyPass = buyPass, buyProduct = buyProduct })
local panel = shopPanel.panel

local function openShop(from: string)
	shopPanel.refresh()
	shopBadge.Visible = false
	Style.setOpen(panel, true)
	Net.event("ShopOpened"):FireServer(from)
end
shopButton.Activated:Connect(function()
	if panel.Visible then
		Style.setOpen(panel, false)
	else
		openShop("ShopButton")
	end
end)
shopPanel.close.Activated:Connect(function()
	Style.setOpen(panel, false)
end)

-- Offer buttons (right side) ----------------------------------------------------
-- Destroy a Vault style: a wobbling rainbow "2X CASH  ONLY R$ x" button and a
-- featured pass card under it. Each hides once owned; the card moves on to the
-- next pass you don't have yet.
local offers = make("Frame", {
	Name = "Offers", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, if Config.Crushers.Enabled then -24 else -240), Size = UDim2.fromOffset(200, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
}, { make("UIListLayout", { Padding = UDim.new(0, 26), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
local offersScale = make("UIScale", { Parent = offers })
local function fitOffers()
	local viewport = Workspace.CurrentCamera.ViewportSize
	local h = viewport.Y
	offersScale.Scale = math.clamp((h - 380) / 480, 0.5, 1) -- stays between the leaderboard and the CRUSH button
	offers:SetAttribute("FitsScreen", not Style.compact() and h >= (if Config.Crushers.Enabled then 560 else 650))
	local book = hud:FindFirstChild("Book") :: GuiObject?
	offers.Visible = offers:GetAttribute("FitsScreen") == true and not panel.Visible and not (book and book.Visible)
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitOffers)
fitOffers()

-- 2X CASH: rainbow tile with a dark outline, big text and "ONLY R$ 249" under it.
local doublePass = Store.passByPerk("DoubleCash")
local doubleHolder = make("Frame", { Size = UDim2.fromOffset(200, 96), BackgroundTransparency = 1, LayoutOrder = 1, Parent = offers })
local doubleButton = make("TextButton", {
	Name = "DoubleCashOffer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(190, 66),
	BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, Parent = doubleHolder,
}, { corner(10), make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(25, 20, 35), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
Style.rainbow(doubleButton)
Style.studsImage(doubleButton, 22, 0.7)
local doubleText = make("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Text = "2X Cash", ZIndex = 2, Parent = doubleButton,
}, { make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
Style.text(doubleText, 3.5)
local doublePrice = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(0.8, 0, 0, 30),
	BackgroundTransparency = 1, TextScaled = true, Text = "", ZIndex = 3, Parent = doubleButton,
})
Style.text(doublePrice, 3)
doublePrice.TextColor3 = Color3.fromRGB(150, 255, 110)
Style.wobble(doubleButton, 4, 2.5)
Style.feedback(doubleButton)
doubleButton.Activated:Connect(function()
	Net.event("ShopOpened"):FireServer("DoubleCashOffer")
	buyPass("DoubleCash")
end)

-- Featured pass card: gradient panel, "BEST!" ribbon, big icon, name and price.
local FEATURED = {
	{ perk = "AutoCrush", icon = Icons.AutoCrush, a = Color3.fromRGB(255, 120, 90), b = Color3.fromRGB(200, 40, 70) },
	{ perk = "AutoCollect", icon = Icons.Cash, a = Color3.fromRGB(255, 185, 70), b = Color3.fromRGB(225, 110, 30) },
	{ perk = "Lucky", icon = Icons.Lucky, a = Color3.fromRGB(255, 225, 90), b = Color3.fromRGB(230, 140, 20) },
	{ perk = "OfflineEarnings", icon = Icons.Offline, a = Color3.fromRGB(130, 160, 255), b = Color3.fromRGB(70, 60, 210) },
}
local featuredCard = make("TextButton", {
	Name = "FeaturedOffer", Size = UDim2.fromOffset(170, 170), BackgroundTransparency = 1, Text = "", LayoutOrder = 2, Parent = offers,
})
Style.feedback(featuredCard)
local featuredPanels: { [string]: Frame } = {}
for _, f in FEATURED do
	local pass = Store.passByPerk(f.perk)
	if not pass then
		continue
	end
	local p = make("Frame", { Name = f.perk, Size = UDim2.fromOffset(170, 150), Visible = false, Parent = featuredCard })
	Style.panel(p, f.a, f.b)
	local title = make("TextLabel", {
		Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 30), BackgroundTransparency = 1, TextScaled = true,
		Text = pass.title, ZIndex = 2, Parent = p,
	})
	Style.text(title, 3)
	make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(84, 84),
		BackgroundTransparency = 1, Image = f.icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = p,
	})
	local price = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(0.8, 0, 0, 36),
		BackgroundTransparency = 1, TextScaled = true, Text = "R$ " .. pass.price, ZIndex = 3, Parent = p,
	})
	Store.livePrice("pass", pass.gamePassId, pass.price, function(n) price.Text = "R$ " .. n end)
	Style.text(price, 3)
	price.TextColor3 = Color3.fromRGB(150, 255, 110)
	local ribbon = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -14, 0, 4), Size = UDim2.fromOffset(64, 26), Rotation = 14,
		BackgroundColor3 = Color3.fromRGB(235, 40, 40), TextScaled = true, Text = "BEST!", ZIndex = 4, Parent = p,
	}, { corner(6), make("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }) })
	Style.text(ribbon, 2)
	featuredPanels[f.perk] = p
end
local featuredPerk: string? = nil
featuredCard.Activated:Connect(function()
	if featuredPerk then
		Net.event("ShopOpened"):FireServer("FeaturedOffer")
		buyPass(featuredPerk)
	end
end)

local function refreshOffers()
	doubleHolder.Visible = doublePass ~= nil and not Store.hasPass(player, "DoubleCash")
	if doublePass then
		local pass = doublePass
		Store.livePrice("pass", pass.gamePassId, pass.price, function(n) doublePrice.Text = "ONLY R$ " .. n end)
	end
	featuredPerk = nil
	for _, f in FEATURED do
		local p = featuredPanels[f.perk]
		if p then
			local show = featuredPerk == nil and not Store.hasPass(player, f.perk)
			p.Visible = show
			if show then
				featuredPerk = f.perk
			end
		end
	end
	featuredCard.Visible = featuredPerk ~= nil
end
for _, pass in Store.Passes do
	player:GetAttributeChangedSignal(Store.passAttr(pass.perk)):Connect(refreshOffers)
end
refreshOffers()
-- The book lives in the HUD below this ScreenGui: hide the offers while it's open.
local bookPanel = hud:WaitForChild("Book", 10) :: GuiObject?
if bookPanel then
	bookPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		offers.Visible = offers:GetAttribute("FitsScreen") == true and not bookPanel.Visible and not panel.Visible
	end)
end
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	offers.Visible = offers:GetAttribute("FitsScreen") == true and not panel.Visible and not (bookPanel and bookPanel.Visible)
end)

-- Offline earnings card (30 Oct, after Destroy a Vault's): gold studded header,
-- "While OFFLINE you earned...", then three columns: TAKE IT (free, 1x),
-- DOUBLE IT (2x, Robux) and the rainbow 5X IT! (5x, Robux). The server keeps
-- the record and pays; this card only asks.
local function duration(seconds: number): string
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	return if h > 0 then string.format("%dh %dm", h, m) else string.format("%dm", m)
end
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 50)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 30)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 230, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 200, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 70, 255)),
})
local CW, CH = 900, 470
local offlineCard = make("Frame", {
	Name = "OfflineCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CW, CH),
	BackgroundColor3 = Color3.fromRGB(34, 36, 48), BackgroundTransparency = 0.12, Visible = false, ZIndex = 8, Parent = gui,
}, { corner(10), make("UIStroke", { Thickness = 4, Color = Style.Colors.Ink }) })
Style.modal(offlineCard)
do local st = Style.studsImage(offlineCard, 34, 0.55) st.ZIndex = 8 st.ImageColor3 = Color3.fromRGB(60, 64, 82) end -- subtle studs on the dark body too
local function olabel(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3?, thick: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 10, Parent = parent })
	Style.text(l, thick or 3) if color then l.TextColor3 = color end
	Style.bold(l, (thick or 3) + 0.5)
	return l
end
-- gold header with the studs and a tilted icon poking out
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 96),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 9, Parent = offlineCard }, { corner(10), make("UIStroke", { Thickness = 4, Color = Style.Colors.Ink }),
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 226, 90), Color3.fromRGB(255, 170, 20)) }) })
-- 30 Oct: studs clearly visible (like the reference), drifting slowly
do local st = Style.studsImage(header, 34, 0.2) st.ZIndex = 9 st.ImageColor3 = Color3.fromRGB(255, 175, 20) end -- tinted like the header: studs read as raised bumps
olabel(header, "Offline Earnings", UDim2.fromOffset(150, 10), UDim2.new(1, -170, 0, 76), nil, 4).TextXAlignment = Enum.TextXAlignment.Left
local icon = Style.image(offlineCard, Icons.Offline, { Name = "Icon", Position = UDim2.fromOffset(-50, -46), Size = UDim2.fromOffset(170, 170), Rotation = -14, ZIndex = 12 })
Style.wobble(icon, 3, 1.4)
olabel(offlineCard, "While OFFLINE you earned...", UDim2.fromOffset(40, 108), UDim2.new(1, -80, 0, 56), nil, 3.5)
local offlineAway = olabel(offlineCard, "", UDim2.fromOffset(40, 162), UDim2.new(1, -80, 0, 26), Color3.fromRGB(200, 205, 225), 2)
-- three columns
local COL = (CW - 80) / 3
local function column(i: number, title: string): (TextLabel, TextLabel, TextButton, TextLabel)
	local x = 40 + (i - 1) * COL
	if i > 1 then
		make("Frame", { Name = "Divider", Position = UDim2.fromOffset(x - 2, 200), Size = UDim2.fromOffset(4, 240), BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(210, 215, 230), BackgroundTransparency = 0.35, ZIndex = 9, Parent = offlineCard })
	end
	local t = olabel(offlineCard, title, UDim2.fromOffset(x + 14, 204), UDim2.fromOffset(COL - 28, 32), nil, 2.5)
	local amount = olabel(offlineCard, "", UDim2.fromOffset(x + 10, 240), UDim2.fromOffset(COL - 20, 70), nil, 4)
	local btn = make("TextButton", { Name = "Option" .. i, Position = UDim2.fromOffset(x + 18, 336), Size = UDim2.fromOffset(COL - 36, 82),
		Text = "", ZIndex = 10, Parent = offlineCard })
	Style.button(btn, GREEN)
	btn.TextTransparency = 1
	local cap = olabel(btn, "", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), nil, 3)
	cap.ZIndex = 12
	-- still studs; only the paid 2x / 5x buttons get drifting ones (below)
	if i == 1 then Style.studsImage(btn, 26, 0.25).ZIndex = 11 else Style.flowingStuds(btn, 26, 0.25, offlineCard).ZIndex = 11 end
	return t, amount, btn, cap
end
local _, takeAmount, takeButton, takeCap = column(1, "CURRENT")
local _, x2Amount, x2Button, x2Cap = column(2, "Double")
local _, x5Amount, x5Button, x5Cap = column(3, "Five Times")
takeAmount.TextColor3 = Color3.fromRGB(140, 255, 40)
x2Amount.TextColor3 = Color3.fromRGB(80, 210, 255)
x5Amount.TextColor3 = Color3.new(1, 1, 1)
local x5TextGradient = make("UIGradient", { Color = RAINBOW, Parent = x5Amount:FindFirstChild("Face") or x5Amount })
Style.setButtonColor(takeButton, Color3.fromRGB(255, 40, 55)) takeCap.Text = "Take It"
Style.setButtonColor(x2Button, Color3.fromRGB(40, 150, 255))
-- studs tinted with each button's own colour (white studs wash the colour out)
local function tintStuds(btn: GuiObject, c: Color3, transparency: number)
	local flow = btn:FindFirstChild("StudsFlow") local img = (flow and flow:FindFirstChild("Studs") or btn:FindFirstChild("Studs")) :: ImageLabel?
	if img then img.ImageColor3 = c img.ImageTransparency = transparency end
end
tintStuds(takeButton, Color3.fromRGB(255, 50, 60), 0.15)
tintStuds(x2Button, Color3.fromRGB(50, 150, 255), 0.15)
tintStuds(x5Button, Color3.new(1, 1, 1), 0.72)
-- the rainbow 5X IT! button, with a glow pulse and a little "x5" tag
local fill = x5Button:FindFirstChild("Fill") :: UIGradient?
if fill then fill.Color = RAINBOW fill.Rotation = 0 end
local tag = olabel(x5Button, "x5", UDim2.new(0.5, -30, 0, -24), UDim2.fromOffset(60, 32), nil, 3)
tag.ZIndex = 13
-- the 5X IT! rainbow keeps flowing (hue cycles), the button pulses and glows
local glow = make("UIStroke", { Thickness = 4, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.2 })
local outline = x5Button:FindFirstChild("Outline") :: UIStroke?
if outline then outline:Destroy() end
glow.Parent = x5Button
local x5Scale = make("UIScale", { Parent = x5Button })
local function rainbowAt(t: number): ColorSequence
	local keys = {}
	for i = 0, 6 do
		keys[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((t + i / 6) % 1, 0.85, 1))
	end
	return ColorSequence.new(keys)
end
game:GetService("RunService").RenderStepped:Connect(function()
	if not offlineCard.Visible then return end
	local t = os.clock()
	local seq = rainbowAt(t * 0.35)
	if fill then fill.Color = seq fill.Rotation = 0 end
	x5TextGradient.Color = seq
	glow.Color = Color3.fromHSV((t * 0.35) % 1, 0.6, 1)
	x5Scale.Scale = 1 + 0.04 * math.sin(t * 5)
end)
-- price shown under the multiplier buttons (Roblox's price once a product id is set)
local function priceText(id: string): string
	local product = Store.productById(id)
	if not product then return "" end
	if product.productId == 0 then return "SOON" end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(product.productId, Enum.InfoType.Product) end)
	return "R$ " .. tostring(if ok and info and info.PriceInRobux then info.PriceInRobux else product.price)
end
local x2Price = olabel(offlineCard, "", UDim2.fromOffset(40 + COL + 18, 422), UDim2.fromOffset(COL - 36, 30), Color3.fromRGB(150, 255, 120), 2.5)
local x5Price = olabel(offlineCard, "", UDim2.fromOffset(40 + 2 * COL + 18, 422), UDim2.fromOffset(COL - 36, 30), Color3.fromRGB(150, 255, 120), 2.5)
task.spawn(function() x2Price.Text = priceText("OfflineX2") x5Price.Text = priceText("OfflineX5") end)

local function setOption(btn: TextButton, cap: TextLabel, priceLabel: TextLabel?, available: boolean, text: string)
	cap.Text = text
	btn.Active = available btn.AutoButtonColor = false
	btn.Visible = available
	if priceLabel then priceLabel.Visible = available end
end
takeButton.Activated:Connect(function()
	Net.event("OfflineAction"):FireServer("Collect")
	Style.setOpen(offlineCard, false)
end)
x2Button.Activated:Connect(function() Net.event("ShopOpened"):FireServer("OfflineX2") buyProduct("OfflineX2") end)
x5Button.Activated:Connect(function() Net.event("ShopOpened"):FireServer("OfflineX5") buyProduct("OfflineX5") end)

Net.event("ShopNotice").OnClientEvent:Connect(function(msg)
	if msg.kind ~= "offline" then
		return
	end
	local cash = tonumber(msg.cash) or 0
	local paid = tonumber(msg.paid) or 0
	offlineAway.Text = "You were away for " .. duration(tonumber(msg.seconds) or 0)
	takeAmount.Text = Format.cash(cash)
	x2Amount.Text = Format.cash(cash * 2)
	x5Amount.Text = Format.cash(cash * 5)
	setOption(takeButton, takeCap, nil, paid == 0, "Take It")
	setOption(x2Button, x2Cap, x2Price, paid < 2, "2X IT!")
	setOption(x5Button, x5Cap, x5Price, paid < 5, "5X IT!")
	offlineCard.Visible = paid < 5
end)

-- Purchase celebration ----------------------------------------------------------
Net.event("Purchased").OnClientEvent:Connect(function(msg)
	panel.Visible = false
	if string.sub(tostring(msg.id), 1, 7) == "Offline" then
		Style.setOpen(offlineCard, false) -- the welcome-back card was answered
	end
	if msg.id == "OfflineEarnings" or string.sub(tostring(msg.id), 1, 12) == "FactoryCrate" then
		return -- the offline card shows the payout; crates get their own reveal
	end
	local label = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromOffset(480, 70),
		BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = GOLD, Text = msg.text, Parent = gui,
	}, { stroke(4) })
	local scale = make("UIScale", { Scale = 0.2, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. Config.Sounds.LevelUp
	s.Volume = 0.7
	s.Parent = Workspace
	s:Play()
	task.delay(2.2, function()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.4)
		label:Destroy()
		s:Destroy()
	end)
end)

-- Other scripts can open the shop: set the "OpenShop" attribute on the player's ShopHud.
gui:GetAttributeChangedSignal("OpenShop"):Connect(function()
	openShop(tostring(gui:GetAttribute("OpenShop")))
end)
-- ...or one offer's details: "OpenOffer" = offer id (PrismMech, StarterPack, FactoryCrate).
gui:GetAttributeChangedSignal("OpenOffer"):Connect(function()
	local id = gui:GetAttribute("OpenOffer")
	if type(id) ~= "string" then return end
	gui:SetAttribute("OpenOffer", nil)
	openShop("Offer" .. id)
	shopPanel.openOffer(id)
end)
