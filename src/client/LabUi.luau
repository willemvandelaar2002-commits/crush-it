--!strict
-- Shared look for the Coating Lab and Fusion Machine screens (the mockups):
-- a studded coloured header with a big outlined title, studded section
-- panels with title bars, crusher tiles (3D picture, name, level pill, check
-- badge), pills, chunky buttons and twinkling sparkles. Visual only.
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local Style = require(RS.Shared.Kit.Style)
local CrusherIcon = require(script.Parent.CrusherIcon)

local L = {}
L.INK = Style.Colors.Ink
L.GREEN = Color3.fromRGB(88, 214, 40)
L.GOLD = Color3.fromRGB(255, 200, 40)
L.GREY = Color3.fromRGB(112, 124, 146)
L.TILE = Color3.fromRGB(206, 214, 228)
L.WHITE = Color3.new(1, 1, 1)
L.Font = Enum.Font.FredokaOne

function L.make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local make = L.make

-- White text with a thick dark outline (the mockups' chunky lettering).
function L.text(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, textSize: number, stroke: number?): TextLabel
	local t = make("TextLabel", { Name = name, Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
		Font = L.Font, TextSize = textSize, TextColor3 = L.WHITE, TextWrapped = true, ZIndex = 10 }, parent)
	make("UIStroke", { Name = "TextOutline", Thickness = stroke or 3, Color = L.INK, LineJoinMode = Enum.LineJoinMode.Round }, t)
	return t
end

-- Image if the id is set, else an emoji stand-in.
function L.art(parent: Instance, image: string?, glyph: string, pos: UDim2, size: UDim2, z: number?): GuiObject
	if image and image ~= "" then
		return make("ImageLabel", { Name = "Art", Image = image, Position = pos, Size = size, BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit, ZIndex = z or 11 }, parent)
	end
	return make("TextLabel", { Name = "Art", Text = glyph, Position = pos, Size = size, BackgroundTransparency = 1,
		TextScaled = true, Font = Enum.Font.GothamBold, ZIndex = z or 11 }, parent)
end

function L.panel(parent: Instance, name: string, pos: UDim2, size: UDim2, a: Color3, b: Color3?, radius: number?): Frame
	local f = make("Frame", { Name = name, Position = pos, Size = size, ZIndex = 6 }, parent)
	Style.panel(f, a, b)
	if radius then (f:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, radius) end
	return f
end

-- Section with a lighter title bar ("YOUR CRUSHERS", "CHOOSE A COATING").
function L.section(parent: Instance, name: string, title: string, pos: UDim2, size: UDim2, color: Color3): Frame
	local f = L.panel(parent, name, pos, size, color, Style.darken(color, .25), 14)
	local bar = L.panel(f, "TitleBar", UDim2.fromOffset(6, 6), UDim2.new(1, -12, 0, 50), Style.lighten(color, .12), color, 10)
	bar.ZIndex = 7
	L.text(bar, "Title", title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 30, 3)
	return f
end

-- The window: dark studded frame, coloured header, icon, title, subtitle, X.
function L.window(gui: ScreenGui, opts: any): (Frame, TextButton)
	local panel = make("Frame", { Name = opts.name, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .52),
		Size = UDim2.fromOffset(opts.w, opts.h), Visible = false, ZIndex = 5 }, gui)
	Style.panel(panel, Color3.fromRGB(34, 40, 78), Color3.fromRGB(20, 24, 50))
	;(panel:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 22)
	;(panel:FindFirstChild("Outline") :: UIStroke).Thickness = 6
	Style.modal(panel)
	local header = L.panel(panel, "Header", UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 118), opts.color, opts.colorDark, 18)
	header.ZIndex = 6
	L.art(header, opts.icon, opts.glyph, UDim2.fromOffset(-34, -30), UDim2.fromOffset(150, 150), 12)
	local title = L.text(header, "Title", opts.title, UDim2.fromOffset(128, 4), UDim2.new(1, -240, 0, 76), 70, 6)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local sub = L.text(header, "Subtitle", opts.subtitle, UDim2.fromOffset(130, 76), UDim2.new(1, -240, 0, 34), 27, 3)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	local close = make("TextButton", { Name = "Close", Text = "X", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(92, 92), TextSize = 58, ZIndex = 12 }, header)
	Style.button(close, Style.Colors.Red)
	;(close:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 16)
	;(close:FindFirstChild("TextOutline") :: UIStroke).Thickness = 4
	close.Activated:Connect(function() Style.setOpen(panel, false) end)
	return panel, close
end

function L.fit(panel: Frame, w: number, h: number)
	-- 30 Oct: Style.modal's ModalScale does the fitting (one UIScale per panel)
	panel:SetAttribute("FitWidth", w) panel:SetAttribute("FitHeight", h)
	local scale = panel:FindFirstChild("ModalScale") :: UIScale?
	if scale and panel.Visible then scale.Scale = Style.fitScale(panel) end
end

-- Dark rounded label ("Lv. 1", "COPY", "4/4").
function L.pill(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, color: Color3?, textColor: Color3?, textSize: number?): Frame
	local f = make("Frame", { Name = name, Position = pos, Size = size, BackgroundColor3 = color or Color3.fromRGB(26, 30, 52), ZIndex = 11 }, parent)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	make("UIStroke", { Color = L.INK, Thickness = 2 }, f)
	local t = L.text(f, "Text", text, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), textSize or 22, 2)
	t.ZIndex = 12 if textColor then t.TextColor3 = textColor end
	return f
end
function L.setPill(pill: Frame, text: string, color: Color3?, textColor: Color3?)
	local t = pill:FindFirstChild("Text") :: TextLabel
	t.Text = text
	if color then pill.BackgroundColor3 = color end
	t.TextColor3 = textColor or L.WHITE
