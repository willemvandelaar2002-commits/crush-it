--!strict
-- Presentation only (31 Oct, approved compact card): the illustrated
-- backplate with the illustrated chest on the left and three multicolour
-- reward cards on the right. Receives the existing odds/text and opens the
-- existing crate detail view (all rewards + exact chances); never purchases.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Art = require(ReplicatedStorage.Shared.ShopArt).FactoryCrate
local CardFx = require(script.Parent.CardFx)
local Card = {}
local C = Color3.fromRGB
local INK = Style.Colors.Ink
-- design size: the backplate at 816 px wide (~2.48:1); other widths scale it
local DESIGN_W = 816
local DESIGN_H = math.floor(DESIGN_W / Art.Aspect + 0.5) -- 329
-- the approved preview, shown only while they are still rewards in this crate
Card.Approved = { "DuckyDynamo", "ArcadeClaw", "DiscoDestroyer" }
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
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = maxSize }, node)
	return node
end
local function rarityOf(id: string, resolve: (string) -> any): any
	return resolve(id) or { name = "Crusher", rank = 0, color = C(150, 180, 220) }
end
-- An image with a fallback underneath that hides once the new art has loaded.
local function artWithFallback(parent: Instance, name: string, asset: string, fallback: Instance?, props: any): ImageLabel
	local img = make("ImageLabel", props, parent)
	img.Name = name img.Image = asset
	if fallback then
		-- IsLoaded has no change event: ask for the image, then check until it has
		-- loaded (it also loads lazily once shown); the fallback hides at that moment
		task.spawn(function()
			pcall(function() ContentProvider:PreloadAsync({ img.Image }) end)
			while img.Parent and not img.IsLoaded do task.wait(0.25) end
			if img.IsLoaded and fallback.Parent then (fallback :: any).Visible = false end
		end)
	end
	return img
end
-- Three previews: the approved ones that are still in the crate; any gap is
-- filled with one crusher per rarity, highest rarity first (source order).
-- Each item keeps its own individual chance (item.text), never a rarity total.
function Card.pick(odds: { any }, resolve: (string) -> any, count: number?): { any }
	local want = count or 3
	local byType = {} for _, item in odds do byType[item.type] = item end
	local selected, used, rarities = {}, {}, {}
	local function add(item: any)
		if #selected < want and not used[item.type] then
			table.insert(selected, item) used[item.type] = true rarities[rarityOf(item.type, resolve).name] = true
		end
	end
	for _, id in Card.Approved do if byType[id] then add(byType[id]) end end
	local ranked = table.clone(odds)
	local index = {} for i, item in odds do index[item.type] = i end
	table.sort(ranked, function(a, b)
		local ar, br = rarityOf(a.type, resolve).rank, rarityOf(b.type, resolve).rank
		return if ar == br then index[a.type] < index[b.type] else ar > br
	end)
	for _, item in ranked do if not rarities[rarityOf(item.type, resolve).name] then add(item) end end
	for _, item in ranked do add(item) end
	table.sort(selected, function(a, b)
		local ar, br = rarityOf(a.type, resolve).rank, rarityOf(b.type, resolve).rank
		return if ar == br then index[a.type] < index[b.type] else ar < br
	end)
	return selected
