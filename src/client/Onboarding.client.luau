--!strict
-- First-session guide: a pulsing frame around what to press next plus a hint.
--   1. never crushed            -> CRUSH button  "Hold CRUSH (or F)!"
--   (not enough cash yet)       -> banner "Pick Up The Scrap!" / "Sell Your Scrap At The Shop!"
--   2. no upgrades yet          -> Power card     "Buy An Upgrade"  (once affordable)
--   3. still on the first press -> Bigger Press   "Buy A Bigger Press"      (once affordable)
-- Gone for good once the press is bigger than the first one (or after a rebirth).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
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
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
banner.Position = UDim2.new(0.5, 0, 0, if touch then 205 else 178)
banner.Size = UDim2.new(if touch then 0.55 else 0.36, 0, 0, if touch then 36 else 48)
banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
banner.BackgroundTransparency = 0.45
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
Style.panel(banner, Color3.fromRGB(78, 163, 250), Color3.fromRGB(40, 78, 170))
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.FredokaOne
hint.TextScaled = true
hint.TextColor3 = Color3.new(1, 1, 1)
hint.Size = UDim2.fromScale(1, 0.8)
hint.Position = UDim2.fromScale(0, 0.1)
hint.Parent = banner
Style.text(hint, 2.5)

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
	local need = if anyLevel() then Config.SizeCost(1) else Config.Upgrades[1].cost(0)
	if cash < need then
		-- scrap steps (banner only; the ground arrows point the way)
		if attr("Scrap") > 0 then
			return nil, "Sell Your Scrap At The Shop!", "banner"
		end
		local plots = workspace:FindFirstChild("Plots")
		local plot = plots and plots:FindFirstChild("Plot" .. tostring(player:GetAttribute("Plot")))
		local pieces = plot and plot:FindFirstChild("Scrap")
		if pieces and #pieces:GetChildren() > 0 then
			return nil, "Pick Up The Scrap!", "banner"
		end
		return nil
	end
	if not anyLevel() then
		return powerCard, "Buy An Upgrade", "right"
	end
	return sizeCard, "Buy A Bigger Press", "right"
end

local finished = false
local lastTarget: GuiObject? = nil

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
	if side == "banner" and text and not Style.hasModal() and hud:GetAttribute("NoticeActive") ~= true then
		ring.Visible = false
		hand.Visible = false
		hint.Text = text
		banner.Visible = true
		return
	end
	if not el or not el.Visible or Style.hasModal() or hud:GetAttribute("NoticeActive") == true then
		ring.Visible = false
		banner.Visible = false
		hand.Visible = false
		return
	end
	if el ~= lastTarget and upgrades:IsA("ScrollingFrame") and el:IsDescendantOf(upgrades) then
		local scale = upgrades:FindFirstChildOfClass("UIScale")
		local zoom = if scale then scale.Scale else 1
		upgrades.CanvasPosition = Vector2.new(0, math.max(0, upgrades.CanvasPosition.Y + (el.AbsolutePosition.Y - upgrades.AbsolutePosition.Y) / zoom - 6))
	end
	lastTarget = el
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
