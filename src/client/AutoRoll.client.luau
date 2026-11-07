--!strict
-- 7 Nov (Willem): the AUTO ROLL bar, bottom middle above the crusher hotbar (phones
-- too, smaller). Three buttons:
--   AUTO ROLL  on / off (free, after the tutorial; server/AutoRoll does the rolling)
--   STOP AT    tap to cycle the rarity it stops on (C.AutoRoll.Choices), in its colour
--   AUTO BUY   with the pass: buy what it stops for and keep going; without the pass
--              it shows a lock and opens the pass purchase (once the pass exists)
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
local INK = Style.Colors.Ink
local function rgb(r: number, g: number, b: number) return Color3.fromRGB(r, g, b) end
local GREEN, GREY, CYAN = rgb(60, 200, 80), rgb(110, 116, 140), rgb(60, 170, 235)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end

local gui = make("ScreenGui", { Name = "AutoRollHud", ResetOnSpawn = false, DisplayOrder = 3, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local W, H = 420, 54
local bar = make("Frame", { Name = "AutoRollBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -164), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1 }, gui)
Style.phoneFit(bar, { scale = 0.62, anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -100) })

local function button(name: string, x: number, w: number, color: Color3): (TextButton, TextLabel)
	local b = make("TextButton", { Name = name, Text = "", Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, H) }, bar)
	Style.button(b, color)
	local t = make("TextLabel", { Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -12), BackgroundTransparency = 1, TextScaled = true, ZIndex = 4 }, b)
	Style.text(t, 3)
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 24 }, t)
	return b, t
end
local toggle, toggleText = button("Toggle", 0, 150, GREY)
local stopAt, stopText = button("StopAt", 158, 150, GREY)
local buy, buyText = button("AutoBuy", 316, 104, GREY)

local function state()
	return me:GetAttribute("AutoRoll") == true, (me:GetAttribute("AutoRollMin") :: string?) or C.AutoRoll.Default, me:GetAttribute("AutoBuy") == true
end
local function refresh()
	local on, min, buying = state()
	toggleText.Text = if on then "AUTO ROLL: ON" else "AUTO ROLL"
	Style.setButtonColor(toggle, if on then GREEN else GREY)
	stopText.Text = "STOP AT: " .. string.upper(min) .. "+"
	local r = C.rarity(min)
	Style.setButtonColor(stopAt, if r then r.color:Lerp(INK, 0.15) else GREY)
	local owns = Store.hasPass(me, "AutoBuy")
	buyText.Text = if not owns then "🔒 AUTO BUY" elseif buying then "AUTO BUY: ON" else "AUTO BUY"
	Style.setButtonColor(buy, if owns and buying then CYAN else GREY)
	-- no pass yet (id 0): the AUTO BUY button waits
	local pass = Store.passByPerk("AutoBuy")
	buy.Visible = owns or (pass ~= nil and pass.gamePassId ~= 0)
	bar.Size = UDim2.fromOffset(if buy.Visible then W else 308, H)
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
