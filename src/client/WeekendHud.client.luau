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
local pill = Instance.new("Frame")
pill.Name = "Weekend" pill.AnchorPoint = Vector2.new(1, 0) pill.Position = UDim2.new(1, -10, 0, 62)
pill.Size = UDim2.fromOffset(250, 34) pill.Visible = false pill.Parent = gui
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 17) corner.Parent = pill
local stroke = Instance.new("UIStroke") stroke.Thickness = 3 stroke.Color = INK stroke.Parent = pill
local grad = Instance.new("UIGradient") grad.Rotation = 90 grad.Parent = pill
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1 text.TextScaled = true text.Position = UDim2.fromOffset(10, 5) text.Size = UDim2.new(1, -20, 1, -10)
text.Parent = pill
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
		on = active
		pill.Visible = left ~= nil
		if active and left then
			text.Text = "🍀 " .. W.Name .. " · " .. W.Luck .. "x LUCK · " .. span(left) .. " left"
			grad.Color = ColorSequence.new(C(255, 220, 70), C(240, 150, 20))
		elseif left then
			text.Text = W.Name .. " in " .. span(left)
			grad.Color = ColorSequence.new(C(90, 80, 170), C(56, 46, 130))
		end
		task.wait(1)
	end
end)
RunService.RenderStepped:Connect(function()
	local base = if fit then fit.Scale else 1
	pulse.Scale = base * (if on then 1 + 0.04 * math.sin(os.clock() * 3) else 1)
end)
