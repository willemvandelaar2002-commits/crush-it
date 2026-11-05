--!strict
-- The pushed Starter Pack offer (4 Nov). V2 (Willem's layered art, CrushIt-Starter-Popup-
-- Layers-V2): one static background image (panel, banner, plaques, reward cards) with
-- two separate animated ImageButtons (GET STARTER PACK, close) and live text/icons on top.
-- Positions are fractions of the full 1448x1086 background canvas (the pack's layout.json),
-- so the whole card scales as one piece (Style.modal fits it to the screen).
-- Live data only: the real Candy Colossus portrait (CrusherIcon), the cash amount from your
-- current earnings (Store.cashFor, like the pack grants it), the boost from OfferConfig,
-- and Roblox's own price (GetProductInfo; product id 0 shows COMING SOON). Buying goes
-- through the server's OfferAction "Prompt", exactly like the shop; nothing is granted here.
-- Motion: buttons grow on hover and squash on press (the button only, never the art),
-- the crusher floats gently, cash/boost icons pop a little on hover. Stops when hidden.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Style = require(RS.Shared.Kit.Style)
local Store = require(RS.Shared.Store)
local Icons = require(RS.Shared.Icons)
local ShopArt = require(RS.Shared.ShopArt)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local O = require(RS.Shared.OfferConfig)
local Config = require(RS.Shared.Config)
local CrusherIcon = require(script.Parent.CrusherIcon)

local player = Players.LocalPlayer
local C = Color3.fromRGB
local W, H = 760, 570 -- 4:3 like the art (1448 x 1086)

-- Willem's uploads (4 Nov)
local ART = {
	Background = "rbxassetid://85579393736486", -- StarterPack-Background.png
	Purchase = "rbxassetid://106307684676239", -- PurchaseButton.png (2056 x 306)
	Close = "rbxassetid://86950187561147", -- CloseButton.png (967 x 959)
}
-- normalized x, y, w, h on the background canvas (layout.json v2, checked in Studio)
local L = {
	offerTitle = { 0.36, 0.052, 0.275, 0.055 },
	packTitle = { 0.25, 0.115, 0.5, 0.095 },
	closeButton = { 0.84, 0.135, 0.077, 0.103 },
	rarity = { 0.2, 0.243, 0.17, 0.046 },
	crusherIcon = { 0.115, 0.302, 0.325, 0.3 },
	crusherName = { 0.12, 0.6, 0.31, 0.085 },
	crusherDescription = { 0.12, 0.682, 0.31, 0.036 },
	cashIcon = { 0.485, 0.29, 0.155, 0.155 },
	cashAmount = { 0.65, 0.312, 0.24, 0.064 },
	cashDescription = { 0.65, 0.377, 0.24, 0.042 },
	boostIcon = { 0.485, 0.535, 0.155, 0.155 },
	boostTitle = { 0.65, 0.553, 0.24, 0.064 },
	boostDuration = { 0.65, 0.618, 0.24, 0.042 },
	purchaseButton = { 0.13, 0.745, 0.74, 0.145 },
	browseShopButton = { 0.35, 0.894, 0.3, 0.046 },
}

local Offer = {}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function rect(r: { number }): (UDim2, UDim2)
	return UDim2.fromScale(r[1], r[2]), UDim2.fromScale(r[3], r[4])
end
local function box(parent: Instance, name: string, r: { number }, z: number): Frame
	local pos, size = rect(r)
	return make("Frame", { Name = name, Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = z }, parent)
end
-- outlined display text filling `parent` (bold = chunky drop outline for titles)
local function words(parent: Instance, text: string, z: number, opts: { bold: number?, color: Color3?, outline: number?, max: number? }?): TextLabel
	local o = opts or {}
	local l = make("TextLabel", { Name = "Text", Text = text, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, ZIndex = z }, parent)
	Style.text(l, o.outline or 2.5)
	l.TextColor3 = o.color or Color3.new(1, 1, 1)
	if o.max then make("UITextSizeConstraint", { MaxTextSize = o.max }, l) end
	if o.bold then
		Style.bold(l, o.bold)
		if o.max then
			for _, c in l:GetChildren() do
				if c:IsA("TextLabel") then make("UITextSizeConstraint", { MaxTextSize = o.max }, c) end
			end
		end
	end
	return l
end

-- a stable root frame with an ImageButton centred in it; hover/press scale the button
-- only (its UIScale), and every exit path puts it back
local function imageButton(parent: Instance, name: string, r: { number }, image: string, z: number, hoverScale: number, pressScale: number)
	local root = box(parent, name .. "Root", r, z)
	local b = make("ImageButton", { Name = name, Image = image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = z, Selectable = true }, root)
	local scale = make("UIScale", { Scale = 1 }, b)
	local hovered, down = false, false
	local tween: Tween? = nil
	local function settle()
		local target = if down then pressScale elseif hovered then hoverScale else 1
		if tween then tween:Cancel() end
		tween = TweenService:Create(scale, TweenInfo.new(if down then 0.07 else 0.12, Enum.EasingStyle.Quad), { Scale = target })
		;(tween :: Tween):Play()
	end
	b.MouseEnter:Connect(function() hovered = true settle() end)
	b.MouseLeave:Connect(function() hovered = false down = false settle() end)
	b.SelectionGained:Connect(function() hovered = true settle() end)
	b.SelectionLost:Connect(function() hovered = false down = false settle() end)
	b.MouseButton1Down:Connect(function() down = true settle() end)
	b.MouseButton1Up:Connect(function() down = false settle() end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then hovered = false down = false settle() end
	end)
	local function reset() hovered = false down = false if tween then tween:Cancel() end scale.Scale = 1 end
	return b, reset
end

export type Deps = { browse: () -> (), notice: (string) -> () }

function Offer.build(gui: ScreenGui, deps: Deps)
	local starter = O.StarterPack
	local product = Store.productById(starter.product)
	local crusherName = string.upper(((Config.Crushers.typeById(starter.crusher) :: any) or { name = starter.crusher }).name)

	local panel = make("Frame", { Name = "StarterOffer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, gui)
	make("UIAspectRatioConstraint", { AspectRatio = 1448 / 1086 }, panel)
	make("ImageLabel", { Name = "Background", Image = ART.Background, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch, ZIndex = 6 }, panel)

	-- titles and plaques
	words(box(panel, "OfferTitle", L.offerTitle, 8), "SPECIAL OFFER", 9, { bold = 3, color = C(255, 252, 240) })
	words(box(panel, "PackTitle", L.packTitle, 8), "STARTER PACK", 9, { bold = 4 })
	words(box(panel, "Rarity", L.rarity, 8), string.upper(starter.rarity), 9, { bold = 3 })

	-- the crusher (real portrait), floating gently
	local iconHome = box(panel, "CrusherIconHome", L.crusherIcon, 8)
	local icon = CrusherIcon.new(iconHome, starter.crusher, { size = UDim2.fromScale(1, 1), zIndex = 8 })
	words(box(panel, "CrusherName", L.crusherName, 8), crusherName, 9, { bold = 3 })
	words(box(panel, "CrusherDescription", L.crusherDescription, 8), "Guaranteed crusher", 9, { color = C(240, 228, 255) })

	-- cash + boost
	local function rewardIcon(name: string, r: { number }, image: string): (ImageLabel, UIScale)
		local home = box(panel, name .. "Home", r, 8)
		local img = make("ImageLabel", { Name = name, Image = image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, BackgroundTransparency = 1, ZIndex = 8 }, home)
		return img, make("UIScale", { Scale = 1 }, img)
	end
	local cashIcon, cashPop = rewardIcon("CashIcon", L.cashIcon, ShopArt.CashPacks.CashMedium)
	local cashTitle = words(box(panel, "CashAmount", L.cashAmount, 8), "CASH", 9, { bold = 3 })
	words(box(panel, "CashDescription", L.cashDescription, 8), "Instant cash", 9, { color = C(235, 255, 245) })
	local boostIcon, boostPop = rewardIcon("BoostIcon", L.boostIcon, Icons.DoubleCash)
	local boostMult = 2 -- the 2x Cash boost (BoostConfig "Cash" doubles cash)
	words(box(panel, "BoostTitle", L.boostTitle, 8), boostMult .. "x " .. string.upper(starter.boost.id), 9, { bold = 3 })
	words(box(panel, "BoostDuration", L.boostDuration, 8), tostring(starter.boost.minutes) .. "-minute boost", 9, { color = C(255, 236, 255) })
	-- cash/boost pop 4% while the pointer is over their card
	for _, pair in { { cashIcon, cashPop, { 0.475, 0.255, 0.43, 0.215 } }, { boostIcon, boostPop, { 0.475, 0.49, 0.43, 0.225 } } } do
		local hit = box(panel, "Hover", pair[3] :: any, 7)
		local pop = pair[2] :: UIScale
		hit.MouseEnter:Connect(function() TweenService:Create(pop, TweenInfo.new(0.12), { Scale = 1.04 }):Play() end)
		hit.MouseLeave:Connect(function() TweenService:Create(pop, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	end

	-- buttons
	local buy, resetBuy = imageButton(panel, "Buy", L.purchaseButton, ART.Purchase, 10, 1.035, 0.97)
	local buyTextHome = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.86, 0.56),
		BackgroundTransparency = 1, ZIndex = 11 }, buy)
	local buyText = words(buyTextHome, "GET STARTER PACK", 11, { bold = 4 })
	local close, resetClose = imageButton(panel, "Close", L.closeButton, ART.Close, 12, 1.07, 0.94)
	local xHome = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.56, 0.56),
		BackgroundTransparency = 1, ZIndex = 13 }, close)
	words(xHome, "X", 13, { bold = 4 })
	local browse = make("TextButton", { Name = "Browse", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 10 }, panel)
	browse.Position, browse.Size = rect(L.browseShopButton)
	local browseText = words(browse, "<u>Browse shop</u>", 10, { outline = 2 })
	browseText.RichText = true

	Style.modal(panel)
	panel:SetAttribute("FitWidth", W) panel:SetAttribute("FitHeight", H)

	-- live data ---------------------------------------------------------------------------
	local price: number? = nil
	local priceAsked = false
	local function paint()
		local rate = (player:GetAttribute("CashRate") :: number?) or 0
		cashTitle.Text = Format.cash(Store.cashFor(rate, starter.cashMinutes * 60)) .. " CASH"
		if not product or product.productId == 0 then buyText.Text = "COMING SOON"
		elseif price then buyText.Text = "GET STARTER PACK · R$ " .. price
		else buyText.Text = "GET STARTER PACK" end
	end
	local function askPrice()
		if priceAsked or not product or product.productId == 0 then return end
		priceAsked = true
		task.spawn(function()
			local ok, info = pcall(function() return MarketplaceService:GetProductInfoAsync(product.productId, Enum.InfoType.Product) end)
			if ok and info and type(info.PriceInRobux) == "number" then price = info.PriceInRobux else priceAsked = false end
			paint()
		end)
	end

	local function hide() if panel.Visible then Style.setOpen(panel, false) end end
	close.Activated:Connect(hide)
	browse.Activated:Connect(function() hide() task.delay(0.15, deps.browse) end)
	local lastBuy = 0
	buy.Activated:Connect(function()
		if not product or product.productId == 0 then deps.notice("Coming soon!") return end
		if os.clock() - lastBuy < 1.5 then return end -- one prompt per tap (Roblox shows its own window)
		lastBuy = os.clock()
		Net.event("OfferAction"):FireServer("Prompt", starter.product)
	end)
	player:GetAttributeChangedSignal("Offer_" .. starter.id):Connect(function()
		if player:GetAttribute("Offer_" .. starter.id) == true then hide() end
	end)

	-- idle motion (only while open) ---------------------------------------------------------
	local loop: RBXScriptConnection? = nil
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			askPrice() paint()
			if not loop then
				local t0 = os.clock()
				local nextPaint = 0
				loop = RunService.RenderStepped:Connect(function()
					local t = os.clock() - t0
					-- the crusher: +/-3 px over ~3 s, a 1 degree tilt
					icon.Position = UDim2.new(0, 0, 0, math.sin(t * 2.1) * 3)
					icon.Rotation = math.sin(t * 1.4) * 1
					cashIcon.Position = UDim2.new(0.5, 0, 0.5, math.sin(t * 1.8 + 1) * 2)
					boostIcon.Position = UDim2.new(0.5, 0, 0.5, math.sin(t * 1.8 + 2.6) * 2)
					if os.clock() >= nextPaint then nextPaint = os.clock() + 1 paint() end
				end)
			end
		else
			if loop then loop:Disconnect() loop = nil end
			resetBuy() resetClose()
		end
	end)

	local api = {}
	api.panel = panel
	function api.open()
		if player:GetAttribute("Offer_" .. starter.id) == true then return false end
		paint()
		Style.setOpen(panel, true)
		return true
	end
	return api
end

return Offer
