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
local TweenService = game:GetService("TweenService")
local INK = C(19, 23, 38)

Style.Colors = {
	Ink = INK, Blue = C(65, 151, 255), Purple = C(153, 83, 238),
	Pink = C(255, 89, 135), Gold = C(255, 210, 68), Red = C(245, 78, 81),
}

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
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Style.Studs.Texture,
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
-- thin white inner border and a faint stud pattern.
function Style.panel(frame: Frame, a: Color3, b: Color3?)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	decoration(frame, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 12) })
	decoration(frame, "UIGradient", "PanelFill", { Name = "PanelFill", Color = ColorSequence.new(Style.lighten(a, 0.12), b or Style.darken(a, 0.3)), Rotation = 90 })
	decoration(frame, "UIStroke", "Outline", { Name = "Outline", Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	local inner = decoration(frame, "Frame", "InnerBorder", {
		Name = "InnerBorder", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = 0, BorderSizePixel = 0,
	})
	decoration(inner, "UICorner", "Corner", { Name = "Corner", CornerRadius = UDim.new(0, 9) })
	decoration(inner, "UIStroke", "Shine", { Name = "Shine", Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	local studs = Style.studsImage(frame, 22, 0.55) -- as strong as before the 20 Oct polish
	studs.ZIndex = 0
end

local GREEN = C(104, 232, 65)

local function buttonFill(c: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Style.lighten(c, 0.4)),
		ColorSequenceKeypoint.new(0.48, Style.lighten(c, 0.12)),
		ColorSequenceKeypoint.new(0.5, c),
		ColorSequenceKeypoint.new(1, Style.darken(c, 0.25)),
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
	return (input.TouchEnabled and not input.KeyboardEnabled) or (camera ~= nil and camera.ViewportSize.X < 1000)
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
		local tween = TweenService:Create(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back), { Scale = 1 })
		panelTweens[panel] = tween
		tween:Play()
	else
		local tween = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 0.92 })
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
	local scale = child("UIScale", { Name = "ModalScale", Scale = 1 }, panel)
	local shade = child("TextButton", { Name = panel.Name .. "Backdrop", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, Text = "",
		AutoButtonColor = false, Visible = false, ZIndex = panel.ZIndex - 1, Modal = true }, gui)
	shade.Activated:Connect(function() Style.setOpen(panel, false) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		shade.Visible = panel.Visible
		if panel.Visible then
			if activePanel and activePanel ~= panel then activePanel.Visible = false end
			activePanel = panel
			gui.DisplayOrder = 30
			scale.Scale = 0.92
			Style.setOpen(panel, true)
		else
			if activePanel == panel then activePanel = nil end
			gui.DisplayOrder = order
		end
	end)
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
	if opts.art then
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

Style.GREEN = GREEN

return Style
