--!strict
-- 11 Nov (audit, Roblox "Paid random items" policy: odds as percentages that add up to 100%,
-- updated while a paid luck effect is on): the ROLL ODDS window. Opened with the ODDS button
-- on the roll machine (CrusherHud action "Odds" fires RollOddsHud.Open). One row per rarity
-- that can roll right now: its chance per pedestal in percent, "1 in N" beside it, and how
-- many crushers share it. Computed with THE roll weights (CrusherConfig.oddsTable) from the
-- luck the server publishes every second (attributes RollLuck, RollLuckMult, RollLuckBonus),
-- so it always matches the real roll, including boosts, Server Luck and the weekend.
-- 11 Nov (later): Willem's art. The window is his RollOdds-Frame (purple header with the
-- dice, gold corners; nine-sliced so it grows with the number of rows) and the YOUR LUCK
-- strip is his RollOdds-LuckBanner with the clover on top. Everything written on them
-- (title, X, luck, rows, numbers) is live UI. Until the images load, plain panels show.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local CC = require(ReplicatedStorage.Shared.CrusherConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = C(19, 23, 42) -- #13172A
local NAVY = C(26, 28, 62)
local FRAME_ART = "rbxassetid://76782318106485" -- Willem's RollOdds-Frame (decal 103893088785478)
local BANNER_ART = "rbxassetid://96273670425822" -- Willem's RollOdds-LuckBanner (decal 117596574851226)
local SRC_W = 1024 -- the art's source width
local W = 640
local K = W / SRC_W -- art scale (header, dice and corners keep their proportions)
local HEADER = math.floor(185 * K) -- the purple header strip in the frame art
local BANNER_H = math.floor(194 * (W - 52) / SRC_W)
local ROW, GAP = 46, 6
local TOP = HEADER + 16 + BANNER_H + 10 + 26 + 8 + 38 + 8 -- first row
local FOOT = 74

-- a brighter colour per rarity for the row (Willem's design); others use the rarity colour
local ROW_COLOR: { [string]: Color3 } = {
	Common = C(176, 188, 206), Uncommon = C(46, 214, 104), Rare = C(30, 160, 255), Epic = C(196, 70, 255),
	Legendary = C(255, 196, 30), Exotic = C(255, 96, 62), Limited = C(70, 210, 90), Secret = C(170, 166, 214),
	Divine = C(60, 222, 255), Eternal = C(196, 160, 255),
}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function corner(p: Instance, r: number) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p: Instance, t: number, c: Color3?) return make("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
-- fixed-size outlined text (not TextScaled, so tiny chances stay readable)
local function text(p: Instance, s: string, pos: UDim2, size: UDim2, px: number, outline: number?, z: number?): TextLabel
	local l = make("TextLabel", { Text = s, Position = pos, Size = size, BackgroundTransparency = 1, TextSize = px,
		TextScaled = false, TextWrapped = false, ZIndex = z or 8 }, p)
	Style.text(l, outline or 2.5)
	local tl = l:FindFirstChild("TextOutline") :: UIStroke? if tl then tl.Color = INK end
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
-- "1 in N": a decimal for small N, so a 67% rarity doesn't read as "1 in 1"
local function oneIn(percent: number): string
	if percent <= 0 then return "-" end
	local n = 100 / percent
	if n < 10 then return (string.format("%.1f", n):gsub("%.0$", "")) end
	return commas(n)
end

local rows = 0 for _, r in CC.Rarities do if r.weight > 0 or r.event then rows += 1 end end
local function heightFor(n: number): number return TOP + n * (ROW + GAP) - GAP + FOOT end

local gui = make("ScreenGui", { Name = "RollOddsHud", ResetOnSpawn = false, DisplayOrder = 7, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local openEvent = make("BindableEvent", { Name = "Open" }, gui)
-- the panel itself is see-through; the art (or the plain fallback) is its background
local panel = make("Frame", { Name = "RollOddsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromOffset(W, heightFor(rows)), BackgroundColor3 = C(34, 20, 92), BackgroundTransparency = 0, Visible = false, ZIndex = 5 }, gui)
corner(panel, 14)
local fallbackStroke = stroke(panel, 5)
local art = make("ImageLabel", { Name = "FrameArt", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = FRAME_ART,
	ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(88, 232, 936, 1162), SliceScale = K, ZIndex = 5 }, panel)
local fallbackHeader = make("Frame", { Name = "PlainHeader", Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, HEADER - 14),
	BackgroundColor3 = C(150, 60, 235), ZIndex = 5 }, panel)
corner(fallbackHeader, 10)
local function artLoaded()
	local ok = art.IsLoaded
	panel.BackgroundTransparency = if ok then 1 else 0
	fallbackStroke.Enabled = not ok
	fallbackHeader.Visible = not ok
end
artLoaded()
Style.modal(panel)

-- header: the dice is in the art; title and X are live
local title = text(panel, "ROLL ODDS", UDim2.fromOffset(math.floor(150 * K) + 16, 14), UDim2.new(1, -math.floor(150 * K) - 110, 0, HEADER - 34), 46, 4.5)
title.TextXAlignment = Enum.TextXAlignment.Left
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -36, 0, 18), Size = UDim2.fromOffset(62, 62),
	Text = "", ZIndex = 8, BackgroundColor3 = C(232, 46, 52), AutoButtonColor = false }, panel)
corner(close, 12) stroke(close, 4)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(255, 120, 110), C(200, 30, 40)) }, close)
Style.feedback(close)
text(close, "X", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 40, 3.5, 9)

