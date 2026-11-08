--!strict
-- 8 Nov (Willem: "your factory keeps running" + "something that finishes overnight";
-- Shared/CrateConfig, server/OvernightCrate):
--   * Crate signs: every MysteryCrate model shows "MYSTERY CRATE" and its countdown, or
--     "READY! OPEN ME" (bouncing) once it can be opened.
--   * Cards (Willem's come-back frame, bottom middle, never blocking):
--       - the crate ARRIVED (after the tutorial): opens in 8 hours, come back
--       - the crate OPENED: what you got, next one in 20 hours
--       - AWAY card, once per session after CrateConfig.Away.AfterMinutes of play: your
--         factory keeps earning while you're away (Store.Offline) + when the crate opens
--     REMIND ME (Roblox's notification opt-in) shows when Roblox lets us ask.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Tags = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local N = require(RS.Shared.NotifyConfig)
local K = require(RS.Shared.CrateConfig)
local Store = require(RS.Shared.Store)
local Format = require(RS.Shared.Format)
local C2 = require(RS.Shared.CrusherConfig)

local me = Players.LocalPlayer
local rgb = Color3.fromRGB

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
	make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = max }, l)
	return l
end
local function timeLeft(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h, m = seconds // 3600, (seconds % 3600) // 60
	if h > 0 then return string.format("%dh %dm", h, m) end
	return string.format("%dm %ds", m, seconds % 60)
end

-- crate signs ------------------------------------------------------------------------
local function sign(model: Instance)
	local body = model:WaitForChild("Body", 10)
	local bb = body and body:WaitForChild("Sign", 10) :: BillboardGui?
	if not bb then return end
	local title = words(bb, "MYSTERY CRATE", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.48), 2, 30, rgb(255, 215, 80))
	local timer = words(bb, "", UDim2.fromScale(0, 0.5), UDim2.fromScale(1, 0.46), 2, 28)
	local mine = model:GetAttribute("Owner") == me.UserId
	if not mine then title.Text = tostring(model:GetAttribute("OwnerName")) .. "'s CRATE" end
	task.spawn(function()
		while model.Parent do
			local at = tonumber(model:GetAttribute("ReadyAt"))
			if at then
				local left = at - Workspace:GetServerTimeNow()
				if left <= 0 then
					timer.Text = if mine then "READY! OPEN ME" else "READY!"
					timer.TextColor3 = rgb(110, 255, 120)
					bb.StudsOffsetWorldSpace = Vector3.new(0, 4.8 + math.abs(math.sin(os.clock() * 3)) * 0.6, 0)
				else
					timer.Text = "Opens in " .. timeLeft(left)
					timer.TextColor3 = Color3.new(1, 1, 1)
				end
			end
			task.wait(if at and at - Workspace:GetServerTimeNow() <= 0 then 0.05 else 1)
		end
	end)
end
for _, m in Tags:GetTagged("MysteryCrate") do task.spawn(sign, m) end
Tags:GetInstanceAddedSignal("MysteryCrate"):Connect(function(m) task.spawn(sign, m) end)

