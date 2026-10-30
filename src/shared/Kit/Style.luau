--!strict
-- Reusable look kit (Destroy-a-Vault style): stud textures, colour themes and
-- UI helpers for chunky, outlined, gradient panels and big green buttons.
-- No game-specific code: copy src/shared/Kit and src/server/Kit to the next game.
--
--   Style.studs(part, faces?)                  imported Studs material on the whole part
--                                              (an empty faces list means no studs)
--   Style.materialStuds(part, enabled?) -> boolean   same; kept for older callers
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
--   Style.flowingStuds(guiObject, tile, transparency, gate?) stud pattern that slowly drifts (client only)
--   Style.sunburst(guiObject, props?) -> Frame              white rays fanning out behind an icon

local Style = {}

local C = Color3.fromRGB
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")
local INK = C(19, 23, 42) -- #13172A

Style.Colors = {
	Ink = INK, Blue = C(65, 151, 255), Purple = C(153, 83, 238),
	Pink = C(255, 89, 135), Gold = C(255, 210, 68), Red = C(250, 42, 48),
	Green = C(45, 230, 45), Yellow = C(255, 222, 24),
	Cobalt = C(48, 111, 224), CobaltDark = C(30, 64, 139),
	Steel = C(119, 145, 169), SteelDark = C(62, 82, 110),
	Safety = C(255, 216, 72), Chrome = C(211, 231, 245),
}

-- The imported Studs MaterialVariant (MaterialService, saved with the place)
-- is the only stud look in the world. UI uses its colour map as a tiled image.
Style.Studs = {
	MaterialVariant = "Studs",
	UiImage = "rbxassetid://10509831729", -- Studs variant colour map
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
	-- Toy workshop finishes on the existing island geometry. Legacy keys remain
	-- because Build/Plots/Hub consume them; changing this palette changes no shapes.
	Island = {
		ground = C(119, 145, 169), platform = C(119, 145, 169), edge = C(48, 67, 94), path = C(167, 181, 194),
		dark = C(29, 42, 65), pad = C(68, 92, 122), light = C(211, 231, 245), trim = C(255, 216, 72),
		grass = C(119, 145, 169), grassEdge = C(57, 80, 109), dirt = C(73, 95, 123), stone = C(141, 161, 180), stoneDark = C(78, 100, 127),
		wood = C(167, 181, 194), woodDark = C(48, 67, 94),
		leaf = C(105, 193, 79), trunk = C(133, 99, 69), rock = C(161, 156, 145), fence = C(185, 205, 223), lamp = C(255, 242, 200),
		cliff = C(172, 166, 153), cliffDark = C(137, 131, 121),
	},
	Factory = {
		ground = C(118, 206, 78), platform = C(96, 100, 110), edge = C(48, 50, 58), path = C(236, 186, 64),
		dark = C(32, 34, 42), pad = C(56, 59, 68), light = C(170, 176, 190), trim = C(250, 196, 46),
		leaf = C(96, 200, 72), trunk = C(118, 78, 48), rock = C(132, 128, 136), fence = C(236, 236, 242), lamp = C(255, 206, 110),
		cliff = C(150, 146, 136), cliffDark = C(118, 112, 104), grass = C(110, 200, 70),
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

-- Imported Studs on the whole part (a MaterialVariant always wraps every face).
-- Pass an empty faces list for "no studs" (Build.block uses that).
function Style.studs(p: BasePart, faces: { Enum.NormalId }?, _perTile: number?)
	if faces and #faces == 0 then return end
	local variant = MaterialService:FindFirstChild(Style.Studs.MaterialVariant)
	if not (variant and variant:IsA("MaterialVariant")) then return end
	p.Material = variant.BaseMaterial
	p.MaterialVariant = variant.Name
end

function Style.materialStuds(p: BasePart, enabled: boolean?, _faces: { Enum.NormalId }?, _perTile: number?): boolean
	if enabled == false then return false end
	Style.studs(p)
	return p.MaterialVariant == Style.Studs.MaterialVariant
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

-- Named decorations are updated in place: restyling never stacks strokes or gradients.
local function decoration(parent: Instance, class: string, name: string, props: { [string]: any }): any
	local item = parent:FindFirstChild(name)
	if not item then
		return child(class, props, parent) -- name is assigned below by the caller's props
	end
	for key, value in props do
		(item :: any)[key] = value
	end
	return item
end

function Style.studsImage(parent: GuiObject, tile: number, transparency: number)
	local img = decoration(parent, "ImageLabel", "Studs", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Style.Studs.UiImage,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(tile, tile), ImageTransparency = transparency,
		ZIndex = parent.ZIndex,
	})
	decoration(img, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 10) })
	return img
