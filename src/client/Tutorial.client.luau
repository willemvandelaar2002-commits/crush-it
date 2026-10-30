--!strict
-- Guided tutorial (steps in CrusherConfig.TutorialSteps, progress and rewards
-- on the server in CrusherRules). This draws:
--   * a step card at the top: "STEP 2 / 8", title, hint, reward chip and a
--     segmented progress bar; it celebrates each finished step (green flash,
--     check, "+$10" flying into the cash counter) and the whole tutorial;
--   * a glowing chevron path on the floor from you to the next thing to use,
--     a bobbing arrow over it and a pulsing outline around it;
--   * a detour when you can't afford the next step yet (collect / sell first).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local C = Config.Crushers
if not C.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Format = require(ReplicatedStorage.Shared.Format)
local Icons = require(ReplicatedStorage.Shared.Icons)
local GuidePath = require(ReplicatedStorage.Shared.Kit.GuidePath)

local me = Players.LocalPlayer
local STEPS = C.TutorialSteps
local INK = Style.Colors.Ink
local GOLD = Color3.fromRGB(255, 205, 60)
local GREEN = Style.GREEN
local CARD_W, CARD_H = 600, 112

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local node = Instance.new(class)
	for k, v in props do (node :: any)[k] = v end
	node.Parent = parent
	return node
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, stroke: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 4 }, parent)
	Style.text(l, stroke or 2.5)
	return l
end

-- Card --------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "TutorialHud", ResetOnSpawn = false, DisplayOrder = 4, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
-- 30 Oct (phone patch): the card sits in a holder that shrinks on phones (the
-- card's own UIScale is its pop animation); positions stay relative to it.
local holder = make("Frame", { Name = "StepCardHolder", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.fromOffset(CARD_W, CARD_H + 68), BackgroundTransparency = 1 }, gui)
Style.phoneFit(holder, { scale = 0.6, width = 0.6, position = UDim2.new(0.5, 60, 0, 80 - 68 * 0.6) }) -- right of the cash column
local card = make("Frame", { Name = "StepCard", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 68),
	Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundColor3 = Color3.fromRGB(30, 36, 62), Visible = false, ZIndex = 2 }, holder)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
local cardStroke = make("UIStroke", { Thickness = 4, Color = INK }, card)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(70, 82, 130), Color3.fromRGB(30, 36, 62)) }, card)
Style.studsImage(card, 22, 0.9).ZIndex = 2
local cardScale = make("UIScale", { Scale = 1 }, card)

-- step badge (number, becomes a check when done)
local badge = make("Frame", { Name = "Badge", Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(70, 70), BackgroundColor3 = GOLD, ZIndex = 3 }, card)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
make("UIStroke", { Thickness = 4, Color = INK }, badge)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 236, 140), Color3.fromRGB(240, 160, 30)) }, badge)
local badgeText = label(badge, "1", UDim2.fromScale(0.15, 0.12), UDim2.fromScale(0.7, 0.76), 3)
local badgeScale = make("UIScale", { Scale = 1 }, badge)

local stepTag = label(card, "STEP 1 / 8", UDim2.fromOffset(98, 10), UDim2.fromOffset(160, 20), 2)
stepTag.TextXAlignment = Enum.TextXAlignment.Left
stepTag.TextColor3 = GOLD
local title = label(card, "", UDim2.fromOffset(98, 28), UDim2.fromOffset(CARD_W - 230, 36), 3)
title.TextXAlignment = Enum.TextXAlignment.Left
Style.bold(title, 3)
local hint = label(card, "", UDim2.fromOffset(98, 64), UDim2.fromOffset(CARD_W - 120, 22), 2)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextColor3 = Color3.fromRGB(220, 228, 255)

-- reward chip
local chip = make("Frame", { Name = "Reward", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(112, 42),
	BackgroundColor3 = GREEN, ZIndex = 3 }, card)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, chip)
