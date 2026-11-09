--!strict
-- 2 Nov evening: REBIRTH (vault: Rebirth and Prestige; doc wave 3 "long loop").
-- A HUD button (slot 3, after INDEX / SHOP / REWARDS) shows from Factory III on.
-- The panel shows income now > after, what resets and what stays, the cost and
-- a REBIRTH button that asks twice. The server decides (CrusherRules "Rebirth").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local Config = require(RS.Shared.Config)
local Icons = require(RS.Shared.Icons)
local Gems = require(RS.Shared.GemConfig)
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local RGB = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, stroke or 2.5)
	return l
end

local gui = make("ScreenGui", { Name = "RebirthHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local button, badge = Style.iconButton(gui, { name = "RebirthButton", icon = "🔄", image = Icons.Rebirth, label = "REBIRTH", a = RGB(255, 170, 60), b = RGB(230, 70, 40) })
button.Visible = false
Style.placeHudButton(button, 3)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(button, 3) end)

-- 5 Nov: the panel is Willem's art (Rebirth-Background, 1448 x 1086) with live text, a
-- native progress bar and the starter offer's green / red sprite buttons on top.
-- Layout = the art pack's layout.json (fractions of the background).
local ART = {
	Background = "rbxassetid://99505950209721", -- Rebirth-Background.png
	Purchase = "rbxassetid://106307684676239", -- PurchaseButton.png (from the starter offer pack)
	Close = "rbxassetid://86950187561147", -- CloseButton.png (from the starter offer pack)
}
local L = {
	title = { 0.37, 0.043, 0.34, 0.10 }, closeButton = { 0.832, 0.062, 0.077, 0.103 }, boostSubtitle = { 0.34, 0.177, 0.32, 0.034 },
	cashTitle = { 0.19, 0.235, 0.29, 0.048 }, cashValues = { 0.19, 0.29, 0.29, 0.058 },
	luckTitle = { 0.59, 0.235, 0.29, 0.048 }, luckValues = { 0.59, 0.29, 0.29, 0.058 },
	rebirthCount = { 0.40, 0.367, 0.20, 0.038 },
	resetsTitle = { 0.264, 0.438, 0.21, 0.05 }, keepsTitle = { 0.64, 0.438, 0.23, 0.05 },
	resetsList = { 0.145, 0.507, 0.33, 0.195 }, keepsList = { 0.54, 0.507, 0.345, 0.195 },
	progressBar = { 0.125, 0.742, 0.75, 0.06 }, rebirthButton = { 0.21, 0.825, 0.58, 0.12 },
}
local W, H = 760, 570 -- 4:3 like the art
local function box(parent: Instance, name: string, r: { number }, z: number): Frame
	return make("Frame", { Name = name, Position = UDim2.fromScale(r[1], r[2]), Size = UDim2.fromScale(r[3], r[4]), BackgroundTransparency = 1, ZIndex = z }, parent)
end
local function words(parent: Instance, text: string, z: number, outline: number?, max: number?): TextLabel
	local l = make("TextLabel", { Name = "Text", Text = text, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, ZIndex = z }, parent)
	Style.text(l, outline or 2.5)
	if max then make("UITextSizeConstraint", { MaxTextSize = max }, l) end
	return l
end
-- a stable root frame with an ImageButton centred in it; hover/press scale only the button
local function imageButton(parent: Instance, name: string, r: { number }, image: string, z: number, hoverScale: number, pressScale: number)
	local root = box(parent, name .. "Root", r, z)
	local b = make("ImageButton", { Name = name, Image = image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = z, Selectable = true }, root)
	local scale = make("UIScale", { Scale = 1 }, b)
	local hovered, down = false, false
	local tween: Tween? = nil
	local function settle()
		local target = if down then pressScale elseif hovered then hoverScale else 1
		if tween then tween:Cancel() end
		tween = TweenService:Create(scale, TweenInfo.new(if down then 0.07 else 0.12, Enum.EasingStyle.Quad), { Scale = target })
		;(tween :: Tween):Play()
	end
	b.MouseEnter:Connect(function() hovered = true settle() end)
	b.MouseLeave:Connect(function() hovered = false down = false settle() end)
	b.SelectionGained:Connect(function() hovered = true settle() end)
	b.SelectionLost:Connect(function() hovered = false down = false settle() end)
	b.MouseButton1Down:Connect(function() down = true settle() end)
	b.MouseButton1Up:Connect(function() down = false settle() end)
	b.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then hovered = false down = false settle() end end)
	local function reset() hovered = false down = false if tween then tween:Cancel() end scale.Scale = 1 end
	return b, reset