end

function Style.text(label: TextLabel | TextButton, strokeThickness: number?)
	label.Font = Style.Font
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BorderSizePixel = 0
	decoration(label, "UIStroke", "TextOutline", { Name = "TextOutline", Thickness = strokeThickness or 2, Color = INK,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round })
end

-- A chunky panel: top-to-bottom gradient between two colours, dark outline,
-- thin white inner border and visible, colour-matched studs. Tinting the grey
-- imported colour map keeps its flat areas from washing bright paint pastel.
function Style.panel(frame: Frame, a: Color3, b: Color3?)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	decoration(frame, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 12) })
	decoration(frame, "UIGradient", "PanelFill", { Name = "PanelFill", Color = ColorSequence.new(Style.lighten(a, 0.035), b or Style.darken(a, 0.3)), Rotation = 90 })
	decoration(frame, "UIStroke", "Outline", { Name = "Outline", Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	local inner = decoration(frame, "Frame", "InnerBorder", {
		Name = "InnerBorder", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = 0, BorderSizePixel = 0,
	})
	decoration(inner, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 9) })
	decoration(inner, "UIStroke", "Shine", { Name = "Shine", Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	local studs = Style.studsImage(frame, 26, 0.42)
	studs.ImageColor3 = a
	studs.ZIndex = 0
end

-- Compact collectible cards and headers: same palette/studs as panels, with
-- squarer corners so neighbouring cards read as a single dense collection.
function Style.collectionPanel(frame: Frame, a: Color3, b: Color3?)
	Style.panel(frame, a, b)
	local corner = frame:FindFirstChild("Corner") :: UICorner
	corner.CornerRadius = UDim.new(0, 4)
	for _, name in { "InnerBorder", "Studs" } do
		local layer = frame:FindFirstChild(name)
		local inner = layer and layer:FindFirstChildOfClass("UICorner")
		if inner then inner.CornerRadius = UDim.new(0, 2) end
	end
end

-- Opt-in bolted casing for major workshop panels. Keep this off list/grid
-- containers; the single noninteractive decoration layer sits behind content.
function Style.workshopPanel(frame: Frame, accent: Color3?)
	Style.panel(frame, Style.Colors.SteelDark, C(35, 52, 81))
	local hardware = decoration(frame, "Frame", "WorkshopHardware", {
		Name = "WorkshopHardware", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = false, Selectable = false, ZIndex = 0,
	})
	decoration(hardware, "Frame", "Accent", {
		Name = "Accent", Position = UDim2.fromOffset(22, 3), Size = UDim2.new(1, -44, 0, 3),
		BackgroundColor3 = accent or Style.Colors.Cobalt, BorderSizePixel = 0,
	})
	for index, point in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local bolt = decoration(hardware, "Frame", "Bolt" .. index, {
			Name = "Bolt" .. index, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(point.X, if point.X == 0 then 8 else -8, point.Y, if point.Y == 0 then 8 else -8),
			Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Style.Colors.Chrome, BorderSizePixel = 0,
		})
		decoration(bolt, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(1, 0) })
		decoration(bolt, "Frame", "Slot", {
			Name = "Slot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(4, 1), Rotation = 35, BackgroundColor3 = INK, BorderSizePixel = 0,
		})
	end
end

-- Small pressure dial for machine controls. The caller owns needle motion;
-- this helper never reads or changes gameplay state.
function Style.pressureGauge(parent: GuiObject): (Frame, Frame)
	local dial = decoration(parent, "Frame", "PressureGauge", {
		Name = "PressureGauge", Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Style.Colors.Chrome,
		BorderSizePixel = 0, Active = false, Selectable = false,
	})
	decoration(dial, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(1, 0) })
	decoration(dial, "UIStroke", "Outline", { Name = "Outline", Color = INK, Thickness = 3 })
	for index, angle in { -60, -30, 0, 30, 60 } do
		local radians = math.rad(angle - 90)
		decoration(dial, "Frame", "Tick" .. index, {
			Name = "Tick" .. index, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.cos(radians) * 0.35, 0.57 + math.sin(radians) * 0.35),
			Size = UDim2.fromOffset(2, 4), Rotation = angle, BorderSizePixel = 0,
			BackgroundColor3 = if index == 5 then Style.Colors.Red else INK,
		})
	end
	local needle = decoration(dial, "Frame", "Needle", {
		Name = "Needle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.fromScale(0.65, 0.65), BackgroundTransparency = 1, Rotation = -60, ZIndex = 2,
	})
	decoration(needle, "Frame", "Pointer", {
		Name = "Pointer", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(3, 11), BackgroundColor3 = Style.Colors.Red, BorderSizePixel = 0,
	})
	local hub = decoration(dial, "Frame", "Hub", {
		Name = "Hub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.fromOffset(6, 6), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 3,
	})
	decoration(hub, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(1, 0) })
	return dial, needle
