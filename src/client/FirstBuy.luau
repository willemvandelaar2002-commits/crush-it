--!strict
-- 6 Nov (Willem: "something under 5 robux that is very visible, to get people over the
-- first buy barrier"): the R$ 5 First Buy Deal (Shared/OfferConfig FirstBuy, granted by
-- server/Offers through Shop's receipt handler).
--   * A wobbling rainbow "R$ 5 DEAL" button in the top-left button row (after Index /
--     Shop / Rewards / Rebirth), on phones too, in the Shop gui (so it appears when the
--     shop does). Gone once bought (attribute Offer_FirstBuy) or while the product id is 0.
--   * Tapping it opens Willem's card art (what you get, BUY R$ 5) with tap areas on X and BUY.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Store = require(RS.Shared.Store)
local O = require(RS.Shared.OfferConfig)

local M = {}
M.Art = "rbxassetid://77919314377312" -- 6 Nov: Willem's card art ("5robuxdealcardboard")
local C = Color3.fromRGB

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
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

	-- the card: Willem's art (6 Nov, image 77919314377312, 1536 x 1024) with invisible tap
	-- areas over its X and BUY buttons (measured on the art, in fractions of its size)
	local W, H = 600, 400
	local card = make("ImageLabel", { Name = "FirstBuyCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1, Image = M.Art, ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 5 }, gui)
	Style.modal(card :: any)
	card:SetAttribute("FitWidth", W + 20) card:SetAttribute("FitHeight", H + 20)
	local function hit(name: string, cx: number, cy: number, w: number, h: number): TextButton
		local b = make("TextButton", { Name = name, Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h), ZIndex = 7 }, card)
		Style.feedback(b)
		return b
	end
	local close = hit("Close", 0.905, 0.132, 0.09, 0.13)
	local buy = hit("Buy", 0.5, 0.82, 0.53, 0.16)

	local function setPrice(n: number)
		priceText = "R$ " .. n
		label.Text = priceText .. " DEAL"
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