make("UIStroke", { Thickness = 3, Color = INK }, chip)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 255, 120), Color3.fromRGB(50, 170, 60)) }, chip)
make("ImageLabel", { Image = Icons.Cash, BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(36, 36), ZIndex = 4 }, chip)
local chipText = label(chip, "+$10", UDim2.fromOffset(40, 6), UDim2.fromOffset(66, 30), 2.5)

-- progress: one segment per step
local bar = make("Frame", { Name = "Progress", Position = UDim2.fromOffset(98, 92), Size = UDim2.fromOffset(CARD_W - 112, 10), BackgroundTransparency = 1, ZIndex = 3 }, card)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }, bar)
local segments: { Frame } = {}
for i = 1, #STEPS do
	local seg = make("Frame", { Name = "Seg" .. i, LayoutOrder = i, Size = UDim2.new(1 / #STEPS, -5, 1, 0), BackgroundColor3 = Color3.fromRGB(20, 24, 40), ZIndex = 3 }, bar)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, seg)
	make("UIStroke", { Thickness = 1.5, Color = INK }, seg)
	segments[i] = seg
end

-- Effects -----------------------------------------------------------------------
local coin = make("Sound", { SoundId = "rbxassetid://" .. Config.Sounds.Coin, Volume = 0.6 }, SoundService)
local levelUp = make("Sound", { SoundId = "rbxassetid://" .. Config.Sounds.LevelUp, Volume = 0.5 }, SoundService)
local function centre(g: GuiObject): Vector2 return g.AbsolutePosition + g.AbsoluteSize / 2 end
local function cashTarget(): Vector2?
	local hud = me.PlayerGui:FindFirstChild("CrushHud")
	local icon = hud and hud:FindFirstChild("CashIcon", true) :: GuiObject?
	return icon and centre(icon)
end
local function cashBurst(from: Vector2, amount: number)
	local target = cashTarget()
	local pop = label(gui, "+" .. Format.cash(amount), UDim2.fromOffset(from.X - 90, from.Y - 20), UDim2.fromOffset(180, 42), 3.5)
	pop.ZIndex = 30
	pop.TextColor3 = Color3.fromRGB(150, 255, 120)
	TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(from.X - 90, from.Y + 40) }):Play()
	TweenService:Create(pop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), { TextTransparency = 1 }):Play()
	task.delay(1.05, function() pop:Destroy() end)
	for i = 1, 10 do
		local img = make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.fromOffset(38, 38),
			BackgroundTransparency = 1, Image = Icons.Cash, Rotation = math.random(-30, 30), ZIndex = 29 }, gui)
		local a = math.random() * math.pi * 2
		local out = from + Vector2.new(math.cos(a), math.sin(a) * 0.6) * math.random(40, 120)
		TweenService:Create(img, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(out.X, out.Y) }):Play()
		task.delay(0.28 + i * 0.03, function()
			local goal = target or out + Vector2.new(0, 200)
			local t = TweenService:Create(img, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(goal.X, goal.Y), Size = UDim2.fromOffset(20, 20) })
			t:Play()
			t.Completed:Once(function() img:Destroy() end)
		end)
	end
end

local shown = 0 -- the step the card shows
local function paint(step: number)
	local s = STEPS[step]
	if not s then return end
	stepTag.Text = "STEP " .. step .. " / " .. #STEPS
	badgeText.Text = tostring(step)
	title.Text = s.title
	hint.Text = s.text
	chipText.Text = "+" .. Format.cash(s.reward)
	for i, seg in segments do
		seg.BackgroundColor3 = if i < step then GREEN elseif i == step then GOLD else Color3.fromRGB(20, 24, 40)
	end