-- YOUR LUCK strip (a status, not a button)
local banner = make("ImageLabel", { Name = "LuckBanner", Position = UDim2.fromOffset(26, HEADER + 16), Size = UDim2.new(1, -52, 0, BANNER_H),
	BackgroundColor3 = C(40, 160, 60), BackgroundTransparency = 1, Image = BANNER_ART, ScaleType = Enum.ScaleType.Stretch, ZIndex = 6 }, panel)
local function bannerLoaded()
	banner.BackgroundTransparency = if banner.IsLoaded then 1 else 0
end
corner(banner, 14)
bannerLoaded()
-- load the art now (IsLoaded has no reliable change signal): switch the plain panels off when it's in
task.spawn(function()
	pcall(function() game:GetService("ContentProvider"):PreloadAsync({ art, banner }) end)
	for _ = 1, 60 do
		artLoaded() bannerLoaded()
		if art.IsLoaded and banner.IsLoaded then break end
		task.wait(1)
	end
end)
make("ImageLabel", { Name = "Clover", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 46, 0.5, -2), Size = UDim2.fromOffset(BANNER_H + 4, BANNER_H + 4),
	BackgroundTransparency = 1, Image = Icons.Lucky, ScaleType = Enum.ScaleType.Fit, ZIndex = 8, Rotation = -8 }, banner)
local bw = W - 52
text(banner, "YOUR LUCK", UDim2.fromOffset(98, 12), UDim2.fromOffset(200, 36), 30, 3.5).TextXAlignment = Enum.TextXAlignment.Left
local lvPill = make("Frame", { Position = UDim2.fromOffset(100, 52), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = C(22, 92, 40), ZIndex = 7 }, banner)
corner(lvPill, 14) stroke(lvPill, 2, C(10, 50, 22))
local lvText = text(lvPill, "Luck Lv 0", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 20, 2)
local multText = text(banner, "x1", UDim2.fromOffset(300, 10), UDim2.fromOffset(150, BANNER_H - 20), 44, 4)
local multScale = make("UIScale", { Scale = 1 }, multText)
local livePill = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, bw - 24, 0.5, 0), Size = UDim2.fromOffset(104, 38), BackgroundColor3 = C(16, 70, 30), ZIndex = 7 }, banner)
corner(livePill, 19) stroke(livePill, 2.5, C(255, 214, 70))
local liveDot = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C(120, 255, 90), ZIndex = 8 }, livePill)
corner(liveDot, 8) stroke(liveDot, 2)
local liveText = text(livePill, "LIVE", UDim2.fromOffset(32, 0), UDim2.new(1, -38, 1, 0), 22, 2.5)

local sub = text(panel, "Per pedestal  ·  includes your current luck", UDim2.fromOffset(30, HEADER + 16 + BANNER_H + 10), UDim2.new(1, -60, 0, 26), 21, 2)
sub.TextColor3 = C(222, 210, 255)

-- column heads
local COLS = { { "RARITY", 0.04, 0.33 }, { "CHANCE", 0.38, 0.30 }, { "≈ 1 IN", 0.68, 0.21 }, { "TYPES", 0.89, 0.10 } }
local heads = make("Frame", { Position = UDim2.fromOffset(26, TOP - 46), Size = UDim2.new(1, -52, 0, 38), BackgroundColor3 = C(78, 52, 168), ZIndex = 6 }, panel)
corner(heads, 10) stroke(heads, 2.5)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(120, 84, 220), C(70, 44, 150)) }, heads)
for _, h in COLS do
	local l = text(heads, h[1], UDim2.fromScale(h[2], 0), UDim2.fromScale(h[3], 1), 22, 2.5)
	l.TextXAlignment = if h[1] == "RARITY" then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
