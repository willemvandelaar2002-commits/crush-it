--!strict
-- 2 Nov: the TURBO menu (opened at the Turbo pump on your plot) and a running
-- turbo chip on the HUD. Prices come from the server (seconds of your income).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local T = require(RS.Shared.TurboConfig)

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local action = Net.event("TurboAction")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, stroke or 2.5)
	return l
end

local gui = make("ScreenGui", { Name = "TurboHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
-- 11 Nov: Willem's TURBO FUEL design (CrushIt-Turbo-UI-Parts): his frame, one card skin tinted per
-- tier, a fuel icon per tier and the Instant Turbo strip; every word, price, timer, lock and
-- button is live UI. Art ids are the images behind his decal uploads; an empty id shows the
-- plain native look instead (the frame and the card skin were still processing on 11 Nov).
local ART = {
	Frame = "", -- Turbo-Frame (1536 x 896)
	Card = "", -- Turbo-CardSkin (576 x 768, grey: tinted by a gradient per tier)
	Strip = "rbxassetid://104719562894587", -- Turbo-InstantStrip (1280 x 224), decal 109451328643052
	Icons = {
		Turbo = "rbxassetid://74419096420919", -- TurboFuel-Icon, decal 78857830608552
		MegaTurbo = "rbxassetid://104469236304196", -- decal 87541869288173
		HyperTurbo = "rbxassetid://81080902693562", -- decal 116647513188668
		UltraTurbo = "rbxassetid://128016896632481", -- decal 87752140340291
	} :: { [string]: string },
}
local RGB = Color3.fromRGB
-- the card colours (top, middle, bottom) from the design
local TINT: { [string]: { Color3 } } = {
	Turbo = { RGB(255, 232, 59), RGB(255, 150, 32), RGB(241, 77, 21) },
	MegaTurbo = { RGB(255, 84, 125), RGB(255, 37, 77), RGB(217, 15, 52) },
	HyperTurbo = { RGB(248, 98, 255), RGB(216, 23, 234), RGB(136, 17, 222) },
	UltraTurbo = { RGB(138, 235, 255), RGB(17, 191, 240), RGB(34, 84, 232) },
}
local Icons = require(RS.Shared.Icons)
local W = 984
local CARD_W, CARD_H, GAP, CARD_Y = 211, 324, 14, 138
-- 4 Nov: the Instant Turbo (Robux) strip under the cards, once its product exists
local Store = require(RS.Shared.Store)
local turboNow = Store.productById("TurboNow")
local SELL_NOW = turboNow ~= nil and turboNow.productId ~= 0
local H = if SELL_NOW then 574 else 500
local panel = make("Frame", { Name = "TurboPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = RGB(36, 28, 84), BackgroundTransparency = if ART.Frame ~= "" then 1 else 0, Visible = false, ZIndex = 5 }, gui)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 40)
panel:SetAttribute("FitHeight", H + 60)
if ART.Frame ~= "" then
	make("ImageLabel", { Name = "FrameArt", Image = ART.Frame, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 5 }, panel)
else
	make("UICorner", { CornerRadius = UDim.new(0, 18) }, panel)
	make("UIStroke", { Thickness = 5, Color = INK }, panel)
	local header = make("Frame", { Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 88), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 18) }, header)
	make("UIStroke", { Thickness = 5, Color = INK }, header)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(255, 206, 70), RGB(240, 110, 20)) }, header)
end
local titleIcon = make("ImageLabel", { Image = ART.Icons.Turbo, Position = UDim2.fromOffset(34, 2), Size = UDim2.fromOffset(84, 84), Rotation = -10,
	BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, panel)
Style.floatArt(titleIcon, { gate = panel, bob = 2, tilt = 4, period = 3 })
local headTitle = label(panel, "TURBO FUEL", UDim2.fromOffset(126, 12), UDim2.new(1, -260, 0, 64), 5)
headTitle.TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 14), Size = UDim2.fromOffset(62, 62), Text = "",
	BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, ZIndex = 8 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, close)
make("UIStroke", { Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, close)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(255, 110, 100), RGB(205, 25, 40)) }, close)
Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.1), UDim2.fromScale(0.7, 0.8), 3.5).ZIndex = 9
label(panel, "Boost ALL cash earnings. Only your strongest turbo counts.", UDim2.fromOffset(60, 96), UDim2.new(1, -120, 0, 30), 2.5)
local message = label(panel, "", UDim2.new(0, 60, 1, -28), UDim2.new(1, -120, 0, 22), 2.5)
message.TextColor3 = RGB(255, 230, 120)

