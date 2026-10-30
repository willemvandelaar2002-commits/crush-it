--!strict
-- Presentation only. Receives the existing odds/text and opens existing details.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Card = {}
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local function make(class: string, props: any, parent: Instance): any
	local node = Instance.new(class)
	for k, v in props do (node :: any)[k] = v end
	node.Parent = parent
	return node
end
local function round(parent: Instance, radius: number)
	make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end
local function stroke(parent: Instance, color: Color3, thickness: number)
	make("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end
local function fill(parent: Instance, a: Color3, b: Color3, rotation: number?)
	make("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rotation or 90 }, parent)
end
local function text(parent: Instance, name: string, caption: string, x: number, y: number, w: number, h: number, z: number, maxSize: number?): TextLabel
	local node = make("TextLabel", { Name = name, Text = caption, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1, TextScaled = true, TextWrapped = true, ZIndex = z }, parent)
	Style.text(node, 2)
	make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = maxSize or 22 }, node)
	return node
end
local function image(parent: Instance, asset: string, x: number, y: number, size: number, z: number): ImageLabel
	return make("ImageLabel", { Name = "Art", Image = asset, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = z }, parent)
end
local function rarityOf(id: string, resolve: (string) -> any): any
	return resolve(id) or { name = "Crusher", rank = 0, color = C(150, 180, 220) }
end
-- One of each available rarity, then fill spare spaces in source order. The
-- spotlight is highest rarity / lowest chance, with a stable source-order tie.
-- These are individual item odds, never a combined rarity percentage.
function Card.preview(odds: { any }, resolve: (string) -> any): ({ any }, any)
	local spotlight = nil
	for _, item in odds do
		local rank = rarityOf(item.type, resolve).rank
		if not spotlight or rank > rarityOf(spotlight.type, resolve).rank
			or (rank == rarityOf(spotlight.type, resolve).rank and item.percent < spotlight.percent) then
			spotlight = item
		end
	end
	local selected, used, rarities = {}, {}, {}
	if spotlight then used[spotlight.type] = true end
	for _, item in odds do
		local rarity = rarityOf(item.type, resolve).name
		if not used[item.type] and not rarities[rarity] and #selected < 4 then
			table.insert(selected, item) used[item.type] = true rarities[rarity] = true
		end
	end
	for _, item in odds do
		if #selected >= 4 then break end
		if not used[item.type] then table.insert(selected, item) used[item.type] = true end
	end
	local index = {} for i, item in odds do index[item.type] = i end
	table.sort(selected, function(a, b)
		local ar, br = rarityOf(a.type, resolve).rank, rarityOf(b.type, resolve).rank
		return if ar == br then index[a.type] < index[b.type] else ar < br
	end)
	return selected, spotlight