end

local GREEN = Style.Colors.Green

local function buttonFill(c: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Style.lighten(c, 0.28)),
		ColorSequenceKeypoint.new(0.48, Style.lighten(c, 0.04)),
		ColorSequenceKeypoint.new(0.5, c),
		ColorSequenceKeypoint.new(1, Style.darken(c, 0.18)),
	})
end

-- Uses its own scale, never changes layout sizes, and also responds to gamepad focus.
function Style.feedback(btn: GuiButton)
	if btn:FindFirstChild("FeedbackScale") then
		return
	end
	local scale = child("UIScale", { Name = "FeedbackScale", Scale = 1 }, btn)
	local hover, down = false, false
	local tween: Tween? = nil
	local function update()
		if tween then tween:Cancel() end
		local target = if not btn.Active then 1 else if down then 0.94 else if hover then 1.04 else 1
		local nextTween = TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Scale = target })
		tween = nextTween
		nextTween:Play()
	end
	btn.MouseEnter:Connect(function() hover = true; update() end)
	btn.MouseLeave:Connect(function() hover = false; down = false; update() end)
	btn.SelectionGained:Connect(function() hover = true; update() end)
	btn.SelectionLost:Connect(function() hover = false; down = false; update() end)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA then
			down = true
			update()
			local connection: RBXScriptConnection? = nil
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
					if connection then connection:Disconnect() end
					down = false
					update()
				end
			end)
		end
	end)
	btn:GetPropertyChangedSignal("Active"):Connect(update)
end

