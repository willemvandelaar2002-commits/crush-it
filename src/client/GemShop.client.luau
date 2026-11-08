--!strict
-- 8 Nov: the GEM SHOP (Shared/GemConfig; server rules "GemCrate" / "GemUpgrade").
-- A GEMS button in the top-left row appears after the first rebirth and shows how
-- many Gems you have. The panel: the Gem Crate (every chance listed before you open
-- it) and the permanent Gem upgrades (kept through rebirths). The server decides.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Config = require(RS.Shared.Config)
local G = require(RS.Shared.GemConfig)
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local RGB = Color3.fromRGB
local GEM = RGB(235, 80, 210)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, max: number, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, stroke or 2.5)
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = max }, l)
	return l
end
local function button(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, max: number): (TextButton, TextLabel)
	local b = make("TextButton", { Text = "", Position = pos, Size = size, ZIndex = 8 }, parent)
	Style.button(b, color)
	Style.buttonStuds(b, color)
	local t = words(b, text, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 1, -12), max)
	t.ZIndex = 10
	return b, t
end
-- the Gem picture: Willem's icon once its id is in GemConfig, a 💎 until then
local function gemIcon(parent: Instance, pos: UDim2, size: UDim2, z: number): GuiObject
	if G.Icon ~= "rbxassetid://0" then
		return make("ImageLabel", { Image = G.Icon, Position = pos, Size = size, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = z }, parent)
	end
	return make("TextLabel", { Text = G.Emoji, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.GothamBold, ZIndex = z }, parent)
end