end
function Card.build(parent: Instance, o: any): Frame
	local width = o.width or 816
	local root = make("Frame", { Name = "FactoryCrateShowcase", Size = UDim2.fromOffset(width, 338), LayoutOrder = o.order,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7 }, parent)
	local shadow = make("Frame", { Name = "DropShadow", Position = UDim2.fromOffset(4, 7), Size = UDim2.new(1, -4, 1, -8),
		BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 7 }, root)
	round(shadow, 14)
	local body = make("Frame", { Name = "Body", Size = UDim2.new(1, 0, 1, -8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 8 }, root)
	round(body, 14) stroke(body, INK, 4)
	fill(body, C(40, 103, 216), C(24, 33, 95), 18)
	local studs = Style.studsImage(body, 30, 0.86) studs.ImageColor3 = C(90, 185, 255) studs.ZIndex = 8
	local trim = make("Frame", { Name = "GoldTrim", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1, ZIndex = 9 }, body)
	round(trim, 11) stroke(trim, C(255, 202, 55), 2)
	for _, x in { 10, width - 25 } do
		for _, y in { 10, 306 } do
			local bolt = make("Frame", { Name = "CornerBolt", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = C(255, 208, 65), BorderSizePixel = 0, ZIndex = 10 }, body)
			round(bolt, 4) stroke(bolt, INK, 2)
		end
	end
	local title = text(body, "Title", string.upper(o.title), 24, 12, 550, 48, 11, 38)
	title.TextXAlignment = Enum.TextXAlignment.Left
	fill(title, C(255, 222, 80), C(86, 236, 255), 0)
	local subtitle = text(body, "Contents", `1 random crusher • {#o.odds} possible rewards`, 26, 58, 520, 22, 11, 18)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	local tag = make("Frame", { Name = "FactoryTag", Position = UDim2.new(1, -184, 0, 20), Size = UDim2.fromOffset(160, 28),
		BackgroundColor3 = C(255, 203, 48), BorderSizePixel = 0, ZIndex = 11 }, body)
	round(tag, 7) stroke(tag, INK, 2)
	local tagText = text(tag, "Label", "FACTORY SERIES", 6, 3, 148, 22, 12, 15)
	tagText.TextColor3 = INK
	local tagOutline = tagText:FindFirstChild("TextOutline") :: UIStroke?
	if tagOutline then tagOutline.Thickness = 0 end
	local aura = make("Frame", { Name = "ChestAura", Position = UDim2.fromOffset(4, 86), Size = UDim2.fromOffset(228, 216), BackgroundTransparency = 1, ZIndex = 9 }, body)
	local rays = Style.sunburst(aura, { count = 10, alpha = 0.62, width = 0.1, length = 1.5, color = C(107, 227, 255), zIndex = 9, spin = 0 })
	Style.spinArt(rays, { gate = o.gate, enabled = o.enabled, speed = 8 })
	local chest = make("TextButton", { Name = "ChestPortrait", Position = UDim2.fromOffset(6, 88), Size = UDim2.fromOffset(226, 214),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 12 }, body)
	local chestArt = image(chest, o.crateImage, 3, -3, 220, 13)
	Style.floatArt(chestArt, { gate = o.gate, enabled = o.enabled, bob = 5, tilt = 6, period = 3.2 }) -- 31 Oct: livelier, like the reference chest
	Style.glint(chestArt, { gate = o.gate, enabled = o.enabled, interval = 6.4, phase = 2.1, position = UDim2.fromScale(0.77, 0.3), zIndex = 14 })
	Style.feedback(chest)
	chest.Activated:Connect(o.open)
	text(body, "ChestCaption", "ONE CRUSHER PER CRATE", 32, 300, 190, 20, 12, 14)
	text(body, "PreviewHeading", "POSSIBLE REWARDS", 244, 86, 404, 18, 12, 16).TextXAlignment = Enum.TextXAlignment.Left
	local selected, spotlight = Card.preview(o.odds, o.rarityOf)
	local function reward(item: any, x: number, y: number, w: number, h: number, large: boolean, phase: number)
		local rarity = rarityOf(item.type, o.rarityOf)
		local tile = make("TextButton", { Name = "Reward_" .. item.type, Text = "", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 12 }, body)
		tile:SetAttribute("CrusherType", item.type) tile:SetAttribute("Chance", item.text)
		round(tile, 9) stroke(tile, if large then C(255, 218, 78) else INK, if large then 3.5 else 3)
		fill(tile, Style.lighten(rarity.color, 0.08), Style.darken(rarity.color, 0.6), 35)
		if large then
			local burst = Style.sunburst(tile, { count = 9, alpha = 0.5, length = 1.8, width = 0.14, zIndex = 13, spin = 0, fullBleed = true,
				colors = { C(255, 235, 116), C(255, 130, 225), C(103, 238, 255) } })
			Style.spinArt(burst, { gate = o.gate, enabled = o.enabled, speed = 14 })
		end
		local name = text(tile, "CrusherName", o.typeName(item.type), 4, 5, w - 8, 32, 15, if large then 17 else 15)
		name.TextYAlignment = Enum.TextYAlignment.Center
		local size = if large then 108 else 80
		local art = image(tile, o.image(item.type), (w - size) / 2, if large then 35 else 37, size, 14)
		Style.floatArt(art, { gate = o.gate, enabled = o.enabled, bob = if large then 3.5 else 2, tilt = if large then 4 else 2.5, period = 3.3, phase = phase })
		if large then Style.glint(art, { gate = o.gate, enabled = o.enabled, interval = 4.8, phase = 0.8, zIndex = 16, size = 25 }) end
		local chance = text(tile, "Chance", item.text, 3, h - 29, w - 6, 24, 15, if large then 20 else 17)
		chance.TextColor3 = C(255, 243, 159)
		Style.feedback(tile)
		tile.Activated:Connect(o.open)
	end
	for i, item in selected do reward(item, 244 + (i - 1) * 104, 108, 96, 146, false, i * 0.57) end
	if spotlight then
		text(body, "SpotlightHeading", string.upper(rarityOf(spotlight.type, o.rarityOf).name) .. " SPOTLIGHT", 662, 66, 138, 20, 12, 13)
		reward(spotlight, 662, 90, 138, 174, true, 0.2)
	end
	text(body, "PreviewDisclosure", `Preview: {#selected + (if spotlight then 1 else 0)} of {#o.odds} • Individual chances`, 244, 259, 404, 18, 12, 13).TextXAlignment = Enum.TextXAlignment.Left
	local chances = make("TextButton", { Name = "AllRewards", Text = "", Position = UDim2.fromOffset(244, 284), Size = UDim2.fromOffset(346, 36),
		BackgroundColor3 = C(35, 58, 125), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 12 }, body)
	round(chances, 9) stroke(chances, C(93, 199, 244), 2)
	text(chances, "Caption", `See all {#o.odds} rewards & chances`, 8, 4, 330, 28, 13, 18)
	Style.feedback(chances) chances.Activated:Connect(o.open)
	local view = make("TextButton", { Name = "ViewCrate", Text = "", Position = UDim2.fromOffset(602, 280), Size = UDim2.fromOffset(198, 42), ZIndex = 12 }, body)
	Style.button(view)
	text(view, "Caption", "VIEW CRATE", 8, 5, 182, 32, 13, 24)
	view.Activated:Connect(o.open)
	return root
end
return Card
