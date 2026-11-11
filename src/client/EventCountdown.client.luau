--!strict
-- 30 Oct: a "next event" line, bottom right (reference: "Next event in 28s").
-- 11 Nov (Willem's 3 reference games; D1 retention): the countdown is always there
-- while no event runs (not only the last 10 minutes), as a clear chip: the event's name
-- on top, the time under it. It turns gold and pulses in the last minute. It shows from
-- the first second in the game (HudReveal), so a new player sees there is something coming.
-- Reads ReplicatedStorage.FactoryEventState (Phase, PhaseEnds, Variant).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Style = require(RS.Shared.Kit.Style)
local E = require(RS.Shared.FactoryEventConfig)

local player = Players.LocalPlayer
local C = Color3.fromRGB

local gui = Instance.new("ScreenGui")
gui.Name = "EventCountdown" gui.ResetOnSpawn = false gui.DisplayOrder = 3
gui.Parent = player:WaitForChild("PlayerGui")

local chip = Instance.new("Frame")
chip.Name = "Countdown" chip.BackgroundColor3 = Color3.new(1, 1, 1) chip.Visible = false chip.Parent = gui
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 10) corner.Parent = chip
local stroke = Instance.new("UIStroke") stroke.Thickness = 3 stroke.Color = Style.Colors.Ink stroke.Parent = chip
local grad = Instance.new("UIGradient") grad.Rotation = 90 grad.Parent = chip
local scale = Instance.new("UIScale") scale.Parent = chip

local function label(name: string, pos: UDim2, size: UDim2, outline: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name l.Position = pos l.Size = size l.BackgroundTransparency = 1 l.TextScaled = true l.Text = ""
	l.Parent = chip
	Style.text(l, outline)
	return l
end
local title = label("Title", UDim2.new(0, 6, 0, 3), UDim2.new(1, -12, 0.46, -3), 2)
local time = label("Time", UDim2.new(0, 6, 0.46, 0), UDim2.new(1, -12, 0.54, -4), 2.5)

local function place()
	if game:GetService("UserInputService").TouchEnabled or Style.compact() then
		-- 1 Nov: on touch screens the jump button sits bottom-right and the hotbar bottom
		-- centre: top right, just under the travel buttons
		chip.AnchorPoint = Vector2.new(1, 0) chip.Position = UDim2.new(1, -10, 0, 100) chip.Size = UDim2.fromOffset(150, 46)
	else
		chip.AnchorPoint = Vector2.new(1, 1) chip.Size = UDim2.fromOffset(200, 58)
		-- 12 Nov: the 2X CASH / pass offers stack sits bottom right on PC: go just above it
		local shop = player.PlayerGui:FindFirstChild("ShopHud")
		local offers = shop and shop:FindFirstChild("Offers") :: GuiObject?
		if offers and offers.Visible and offers.AbsoluteSize.Y > 0 then
			chip.Position = UDim2.new(1, -12, 0, offers.AbsolutePosition.Y - gui.AbsolutePosition.Y - 8)
		else
			chip.Position = UDim2.new(1, -12, 1, -12)
		end
	end
end
place()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)

local function paint(look: any, soon: boolean)
	local a: Color3 = if soon then C(255, 200, 40) else (look.chip or look.accent)
	grad.Color = ColorSequence.new(Style.lighten(a, 0.25), Style.darken(a, 0.35))
	time.TextColor3 = if soon then Color3.new(1, 1, 1) else C(255, 230, 90)
end

local pulse = TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 })
local pulsing = false

local state = RS:WaitForChild("FactoryEventState", 30)
while true do
	if state then
		local phase = state:GetAttribute("Phase")
		local left = ((state:GetAttribute("PhaseEnds") :: number?) or 0) - workspace:GetServerTimeNow()
		local show = phase == "Idle" and left > 0
		chip.Visible = show
		if show then
			place()
			local look = E.variant(state:GetAttribute("Variant") :: string?)
			local s = math.ceil(left)
			local soon = s <= 60
			title.Text = string.upper(look.Boss or "Bear") .. " EVENT"
			time.Text = if s >= 3600 then string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
				else string.format("IN %d:%02d", s // 60, s % 60)
			paint(look, soon)
			if soon ~= pulsing then
				pulsing = soon
				if soon then pulse:Play() else pulse:Cancel() scale.Scale = 1 end
			end
		elseif pulsing then
			pulsing = false pulse:Cancel() scale.Scale = 1
		end
	end
	task.wait(1)
end
