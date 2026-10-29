--!strict
-- Extra shine for the top rarities on UI cards (Index, Rewards), like the
-- reference game: strong rays that turn in a circle and reach the edges, a
-- shimmering inner border (gold for Legendary, rainbow for Mythic), twinkling
-- sparkles and, for Mythic, a pulsing rainbow halo behind the card.
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

function CardFx.special(card: GuiObject, rarity: string, gate: GuiObject?): boolean
	local mythic = rarity == "Mythic"
	if not mythic and rarity ~= "Legendary" then return false end
	local z = card.ZIndex

	-- big turning rays over the whole card
	Style.sunburst(card, { fullBleed = true, count = if mythic then 10 else 9, width = 0.2, alpha = if mythic then 0.42 else 0.48,
		spin = if mythic then 34 else 24, gate = gate, zIndex = z, center = UDim2.fromScale(0.5, 0.42) })

	-- shimmering inner border, inside the dark outline
	local rim = make("Frame", { Name = "RarityRim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
		BackgroundTransparency = 1, ZIndex = z + 2 }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 2) }, rim)
	local stroke = make("UIStroke", { Thickness = if mythic then 4 else 3.5, Color = Color3.new(1, 1, 1),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, rim)
	local grad = make("UIGradient", { Color = if mythic then rainbow(0) else GOLD }, stroke)

	-- Mythic: a rainbow halo that breathes behind the card
	local halo: Frame? = nil
	local parent = card.Parent
	local laidOut = parent ~= nil and parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
	if mythic and parent and parent:IsA("GuiObject") and not laidOut then
		local h: Frame = make("Frame", { Name = "MythicHalo", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(card.Position.X.Scale + card.Size.X.Scale / 2, card.Position.X.Offset + card.Size.X.Offset / 2,
				card.Position.Y.Scale + card.Size.Y.Scale / 2, card.Position.Y.Offset + card.Size.Y.Offset / 2),
			Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset + 14, card.Size.Y.Scale, card.Size.Y.Offset + 14),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, parent)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, h)
		make("UIGradient", { Name = "Rainbow", Color = rainbow(0), Rotation = 45 }, h)
		-- the halo sits just under the card
		h.ZIndex = card.ZIndex
		card.ZIndex += 1
		halo = h
	end

	-- twinkling sparkles at fixed spots, each on its own beat
	local spots = if mythic
		then { Vector2.new(0.16, 0.18), Vector2.new(0.84, 0.26), Vector2.new(0.22, 0.7), Vector2.new(0.8, 0.66), Vector2.new(0.52, 0.1) }
		else { Vector2.new(0.18, 0.2), Vector2.new(0.82, 0.3), Vector2.new(0.24, 0.68), Vector2.new(0.78, 0.62) }
	local stars = {}
	for i, p in spots do
		local s = sparkle(card, z + 3)
		s.Position = UDim2.fromScale(p.X, p.Y)
		stars[i] = { frame = s, phase = math.random() * 6.28, speed = 1.6 + math.random() * 1.2, size = if mythic then 20 else 16 }
	end

	local phase = math.random()
	table.insert(entries, { root = card, gate = gate, step = function(t: number)
		grad.Rotation = (t * 120 + phase * 360) % 360
		if mythic then
			grad.Color = rainbow(t * 0.25 + phase)
		end
		if halo then
			local h = halo :: Frame;
			(h:FindFirstChild("Rainbow") :: UIGradient).Color = rainbow(t * 0.2 + phase)
			h.BackgroundTransparency = 0.35 + 0.3 * (0.5 + 0.5 * math.sin(t * 3 + phase * 6))
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
