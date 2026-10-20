--!strict
-- First-session tutorial as numbered steps (like the Yuzu game's
-- "Tutorial / Collect Yuzu (0/3)"): big outlined text at the top, a pulsing
-- ring + pointing hand on the button to use, ground arrows (Guide.client)
-- and a "Nice! Next step." pop when a step is done.
--   1. Crush Objects (n/3)          -> CRUSH button
--   2. Pick Up The Scrap            -> the pile (arrows)
--   3. Sell Your Scrap              -> the sell pad of your scrap shop (arrows)
--   4. Buy An Upgrade               -> the Power pad (arrows) / Power row
--   5. Buy A Bigger Press           -> the Bigger Press pad / row
-- Gone for good once the press is bigger than the first one (or after a rebirth).
-- Sets the local player attribute "TutorialStep" (1..5, 0 = done) for Guide.client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer
local hud = player:WaitForChild("PlayerGui"):WaitForChild("CrushHud")
local crushButton = hud:WaitForChild("CrushButton") :: GuiObject
local upgrades = hud:WaitForChild("Upgrades")
local powerCard = upgrades:WaitForChild("Card_Power") :: GuiObject
local sizeCard = upgrades:WaitForChild("Card_Size") :: GuiObject

local gui = Instance.new("ScreenGui")
gui.Name = "Onboarding"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- "Tutorial" + the step, under the goal bar
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, if touch then 190 else 160)
holder.Size = UDim2.fromOffset(if touch then 340 else 560, if touch then 64 else 92)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui
local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.42)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Text = "Tutorial"
title.Parent = holder
Style.text(title, 3)
title.TextColor3 = Color3.new(1, 1, 1)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(110, 200, 255), Color3.fromRGB(40, 110, 255))
grad.Rotation = 90
grad.Parent = title
local stepText = Instance.new("TextLabel")
stepText.Position = UDim2.fromScale(0, 0.4)
stepText.Size = UDim2.fromScale(1, 0.6)
stepText.BackgroundTransparency = 1
stepText.TextScaled = true
stepText.Parent = holder
Style.text(stepText, 4)

-- "Nice! Next step." pop
local nice = Instance.new("TextLabel")
nice.AnchorPoint = Vector2.new(0.5, 0.5)
nice.Position = UDim2.fromScale(0.5, 0.62)
nice.Size = UDim2.fromOffset(420, 46)
nice.BackgroundTransparency = 1
nice.TextScaled = true
nice.Text = "Nice! Next step."
nice.Visible = false
nice.Parent = gui
Style.text(nice, 3)
local niceScale = Instance.new("UIScale")
niceScale.Parent = nice

local ring = Instance.new("Frame")
ring.BackgroundTransparency = 1
ring.Visible = false
ring.Parent = gui
local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.fromRGB(255, 220, 60)
ringStroke.Thickness = 4
ringStroke.Parent = ring
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(0, 12)
ringCorner.Parent = ring

local hand = Instance.new("TextLabel")
hand.BackgroundTransparency = 1
hand.Font = Enum.Font.FredokaOne
hand.TextScaled = true
hand.Text = "👉"
hand.Size = UDim2.fromOffset(60, 60)
hand.Visible = false
hand.Parent = gui

local function attr(name: string): number
	return (player:GetAttribute(name) :: number?) or 0
end

local function anyLevel(): boolean
	return attr("PowerLv") + attr("SpeedLv") + attr("ValueLv") > 0
end

local sold = false
Net.event("ScrapSold").OnClientEvent:Connect(function(msg)
	if msg.owner == player then
		sold = true
	end
end)

-- (step number, text, ui target, hand side)
local function current(): (number, string?, GuiObject?, string?)
	if attr("Tier") > 1 or attr("Rebirths") > 0 then
		return 0
	end
	local crushed = attr("Crushed")
	if crushed < 3 and not anyLevel() then
		local keys = if UserInputService.KeyboardEnabled then " (hold F)" else ""
		return 1, string.format("Crush Objects (%d/3)%s", crushed, keys), crushButton, "left"
	end
	if anyLevel() then
		return 5, "Buy A Bigger Press (0/1)", sizeCard, "right"
	end
	if not sold and attr("Cash") <= 0 then
		if attr("Scrap") > 0 then
			return 3, "Sell Your Scrap (0/1)"
		end
		return 2, "Pick Up The Scrap (0/1)"
	end
	return 4, "Buy An Upgrade (0/1)", powerCard, "right"
end

local lastStep = -1
local lastTarget: GuiObject? = nil

local function celebrate()
	nice.Visible = true
	niceScale.Scale = 0.3
	nice.TextColor3 = Color3.fromRGB(255, 240, 120)
	TweenService:Create(niceScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. Config.Sounds.LevelUp
	s.Volume = 0.4
	s.PlaybackSpeed = 1.3
	s.Parent = gui
	s:Play()
	task.delay(1.6, function()
		nice.Visible = false
		s:Destroy()
	end)
end

RunService.RenderStepped:Connect(function()
	local step, text, el, side = current()
	player:SetAttribute("TutorialStep", step)
	if step ~= lastStep then
		if lastStep > 0 then
			celebrate()
		end
		lastStep = step
	end
	if step == 0 then
		holder.Visible = false
		ring.Visible = false
		hand.Visible = false
		return
	end
	local hidden = Style.hasModal()
	holder.Visible = not hidden
	stepText.Text = text or ""
	if hidden or not el or not el.Visible then
		ring.Visible = false
		hand.Visible = false
		return
	end
	-- steps 4/5: only point at the HUD once it's affordable (the pads are the other way)
	if step == 4 and attr("Cash") < Config.Upgrades[1].cost(0) or step == 5 and attr("Cash") < Config.SizeCost(1) then
		ring.Visible = false
		hand.Visible = false
		return
	end
	if el ~= lastTarget and upgrades:IsA("ScrollingFrame") and el:IsDescendantOf(upgrades) then
		local scale = upgrades:FindFirstChildOfClass("UIScale")
		local zoom = if scale then scale.Scale else 1
		upgrades.CanvasPosition = Vector2.new(0, math.max(0, upgrades.CanvasPosition.Y + (el.AbsolutePosition.Y - upgrades.AbsolutePosition.Y) / zoom - 6))
	end
	lastTarget = el
	local pos, size = el.AbsolutePosition, el.AbsoluteSize
	local pulse = 1 + math.sin(os.clock() * 6) * 0.04
	local w, h = size.X * pulse + 12, size.Y * pulse + 12
	ring.Position = UDim2.fromOffset(pos.X + size.X / 2 - w / 2, pos.Y + size.Y / 2 - h / 2)
	ring.Size = UDim2.fromOffset(w, h)
	ringCorner.CornerRadius = if el == crushButton then UDim.new(1, 0) else UDim.new(0, 12)
	ring.Visible = true
	local bob = math.sin(os.clock() * 7) * 8
	if side == "left" then
		hand.Text = "👉"
		hand.Position = UDim2.fromOffset(pos.X - 70 + bob, pos.Y + size.Y / 2 - 30)
	else
		hand.Text = "👈"
		hand.Position = UDim2.fromOffset(pos.X + size.X + 10 - bob, pos.Y + size.Y / 2 - 30)
	end
	hand.Visible = true
end)