end

local panel = make("Frame", { Name = "RebirthPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, gui)
make("UIAspectRatioConstraint", { AspectRatio = 1448 / 1086 }, panel)
make("ImageLabel", { Name = "Background", Image = ART.Background, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = 6 }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W) panel:SetAttribute("FitHeight", H * 1.16)
-- 8 Nov: under the panel, what the next rebirth also gives: Gems (Willem's gem pile) and
-- the next unlock (Gem Shop / Annex / Gem Crusher / Awakened) with its art
local extras = make("Frame", { Name = "NextRewards", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromScale(0.86, 0.13),
	BackgroundColor3 = RGB(46, 30, 110), ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, extras)
make("UIStroke", { Thickness = 4, Color = INK }, extras)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(120, 60, 200), RGB(50, 26, 110)) }, extras)
make("ImageLabel", { Image = Gems.Art.Pile, Position = UDim2.fromScale(0.015, -0.12), Size = UDim2.fromScale(0.13, 1.2), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, extras)
local gemsBox = box(extras, "Gems", { 0.15, 0.12, 0.25, 0.76 }, 8)
local gemsText = words(gemsBox, "", 9, 2.5)
gemsText.TextXAlignment = Enum.TextXAlignment.Left gemsText.TextColor3 = RGB(255, 190, 250)
local unlockArt = make("ImageLabel", { Position = UDim2.fromScale(0.42, -0.12), Size = UDim2.fromScale(0.13, 1.2), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 8 }, extras)
local unlockBox = box(extras, "Unlock", { 0.56, 0.1, 0.42, 0.8 }, 8)
local unlockText = words(unlockBox, "", 9, 2.5)
unlockText.TextXAlignment = Enum.TextXAlignment.Left

local titleText = words(box(panel, "Title", L.title, 8), "REBIRTH", 9, 4)
Style.bold(titleText, 4)
local close, resetClose = imageButton(panel, "Close", L.closeButton, ART.Close, 12, 1.07, 0.94)
local xHome = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.56, 0.56), BackgroundTransparency = 1, ZIndex = 13 }, close)
Style.bold(words(xHome, "X", 13, 4), 4)
words(box(panel, "Subtitle", L.boostSubtitle, 8), "PERMANENT BOOSTS", 9, 2.5)
words(box(panel, "CashTitle", L.cashTitle, 8), "CASH MULTIPLIER", 9, 3)
words(box(panel, "LuckTitle", L.luckTitle, 8), "LUCK", 9, 3)
local cashValues = words(box(panel, "CashValues", L.cashValues, 8), "", 9, 3.5)
local luckValues = words(box(panel, "LuckValues", L.luckValues, 8), "", 9, 3.5)
cashValues.RichText = true luckValues.RichText = true
local countText = words(box(panel, "RebirthCount", L.rebirthCount, 8), "", 9, 2.5)
words(box(panel, "ResetsTitle", L.resetsTitle, 8), "RESETS", 9, 3)
words(box(panel, "KeepsTitle", L.keepsTitle, 8), "YOU KEEP", 9, 3)
-- the real reset / keep rules (CrusherRules "Rebirth"), five lines each
local function list(r: { number }, name: string, lines: { string })
	local home = box(panel, name, r, 8)
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Vertical }, home)
	for i, text in lines do
		local row = make("Frame", { Size = UDim2.fromScale(1, 1 / #lines), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 8 }, home)
		local l = words(row, "•  " .. text, 9, 2.2, 26)
		l.TextXAlignment = Enum.TextXAlignment.Left
	end
end
list(L.resetsList, "ResetsList", { "Cash", "Bays", "Factory level", "Factory upgrades", "Crusher levels" })
list(L.keepsList, "KeepsList", { "All crushers", "Coatings & fused status", "Index & Luck", "Pedestals", "Passes" })
-- native progress bar: navy track, gold gradient fill
local progressBack = box(panel, "Progress", L.progressBar, 8)
progressBack.BackgroundTransparency = 0 progressBack.BackgroundColor3 = RGB(16, 26, 70)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressBack)
make("UIStroke", { Thickness = 3, Color = INK }, progressBack)
local progressFill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, ZIndex = 9 }, progressBack)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressFill)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, RGB(255, 236, 110)), ColorSequenceKeypoint.new(0.55, RGB(255, 196, 30)), ColorSequenceKeypoint.new(1, RGB(240, 150, 20)) }) }, progressFill)
local progressText = words(progressBack, "", 10, 2.5)
local go, resetGo = imageButton(panel, "Rebirth", L.rebirthButton, ART.Purchase, 10, 1.035, 0.97)
local goHome = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.8, 0.56), BackgroundTransparency = 1, ZIndex = 11 }, go)
local goText = words(goHome, "REBIRTH", 11, 4)
Style.bold(goText, 4)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if not panel.Visible then resetGo() resetClose() end end)