local gui = make("ScreenGui", { Name = "GemShopHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))

-- HUD button (after REBIRTH in the top-left row)
local hud = Style.iconButton(gui, { name = "GemsButton", image = G.Icon, icon = G.Emoji, label = "GEMS", a = RGB(255, 140, 230), b = RGB(150, 50, 220) })
hud.Visible = false
local function place() if hud.Visible then Style.placeAfterHudRow(hud) end end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
task.spawn(function() while true do place() task.wait(2) end end)

-- panel
local W, H = 780, 500
local panel = make("Frame", { Name = "GemShopPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = RGB(46, 30, 110), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 20) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(110, 50, 190), RGB(36, 22, 96)) }, panel)
local st = Style.studsImage(panel, 30, 0.88) st.ZIndex = 5 st.ImageColor3 = RGB(150, 90, 230)
-- 8 Nov: Willem's Gem banner as the frame (crystal corners kept their size: 9-slice)
make("ImageLabel", { Name = "BannerArt", Image = G.Art.Banner, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(240, 300, 784, 724), SliceScale = 0.42, Position = UDim2.fromOffset(-26, -30), Size = UDim2.new(1, 52, 1, 56), ZIndex = 5 }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 20) panel:SetAttribute("FitHeight", H + 20)
gemIcon(panel, UDim2.fromOffset(22, 12), UDim2.fromOffset(60, 60), 8)
local title = words(panel, "GEM SHOP", UDim2.fromOffset(90, 14), UDim2.fromOffset(300, 54), 46, 4)
title.TextXAlignment = Enum.TextXAlignment.Left
local have = words(panel, "", UDim2.fromOffset(380, 22), UDim2.new(1, -470, 0, 38), 30, 3)
have.TextXAlignment = Enum.TextXAlignment.Right
have.TextColor3 = RGB(255, 200, 250)
local close = button(panel, "X", UDim2.new(1, -76, 0, 12), UDim2.fromOffset(62, 62), RGB(228, 36, 44), 38)
close.Activated:Connect(function() Style.setOpen(panel, false) end)

-- left: the Gem Crate
local crate = make("Frame", { Name = "GemCrate", Position = UDim2.fromOffset(20, 88), Size = UDim2.fromOffset(350, H - 108), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, crate)
make("UIStroke", { Thickness = 4, Color = INK }, crate)
make("UIGradient", { Rotation = 60, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, RGB(255, 150, 235)), ColorSequenceKeypoint.new(0.5, RGB(190, 70, 230)), ColorSequenceKeypoint.new(1, RGB(80, 60, 220)) }) }, crate)
-- 8 Nov: Willem's pink card art over the gradient, his crate in the middle
crate.BackgroundTransparency = 1
local crateStroke = crate:FindFirstChildOfClass("UIStroke") if crateStroke then crateStroke.Enabled = false end
make("ImageLabel", { Name = "CardArt", Image = G.Art.Card, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch,
	Position = UDim2.fromOffset(-10, -10), Size = UDim2.new(1, 20, 1, 20), ZIndex = 6 }, crate)
words(crate, "GEM CRATE", UDim2.fromOffset(30, 26), UDim2.new(1, -60, 0, 38), 34, 3.5)
local crateArt = make("ImageLabel", { Image = G.Art.Crate, Position = UDim2.new(0.5, -62, 0, 54), Size = UDim2.fromOffset(124, 124), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, crate)
Style.floatArt(crateArt, { gate = panel, bob = 2.5, tilt = 0, period = 3.2 })
words(crate, "One crusher per crate. Chances:", UDim2.fromOffset(30, 176), UDim2.new(1, -60, 0, 20), 17, 2)
for i, o in G.Crate.Odds do
	local r = C.rarity(o.rarity)
	local row = make("Frame", { Position = UDim2.fromOffset(32, 198 + (i - 1) * 27), Size = UDim2.new(1, -64, 0, 24), BackgroundColor3 = INK, BackgroundTransparency = 0.25, ZIndex = 7 }, crate)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, row)
	local n = words(row, string.upper(o.rarity), UDim2.fromOffset(12, 2), UDim2.new(0.6, -12, 1, -4), 20, 2)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.TextColor3 = if r then r.color else Color3.new(1, 1, 1)
	local pct = o.chance * 100
	local c = words(row, (if pct == math.floor(pct) then string.format("%d", pct) else string.format("%.1f", pct)) .. "%", UDim2.new(0.6, 0, 0, 2), UDim2.new(0.4, -12, 1, -4), 20, 2)
	c.TextXAlignment = Enum.TextXAlignment.Right
end
local open, openText = button(crate, "OPEN  " .. G.Crate.Cost .. " " .. G.Emoji, UDim2.new(0, 30, 1, -76), UDim2.new(1, -60, 0, 50), Style.GREEN, 30)
-- what came out: the new crusher's name in its rarity colour over the crate for 4 s
local result = words(crate, "", UDim2.fromOffset(24, 146), UDim2.new(1, -48, 0, 30), 26, 3)
result.ZIndex = 12
local waitingFor: { [string]: boolean }? = nil
local resultToken = 0
open.Activated:Connect(function()
	waitingFor = {}
	Net.event("CrusherAction"):FireServer("GemCrate", {})
end)

-- right: permanent upgrades
local list = make("Frame", { Name = "Upgrades", Position = UDim2.fromOffset(384, 88), Size = UDim2.new(1, -404, 0, H - 108), BackgroundTransparency = 1, ZIndex = 6 }, panel)
local head = words(list, "PERMANENT UPGRADES", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 30), 26, 3)
head.TextColor3 = RGB(255, 230, 120)
local note = words(list, "Kept through every rebirth.", UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 22), 18, 2)
note.TextColor3 = RGB(235, 225, 255)
local PALETTE = { Cash = { RGB(255, 236, 120), RGB(250, 150, 30) }, Luck = { RGB(120, 236, 255), RGB(50, 120, 240) }, Rolls = { RGB(255, 150, 220), RGB(160, 60, 230) },
	Pedestal = { RGB(150, 255, 190), RGB(30, 160, 120) } }
