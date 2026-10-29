--!strict
-- Extra shine for the top rarities on UI cards (Index, Rewards), like the
-- reference game: strong rays that turn in a circle and reach the edges, a
-- shimmering inner border (gold Legendary, silver Secret, white-gold Divine,
-- rainbow Mythic), twinkling sparkles and, for Divine and Mythic, a halo
-- that breathes behind the card. Looks per rarity in LOOKS.
--   CardFx.special(card, rarityName, gate) -> boolean   true when it added anything
-- One shared loop animates every card; it skips cards whose `gate` (the panel)
-- is hidden and forgets cards that were destroyed.

local RunService = game:GetService("RunService")
local Style = require(game:GetService("ReplicatedStorage").Shared.Kit.Style)

local CardFx = {}

type Entry = { root: GuiObject, gate: GuiObject?, step: (number) -> () }
local entries: { Entry } = {}
local conn: RBXScriptConnection? = nil

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = parent
	return i
end

local function rainbow(shift: number): ColorSequence
	local keys = {}
	for i = 0, 6 do
		local t = i / 6
		keys[i + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV((t + shift) % 1, 0.65, 1))
	end
	return ColorSequence.new(keys)
end

local GOLD = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 40)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 250, 210)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 170, 20)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 250, 210)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 190, 40)),
})

local function start()
	if conn then return end
	local last = 0
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - last < 1 / 30 then return end
		last = now
		for i = #entries, 1, -1 do
			local e = entries[i]
			if not e.root.Parent then
				table.remove(entries, i)
			elseif not e.gate or e.gate.Visible then
				e.step(now)
			end
		end
	end)
end

-- A four-point twinkle: two thin crossed bars and a small diamond.
local function sparkle(parent: GuiObject, z: number): Frame
	local s = make("Frame", { Name = "Sparkle", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1, ZIndex = z }, parent)
	for _, r in { 0, 90 } do
		local bar = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 1),
			Rotation = r, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, s)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	end
	local core = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.42, 0.42),
		Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, s)
	make("UICorner", { CornerRadius = UDim.new(0, 2) }, core)
	return s
end

local SILVER = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 124, 150)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 94, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 124, 150)),
})
local HEAVEN = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 170)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 230, 255)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 170)),
})
-- per top rarity: card colour, border shimmer, ray speed, halo, sparkles
local LOOKS = {
	Legendary = { base = Color3.fromRGB(255, 176, 20), rim = GOLD, spin = 24, sparkles = 4 },
	Secret = { base = Color3.fromRGB(46, 48, 64), rim = SILVER, spin = 28, sparkles = 5, alpha = 0.7 },
	Divine = { base = Color3.fromRGB(70, 180, 255), rim = HEAVEN, spin = 30, sparkles = 5,
		halo = ColorSequence.new(Color3.fromRGB(255, 246, 190), Color3.fromRGB(150, 235, 255)) },
	Mythic = { base = Color3.fromRGB(245, 40, 120), rainbow = true, spin = 34, sparkles = 5 },
}

function CardFx.special(card: GuiObject, rarity: string, gate: GuiObject?): boolean
	local look = LOOKS[rarity]
	if not look then return false end
	local mythic = look.rainbow == true
	local z = card.ZIndex

	-- deeper, richer fill than the other rarities (the rays bring the light)
	local fill = card:FindFirstChild("Fill")
	if fill and fill:IsA("UIGradient") then
		local base = look.base
		fill.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Style.darken(base, 0.25)),
			ColorSequenceKeypoint.new(0.45, Style.lighten(base, 0.12)),
			ColorSequenceKeypoint.new(1, Style.darken(base, 0.35)),
		})
	end
	-- big turning rays over the whole card
	Style.sunburst(card, { fullBleed = true, count = 10, width = 0.11, alpha = look.alpha or 0.62, glow = 0.75,
		spin = look.spin, gate = gate, zIndex = z, center = UDim2.fromScale(0.5, 0.42) })

	-- shimmering inner border, inside the dark outline
	local rim = make("Frame", { Name = "RarityRim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
		BackgroundTransparency = 1, ZIndex = z + 2 }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 2) }, rim)
	local stroke = make("UIStroke", { Thickness = if look.sparkles > 4 then 4 else 3.5, Color = Color3.new(1, 1, 1),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, rim)
	local grad = make("UIGradient", { Color = if mythic then rainbow(0) else look.rim }, stroke)

	-- Mythic (rainbow) and Divine (gold-blue): a halo that breathes behind the card
	local halo: Frame? = nil
	local parent = card.Parent
	local laidOut = parent ~= nil and parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
	if (mythic or look.halo) and parent and parent:IsA("GuiObject") and not laidOut then
		local h: Frame = make("Frame", { Name = "RarityHalo", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(card.Position.X.Scale + card.Size.X.Scale / 2, card.Position.X.Offset + card.Size.X.Offset / 2,
				card.Position.Y.Scale + card.Size.Y.Scale / 2, card.Position.Y.Offset + card.Size.Y.Offset / 2),
			Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset + 14, card.Size.Y.Scale, card.Size.Y.Offset + 14),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, parent)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, h)
		make("UIGradient", { Name = "Rainbow", Color = if mythic then rainbow(0) else look.halo, Rotation = 45 }, h)
		-- the halo sits just under the card
		h.ZIndex = card.ZIndex
		card.ZIndex += 1
		halo = h
	end

	-- twinkling sparkles at fixed spots, each on its own beat
	local allSpots = { Vector2.new(0.16, 0.18), Vector2.new(0.84, 0.26), Vector2.new(0.22, 0.7), Vector2.new(0.8, 0.66), Vector2.new(0.52, 0.1) }
	local stars = {}
	for i = 1, look.sparkles do
		local p = allSpots[i]
		local s = sparkle(card, z + 3)
		s.Position = UDim2.fromScale(p.X, p.Y)
		stars[i] = { frame = s, phase = math.random() * 6.28, speed = 1.6 + math.random() * 1.2, size = if look.sparkles > 4 then 20 else 16 }
	end

	local phase = math.random()
	table.insert(entries, { root = card, gate = gate, step = function(t: number)
		grad.Rotation = (t * 120 + phase * 360) % 360
		if mythic then
			grad.Color = rainbow(t * 0.25 + phase)
		end
		if halo then
			local h = halo :: Frame;
			local hg = h:FindFirstChild("Rainbow") :: UIGradient
			if mythic then hg.Color = rainbow(t * 0.2 + phase) else hg.Rotation = (t * 40) % 360 end
			h.BackgroundTransparency = 0.15 + 0.4 * (0.5 + 0.5 * math.sin(t * 3 + phase * 6))
		end
		for _, st in stars do
			local k = math.max(0, math.sin(t * st.speed + st.phase))
			k = k * k * k
			st.frame.Size = UDim2.fromOffset(st.size * k, st.size * k)
			st.frame.Rotation = t * 60
		end
	end })
	start()
	return true
end

return CardFx
