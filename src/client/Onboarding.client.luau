--!strict
-- First-session guide: a pulsing frame around what to press next plus a hint.
--   1. never crushed            -> CRUSH button  "Hold CRUSH (or F)!"
--   2. no upgrades yet          -> Power card     "Buy An Upgrade"  (once affordable)
--   3. still on the first press -> Bigger Press   "Buy A Bigger Press"      (once affordable)
-- Gone for good once the press is bigger than the first one (or after a rebirth).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

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
gui.Parent = player.PlayerGui

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

-- Big banner across the top ("Buy An Upgrade") like Destroy a Vault.
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 132)
banner.Size = UDim2.new(0.6, 0, 0, 64)
banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
banner.BackgroundTransparency = 0.45
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
local bannerGrad = Instance.new("UIGradient")
bannerGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1),
})
bannerGrad.Parent = banner
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.FredokaOne
hint.TextScaled = true
hint.TextColor3 = Color3.new(1, 1, 1)
hint.Size = UDim2.fromScale(1, 0.8)
hint.Position = UDim2.fromScale(0, 0.1)
hint.Parent = banner
local hintStroke = Instance.new("UIStroke")
hintStroke.Thickness = 3
hintStroke.Parent = hint

-- A pointing hand next to the thing to press.
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

-- Which element to point at right now (nil = nothing).
local function target(): (GuiObject?, string?, string?)
	if attr("Tier") > 1 or attr("Rebirths") > 0 then
		return nil, nil, "done"
	end
	if attr("Crushed") == 0 then
		local keys = if UserInputService.KeyboardEnabled then "Hold CRUSH (or F)" else "Hold CRUSH"
		return crushButton, keys, "left"
	end
	local cash = attr("Cash")
	if not anyLevel() then
		if cash >= Config.Upgrades[1].cost(0) then
			return powerCard, "Buy An Upgrade", "right"
		end
		return nil
	end
	if cash >= Config.SizeCost(1) then
		return sizeCard, "Buy A Bigger Press", "right"
	end
	return nil
end

local finished = false

RunService.RenderStepped:Connect(function()
	if finished then
		return
	end
	local el, text, side = target()
	if side == "done" then
		finished = true
		gui:Destroy()
		return
	end
	if not el or not el.Visible then
		ring.Visible = false
		banner.Visible = false
		hand.Visible = false
		return
	end
	-- Element positions are in the HUD's space (below the top bar); ours too
	-- since both ScreenGuis keep the inset, so AbsolutePosition lines up.
	local pos, size = el.AbsolutePosition, el.AbsoluteSize
	local pulse = 1 + math.sin(os.clock() * 6) * 0.04
	local w, h = size.X * pulse + 12, size.Y * pulse + 12
	ring.Position = UDim2.fromOffset(pos.X + size.X / 2 - w / 2, pos.Y + size.Y / 2 - h / 2)
	ring.Size = UDim2.fromOffset(w, h)
	ringCorner.CornerRadius = if el == crushButton then UDim.new(1, 0) else UDim.new(0, 12)
	ring.Visible = true
	hint.Text = text or ""
	banner.Visible = true
	local bob = math.sin(os.clock() * 7) * 8
	if side == "left" then
		-- hand to the left of the target, pointing right
		hand.Text = "👉"
		hand.Position = UDim2.fromOffset(pos.X - 70 + bob, pos.Y + size.Y / 2 - 30)
	else
		-- hand to the right of the target, pointing left
		hand.Text = "👈"
		hand.Position = UDim2.fromOffset(pos.X + size.X + 10 - bob, pos.Y + size.Y / 2 - 30)
	end
	hand.Visible = true
end)