end
local function slideIn()
	card.Position = UDim2.new(0.5, 0, 0, -CARD_H - 10)
	card.Visible = true
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 68) }):Play()
end
local busy = false
local function finishStep(step: number, nextStep: number)
	busy = true
	local s = STEPS[step]
	coin:Play()
	-- card flashes green, the badge turns into a check and pops
	cardStroke.Color = GREEN
	badgeText.Text = "✓"
	badge.BackgroundColor3 = GREEN
	badgeScale.Scale = 1.5
	TweenService:Create(badgeScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	cardScale.Scale = 1.06
	TweenService:Create(cardScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	segments[step].BackgroundColor3 = GREEN
	if s then cashBurst(centre(chip), s.reward) end
	task.wait(1.1)
	cardStroke.Color = INK
	badge.BackgroundColor3 = GOLD
	if nextStep > #STEPS then
		-- all done: big banner, bonus, then the card goes away for good
		levelUp:Play()
		TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -CARD_H - 10) }):Play()
		local banner = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(560, 150),
			BackgroundColor3 = GOLD, ZIndex = 20 }, gui)
		make("UICorner", { CornerRadius = UDim.new(0, 18) }, banner)
		make("UIStroke", { Thickness = 5, Color = INK }, banner)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 236, 140), Color3.fromRGB(240, 150, 30)) }, banner)
		Style.studsImage(banner, 24, 0.85).ZIndex = 20
		local big = label(banner, "TUTORIAL COMPLETE!", UDim2.fromOffset(20, 16), UDim2.new(1, -40, 0, 64), 4)
		big.ZIndex = 22
		local sub = label(banner, "Bonus +" .. Format.cash(C.TutorialBonus) .. "  ·  keep rolling for rarer crushers!", UDim2.fromOffset(20, 88), UDim2.new(1, -40, 0, 36), 3)
		sub.ZIndex = 22
		local scale = make("UIScale", { Scale = 0.3 }, banner)
		TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
		Style.wobble(banner, 2, 3)
		cashBurst(centre(banner), C.TutorialBonus)
		task.wait(3.5)
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.3)
		banner:Destroy()
		card.Visible = false
	else
		-- next step slides in
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -CARD_H - 10) }):Play()
		task.wait(0.28)
		paint(nextStep)
		slideIn()
	end
	shown = nextStep
	busy = false
end

