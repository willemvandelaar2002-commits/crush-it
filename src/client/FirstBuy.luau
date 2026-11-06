--!strict
-- 6 Nov (Willem: "something under 5 robux that is very visible, to get people over the
-- first buy barrier"): the R$ 5 First Buy Deal (Shared/OfferConfig FirstBuy). Willem
-- made it a GAME PASS (Store pass "FirstBuy"); server/Offers grants the contents once
-- when it sees the pass owned.
--   * A wobbling rainbow "R$ 5 DEAL" button in the top-left button row (after Index /
--     Shop / Rewards / Rebirth), on phones too, in the Shop gui (so it appears when the
--     shop does). Gone once owned (Pass_FirstBuy / Offer_FirstBuy).
--   * Tapping it opens Willem's card art (what you get, BUY R$ 5) with tap areas on X and BUY.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Store = require(RS.Shared.Store)
local Icons = require(RS.Shared.Icons)
local CrusherIcons = require(RS.Shared.CrusherIcons)
local CrusherConfig = require(RS.Shared.CrusherConfig)
local O = require(RS.Shared.OfferConfig)

local M = {}
M.Art = "rbxassetid://77919314377312" -- 6 Nov: Willem's card art ("5robuxdealcardboard", the empty board)
M.CloseArt = "rbxassetid://86950187561147" -- CloseButton.png (starter offer pack, also on the Rebirth card)
local C = Color3.fromRGB

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end

function M.build(gui: ScreenGui, buyPass: (string) -> ())
	local me = Players.LocalPlayer
	local offer = O.FirstBuy
	local pass = Store.passByPerk("FirstBuy")
	if not pass then return end
	local priceText = "R$ " .. pass.price

	-- the HUD button
	local button = Style.iconButton(gui, { name = "FirstBuyButton", icon = "🎁", label = priceText .. " DEAL", a = C(255, 120, 220), b = C(150, 50, 230) })
	local tile = button:FindFirstChild("Tile") :: Frame
	local fill = tile:FindFirstChild("PanelFill")
	if fill then fill:Destroy() end -- the rainbow is the fill
	Style.rainbow(tile)
	Style.wobble(tile, 5, 2.2)
	local label = button:FindFirstChild("Label") :: TextLabel
	label.TextColor3 = C(150, 255, 110)

	-- the card: Willem's art (6 Nov, image 77919314377312, 1536 x 1024) with invisible tap
	-- areas: the X and BUY are drawn on top
	local W, H = 600, 400
	local card = make("ImageLabel", { Name = "FirstBuyCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1, Image = M.Art, ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 5 }, gui)
	Style.modal(card :: any)
	card:SetAttribute("FitWidth", W + 20) card:SetAttribute("FitHeight", H + 20)
	-- the art is the empty board; everything on it is laid out here like Willem's reference
	-- (positions are fractions of the art, measured on the board's panels)
	local function text(str: string, cx: number, cy: number, w: number, h: number, max: number, color: Color3?, stroke: number?): TextLabel
		local l = make("TextLabel", { Text = str, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h),
			BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, card)
		Style.text(l, stroke or 3)
		if color then l.TextColor3 = color end
		make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = max }, l)
		return l
	end
	local function pill(str: string, cx: number, cy: number, w: number, h: number, bg: Color3)
		local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h), BackgroundColor3 = bg, ZIndex = 7 }, card)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		local l = make("TextLabel", { Text = str, Position = UDim2.fromScale(0.08, 0.12), Size = UDim2.fromScale(0.84, 0.76), BackgroundTransparency = 1,
			TextScaled = true, ZIndex = 8 }, f)
		Style.text(l, 2)
		make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 22 }, l)
	end
	local function image(img: string, cx: number, cy: number, w: number, h: number)
		make("ImageLabel", { Image = img, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h),
			BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 7 }, card)
	end
	local typeDef = CrusherConfig.typeById(offer.crusher)
	text("FIRST BUY DEAL", 0.5, 0.11, 0.6, 0.13, 46, nil, 4)
	-- left panel: the crusher
	image(CrusherIcons.image(offer.crusher) or Icons.Press, 0.272, 0.38, 0.36, 0.34)
	text(if typeDef then typeDef.name else offer.crusher, 0.272, 0.6, 0.38, 0.075, 30)
	pill(string.upper(offer.rarity) .. " CRUSHER", 0.272, 0.68, 0.27, 0.06, C(110, 40, 170))
	-- right panels: the boosts (orange = cash, green = luck)
	for i, bst in offer.boosts do
		local cy = if i == 1 then 0.338 else 0.616
		image(if bst.id == "Luck" then Icons.Lucky else Icons.DoubleCash, 0.6, cy, 0.14, 0.2)
		text("2x " .. string.upper(bst.id), 0.8, cy - 0.035, 0.24, 0.085, 34)
		pill(bst.minutes .. " MIN", 0.8, cy + 0.05, 0.15, 0.06, C(25, 30, 60))
	end
	text("Only once per player!", 0.5, 0.935, 0.5, 0.05, 20, C(255, 230, 120), 2)

	local function hit(name: string, cx: number, cy: number, w: number, h: number): TextButton
		local b = make("TextButton", { Name = name, Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h), ZIndex = 7 }, card)
		Style.feedback(b)
		return b
	end
	local close = hit("Close", 0.92, 0.1, 0.085, 0.13)
	make("ImageLabel", { Image = M.CloseArt, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, close)
	local x = make("TextLabel", { Text = "X", Position = UDim2.fromScale(0.18, 0.12), Size = UDim2.fromScale(0.64, 0.7), BackgroundTransparency = 1,
		TextScaled = true, ZIndex = 9 }, close) -- (the sprite is a plain red button, like on the Rebirth card)
	Style.text(x, 4)
	local buy = hit("Buy", 0.5, 0.845, 0.46, 0.13)
	buy.BackgroundTransparency = 0
	Style.button(buy, C(70, 210, 70))
	local buyText = make("TextLabel", { Text = "BUY " .. priceText, Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76),
		BackgroundTransparency = 1, TextScaled = true, ZIndex = 9 }, buy)
	Style.text(buyText, 4)
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 44 }, buyText)

	local function setPrice(n: number)
		priceText = "R$ " .. n
		label.Text = priceText .. " DEAL"
		buyText.Text = "BUY " .. priceText
	end

	-- where the button sits: right after the last visible button of the row
	local function place() Style.placeAfterHudRow(button) end
	local function refresh()
		local owned = me:GetAttribute("Offer_" .. offer.id) == true or Store.hasPass(me, "FirstBuy")
		button.Visible = pass.gamePassId ~= 0 and not owned
		if owned and card.Visible then Style.setOpen(card, false) end
		place()
	end
	me:GetAttributeChangedSignal("Offer_" .. offer.id):Connect(refresh)
	me:GetAttributeChangedSignal(Store.passAttr("FirstBuy")):Connect(refresh)
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	task.spawn(function() while true do task.wait(2) place() end end) -- the Rebirth button can appear later
	refresh()
	if pass.gamePassId ~= 0 then Store.livePrice("pass", pass.gamePassId, pass.price, setPrice) end

	button.Activated:Connect(function()
		Net.event("ShopOpened"):FireServer("FirstBuyButton")
		Style.setOpen(card, true)
	end)
	close.Activated:Connect(function() Style.setOpen(card, false) end)
	buy.Activated:Connect(function()
		buyPass("FirstBuy")
	end)
end

return M
