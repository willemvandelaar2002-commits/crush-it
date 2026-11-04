--!strict
-- 4 Nov: the LUCKY WEEKEND pill (Shared/WeekendConfig), top right under the travel
-- buttons. During the weekend: "LUCKY WEEKEND · 2x LUCK · 1d 4h left" (gold, gently
-- pulsing). From Friday: "LUCKY WEEKEND in 9h 20m" (quieter). Hidden on other days and
-- during the tutorial (HudReveal). Uses the server clock.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Style = require(RS.Shared.Kit.Style)
local W = require(RS.Shared.WeekendConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink

local gui = Instance.new("ScreenGui")
gui.Name = "WeekendHud" gui.ResetOnSpawn = false gui.DisplayOrder = 3 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = me:WaitForChild("PlayerGui")
-- 4 Nov: Willem's art: Weekend-Upcoming (purple) / Weekend-Active (gold) banners
-- (1018 x 129) with the Lucky-Clover (512 x 512) on the left end
local ART = { Upcoming = "rbxassetid://70823757255724", Active = "rbxassetid://139379552120006", Clover = "rbxassetid://92298197015475" }
-- one banner pill (art + clover + text); the weekend one and (4 Nov) the Server Luck one
local function newPill(name: string): (Frame, ImageLabel, ImageLabel, TextLabel, UIScale, UIScale?)
	local f = Instance.new("Frame")
	f.Name = name f.AnchorPoint = Vector2.new(1, 0) f.Position = UDim2.new(1, -10, 0, 64)
	f.Size = UDim2.fromOffset(316, 40) f.BackgroundTransparency = 1 f.Visible = false f.Parent = gui
	local art = Instance.new("ImageLabel")
	art.Name = "Banner" art.BackgroundTransparency = 1 art.Size = UDim2.fromScale(1, 1) art.ScaleType = Enum.ScaleType.Stretch
	art.Image = ART.Upcoming art.Parent = f
	local leaf = Instance.new("ImageLabel")
	leaf.Name = "Clover" leaf.BackgroundTransparency = 1 leaf.Image = ART.Clover leaf.ScaleType = Enum.ScaleType.Fit
	leaf.AnchorPoint = Vector2.new(0.5, 0.5) leaf.Position = UDim2.new(0, 6, 0.5, 0) leaf.Size = UDim2.fromOffset(54, 54) leaf.ZIndex = 3
	leaf.Parent = f
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1 t.TextScaled = true t.Position = UDim2.new(0, 38, 0.18, 0) t.Size = UDim2.new(1, -56, 0.64, 0)
	t.ZIndex = 2 t.Parent = f
	Style.text(t, 2)
	local c = Instance.new("UITextSizeConstraint") c.MinTextSize = 12 c.MaxTextSize = 22 c.Parent = t
	local sc = Instance.new("UIScale") sc.Parent = f
	Style.phoneFit(f, { scale = 0.85 })
	-- (phoneFit adds its own UIScale; keep one: fold the pulse into it below)
	local ft = f:FindFirstChild("PhoneFit") :: UIScale?
	if ft then ft.Parent = nil end
	return f, art, leaf, t, sc, ft
end
local pill, banner, clover, text, pulse, fit = newPill("Weekend")
local luck, luckBanner, luckClover, luckText, luckPulse, luckFit = newPill("ServerLuck")
luckBanner.Image = ART.Active

local function span(s: number): string
	s = math.max(0, math.floor(s))
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. m .. "m" end
	return m .. "m " .. (s % 60) .. "s"
end

local on = false
task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		local active, left = W.status(now)
		-- Studio only: workspace attribute WeekendTest = "active" / "upcoming" previews the pill
		local test = if RunService:IsStudio() then workspace:GetAttribute("WeekendTest") else nil
		if test == "active" then active, left = true, 101400 elseif test == "upcoming" then active, left = false, 33600 end
		on = active
		pill.Visible = left ~= nil
		-- under the top-right button row; on short screens (phones) the SMASH button sits
		-- there too, so then the banner moves to its left
		if pill.Visible then
			local pg = me.PlayerGui
			local row = pg:FindFirstChild("EquipBest", true) :: GuiObject?
			local y = if row and row:IsA("GuiObject") and row.AbsoluteSize.Y > 0 then row.AbsolutePosition.Y + row.AbsoluteSize.Y + 8 else 64
			local smash = pg:FindFirstChild("SmashHolder", true) :: GuiObject?
			local right = gui.AbsoluteSize.X - 10
			if smash and smash:IsA("GuiObject") and smash.Visible and smash.AbsoluteSize.X > 0 then
				local h = pill.AbsoluteSize.Y
				local overlapsY = y < smash.AbsolutePosition.Y + smash.AbsoluteSize.Y and y + h > smash.AbsolutePosition.Y
				if overlapsY and right > smash.AbsolutePosition.X then right = smash.AbsolutePosition.X - 8 end
			end
			pill.Position = UDim2.fromOffset(right, y)
		end
		-- 4 Nov: Server Luck (someone bought 2x luck for this server), under the weekend pill
		local luckLeft = ((workspace:GetAttribute("ServerLuckEnds") :: number?) or 0) - now
		luck.Visible = luckLeft > 0
		if luck.Visible then
			local by = workspace:GetAttribute("ServerLuckBy")
			luckText.Text = "x2 SERVER LUCK · " .. string.format("%d:%02d", math.floor(luckLeft) // 60, math.floor(luckLeft) % 60) .. (if type(by) == "string" then " · " .. by else "")
			local pos = pill.Position
			if not pill.Visible then
				local row = me.PlayerGui:FindFirstChild("EquipBest", true) :: GuiObject?
				local y = if row and row:IsA("GuiObject") and row.AbsoluteSize.Y > 0 then row.AbsolutePosition.Y + row.AbsoluteSize.Y + 8 else 64
				pos = UDim2.new(1, -10, 0, y)
			end
			luck.Position = pos + UDim2.fromOffset(0, if pill.Visible then pill.AbsoluteSize.Y + 8 else 0)
		end
		if active and left then
			text.Text = W.Luck .. "x LUCK WEEKEND · " .. span(left)
			banner.Image = ART.Active
		elseif left then
			text.Text = W.Name .. " in " .. span(left)
			banner.Image = ART.Upcoming
		end
		task.wait(1)
	end
end)
RunService.RenderStepped:Connect(function()
	local base = if fit then fit.Scale else 1
	pulse.Scale = base * (if on then 1 + 0.03 * math.sin(os.clock() * 3) else 1)
	clover.Rotation = math.sin(os.clock() * (if on then 2.4 else 1.2)) * 8 -- the clover sways (faster during the weekend)
	luckPulse.Scale = (if luckFit then luckFit.Scale else 1) * (1 + 0.03 * math.sin(os.clock() * 3 + 1))
	luckClover.Rotation = math.sin(os.clock() * 2.4 + 1) * 8
end)
