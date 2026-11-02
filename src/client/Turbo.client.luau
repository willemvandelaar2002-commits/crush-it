--!strict
-- 2 Nov: the TURBO menu (opened at the Turbo pump on your plot) and a running
-- turbo chip on the HUD. Prices come from the server (seconds of your income).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local T = require(RS.Shared.TurboConfig)

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local action = Net.event("TurboAction")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, stroke or 2.5)
	return l
end

local gui = make("ScreenGui", { Name = "TurboHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local CARD_W, GAP = 190, 14
local W, H = #T.List * CARD_W + (#T.List + 1) * GAP, 330
local panel = make("Frame", { Name = "TurboPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = Color3.fromRGB(44, 48, 54), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 40)
panel:SetAttribute("FitHeight", H + 60)
local header = make("Frame", { Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 70), BackgroundColor3 = Color3.fromRGB(255, 140, 30), ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, header)
make("UIStroke", { Thickness = 5, Color = INK }, header)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 200, 70), Color3.fromRGB(240, 110, 20)) }, header)
local headTitle = label(header, "TURBO FUEL", UDim2.fromOffset(20, 8), UDim2.new(1, -120, 0, 54), 4)
headTitle.TextXAlignment = Enum.TextXAlignment.Left
headTitle.ZIndex = 7
local close = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(54, 54), Text = "",
	BackgroundColor3 = Color3.fromRGB(228, 36, 44), ZIndex = 8 }, header)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, close)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, close)
label(close, "X", UDim2.fromScale(0.15, 0.1), UDim2.fromScale(0.7, 0.8), 3).ZIndex = 9
local info = label(panel, "Turbo multiplies ALL your cash. The strongest running turbo counts.", UDim2.fromOffset(GAP, 76), UDim2.new(1, -GAP * 2, 0, 24), 2)
local message = label(panel, "", UDim2.fromOffset(GAP, H - 34), UDim2.new(1, -GAP * 2, 0, 26), 2.5)
message.TextColor3 = Color3.fromRGB(255, 230, 120)

type Card = { buy: TextButton, price: TextLabel, left: TextLabel, lock: TextLabel, def: any }
local cards: { Card } = {}
for i, t in T.List do
	local x = GAP + (i - 1) * (CARD_W + GAP)
	local card = make("Frame", { Position = UDim2.fromOffset(x, 108), Size = UDim2.fromOffset(CARD_W, 180), BackgroundColor3 = t.color, ZIndex = 6 }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	make("UIStroke", { Thickness = 4, Color = INK }, card)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Style.lighten(t.color, 0.25), Style.darken(t.color, 0.3)) }, card)
	label(card, t.title, UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 30), 3)
	label(card, "x" .. t.mult .. " CASH", UDim2.fromOffset(8, 38), UDim2.new(1, -16, 0, 40), 3.5)
	label(card, t.minutes .. " MIN", UDim2.fromOffset(8, 78), UDim2.new(1, -16, 0, 22), 2.5)
	local left = label(card, "", UDim2.fromOffset(8, 100), UDim2.new(1, -16, 0, 20), 2)
	left.TextColor3 = Color3.fromRGB(255, 255, 160)
	local buy = make("TextButton", { Position = UDim2.fromOffset(10, 124), Size = UDim2.new(1, -20, 0, 46), Text = "", BackgroundColor3 = Color3.fromRGB(60, 200, 80), ZIndex = 8 }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, buy)
	make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, buy)
	Style.feedback(buy)
	local price = label(buy, "...", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8), 2.5)
	price.ZIndex = 9
	local lock = label(card, "", UDim2.fromOffset(8, 124), UDim2.new(1, -16, 0, 46), 3)
	lock.ZIndex = 9
	buy.Activated:Connect(function() action:FireServer("Buy", t.id) end)
	cards[i] = { buy = buy, price = price, left = left, lock = lock, def = t }
end

local last: any = nil
local function paint()
	local now = workspace:GetServerTimeNow()
	for _, c in cards do
		local t = c.def
		local locked = last and (last.plotLevel or 0) < t.plot
		c.buy.Visible = not locked
		c.lock.Text = if locked then "FACTORY " .. ({ "I", "II", "III", "IV", "V", "VI" })[t.plot + 1] else ""
		local p = last and last.prices and last.prices[t.id]
		c.price.Text = if p then Format.cash(p) else "..."
		local ends = (me:GetAttribute(T.attr(t.id)) :: number?) or 0
		local secs = math.floor(ends - now)
		c.left.Text = if secs > 0 then string.format("RUNNING %d:%02d", secs // 60, secs % 60) else ""
		local cash = (me:GetAttribute("Cash") :: number?) or 0
		c.buy.BackgroundColor3 = if p and cash >= p then Color3.fromRGB(60, 200, 80) else Color3.fromRGB(120, 124, 134)
	end
end
Net.event("TurboState").OnClientEvent:Connect(function(s: any)
	if type(s) ~= "table" then return end
	last = s
	if s.message then message.Text = s.message end
	paint()
end)
Net.event("CrusherOpen").OnClientEvent:Connect(function(kind: any)
	if kind ~= "Turbo" then return end
	message.Text = ""
	Style.setOpen(panel, true)
	action:FireServer("State")
	paint()
end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)

-- running turbo chip, bottom left above the cash
local chip = make("Frame", { Name = "TurboChip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -150), Size = UDim2.fromOffset(170, 40),
	BackgroundColor3 = Color3.fromRGB(255, 140, 30), Visible = false, ZIndex = 4 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, chip)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
local chipText = label(chip, "", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 1, -8), 2.5)
chipText.ZIndex = 5
Style.phoneFit(chip, { scale = 0.75 })
task.spawn(function()
	while true do
		task.wait(0.5)
		local mult, left = T.active(me, workspace:GetServerTimeNow())
		chip.Visible = mult > 1
		if mult > 1 then
			chipText.Text = string.format("TURBO x%d  %d:%02d", mult, left // 60, left % 60)
		end
		if panel.Visible then paint() end
	end
end)
