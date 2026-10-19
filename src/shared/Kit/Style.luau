--!strict
-- Reusable look kit (Destroy-a-Vault style): stud textures, colour themes and
-- UI helpers for chunky, outlined, gradient panels and big green buttons.
-- No game-specific code: copy src/shared/Kit and src/server/Kit to the next game.
--
--   Style.studs(part, faces?, perTile?)        stud pattern on a part
--   Style.theme(name) -> palette               world colours (ground, platform, edge, path, dark,
--                                              and leaf, trunk, rock, fence, lamp for props)
--   Style.lighten(c, f) / Style.darken(c, f)
--   Style.panel(frame, colorA, colorB?)        gradient + dark outline + white inner border + studs
--   Style.button(button, color?)               glossy button (default green) with outline + bounce
--   Style.text(label, strokeThickness?)        white bold text with a dark outline
--   Style.studsImage(guiObject, tile, transparency)   stud pattern inside UI
--   Style.iconButton(parent, opts) -> (TextButton, badge)  big chunky icon tile with a label and a "!" badge
--   Style.rainbow(guiObject, speed?) -> UIGradient          animated rainbow fill (client only)
--   Style.wobble(guiObject, degrees?, speed?)               gentle tilt back and forth (client only)

local Style = {}

local C = Color3.fromRGB

Style.Studs = {
	Texture = "rbxassetid://7447638591", -- free "Stud Texture" (decal 7447638611)
	PerTile = 2,
}
Style.Font = Enum.Font.FredokaOne

Style.Themes = {
	-- teal blocks on yellow ground, like Destroy a Vault's first island
	Teal = {
		ground = C(214, 206, 60), platform = C(40, 104, 100), edge = C(24, 66, 64), path = C(50, 118, 112),
		dark = C(18, 48, 47), pad = C(30, 84, 80), light = C(110, 190, 172),
		-- props (Build.tree/bush/rock/fence/lamp)
		leaf = C(86, 190, 70), trunk = C(120, 78, 46), rock = C(140, 146, 160), fence = C(235, 235, 240), lamp = C(255, 214, 120),
	},
	-- orange/grey scrapyard
	Scrap = {
		ground = C(120, 200, 90), platform = C(96, 100, 116), edge = C(60, 62, 74), path = C(130, 134, 150),
		dark = C(40, 42, 52), pad = C(78, 82, 96), light = C(180, 186, 200),
		leaf = C(70, 160, 60), trunk = C(100, 70, 50), rock = C(150, 120, 100), fence = C(230, 140, 50), lamp = C(255, 190, 90),
	},
}

function Style.theme(name: string): { [string]: Color3 }
	return Style.Themes[name] or Style.Themes.Teal
end

function Style.lighten(c: Color3, f: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), f)
end

function Style.darken(c: Color3, f: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), f)
end

function Style.studs(p: BasePart, faces: { Enum.NormalId }?, perTile: number?)
	for _, face in faces or { Enum.NormalId.Top } do
		local t = Instance.new("Texture")
		t.Name = "Studs"
		t.Texture = Style.Studs.Texture
		t.Face = face
		t.StudsPerTileU = perTile or Style.Studs.PerTile
		t.StudsPerTileV = perTile or Style.Studs.PerTile
		t.Parent = p
	end
end

-- UI -----------------------------------------------------------------------------

local function child(class: string, props: { [string]: any }, parent: Instance): any
	local i = Instance.new(class)
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = parent
	return i
end

function Style.studsImage(parent: GuiObject, tile: number, transparency: number)
	local img = child("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Style.Studs.Texture,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(tile, tile), ImageTransparency = transparency,
		ZIndex = parent.ZIndex,
	}, parent)
	child("UICorner", { CornerRadius = UDim.new(0, 10) }, img)
	return img
end

function Style.text(label: TextLabel | TextButton, strokeThickness: number?)
	label.Font = Style.Font
	label.TextColor3 = Color3.new(1, 1, 1)
	child("UIStroke", { Thickness = strokeThickness or 2, Color = C(20, 20, 30), LineJoinMode = Enum.LineJoinMode.Round }, label)
end

