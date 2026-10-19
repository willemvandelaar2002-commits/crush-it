--!strict
-- Robux shop: SHOP button + panel (passes and boosts), the AUTO switch on the
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

local gui = make("ScreenGui", { Name = "ShopHud", ResetOnSpawn = false, DisplayOrder = 5, Parent = player.PlayerGui })

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
local crushButton = hud:WaitForChild("CrushButton") :: TextButton
local autoButton = make("TextButton", {
	Name = "AutoButton", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = GREY, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "AUTO", Parent = crushButton,
}, { corner(10), stroke(2), pad(5) })

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
local shopButton = make("TextButton", {
	Name = "ShopButton", Position = UDim2.fromOffset(130, 8), Size = UDim2.fromOffset(110, 44), BackgroundColor3 = GREEN,
	Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "SHOP", Parent = gui,
}, { corner(10), stroke(2), make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })

local panel = make("Frame", {
	Name = "ShopPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0.82, 0),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.03, Visible = false, Parent = gui,
}, { corner(14), stroke(3), make("UISizeConstraint", { MaxSize = Vector2.new(820, 560) }) })
make("TextLabel", {
	Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -80, 0, 34), BackgroundTransparency = 1, Font = FONT,
	TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Text = "Shop", Parent = panel,
})
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = RED,
	Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "X", Parent = panel,
}, { corner(8), stroke(2) })
local scroll = make("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 1, -64), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel,
}, { make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

local function section(title: string, order: number): Frame
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Font = FONT, TextScaled = true, LayoutOrder = order,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, Text = title, Parent = scroll,
	})
	return make("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order + 1, Parent = scroll,
	}, { make("UIGridLayout", { CellSize = UDim2.fromOffset(185, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
end

type ShopCard = { desc: TextLabel, button: TextButton, update: () -> () }
local shopCards: { ShopCard } = {}

local function card(parent: Frame, order: number, title: string, color: Color3, onBuy: () -> ()): (TextLabel, TextButton)
	local f = make("Frame", { BackgroundColor3 = Color3.fromRGB(45, 48, 60), LayoutOrder = order, Parent = parent }, { corner(10) })
	make("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = color, BorderSizePixel = 0, Parent = f }, { corner(4) })
	make("TextLabel", {
		Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -20, 0, 28), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, Text = title, Parent = f,
	}, { stroke(1.5) })
	local desc = make("TextLabel", {
		Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		TextWrapped = true, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(210, 210, 220), Text = "", Parent = f,
	})
	local button = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -20, 0, 40), BackgroundColor3 = GREEN,
		Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = f,
	}, { corner(8), stroke(2), pad(6) })
	button.Activated:Connect(onBuy)
	return desc, button
end

local passGrid = section("Passes (forever)", 1)
for i, pass in Store.Passes do
	local desc, button = card(passGrid, i, pass.title, pass.color, function()
		buyPass(pass.perk)
	end)
	desc.Text = pass.desc
	local function update()
		if Store.hasPass(player, pass.perk) then
			button.Text = "OWNED"
			button.BackgroundColor3 = GREY
		elseif pass.gamePassId == 0 then
			button.Text = "SOON"
			button.BackgroundColor3 = GREY
		else
			button.Text = "R$ " .. pass.price
			button.BackgroundColor3 = GREEN
		end
	end
	player:GetAttributeChangedSignal(Store.passAttr(pass.perk)):Connect(update)
	table.insert(shopCards, { desc = desc, button = button, update = update })
end

local boostGrid = section("Boosts", 3)
for i, product in Store.Products do
	local desc, button = card(boostGrid, i, product.title, product.color, function()
		buyProduct(product.id)
	end)
	local function update()
		local tier = (player:GetAttribute("Tier") :: number?) or 1
		if Store.CashPackShare[product.id] then
			desc.Text = "+" .. Format.cash(Store.cashPackAmount(product.id, tier)) .. " cash\n(" .. product.desc .. ")"
		else
			local left = (player:GetAttribute("GoldenRush") :: number?) or 0
			desc.Text = product.desc .. (if left > 0 then "\n(" .. left .. " left)" else "")
		end
		button.Text = if product.productId == 0 then "SOON" else "R$ " .. product.price
		button.BackgroundColor3 = if product.productId == 0 then GREY else GREEN
	end
	table.insert(shopCards, { desc = desc, button = button, update = update })
end

local function refreshShop()
	for _, c in shopCards do
		c.update()
	end
end
player:GetAttributeChangedSignal("Tier"):Connect(refreshShop)
player:GetAttributeChangedSignal("GoldenRush"):Connect(refreshShop)
refreshShop()

local function openShop(from: string)
	refreshShop()
	panel.Visible = true
	Net.event("ShopOpened"):FireServer(from)
end
shopButton.Activated:Connect(function()
	if panel.Visible then
		panel.Visible = false
	else
		openShop("ShopButton")
	end
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)

-- Offline earnings card ---------------------------------------------------------
local function duration(seconds: number): string
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	return if h > 0 then string.format("%dh %dm", h, m) else string.format("%dm", m)
end

local offlineCard = make("Frame", {
	Name = "OfflineCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 230),
	BackgroundColor3 = DARK, Visible = false, Parent = gui,
}, { corner(14), stroke(3) })
make("TextLabel", {
	Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 34), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1), Text = "Welcome back!", Parent = offlineCard,
})
local offlineAway = make("TextLabel", {
	Position = UDim2.fromOffset(16, 50), Size = UDim2.new(1, -32, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextScaled = true,
	TextColor3 = Color3.fromRGB(200, 200, 210), Text = "", Parent = offlineCard,
})
local offlineCash = make("TextLabel", {
	Position = UDim2.fromOffset(16, 78), Size = UDim2.new(1, -32, 0, 44), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = GREEN, Text = "", Parent = offlineCard,
}, { stroke(2) })
local offlineMain = make("TextButton", {
	Position = UDim2.fromOffset(16, 132), Size = UDim2.new(1, -32, 0, 44), BackgroundColor3 = GREEN, Font = FONT, TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = offlineCard,
}, { corner(8), stroke(2), pad(7) })
local offlineSkip = make("TextButton", {
	Position = UDim2.fromOffset(16, 184), Size = UDim2.new(1, -32, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextScaled = true,
	TextColor3 = Color3.fromRGB(170, 170, 180), Text = "No thanks", Parent = offlineCard,
})
local offlineOwned = false
offlineMain.Activated:Connect(function()
	if offlineOwned then
		offlineCard.Visible = false
	else
		Net.event("ShopOpened"):FireServer("OfflineCard")
		buyPass("OfflineEarnings")
	end
end)
offlineSkip.Activated:Connect(function()
	offlineCard.Visible = false
end)

Net.event("ShopNotice").OnClientEvent:Connect(function(msg)
	if msg.kind ~= "offline" then
		return
	end
	offlineOwned = msg.owned
	offlineAway.Text = "You were away for " .. duration(msg.seconds)
	if msg.owned then
		offlineCash.Text = "+" .. Format.cash(msg.cash) .. " earned!"
		offlineMain.Text = "COLLECT"
		offlineSkip.Visible = false
	else
		offlineCash.Text = "You could have earned " .. Format.cash(msg.cash)
		local pass = Store.passByPerk("OfflineEarnings")
		offlineMain.Text = "Offline Earnings  R$ " .. (if pass then pass.price else 0)
		offlineSkip.Visible = true
	end
	offlineCard.Visible = true
end)

-- Purchase celebration ----------------------------------------------------------
Net.event("Purchased").OnClientEvent:Connect(function(msg)
	panel.Visible = false
	if msg.id == "OfflineEarnings" then
		return -- the offline card shows the payout
	end
	local label = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromOffset(480, 70),
		BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = GOLD, Text = msg.text, Parent = gui,
	}, { stroke(4) })
	local scale = make("UIScale", { Scale = 0.2, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
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