-- multipliers shown rounded for reading (2 decimals at most); the math is untouched
local function mult(x: number): string
	local t = string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
	return t .. "x"
end
local GREEN = "#7CFF4E"
local state: any = nil
local confirmUntil = 0
local function ready(): boolean
	return state ~= nil and (state.plotLevel or 0) >= C.Rebirth.MinPlot and (state.cash or 0) >= (state.rebirthCost or math.huge)
end
local function paint()
	if not state then return end
	local n = state.rebirths or 0
	button.Visible = (state.plotLevel or 0) >= C.Rebirth.MinPlot - 1 or n > 0
	badge.Visible = ready()
	cashValues.Text = string.format('%s → <font color="%s">%s</font>', mult(C.rebirthMult(n)), GREEN, mult(C.rebirthMult(n + 1)))
	luckValues.Text = string.format('%s → <font color="%s">%s</font>', mult(C.rebirthLuck(n)), GREEN, mult(C.rebirthLuck(n + 1)))
	countText.Text = "Rebirths: " .. n
	gemsText.Text = if n >= Gems.UnlockRebirths then "GEMS: GEM MINE" else "NEXT: GEMS"
	local nextUp = Gems.nextMilestone(n)
	unlockArt.Visible = nextUp ~= nil
	if nextUp then
		unlockArt.Image = nextUp.art
		unlockText.Text = if nextUp.rebirths == n + 1 then "UNLOCKS: " .. nextUp.text .. "!" else "REBIRTH " .. nextUp.rebirths .. ": " .. nextUp.text
		unlockText.TextColor3 = if nextUp.rebirths == n + 1 then RGB(255, 236, 90) else WHITE
	else
		unlockText.Text = "EVERYTHING UNLOCKED!"
		unlockText.TextColor3 = RGB(255, 236, 90)
	end
	local cost = state.rebirthCost or C.rebirthCost(n)
	if (state.plotLevel or 0) < C.Rebirth.MinPlot then
		progressFill.Size = UDim2.fromScale(math.clamp((state.plotLevel or 0) / C.Rebirth.MinPlot, 0, 1), 1)
		progressText.Text = "Needs " .. C.PlotUpgrade.Names[C.Rebirth.MinPlot]
	elseif type(cost) == "number" and cost > 0 and cost == cost then
		progressFill.Size = UDim2.fromScale(math.clamp((state.cash or 0) / cost, 0, 1), 1)
		progressText.Text = Format.cash(state.cash or 0) .. " / " .. Format.cash(cost)
	else
		progressFill.Size = UDim2.fromScale(0, 1)
		progressText.Text = "..."
	end
	progressFill.Visible = progressFill.Size.X.Scale > 0.01
	local confirming = os.clock() < confirmUntil
	local can = ready()
	go.ImageColor3 = if can then WHITE else RGB(150, 150, 150)
	go.ImageTransparency = if can then 0 else 0.15
	goText.Text = if confirming then "SURE? TAP AGAIN" else "REBIRTH"
	goText.TextColor3 = if confirming then RGB(255, 236, 90) else WHITE