end

-- Round check badge in a tile's top-right corner.
function L.check(parent: Instance, color: Color3): Frame
	local f = make("Frame", { Name = "Check", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -6),
		Size = UDim2.fromOffset(42, 42), BackgroundColor3 = color, ZIndex = 14 }, parent)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	make("UIStroke", { Color = L.INK, Thickness = 3 }, f)
	local t = L.text(f, "Mark", "✓", UDim2.fromScale(0, -.04), UDim2.fromScale(1, 1), 30, 3) t.ZIndex = 15
	return f
end

-- Crusher tile: 3D picture, name, pill. Gold when selected.
function L.tile(parent: Instance, name: string, size: UDim2, item: any, label: string, pillText: string): TextButton
	local b = make("TextButton", { Name = name, Text = "", Size = size, AutoButtonColor = false, ZIndex = 8 }, parent)
	Style.panel(b :: any, L.TILE, Color3.fromRGB(168, 180, 202))
	;(b:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 14)
	CrusherIcon.new(b, item.type, { position = UDim2.new(.1, 0, 0, 6), size = UDim2.new(.8, 0, .58, 0), zIndex = 9,
		modifier = if item.modifier ~= "Standard" then item.modifier else nil, fused = item.fused })
	local t = L.text(b, "Name", label, UDim2.new(0, 2, .6, 0), UDim2.new(1, -4, .2, 0), 22, 3)
	t.TextScaled = true make("UITextSizeConstraint", { MaxTextSize = 24 }, t)
	L.pill(b, "Pill", pillText, UDim2.new(.18, 0, .81, 0), UDim2.new(.64, 0, .15, 0))
	return b
end
function L.select(tile: Instance, on: boolean, checkColor: Color3?)
	local fill = tile:FindFirstChild("PanelFill") :: UIGradient
	local studs = tile:FindFirstChild("Studs") :: ImageLabel
	local a = if on then L.GOLD else L.TILE
	fill.Color = ColorSequence.new(Style.lighten(a, .035), if on then Color3.fromRGB(240, 160, 20) else Color3.fromRGB(168, 180, 202))
	if studs then studs.ImageColor3 = a end
	local outline = tile:FindFirstChild("Outline") :: UIStroke
	outline.Color = if on then Color3.fromRGB(255, 236, 120) else L.INK
	local old = tile:FindFirstChild("Check") if old then old:Destroy() end
	if on then L.check(tile, checkColor or L.GOLD) end
end

-- Chunky button (APPLY / FUSE).
function L.button(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, color: Color3, textSize: number): TextButton
	local b = make("TextButton", { Name = name, Text = text, Position = pos, Size = size, TextSize = textSize, ZIndex = 10 }, parent)
	Style.button(b, color)
	b.Font = L.Font
	;(b:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 18)
	;(b:FindFirstChild("Outline") :: UIStroke).Thickness = 5
	;(b:FindFirstChild("TextOutline") :: UIStroke).Thickness = 4
	return b
end

-- Twinkling sparkles scattered round a frame: drawn diamonds (font-safe),
-- plus optional emoji (e.g. snowflakes for Frost).
function L.sparkles(parent: Instance, count: number, color: Color3, emoji: { string }?): Frame
	local holder = make("Frame", { Name = "Sparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 12 }, parent)
	local rng = Random.new(count * 13 + (if emoji then #emoji else 0))
	local extra = if emoji then #emoji else 0
	for i = 1, count + extra do
		local edge = rng:NextNumber() < .5
		local x = if edge then (if rng:NextNumber() < .5 then rng:NextNumber(0, .18) else rng:NextNumber(.82, 1)) else rng:NextNumber(.05, .95)
		local y = if edge then rng:NextNumber(.05, .95) else (if rng:NextNumber() < .5 then rng:NextNumber(0, .15) else rng:NextNumber(.8, .95))
		local s = rng:NextInteger(10, 20)
		local t: GuiObject
		if i > count and emoji then
			t = make("TextLabel", { Name = "Emoji", Text = emoji[i - count], AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(x, y),
				Size = UDim2.fromOffset(s * 2, s * 2), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.GothamBold, ZIndex = 12 }, holder)
		else
			t = make("Frame", { Name = "Spark", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(s, s),
				Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 12 }, holder)
			make("UICorner", { CornerRadius = UDim.new(.2, 0) }, t)
			make("Frame", { Name = "Core", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.45, .45),
				BackgroundColor3 = L.WHITE, BorderSizePixel = 0, ZIndex = 13 }, t)
		end
		local prop = if t:IsA("TextLabel") then { TextTransparency = .8 } else { BackgroundTransparency = .85, Size = UDim2.fromOffset(s * .5, s * .5) }
		Tween:Create(t, TweenInfo.new(rng:NextNumber(.7, 1.3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, .8)), prop):Play()
	end
	return holder
end

-- White down arrow (shaft + head), outlined.
function L.arrow(parent: Instance, pos: UDim2, size: UDim2, color: Color3?): Frame
	local f = make("Frame", { Name = "Arrow", Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = 11 }, parent)
	local shaft = make("Frame", { Name = "Shaft", AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, 0),
		Size = UDim2.fromScale(.36, .5), BackgroundColor3 = color or L.WHITE, ZIndex = 11 }, f)
	make("UIStroke", { Color = L.INK, Thickness = 3 }, shaft)
	local head = L.text(f, "Head", "▼", UDim2.fromScale(-.1, .25), UDim2.fromScale(1.2, .85), 10, 3)
	head.TextScaled = true head.TextColor3 = color or L.WHITE head.ZIndex = 12
	return f
end
return L
