--!strict
-- 5 Nov: the one-tap survey (Shared/FeedbackConfig, server/Feedback).
--   page 1  "How do you like Crush It so far?"   😍 LOVE IT / 🙂 IT'S OK / 😕 NOT FUN
--   page 2  "What would make it better?"          tap any (each is logged once), DONE
-- Pops up once per save after 10 minutes in a session (tutorial done, through the
-- pop-up gate: no other window, cutscene or event). The FEEDBACK button on the Codes
-- tab of Rewards opens it any time (BindableEvent "OpenFeedback" on this script's gui).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Config = require(RS.Shared.Config)
local F = require(RS.Shared.FeedbackConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local remote = Net.event("Feedback")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, max: number): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, 3)
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = max }, l)
	return l
end
local function button(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, max: number): (TextButton, TextLabel)
	local b = make("TextButton", { Text = "", Position = pos, Size = size, ZIndex = 7 }, parent)
	Style.button(b, color)
	local t = words(b, text, UDim2.fromOffset(10, 8), UDim2.new(1, -20, 1, -16), max)
	t.ZIndex = 9
	return b, t
end

local gui = make("ScreenGui", { Name = "FeedbackHud", ResetOnSpawn = false, DisplayOrder = 7, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local W, H = 600, 400 -- (6 Nov: was 360; the thanks line overlapped DONE)
local panel = make("Frame", { Name = "FeedbackPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = C(52, 44, 140), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 20) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(80, 68, 190), C(42, 34, 120)) }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 20) panel:SetAttribute("FitHeight", H + 20)
local title = words(panel, "", UDim2.fromOffset(30, 18), UDim2.new(1, -110, 0, 52), 40)
local close, _ = button(panel, "X", UDim2.new(1, -78, 0, 12), UDim2.fromOffset(66, 66), C(228, 36, 44), 40)

-- page 1: rating
local page1 = make("Frame", { Position = UDim2.fromOffset(20, 90), Size = UDim2.new(1, -40, 1, -110), BackgroundTransparency = 1, ZIndex = 6 }, panel)
-- page 2: wishes
local page2 = make("Frame", { Position = UDim2.fromOffset(20, 84), Size = UDim2.new(1, -40, 1, -104), BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, panel)
-- page 3 (6 Nov): after LOVE IT, ask for a like (no reward)
local page3 = make("Frame", { Position = UDim2.fromOffset(20, 84), Size = UDim2.new(1, -40, 1, -104), BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, panel)
local thumb = make("TextLabel", { Text = "👍", Position = UDim2.new(0.5, -60, 0, 0), Size = UDim2.fromOffset(120, 110), BackgroundTransparency = 1,
	TextScaled = true, Font = Enum.Font.GothamBold, ZIndex = 9 }, page3)
local _ = thumb
words(page3, F.LikeAsk.Text, UDim2.fromOffset(10, 112), UDim2.new(1, -20, 0, 66), 28)
local sure, _s = button(page3, F.LikeAsk.Button, UDim2.new(0.5, -90, 1, -58), UDim2.fromOffset(180, 54), C(60, 190, 80), 30)
local thanks = words(panel, "", UDim2.fromOffset(30, H - 42), UDim2.new(1, -60, 0, 28), 24)
thanks.TextColor3 = C(150, 255, 140)

local pageShown = 0
local function showPage(n: number)
	pageShown = os.clock()
	page1.Visible = n == 1
	page2.Visible = n == 2
	page3.Visible = n == 3
	title.Text = if n == 1 then "How do you like Crush It so far?" elseif n == 3 then F.LikeAsk.Title else "What would make it better?"
	thanks.Text = if n == 2 then "Thanks! Tap as many as you like." else ""
end

local RATING_COLORS = { [3] = C(70, 200, 90), [2] = C(250, 180, 40), [1] = C(220, 80, 80) }
for i, r in F.Ratings do
	local b = make("TextButton", { Text = "", Position = UDim2.new((i - 1) / 3, 6, 0, 0), Size = UDim2.new(1 / 3, -12, 1, -10), ZIndex = 7 }, page1)
	Style.button(b, RATING_COLORS[r.value] or C(120, 124, 134))
	local e = make("TextLabel", { Text = r.emoji, Position = UDim2.fromScale(0.1, 0.06), Size = UDim2.fromScale(0.8, 0.56), BackgroundTransparency = 1,
		TextScaled = true, Font = Enum.Font.GothamBold, ZIndex = 9 }, b)
	local _ = e
	local t = words(b, r.label, UDim2.fromScale(0.06, 0.64), UDim2.fromScale(0.88, 0.28), 30)
	t.ZIndex = 9
	b.Activated:Connect(function()
		remote:FireServer("Rating", r.value)
		if r.value == 3 then
			remote:FireServer("LikeAsk")
			showPage(3)
		else
			showPage(2)
		end
	end)
end

local picked: { [string]: boolean } = {}
for i, w in F.Wishes do
	local col, row = (i - 1) % 2, (i - 1) // 2
	local b, t = button(page2, w.text, UDim2.new(col * 0.5, 6, 0, row * 66), UDim2.new(0.5, -12, 0, 58), C(70, 120, 230), 28)
	b.Activated:Connect(function()
		if picked[w.key] then return end
		picked[w.key] = true
		remote:FireServer("Wish", w.key)
		Style.setButtonColor(b, C(60, 190, 80))
		t.Text = "✓ " .. w.text
	end)
end
local done, _d = button(page2, "DONE", UDim2.new(0.5, -90, 0, 3 * 66 + 2), UDim2.fromOffset(180, 52), C(60, 190, 80), 30)

sure.Activated:Connect(function() showPage(2) end)

local function open()
	showPage(1)
	Style.setOpen(panel, true)
end
local function shut() Style.setOpen(panel, false) end
close.Activated:Connect(shut)
-- (6 Nov: SURE! on the like page sits where DONE appears; ignore DONE for a moment so
-- the same tap doesn't close the survey)
done.Activated:Connect(function() if os.clock() - pageShown > 0.4 then shut() end end)
local opener = make("BindableEvent", { Name = "OpenFeedback" }, gui)
opener.Event:Connect(open)

-- the once-per-save pop-up
local tutorialDone = false
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) == "table" and type(v.tutorial) == "number" then tutorialDone = v.tutorial > #Config.Crushers.TutorialSteps end
end)
task.spawn(function()
	local joined = os.clock()
	while true do
		task.wait(5)
		if me:GetAttribute("FeedbackAsked") == true then return end
		local calm = tutorialDone and os.clock() - joined >= F.AskAfterMinutes * 60 and not Style.hasModal()
			and me:GetAttribute("CutscenePlaying") ~= true and me:GetAttribute("FactoryEventRunning") ~= true
		if calm and me:GetAttribute("FeedbackAsked") == false then
			remote:FireServer("Shown")
			open()
			return
		end
	end
end)
