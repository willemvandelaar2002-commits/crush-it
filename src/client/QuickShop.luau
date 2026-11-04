--!strict
-- 3 Nov (monetization audit; vault: Pricing and Store Design "phone first", "starter
-- shop view for players who never bought"): a phone-sized shop.
--   * Phones (Style.compact) always get this shop; on bigger screens it is the first
--     page for players who own nothing yet. SEE EVERYTHING opens the full shop
--     (crates with their odds, Mythics, all tabs).
--   * One scrolling column of big rows (64 px, 48 px BUY buttons, text >= 14 px):
--     Starter Pack (until owned), passes you don't own, cash packs, boosts.
--   * openOffer(): the same window showing only the Starter Pack, used for the
--     once-per-session starter offer (Shop.client decides when).
-- Prices are Roblox's own (GetProductInfo); id 0 shows SOON. Buying goes through
-- the same functions as the full shop (Shop.client buyPass / buyProduct and the
-- server's OfferAction "Prompt" for the Starter Pack).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Style = require(RS.Shared.Kit.Style)
local Store = require(RS.Shared.Store)
local Icons = require(RS.Shared.Icons)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local O = require(RS.Shared.OfferConfig)

local player = Players.LocalPlayer
local INK = Style.Colors.Ink
local C = Color3.fromRGB

local Quick = {}

-- price cache (Roblox's live prices)
local prices: { [string]: number | false } = {}
local function price(kind: string, id: number, done: () -> ()): number?
	if id == 0 then return nil end
	local key = kind .. id
	local p = prices[key]
	if p == nil then
		prices[key] = false
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(id, if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			end)
			prices[key] = if ok and info and type(info.PriceInRobux) == "number" then info.PriceInRobux else false
			done()
		end)
		return nil
	end
	return if p then p else nil
end

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, parent)
	Style.text(l, stroke or 2)
	local cap = make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 30 }, l)
	local _ = cap
	return l
end

export type Deps = { buyPass: (string) -> (), buyProduct: (string) -> (), openFull: () -> (), notice: (string) -> () }

