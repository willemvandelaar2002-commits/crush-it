--!strict
-- Boosts window (opened at the hub's Boosts station, tag "BoostsPrompt"): a card
-- per boost with its effect, time left, a FREE 5 MIN button (once a day) and a
-- Robux button. Active boosts also show as small timer chips on the left side
-- of the screen. The server decides everything (server/Boosts).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local Store = require(ReplicatedStorage.Shared.Store)
local B = require(ReplicatedStorage.Shared.BoostConfig)

local me = Players.LocalPlayer
local action = Net.event("BoostAction")
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local PURPLE = C(150, 70, 230)
local W, H = 760, 430

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(p: Instance, text: string, pos: UDim2, size: UDim2, outline: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, p)
	Style.text(l, outline or 2.5)
	return l
end
local function shade(p: GuiObject, color: Color3)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Style.lighten(color, 0.15), Style.darken(color, 0.35)) }, p)
end
local function clock(s: number): string
	s = math.max(0, math.ceil(s))
	if s >= 3600 then return string.format("%d:%02d:%02d", s // 3600, s % 3600 // 60, s % 60) end
	return string.format("%d:%02d", s // 60, s % 60)
end
local function productFor(b: any): any
	for _, p in Store.Products do if p.id == b.product then return p end end
	return nil
end

-- Window --------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "BoostsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "BoostsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = C(28, 24, 48), Visible = false, ZIndex = 5 }, gui)
corner(panel, 12) stroke(panel, 5)
local ps = Style.studsImage(panel, 26, 0.92) ps.ZIndex = 5
Style.modal(panel)

local header = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20, 70), BackgroundColor3 = PURPLE, ZIndex = 6 }, panel)
corner(header, 8) stroke(header, 4, Style.darken(PURPLE, 0.5))
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(205, 130, 255), C(130, 50, 220)) }, header)
local hs = Style.studsImage(header, 32, 0.3) hs.ZIndex = 6 hs.ImageColor3 = C(190, 110, 255)
label(header, "Boosts", UDim2.new(0.5, -170, 0, 4), UDim2.fromOffset(340, 62), 4.5).ZIndex = 8
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(54, 54), Text = "", ZIndex = 8, BackgroundColor3 = C(225, 50, 50), AutoButtonColor = false }, header)
corner(close, 6) stroke(close, 3) shade(close, C(225, 50, 50)) Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 3).ZIndex = 9

local freeLine = label(panel, "", UDim2.fromOffset(20, 88), UDim2.new(1, -40, 0, 32), 2.5)
freeLine.TextColor3 = C(150, 255, 130)

