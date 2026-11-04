--!strict
-- 4 Nov (Willem's mockup): the pushed Starter Pack offer as its own big card.
--   [ SPECIAL OFFER ]
--   [   STARTER PACK   ]                         [X]
--   | MYTHIC            |  | $9K CASH        |
--   | (Candy Colossus)  |  | Instant cash    |
--   | CANDY COLOSSUS    |  | 2x CASH         |
--   | Guaranteed crusher|  | 15-minute boost |
--   [ GET STARTER PACK · R$ 69 ]
--          Browse shop
-- Live data only: the real Candy Colossus portrait (CrusherIcon), the cash amount
-- from your current earnings (Store.cashFor, like the pack grants it), the boost
-- length from OfferConfig, and Roblox's own price (GetProductInfo; product id 0
-- shows SOON). Buying goes through the server's OfferAction "Prompt", exactly
-- like the shop. Everything gently hovers while the card is open.
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
local INK = Style.Colors.Ink
local W, H = 700, 552 -- design size: everything (pill on top to the Browse link) is inside it

local Offer = {}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function grad(p: Instance, a: Color3, b: Color3, rot: number?) make("UIGradient", { Rotation = rot or 90, Color = ColorSequence.new(a, b) }, p) end
-- chunky white text (thick dark outline + drop), text size capped
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, z: number, opts: { bold: number?, color: Color3?, align: Enum.TextXAlignment?, max: number?, outline: number? }?): TextLabel
	local o = opts or {}
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true,
		TextXAlignment = o.align or Enum.TextXAlignment.Center, ZIndex = z }, parent)
	Style.text(l, o.outline or 2.5)
	l.TextColor3 = o.color or Color3.new(1, 1, 1)
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = o.max or 60 }, l)
	if o.bold then
		local face = Style.bold(l, o.bold)
		for _, c in l:GetChildren() do
			if c:IsA("TextLabel") then make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = o.max or 60 }, c) end
		end
		local _ = face
	end
	return l
end
-- a glossy top half (the shine on buttons and cards)
local function gloss(p: GuiObject, r: number, z: number, alpha: number?)
	local g = make("Frame", { Name = "Gloss", Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0.45, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = alpha or 0.8, BorderSizePixel = 0, ZIndex = z }, p)
	corner(g, r)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1) }, g)
	return g
end
local function rivet(parent: Instance, x: number, y: number, size: number, color: Color3, z: number)
	local r = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z }, parent)
	corner(r, size)
	make("UIStroke", { Thickness = 2, Color = Style.darken(color, 0.4), Transparency = 0.2 }, r)
	return r
end
-- yellow / dark diagonal hazard stripes (a CanvasGroup clips the rotated bars)
local function hazard(parent: Instance, pos: UDim2, size: Vector2, z: number)
	local g = make("CanvasGroup", { Position = pos, Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = C(34, 26, 80),
		BorderSizePixel = 0, ZIndex = z }, parent)
	for x = -size.Y, size.X + size.Y, 26 do
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, size.Y / 2), Size = UDim2.fromOffset(12, size.Y * 2.4),
			Rotation = 35, BackgroundColor3 = C(255, 196, 30), BorderSizePixel = 0, ZIndex = z + 1 }, g)
	end
	return g
end
-- little yellow "shine" ticks next to an icon (they flicker)
local function sparks(parent: Instance, x: number, y: number, z: number): { Frame }
	local list = {}
	for i, a in { -50, -20, 10 } do
		local s = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(x + (i - 2) * 14, y + math.abs(i - 2) * 6),
			Size = UDim2.fromOffset(5, 16), Rotation = a, BackgroundColor3 = C(255, 222, 60), BorderSizePixel = 0, ZIndex = z }, parent)
		corner(s, 3)
		table.insert(list, s)
	end
	return list
end

export type Deps = { browse: () -> (), notice: (string) -> () }