function Quick.build(gui: ScreenGui, deps: Deps)
	-- a dark backdrop behind the window; while open the shop draws above the HUD
	local baseOrder = gui.DisplayOrder
	local shade = make("TextButton", { Name = "QuickShopBackdrop", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -60),
		BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 4, Modal = true }, gui)
	shade.Size = UDim2.new(1, 0, 1, 120)
	local panel = make("Frame", { Name = "QuickShop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C(44, 48, 54), Visible = false, ZIndex = 5 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, panel)
	make("UIStroke", { Thickness = 4, Color = INK }, panel)
	-- real pixel layout, no shrinking: most of the screen on phones, 560 x 620 at most
	local function size()
		local v = workspace.CurrentCamera.ViewportSize
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		panel.Size = UDim2.fromOffset(math.min(560, v.X - 24), math.min(620, v.Y - inset - 16))
		panel.Position = UDim2.new(0.5, 0, 0.5, -inset / 2)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(size)
	size()

	local header = make("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C(255, 90, 120), ZIndex = 6 }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, header)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(255, 130, 150), C(220, 40, 70)) }, header)
	local title = label(header, "SHOP", UDim2.fromOffset(16, 8), UDim2.new(1, -90, 0, 40), 3)
	title.ZIndex = 7
	local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(48, 48), Text = "", BackgroundColor3 = C(228, 36, 44), ZIndex = 8 }, header)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, close)
	make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, close)
	local x = label(close, "X", UDim2.fromScale(0.2, 0.12), UDim2.fromScale(0.6, 0.76), 3)
	x.TextXAlignment = Enum.TextXAlignment.Center x.ZIndex = 9

	local list = make("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(10, 64), Size = UDim2.new(1, -20, 1, -72),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 6 }, panel)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, list)

	local offerAction = Net.event("OfferAction")
	local mode = "shop"
	local rebuild: () -> ()

	local function section(order: number, text: string)
		local l = label(list, text, UDim2.new(), UDim2.new(1, 0, 0, 26), 2)
		l.LayoutOrder = order l.TextColor3 = C(255, 225, 120)
	end
	-- one row: icon, name, one line of what it does, a big BUY button
	local function row(order: number, color: Color3, icon: string, name: string, desc: string, priceText: string, ready: boolean, onBuy: () -> (), tall: boolean?)
		local h = if tall then 96 else 68
		local f = make("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = color, LayoutOrder = order, ZIndex = 6 }, list)
		make("UICorner", { CornerRadius = UDim.new(0, 12) }, f)
		make("UIStroke", { Thickness = 3, Color = INK }, f)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Style.lighten(color, 0.15), Style.darken(color, 0.35)) }, f)
		local img = make("ImageLabel", { Image = icon, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(h - 12, h - 12), ZIndex = 7 }, f)
		local _ = img
		local textW = UDim2.new(1, -(h + 120), 0, 0)
		label(f, name, UDim2.fromOffset(h, 6), textW + UDim2.fromOffset(0, if tall then 34 else 28), 2.5)
		local d = label(f, desc, UDim2.fromOffset(h, if tall then 42 else 36), textW + UDim2.fromOffset(0, if tall then 46 else 26), 1.5)
		d.TextWrapped = true d.TextYAlignment = Enum.TextYAlignment.Top
		local buy = make("TextButton", { Name = "Buy", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(104, 48), Text = "", ZIndex = 8 }, f)
		Style.button(buy, if ready then C(60, 200, 80) else C(120, 124, 134))
		local bl = label(buy, priceText, UDim2.fromOffset(6, 6), UDim2.new(1, -12, 1, -12), 2.5)
		bl.TextXAlignment = Enum.TextXAlignment.Center bl.ZIndex = 9
		buy.Activated:Connect(onBuy)
		return f
	end
	local function robux(p: number?): string return if p then "R$ " .. p else "..." end

	rebuild = function()
		for _, c in list:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		local order = 0
		local function nextOrder() order += 1 return order end
		-- Starter Pack (until owned)
		local starter = O.StarterPack
		local ownsStarter = player:GetAttribute("Offer_" .. starter.id) == true
		local sp = Store.productById(starter.product)
		if not ownsStarter and sp then
			if mode == "shop" then section(nextOrder(), "BEST VALUE · ONE TIME") end
			local p = price("product", sp.productId, function() if panel.Visible then rebuild() end end)
			local rate = (player:GetAttribute("CashRate") :: number?) or 0
			row(nextOrder(), C(255, 80, 170), Icons.Golden, "STARTER PACK",
				"MYTHIC Candy Colossus + " .. Format.cash(Store.cashFor(rate, starter.cashMinutes * 60)) .. " cash + 2x Cash " .. starter.boost.minutes .. " min",
				if sp.productId == 0 then "SOON" else robux(p), sp.productId ~= 0, function()
					if sp.productId == 0 then deps.notice("Coming soon!") return end
					offerAction:FireServer("Prompt", starter.product)
				end, true)
		end
		if mode == "offer" then
			-- the starter offer shows only the pack plus a way to the whole shop
			local more = make("TextButton", { Name = "SeeShop", Size = UDim2.new(1, 0, 0, 52), Text = "", LayoutOrder = nextOrder(), ZIndex = 7 }, list)
			Style.button(more, C(64, 140, 255))
			local ml = label(more, "SEE THE SHOP", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 2.5)
			ml.TextXAlignment = Enum.TextXAlignment.Center ml.ZIndex = 9
			more.Activated:Connect(function() mode = "shop" rebuild() end)
			return
		end
		-- passes you don't own yet
		local firstPass = true
		for _, pass in Store.Passes do
			if not Store.hasPass(player, pass.perk) then
				if firstPass then section(nextOrder(), "FOREVER (GAME PASSES)") firstPass = false end
				local p = price("pass", pass.gamePassId, function() if panel.Visible then rebuild() end end)
				local icon = ({ AutoCrush = Icons.AutoCrush, DoubleCash = Icons.DoubleCash, Lucky = Icons.Lucky, AutoCollect = Icons.Cash } :: any)[pass.perk] or Icons.Shop
				row(nextOrder(), pass.color, icon, string.upper(pass.title), pass.desc,
					if pass.gamePassId == 0 then "SOON" else robux(p), pass.gamePassId ~= 0, function() deps.buyPass(pass.perk) end)
			end
		end
		-- cash packs and boosts
		section(nextOrder(), "CASH (YOUR EARNINGS, RIGHT AWAY)")
		local rate = (player:GetAttribute("CashRate") :: number?) or 0
		for _, id in { "CashSmall", "CashMedium", "CashLarge" } do
			local product = Store.productById(id)
			if product then
				local minutes = Store.CashPackMinutes[id] or 0
				local p = price("product", product.productId, function() if panel.Visible then rebuild() end end)
				row(nextOrder(), product.color, Icons.Cash, string.upper(product.title),
					Format.cash(Store.cashFor(rate, minutes * 60)) .. " · " .. (if minutes >= 60 then (minutes // 60) .. " h" else minutes .. " min") .. " of earnings",
					if product.productId == 0 then "SOON" else robux(p), product.productId ~= 0, function() deps.buyProduct(id) end)
			end
		end
		section(nextOrder(), "BOOSTS")
		for _, id in { "BoostCash", "BoostLuck", "BoostSuper" } do
			local product = Store.productById(id)
			if product then
				local p = price("product", product.productId, function() if panel.Visible then rebuild() end end)
				local icon = if id == "BoostLuck" then Icons.Lucky elseif id == "BoostSuper" then Icons.Golden else Icons.DoubleCash
				row(nextOrder(), product.color, icon, string.upper(product.title), product.desc,
					if product.productId == 0 then "SOON" else robux(p), product.productId ~= 0, function() deps.buyProduct(id) end)
			end
		end
		-- everything else (crates with odds, Mythics) in the full shop
		local more = make("TextButton", { Name = "SeeEverything", Size = UDim2.new(1, 0, 0, 52), Text = "", LayoutOrder = nextOrder(), ZIndex = 7 }, list)
		Style.button(more, C(64, 140, 255))
		local ml = label(more, "SEE EVERYTHING (CRATES, MYTHICS)", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 2.5)
		ml.TextXAlignment = Enum.TextXAlignment.Center ml.ZIndex = 9
		more.Activated:Connect(function() panel.Visible = false deps.openFull() end)
	end

	close.Activated:Connect(function() panel.Visible = false end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		shade.Visible = panel.Visible
		gui.DisplayOrder = if panel.Visible then 30 else baseOrder
	end)
	player:GetAttributeChangedSignal("Offer_" .. O.StarterPack.id):Connect(function() if panel.Visible then rebuild() end end)

	local api = {}
	api.panel = panel
	function api.open()
		mode = "shop" title.Text = "SHOP" size() rebuild() panel.Visible = true
	end
	function api.openOffer()
		mode = "offer" title.Text = "SPECIAL OFFER" size() rebuild() panel.Visible = true
	end
	function api.refresh() if panel.Visible then rebuild() end end
	return api
end

return Quick