-- Glossy button: light-to-dark gradient, dark outline, outlined white text.
function Style.button(btn: TextButton, color: Color3?)
	local c = color or GREEN
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	decoration(btn, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 10) })
	decoration(btn, "UIGradient", "Fill", { Name = "Fill", Color = buttonFill(c), Rotation = 90 })
	decoration(btn, "UIStroke", "Outline", { Name = "Outline", Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	Style.text(btn, 2)
	Style.feedback(btn)
end

-- Recolour a button made with Style.button.
function Style.setButtonColor(btn: TextButton, c: Color3)
	local fill = btn:FindFirstChild("Fill") :: UIGradient?
	local outline = btn:FindFirstChild("Outline") :: UIStroke?
	if fill then
		fill.Color = buttonFill(c)
	end
	if outline then
		outline.Color = INK
	end
end

-- Small vector illustrations render consistently on every device without uploaded assets.
function Style.icon(parent: Instance, kind: string): Frame
	local root = child("Frame", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.75, 0.75), ZIndex = 3 }, parent)
	child("UIAspectRatioConstraint", { AspectRatio = 1 }, root)
	local function block(x: number, y: number, w: number, h: number, color: Color3, radius: number?, outlined: boolean?): Frame
		local part = child("Frame", { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
			BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 1 }, root)
		child("UICorner", { CornerRadius = UDim.new(radius or 0.08, 0) }, part)
		if outlined ~= false then
			child("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, part)
		end
		return part
	end
	if kind == "Shop" then
		block(0.3, 0.04, 0.4, 0.45, C(255, 230, 246), 0.4)
		block(0.08, 0.32, 0.84, 0.58, C(255, 88, 148))
		block(0.16, 0.38, 0.68, 0.12, C(255, 184, 222), 0.1, false)
		for _, x in { 0.3, 0.6 } do block(x, 0.59, 0.1, 0.18, C(190, 32, 98), 0.1, false) end
	elseif kind == "Book" then
		block(0.08, 0.2, 0.84, 0.7, C(39, 114, 235))
		block(0.15, 0.12, 0.7, 0.65, C(224, 247, 255))
		block(0.14, 0.06, 0.7, 0.59, C(73, 188, 255))
		block(0.16, 0.08, 0.12, 0.55, C(25, 103, 219), 0.05, false)
		block(0.38, 0.23, 0.32, 0.08, C(234, 255, 255), 0.1, false)
		block(0.38, 0.38, 0.24, 0.06, C(234, 255, 255), 0.1, false)
	elseif kind == "Rewards" then
		local left = block(0.17, 0.08, 0.33, 0.3, C(255, 214, 64), 0.4)
		left.Rotation = 24
		local right = block(0.5, 0.08, 0.33, 0.3, C(255, 214, 64), 0.4)
		right.Rotation = -24
		block(0.12, 0.4, 0.76, 0.5, C(170, 94, 255))
		block(0.06, 0.31, 0.88, 0.2, C(213, 153, 255))
		block(0.42, 0.32, 0.16, 0.57, C(255, 219, 70), 0.05)
	elseif kind == "Cash" then
		block(0.08, 0.31, 0.82, 0.52, C(33, 150, 76))
		block(0.13, 0.19, 0.78, 0.5, C(141, 255, 99))
		block(0.19, 0.25, 0.66, 0.37, C(55, 188, 80), 0.08, false)
		local dollar = child("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.32, 0.18),
			Size = UDim2.fromScale(0.4, 0.5), Text = "$", TextScaled = true, ZIndex = 2 }, root)
		Style.text(dollar, 2)
	end
	return root
end

function Style.compact(): boolean
	local input = game:GetService("UserInputService")
	local camera = workspace.CurrentCamera
	-- (right at start-up the camera can still report a 1x1 viewport: ignore that)
	return (input.TouchEnabled and not input.KeyboardEnabled) or (camera ~= nil and camera.ViewportSize.X > 10 and camera.ViewportSize.X < 1000)
end

