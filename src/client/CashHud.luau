--!strict
-- Bottom-left cash (Destroy a Vault style) with the friend boost line under it.
-- Shared by the collectible-crusher HUD; reads the player's Cash and
-- FriendBoost attributes only. Same look as the classic HUD in Main.client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Format = require(ReplicatedStorage.Shared.Format)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)

local CashHud = {}

function CashHud.start(gui: ScreenGui)
	local player = Players.LocalPlayer
	local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local height = if TOUCH then 40 else 64
	local function make(class: string, props: { [string]: any }, parent: Instance?): any
		local v = Instance.new(class)
		for k, x in props do (v :: any)[k] = x end
		v.Parent = parent
		return v
	end
	local cashLabel = make("TextLabel", {
		Name = "Cash", AnchorPoint = if TOUCH then Vector2.new(0.5, 0) else Vector2.new(0, 1),
		Position = if TOUCH then UDim2.new(0.5, 0, 0, 74) else UDim2.new(0, 84, 1, -42),
		Size = UDim2.fromOffset(if TOUCH then 180 else 320, height), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne,
		TextScaled = true, TextXAlignment = if TOUCH then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(110, 255, 90), Text = "$0",
	}, gui)
	make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(20, 40, 15) }, cashLabel)
	if not TOUCH then
		local icon = make("Frame", { Name = "CashIcon", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -40),
			Size = UDim2.fromOffset(66, 66), BackgroundTransparency = 1, Rotation = -10 }, gui)
		Style.image(icon, Icons.Cash)
	end

	-- Friend boost line; the + opens Roblox's invite dialog.
	local row = make("Frame", { Name = "FriendBoost", AnchorPoint = Vector2.new(0, 1),
		Position = if TOUCH then UDim2.new(0.5, -96, 0, 145) else UDim2.new(0, 14, 1, -10),
		Size = UDim2.fromOffset(if TOUCH then 192 else 260, if TOUCH then 26 else 30), BackgroundTransparency = 1 }, gui)
	local label = make("TextLabel", { Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "Friend Boost: 0%" }, row)
	Style.text(label, 2.5)
	local invite = make("TextButton", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(if TOUCH then 24 else 30, if TOUCH then 24 else 30), Text = "+", TextScaled = true }, row)
	Style.button(invite)
	local function refreshFriends()
		local boost = (player:GetAttribute("FriendBoost") :: number?) or 0
		label.Text = string.format("Friend Boost: %d%%", math.floor(boost * 100 + 0.5))
		label.TextColor3 = if boost > 0 then Color3.fromRGB(120, 255, 120) else Color3.new(1, 1, 1)
		invite.Position = UDim2.new(0, label.TextBounds.X + 8, 0.5, 0)
	end
	player:GetAttributeChangedSignal("FriendBoost"):Connect(refreshFriends)
	label:GetPropertyChangedSignal("TextBounds"):Connect(refreshFriends)
	refreshFriends()
	invite.Activated:Connect(function()
		local social = game:GetService("SocialService")
		local ok, can = pcall(function() return social:CanSendGameInviteAsync(player) end)
		if ok and can then pcall(function() social:PromptGameInvite(player) end) end
	end)

	-- Smooth count-up on gains, instant on spends, plus a short "+$X" pop.
	local shown = make("NumberValue", { Value = (player:GetAttribute("Cash") :: number?) or 0 }, gui)
	shown.Changed:Connect(function(v) cashLabel.Text = Format.cash(math.floor(v + 0.5)) end)
	cashLabel.Text = Format.cash(shown.Value)
	local pop = make("TextLabel", { Name = "CashGain", AnchorPoint = if TOUCH then Vector2.new(1, 0.5) else Vector2.new(0, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0), Size = UDim2.fromOffset(if TOUCH then 72 else 160, if TOUCH then 22 else 28),
		BackgroundTransparency = 1, TextScaled = true, Text = "", Visible = false, ZIndex = 3 }, cashLabel)
	Style.text(pop, 2)
	pop.TextColor3 = Color3.fromRGB(169, 255, 117)
	local last = shown.Value
	local tween: Tween? = nil
	local token = 0
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		local cash = (player:GetAttribute("Cash") :: number?) or 0
		if tween then tween:Cancel() end
		if cash > last then
			local t = TweenService:Create(shown, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Value = cash })
			tween = t
			t:Play()
			token += 1
			local mine = token
			pop.Text = "+" .. Format.cash(cash - last)
			if not TOUCH then pop.Position = UDim2.new(0, Format.cash(cash):len() * height * 0.5 + 12, 0.5, 0) end
			pop.Visible = true
			task.delay(0.9, function() if mine == token then pop.Visible = false end end)
		else
			shown.Value = cash
		end
		last = cash
	end)
end

return CashHud
