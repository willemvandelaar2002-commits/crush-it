--!strict
-- The shop window (built by Shop.client inside ShopHud): gold studded header
-- with the tilted basket, tabs FEATURED / CRATES / PACKS / PASSES / CASH, wide
-- illustrated offer banners, detail pages and the crate reveal.
--
-- Offers (Starter Pack, Factory Crate, Prism Mech) are bought through the
-- server (OfferAction "Prompt"), which checks ownership and crate eligibility
-- first. Prices shown are Roblox's own (GetProductInfo); a product or pass
-- with id 0 shows SOON. Odds come from Shared/OfferConfig and are shown
-- before any crate can be bought.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Store = require(ReplicatedStorage.Shared.Store)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local Format = require(ReplicatedStorage.Shared.Format)
local O = require(ReplicatedStorage.Shared.OfferConfig)
local BoostConfig = require(ReplicatedStorage.Shared.BoostConfig)
local CrusherConfig = require(ReplicatedStorage.Shared.CrusherConfig)
local CrusherIcons = require(ReplicatedStorage.Shared.CrusherIcons)
local FactoryCrateCard = require(script.Parent.FactoryCrateCard)
local StarterPackCard = require(script.Parent.StarterPackCard)
local PrismMechCard = require(script.Parent.PrismMechCard)
local ShopArt = require(ReplicatedStorage.Shared.ShopArt)

local player = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local NAVY = C(34, 40, 78)
local NAVY_DARK = C(22, 26, 52)
local GREY = C(120, 124, 140)
local W, H = 860, 590
local CONTENT_W = W - 28
local BANNER_W = CONTENT_W - 16

local Panel = {}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do (i :: any)[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function outline(p: Instance, t: number, c: Color3?): UIStroke
	return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?, z: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z or 3 }, parent)
	Style.text(l, stroke or 2.5)
	return l
end
local function gradient(p: Instance, colors: { Color3 }, rotation: number?): UIGradient
	local keys = {}
	for i, c in colors do keys[i] = ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c) end
	return make("UIGradient", { Color = ColorSequence.new(keys), Rotation = rotation or 90 }, p)
end
local function icon(parent: Instance, image: string?, pos: UDim2, size: UDim2, z: number?): ImageLabel
	return make("ImageLabel", { Image = image or Icons.Press, Position = pos, Size = size, BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, ZIndex = z or 3 }, parent)
end
local function crusherImage(typeId: string): string
	return CrusherIcons.image(typeId) or Icons.Press
end
local function typeName(typeId: string): string
	local t = CrusherConfig.typeById(typeId)
	return if t then t.name else typeId
end
-- a rounded pill with outlined text
local function pill(parent: Instance, text: string, pos: UDim2, size: UDim2, fill: Color3, edge: Color3?, z: number?): (Frame, TextLabel)
	local f = make("Frame", { Position = pos, Size = size, BackgroundColor3 = fill, ZIndex = z or 3 }, parent)
	corner(f, 99)
	outline(f, 3, edge or INK)
	local l = label(f, text, UDim2.new(0, 10, 0.14, 0), UDim2.new(1, -20, 0.72, 0), 2, (z or 3) + 1)
	return f, l
end
-- big glossy action button
local function bigButton(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3?, z: number?): TextButton
	local b = make("TextButton", { Text = "", Position = pos, Size = size, ZIndex = z or 4 }, parent)
	Style.button(b, color or Style.GREEN)
	local l = label(b, text, UDim2.fromScale(0.06, 0.14), UDim2.fromScale(0.88, 0.72), 3, (z or 4) + 1)
	l.Name = "Caption"
	return b
end
local function setCaption(b: TextButton, text: string, color: Color3)
	(b:FindFirstChild("Caption") :: TextLabel).Text = text
	Style.setButtonColor(b, color)
end
local function shake(g: GuiObject)
	task.spawn(function()
		for _, d in { -5, 5, -3, 3, 0 } do
			TweenService:Create(g, TweenInfo.new(0.04), { Rotation = d }):Play()
			task.wait(0.04)
		end
	end)
end

-- Robux prices straight from Roblox (cached; nil while loading or for id 0)
local prices: { [string]: number } = {}
local loading: { [string]: boolean } = {}
local priceListeners: { () -> () } = {}
local function priceOf(kind: string, id: number): number?
	if id == 0 then return nil end
	local key = kind .. id
	if prices[key] then return prices[key] end
	if not loading[key] then
		loading[key] = true
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(id, if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			end)
			if ok and info and type(info.PriceInRobux) == "number" then
				prices[key] = info.PriceInRobux
				for _, f in priceListeners do f() end
			else
				loading[key] = nil
			end
		end)
	end
	return nil
end