-- 30 Oct (phone patch): full-screen celebration pop-ups (banners, "+30
-- tokens!", purchase text) end their grow animation at this scale.
function Style.popScale(): number
	return if Style.compact() then 0.6 else 1
end

function Style.placeHudButton(btn: TextButton, slot: number)
	local size = if Style.compact() then 54 else 84
	btn.Size = UDim2.fromOffset(size, size + 14)
	btn.Position = UDim2.fromOffset(12 + slot * (size + 10), 8)
	local tile = btn:FindFirstChild("Tile") :: Frame
	tile.Size = UDim2.fromOffset(size, size)
	local label = btn:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.new(1.15, 0, 0, size * 0.34)
	local badge = btn:FindFirstChild("Badge") :: Frame
	badge.Size = UDim2.fromOffset(size * 0.36, size * 0.36)
end

-- Reflow columns to use the available width, including narrow portrait phones.
function Style.grid(container: GuiObject, minWidth: number, height: number, gap: number?)
	local layout = container:FindFirstChildOfClass("UIGridLayout")
	if not layout then return end
	local spacing = gap or 10
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local function fit()
		local width = math.max(1, container.AbsoluteSize.X - 16)
		local columns = math.max(1, math.floor((width + spacing) / (minWidth + spacing)))
		layout.CellPadding = UDim2.fromOffset(spacing, spacing)
		layout.CellSize = UDim2.fromOffset(math.floor((width - spacing * (columns - 1)) / columns), height)
	end
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
end

function Style.scroll(scroll: ScrollingFrame)
	scroll.ScrollBarImageColor3 = C(229, 237, 255)
	scroll.ScrollBarThickness = 5
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	child("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, scroll)
end

local activePanel: Frame? = nil
local panelTweens: { [Frame]: Tween } = {}
local panelTokens: { [Frame]: number } = {}

function Style.hasModal(): boolean
	return activePanel ~= nil
end

-- Fixed-size panels can set attributes FitWidth/FitHeight (pixels, incl. bits
-- that poke out); they then shrink to fit small screens when opened.
-- 30 Oct (phone patch): panels without FitWidth/FitHeight fit by what they
-- really show: the panel plus anything hanging outside it (side tabs, bottom
-- bars; scrolling lists don't count), so every menu fits a phone screen. When a
-- menu has to shrink, it is also moved so what it shows sits in the middle.
local basePositions: { [GuiObject]: UDim2 } = setmetatable({}, { __mode = "k" }) :: any
local function shownIn(d: GuiObject, panel: GuiObject): boolean
	local node: Instance? = d
	while node and node ~= panel do
		if node:IsA("ScrollingFrame") and node ~= d then return false end -- inside a list
		if node:IsA("GuiObject") and not node.Visible then return false end
		node = node.Parent
	end
	return true
end
local function designBounds(panel: GuiObject, current: number)
	local p0, s0 = panel.AbsolutePosition, panel.AbsoluteSize
	local x1, y1, x2, y2 = p0.X, p0.Y, p0.X + s0.X, p0.Y + s0.Y
	for _, d in panel:GetDescendants() do
		if d:IsA("GuiObject") and shownIn(d, panel) then
			local p, sz = d.AbsolutePosition, d.AbsoluteSize
			x1 = math.min(x1, p.X) y1 = math.min(y1, p.Y) x2 = math.max(x2, p.X + sz.X) y2 = math.max(y2, p.Y + sz.Y)
		end
	end
	current = math.max(current, 0.01)
	local centre = (Vector2.new(x1 + x2, y1 + y2) / 2 - (p0 + s0 / 2)) / current
	return (x2 - x1) / current, (y2 - y1) / current, centre
end
function Style.fitScale(panel: Frame): number
	local w, h = panel:GetAttribute("FitWidth"), panel:GetAttribute("FitHeight")
	local v = workspace.CurrentCamera.ViewportSize
	local centre = Vector2.zero
	if type(w) ~= "number" or type(h) ~= "number" then
		local scale = panel:FindFirstChild("ModalScale") :: UIScale?
		if panel.Visible and panel.AbsoluteSize.X > 0 then
			w, h, centre = designBounds(panel, if scale then scale.Scale else 1)
		else
			w = panel.Size.X.Offset + panel.Size.X.Scale * v.X
			h = panel.Size.Y.Offset + panel.Size.Y.Scale * v.Y
		end
	end
	if w <= 0 or h <= 0 then return 1 end
	-- the area under Roblox's top bar (ScreenGuis keep its inset); phones use nearly all of it
	local inset = game:GetService("GuiService"):GetGuiInset().Y
	local spare = if Style.compact() then 12 else 70
	local fit = math.clamp(math.min((v.X - 24) / w, (v.Y - inset - spare) / h), 0.3, 1)
	-- recentre what the menu shows (only when it has to shrink; desktop stays put)
	if not basePositions[panel] then basePositions[panel] = panel.Position end
	local base = basePositions[panel]
	if fit >= 1 then panel.Position = base
	elseif panel.AnchorPoint == Vector2.new(0.5, 0.5) then
		-- dead centre of the screen (desktop nudges in the offsets are dropped)
		panel.Position = UDim2.new(0.5, -centre.X * fit, 0.5, -centre.Y * fit)
	else panel.Position = base - UDim2.fromOffset(centre.X * fit, centre.Y * fit) end
	return fit
end

-- Phone HUD fit (30 Oct): on compact screens shrink a fixed-pixel HUD piece
-- (UIScale "PhoneFit") to at most `scale`, and also so it takes no more than
-- `width`/`height` of the screen; optional phone-only anchor/position.
-- Desktop is untouched (scale 1, original placement). Tap targets: keep
-- `scale` so buttons stay >= ~40 px.
function Style.phoneFit(obj: GuiObject, opts: { scale: number?, width: number?, height: number?, margin: number?, anchor: Vector2?, position: UDim2? })
	local fit = obj:FindFirstChild("PhoneFit") :: UIScale? or Instance.new("UIScale")
	fit.Name = "PhoneFit" fit.Parent = obj
	local desk = { anchor = obj.AnchorPoint, position = obj.Position }
	local function apply()
		local camera = workspace.CurrentCamera
		if not Style.compact() then
			fit.Scale = 1 obj.AnchorPoint = desk.anchor obj.Position = desk.position
			return
		end
		local v = camera.ViewportSize
		local w = obj.Size.X.Offset local h = obj.Size.Y.Offset
		local s = opts.scale or 1
		if opts.width and w > 0 then s = math.min(s, v.X * opts.width / w) end
		if opts.height and h > 0 then s = math.min(s, v.Y * opts.height / h) end
		if opts.margin and w > 0 then s = math.min(s, (v.X - opts.margin) / w) end -- leave `margin` px of screen width free
		fit.Scale = math.max(0.3, s)
		if opts.anchor then obj.AnchorPoint = opts.anchor end
		if opts.position then obj.Position = opts.position end
	end
	apply()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
	obj:GetPropertyChangedSignal("Size"):Connect(apply)
	return fit
end

function Style.setOpen(panel: Frame, open: boolean)
	local scale = panel:FindFirstChild("ModalScale") :: UIScale?
	if not scale then panel.Visible = open; return end
	panelTokens[panel] = (panelTokens[panel] or 0) + 1
	local token = panelTokens[panel]
	if panelTweens[panel] then panelTweens[panel]:Cancel() end
	if open then
		if not panel.Visible then
			panel.Visible = true -- the visibility handler starts the entrance tween
			return
		end
		panel.Visible = true
		local tween = TweenService:Create(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back), { Scale = Style.fitScale(panel) })
		panelTweens[panel] = tween
		tween:Play()
	else
		local tween = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 0.92 * Style.fitScale(panel) })
		panelTweens[panel] = tween
		tween:Play()
		tween.Completed:Once(function()
			if panelTokens[panel] == token then panel.Visible = false end
		end)
	end
