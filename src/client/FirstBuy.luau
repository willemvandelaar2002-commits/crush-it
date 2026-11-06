--!strict
-- 6 Nov (Willem: "something under 5 robux that is very visible, to get people over the
-- first buy barrier"): the R$ 5 First Buy Deal (Shared/OfferConfig FirstBuy, granted by
-- server/Offers through Shop's receipt handler).
--   * A wobbling rainbow "R$ 5 DEAL" button in the top-left button row (after Index /
--     Shop / Rewards / Rebirth), on phones too, in the Shop gui (so it appears when the
--     shop does). Gone once bought (attribute Offer_FirstBuy) or while the product id is 0.
--   * Tapping it opens a small card that shows exactly what you get, with BUY R$ 5.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Store = require(RS.Shared.Store)
local O = require(RS.Shared.OfferConfig)
local Icons = require(RS.Shared.Icons)
local CrusherIcons = require(RS.Shared.CrusherIcons)
local CrusherConfig = require(RS.Shared.CrusherConfig)

local M = {}
local C = Color3.fromRGB
local INK = Style.Colors.Ink

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, max: number, z: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z or 8 }, parent)
	Style.text(l, 3)
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = max }, l)
	return l
end

function M.build(gui: ScreenGui)
	local me = Players.LocalPlayer
	local offer = O.FirstBuy
	local product = Store.productById(offer.product)
	if not product then return end
	local priceText = "R$ " .. product.price

	-- the HUD button
	local button = Style.iconButton(gui, { name = "FirstBuyButton", icon = "🎁", label = priceText .. " DEAL", a = C(255, 120, 220), b = C(150, 50, 230) })
	local tile = button:FindFirstChild("Tile") :: Frame
	local fill = tile:FindFirstChild("PanelFill")
	if fill then fill:Destroy() end -- the rainbow is the fill
	Style.rainbow(tile)
	Style.wobble(tile, 5, 2.2)
	local label = button:FindFirstChild("Label") :: TextLabel
	label.TextColor3 = C(150, 255, 110)

	-- the card
	local W, H = 520, 380
	local card = make("Frame", { Name = "FirstBuyCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = C(60, 30, 140), Visible = false, ZIndex = 5 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 20) }, card)
	make("UIStroke", { Thickness = 5, Color = INK }, card)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(150, 60, 220), C(50, 24, 120)) }, card)
	Style.modal(card)
	card:SetAttribute("FitWidth", W + 20) card:SetAttribute("FitHeight", H + 20)
	words(card, "FIRST BUY DEAL", UDim2.fromOffset(24, 14), UDim2.new(1, -110, 0, 50), 42)
	local close = make("TextButton", { Text = "", Position = UDim2.new(1, -74, 0, 12), Size = UDim2.fromOffset(60, 60), ZIndex = 7 }, card)
	Style.button(close, C(228, 36, 44))
	words(close, "X", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 36, 9)
	local ribbon = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 70, 0, 6), Size = UDim2.fromOffset(120, 30), Rotation = -8,
		BackgroundColor3 = C(235, 40, 40), ZIndex = 9 }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, ribbon)
	make("UIStroke", { Thickness = 3, Color = INK }, ribbon)
	words(ribbon, offer.tag, UDim2.fromOffset(6, 3), UDim2.new(1, -12, 1, -6), 22, 10)

	-- three tiles: crusher, 2x cash, 2x luck
	local typeDef = CrusherConfig.typeById(offer.crusher)
	local items = {
		{ image = CrusherIcons.image(offer.crusher) or Icons.Press, top = if typeDef then typeDef.name else offer.crusher, sub = string.upper(offer.rarity) .. " CRUSHER", color = C(187, 105, 246) },
	}
	for _, b in offer.boosts do
		table.insert(items, { image = if b.id == "Luck" then Icons.Lucky else Icons.DoubleCash, top = "2x " .. string.upper(b.id), sub = b.minutes .. " MIN",
			color = if b.id == "Luck" then C(60, 190, 90) else C(230, 70, 60) })
	end
	local row = make("Frame", { Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 0, 190), BackgroundTransparency = 1, ZIndex = 6 }, card)
	for i, it in items do
		local t = make("Frame", { Position = UDim2.new((i - 1) / #items, 5, 0, 0), Size = UDim2.new(1 / #items, -10, 1, 0), BackgroundColor3 = it.color, ZIndex = 6 }, row)
		make("UICorner", { CornerRadius = UDim.new(0, 14) }, t)
		make("UIStroke", { Thickness = 4, Color = INK }, t)
		make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(104, 104), BackgroundTransparency = 1,
			Image = it.image, ScaleType = Enum.ScaleType.Fit, ZIndex = 7 }, t)
		words(t, it.top, UDim2.new(0, 6, 0, 116), UDim2.new(1, -12, 0, 36), 26)
		words(t, it.sub, UDim2.new(0, 6, 0, 152), UDim2.new(1, -12, 0, 28), 20)
	end
	local buy = make("TextButton", { Text = "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 282), Size = UDim2.fromOffset(240, 70), ZIndex = 7 }, card)
	Style.button(buy, C(60, 200, 80))
	local buyText = words(buy, "BUY " .. priceText, UDim2.fromOffset(10, 8), UDim2.new(1, -20, 1, -16), 40, 9)
	words(card, "Only once per player!", UDim2.new(0, 20, 1, -26), UDim2.new(1, -40, 0, 20), 18).TextColor3 = C(255, 230, 120)

	local function setPrice(n: number)
		priceText = "R$ " .. n
		label.Text = priceText .. " DEAL"
		buyText.Text = "BUY " .. priceText
	end

	-- where the button sits: right after the last visible button of the row
	local function place()
		local slot = 3
		local rebirth = gui.Parent and (gui.Parent :: Instance):FindFirstChild("RebirthButton", true) :: GuiObject?
		local rebirthGui = rebirth and rebirth:FindFirstAncestorOfClass("ScreenGui")
		if rebirth and rebirth:IsA("GuiObject") and rebirth.Visible and rebirthGui and rebirthGui.Enabled then slot = 4 end
		Style.placeHudButton(button, slot)
	end
	local function refresh()
		local owned = me:GetAttribute("Offer_" .. offer.id) == true
		button.Visible = product.productId ~= 0 and not owned
		if owned and card.Visible then Style.setOpen(card, false) end
		place()
	end
	me:GetAttributeChangedSignal("Offer_" .. offer.id):Connect(refresh)
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	task.spawn(function() while true do task.wait(2) place() end end) -- the Rebirth button can appear later
	refresh()
	if product.productId ~= 0 then Store.livePrice("product", product.productId, product.price, setPrice) end

	button.Activated:Connect(function()
		Net.event("ShopOpened"):FireServer("FirstBuyButton")
		Style.setOpen(card, true)
	end)
	close.Activated:Connect(function() Style.setOpen(card, false) end)
	buy.Activated:Connect(function()
		Net.event("OfferAction"):FireServer("Prompt", offer.product)
	end)
end

return M