-- A chunky panel: top-to-bottom gradient between two colours, dark outline,
-- thin white inner border and a faint stud pattern.
function Style.panel(frame: Frame, a: Color3, b: Color3?)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	child("UICorner", { CornerRadius = UDim.new(0, 12) }, frame)
	child("UIGradient", { Color = ColorSequence.new(Style.lighten(a, 0.1), b or Style.darken(a, 0.25)), Rotation = 90 }, frame)
	child("UIStroke", { Thickness = 3, Color = Style.darken(a, 0.7), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
	local inner = child("Frame", {
		Name = "InnerBorder", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = frame.ZIndex,
	}, frame)
	child("UICorner", { CornerRadius = UDim.new(0, 10) }, inner)
	child("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inner)
	Style.studsImage(frame, 22, 0.55)
end

local GREEN = C(95, 220, 70)

-- Glossy button: light-to-dark gradient, dark outline, outlined white text.
function Style.button(btn: TextButton, color: Color3?)
	local c = color or GREEN
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	btn.AutoButtonColor = true
	child("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
	child("UIGradient", { Name = "Fill", Color = ColorSequence.new(Style.lighten(c, 0.2), Style.darken(c, 0.2)), Rotation = 90 }, btn)
	child("UIStroke", { Name = "Outline", Thickness = 3, Color = Style.darken(c, 0.65), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
	Style.text(btn, 2)
end

-- Recolour a button made with Style.button.
function Style.setButtonColor(btn: TextButton, c: Color3)
	local fill = btn:FindFirstChild("Fill") :: UIGradient?
	local outline = btn:FindFirstChild("Outline") :: UIStroke?
	if fill then
		fill.Color = ColorSequence.new(Style.lighten(c, 0.2), Style.darken(c, 0.2))
	end
	if outline then
		outline.Color = Style.darken(c, 0.65)
	end
end

-- Big chunky icon button (Destroy a Vault's SHOP / INDEX / REWARDS): a tilted
-- gradient tile with a large emoji, an outlined label overlapping its bottom
-- edge and a red "!" badge (hidden; show it with badge.Visible = true).
-- opts = { name, icon, label, a, b?, size? (px, default 84) }
function Style.iconButton(parent: Instance, opts: { [string]: any }): (TextButton, Frame)
	local size = opts.size or 84
	local btn = child("TextButton", {
		Name = opts.name or "IconButton", Size = UDim2.fromOffset(size, size + 14), BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false,
	}, parent)
	local scale = child("UIScale", { Scale = 1 }, btn)
	local tile = child("Frame", {
		Name = "Tile", Size = UDim2.fromOffset(size, size), Rotation = -4, ZIndex = 2,
	}, btn)
	Style.panel(tile, opts.a, opts.b)
	child("TextLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.78, 0.78),
		BackgroundTransparency = 1, TextScaled = true, Text = opts.icon, ZIndex = 3,
	}, tile)
	local label = child("TextLabel", {
		Name = "Label", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1.15, 0, 0, size * 0.34),
		BackgroundTransparency = 1, TextScaled = true, Text = opts.label, ZIndex = 4,
	}, btn)
	Style.text(label, 3)
	local badge = child("Frame", {
		Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(size * 0.36, size * 0.36),
		BackgroundColor3 = C(235, 40, 40), Visible = false, ZIndex = 5,
	}, btn)
	child("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
	child("UIStroke", { Thickness = 3, Color = Color3.new(1, 1, 1) }, badge)
	local bang = child("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Text = "!", ZIndex = 6,
	}, badge)
	Style.text(bang, 2)
	-- hover grows, press squishes
	local TweenService = game:GetService("TweenService")
	local function to(v: number)
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = v }):Play()
	end
	btn.MouseEnter:Connect(function()
		to(1.08)
	end)
	btn.MouseLeave:Connect(function()
		to(1)
	end)
	btn.Activated:Connect(function()
		scale.Scale = 0.88
		to(1)
	end)
	return btn, badge
end

-- Moving rainbow over a white-backed GuiObject: the hues slide along the
-- gradient every frame (an Offset would clamp to one colour at the ends).
function Style.rainbow(gui: GuiObject, speed: number?): UIGradient
	local g = child("UIGradient", { Name = "Rainbow", Rotation = 20 }, gui)
	local s = speed or 0.35
	local function paint()
		local shift = (os.clock() * s) % 1
		local keys = {}
		for i = 0, 6 do
			local t = i / 6
			keys[i + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV((t * 0.75 + shift) % 1, 0.72, 1))
		end
		g.Color = ColorSequence.new(keys)
	end
	paint()
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		if not g.Parent then
			conn:Disconnect()
			return
		end
		paint()
	end)
	return g
end

-- Tilts a GuiObject gently back and forth (eye-catching offer buttons).
function Style.wobble(gui: GuiObject, degrees: number?, speed: number?)
	local d = degrees or 4
	local s = speed or 3
	local phase = math.random() * 6
	game:GetService("RunService").RenderStepped:Connect(function()
		gui.Rotation = math.sin(os.clock() * s + phase) * d
	end)
end

Style.GREEN = GREEN

return Style
