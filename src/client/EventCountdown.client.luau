--!strict
-- 30 Oct: a "next event" line, bottom right (reference: "Next event in 28s").
-- 11 Nov (Willem's 3 reference games; D1 retention): the countdown is always there while
-- no event runs (not only the last 10 minutes), from the first second in the game.
-- 12 Nov (Willem, a reference game's phone screen: less blocking the screen): a small tile
-- in the timer row (BoostsHud.ActiveBoosts, Style.timerTile), first in the row: the event's
-- animal (🐻 / 🎃) on its colour, "EVENT" in the corner, the time under it. It turns gold
-- and pulses in the last minute.
-- Reads ReplicatedStorage.FactoryEventState (Phase, PhaseEnds, Variant).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Style = require(RS.Shared.Kit.Style)
local E = require(RS.Shared.FactoryEventConfig)

local player = Players.LocalPlayer
local C = Color3.fromRGB
local EMOJI = { Bear = "🐻", Pumpkin = "🎃" }

local holder = Instance.new("Folder") -- (keeps the tile until the timer row exists)
local tile, time, badge = Style.timerTile(holder, "EventTile", C(150, 70, 235), "", "EVENT", -10)
local square = tile:FindFirstChild("Square") :: Frame
local grad = square:FindFirstChildOfClass("UIGradient") :: UIGradient
local animal = Instance.new("TextLabel")
animal.Name = "Animal" animal.BackgroundTransparency = 1 animal.TextScaled = true animal.Text = "🐻"
animal.AnchorPoint = Vector2.new(0.5, 0.5) animal.Position = UDim2.fromScale(0.5, 0.52) animal.Size = UDim2.fromScale(0.78, 0.78) animal.ZIndex = 2
animal.Parent = square
local scale = Instance.new("UIScale") scale.Parent = square
badge.Size = UDim2.fromOffset(44, 18)

local function home()
	if tile.Parent and tile.Parent:IsA("GuiObject") then return end
	local row = player:WaitForChild("PlayerGui"):FindFirstChild("ActiveBoosts", true)
	if row then tile.Parent = row end
end

local function paint(look: any, soon: boolean)
	local a: Color3 = if soon then C(255, 200, 40) else (look.chip or look.accent)
	square.BackgroundColor3 = a
	grad.Color = ColorSequence.new(Style.lighten(a, 0.2), Style.darken(a, 0.3))
	time.TextColor3 = if soon then C(255, 230, 90) else Color3.new(1, 1, 1)
end

local pulse = TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 })
local pulsing = false

local state = RS:WaitForChild("FactoryEventState", 30)
while true do
	home()
	if state then
		local phase = state:GetAttribute("Phase")
		local left = ((state:GetAttribute("PhaseEnds") :: number?) or 0) - workspace:GetServerTimeNow()
		local show = phase == "Idle" and left > 0
		tile.Visible = show
		if show then
			local look = E.variant(state:GetAttribute("Variant") :: string?)
			local s = math.ceil(left)
			local soon = s <= 60
			animal.Text = EMOJI[look.Boss or "Bear"] or "🐻"
			time.Text = if s >= 3600 then string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60) else string.format("%d:%02d", s // 60, s % 60)
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