end
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) ~= "table" then return end
	state = v
	paint()
end)
button.Activated:Connect(function() confirmUntil = 0 Style.setOpen(panel, not panel.Visible) paint() end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)
go.Activated:Connect(function()
	if not ready() then return end
	if os.clock() < confirmUntil then
		confirmUntil = 0
		Net.event("CrusherAction"):FireServer("Rebirth", {})
	else
		confirmUntil = os.clock() + 3
	end
	paint()
end)
task.spawn(function() while true do task.wait(0.5) if panel.Visible then paint() end end end)

-- the big moment (only the player who rebirthed)
Net.event("RebirthDone").OnClientEvent:Connect(function(r: any)
	if type(r) ~= "table" then return end
	Style.setOpen(panel, false)
	local s = make("Sound", { SoundId = "rbxassetid://" .. Config.Sounds.LevelUp, Volume = 0.7 }, SoundService)
	s:Play() task.delay(3, function() s:Destroy() end)
	local pop = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(620, 90),
		BackgroundTransparency = 1, TextScaled = true, Text = "REBIRTH " .. tostring(r.rebirths) .. "!  x" .. tostring(r.mult) .. " CASH · x" .. tostring(r.luck or 1) .. " LUCK", ZIndex = 9 }, gui)
	pop.Font = Style.Font -- (8 Nov: the game font, was the default)
	Style.bold(pop, 4)
	pop.TextColor3 = RGB(255, 190, 60)
	local sc = make("UIScale", { Scale = 0.3 }, pop)
	TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
	task.delay(2.6, function()
		TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0 }):Play()
		task.delay(0.35, function() pop:Destroy() end)
	end)
	-- 8 Nov: what it unlocked (Willem's art). 9 Nov: rebirths no longer pay Gems (the Gem Mine does)
	local n = tonumber(r.rebirths) or 0
	local unlocked: any = nil
	for _, m in Gems.Milestones do if m.rebirths == n then unlocked = m end end
	if not unlocked then return end
	local card = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.4, -36), Size = UDim2.fromOffset(520, 250),
		BackgroundTransparency = 1, ZIndex = 9 }, gui)
	if unlocked then
		make("ImageLabel", { Image = unlocked.art, Position = UDim2.fromOffset(10, 92), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 9 }, card)
		local u = make("TextLabel", { Position = UDim2.fromOffset(170, 120), Size = UDim2.fromOffset(340, 90), BackgroundTransparency = 1, TextScaled = true,
			Text = "UNLOCKED:\n" .. unlocked.text .. "!", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }, card)
		u.Font = Style.Font
		Style.bold(u, 4)
		u.TextColor3 = RGB(255, 236, 90)
	end
	local cs = make("UIScale", { Scale = 0.3 }, card)
	TweenService:Create(cs, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
	task.delay(if unlocked then 4.5 else 2.6, function()
		TweenService:Create(cs, TweenInfo.new(0.3), { Scale = 0 }):Play()
		task.delay(0.35, function() card:Destroy() end)
	end)
end)