-- World guidance ------------------------------------------------------------------
local path = GuidePath.new({ color = GOLD, spacing = 3.5, speed = 7, stopDistance = 9 })
-- (a Highlight only draws when parented to what it outlines)
local outline = make("Highlight", { Name = "TutorialOutline", FillTransparency = 1, OutlineColor = GOLD, OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, nil)

local state: any = nil
local function plotModel(): Model?
	local plots = Workspace:FindFirstChild("Plots")
	return plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot"))) :: Model?
end
local function find(plot: Model, name: string): Instance?
	return plot:FindFirstChild(name, true)
end
local function holding(): boolean
	local tool = me.Character and me.Character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("InventoryId") ~= nil
end
local function bayModel(plot: Model, i: number): Instance? return plot:FindFirstChild("WorkingBay" .. i, true) end
local function pedestal(plot: Model): BasePart?
	local st = find(plot, "RollStation")
	if not st then return nil end
	for _, v in st:GetChildren() do
		if v.Name == "Pedestal" and v:GetAttribute("Slot") == 1 then return v :: BasePart end
	end
	return nil
end

-- What to point at now: (instance to outline, label over it, card hint override)
local function goal(): (Instance?, string?, string?)
	local plot = plotModel()
	local step = STEPS[state.tutorial]
	if not plot or not step then return nil end
	local cash = state.cash
	-- not enough cash for this step: send them to make some first
	local function earn(need: number): (Instance?, string?, string?)
		local text = "You need " .. Format.cash(need) .. ". "
		if state.carried > 0 then return find(plot, "SellStation"), "SELL", text .. "Sell your scrap first!" end
		return find(plot, "CollectStation"), "COLLECT", text .. "Collect more scrap first!"
	end
	if step.target == "Collect" then
		if state.available <= 0 then return find(plot, "CollectStation"), "WAIT...", "Your crusher is working... scrap is coming!" end
		return find(plot, "CollectStation"), "COLLECT"
	elseif step.target == "Sell" then
		if state.carried <= 0 then return find(plot, "CollectStation"), "COLLECT", "Collect scrap at the blue bin first." end
		return find(plot, "SellStation"), "SELL"
	elseif step.target == "Roll" then
		return find(plot, "RollStation"), "ROLL"
	elseif step.target == "Pedestal" then
		local rolling = state.rollReadyAt - Workspace:GetServerTimeNow() > 0
		if not rolling and not find(plot, "OfferCrusher") then return find(plot, "RollStation"), "ROLL", "Roll first, then buy from the pedestal." end
		if cash < C.Rarities[1].price then return earn(C.Rarities[1].price) end
		return pedestal(plot), "BUY"
	elseif step.target == "NextBay" then
		local cost = C.BayCosts[state.unlocked + 1] or 0
		if cash < cost then return earn(cost) end
		return bayModel(plot, state.unlocked + 1), "UNLOCK"
	elseif step.target == "EmptyBay" then
		for i = 1, state.unlocked do
			if not state.bays[tostring(i)] then
				return bayModel(plot, i), "PLACE", if holding() then "Press E at the empty bay to place it." else nil
			end
		end
		return bayModel(plot, 1), "PLACE"
	elseif step.target == "Production" then
		local cheapest = math.huge
		for _, id in { "Damage", "Speed", "Yield" } do cheapest = math.min(cheapest, C.globalCost(id, state.upgrades[id])) end
		if cash < cheapest then return earn(cheapest) end
		return find(plot, "ProductionStation"), "UPGRADE"
	elseif step.target == "LevelBay" then
		local best, cost = nil, math.huge
		for key, id in state.bays do
			for _, item in state.items do
				if item.id == id and item.cost < cost then best, cost = tonumber(key), item.cost end
			end
		end
		if not best then return bayModel(plot, 1), "LEVEL UP" end
		if cash < cost then return earn(cost) end
		return bayModel(plot, best), "LEVEL UP"
	end
	return nil
end

local function topOf(target: Instance): Vector3?
	if target:IsA("BasePart") then return target.Position + Vector3.new(0, target.Size.Y / 2, 0) end
	if target:IsA("Model") then
		local cf, size = target:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2, 0)
	end
	return nil
end

-- the target is looked up a few times a second (searching the plot every frame is slow)
local cached: { target: Instance?, text: string?, override: string? } = {}
local nextLook = 0
RunService.RenderStepped:Connect(function()
	local active = state and STEPS[state.tutorial] and not busy
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not active or not root then
		path:update(Vector3.zero, nil)
		outline.Enabled = false
		return
	end
	if os.clock() >= nextLook then
		nextLook = os.clock() + 0.25
		local t, l, o = goal()
		cached = { target = t, text = l, override = o }
	end
	local target, text, override = cached.target, cached.text, cached.override
	if target and not target:IsDescendantOf(Workspace) then target = nil end
	local top = target and topOf(target)
	if not top then
		path:update(root.Position, nil)
		outline.Enabled = false
	else
		path:update(root.Position, top, text)
		if outline.Parent ~= target then outline.Parent = target end
		outline.Enabled = true
		outline.OutlineTransparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(os.clock() * 5))
	end
	local step = STEPS[state.tutorial]
	hint.Text = override or step.text
	-- the current progress segment and the badge breathe
	segments[state.tutorial].BackgroundTransparency = 0.25 * (0.5 + 0.5 * math.sin(os.clock() * 4))
	badgeScale.Scale = 1 + 0.04 * math.sin(os.clock() * 4)
end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.tutorial) ~= "number" then return end
	local before = state and state.tutorial
	state = v
	if busy then return end
	if before == nil then
		-- first state after joining: show the current step (or nothing if done)
		shown = v.tutorial
		if STEPS[shown] then paint(shown) slideIn() end
	elseif v.tutorial > shown then
		task.spawn(finishStep, shown, v.tutorial)
	end
end)
