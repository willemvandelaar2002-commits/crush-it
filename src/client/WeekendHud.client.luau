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
local pill = Instance.new("Frame")
pill.Name = "Weekend" pill.AnchorPoint = Vector2.new(1, 0) pill.Position = UDim2.new(1, -10, 0, 64)
pill.Size = UDim2.fromOffset(316, 40) pill.BackgroundTransparency = 1 pill.Visible = false pill.Parent = gui
local banner = Instance.new("ImageLabel")
banner.Name = "Banner" banner.BackgroundTransparency = 1 banner.Size = UDim2.fromScale(1, 1) banner.ScaleType = Enum.ScaleType.Stretch
banner.Image = ART.Upcoming banner.Parent = pill
local clover = Instance.new("ImageLabel")
clover.Name = "Clover" clover.BackgroundTransparency = 1 clover.Image = ART.Clover clover.ScaleType = Enum.ScaleType.Fit
clover.AnchorPoint = Vector2.new(0.5, 0.5) clover.Position = UDim2.new(0, 6, 0.5, 0) clover.Size = UDim2.fromOffset(54, 54) clover.ZIndex = 3
clover.Parent = pill
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1 text.TextScaled = true text.Position = UDim2.new(0, 38, 0.18, 0) text.Size = UDim2.new(1, -56, 0.64, 0)
text.ZIndex = 2 text.Parent = pill
Style.text(text, 2)
local cap = Instance.new("UITextSizeConstraint") cap.MinTextSize = 12 cap.MaxTextSize = 22 cap.Parent = text
local pulse = Instance.new("UIScale") pulse.Parent = pill
Style.phoneFit(pill, { scale = 0.85 })
-- (phoneFit adds its own UIScale; keep one: fold the pulse into it below)
local fit = pill:FindFirstChild("PhoneFit") :: UIScale?
if fit then fit.Parent = nil end

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
end)
