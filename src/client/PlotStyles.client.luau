--!strict
-- 11 Nov: the PLOT STYLES window (opened with OPEN on the PLOT STYLES board, CrusherHud action
-- "Styles"). Every style (Shared/PlotStyles): yours to put on your factory (free to switch),
-- earned ones with what it takes (a full row of that rarity or better), Gem ones with their
-- price. Every style you own adds cash forever; the header shows your total.
-- State: attributes PlotStyle (the one on your plot), StylesOwned ("Legendary,Exotic"), Gems.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local Style = require(RS.Shared.Kit.Style)
local Styles = require(RS.Shared.PlotStyles)
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local W, CARD_W, CARD_H = 660, 196, 214

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(p: Instance, text: string, pos: UDim2, size: UDim2, outline: number?, z: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z or 8 }, p)
	Style.text(l, outline or 2.5)
	return l
end
local function commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local rows = math.ceil(#Styles.List / 3) + (if #Styles.List % 3 == 0 then 1 else 0) -- (+ the "more soon" card)
local H = 168 + rows * (CARD_H + 12) + 20

local gui = make("ScreenGui", { Name = "PlotStylesHud", ResetOnSpawn = false, DisplayOrder = 7, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local openEvent = make("BindableEvent", { Name = "Open" }, gui)
local panel = make("Frame", { Name = "PlotStylesPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = C(34, 22, 78), Visible = false, ZIndex = 5 }, gui)
corner(panel, 14) stroke(panel, 5)
local ps = Style.studsImage(panel, 26, 0.92) ps.ZIndex = 5
Style.modal(panel)

local header = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 64), BackgroundColor3 = C(150, 70, 230), ZIndex = 6 }, panel)
corner(header, 10) stroke(header, 4, C(70, 30, 120))
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(205, 130, 255), C(120, 50, 210)) }, header)
label(header, "PLOT STYLES", UDim2.fromOffset(18, 7), UDim2.new(1, -110, 0, 50), 4).TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(50, 50), Text = "", ZIndex = 8,
	BackgroundColor3 = C(225, 50, 50), AutoButtonColor = false }, header)
corner(close, 8) stroke(close, 3) Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 3, 9)

local bonusText = label(panel, "", UDim2.fromOffset(20, 84), UDim2.new(1, -40, 0, 34), 3)
bonusText.TextColor3 = C(150, 255, 130)
local intro = label(panel, "Every style you own adds cash forever. Tap one to put it on your factory.", UDim2.fromOffset(20, 120), UDim2.new(1, -40, 0, 24), 2)
intro.TextColor3 = C(222, 210, 255)

local grid = make("Frame", { Position = UDim2.fromOffset(20, 158), Size = UDim2.new(1, -40, 1, -170), BackgroundTransparency = 1, ZIndex = 6 }, panel)
make("UIGridLayout", { CellSize = UDim2.fromOffset(CARD_W, CARD_H), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center }, grid)

local function act(name: string, id: string) Net.event("CrusherAction"):FireServer(name, { id = id }) end