local ROW = math.floor((H - 108 - 58) / #G.Upgrades) -- 4 rows: 83 px each
local rows: { [string]: { level: TextLabel, buy: TextButton, cost: TextLabel } } = {}
for i, u in G.Upgrades do
	local pal = PALETTE[u.id] or PALETTE.Rolls
	local f = make("Frame", { Name = u.id, Position = UDim2.fromOffset(0, 58 + (i - 1) * ROW), Size = UDim2.new(1, 0, 0, ROW - 6), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, list)
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, f)
	make("UIStroke", { Thickness = 4, Color = INK }, f)
	make("UIGradient", { Rotation = 30, Color = ColorSequence.new(pal[1], pal[2]) }, f)
	-- 8 Nov: Willem's upgrade icon on the left
	local art = G.Art.Upgrades[u.id]
	if art then make("ImageLabel", { Image = art, Position = UDim2.new(0, 2, 0.5, -36), Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, f) end
	local x = if art then 76 else 14
	local t = words(f, u.title, UDim2.fromOffset(x, 4), UDim2.new(1, -x - 140, 0, 28), 26, 3)
	t.TextXAlignment = Enum.TextXAlignment.Left
	local l = words(f, u.line, UDim2.fromOffset(x, 33), UDim2.new(1, -x - 140, 0, 20), 16, 2)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local lv = words(f, "", UDim2.fromOffset(x, 54), UDim2.new(1, -x - 140, 0, 20), 16, 2)
	lv.TextXAlignment = Enum.TextXAlignment.Left
	lv.TextColor3 = RGB(255, 255, 210)
	local b, bt = button(f, "", UDim2.new(1, -130, 0.5, -24), UDim2.fromOffset(120, 48), Style.GREEN, 24)
	b.Activated:Connect(function() Net.event("CrusherAction"):FireServer("GemUpgrade", { id = u.id }) end)
	rows[u.id] = { level = lv, buy = b, cost = bt }
end

local last: any = nil
local function refresh()
	local gems = math.floor(tonumber(me:GetAttribute("Gems")) or 0)
	local rate = tonumber(me:GetAttribute("GemRate")) or 0
	have.Text = G.Emoji .. " " .. gems .. (if rate > 0 then string.format("   +%.1f/min", rate) else "")
	local label = hud:FindFirstChild("Label") :: TextLabel?
	if label then label.Text = tostring(gems) end -- the button is the gem: just the count
	local canOpen = gems >= G.Crate.Cost
	Style.setButtonColor(open, if canOpen then Style.GREEN else RGB(120, 124, 140))
	openText.Text = "OPEN  " .. G.Crate.Cost .. " " .. G.Emoji
	for _, u in G.Upgrades do
		local r = rows[u.id]
		local level = (last and last.gemUps and last.gemUps[u.id]) or 0
		r.level.Text = "Level " .. level .. " / " .. u.max
		local cost = G.cost(u.id, level)
		if not cost then
			r.cost.Text = "MAX"
			Style.setButtonColor(r.buy, RGB(120, 124, 140))
		else
			r.cost.Text = cost .. " " .. G.Emoji
			Style.setButtonColor(r.buy, if gems >= cost then Style.GREEN else RGB(120, 124, 140))
		end
	end
end
local function showHud()
	local rebirths = tonumber(me:GetAttribute("Rebirths")) or 0
	local should = rebirths >= G.UnlockRebirths
	if hud.Visible ~= should then hud.Visible = should place() end
end
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) == "table" and type(v.gemUps) == "table" then
		-- after OPEN: the crusher that wasn't there before is the crate's
		if waitingFor and last and type(v.items) == "table" and type(last.items) == "table" then
			local known: { [string]: boolean } = {}
			for _, item in last.items do known[item.id] = true end
			for _, item in v.items do
				if not known[item.id] then
					local r = C.rarity(item.rarity) local t = C.typeById(item.type)
					result.Text = string.upper(item.rarity) .. ": " .. (if t then t.name else item.type) .. "!"
					result.TextColor3 = if r then r.color else Color3.new(1, 1, 1)
					waitingFor = nil
					resultToken += 1
					local mine = resultToken
					task.delay(4, function() if resultToken == mine then result.Text = "" end end)
					break
				end
			end
		end
		last = v
	end
	refresh()
end)
me:GetAttributeChangedSignal("Gems"):Connect(refresh)
me:GetAttributeChangedSignal("GemRate"):Connect(refresh)
me:GetAttributeChangedSignal("Rebirths"):Connect(showHud)
showHud()
refresh()
hud.Activated:Connect(function()
	refresh()
	Style.setOpen(panel, not panel.Visible)
end)
-- other scripts (or a test) can open it: GemShopHud:SetAttribute("Open", true)
gui:GetAttributeChangedSignal("Open"):Connect(function()
	if gui:GetAttribute("Open") then gui:SetAttribute("Open", nil) refresh() Style.setOpen(panel, true) end
end)
