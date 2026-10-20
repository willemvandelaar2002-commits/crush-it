--!strict
-- "Next up" goal bar, top centre (Destroy a Vault's "223.88K / 225.00K" bar):
-- always shows the next thing to save for and what it gives.
--   * not at the biggest press  -> cash / price of the Bigger Press, "Next up: <object>"
--   * rebirth unlocked          -> full gold bar, "Rebirth ready! Cash xA > xB"
-- When the bar is full it pulses; tapping it buys the bigger press.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local GREEN_A, GREEN_B = Color3.fromRGB(120, 255, 90), Color3.fromRGB(40, 190, 50)
local GOLD_A, GOLD_B = Color3.fromRGB(255, 235, 110), Color3.fromRGB(240, 160, 20)

local gui = Instance.new("ScreenGui")
gui.Name = "GoalHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Bar: dark rounded track with a studded gradient fill and big outlined text.
local bar = Instance.new("TextButton")
bar.Name = "GoalBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 44)
bar.Size = UDim2.new(if TOUCH then 0.5 else 0.42, 0, 0, if TOUCH then 32 else 42)
bar.BackgroundColor3 = Style.Colors.Ink
bar.AutoButtonColor = false
bar.Text = ""
bar.Parent = gui
local maxW = Instance.new("UISizeConstraint")
maxW.MaxSize = Vector2.new(560, 60)
maxW.Parent = bar
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = bar
local outline = Instance.new("UIStroke")
outline.Thickness = 3
outline.Color = Style.Colors.Ink
outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outline.Parent = bar
local scale = Instance.new("UIScale")
scale.Parent = bar
local function fitBar()
	local compact = Style.compact()
	bar.AnchorPoint = if compact then Vector2.new(1, 0) else Vector2.new(0.5, 0)
	bar.Position = if compact then UDim2.new(1, -14, 0, 8) else UDim2.new(0.5, 0, 0, 44) -- the zone label (Zone.client) sits above it
	bar.Size = if compact then UDim2.new(1, -220, 0, 32) else UDim2.new(0.38, 0, 0, 44)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitBar)
fitBar()

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.Parent = bar
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 10)
fillCorner.Parent = fill
local fillGrad = Instance.new("UIGradient")
fillGrad.Rotation = 90
fillGrad.Parent = fill
Style.studsImage(fill, 20, 0.6)

local amount = Instance.new("TextLabel")
amount.Name = "Amount"
amount.Size = UDim2.fromScale(1, 1)
amount.BackgroundTransparency = 1
amount.TextScaled = true
amount.ZIndex = 3
amount.Parent = bar
Style.text(amount, 3)
local amountPad = Instance.new("UIPadding")
amountPad.PaddingTop = UDim.new(0, 4)
amountPad.PaddingBottom = UDim.new(0, 4)
amountPad.Parent = amount

-- Reward line under the bar ("Next up: 🧸 Teddy Bear").
local reward = Instance.new("TextLabel")
reward.Name = "Reward"
reward.AnchorPoint = Vector2.new(0.5, 0)
reward.Position = UDim2.new(0.5, 0, 1, 4)
reward.Size = UDim2.new(1, 0, 0, if TOUCH then 20 else 24)
reward.BackgroundTransparency = 1
reward.TextScaled = true
reward.Parent = bar
Style.text(reward, 2.5)
local function fitReward()
	local viewport = workspace.CurrentCamera.ViewportSize
	local sharedRow = Style.compact() and viewport.X > viewport.Y
	-- Landscape shares this line with the zone plate on the right.
	reward.AnchorPoint = if sharedRow then Vector2.zero else Vector2.new(0.5, 0)
	reward.Position = UDim2.new(if sharedRow then 0 else 0.5, 0, 1, 4)
	reward.Size = UDim2.new(1, if sharedRow then -164 else 0, 0, if Style.compact() then 20 else 24)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitReward)
fitReward()

local function attr(name: string): number
	return (player:GetAttribute(name) :: number?) or 0
end

local shownRatio = 0
local full = false
local canBuy = false

local function refresh()
	local cash = attr("Cash")
	local tier = math.max(1, attr("Tier"))
	local rebirths = attr("Rebirths")
	local need = Config.Rebirth.RequiredTier(rebirths)
	local ratio: number
	if tier >= need then
		-- rebirth is the goal now
		ratio = 1
		amount.Text = "Rebirth ready!"
		reward.Text = string.format("🔄 Cash x%.1f > x%.1f forever", Config.rebirthMult(rebirths), Config.rebirthMult(rebirths + 1))
		reward.TextColor3 = GOLD_A
		fillGrad.Color = ColorSequence.new(GOLD_A, GOLD_B)
		canBuy = false
	else
		local cost = Config.SizeCost(tier)
		ratio = math.clamp(cash / cost, 0, 1)
		amount.Text = Format.compact(math.min(cash, cost)) .. " / " .. Format.compact(cost)
		local nextName = Config.Objects[tier + 1].name
		reward.Text = if ratio >= 1 then "Tap to unlock: " .. nextName .. "!" else "Next up: " .. nextName
		reward.TextColor3 = Color3.fromRGB(255, 250, 210)
		fillGrad.Color = ColorSequence.new(GREEN_A, GREEN_B)
		canBuy = ratio >= 1
	end
	full = ratio >= 1
	if math.abs(ratio - shownRatio) > 0.001 then
		shownRatio = ratio
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(math.max(ratio, 0.04), 1) }):Play()
	end
	fill.Visible = ratio > 0
end

for _, name in { "Cash", "Tier", "Rebirths" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

-- Pulse while full.
RunService.RenderStepped:Connect(function()
	scale.Scale = if full then 1 + math.abs(math.sin(os.clock() * 4)) * 0.04 else 1
end)

bar.Activated:Connect(function()
	if canBuy then
		Net.event("BuyUpgrade"):FireServer("Size")
	end
end)