type Card = { time: TextLabel, free: TextButton, buy: TextButton, glow: UIStroke, b: any }
local cards: { Card } = {}
local CARD_W = (W - 20 - 2 * 12 - 20) / 3
for i, b in B.List do
	local f = make("Frame", { Name = b.id, Position = UDim2.fromOffset(20 + (i - 1) * (CARD_W + 12), 128), Size = UDim2.fromOffset(CARD_W, H - 148),
		BackgroundColor3 = b.color, ZIndex = 6 }, panel)
	corner(f, 10)
	local glow = stroke(f, 4)
	shade(f, b.color)
	local st = Style.studsImage(f, 26, 0.45) st.ZIndex = 6 st.ImageColor3 = Style.lighten(b.color, 0.1)
	label(f, b.title, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 0, 36), 3).ZIndex = 8
	make("ImageLabel", { Image = (Icons :: any)[b.icon] or Icons.Cash, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48),
		Size = UDim2.fromOffset(78, 78), ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, f)
	local desc = label(f, b.desc, UDim2.fromOffset(10, 130), UDim2.new(1, -20, 0, 22), 2)
	desc.ZIndex = 8
	local time = label(f, "", UDim2.fromOffset(10, 154), UDim2.new(1, -20, 0, 24), 2.5)
	time.ZIndex = 8 time.TextColor3 = C(255, 240, 150)
	local free = make("TextButton", { Name = "Free", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -54), Size = UDim2.new(1, -20, 0, 40), Text = "", ZIndex = 8 }, f)
	Style.button(free, Style.GREEN)
	label(free, "FREE " .. B.FreeMinutes .. " MIN", UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.76), 2.5).ZIndex = 9
	local buy = make("TextButton", { Name = "Buy", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -20, 0, 40), Text = "", ZIndex = 8 }, f)
	Style.button(buy, C(255, 196, 40))
	local product = productFor(b)
	local price = if product and product.productId ~= 0 then b.minutes .. " MIN  R$ " .. product.price else "Coming soon"
	local priceLabel = label(buy, price, UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.76), 2.5)
	priceLabel.ZIndex = 9
	if product and product.productId ~= 0 then
		Store.livePrice("product", product.productId, product.price, function(n) priceLabel.Text = b.minutes .. " MIN  R$ " .. n end)
	end
	free.Activated:Connect(function() action:FireServer("Free", b.id) end)
	buy.Activated:Connect(function()
		if product and product.productId ~= 0 then
			MarketplaceService:PromptProductPurchase(me, product.productId)
		else
			for _, d in { -4, 4, -3, 3, 0 } do TweenService:Create(buy, TweenInfo.new(0.04), { Rotation = d }):Play() task.wait(0.04) end
		end
	end)
	cards[i] = { time = time, free = free, buy = buy, glow = glow, b = b }
end

-- Active boost chips (left side, under the menu buttons) ------------------------------------
local chips = make("Frame", { Name = "ActiveBoosts", Position = UDim2.new(0, 12, 0, 190), Size = UDim2.fromOffset(170, 160), BackgroundTransparency = 1 }, gui)
Style.phoneFit(chips, { scale = 0.65, position = UDim2.new(0, 12, 0, 164) }) -- 30 Oct: under cash + friend boost on phones
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
local chipFor: { [string]: TextLabel } = {}
for i, b in B.List do
	local c = make("Frame", { Name = b.id, LayoutOrder = i, Size = UDim2.fromOffset(170, 40), BackgroundColor3 = b.color, Visible = false }, chips)
	corner(c, 8) stroke(c, 3) shade(c, b.color)
	make("ImageLabel", { Image = (Icons :: any)[b.icon] or Icons.Cash, BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(34, 34), ZIndex = 2 }, c)
	local t = label(c, "", UDim2.fromOffset(42, 5), UDim2.new(1, -48, 1, -10), 2.5)
	t.ZIndex = 3 t.TextXAlignment = Enum.TextXAlignment.Left
	chipFor[b.id] = t
end

local function refresh()
	local now = Workspace:GetServerTimeNow()
	local free = me:GetAttribute("FreeBoost") == true
	freeLine.Text = if free then "Your free " .. B.FreeMinutes .. "-minute boost is ready: pick one!" else "Free boost used today. Come back tomorrow!"
	for _, c in cards do
		local left = ((me:GetAttribute(B.attr(c.b.id)) :: number?) or 0) - now
		c.time.Text = if left > 0 then "Active: " .. clock(left) else ""
		c.glow.Color = if left > 0 then Color3.new(1, 1, 1) else INK
		c.free.Visible = free
	end
	for id, t in chipFor do
		local left = ((me:GetAttribute(B.attr(id)) :: number?) or 0) - now
		t.Parent.Visible = left > 0
		if left > 0 then t.Text = B.find(id).title .. "  " .. clock(left) end
	end
end

local function open() Style.setOpen(panel, true) refresh() end
close.Activated:Connect(function() Style.setOpen(panel, false) end)
local function bind(p: Instance) if p:IsA("ProximityPrompt") then p.Triggered:Connect(open) end end
for _, p in CollectionService:GetTagged("BoostsPrompt") do bind(p) end
CollectionService:GetInstanceAddedSignal("BoostsPrompt"):Connect(bind)
task.spawn(function() while true do refresh() task.wait(0.5) end end)