function Panel.build(gui: ScreenGui, deps: { notice: (string) -> (), buyPass: (string) -> (), buyProduct: (string) -> () })
	local offerAction = Net.event("OfferAction")
	local state: any = { owned = {}, reveals = {}, crates = "checking" }
	local refreshers: { () -> () } = {}
	local function refreshAll() for _, f in refreshers do f() end end
	table.insert(priceListeners, refreshAll)

	local function owns(id: string): boolean
		return state.owned[id] == true or player:GetAttribute("Offer_" .. id) == true
	end

	-- Window ---------------------------------------------------------------------------
	local panel = make("Frame", { Name = "ShopPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = NAVY, Visible = false, ZIndex = 5 }, gui)
	corner(panel, 16)
	outline(panel, 5)
	gradient(panel, { C(44, 52, 98), NAVY_DARK })
	local ps = Style.studsImage(panel, 30, 0.93) ps.ZIndex = 5
	panel:SetAttribute("FitWidth", W / 0.94) panel:SetAttribute("FitHeight", H / 0.92) -- 30 Oct: fitted by Style.modal
	Style.modal(panel)
	Style.focusBlur(panel, 12)
	local backdrop = gui:FindFirstChild(panel.Name .. "Backdrop") :: TextButton?
	if backdrop then backdrop.BackgroundTransparency = 0.52 end

	-- gold studded header with the tilted basket and the chunky red X
	local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20, 72), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, panel)
	corner(header, 12)
	outline(header, 4)
	gradient(header, { C(255, 236, 110), C(255, 205, 40), C(240, 160, 20) })
	local hs = Style.studsImage(header, 34, 0.15) hs.ZIndex = 6 hs.ImageColor3 = C(255, 214, 60)
	local basket = icon(header, Icons.Shop, UDim2.fromOffset(-26, -30), UDim2.fromOffset(118, 118), 9)
	basket.Rotation = -14
	local title = label(header, "SHOP", UDim2.fromOffset(98, 6), UDim2.fromOffset(220, 60), 4.5, 8)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local close = bigButton(header, "X", UDim2.new(1, -70, 0, 6), UDim2.fromOffset(62, 60), Style.Colors.Red, 8)
	close.Name = "Close"

	-- tabs
	local TABS = { "FEATURED", "CRATES", "PACKS", "PASSES", "CASH" }
	local tabBar = make("Frame", { Position = UDim2.fromOffset(14, 92), Size = UDim2.fromOffset(CONTENT_W, 42), BackgroundTransparency = 1, ZIndex = 6 }, panel)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
	local tabWidth = (CONTENT_W - 8 * (#TABS - 1)) / #TABS
	local tabButtons: { [string]: TextButton } = {}
	local pages: { [string]: ScrollingFrame } = {}
	local current = "FEATURED"
	local area = make("Frame", { Name = "Content", Position = UDim2.fromOffset(14, 144), Size = UDim2.fromOffset(CONTENT_W, H - 158), BackgroundTransparency = 1, ZIndex = 6, ClipsDescendants = true }, panel)

	local function newPage(name: string): ScrollingFrame
		local s = make("ScrollingFrame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8,
			ScrollBarImageColor3 = C(255, 214, 60), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, ZIndex = 6 }, area)
		make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, s)
		make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2) }, s)
		Style.scroll(s)
		pages[name] = s
		return s
	end

	local function paintTab(name: string)
		local b = tabButtons[name]
		local on = name == current
		local fill = b:FindFirstChild("Fill") :: UIGradient
		fill.Color = if on then ColorSequence.new(C(255, 120, 180), C(230, 40, 120)) else ColorSequence.new(C(52, 60, 104), C(32, 38, 72))
		local edge = b:FindFirstChild("Edge") :: UIStroke
		edge.Color = if on then C(255, 214, 60) else INK
		edge.Thickness = if on then 3.5 else 3
	end
	local detail: Frame -- set below
	local function showTab(name: string)
		current = name
		for n, p in pages do p.Visible = n == name end
		for n in tabButtons do paintTab(n) end
		detail.Visible = false
		pages[name].CanvasPosition = Vector2.zero
	end
	for i, name in TABS do
		local b = make("TextButton", { Name = name, Text = "", LayoutOrder = i, Size = UDim2.fromOffset(tabWidth, 42), BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, ZIndex = 7 }, tabBar)
		corner(b, 10)
		make("UIGradient", { Name = "Fill", Rotation = 90 }, b)
		make("UIStroke", { Name = "Edge", Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		label(b, name, UDim2.fromScale(0.08, 0.16), UDim2.fromScale(0.84, 0.68), 2.5, 8)
		Style.feedback(b)
		tabButtons[name] = b
		b.Activated:Connect(function() showTab(name) Net.event("ShopOpened"):FireServer("Tab" .. name) end)
		newPage(name)
	end

	-- Section heading "~ Title ~" -----------------------------------------------------
	local function heading(page: ScrollingFrame, text: string, order: number)
		local l = label(page, "~ " .. text .. " ~", UDim2.new(), UDim2.fromOffset(BANNER_W, 30), 2.5, 7)
		l.LayoutOrder = order
	end

	-- Banner frame: multi-colour gradient, studs, dark outline -------------------------
	local function banner(page: ScrollingFrame, order: number, colors: { Color3 }, height: number?): Frame
		local f = make("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(BANNER_W, height or 176), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 }, page)
		corner(f, 14)
		outline(f, 4)
		gradient(f, colors, 20)
		local st = Style.studsImage(f, 30, 0.82) st.ZIndex = 7
		make("Frame", { Name = "Shine", Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 8 }, f)
		return f
	end
	local function glow(parent: Instance, pos: UDim2, size: number)
		local g = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, ZIndex = 8 }, parent)
		corner(g, 999)
		make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }), Rotation = 0 }, g)
		return g
	end
	local function twoTone(parent: Instance, a: string, colorA: string, b: string, colorB: string, pos: UDim2, size: UDim2, z: number): TextLabel
		local l = label(parent, "", pos, size, 4, z)
		l.RichText = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = `<font color="{colorA}">{a}</font> <font color="{colorB}">{b}</font>`
		return l
	end
	-- An item chip: icon above a caption pill
	local function itemChip(parent: Instance, image: string, caption: string, pos: UDim2, z: number): Frame
		local f = make("Frame", { Position = pos, Size = UDim2.fromOffset(104, 98), BackgroundTransparency = 1, ZIndex = z }, parent)
		icon(f, image, UDim2.fromOffset(12, 0), UDim2.fromOffset(80, 70), z + 1)
		local p = pill(f, caption, UDim2.fromOffset(0, 66), UDim2.fromOffset(104, 30), C(255, 255, 255), INK, z + 1)
		p.BackgroundTransparency = 0.82
		return f
	end
	local function plus(parent: Instance, pos: UDim2, z: number)
		label(parent, "+", pos, UDim2.fromOffset(26, 40), 3, z)
	end

	-- Purchase button state for an offer product (SOON / OWNED / price) -------------
	local function offerButtonState(productKey: string, offerId: string?, isCrate: boolean?): (string, Color3, boolean)
		local product = Store.productById(productKey)
		if offerId and owns(offerId) then return "OWNED", GREY, false end
		if not product or product.productId == 0 then return "SOON", GREY, false end
		if isCrate and state.crates == "restricted" then return "UNAVAILABLE", GREY, false end
		if isCrate and state.crates ~= "allowed" then return "CHECKING...", GREY, false end
		local price = priceOf("product", product.productId)
		return if price then "R$ " .. price else "BUY", Style.GREEN, true
	end
	local function promptOffer(productKey: string, offerId: string?, isCrate: boolean?, button: TextButton)
		local _, _, ok = offerButtonState(productKey, offerId, isCrate)
		if not ok then
			shake(button)
			local product = Store.productById(productKey)
			if offerId and owns(offerId) then deps.notice("Already owned!")
			elseif not product or product.productId == 0 then deps.notice("Coming soon!")
			elseif isCrate and state.crates == "restricted" then deps.notice("Crates aren't available for your account.") end
			return
		end
		offerAction:FireServer("Prompt", productKey)
	end

	-- Detail page (covers the content area) ------------------------------------------
	detail = make("Frame", { Name = "Detail", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NAVY_DARK, Visible = false, ZIndex = 20 }, area)
	corner(detail, 14)
	outline(detail, 4)
	local ds = Style.studsImage(detail, 30, 0.9) ds.ZIndex = 20
	local back = bigButton(detail, "< BACK", UDim2.fromOffset(12, 12), UDim2.fromOffset(120, 44), C(70, 130, 255), 24)
	back.Activated:Connect(function() detail.Visible = false end)
	local detailBody = make("Frame", { Name = "Body", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 21 }, detail)
	local detailRefresh: (() -> ())? = nil
	table.insert(refreshers, function() if detail.Visible and detailRefresh then detailRefresh() end end)
	local detailTween: Tween? = nil
	local function openDetail(build: (Frame) -> (() -> ())?)
		detailBody:ClearAllChildren()
		detailRefresh = build(detailBody)
		if detailTween then detailTween:Cancel() end
		detail.Position = UDim2.fromOffset(12, 0)
		detail.Visible = true
		detailTween = TweenService:Create(detail, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new() })
		detailTween:Play()
		if detailRefresh then detailRefresh() end
	end
	local function detailTitle(text: string, color: Color3?)
		local t = label(detailBody, text, UDim2.fromOffset(146, 10), UDim2.new(1, -170, 0, 48), 4, 22)
		t.TextXAlignment = Enum.TextXAlignment.Left
		if color then t.TextColor3 = color end
	end
	-- a row: icon, name, sub text, right text (odds)
	local function detailRow(y: number, image: string, name: string, sub: string, right: string?, accent: Color3, height: number?): Frame
		local h = height or 86
		local r = make("Frame", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, h), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 22 }, detailBody)
		corner(r, 12)
		outline(r, 3)
		gradient(r, { Style.lighten(accent, 0.05), Style.darken(accent, 0.35) }, 0)
		icon(r, image, UDim2.fromOffset(10, 4), UDim2.fromOffset(h - 8, h - 8), 23)
		local n = label(r, name, UDim2.fromOffset(h + 14, h * 0.1), UDim2.new(0.55, -h - 14, 0, h * 0.44), 3, 23)
		n.TextXAlignment = Enum.TextXAlignment.Left
		local s = label(r, sub, UDim2.fromOffset(h + 14, h * 0.56), UDim2.new(0.62, -h - 14, 0, h * 0.3), 2, 23)
		s.TextXAlignment = Enum.TextXAlignment.Left
		s.TextColor3 = C(235, 238, 255)
		if right then
			local o = label(r, right, UDim2.new(1, -190, 0.5, -24), UDim2.fromOffset(170, 48), 3.5, 23)
			o.TextXAlignment = Enum.TextXAlignment.Right
			o.TextColor3 = C(255, 236, 110)
		end
		return r
	end

	local starter = O.StarterPack
	local boost = BoostConfig.find(starter.boost.id)
	local crate = O.Crates[1]
	local odds, rounded = O.odds(crate)
	local show = O.Showroom
	local mythicDesc = "MYTHIC crusher · 3x Legendary output"

	local function starterDetail(body: Frame)
		detailTitle(string.upper(starter.title), C(255, 150, 215))
		detailRow(70, crusherImage(starter.crusher), typeName(starter.crusher), mythicDesc, "x1", C(255, 90, 170))
		detailRow(166, Icons.Cash, Format.cash(Store.cashFor((player:GetAttribute("CashRate") :: number?) or 0, starter.cashMinutes * 60)) .. " cash", starter.cashMinutes .. " min of your earnings, right away", "x1", C(60, 180, 90))
		detailRow(262, (Icons :: any)[boost.icon] or Icons.DoubleCash, boost.title .. " boost", starter.boost.minutes .. " minutes · " .. boost.desc, "x1", boost.color)
		local note = label(body, "One-time pack: everything above is guaranteed, once per player.", UDim2.fromOffset(20, 360), UDim2.new(1, -300, 0, 26), 2, 22)
		note.TextXAlignment = Enum.TextXAlignment.Left
		local buy = bigButton(body, "BUY", UDim2.new(1, -260, 1, -78), UDim2.fromOffset(240, 64), nil, 24)
		buy.Activated:Connect(function() promptOffer(starter.product, starter.id, false, buy) end)
		return function()
			local text, color = offerButtonState(starter.product, starter.id)
			setCaption(buy, text, color)
		end
	end
	local function crateDetail(body: Frame)
		detailTitle(string.upper(crate.title), C(255, 220, 90))
		local sub = label(body, "You get exactly ONE of these crushers. Chances:", UDim2.fromOffset(20, 64), UDim2.new(1, -40, 0, 28), 2.5, 22)
		sub.TextXAlignment = Enum.TextXAlignment.Left
		local list = make("ScrollingFrame", { Position = UDim2.fromOffset(0, 94), Size = UDim2.new(1, 0, 0, 250), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 8, ScrollBarImageColor3 = C(255, 214, 60), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 22 }, body)
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		make("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 2) }, list)
		for i, o in odds do
			local r = CrusherConfig.rarityOf(o.type)
			local row = detailRow(0, crusherImage(o.type), typeName(o.type), string.upper(r.name) .. " crusher", o.text, r.color, 70)
			row.Parent = list
			row.Position = UDim2.new()
			row.Size = UDim2.new(1, -10, 0, 70)
			row.LayoutOrder = i
		end
		local notes = {}
		if rounded then table.insert(notes, O.RoundingNote) end
		if crate.provisional and RunService:IsStudio() then table.insert(notes, "(Studio: test odds, not final.)") end
		local n = label(body, table.concat(notes, " "), UDim2.fromOffset(20, 380), UDim2.new(1, -300, 0, 40), 1.5, 22)
		n.TextWrapped = true
		n.TextXAlignment = Enum.TextXAlignment.Left
		local buy = bigButton(body, "BUY x1", UDim2.new(1, -260, 0, 352), UDim2.fromOffset(240, 64), nil, 24)
		local bundle = crate.bundles[1]
		buy.Activated:Connect(function() promptOffer(bundle.product, nil, true, buy) end)
		local why = label(body, "", UDim2.fromOffset(20, 348), UDim2.new(1, -300, 0, 28), 2, 22)
		why.TextXAlignment = Enum.TextXAlignment.Left
		why.TextColor3 = C(255, 170, 170)
		return function()
			local text, color = offerButtonState(bundle.product, nil, true)
			setCaption(buy, if text:sub(1, 3) == "R$ " then "x1  " .. text else text, color)
			why.Text = if state.crates == "restricted" then "Crates aren't available for your account." else ""
		end
	end
	local function showroomDetail(body: Frame)
		detailTitle(string.upper(show.title), C(140, 240, 255))
		local art = make("Frame", { Position = UDim2.fromOffset(20, 70), Size = UDim2.fromOffset(270, 270), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 22 }, body)
		corner(art, 16)
		outline(art, 4)
		gradient(art, { C(70, 230, 255), C(150, 90, 255), C(255, 100, 200) }, 45)
		icon(art, crusherImage(show.crusher), UDim2.fromOffset(12, 12), UDim2.fromOffset(246, 246), 23)
		local lines = {
			"GUARANTEED: you get exactly this crusher",
			mythicDesc,
			"Works in any bay, like your other crushers",
			"See it running on the pad in your factory",
		}
		for i, line in lines do
			local l = label(body, "• " .. line, UDim2.fromOffset(310, 70 + (i - 1) * 44), UDim2.new(1, -330, 0, 34), 2.5, 22)
			l.TextXAlignment = Enum.TextXAlignment.Left
		end
		local find = bigButton(body, "FIND ON PLOT", UDim2.new(1, -520, 1, -78), UDim2.fromOffset(240, 64), C(255, 196, 40), 24)
		find.Activated:Connect(function()
			Net.event("Travel"):FireServer("Plot")
			Style.setOpen(panel, false)
		end)
		local buy = bigButton(body, "BUY", UDim2.new(1, -260, 1, -78), UDim2.fromOffset(240, 64), nil, 24)
		buy.Activated:Connect(function() promptOffer(show.product, show.id, false, buy) end)
		return function()
			local text, color = offerButtonState(show.product, show.id)
			setCaption(buy, text, color)
		end
	end

	-- Banners --------------------------------------------------------------------------
	local function starterBanner(page: ScrollingFrame, order: number)
		-- 31 Oct: candy card (client/StarterPackCard); contents from OfferConfig/BoostConfig
		local function cashText(): (string, string)
			local m = starter.cashMinutes
			local span = if m % 60 == 0 then (m // 60) .. "H" else m .. " MIN"
			local cash = Store.cashFor((player:GetAttribute("CashRate") :: number?) or 0, m * 60)
			return if cash > 0 then Format.cash(cash) else span .. " OF CASH", span .. " EARNINGS"
		end
		StarterPackCard.build(page, {
			width = BANNER_W, order = order, gate = panel,
			enabled = function()
				local reveal = gui:FindFirstChild("CrateReveal") :: GuiObject?
				return not detail.Visible and not (reveal and reveal.Visible)
			end,
			open = function() openDetail(starterDetail) end,
			crusherImage = crusherImage(starter.crusher), crusherName = typeName(starter.crusher), rarity = starter.rarity,
			cashIcon = Icons.Cash, cashText = cashText,
			boostIcon = (Icons :: any)[boost.icon] or Icons.DoubleCash, boostTitle = boost.title, boostMinutes = starter.boost.minutes,
			owned = function() return owns(starter.id) end,
			onRefresh = function(f) table.insert(refreshers, f) f() end,
		})
	end
	local function crateArt(parent: Instance, pos: UDim2, size: number, z: number): Frame
		-- the Factory Crate image (29 Oct; replaces the blue crate drawn in UI)
		local box = make("Frame", { Position = pos, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z }, parent)
		make("ImageLabel", { Name = "CrateImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Icons.FactoryCrate,
			ScaleType = Enum.ScaleType.Fit, ZIndex = z + 1 }, box)
		return box
	end
	local function crateBanner(page: ScrollingFrame, order: number)
		FactoryCrateCard.build(page, {
			width = BANNER_W, order = order, title = crate.title, odds = odds,
			crateImage = Icons.FactoryCrate, image = crusherImage, typeName = typeName, rarityOf = CrusherConfig.rarityOf,
			gate = panel,
			enabled = function()
				local reveal = gui:FindFirstChild("CrateReveal") :: GuiObject?
				return not detail.Visible and not (reveal and reveal.Visible)
			end,
			open = function() openDetail(crateDetail) end,
		})
	end
	local function showroomBanner(page: ScrollingFrame, order: number)
		-- 31 Oct: crystal card (client/PrismMechCard); same callbacks as before
		PrismMechCard.build(page, {
			width = BANNER_W, order = order, gate = panel,
			enabled = function()
				local reveal = gui:FindFirstChild("CrateReveal") :: GuiObject?
				return not detail.Visible and not (reveal and reveal.Visible)
			end,
			crusherImage = crusherImage(show.crusher), title = show.title, rarity = show.rarity, tag = show.tag,
			line = "Plot showcase: visit your plot to inspect it",
			find = function()
				Net.event("Travel"):FireServer("Plot")
				Style.setOpen(panel, false)
			end,
			details = function() openDetail(showroomDetail) end,
			owned = function() return owns(show.id) end,
			onRefresh = function(f) table.insert(refreshers, f) f() end,
		})
	end

	-- Product / pass cards (grid) -------------------------------------------------------
	local function grid(page: ScrollingFrame, order: number): Frame
		local g = make("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(BANNER_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 7 }, page)
		make("UIGridLayout", { CellSize = UDim2.fromOffset((BANNER_W - 24) / 3, 158), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, g)
		return g
	end
	local function card(parent: Frame, order: number, title: string, desc: string, color: Color3, image: string, onBuy: (TextButton) -> ()): (TextButton, TextLabel)
		local f = make("Frame", { LayoutOrder = order, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, parent)
		corner(f, 12)
		outline(f, 4)
		gradient(f, { Style.lighten(color, 0.12), Style.darken(color, 0.3) }, 25)
		local st = Style.studsImage(f, 26, 0.75) st.ZIndex = 8 st.ImageColor3 = color
		icon(f, image, UDim2.fromOffset(8, 10), UDim2.fromOffset(82, 82), 9)
		local t = label(f, title, UDim2.fromOffset(96, 10), UDim2.new(1, -104, 0, 32), 3, 9)
		t.TextXAlignment = Enum.TextXAlignment.Right
		local d = label(f, desc, UDim2.fromOffset(96, 44), UDim2.new(1, -104, 0, 48), 1.5, 9)
		d.TextScaled = true
		d.TextWrapped = true
		d.TextXAlignment = Enum.TextXAlignment.Right
		d.TextYAlignment = Enum.TextYAlignment.Top
		local b = bigButton(f, "", UDim2.new(1, -150, 1, -56), UDim2.fromOffset(140, 46), nil, 10)
		b.Activated:Connect(function() onBuy(b) end)
		return b, d
	end
	local PASS_ICONS: { [string]: string } = { AutoCrush = Icons.AutoCrush, DoubleCash = Icons.DoubleCash, Lucky = Icons.Lucky, OfflineEarnings = Icons.Offline, AutoCollect = Icons.Cash }
	local function passCards(page: ScrollingFrame, order: number)
		local g = grid(page, order)
		for i, pass in Store.Passes do
			local b = card(g, i, pass.title, pass.desc, pass.color, PASS_ICONS[pass.perk] or Icons.Shop, function(button)
				if Store.hasPass(player, pass.perk) then return end
				if pass.gamePassId == 0 then shake(button) end
				deps.buyPass(pass.perk)
			end)
			local function update()
				if Store.hasPass(player, pass.perk) then setCaption(b, "OWNED", GREY)
				elseif pass.gamePassId == 0 then setCaption(b, "SOON", GREY)
				else
					local price = priceOf("pass", pass.gamePassId)
					setCaption(b, if price then "R$ " .. price else "BUY", Style.GREEN)
				end
			end
			player:GetAttributeChangedSignal(Store.passAttr(pass.perk)):Connect(update)
			table.insert(refreshers, update)
		end
	end
	-- Cash pack card (31 Oct): its own icon per pack (ShopArt.CashPacks) in a
	-- 122 px slot on the left; title, live amount and earnings time in their own
	-- rows on the right; the buy button bottom-right, clear of the art.
	local function cashCard(parent: Frame, order: number, id: string, product: any, onBuy: (TextButton) -> ()): (TextButton, TextLabel)
		local f = make("Frame", { Name = "Cash_" .. id, LayoutOrder = order, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, parent)
		corner(f, 12)
		outline(f, 4)
		gradient(f, { Style.lighten(product.color, 0.12), Style.darken(product.color, 0.3) }, 25)
		local st = Style.studsImage(f, 26, 0.75) st.ZIndex = 8 st.ImageColor3 = product.color
		-- art slot: still at rest, grows/tilts a little on hover (text never moves)
		local slot = make("TextButton", { Name = "ArtSlot", Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
			Position = UDim2.fromOffset(4, 6), Size = UDim2.fromOffset(122, 122), ZIndex = 9 }, f)
		local fallback = icon(slot, Icons.Cash, UDim2.fromOffset(20, 20), UDim2.fromOffset(82, 82), 9)
		fallback.Name = "Fallback"
		local art = icon(slot, ShopArt.CashPacks[id] or Icons.Cash, UDim2.new(), UDim2.fromScale(1, 1), 10)
		art.Name = "Art"
		task.spawn(function()
			while art.Parent and not art.IsLoaded do task.wait(0.25) end
			if art.IsLoaded then fallback.Visible = false end
		end)
		Style.hoverLift(slot, { art = art, scale = 1.06, artScale = 1.04, lift = 2, tilt = 3, press = 0.97 })
		local t = label(f, product.title, UDim2.fromOffset(128, 8), UDim2.new(1, -136, 0, 30), 3, 9)
		t.TextXAlignment = Enum.TextXAlignment.Right
		local amount = label(f, "", UDim2.fromOffset(128, 40), UDim2.new(1, -136, 0, 32), 3, 9)
		amount.Name = "Amount"
		amount.TextXAlignment = Enum.TextXAlignment.Right
		amount.TextColor3 = C(255, 240, 120)
		local minutes = Store.CashPackMinutes[id] or 0
		local span = if minutes >= 60 and minutes % 60 == 0 then (minutes // 60) .. (if minutes == 60 then " hour" else " hours") else minutes .. " min"
		local note = label(f, span .. " of earnings", UDim2.fromOffset(128, 74), UDim2.new(1, -136, 0, 20), 1.5, 9)
		note.TextScaled = true
		note.TextWrapped = true
		note.TextXAlignment = Enum.TextXAlignment.Right
		local b = bigButton(f, "", UDim2.new(1, -128, 1, -52), UDim2.fromOffset(120, 44), nil, 10)
		b.Activated:Connect(function() onBuy(b) end)
		return b, amount
	end
	local function productCards(page: ScrollingFrame, order: number, ids: { string })
		local g = grid(page, order)
		for i, id in ids do
			local product = Store.productById(id)
			if not product then continue end
			local image = if Store.CashPackShare[id] then Icons.Cash elseif id == "GoldenRush" then Icons.Golden elseif id == "BoostLuck" then Icons.Lucky
				elseif id == "BoostSuper" then Icons.Golden elseif id == "BoostCash" then Icons.DoubleCash else Icons.Press
			local function buy(button: TextButton)
				if product.productId == 0 then shake(button) end
				deps.buyProduct(id)
			end
			local b, d
			if Store.CashPackShare[id] then b, d = cashCard(g, i, id, product, buy)
			else b, d = card(g, i, product.title, product.desc, product.color, image, buy) end
			local function update()
				if Store.CashPackShare[id] then d.Text = "+" .. Format.cash(Store.cashPackAmount(id, 1, (player:GetAttribute("CashRate") :: number?) or 0)) end
				if product.productId == 0 then setCaption(b, "SOON", GREY)
				else
					local price = priceOf("product", product.productId)
					setCaption(b, if price then "R$ " .. price else "BUY", Style.GREEN)
				end
			end
			table.insert(refreshers, update)
		end
	end

	-- Pages ------------------------------------------------------------------------------
	heading(pages.FEATURED, "Featured", 1)
	crateBanner(pages.FEATURED, 2)
	starterBanner(pages.FEATURED, 3)
	showroomBanner(pages.FEATURED, 4)

	heading(pages.CRATES, "Crates", 1)
	crateBanner(pages.CRATES, 2)
	local disclose = label(pages.CRATES, "Each crate gives exactly one crusher. Tap the crate or a crusher to see all rewards & exact chances.",
		UDim2.new(), UDim2.fromOffset(BANNER_W, 26), 1.5, 7)
	disclose.LayoutOrder = 3
	if rounded then
		local n = label(pages.CRATES, O.RoundingNote, UDim2.new(), UDim2.fromOffset(BANNER_W, 22), 1.5, 7)
		n.LayoutOrder = 4
	end

	heading(pages.PACKS, "Packs", 1)
	starterBanner(pages.PACKS, 2)
	showroomBanner(pages.PACKS, 3)
	heading(pages.PACKS, "Boosts", 4)
	productCards(pages.PACKS, 5, { "BoostCash", "BoostLuck", "BoostSuper" })

	heading(pages.PASSES, "Gamepasses", 1)
	passCards(pages.PASSES, 2)

	heading(pages.CASH, "Cash", 1)
	productCards(pages.CASH, 2, { "CashSmall", "CashMedium", "CashLarge" })

	showTab("FEATURED")

	-- Crate reveal -----------------------------------------------------------------------
	-- Shows a result the server already picked, saved and granted. SKIP jumps
	-- to the result; COLLECT tells the server it was seen. Anything else
	-- (closing the game mid-way) shows the same result again next time.
	local reveal = make("Frame", { Name = "CrateReveal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.12, Visible = false, ZIndex = 50, Active = true }, gui)
	local stage = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -50), Size = UDim2.fromOffset(520, 470), BackgroundTransparency = 1, ZIndex = 51 }, reveal)
	local stageScale = make("UIScale", {}, stage)
	local function stageFit(): number
		return math.min(1, (Workspace.CurrentCamera.ViewportSize.Y - 140) / 470)
	end
	local burst = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(420, 420), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 51 }, stage)
	corner(burst, 999)
	local burstGradient = make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, burst)
	burstGradient.Rotation = 0
	local crateBox = crateArt(stage, UDim2.fromOffset(150, 120), 220, 52)
	local prize = icon(stage, nil, UDim2.fromOffset(110, 40), UDim2.fromOffset(300, 300), 55)
	local prizeName = label(stage, "", UDim2.fromOffset(20, 340), UDim2.fromOffset(480, 58), 4, 56)
	local prizeRarity = label(stage, "MYTHIC!", UDim2.fromOffset(160, 398), UDim2.fromOffset(200, 34), 3, 56)
	prizeRarity.TextColor3 = C(255, 90, 200)
	local prizeNote = label(stage, "Added to your inventory", UDim2.fromOffset(110, 434), UDim2.fromOffset(300, 26), 2, 56)
	local skip = bigButton(reveal, "SKIP", UDim2.new(0.5, -90, 1, -86), UDim2.fromOffset(180, 60), C(70, 130, 255), 60)
	skip.Name = "Skip"
	local collect = bigButton(reveal, "COLLECT", UDim2.new(0.5, -120, 1, -90), UDim2.fromOffset(240, 66), nil, 60)
	collect.Name = "Collect"
	local revealing: any = nil
	local revealToken = 0
	local function showResult()
		if not revealing then return end
		revealToken += 1
		crateBox.Visible = false
		prize.Visible = true
		prize.Image = crusherImage(revealing.type)
		prizeName.Text = typeName(revealing.type)
		local rarity = CrusherConfig.rarityOf(revealing.type)
		prizeRarity.Text = (if rarity then string.upper(rarity.name) else "NEW") .. "!"
		prizeRarity.TextColor3 = if rarity then Style.lighten(rarity.color, 0.15) else C(255, 90, 200)
		prizeName.Visible = true
		prizeRarity.Visible = true
		prizeNote.Visible = true
		burst.BackgroundTransparency = 0.2
		burst.BackgroundColor3 = C(255, 120, 220)
		TweenService:Create(burst, TweenInfo.new(0.8), { BackgroundTransparency = 0.65 }):Play()
		local s = make("UIScale", { Scale = 0.3 }, prize)
		TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		skip.Visible = false
		collect.Visible = true
	end
	local function playReveal(r: any)
		revealing = r
		revealToken += 1
		local token = revealToken
		reveal.Visible = true
		Style.setOpen(panel, false)
		crateBox.Visible = true
		crateBox.Rotation = 0
		prize.Visible = false
		prizeName.Visible = false
		prizeRarity.Visible = false
		prizeNote.Visible = false
		burst.BackgroundTransparency = 1
		skip.Visible = true
		collect.Visible = false
		stageScale.Scale = 0.6 * stageFit()
		TweenService:Create(stageScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = stageFit() }):Play()
		task.spawn(function()
			local t0 = os.clock()
			while revealToken == token and os.clock() - t0 < 1.8 do
				local k = (os.clock() - t0) / 1.8
				crateBox.Rotation = math.sin(os.clock() * (20 + 30 * k)) * (3 + 9 * k)
				task.wait()
			end
			if revealToken == token then showResult() end
		end)
	end
	local function nextReveal()
		if reveal.Visible then return end
		local r = state.reveals[1]
		if r then playReveal(r) end
	end
	skip.Activated:Connect(showResult)
	collect.Activated:Connect(function()
		if not revealing then return end
		local id = revealing.id
		for i, r in state.reveals do if r.id == id then table.remove(state.reveals, i) break end end
		offerAction:FireServer("Seen", id)
		revealing = nil
		reveal.Visible = false
		task.delay(0.3, nextReveal)
	end)

	-- Server state ------------------------------------------------------------------------
	Net.event("OfferState").OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then return end
		state.owned = if type(msg.owned) == "table" then msg.owned else {}
		state.crates = msg.crates
		state.reveals = if type(msg.reveals) == "table" then msg.reveals else {}
		refreshAll()
		nextReveal()
	end)
	for _, id in { starter.id, show.id } do player:GetAttributeChangedSignal("Offer_" .. id):Connect(refreshAll) end
	player:GetAttributeChangedSignal("PaidRandomItems"):Connect(function()
		state.crates = player:GetAttribute("PaidRandomItems") or state.crates
		refreshAll()
	end)
	player:GetAttributeChangedSignal("Tier"):Connect(refreshAll)
	refreshAll()
	offerAction:FireServer("State")

	local api = {}
	api.panel = panel
	api.close = close
	api.refresh = refreshAll
	function api.showTab(name: string) if pages[name] then showTab(name) end end
	function api.openOffer(id: string)
		if id == show.id then openDetail(showroomDetail)
		elseif id == starter.id then openDetail(starterDetail)
		elseif O.crate(id) then showTab("CRATES") openDetail(crateDetail) end
	end
	return api
end

return Panel
