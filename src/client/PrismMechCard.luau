--!strict
-- Presentation only (31 Oct, Prism Mech Card handoff): the violet/gold crystal
-- backplate with Prism Mech floating on the left and live text + FIND ON PLOT /
-- DETAILS on the right. One guaranteed crusher shown on the plot: no tiles,
-- odds or timers. ShopPanel passes the existing callbacks (Travel to plot,
-- showroom details) and ownership; nothing here buys or grants anything.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Art = require(ReplicatedStorage.Shared.ShopArt).PrismMech
local Card = {}
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local DESIGN_W = 816
local DESIGN_H = math.floor(DESIGN_W / Art.Aspect + 0.5) -- 329
local function make(class: string, props: any, parent: Instance): any
	local node = Instance.new(class)
	for k, v in props do (node :: any)[k] = v end
	node.Parent = parent
	return node
end
local function text(parent: Instance, name: string, caption: string, pos: UDim2, size: UDim2, z: number, maxSize: number, outline: number?): TextLabel
	local node = make("TextLabel", { Name = name, Text = caption, Position = pos, Size = size,
		BackgroundTransparency = 1, TextScaled = true, TextWrapped = true, ZIndex = z }, parent)
	Style.text(node, outline or 3)
	make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = maxSize }, node)
	return node
end
-- glossy button with a dark lower edge (same recipe as the Starter Pack card)
local function button(parent: Instance, name: string, caption: string, pos: UDim2, size: UDim2, color: Color3): TextButton
	local edge = make("Frame", { Name = name .. "Edge", Position = pos + UDim2.fromOffset(0, 6), Size = size,
		BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 12 }, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, edge)
	local b = make("TextButton", { Name = name, Text = caption, TextScaled = true, Position = pos, Size = size, ZIndex = 13 }, parent)
	Style.button(b, color)
	local corner = b:FindFirstChild("Corner") :: UICorner? if corner then corner.CornerRadius = UDim.new(0, 12) end
	make("UITextSizeConstraint", { MaxTextSize = 24 }, b)
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)
	return b
end
-- o: width, order, gate, enabled, crusherImage, title, rarity, tag, line,
--    find(), details(), owned(), onRefresh(fn)
function Card.build(parent: Instance, o: any): Frame
	local width = o.width or DESIGN_W
	local root = make("Frame", { Name = "PrismMechShowcase", Size = UDim2.fromOffset(width, math.floor(width / Art.Aspect + 0.5)),
		LayoutOrder = o.order, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7 }, parent)
	local body = make("Frame", { Name = "Body", Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundTransparency = 1, ZIndex = 8 }, root)
	if width ~= DESIGN_W then make("UIScale", { Scale = width / DESIGN_W }, body) end
	-- fallback card until the backplate has loaded (inset: never past the art's corners)
	local backing = make("Frame", { Name = "BackplateFallback", Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 1, -28),
		BackgroundColor3 = C(70, 40, 190), BorderSizePixel = 0, ZIndex = 8 }, body)
	make("UICorner", { CornerRadius = UDim.new(0, 24) }, backing)
	make("UIStroke", { Color = C(240, 190, 80), Thickness = 6 }, backing)
	local plate = make("ImageLabel", { Name = "Backplate", Image = Art.Backplate, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch, ZIndex = 9 }, body)
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({ plate.Image }) end)
		while plate.Parent and not plate.IsLoaded do task.wait(0.25) end
		if plate.IsLoaded then backing.Visible = false end
	end)
	-- hero: left interior, over the illustrated glow; floats while visible
	local hero = make("TextButton", { Name = "HeroCrusher", Position = UDim2.fromOffset(78, 36), Size = UDim2.fromOffset(214, 214),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 12 }, body)
	local heroArt = make("ImageLabel", { Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(200, 200), BackgroundTransparency = 1, Image = o.crusherImage, ScaleType = Enum.ScaleType.Fit, ZIndex = 13 }, hero)
	Style.floatArt(heroArt, { gate = o.gate, enabled = o.enabled, bob = 4, tilt = 3, period = 3.6 })
	Style.feedback(hero)
	hero.Activated:Connect(o.details)
	-- right: safe area x 310-653, y 53-253 (clear of the gold rim and corner crystals)
	local title = text(body, "Title", string.upper(o.title), UDim2.fromOffset(310, 50), UDim2.fromOffset(330, 48), 13, 46)
	title.TextXAlignment = Enum.TextXAlignment.Left
	make("UIGradient", { Rotation = 0, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C(140, 240, 255)), ColorSequenceKeypoint.new(0.55, C(255, 150, 225)), ColorSequenceKeypoint.new(1, C(255, 228, 117)) }) }, title)
	Style.bold(title, 3)
	-- MYTHIC badge (Prism gradient) + offer tag (GUARANTEED CRUSHER / OWNED)
	local badge = make("Frame", { Name = "RarityBadge", Position = UDim2.fromOffset(310, 104), Size = UDim2.fromOffset(112, 32), ZIndex = 13 }, body)
	Style.rewardCard(badge, "PrismMythic")
	local outline = badge:FindFirstChild("Outline") :: UIStroke? if outline then outline.Thickness = 3 end
	Style.bold(text(badge, "Label", string.upper(o.rarity), UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8), 15, 20, 2), 2)
	local tag = make("Frame", { Name = "Tag", Position = UDim2.fromOffset(432, 104), Size = UDim2.fromOffset(208, 32),
		BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 13 }, body)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, tag)
	local tagStroke = make("UIStroke", { Color = C(255, 228, 117), Thickness = 2 }, tag)
	local tagText = text(tag, "Label", o.tag, UDim2.fromOffset(10, 5), UDim2.new(1, -20, 1, -10), 14, 18, 2)
	-- supporting line on the dark interior
	local line = text(body, "Info", o.line, UDim2.fromOffset(312, 144), UDim2.fromOffset(326, 24), 13, 20, 2)
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.TextColor3 = C(225, 232, 255)
	local find = button(body, "FindOnPlot", "FIND ON PLOT", UDim2.fromOffset(310, 180), UDim2.fromOffset(186, 46), Style.GREEN)
	find.Activated:Connect(o.find)
	local details = button(body, "Details", "DETAILS", UDim2.fromOffset(506, 180), UDim2.fromOffset(128, 46), C(60, 196, 255))
	details.Activated:Connect(o.details)
	o.onRefresh(function()
		local owned = o.owned()
		tagText.Text = if owned then "OWNED" else o.tag
		tag.BackgroundColor3 = if owned then C(40, 140, 70) else INK
		tagStroke.Color = if owned then C(140, 255, 160) else C(255, 228, 117)
	end)
	return root
end
return Card
