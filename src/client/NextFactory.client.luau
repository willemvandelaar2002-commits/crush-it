--!strict
-- 12 Nov (Willem: "something that makes people think 'I'm almost there' / 'let me just do
-- this one and then I stop'"; funnel: 22 bought FACTORY II, 2 FACTORY III; vault
-- "Progression and Pacing Design": show the next unlock and how close you are):
-- from FACTORY II on, a small bar above your cash: "FACTORY III  62%".
--   The bays of your current factory count for 75% (every crusher you place moves it),
--   the cash for the next factory the last 25% (only once every bay is full, so buying
--   a bay never makes the bar go back). 75%+ reads ALMOST THERE!, 100% FACTORY III READY!
--   Passing 25 / 50 / 75 / 100% pops the bar once.
-- Reads CrusherState (bays = equipped map, plotLevel, cash).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(RS.Shared.Config)
local C = Config.Crushers
if not C.Enabled then return end
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local RGB = Color3.fromRGB
local W, H = 236, 34

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end

local gui = make("ScreenGui", { Name = "NextFactoryHud", ResetOnSpawn = false, DisplayOrder = 2, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local pill = make("Frame", { Name = "NextFactory", Size = UDim2.fromOffset(W, H), BackgroundColor3 = RGB(24, 28, 52), BackgroundTransparency = 0.15, Visible = false }, gui)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
local stroke = make("UIStroke", { Thickness = 2.5, Color = Style.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill)
local scale = make("UIScale", {}, pill)
local fill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 }, pill)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
local grad = make("UIGradient", { Rotation = 90 }, fill)
local text = make("TextLabel", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 1, -8), BackgroundTransparency = 1, TextScaled = true,
	Text = "", ZIndex = 3 }, pill)
Style.text(text, 2.5)

local function place()
	local hud = me.PlayerGui:FindFirstChild("CrushHud")
	local cash = hud and hud:FindFirstChild("Cash") :: GuiObject?
	local icon = hud and hud:FindFirstChild("CashIcon") :: GuiObject?
	if not cash or cash.AbsoluteSize.Y <= 0 then return false end
	local s = if Style.compact() then 0.8 else 1
	scale.Scale = s
	local origin = gui.AbsolutePosition
	local top = cash.AbsolutePosition.Y
	if icon and icon.AbsoluteSize.Y > 0 then top = math.min(top, icon.AbsolutePosition.Y) end
	if cash.AnchorPoint.Y == 0 then
		-- tablets: cash sits top left, Friend Boost under it; go under that
		local row = hud:FindFirstChild("FriendBoost") :: GuiObject?
		local y = if row then row.AbsolutePosition.Y + row.AbsoluteSize.Y + 8 else cash.AbsolutePosition.Y + cash.AbsoluteSize.Y + 40
		pill.Position = UDim2.fromOffset(12, y - origin.Y)
	else
		pill.Position = UDim2.fromOffset(12, top - origin.Y - H * s - 8)
	end
	return true
end

local function paint(p: number)
	local ready = p >= 1
	local col = if ready then RGB(90, 230, 80) elseif p >= 0.75 then RGB(255, 196, 40) else RGB(80, 170, 255)
	grad.Color = ColorSequence.new(Style.lighten(col, 0.3), Style.darken(col, 0.2))
	stroke.Color = if ready then RGB(255, 255, 255) else Style.Colors.Ink
end

local shownTier = -1 -- the last 25% step popped (so a rejoin at 60% doesn't pop)
local level = -1
local pulse = TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 5 })
local pulsing = false
local function pop()
	local base = if Style.compact() then 0.8 else 1
	scale.Scale = base * 1.25
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = base }):Play()
end

Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) ~= "table" or type(v.plotLevel) ~= "number" or type(v.bays) ~= "table" then return end
	local lv = v.plotLevel
	local nextCost = C.plotCost(lv + 1)
	-- from FACTORY II until the last factory
	if lv < 1 or not nextCost then pill.Visible = false return end
	local cap, prev = C.bayCapacity(lv), C.bayCapacity(lv - 1)
	local filled = 0
	for _ in v.bays do filled += 1 end
	local bayPart = math.clamp((filled - prev) / math.max(1, cap - prev), 0, 1)
	local cashPart = if filled >= cap then math.clamp((v.cash or 0) / nextCost, 0, 1) else 0
	local p = bayPart * 0.75 + cashPart * 0.25
	local name = C.PlotUpgrade.Names[lv + 1] or "NEXT FACTORY"
	local pct = math.floor(p * 100)
	text.Text = if p >= 1 then name .. " READY!" elseif p >= 0.75 then "ALMOST THERE!  " .. pct .. "%" else name .. "  " .. pct .. "%"
	paint(p)
	fill.Size = UDim2.new(math.max(p, 0.08), 0, 1, 0)
	if not pill.Visible then pill.Visible = place() end
	local tier = math.floor(p * 4)
	if lv ~= level then level = lv shownTier = tier
	elseif tier > shownTier then shownTier = tier pop() end
	local want = p >= 1
	if want ~= pulsing then
		pulsing = want
		if want then pulse:Play() else pulse:Cancel() stroke.Thickness = 2.5 end
	end
end)

-- keep it above the cash when the screen size changes
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	task.defer(function() if pill.Visible then place() end end)
end)
