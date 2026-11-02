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
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local RGB = Color3.fromRGB

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

local W, H = 560, 420
local panel = make("Frame", { Name = "RebirthPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = RGB(44, 48, 54), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 40)
panel:SetAttribute("FitHeight", H + 60)
local header = make("Frame", { Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 70), BackgroundColor3 = RGB(255, 140, 30), ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, header)
make("UIStroke", { Thickness = 5, Color = INK }, header)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(255, 200, 70), RGB(230, 70, 40)) }, header)
local title = label(header, "REBIRTH", UDim2.fromOffset(20, 8), UDim2.new(1, -120, 0, 54), 4)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 7
local close = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(54, 54), Text = "",
	BackgroundColor3 = RGB(228, 36, 44), ZIndex = 8 }, header)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, close)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, close)
label(close, "X", UDim2.fromScale(0.15, 0.1), UDim2.fromScale(0.7, 0.8), 3).ZIndex = 9

local multLine = label(panel, "", UDim2.fromOffset(20, 80), UDim2.new(1, -40, 0, 56), 4)
multLine.TextColor3 = RGB(255, 215, 60)
multLine.RichText = true
local sub = label(panel, "INCOME FOREVER", UDim2.fromOffset(20, 134), UDim2.new(1, -40, 0, 22), 2)
local function box(x: number, color: Color3, head: string, body: string)
	local f = make("Frame", { Position = UDim2.fromOffset(x, 166), Size = UDim2.fromOffset((W - 60) / 2, 132), BackgroundColor3 = color, ZIndex = 6 }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, f)
	make("UIStroke", { Thickness = 3, Color = INK }, f)
	label(f, head, UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 26), 3)
	local b = label(f, body, UDim2.fromOffset(10, 36), UDim2.new(1, -20, 1, -44), 2)
	b.TextYAlignment = Enum.TextYAlignment.Top
end
box(20, RGB(150, 50, 50), "RESETS", "Cash, bays, factory level, factory upgrades, crusher levels")
box(40 + (W - 60) / 2, RGB(50, 130, 70), "YOU KEEP", "All crushers (coatings, fused), Index, Luck, pedestals, passes")
local progressBack = make("Frame", { Position = UDim2.fromOffset(20, 308), Size = UDim2.new(1, -40, 0, 28), BackgroundColor3 = RGB(24, 28, 46), ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressBack)
make("UIStroke", { Thickness = 3, Color = INK }, progressBack)
local progressFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = RGB(255, 200, 40), ZIndex = 7 }, progressBack)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressFill)
local progressText = label(progressBack, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 2)
local go = make("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 346), Size = UDim2.fromOffset(280, 56), Text = "",
	BackgroundColor3 = RGB(60, 200, 80), ZIndex = 7 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, go)
make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, go)
Style.feedback(go)
local goText = label(go, "REBIRTH", UDim2.fromOffset(8, 6), UDim2.new(1, -16, 1, -12), 3)
goText.ZIndex = 8

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
	multLine.Text = string.format('x%s  >  <font color="#7CFF6E">x%s</font>', tostring(C.rebirthMult(n)), tostring(C.rebirthMult(n + 1)))
	sub.Text = if n > 0 then "INCOME FOREVER · REBIRTHS: " .. n else "INCOME FOREVER"
	local cost = state.rebirthCost or C.rebirthCost(n)
	if (state.plotLevel or 0) < C.Rebirth.MinPlot then
		progressFill.Size = UDim2.fromScale(math.clamp((state.plotLevel or 0) / C.Rebirth.MinPlot, 0, 1), 1)
		progressText.Text = "Needs " .. C.PlotUpgrade.Names[C.Rebirth.MinPlot]
	else
		progressFill.Size = UDim2.fromScale(math.clamp((state.cash or 0) / cost, 0, 1), 1)
		progressText.Text = Format.cash(state.cash or 0) .. " / " .. Format.cash(cost)
	end
	local confirming = os.clock() < confirmUntil
	go.BackgroundColor3 = if not ready() then RGB(120, 124, 134) elseif confirming then RGB(235, 60, 50) else RGB(60, 200, 80)
	goText.Text = if confirming then "SURE? TAP AGAIN" else "REBIRTH"
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
		BackgroundTransparency = 1, TextScaled = true, Text = "REBIRTH " .. tostring(r.rebirths) .. "!  x" .. tostring(r.mult) .. " INCOME", ZIndex = 9 }, gui)
	Style.bold(pop, 4)
	pop.TextColor3 = RGB(255, 190, 60)
	local sc = make("UIScale", { Scale = 0.3 }, pop)
	TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
	task.delay(2.6, function()
		TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0 }):Play()
		task.delay(0.35, function() pop:Destroy() end)
	end)
end)