function Offer.build(gui: ScreenGui, deps: Deps)
	local starter = O.StarterPack
	local product = Store.productById(starter.product)
	local crusherName = string.upper(((Config.Crushers.typeById(starter.crusher) :: any) or { name = starter.crusher }).name)

	local panel = make("Frame", { Name = "StarterOffer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, gui)
	-- everything that hovers lives in `float` so the modal's scale stays on `panel`
	local float = make("Frame", { Name = "Float", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, panel)

	-- body: ink rim, cyan frame, deep indigo face ------------------------------------
	local rim = make("Frame", { Name = "Rim", Position = UDim2.fromOffset(34, 56), Size = UDim2.fromOffset(W - 68, H - 66),
		BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 5 }, float)
	corner(rim, 32)
	local body = make("Frame", { Name = "Body", Position = UDim2.fromOffset(40, 62), Size = UDim2.fromOffset(W - 80, H - 78),
		BackgroundColor3 = C(62, 50, 160), BorderSizePixel = 0, ZIndex = 6 }, float)
	corner(body, 28)
	make("UIStroke", { Thickness = 6, Color = C(70, 205, 255) }, body)
	grad(body, C(74, 62, 178), C(46, 36, 128))
	local inner = make("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1, ZIndex = 6 }, body)
	corner(inner, 20)
	make("UIStroke", { Thickness = 3, Color = C(36, 26, 100), Transparency = 0.15 }, inner)
	-- gold corner brackets with a bolt
	for _, c in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local b = make("Frame", { AnchorPoint = c, Position = UDim2.new(c.X, if c.X == 0 then -8 else 8, c.Y, if c.Y == 0 then -8 else 8),
			Size = UDim2.fromOffset(46, 46), BackgroundColor3 = C(255, 196, 40), BorderSizePixel = 0, ZIndex = 9 }, body)
		corner(b, 12) stroke(b, 3)
		grad(b, C(255, 226, 90), C(240, 150, 20))
		rivet(b, 23, 23, 14, C(255, 236, 140), 10)
	end
	-- rivets along the frame
	for _, p in { Vector2.new(22, 140), Vector2.new(22, 300), Vector2.new(W - 102, 140), Vector2.new(W - 102, 300) } do
		rivet(body, p.X, p.Y, 12, C(86, 74, 190), 7)
	end
	-- (they peek out on both sides of the banner, like the mockup)
	hazard(body, UDim2.fromOffset(60, 24), Vector2.new(70, 26), 7)
	hazard(body, UDim2.fromOffset(484, 24), Vector2.new(60, 26), 7)

	-- banner + "SPECIAL OFFER" pill ------------------------------------------------------
	local banner = make("Frame", { Name = "Banner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.fromOffset(380, 96), BackgroundColor3 = C(255, 64, 150), BorderSizePixel = 0, ZIndex = 11 }, float)
	corner(banner, 24) stroke(banner, 5)
	grad(banner, C(255, 120, 196), C(222, 28, 120))
	gloss(banner, 18, 12, 0.75)
	rivet(banner, 20, 48, 14, C(255, 150, 205), 13)
	rivet(banner, 360, 48, 14, C(255, 150, 205), 13)
	words(banner, "STARTER PACK", UDim2.fromOffset(34, 14), UDim2.new(1, -68, 0, 66), 14, { bold = 4, max = 64 })
	local pill = make("Frame", { Name = "Pill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(236, 48), BackgroundColor3 = C(255, 200, 40), BorderSizePixel = 0, ZIndex = 16 }, float)
	corner(pill, 24) stroke(pill, 4)
	grad(pill, C(255, 228, 90), C(250, 160, 20))
	words(pill, "SPECIAL OFFER", UDim2.fromOffset(14, 7), UDim2.new(1, -28, 1, -14), 17, { bold = 3, max = 34, color = C(255, 252, 240) })

	-- close
	local close = make("TextButton", { Name = "Close", Position = UDim2.fromOffset(588, 70), Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = C(235, 40, 60), Text = "", AutoButtonColor = true, ZIndex = 16 }, float)
	corner(close, 16) stroke(close, 4)
	grad(close, C(255, 90, 100), C(205, 20, 40))
	gloss(close, 12, 17, 0.75)
	words(close, "X", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 1, -16), 18, { bold = 4, max = 46 })

	-- left: the crusher -----------------------------------------------------------------
	local left = make("CanvasGroup", { Name = "Crusher", Position = UDim2.fromOffset(68, 160), Size = UDim2.fromOffset(250, 262),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 10 }, float)
	corner(left, 22)
	grad(left, C(70, 170, 255), C(170, 60, 225))
	local rays = make("Frame", { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(125, 110),
		Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, ZIndex = 10 }, left)
	for i = 0, 11 do
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(46, 560), Rotation = i * 15,
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = if i % 2 == 0 then 0.74 else 1, BorderSizePixel = 0, ZIndex = 10 }, rays)
	end
	local glow = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(125, 112), Size = UDim2.fromOffset(190, 190),
		BackgroundColor3 = C(255, 240, 255), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 10 }, left)
	corner(glow, 95)
	make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }) }, glow)
	-- (the outline sits on a plain frame over the CanvasGroup, so it stays crisp)
	local leftRim = make("Frame", { Position = left.Position, Size = left.Size, BackgroundTransparency = 1, ZIndex = 12 }, float)
	corner(leftRim, 22) make("UIStroke", { Thickness = 5, Color = INK }, leftRim)
	local icon = CrusherIcon.new(leftRim, starter.crusher, { size = UDim2.fromOffset(200, 150), position = UDim2.fromOffset(25, 38), zIndex = 13 })
	local iconScale = make("UIScale", { Scale = 1 }, icon)
	local mythic = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -16), Size = UDim2.fromOffset(150, 42),
		BackgroundColor3 = C(255, 60, 160), BorderSizePixel = 0, ZIndex = 15 }, leftRim)
	corner(mythic, 21) stroke(mythic, 4)
	grad(mythic, C(255, 110, 200), C(220, 30, 130))
	words(mythic, string.upper(starter.rarity), UDim2.fromOffset(12, 5), UDim2.new(1, -24, 1, -10), 16, { bold = 3, max = 32 })
	words(leftRim, crusherName, UDim2.fromOffset(14, 186), UDim2.new(1, -28, 0, 44), 14, { bold = 3, max = 36 })
	words(leftRim, "Guaranteed crusher", UDim2.fromOffset(14, 230), UDim2.new(1, -28, 0, 24), 14, { max = 24, color = C(240, 228, 255) })

	-- right: cash + boost ---------------------------------------------------------------
	local function rewardCard(y: number, a: Color3, b: Color3, image: string, title: string, note: string): (Frame, ImageLabel, TextLabel, { Frame })
		local card = make("Frame", { Position = UDim2.fromOffset(338, y), Size = UDim2.fromOffset(296, 124), BackgroundColor3 = a,
			BorderSizePixel = 0, ZIndex = 10 }, float)
		corner(card, 22) stroke(card, 5)
		grad(card, a, b)
		gloss(card, 18, 11, 0.82)
		for _, p in { Vector2.new(16, 16), Vector2.new(280, 16), Vector2.new(16, 108), Vector2.new(280, 108) } do rivet(card, p.X, p.Y, 10, Style.lighten(b, 0.1), 11) end
		local img = make("ImageLabel", { Image = image, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(70, 66), Size = UDim2.fromOffset(104, 96), ZIndex = 13 }, card)
		local sp = sparks(card, 70, 22, 14)
		local t = words(card, title, UDim2.fromOffset(122, 20), UDim2.fromOffset(164, 50), 13, { bold = 3, max = 44 })
		words(card, note, UDim2.fromOffset(122, 72), UDim2.fromOffset(164, 30), 13, { max = 26, color = C(240, 255, 248) })
		return card, img, t, sp
	end
	local cashCard, cashIcon, cashTitle, cashSparks = rewardCard(160, C(40, 228, 160), C(16, 170, 130), ShopArt.CashPacks.CashMedium, "$0 CASH", "Instant cash")
	local boostCard, boostIcon, _, boostSparks = rewardCard(298, C(232, 86, 230), C(170, 36, 196), Icons.DoubleCash, "2x CASH",
		tostring(starter.boost.minutes) .. "-minute boost")
	local _ = cashCard local _b = boostCard

	-- buy + browse ----------------------------------------------------------------------
	local buy = make("TextButton", { Name = "Buy", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 436), Size = UDim2.fromOffset(520, 64),
		BackgroundColor3 = C(110, 225, 40), Text = "", AutoButtonColor = false, ZIndex = 12 }, float)
	corner(buy, 32) stroke(buy, 5)
	grad(buy, C(150, 245, 60), C(60, 185, 30))
	gloss(buy, 26, 13, 0.7)
	local buyScale = make("UIScale", { Scale = 1 }, buy)
	-- a light sweep that runs across the button now and then
	local shine = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 13 }, buy)
	corner(shine, 32)
	local shineGrad = make("UIGradient", { Rotation = 20, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, shine)
	local buyText = words(buy, "GET STARTER PACK", UDim2.fromOffset(24, 9), UDim2.new(1, -48, 1, -18), 15, { bold = 4, max = 46 })
	local browse = make("TextButton", { Name = "Browse", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 500), Size = UDim2.fromOffset(200, 44),
		BackgroundTransparency = 1, Text = "", ZIndex = 12 }, float)
	local browseText = words(browse, "<u>Browse shop</u>", UDim2.fromOffset(0, 10), UDim2.new(1, 0, 0, 26), 13, { max = 26, outline = 2 })
	browseText.RichText = true
	-- (the body reaches down to the button; the link sits on the rim below it)
	rim.Size = UDim2.fromOffset(W - 68, 498 + 52 - 56) body.Size = UDim2.fromOffset(W - 80, 498 + 40 - 62)

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
			local ok, info = pcall(function() return MarketplaceService:GetProductInfo(product.productId, Enum.InfoType.Product) end)
			if ok and info and type(info.PriceInRobux) == "number" then price = info.PriceInRobux else priceAsked = false end
			paint()
		end)
	end

	local function hide() if panel.Visible then Style.setOpen(panel, false) end end
	close.Activated:Connect(hide)
	browse.Activated:Connect(function() hide() task.delay(0.15, deps.browse) end)
	buy.MouseButton1Down:Connect(function() TweenService:Create(buyScale, TweenInfo.new(0.06), { Scale = 0.94 }):Play() end)
	buy.Activated:Connect(function()
		if not product or product.productId == 0 then deps.notice("Coming soon!") return end
		Net.event("OfferAction"):FireServer("Prompt", starter.product)
	end)
	player:GetAttributeChangedSignal("Offer_" .. starter.id):Connect(function()
		if player:GetAttribute("Offer_" .. starter.id) == true then hide() end
	end)

	-- hovering ----------------------------------------------------------------------------
	local loop: RBXScriptConnection? = nil
	local function animate()
		local t0 = os.clock()
		local nextPaint = 0
		loop = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			float.Position = UDim2.fromOffset(0, math.sin(t * 1.4) * 3)
			banner.Position = UDim2.new(0.5, 0, 0, 40 + math.sin(t * 1.9 + 0.6) * 2)
			pill.Rotation = math.sin(t * 2.2) * 2.5
			icon.Position = UDim2.fromOffset(25, 38 + math.sin(t * 2) * 7)
			icon.Rotation = math.sin(t * 1.3) * 3
			iconScale.Scale = 1 + math.sin(t * 2) * 0.03
			rays.Rotation = t * 10
			glow.BackgroundTransparency = 0.5 + 0.12 * math.sin(t * 2.6)
			mythic.Rotation = math.sin(t * 2.4 + 1) * 2
			cashIcon.Position = UDim2.fromOffset(70, 66 + math.sin(t * 2.5 + 1) * 5)
			cashIcon.Rotation = math.sin(t * 1.8 + 1) * 6
			boostIcon.Position = UDim2.fromOffset(70, 66 + math.sin(t * 2.5 + 2.6) * 5)
			boostIcon.Rotation = math.sin(t * 1.8 + 2.6) * 6
			for i, s in cashSparks do s.BackgroundTransparency = 0.5 + 0.5 * math.sin(t * 5 + i) end
			for i, s in boostSparks do s.BackgroundTransparency = 0.5 + 0.5 * math.sin(t * 5 + i + 2) end
			local pulse = 1 + 0.035 * math.sin(t * 3.2)
			if buyScale.Scale > 0.95 then buyScale.Scale = pulse end
			-- the shine crosses the button every 2.6 s
			local phase = (t % 2.6) / 2.6
			shineGrad.Offset = Vector2.new(-1 + phase * 3, 0)
			if os.clock() >= nextPaint then nextPaint = os.clock() + 1 paint() end
		end)
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			askPrice() paint()
			if not loop then animate() end
		elseif loop then
			loop:Disconnect() loop = nil
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
