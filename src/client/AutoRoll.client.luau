--!strict
-- 7 Nov (Willem): the AUTO ROLL bar (Willem's art), bottom middle above the crusher
-- hotbar (phones too, smaller). Three buttons:
--   AUTO ROLL  on / off (free, after the tutorial; server/AutoRoll does the rolling)
--   STOP AT    tap to cycle the rarity it stops on (C.AutoRoll.Choices), in its colour
--   AUTO BUY   with the pass: buy what it stops for and keep going; without the pass
--              it shows a lock and opens the pass purchase (nothing until the pass exists)
-- Shown when the Shop button is (the HUD appears step by step in the tutorial).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.CrusherConfig)
local Store = require(RS.Shared.Store)

local me = Players.LocalPlayer
local remote = Net.event("AutoRoll")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end

local gui = make("ScreenGui", { Name = "AutoRollHud", ResetOnSpawn = false, DisplayOrder = 3, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
-- 7 Nov: Willem's art. The bar (1023 x 341) has three slots: a see-through frame for
-- AUTO ROLL (the blue OFF / green ON button image sits in it), a white STOP AT slot
-- (the rarity in its own colour), a navy/gold AUTO BUY slot. Positions are fractions
-- of the bar, measured from the image's pixels; all text is live.
local ART = {
	Bar = "rbxassetid://140479169859430",
	Off = "rbxassetid://118340677613688", -- 1023 x 682, the button is x 36-987, y 138-543
	On = "rbxassetid://111686894944891",
}
local W, H = 390, 130
local bar = make("ImageLabel", { Name = "AutoRollBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1, Image = ART.Bar, ScaleType = Enum.ScaleType.Fit }, gui)
Style.phoneFit(bar, { scale = 0.62, anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -92) })

local function slot(name: string, cx: number, w: number, h: number): TextButton
	local b = make("TextButton", { Name = name, Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx, 0.495), Size = UDim2.fromScale(w, h),
		BackgroundTransparency = 1, ZIndex = 3 }, bar)
	Style.feedback(b)
	return b
end
local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, max: number, stroke: number?): TextLabel
	local t = make("TextLabel", { Text = text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
		BackgroundTransparency = 1, TextScaled = true, ZIndex = 5 }, parent)
	Style.text(t, stroke or 3)
	make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = max }, t)
	return t
end
-- AUTO ROLL: the blue/green button image in the see-through frame (x 44-394, y 99-241)
local toggle = slot("Toggle", 219 / 1023, 0.345, 0.44)
local face = make("ImageLabel", { Name = "Face", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ART.Off,
	ImageRectOffset = Vector2.new(36, 138), ImageRectSize = Vector2.new(951, 405), ScaleType = Enum.ScaleType.Stretch, ZIndex = 4 }, toggle)
local toggleText = label(toggle, "AUTO ROLL", 0.5, 0.5, 0.84, 0.62, 30, 3)
-- STOP AT: the white slot (x 430-711)
local stopAt = slot("StopAt", 570 / 1023, 0.27, 0.62)
label(stopAt, "STOP AT", 0.5, 0.27, 0.8, 0.26, 16, 2).TextColor3 = Color3.fromRGB(70, 74, 96)
local stopText = label(stopAt, "LEGENDARY+", 0.5, 0.64, 0.9, 0.4, 26, 3)
-- AUTO BUY: the navy / gold slot (x 721-1014)
local buy = slot("AutoBuy", 867 / 1023, 0.27, 0.62)
local buyText = label(buy, "AUTO BUY", 0.5, 0.5, 0.84, 0.62, 22, 3)

local function state()
	return me:GetAttribute("AutoRoll") == true, (me:GetAttribute("AutoRollMin") :: string?) or C.AutoRoll.Default, me:GetAttribute("AutoBuy") == true
end
local function refresh()
	local on, min, buying = state()
	face.Image = if on then ART.On else ART.Off
	toggleText.Text = if on then "AUTO: ON" else "AUTO ROLL" -- (one line: readable on phones)
	stopText.Text = string.upper(min) .. "+"
	local r = C.rarity(min)
	stopText.TextColor3 = if r then r.color else Color3.new(1, 1, 1)
	local owns = Store.hasPass(me, "AutoBuy")
	buyText.Text = if not owns then "🔒 AUTO\nBUY" elseif buying then "AUTO BUY\nON" else "AUTO\nBUY"
	buyText.TextColor3 = if owns and buying then Color3.fromRGB(120, 255, 130) else Color3.new(1, 1, 1)
end
for _, a in { "AutoRoll", "AutoRollMin", "AutoBuy", Store.passAttr("AutoBuy") } do me:GetAttributeChangedSignal(a):Connect(refresh) end
refresh()

toggle.Activated:Connect(function()
	local on, min, buying = state()
	remote:FireServer(not on, min, buying)
end)
stopAt.Activated:Connect(function()
	local on, min, buying = state()
	local list = C.AutoRoll.Choices
	local i = table.find(list, min) or 1
	remote:FireServer(on, list[i % #list + 1], buying)
end)
buy.Activated:Connect(function()
	local on, min, buying = state()
	if not Store.hasPass(me, "AutoBuy") then
		local pass = Store.passByPerk("AutoBuy")
		if pass and pass.gamePassId ~= 0 then
			Net.event("ShopOpened"):FireServer("AutoBuyButton")
			pcall(function() MarketplaceService:PromptGamePassPurchase(me, pass.gamePassId) end)
		end
		return
	end
	remote:FireServer(on, min, not buying)
end)

-- follow the Shop button (hidden during the first tutorial steps)
task.spawn(function()
	while true do
		local shop = me.PlayerGui:FindFirstChild("ShopButton", true)
		local sg = shop and shop:FindFirstAncestorOfClass("ScreenGui")
		gui.Enabled = sg ~= nil and sg.Enabled and (shop :: GuiObject).Visible
		task.wait(1)
	end
end)
