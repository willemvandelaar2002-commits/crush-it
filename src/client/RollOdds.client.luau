--!strict
-- 11 Nov (audit, Roblox "Paid random items" policy: odds as percentages that add up to 100%,
-- updated while a paid luck effect is on): the ROLL ODDS window. Opened with the ODDS button
-- on the roll machine (CrusherHud action "Odds" fires RollOddsHud.Open). One row per rarity
-- that can roll right now: its chance per pedestal in percent, "1 in N" beside it, and how
-- many crushers share it. Computed with THE roll weights (CrusherConfig.oddsTable) from the
-- luck the server publishes every second (attributes RollLuck, RollLuckMult, RollLuckBonus),
-- so it always matches the real roll, including boosts, Server Luck and the weekend.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local CC = require(ReplicatedStorage.Shared.CrusherConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local PURPLE = C(150, 70, 230)
local W, ROW = 560, 40

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(p: Instance, text: string, pos: UDim2, size: UDim2, outline: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, p)
	Style.text(l, outline or 2.5)
	return l
end
-- at least four digits after the first non-zero one (the policy's rounding rule), no "e-05"
local function pct(x: number): string
	if x >= 10 then return string.format("%.2f%%", x) end
	if x <= 0 then return "0%" end
	local digits = math.clamp(3 - math.floor(math.log10(x)), 3, 12)
	return string.format("%." .. digits .. "f%%", x)
end
local function commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local rows = 0 for _, r in CC.Rarities do if r.weight > 0 or r.event then rows += 1 end end
local H = 196 + rows * (ROW + 4)

local gui = make("ScreenGui", { Name = "RollOddsHud", ResetOnSpawn = false, DisplayOrder = 7, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local openEvent = make("BindableEvent", { Name = "Open" }, gui)
local panel = make("Frame", { Name = "RollOddsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = C(28, 24, 48), Visible = false, ZIndex = 5 }, gui)
corner(panel, 12) stroke(panel, 5)
local ps = Style.studsImage(panel, 26, 0.92) ps.ZIndex = 5
Style.modal(panel)

local header = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20, 62), BackgroundColor3 = PURPLE, ZIndex = 6 }, panel)
corner(header, 8) stroke(header, 4, Style.darken(PURPLE, 0.5))
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(205, 130, 255), C(130, 50, 220)) }, header)
label(header, "ROLL ODDS", UDim2.new(0, 16, 0, 6), UDim2.new(1, -100, 0, 50), 4).TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(48, 48), Text = "", ZIndex = 8,
	BackgroundColor3 = C(225, 50, 50), AutoButtonColor = false }, header)
corner(close, 6) stroke(close, 3) Style.feedback(close)
label(close, "X", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 3).ZIndex = 9

local intro = label(panel, "Chance per pedestal, with your luck right now", UDim2.fromOffset(18, 80), UDim2.new(1, -36, 0, 26), 2)
intro.TextColor3 = C(255, 240, 170)
local heads = make("Frame", { Position = UDim2.fromOffset(18, 110), Size = UDim2.new(1, -36, 0, 22), BackgroundTransparency = 1, ZIndex = 7 }, panel)
for _, h in { { "RARITY", 0.04, 0.34 }, { "CHANCE", 0.38, 0.24 }, { "1 IN", 0.63, 0.2 }, { "CRUSHERS", 0.84, 0.16 } } do
	local l = label(heads, h[1], UDim2.fromScale(h[2], 0), UDim2.fromScale(h[3], 1), 1.5)
	l.TextXAlignment = if h[1] == "RARITY" then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	l.TextColor3 = C(190, 180, 230)
end
local list = make("Frame", { Position = UDim2.fromOffset(18, 136), Size = UDim2.new(1, -36, 0, rows * (ROW + 4)), BackgroundTransparency = 1, ZIndex = 6 }, panel)
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local footer = label(panel, "", UDim2.new(0, 18, 1, -58), UDim2.new(1, -36, 0, 24), 2)
footer.TextColor3 = C(150, 255, 130)
local note = label(panel, "Each crusher: the rarity's chance divided by its crushers. Rounded values may not add up to exactly 100%.", UDim2.new(0, 18, 1, -32), UDim2.new(1, -36, 0, 22), 1.5)
note.TextColor3 = C(200, 195, 225)

type Row = { frame: Frame, name: TextLabel, chance: TextLabel, oneIn: TextLabel, count: TextLabel }
local pool: { Row } = {}
local function rowAt(i: number): Row
	if pool[i] then return pool[i] end
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = C(48, 42, 78), LayoutOrder = i, ZIndex = 6 }, list)
	corner(f, 6)
	local swatch = make("Frame", { Name = "Swatch", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 10, 1, 0), ZIndex = 7 }, f)
	corner(swatch, 4)
	local r: Row = { frame = f,
		name = label(f, "", UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.33, 0.76), 2),
		chance = label(f, "", UDim2.fromScale(0.38, 0.12), UDim2.fromScale(0.24, 0.76), 2),
		oneIn = label(f, "", UDim2.fromScale(0.63, 0.12), UDim2.fromScale(0.2, 0.76), 2),
		count = label(f, "", UDim2.fromScale(0.84, 0.12), UDim2.fromScale(0.16, 0.76), 2) }
	r.name.TextXAlignment = Enum.TextXAlignment.Left
	pool[i] = r
	return r
end

local function refresh()
	local luck = tonumber(me:GetAttribute("RollLuck")) or 0
	local mult = tonumber(me:GetAttribute("RollLuckMult")) or 1
	local bonus = tonumber(me:GetAttribute("RollLuckBonus")) or 0
	local limited = CC.limitedOn()
	local odds = CC.oddsTable(luck, mult, bonus, limited)
	for i, o in odds do
		local r = rowAt(i)
		r.frame.Visible = true
		r.frame.BackgroundColor3 = Style.darken(o.color, 0.62)
		local sw = r.frame:FindFirstChild("Swatch") :: Frame
		sw.BackgroundColor3 = o.color
		r.name.Text = string.upper(o.name)
		r.name.TextColor3 = Style.lighten(o.color, 0.25)
		r.chance.Text = pct(o.percent)
		r.oneIn.Text = commas(100 / o.percent)
		r.count.Text = tostring(o.types)
	end
	for i = #odds + 1, #pool do pool[i].frame.Visible = false end
	-- the window fits the rarities that can roll right now (Common can drop to 0% with big luck)
	panel.Size = UDim2.fromOffset(W, 196 + #odds * (ROW + 4))
	local m = CC.luckMult(mult, bonus)
	footer.Text = string.format("Luck Lv %d  ·  luck x%s%s", luck, (string.format("%.2f", m):gsub("%.?0+$", "")),
		if m >= CC.LuckMultCap - 1e-9 then " (the maximum)" else "")
		.. (if limited then "  ·  LUCKY WEEKEND" else "")
end

local open = false
local function setOpen(v: boolean)
	open = v
	if v then refresh() end
	Style.setOpen(panel, v)
end
openEvent.Event:Connect(function() setOpen(true) end)
close.Activated:Connect(function() setOpen(false) end)
for _, a in { "RollLuck", "RollLuckMult", "RollLuckBonus" } do
	me:GetAttributeChangedSignal(a):Connect(function() if open then refresh() end end)
end