end
local list = make("Frame", { Position = UDim2.fromOffset(26, TOP), Size = UDim2.new(1, -52, 0, rows * (ROW + GAP)), BackgroundTransparency = 1, ZIndex = 6 }, panel)
make("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local footer = text(panel, "Updates automatically with your luck", UDim2.new(0, 30, 1, -FOOT + 6), UDim2.new(1, -60, 0, 26), 22, 2.5)
local note = text(panel, "Each type shares its rarity's chance. Rounded values may not add up to exactly 100%.", UDim2.new(0, 30, 1, -FOOT + 34), UDim2.new(1, -60, 0, 20), 16, 1.5)
note.TextColor3 = C(196, 184, 240)

type Row = { frame: Frame, grad: UIGradient, edge: Frame, gem: Frame, name: TextLabel, chance: TextLabel, oneIn: TextLabel, count: TextLabel }
local pool: { Row } = {}
local function rowAt(i: number): Row
	if pool[i] then return pool[i] end
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i, ZIndex = 6 }, list)
	corner(f, 10) stroke(f, 2.5)
	local grad = make("UIGradient", {}, f)
	local edge = make("Frame", { Name = "Edge", Size = UDim2.new(0, 8, 1, 0), ZIndex = 7 }, f)
	corner(edge, 4)
	-- the row marker: a small outlined diamond
	local gem = make("Frame", { Name = "Gem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 30, 0.5, 0), Size = UDim2.fromOffset(16, 16), Rotation = 45, ZIndex = 8 }, f)
	corner(gem, 3) stroke(gem, 2.5)
	local r: Row = { frame = f, grad = grad, edge = edge, gem = gem,
		name = text(f, "", UDim2.new(COLS[1][2], 26, 0, 0), UDim2.new(COLS[1][3], -20, 1, 0), 24, 3),
		chance = text(f, "", UDim2.fromScale(COLS[2][2], 0), UDim2.fromScale(COLS[2][3], 1), 22, 2.5),
		oneIn = text(f, "", UDim2.fromScale(COLS[3][2], 0), UDim2.fromScale(COLS[3][3], 1), 22, 2.5),
		count = text(f, "", UDim2.fromScale(COLS[4][2], 0), UDim2.fromScale(COLS[4][3], 1), 22, 2.5) }
	r.name.TextXAlignment = Enum.TextXAlignment.Left
	pool[i] = r
	return r
end

local lastMult: string? = nil
local function refresh()
	local luck = tonumber(me:GetAttribute("RollLuck")) or 0
	local mult = tonumber(me:GetAttribute("RollLuckMult")) or 1
	local bonus = tonumber(me:GetAttribute("RollLuckBonus")) or 0
	local limited = CC.limitedOn()
	local odds = CC.oddsTable(luck, mult, bonus, limited)
	for i, o in odds do
		local r = rowAt(i)
		local color = ROW_COLOR[o.name] or o.color
		r.frame.Visible = true
		-- bright rarity colour on the left, fading into the dark navy number area
		r.grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Style.lighten(color, 0.12)), ColorSequenceKeypoint.new(0.24, color),
			ColorSequenceKeypoint.new(0.44, NAVY), ColorSequenceKeypoint.new(1, NAVY) })
		r.edge.BackgroundColor3 = Style.lighten(color, 0.35)
		r.gem.BackgroundColor3 = Style.lighten(color, 0.45)
		r.name.Text = string.upper(o.name)
		r.chance.Text = pct(o.percent)
		r.oneIn.Text = oneIn(o.percent)
		r.count.Text = tostring(o.types)
	end
	for i = #odds + 1, #pool do pool[i].frame.Visible = false end
	-- the window fits the rarities that can roll right now (Common can drop to 0% with big luck)
	panel.Size = UDim2.fromOffset(W, heightFor(#odds))
	list.Size = UDim2.new(1, -52, 0, #odds * (ROW + GAP))
	-- the luck strip
	local m = CC.luckMult(mult, bonus)
	local mText = "x" .. (string.format("%.2f", m):gsub("%.?0+$", ""))
	lvText.Text = "Luck Lv " .. tostring(luck)
	multText.Text = mText
	local maxed = m >= CC.LuckMultCap - 1e-9
	liveText.Text = if maxed then "MAX" else "LIVE"
	liveDot.BackgroundColor3 = if maxed then C(255, 214, 70) else C(120, 255, 90)
	sub.Text = if limited then "Per pedestal  ·  includes your luck  ·  LUCKY WEEKEND" else "Per pedestal  ·  includes your current luck"
	sub.TextColor3 = if limited then C(150, 255, 130) else C(222, 210, 255)
	-- a short pop when the multiplier really changes (not on every publish)
	if lastMult and lastMult ~= mText then
		multScale.Scale = 1.3
		TweenService:Create(multScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	lastMult = mText
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