type Card = { frame: Frame, button: TextButton, status: TextLabel }
local cards: { [string]: Card } = {}
local CLASSIC = { floor = C(120, 132, 150), trim = C(255, 222, 24), rim = C(60, 120, 230), lamp = C(255, 240, 200), accent = C(255, 255, 255) }
for i, st in Styles.List do
	local pal = st.palette or CLASSIC
	local f = make("Frame", { Name = st.id, BackgroundColor3 = C(48, 40, 90), LayoutOrder = i, ZIndex = 6 }, grid)
	corner(f, 10) stroke(f, 3)
	-- a small picture of the palette: floor with a trim edge, two lamps
	local pic = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 82), BackgroundColor3 = pal.floor, ZIndex = 7 }, f)
	corner(pic, 8) stroke(pic, 3, pal.rim)
	make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = pal.trim, BorderSizePixel = 0, ZIndex = 8 }, pic)
	for _, x in { 0.2, 0.8 } do
		local lamp = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.42), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = pal.lamp, ZIndex = 8 }, pic)
		corner(lamp, 9) stroke(lamp, 2)
	end
	local nm = label(f, st.name, UDim2.fromOffset(8, 98), UDim2.new(1, -16, 0, 30), 3)
	nm.TextColor3 = if st.palette then Style.lighten(pal.trim, 0.2) else Color3.new(1, 1, 1)
	local cash = label(f, if st.cash > 0 then "+" .. math.floor(st.cash * 100 + 0.5) .. "% CASH" else "THE ORIGINAL", UDim2.fromOffset(8, 128), UDim2.new(1, -16, 0, 22), 2)
	cash.TextColor3 = C(150, 255, 130)
	local status = label(f, "", UDim2.fromOffset(8, 150), UDim2.new(1, -16, 0, 16), 1.5)
	status.TextColor3 = C(200, 190, 235)
	local b = make("TextButton", { Position = UDim2.new(0, 10, 1, -44), Size = UDim2.new(1, -20, 0, 36), Text = "", TextScaled = true, ZIndex = 8 }, f)
	Style.button(b, Style.GREEN)
	b.Activated:Connect(function()
		local owned = Styles.owns({ owned = (function() local o = {} for id in string.gmatch(me:GetAttribute("StylesOwned") or "", "[^,]+") do o[id] = true end return o end)() }, st.id)
		if owned then act("SetStyle", st.id) elseif st.kind == "gem" then act("BuyStyle", st.id) end
	end)
	cards[st.id] = { frame = f, button = b, status = status }
end
-- Willem's special styles (for Gems) come here
local soon = make("Frame", { Name = "Soon", BackgroundColor3 = C(40, 34, 74), BackgroundTransparency = 0.2, LayoutOrder = 999, ZIndex = 6 }, grid)
corner(soon, 10) stroke(soon, 3, C(90, 80, 140))
label(soon, "SPECIAL STYLES\nFOR GEMS\nCOMING SOON", UDim2.fromScale(0.08, 0.2), UDim2.fromScale(0.84, 0.6), 2.5).TextColor3 = C(255, 170, 245)

local function refresh()
	local owned: { [string]: boolean } = {}
	for id in string.gmatch(me:GetAttribute("StylesOwned") or "", "[^,]+") do owned[id] = true end
	local active = me:GetAttribute("PlotStyle") or Styles.Default
	local gems = tonumber(me:GetAttribute("Gems")) or 0
	local bonus = Styles.cashBonus({ owned = owned })
	bonusText.Text = if bonus > 0 then "YOUR STYLES: +" .. math.floor(bonus * 100 + 0.5) .. "% CASH" else "EARN STYLES FOR EXTRA CASH"
	for id, card in cards do
		local st = Styles.ById[id]
		local has = id == Styles.Default or owned[id]
		if id == active then
			card.button.Text = "ON YOUR FACTORY" Style.setButtonColor(card.button, Style.Colors.Gold) card.button.Active = false
			card.status.Text = if st.kind == "earned" then "EARNED" else ""
		elseif has then
			card.button.Text = "USE" Style.setButtonColor(card.button, Style.GREEN) card.button.Active = true
			card.status.Text = if st.kind == "earned" then "EARNED" elseif st.kind == "gem" then "BOUGHT" else ""
		elseif st.kind == "earned" then
			card.button.Text = "LOCKED" Style.setButtonColor(card.button, C(110, 112, 130)) card.button.Active = false
			card.status.Text = "6 " .. string.upper(st.rarity or "") .. "+ IN ONE ROW"
		else
			local price = st.price or 0
			card.button.Text = commas(price) .. " GEMS" Style.setButtonColor(card.button, if gems >= price then C(235, 80, 210) else C(110, 112, 130))
			card.button.Active = true
			card.status.Text = ""
		end
		card.frame.BackgroundColor3 = if has then C(56, 46, 104) else C(36, 32, 64)
	end
end

local open = false
openEvent.Event:Connect(function() open = true refresh() Style.setOpen(panel, true) end)
close.Activated:Connect(function() open = false Style.setOpen(panel, false) end)
for _, a in { "PlotStyle", "StylesOwned", "Gems" } do
	me:GetAttributeChangedSignal(a):Connect(function() if open then refresh() end end)
end
