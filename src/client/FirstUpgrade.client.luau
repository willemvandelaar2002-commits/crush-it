--!strict
-- 11 Nov (Willem's 3 reference games; D1 retention, funnel: 12.4% left at the
-- "Upgrade production" step): the first factory upgrade is one simple pop-up instead of a
-- walk to the FACTORY UPGRADES board and a board full of buttons. One upgrade (Damage),
-- what it does, one big button with a hand pointing at it. Buying it finishes the
-- tutorial step on the server as before (CrusherRules: an Upgrade of the Production group).
-- LATER closes it; the step's arrow to the blue board still works.
-- Opens once per session, when the step comes up and no other window is open.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(RS.Shared.Config)
local C = Config.Crushers
if not C.Enabled then return end
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Icons = require(RS.Shared.Icons)
local Format = require(RS.Shared.Format)

local UPGRADE = "Damage"
local STEP = 0
for i, s in C.TutorialSteps do if s.id == "Upgrade" then STEP = i end end
if STEP == 0 then return end

local me = Players.LocalPlayer
local RGB = Color3.fromRGB
local INK = Style.Colors.Ink

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(p: Instance, text: string, pos: UDim2, size: UDim2, outline: number, z: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z or 8 }, p)
	Style.text(l, outline)
	return l
end

local gui = make("ScreenGui", { Name = "FirstUpgradeHud", ResetOnSpawn = false, DisplayOrder = 8, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "FirstUpgradePanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 380),
	BackgroundColor3 = RGB(36, 74, 160), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(70, 140, 255), RGB(30, 60, 150)) }, panel)
Style.studsImage(panel, 26, 0.9).ZIndex = 5
Style.modal(panel)
-- room for the hand under the button
panel:SetAttribute("FitHeight", 470)

label(panel, "UPGRADE YOUR FACTORY!", UDim2.fromOffset(18, 14), UDim2.new(1, -80, 0, 46), 4)

local art = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(120, 120), BackgroundTransparency = 1, ZIndex = 6 }, panel)
Style.sunburst(art, { ZIndex = 6 })
local icon = Style.image(art, Icons.Power, { Size = UDim2.fromScale(1, 1), ZIndex = 7 })
Style.wobble(icon, 5, 1.4)

local what = label(panel, "", UDim2.fromOffset(20, 196), UDim2.new(1, -40, 0, 40), 3.5)
what.TextColor3 = RGB(150, 255, 130)
label(panel, "All your crushers hit harder = more cash!", UDim2.fromOffset(28, 238), UDim2.new(1, -56, 0, 24), 2.5).TextColor3 = RGB(225, 235, 255)

local buy = make("TextButton", { Name = "Buy", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 276), Size = UDim2.fromOffset(280, 72),
	Text = "", AutoButtonColor = false, ZIndex = 8 }, panel)
Style.button(buy, Style.GREEN)
local buyText = label(buy, "", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), 4, 9)
local buyScale = make("UIScale", {}, buy)
local later = make("TextButton", { Name = "Later", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(44, 44),
	Text = "", AutoButtonColor = false, BackgroundColor3 = RGB(225, 50, 50), ZIndex = 9 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, later)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, later)
Style.feedback(later)
label(later, "X", UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.7, 0.84), 3, 10)

-- the hand: under the button, pointing up at it, bobbing
local hand = make("TextLabel", { Name = "Hand", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.62, 0, 0, 336), Size = UDim2.fromOffset(78, 78),
	BackgroundTransparency = 1, Text = "👆", TextScaled = true, Font = Enum.Font.FredokaOne, ZIndex = 12, Rotation = -12 }, panel)
local bob = TweenService:Create(hand, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.62, 0, 0, 316) })
local throb = TweenService:Create(buyScale, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.06 })

local state: any = nil
local shownOnce = false
local open = false
local function cost(): number
	local lv = (state and state.upgrades and state.upgrades[UPGRADE]) or 0
	return C.globalCost(UPGRADE, lv)
end
local function refresh()
	if not state then return end
	local price = cost()
	local can = (state.cash or 0) >= price
	what.Text = "DAMAGE +" .. math.floor((C.DamageFactor - 1) * 100 + 0.5) .. "%"
	buyText.Text = if can then "UPGRADE  " .. Format.cash(price) else "NEED " .. Format.cash(price)
	Style.setButtonColor(buy, if can then Style.GREEN else RGB(110, 112, 130))
	hand.Visible = can
end
local function setOpen(on: boolean)
	open = on
	if on then refresh() bob:Play() throb:Play() else bob:Cancel() throb:Cancel() buyScale.Scale = 1 end
	Style.setOpen(panel, on)
end

buy.Activated:Connect(function()
	if not state or (state.cash or 0) < cost() then return end
	Net.event("CrusherAction"):FireServer("Upgrade", { id = UPGRADE })
	setOpen(false)
end)
later.Activated:Connect(function() setOpen(false) end)

local function calm(): boolean
	return not Style.hasModal() and me:GetAttribute("CutscenePlaying") ~= true and me:GetAttribute("FactoryEventRunning") ~= true
end

Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) ~= "table" or type(v.tutorial) ~= "number" then return end
	state = v
	if open then
		if v.tutorial ~= STEP then setOpen(false) else refresh() end
		return
	end
	if shownOnce or v.tutorial ~= STEP then return end
	shownOnce = true
	task.spawn(function()
		task.wait(1.6) -- the "step done" celebration of the step before first
		local waited = 0
		while not calm() and waited < 20 do task.wait(0.5) waited += 0.5 end
		if calm() and state and state.tutorial == STEP then setOpen(true) end
	end)
end)
