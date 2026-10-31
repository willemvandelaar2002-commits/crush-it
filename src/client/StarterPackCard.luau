--!strict
-- Presentation only (31 Oct, Candy Starter Card handoff): the candy backplate
-- with Candy Colossus floating on the left and the pack's three guaranteed
-- rewards + VIEW PACK on the right. Contents come from OfferConfig/BoostConfig
-- via ShopPanel; every click opens the EXISTING Starter Pack details, which
-- stay in charge of price, ownership and buying. No odds: nothing is random.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Art = require(ReplicatedStorage.Shared.ShopArt).CandyStarter
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
-- o: width, order, gate, enabled, open, crusherImage, crusherName, rarity,
--    cashText(): (amount, note), boostIcon, boostTitle, boostMinutes, onRefresh(fn), owned()
function Card.build(parent: Instance, o: any): Frame
	local width = o.width or DESIGN_W
	local root = make("Frame", { Name = "StarterPackShowcase", Size = UDim2.fromOffset(width, math.floor(width / Art.Aspect + 0.5)),
		LayoutOrder = o.order, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7 }, parent)
	local body = make("Frame", { Name = "Body", Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundTransparency = 1, ZIndex = 8 }, root)
	if width ~= DESIGN_W then make("UIScale", { Scale = width / DESIGN_W }, body) end
	-- fallback card until the backplate has loaded (inset: never shows past the art's corners)
	local backing = make("Frame", { Name = "BackplateFallback", Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 1, -28),
		BackgroundColor3 = C(170, 60, 230), BorderSizePixel = 0, ZIndex = 8 }, body)
	make("UICorner", { CornerRadius = UDim.new(0, 24) }, backing)
	make("UIStroke", { Color = C(255, 110, 190), Thickness = 6 }, backing)
	local plate = make("ImageLabel", { Name = "Backplate", Image = Art.Backplate, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch, ZIndex = 9 }, body)
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({ plate.Image }) end)
		while plate.Parent and not plate.IsLoaded do task.wait(0.25) end
		if plate.IsLoaded then backing.Visible = false end
	end)
	-- hero: left third, on the backplate's mint glow; floats while visible
	local hero = make("TextButton", { Name = "HeroCrusher", Position = UDim2.fromOffset(62, 38), Size = UDim2.fromOffset(222, 222),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 12 }, body)
	local heroArt = make("ImageLabel", { Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(206, 206), BackgroundTransparency = 1, Image = o.crusherImage, ScaleType = Enum.ScaleType.Fit, ZIndex = 13 }, hero)
	Style.floatArt(heroArt, { gate = o.gate, enabled = o.enabled, bob = 4, tilt = 3, period = 3.4 })
	Style.feedback(hero)
	hero.Activated:Connect(o.open)
	-- right side: heading + tag, three reward tiles, VIEW PACK (clear of the corner sweets)
	local heading = text(body, "Title", "STARTER PACK", UDim2.fromOffset(296, 46), UDim2.fromOffset(290, 36), 13, 34)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	make("UIGradient", { Rotation = 0, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C(255, 236, 120)), ColorSequenceKeypoint.new(1, C(120, 250, 255)) }) }, heading)
	Style.bold(heading, 3)
	local tag = make("Frame", { Name = "Tag", Position = UDim2.fromOffset(596, 50), Size = UDim2.fromOffset(144, 28),
		BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 13 }, body)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, tag)
	make("UIStroke", { Color = C(255, 120, 200), Thickness = 2 }, tag)
	local tagText = text(tag, "Label", "ONE-TIME PACK", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 1, -8), 14, 16, 2)
	local TILE_W, TILE_H, GAP, TOP = 140, 128, 12, 86
	local function tile(i: number, name: string, palette: string, top: string, image: string, line: string, bottom: string): (TextButton, TextLabel, TextLabel)
		local t = make("TextButton", { Name = name, Text = "", AutoButtonColor = false,
			Position = UDim2.fromOffset(296 + (i - 1) * (TILE_W + GAP), TOP), Size = UDim2.fromOffset(TILE_W, TILE_H), ZIndex = 12 }, body)
		Style.rewardCard(t, palette)
		-- separate bands: label / icon / name / amount
		Style.bold(text(t, "Label", top, UDim2.fromOffset(6, 5), UDim2.new(1, -12, 0, 18), 15, 17, 2), 2)
		local area = make("Frame", { Name = "IconArea", Position = UDim2.fromOffset(6, 23), Size = UDim2.new(1, -12, 0, 58),
			BackgroundTransparency = 1, ZIndex = 13 }, t)
		Style.sunburst(area, { count = 8, alpha = 0.5, width = 0.14, length = 1.25, spin = 0, zIndex = 13,
			colors = { Color3.new(1, 1, 1), C(255, 245, 190) } })
		local art = make("ImageLabel", { Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(66, 66), BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit, ZIndex = 14 }, area)
		local nameLabel = text(t, "RewardName", line, UDim2.fromOffset(5, 81), UDim2.new(1, -10, 0, 20), 15, 18, 2)
		Style.bold(nameLabel, 2)
		local pill = make("Frame", { Name = "AmountPill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 103),
			Size = UDim2.new(1, -16, 0, 20), BackgroundColor3 = INK, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 15 }, t)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
		make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.3 }, pill)
		local amount = text(pill, "Amount", bottom, UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), 16, 15, 1.5)
		amount.TextColor3 = C(255, 243, 159)
		Style.hoverLift(t, { art = art, scale = 1.06, artScale = 1.1, lift = 4, tilt = 3, press = 0.95 })
		t.Activated:Connect(function() Style.click() o.open() end)
		return t, nameLabel, amount
	end
	tile(1, "Reward_Crusher", "CandyMythic", string.upper(o.rarity), o.crusherImage, o.crusherName, "GUARANTEED")
	local cashAmount, cashNote = o.cashText()
	local _, cashName, cashPill = tile(2, "Reward_Cash", "Cash", "CASH", o.cashIcon, cashAmount, cashNote)
	tile(3, "Reward_Boost", "CashBoost", "BOOST", o.boostIcon, o.boostTitle, `{o.boostMinutes} MIN`)
	-- VIEW PACK: glossy green with a dark lower edge
	local edge = make("Frame", { Name = "ViewPackEdge", Position = UDim2.fromOffset(296, 226), Size = UDim2.fromOffset(220, 42),
		BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 12 }, body)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, edge)
	local view = make("TextButton", { Name = "ViewPack", Text = "VIEW PACK", TextScaled = true, Position = UDim2.fromOffset(296, 220),
		Size = UDim2.fromOffset(220, 42), ZIndex = 13 }, body)
	Style.button(view)
	local corner = view:FindFirstChild("Corner") :: UICorner? if corner then corner.CornerRadius = UDim.new(0, 12) end
	make("UITextSizeConstraint", { MaxTextSize = 26 }, view)
	make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, view)
	view.Activated:Connect(o.open)
	o.onRefresh(function()
		local owned = o.owned()
		tagText.Text = if owned then "OWNED" else "ONE-TIME PACK"
		tag.BackgroundColor3 = if owned then C(40, 140, 70) else INK
		view.Text = if owned then "OWNED" else "VIEW PACK"
		Style.setButtonColor(view, if owned then C(120, 124, 140) else Style.GREEN)
		local a, n = o.cashText()
		cashName.Text = a cashPill.Text = n
	end)
	return root
end
return Card