end

-- Shared modal focus: backdrop blocks world/HUD input, with only one panel open.
function Style.modal(panel: Frame)
	local gui = panel:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
	local order = gui.DisplayOrder
	panel.Active = true
	-- one UIScale per panel (a second one is ignored by Roblox): fold older
	-- fit scales into FitWidth/FitHeight-style fitting
	for _, other in panel:GetChildren() do
		if other:IsA("UIScale") and other.Name ~= "ModalScale" then other:Destroy() end
	end
	local scale = child("UIScale", { Name = "ModalScale", Scale = 1 }, panel)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if panel.Visible then scale.Scale = Style.fitScale(panel) end
	end)
	local shade = child("TextButton", { Name = panel.Name .. "Backdrop", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, Text = "",
		AutoButtonColor = false, Visible = false, ZIndex = panel.ZIndex - 1, Modal = true }, gui)
	-- (the backdrop only blocks clicks behind the panel; menus close with their X)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		shade.Visible = panel.Visible
		if panel.Visible then
			if activePanel and activePanel ~= panel then activePanel.Visible = false end
			activePanel = panel
			gui.DisplayOrder = 30
			scale.Scale = 0.92 * Style.fitScale(panel)
			Style.setOpen(panel, true)
			-- children's screen positions are only known after a frame: measure again
			task.delay(0.06, function() if panel.Visible then Style.setOpen(panel, true) end end)
		else
			if activePanel == panel then activePanel = nil end
			gui.DisplayOrder = order
		end
	end)