type Card = { buy: TextButton, price: TextLabel, left: TextLabel, lockSlot: Frame, lock: TextLabel, stroke: UIStroke, def: any }
local cards: { Card } = {}
if SELL_NOW and turboNow then
	-- the Instant Turbo strip: art behind, the icon, the words, a separate green price button
	local strip = make("ImageLabel", { Name = "TurboNow", Position = UDim2.fromOffset(49, CARD_Y + CARD_H + 12), Size = UDim2.new(1, -98, 0, 70),
		BackgroundTransparency = 1, Image = ART.Strip, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(160, 64, 1120, 160), SliceScale = 70 / 224, ZIndex = 6 }, panel)
	make("ImageLabel", { Image = ART.Icons.Turbo, Position = UDim2.fromOffset(22, -6), Size = UDim2.fromOffset(78, 78), Rotation = -12,
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, strip)
	local t1 = label(strip, "INSTANT TURBO", UDim2.fromOffset(120, 6), UDim2.new(1, -380, 0, 34), 3.5)
	t1.TextXAlignment = Enum.TextXAlignment.Left
	local t2 = label(strip, "15 min of your best turbo", UDim2.fromOffset(120, 38), UDim2.new(1, -380, 0, 24), 2.5)
	t2.TextXAlignment = Enum.TextXAlignment.Left
	local buyNow = make("TextButton", { Name = "BuyTurboNow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -22, 0.5, 0), Size = UDim2.fromOffset(220, 52),
		Text = "", ZIndex = 8 }, strip)
	Style.button(buyNow, Style.GREEN)
	make("ImageLabel", { Image = Icons.Robux, Position = UDim2.new(0.5, -62, 0.5, -17), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, ZIndex = 9 }, buyNow)
	local cost = label(buyNow, tostring(turboNow.price), UDim2.new(0.5, -22, 0, 6), UDim2.new(0.5, 10, 1, -12), 3)
	cost.TextXAlignment = Enum.TextXAlignment.Left cost.ZIndex = 9
	Store.livePrice("product", turboNow.productId, turboNow.price, function(n) cost.Text = tostring(n) end)
	buyNow.Activated:Connect(function()
		if me:GetAttribute("SaveOff") then return end
		game:GetService("MarketplaceService"):PromptProductPurchase(me, turboNow.productId)
	end)
end
local x0 = (W - (#T.List * CARD_W + (#T.List - 1) * GAP)) / 2
for i, t in T.List do
	local x = x0 + (i - 1) * (CARD_W + GAP)
	local tint = TINT[t.id] or { Style.lighten(t.color, 0.3), t.color, Style.darken(t.color, 0.3) }
	local grad = ColorSequence.new({ ColorSequenceKeypoint.new(0, tint[1]), ColorSequenceKeypoint.new(0.5, tint[2]), ColorSequenceKeypoint.new(1, tint[3]) })
	local card = make("Frame", { Name = t.id, Position = UDim2.fromOffset(x, CARD_Y), Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundTransparency = 1, ZIndex = 6 }, panel)
	-- the skin (his grey card art tinted, or a plain gradient card)
	local skin = make(if ART.Card ~= "" then "ImageLabel" else "Frame", { Name = "Skin", Size = UDim2.fromScale(1, 1), BackgroundTransparency = if ART.Card ~= "" then 1 else 0,
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, card)
	if ART.Card ~= "" then
		(skin :: ImageLabel).Image = ART.Card (skin :: ImageLabel).ScaleType = Enum.ScaleType.Stretch (skin :: ImageLabel).ImageColor3 = Color3.new(1, 1, 1)
	end
	make("UICorner", { CornerRadius = UDim.new(0, 16) }, skin)
	make("UIGradient", { Rotation = 90, Color = grad }, skin)
	local stroke = make("UIStroke", { Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Enabled = ART.Card == "" }, skin)
	local function frac(y0: number, y1: number): (UDim2, UDim2) return UDim2.fromScale(0.06, y0), UDim2.fromScale(0.88, y1 - y0) end
	local p1, s1 = frac(0.025, 0.11)
	label(card, t.title, p1, s1, 3.5)
	local icon = make("ImageLabel", { Image = ART.Icons[t.id] or "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.82, 0.38),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, card)
	Style.floatArt(icon, { gate = panel, bob = 2.5, tilt = 3, period = 2.6 + i * 0.25 })
	local p2, s2 = frac(0.52, 0.64)
	label(card, "x" .. t.mult .. " CASH", p2, s2, 4)
	local chip = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.fromScale(0.62, 0.08), BackgroundColor3 = RGB(26, 24, 60), ZIndex = 8 }, card)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
	make("UIStroke", { Thickness = 2.5, Color = RGB(255, 206, 60), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
	label(chip, t.minutes .. " MIN", UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.84, 0.76), 2).ZIndex = 9
	local p3, s3 = frac(0.755, 0.82)
	local left = label(card, "", p3, s3, 2.5)
	left.TextColor3 = RGB(255, 255, 170)
	local buy = make("TextButton", { Position = UDim2.fromScale(0.07, 0.84), Size = UDim2.fromScale(0.86, 0.13), Text = "", ZIndex = 8 }, card)
	Style.button(buy, Style.GREEN)
	local price = label(buy, "...", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), 3)
	price.ZIndex = 9
	-- locked: the factory it needs, in a navy slot with a gold edge
	local lockSlot = make("Frame", { Position = UDim2.fromScale(0.07, 0.84), Size = UDim2.fromScale(0.86, 0.13), BackgroundColor3 = RGB(26, 24, 60), Visible = false, ZIndex = 8 }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, lockSlot)
	make("UIStroke", { Thickness = 3, Color = RGB(255, 206, 60), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, lockSlot)
	local lockTag = label(lockSlot, "LOCKED", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.36), 2)
	lockTag.TextColor3 = RGB(255, 206, 60) lockTag.ZIndex = 9
	local lock = label(lockSlot, "", UDim2.fromScale(0.05, 0.42), UDim2.fromScale(0.9, 0.52), 2.5)
	lock.ZIndex = 9
	buy.Activated:Connect(function() action:FireServer("Buy", t.id) end)
	cards[i] = { buy = buy, price = price, left = left, lockSlot = lockSlot, lock = lock, stroke = stroke, def = t }
end

local last: any = nil
local function paint()
	local now = workspace:GetServerTimeNow()
	local best = T.active(me, now)
	for _, c in cards do
		local t = c.def
		local locked = last and (last.plotLevel or 0) < t.plot
		c.buy.Visible = not locked
		c.lockSlot.Visible = locked == true
		c.lock.Text = if locked then "FACTORY " .. ({ "I", "II", "III", "IV", "V", "VI" })[t.plot + 1] else ""
		local p = last and last.prices and last.prices[t.id]
		c.price.Text = if p then Format.cash(p) else "..."
		local ends = (me:GetAttribute(T.attr(t.id)) :: number?) or 0
		local secs = math.floor(ends - now)
		c.left.Text = if secs > 0 then string.format("RUNNING %d:%02d", secs // 60, secs % 60) else ""
		local cash = (me:GetAttribute("Cash") :: number?) or 0
		Style.setButtonColor(c.buy, if p and cash >= p then Style.GREEN else Color3.fromRGB(130, 134, 146))
		-- the strongest running turbo is the one that counts: a green/gold edge on its card
		local counts = secs > 0 and t.mult == best
		c.stroke.Enabled = counts or ART.Card == ""
		c.stroke.Color = if counts then Color3.fromRGB(120, 255, 110) else INK
		c.stroke.Thickness = if counts then 5 else 4
	end
end
Net.event("TurboState").OnClientEvent:Connect(function(s: any)
	if type(s) ~= "table" then return end
	last = s
	if s.message then message.Text = s.message end
	paint()
end)
Net.event("CrusherOpen").OnClientEvent:Connect(function(kind: any)
	if kind ~= "Turbo" then return end
	message.Text = ""
	Style.setOpen(panel, true)
	action:FireServer("State")
	paint()
end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)

-- running turbo chip, bottom left above the cash
local chip = make("Frame", { Name = "TurboChip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -150), Size = UDim2.fromOffset(170, 40),
	BackgroundColor3 = Color3.fromRGB(255, 140, 30), Visible = false, ZIndex = 4 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, chip)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
local chipText = label(chip, "", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 1, -8), 2.5)
chipText.ZIndex = 5
Style.phoneFit(chip, { scale = 0.75 })
task.spawn(function()
	while true do
		task.wait(0.5)
		local mult, left = T.active(me, workspace:GetServerTimeNow())
		chip.Visible = mult > 1
		if mult > 1 then
			chipText.Text = string.format("TURBO x%d  %d:%02d", mult, left // 60, left % 60)
		end
		if panel.Visible then paint() end
	end
end)