-- the card ---------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "CrateHud", ResetOnSpawn = false, DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local ART = { Frame = "rbxassetid://133183009079484" } -- Willem's come-back frame (4 Nov)
local card = make("Frame", { Name = "CrateCard", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(460, 178),
	BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
make("ImageLabel", { Name = "Frame", Image = ART.Frame, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 2 }, card)
local icon = words(card, "🎁", UDim2.fromOffset(22, 30), UDim2.fromOffset(118, 118), 3, 90)
local fit = Style.phoneFit(card, { scale = 0.8, width = 0.7 })
local pop = make("UIScale", { Scale = 1 }, card)
fit.Parent = nil -- (read only: one UIScale per object)
local title = words(card, "", UDim2.fromOffset(150, 14), UDim2.fromOffset(292, 30), 3, 28, rgb(120, 220, 255))
local line1 = words(card, "", UDim2.fromOffset(150, 46), UDim2.fromOffset(292, 32), 3, 26)
local line2 = words(card, "", UDim2.fromOffset(150, 78), UDim2.fromOffset(292, 24), 3, 20, rgb(255, 225, 120))
local function button(text: string, x: number, w: number, color: Color3): TextButton
	local b = make("TextButton", { Text = "", Position = UDim2.fromOffset(x, 112), Size = UDim2.fromOffset(w, 50), ZIndex = 3 }, card)
	Style.button(b, color)
	words(b, text, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 4, 28)
	return b
end
local remind = button("REMIND ME", 150, 160, rgb(60, 200, 80))
local ok = button("OK", 318, 110, rgb(64, 140, 255))
task.spawn(function()
	while true do
		if card.Visible then icon.Rotation = math.sin(os.clock() * 2) * 6 end
		task.wait()
	end
end)

local function canPrompt(): boolean
	if N.DailyReady == "" then return false end
	local okCall, can = pcall(function() return ExperienceNotificationService:CanPromptOptInAsync() end)
	return okCall and can == true
end
local token = 0
local function hide()
	token += 1
	if not card.Visible then return end
	local t = TweenService:Create(pop, TweenInfo.new(0.15), { Scale = 0.8 * fit.Scale })
	t:Play()
	t.Completed:Once(function() card.Visible = false end)
end
local function show(emoji: string, head: string, a: string, b: string, ask: boolean)
	-- (wait while another window or the come-back card is up)
	local come = me.PlayerGui:FindFirstChild("ComeBackHud")
	for _ = 1, 60 do
		local busy = Style.hasModal() or (come ~= nil and (come:FindFirstChild("ComeBack") :: GuiObject?) ~= nil and (come:FindFirstChild("ComeBack") :: GuiObject).Visible)
		if not busy then break end
		task.wait(1)
	end
	ask = ask and canPrompt()
	icon.Text = emoji title.Text = head line1.Text = a line2.Text = b
	remind.Visible = ask
	ok.Position = if ask then UDim2.fromOffset(318, 112) else UDim2.fromOffset(240, 112)
	card.Visible = true
	pop.Scale = 0.7 * fit.Scale
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = fit.Scale }):Play()
	token += 1
	local mine = token
	task.delay(if ask then K.Away.Seconds * 2 else K.Away.Seconds, function() if token == mine then hide() end end)
end
ok.Activated:Connect(hide)
remind.Activated:Connect(function()
	hide()
	pcall(function() ExperienceNotificationService:PromptOptIn() end)
end)

Net.event("Crate").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" then return end
	if msg.arrived then
		task.delay(4, function() -- after the tutorial's own celebration
			show("🎁", "A MYSTERY CRATE ARRIVED!", "It opens in " .. K.FirstHours .. " hours", "Free crusher inside, up to LEGENDARY!", true)
		end)
	elseif type(msg.opened) == "table" then
		local o = msg.opened
		show("🎉", "MYSTERY CRATE OPENED!", tostring(o.name) .. " (" .. tostring(o.rarity) .. ")", "+" .. tostring(o.cash) .. "  ·  next crate in " .. K.Hours .. "h", false)
	end
end)

-- the away card: once per session, after a while of play ---------------------------
task.spawn(function()
	local joined = os.clock()
	while os.clock() - joined < K.Away.AfterMinutes * 60 do task.wait(5) end
	-- only after the tutorial (the crate exists then)
	while me:GetAttribute("CrateReadyAt") == nil do task.wait(5) end
	while Style.hasModal() or me:GetAttribute("CutscenePlaying") == true do task.wait(2) end
	local rate = tonumber(me:GetAttribute("CashRate")) or 0
	local hours = if Store.hasPass(me, "VIP") then Store.Vip.OfflineHours else Store.Offline.MaxHours
	local most = C2.money(rate * Store.Offline.Share * hours * 3600)
	local at = tonumber(me:GetAttribute("CrateReadyAt")) or 0
	local left = at - Workspace:GetServerTimeNow()
	local crateLine = if left > 0 then "Mystery Crate opens in " .. timeLeft(left) else "Your Mystery Crate is READY to open!"
	show("🏭", "YOUR FACTORY NEVER STOPS", "Earns up to " .. Format.cash(most) .. " while you're away", crateLine, true)
end)