end

-- An uploaded icon image, centred and kept square (props override the defaults).
function Style.image(parent: Instance, image: string, props: { [string]: any }?): ImageLabel
	local img = child("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit,
	}, parent)
	for k, v in props or {} do
		(img :: any)[k] = v
	end
	return img
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
	local tile = child("Frame", {
		Name = "Tile", Size = UDim2.fromOffset(size, size), Rotation = -4, ZIndex = 2,
	}, btn)
	Style.panel(tile, opts.a, opts.b)
	if opts.image then
		Style.image(tile, opts.image, { Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.86, 0.86), ZIndex = 3 })
	elseif opts.art then
		Style.icon(tile, opts.art)
	else
		child("TextLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.78, 0.78),
		BackgroundTransparency = 1, TextScaled = true, Text = opts.icon, ZIndex = 3,
	}, tile)
	end
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
	child("UIStroke", { Thickness = 3, Color = INK }, badge)
	local bang = child("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Text = "!", ZIndex = 6,
	}, badge)
	Style.text(bang, 2)
	Style.feedback(btn)
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
	local connection: RBXScriptConnection? = nil
	connection = game:GetService("RunService").RenderStepped:Connect(function()
		if not gui.Parent then
			if connection then connection:Disconnect() end
			return
		end
		gui.Rotation = math.sin(os.clock() * s + phase) * d
	end)
end

-- Stud pattern that slowly drifts diagonally (the "moving white pattern" on
-- cards and headers). A clip frame holds a tiled image one tile larger than its
-- parent; sliding it by up to one tile loops seamlessly. `gate`: skip the work
-- while that GuiObject (usually the panel) is hidden.
local flowing: { { img: ImageLabel, tile: number, gate: GuiObject? } } = {}
local flowConn: RBXScriptConnection? = nil
local FLOW_SPEED = 16 -- pixels per second
function Style.flowingStuds(parent: GuiObject, tile: number, transparency: number, gate: GuiObject?): ImageLabel
	local clip = decoration(parent, "Frame", "StudsFlow", {
		Name = "StudsFlow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = parent.ZIndex, BorderSizePixel = 0,
	})
	local img = decoration(clip, "ImageLabel", "Studs", {
		Name = "Studs", Size = UDim2.new(1, tile, 1, tile), Position = UDim2.fromOffset(-tile, -tile), BackgroundTransparency = 1,
		Image = Style.Studs.UiImage, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(tile, tile),
		ImageTransparency = transparency, ZIndex = parent.ZIndex,
	})
	table.insert(flowing, { img = img, tile = tile, gate = gate })
	if not flowConn and game:GetService("RunService"):IsClient() then
		local last = 0
		flowConn = game:GetService("RunService").RenderStepped:Connect(function()
			local now = os.clock()
			if now - last < 1 / 30 then return end
			last = now
			for i = #flowing, 1, -1 do
				local f = flowing[i]
				if not f.img.Parent then
					table.remove(flowing, i)
				elseif not f.gate or f.gate.Visible then
					local o = (now * FLOW_SPEED) % f.tile
					f.img.Position = UDim2.fromOffset(o - f.tile, o - f.tile)
				end
			end
		end)
	end
	return img
