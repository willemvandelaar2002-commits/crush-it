--!strict
-- 4 Nov (vault: Retention and Return Hooks "a timer that resolves tomorrow" is the D1
-- hook; Experience Notifications "show your own one-line context before the opt-in").
-- Right after today's daily reward is claimed, a small card shows what tomorrow gives:
--   COME BACK TOMORROW
--   Day 4: FREE RARE CRUSHER
--   [ REMIND ME ]  [ OK ]
-- REMIND ME only shows when Roblox lets us ask (13+, not opted in yet, not asked in the
-- last 30 days); it opens Roblox's own notification prompt. Nothing depends on saying
-- yes. Once per session.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local N = require(RS.Shared.NotifyConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, z: number, max: number, color: Color3?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = z }, parent)
	Style.text(l, 2.5)
	l.TextColor3 = color or Color3.new(1, 1, 1)
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = max }, l)
	return l
end

local gui = make("ScreenGui", { Name = "ComeBackHud", ResetOnSpawn = false, DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local card = make("Frame", { Name = "ComeBack", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(420, 164),
	BackgroundColor3 = C(52, 44, 140), Visible = false, ZIndex = 2 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 18) }, card)
make("UIStroke", { Thickness = 4, Color = INK }, card)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(76, 66, 190), C(40, 32, 120)) }, card)
local fit = Style.phoneFit(card, { scale = 0.8, width = 0.7 })
local pop = make("UIScale", { Scale = 1 }, card)
-- (phoneFit's UIScale is read, not parented: one UIScale per object)
fit.Parent = nil
words(card, "COME BACK TOMORROW", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 30), 3, 30, C(120, 220, 255))
local what = words(card, "", UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 40), 3, 38)
local function button(text: string, x: number, w: number, color: Color3): TextButton
	local b = make("TextButton", { Text = "", Position = UDim2.fromOffset(x, 96), Size = UDim2.fromOffset(w, 52), ZIndex = 3 }, card)
	Style.button(b, color)
	words(b, text, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 4, 30)
	return b
end
local remind = button("REMIND ME", 16, 236, C(60, 200, 80))
local ok = button("OK", 264, 140, C(64, 140, 255))

local function canPrompt(): boolean
	if N.DailyReady == "" then return false end -- no notification to send yet: don't ask
	local okCall, can = pcall(function() return ExperienceNotificationService:CanPromptOptInAsync() end)
	return okCall and can == true
end

local shown = false
local token = 0
local function hide()
	token += 1
	if not card.Visible then return end
	local t = TweenService:Create(pop, TweenInfo.new(0.15), { Scale = 0.8 * fit.Scale })
	t:Play()
	t.Completed:Once(function() card.Visible = false end)
end
local function show(day: number, text: string)
	if shown then return end
	shown = true
	local ask = canPrompt()
	what.Text = "Day " .. day .. ": " .. text
	remind.Visible = ask
	ok.Position = if ask then UDim2.fromOffset(264, 96) else UDim2.fromOffset(140, 96)
	card.Visible = true
	pop.Scale = 0.7 * fit.Scale
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = fit.Scale }):Play()
	token += 1
	local mine = token
	-- without a question it goes away by itself
	if not ask then task.delay(7, function() if token == mine then hide() end end) end
end
ok.Activated:Connect(hide)
remind.Activated:Connect(function()
	hide()
	pcall(function() ExperienceNotificationService:PromptOptIn() end)
end)

local before: any = nil
Net.event("Rewards").OnClientEvent:Connect(function(s: any)
	if type(s) ~= "table" or type(s.daily) ~= "table" then return end
	local d0 = before and before.daily
	before = s
	-- just claimed: was claimable, now it isn't
	if d0 and d0.canClaim and not s.daily.canClaim and type(s.daily.tomorrow) == "string" then
		local day, text = s.daily.tomorrowDay, s.daily.tomorrow
		task.delay(2.6, function() show(day, text) end) -- after the claim celebration
	end
end)