end
function Card.build(parent: Instance, o: any): Frame
	local width = o.width or DESIGN_W
	local height = math.floor(width / Art.Aspect + 0.5)
	local root = make("Frame", { Name = "FactoryCrateShowcase", Size = UDim2.fromOffset(width, height), LayoutOrder = o.order,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7 }, parent)
	-- everything is laid out at 816 x 329 and scaled to the real width
	local body = make("Frame", { Name = "Body", Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundTransparency = 1, ZIndex = 8 }, root)
	if width ~= DESIGN_W then make("UIScale", { Scale = width / DESIGN_W }, body) end
	-- fallback card while the backplate loads (inset so it never shows past the art's rounded corners)
	local backing = make("Frame", { Name = "BackplateFallback", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24),
		BackgroundColor3 = C(28, 70, 190), BorderSizePixel = 0, ZIndex = 8 }, body)
	make("UICorner", { CornerRadius = UDim.new(0, 22) }, backing)
	make("UIStroke", { Color = C(255, 202, 55), Thickness = 4 }, backing)
	artWithFallback(body, "Backplate", Art.Backplate, backing, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch, ZIndex = 9 })
	-- chest: left third, centred on the backplate's glow; floats continuously
	local chest = make("TextButton", { Name = "ChestPortrait", Position = UDim2.fromOffset(72, 40), Size = UDim2.fromOffset(226, 206),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 12 }, body)
	local holder = make("Frame", { Name = "ChestArt", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(212, 212), BackgroundTransparency = 1, ZIndex = 12 }, chest)
	local oldChest = make("ImageLabel", { Name = "ChestFallback", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Image = o.crateImage, ScaleType = Enum.ScaleType.Fit, ZIndex = 13 }, holder)
	artWithFallback(holder, "Chest", Art.Chest, oldChest, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, ZIndex = 14 })
	Style.floatArt(holder, { gate = o.gate, enabled = o.enabled, bob = 4.5, tilt = 3, period = 3.4 })
	Style.feedback(chest)
	chest.Activated:Connect(o.open)
	local title = text(body, "Title", string.upper(o.title), UDim2.fromOffset(92, 246), UDim2.fromOffset(206, 30), 13, 28)
	Style.bold(title, 3)
	-- rewards: right side, inside the backplate's safe area (x 6-94 %, y 15-84 %)
	local heading = text(body, "PreviewHeading", "SOME OF WHAT'S INSIDE", UDim2.fromOffset(318, 50), UDim2.fromOffset(418, 32), 13, 28)
	heading.TextColor3 = C(255, 226, 80)
	Style.bold(heading, 3)
	local TILE_W, TILE_H, GAP = 130, 190, 14
	for i, item in Card.pick(o.odds, o.rarityOf) do
		local rarity = rarityOf(item.type, o.rarityOf)
		local tile = make("TextButton", { Name = "Reward_" .. item.type, Text = "", AutoButtonColor = false,
			Position = UDim2.fromOffset(318 + (i - 1) * (TILE_W + GAP), 88), Size = UDim2.fromOffset(TILE_W, TILE_H), ZIndex = 12 }, body)
		tile:SetAttribute("CrusherType", item.type) tile:SetAttribute("Chance", item.text)
		Style.rewardCard(tile, rarity.name, rarity.color)
		-- 31 Oct: Legendary and up get the Index's turning rays, shimmer rim and sparkles
		CardFx.special(tile, rarity.name, o.gate)
		-- separate vertical bands so nothing overlaps: rarity / icon / name / chance
		local tag = text(tile, "Rarity", string.upper(rarity.name), UDim2.fromOffset(6, 7), UDim2.new(1, -12, 0, 22), 15, 20)
		Style.bold(tag, 2)
		local icon = make("Frame", { Name = "IconArea", Position = UDim2.fromOffset(6, 28), Size = UDim2.new(1, -12, 0, 90),
			BackgroundTransparency = 1, ZIndex = 13 }, tile)
		Style.sunburst(icon, { count = 8, alpha = 0.5, width = 0.14, length = 1.25, spin = 0, zIndex = 13,
			colors = { Color3.new(1, 1, 1), C(255, 245, 170) } })
		local art = make("ImageLabel", { Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(94, 94), BackgroundTransparency = 1, Image = o.image(item.type), ScaleType = Enum.ScaleType.Fit, ZIndex = 14 }, icon)
		local name = text(tile, "CrusherName", o.typeName(item.type), UDim2.fromOffset(6, 118), UDim2.new(1, -12, 0, 34), 15, 18)
		Style.bold(name, 2)
		local pill = make("Frame", { Name = "ChancePill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 154),
			Size = UDim2.new(1, -22, 0, 28), BackgroundColor3 = INK, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 15 }, tile)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
		make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.3 }, pill)
		local chance = text(pill, "Chance", item.text, UDim2.fromOffset(6, 3), UDim2.new(1, -12, 1, -6), 16, 20, 2)
		chance.TextColor3 = C(255, 243, 159)
		Style.hoverLift(tile, { art = art, scale = 1.06, artScale = 1.1, lift = 4, tilt = 2, press = 0.95 })
		tile.Activated:Connect(function() Style.click() o.open() end)
	end
	return root
end
return Card