end

-- White rays fanning out from a point (behind a reward icon or card portrait),
-- slowly turning in a circle. The rays sit in a clip frame, so they can run
-- past the edges (fullBleed) and still end at the card border.
-- props: count (12), width (scale of the parent width, .13), alpha (ray transparency, .55),
-- length (scale of the parent height, 1.05), center (UDim2), zIndex, color,
-- spin (degrees per second, 0 = still), gate (skip the spin while this is hidden),
-- fullBleed (rays reach the edges instead of fading out in the middle), glow (centre glow transparency),
-- colors (list: each ray takes the next colour), name (clip name, for a second layer)
local spinning: { { holder: Frame, speed: number, gate: GuiObject? } } = {}
local spinConn: RBXScriptConnection? = nil
function Style.sunburst(parent: GuiObject, props: { [string]: any }?): Frame
	local o = props or {}
	local z = o.zIndex or parent.ZIndex
	local clipName = o.name or "SunburstClip" -- a second layer needs its own name
	local clip = decoration(parent, "Frame", clipName, {
		Name = clipName, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = z,
	})
	clip:ClearAllChildren()
	-- a square holder centred on the burst, big enough to cover the card when turned
	local holder = child("Frame", {
		Name = "Sunburst", AnchorPoint = Vector2.new(0.5, 0.5), Position = o.center or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z,
	}, clip)
	child("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, holder)
	local count = o.count or 12
	local alpha = o.alpha or 0.55
	local fade = if o.fullBleed then NumberSequence.new({
		NumberSequenceKeypoint.new(0, alpha + 0.1), NumberSequenceKeypoint.new(0.5, math.max(0, alpha - 0.2)), NumberSequenceKeypoint.new(1, alpha + 0.1),
	}) else NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 1), NumberSequenceKeypoint.new(0.5, alpha),
		NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 1),
	})
	local length = o.length or (if o.fullBleed then 2.2 else 1.05)
	for i = 1, count do
		local ray = child("Frame", {
			Name = "Ray", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(o.width or 0.13, length), Rotation = (i - 1) * 180 / count,
			BackgroundColor3 = if o.colors then o.colors[(i - 1) % #o.colors + 1] else o.color or Color3.new(1, 1, 1),
			BorderSizePixel = 0, ZIndex = z,
		}, holder)
		child("UIGradient", { Rotation = 90, Transparency = fade }, ray)
	end
	-- soft glow in the middle
	local glow = child("Frame", {
		Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55), BackgroundColor3 = o.color or Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z,
	}, holder)
	child("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
	child("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, o.glow or math.min(1, alpha + 0.15)), NumberSequenceKeypoint.new(1, 1),
	}) }, glow)
	local speed = o.spin or 0
	if speed ~= 0 then
		holder.Rotation = math.random() * 30
		table.insert(spinning, { holder = holder, speed = speed, gate = o.gate })
		if not spinConn and game:GetService("RunService"):IsClient() then
			local last = 0
			spinConn = game:GetService("RunService").RenderStepped:Connect(function()
				local now = os.clock()
				local dt = now - last
				if dt < 1 / 30 then return end
				last = now
				dt = math.min(dt, 0.1)
				for i = #spinning, 1, -1 do
					local sp = spinning[i]
					if not sp.holder.Parent then
						table.remove(spinning, i)
					elseif not sp.gate or sp.gate.Visible then
						sp.holder.Rotation = (sp.holder.Rotation + sp.speed * dt) % 360
					end
				end
			end)
		end
	end
	return holder
end

Style.GREEN = GREEN

return Style
