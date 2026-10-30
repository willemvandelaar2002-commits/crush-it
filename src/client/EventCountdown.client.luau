--!strict
-- 30 Oct: a small, quiet "next event" line, bottom right, shown only in the
-- last LeadMinutes before a factory event starts (reference: "Next event in 28s").
-- Reads ReplicatedStorage.FactoryEventState (Phase, PhaseEnds, Variant).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local E = require(RS.Shared.FactoryEventConfig)

local LeadMinutes = 10
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "EventCountdown" gui.ResetOnSpawn = false gui.DisplayOrder = 3
gui.Parent = player:WaitForChild("PlayerGui")
local text = Instance.new("TextLabel")
text.Name = "Countdown" text.AnchorPoint = Vector2.new(1, 1) text.Position = UDim2.new(1, -10, 1, -4)
text.Size = UDim2.fromOffset(300, 20) text.BackgroundTransparency = 1 text.TextSize = 17
text.TextXAlignment = Enum.TextXAlignment.Right text.Visible = false text.Parent = gui
Style.text(text, 1.5)
text.TextTransparency = .1

local state = RS:WaitForChild("FactoryEventState", 30)
while true do
	task.wait(1)
	if not state then continue end
	local phase = state:GetAttribute("Phase")
	local left = ((state:GetAttribute("PhaseEnds") :: number?) or 0) - workspace:GetServerTimeNow()
	local show = phase == "Idle" and left > 0 and left <= LeadMinutes * 60
	text.Visible = show
	if show then
		local look = E.variant(state:GetAttribute("Variant") :: string?)
		local name = if look.pickup then "Halloween event" else "Bear event"
		local s = math.ceil(left)
		text.Text = name .. " in " .. string.format("%d:%02d", s // 60, s % 60)
		text.TextColor3 = if s <= 60 then Color3.fromRGB(255, 225, 110) else Color3.fromRGB(235, 238, 245)
	end
end
