--!strict
-- Guided tutorial (steps in CrusherConfig.TutorialSteps, progress and rewards
-- on the server in CrusherRules), then the GOALS (C.Goals2, up to Factory II),
-- then NEXT GOAL (Factory III+). 2 Nov restyle after a reference tutorial:
--   * floating text at the top, no box: a small cyan tag ("TUTORIAL 3/8",
--     "GOAL 4 / 16"), one short order, and a line with the counter ("3 / 5")
--     and the reward. The longer hint only shows for detours ("You need $50...")
--     or after 15 s on the same step;
--   * a thick glowing chevron trail from your feet to the target, a bobbing
--     arrow and outline on it and a glowing disc on the floor under it; HUD
--     buttons (Rewards, Index) get a bouncing arrow;
--   * a done step pops green with a check and flies its cash into the counter;
--     the end of the tutorial is a short toast, not a banner.
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
local HEAD_W = 560
local CYAN = Color3.fromRGB(90, 225, 255)

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

-- Headline ----------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "TutorialHud", ResetOnSpawn = false, DisplayOrder = 4, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
-- a CanvasGroup so the whole headline fades in and out as one
local headline = make("CanvasGroup", { Name = "Headline", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64),
	Size = UDim2.fromOffset(HEAD_W, 150), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false }, gui)
Style.phoneFit(headline, { scale = 0.62, width = 0.62 })
local popScale = make("UIScale", { Scale = 1 }, headline)
local tag = label(headline, "TUTORIAL", UDim2.fromOffset(0, 4), UDim2.new(1, 0, 0, 26), 2.5)
tag.TextColor3 = CYAN
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(200, 250, 255), CYAN) }, tag)
local title = label(headline, "", UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 52), 3)
Style.bold(title, 3)
local sub = label(headline, "", UDim2.fromOffset(0, 84), UDim2.new(1, 0, 0, 32), 3)
sub.RichText = true
local hint = label(headline, "", UDim2.fromOffset(0, 118), UDim2.new(1, 0, 0, 24), 2.5)
hint.TextColor3 = Color3.fromRGB(220, 232, 255)

-- the headline sits under the top button row (Equip Best / Mega Crusher / My Factory)
local function placeHeadline()
	local row = me.PlayerGui:FindFirstChild("EquipBest", true) :: GuiObject?
	local y = 64
	if row and row:IsA("GuiObject") and row.AbsoluteSize.Y > 0 then
		-- (both in screen pixels; minus where this ScreenGui starts)
		y = row.AbsolutePosition.Y + row.AbsoluteSize.Y - gui.AbsolutePosition.Y + 6
	end
	headline.Position = UDim2.new(0.5, 0, 0, y)
end

local function hex(c: Color3): string return "#" .. c:ToHex() end
-- the counter / reward line: "3 / 5   +$75"
local function setSub(counter: string?, reward: string?, color: Color3?)
	local parts = {}
	if counter and counter ~= "" then table.insert(parts, counter) end
	if reward and reward ~= "" then table.insert(parts, '<font color="' .. hex(color or GREEN) .. '">' .. reward .. "</font>") end
	sub.Text = table.concat(parts, "     ")
	sub.Visible = #parts > 0
end
local function setHeadline(tagText: string, titleText: string)
	tag.Text = tagText
	title.Text = titleText
	title.TextColor3 = Color3.new(1, 1, 1)
end
local shownOn = false
local function fadeIn()
	placeHeadline()
	headline.Visible = true shownOn = true
	popScale.Scale = 0.85
	TweenService:Create(popScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(headline, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
end
local function fadeOut(instant: boolean?)
	shownOn = false
	if instant then headline.GroupTransparency = 1 headline.Visible = false return end
	local t = TweenService:Create(headline, TweenInfo.new(0.2), { GroupTransparency = 1 })
	t:Play()
	t.Completed:Once(function() if not shownOn then headline.Visible = false end end)
end

local state: any = nil
local GOALS = C.Goals2
local mode: string? = nil -- "tutorial" | "goals" | "finished" | nil (what the headline shows)
local busy = false
-- hint timing: the long hint shows after 15 s on the same step
local stepKey, stepSince = "", 0
local function sameStep(key: string)
	if key ~= stepKey then stepKey = key stepSince = os.clock() end
end
local function showHint(default: string?, override: string?)
	local text = override or (if os.clock() - stepSince > 15 then default else nil)
	hint.Text = if text then Style.controls(text) else ""
	hint.Visible = text ~= nil
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
	for i = 1, 10 do
		local img = make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.fromOffset(34, 34),
			BackgroundTransparency = 1, Image = Icons.Cash, Rotation = math.random(-30, 30), ZIndex = 29 }, gui)
		local a = math.random() * math.pi * 2
		local out = from + Vector2.new(math.cos(a), math.sin(a) * 0.6) * math.random(40, 110)
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
-- a big prize line under the headline (free crusher, boost, tutorial bonus)
local function prizePop(text: string, color: Color3)
	levelUp:Play()
	local y = headline.AbsolutePosition.Y + headline.AbsoluteSize.Y + 6
	local pop = label(gui, text, UDim2.new(0.5, -240, 0, y), UDim2.fromOffset(480, 50), 4)
	pop.ZIndex = 30 pop.TextColor3 = color
	local sc = make("UIScale", { Scale = 0.3 }, pop)
	TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = Style.popScale() }):Play()
	TweenService:Create(pop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.8), { TextTransparency = 1 }):Play()
	task.delay(2.4, function() pop:Destroy() end)
end
-- a finished step: check + green title, pop, sound
local function celebrate()
	coin:Play()
	title.Text = "✓ " .. title.Text
	title.TextColor3 = GREEN
	popScale.Scale = 1.15
	TweenService:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Tutorial steps --------------------------------------------------------------------
local shown = 0 -- the step the headline shows
local function paint(step: number)
	local s = STEPS[step]
	if not s then return end
	setHeadline("TUTORIAL  " .. step .. "/" .. #STEPS, s.title)
	setSub(nil, "+" .. Format.cash(s.reward))
	hint.Visible = false
end
local function finishStep(step: number, nextStep: number)
	busy = true
	local s = STEPS[step]
	celebrate()
	if s then cashBurst(centre(sub), s.reward) end
	task.wait(0.9)
	fadeOut()
	task.wait(0.22)
	shown = nextStep
	if nextStep > #STEPS then
		-- all done: a short toast with the bonus, then the goals take over
		setHeadline("TUTORIAL", "Tutorial complete! Have fun!")
		title.TextColor3 = GREEN
		setSub(nil, "+" .. Format.cash(C.TutorialBonus) .. " BONUS")
		hint.Visible = false
		fadeIn()
		levelUp:Play()
		task.wait(0.3)
		cashBurst(centre(sub), C.TutorialBonus)
		task.wait(2.2)
		fadeOut()
		task.wait(0.25)
		-- 2 Nov fix: "finished", not nil, so the next frame's switch() really hides
		-- the trail and the arrow (with mode = nil it returned early and they stayed)
		mode = "finished"
	else
		paint(nextStep)
		fadeIn()
	end
	busy = false
end

-- Goals -----------------------------------------------------------------------------
local function goalCash(r: any): number
	return math.max(r.min or 0, math.floor(((state and state.rate) or 0) * r.cash))
end
-- (reward text, colour)
local function goalReward(g: any): (string, Color3)
	local r = g.reward
	if r.cash then return "+" .. Format.cash(goalCash(r)), GREEN end
	if r.boost then return "2x " .. string.upper(r.boost) .. " " .. r.minutes .. " MIN", Color3.fromRGB(90, 210, 255) end
	local rarity = C.rarity(r.crusher)
	return "FREE " .. string.upper(r.crusher) .. " CRUSHER", if rarity then rarity.color else GOLD
end
local function goalCounter(g: any): string?
	if g.check == "plot" then
		local cost = C.plotCost((state.plotLevel or 0) + 1) or 0
		return Format.cash(state.cash) .. " / " .. Format.cash(cost)
	end
	local have, need = state.goalHave, state.goalNeed
	if type(have) == "number" and type(need) == "number" and need > 1 then return math.min(have, need) .. " / " .. need end
	return nil
end
local goalShown = 0
local function paintGoal(i: number)
	local g = GOALS[i]
	if not g then return end
	setHeadline("GOAL " .. i .. " / " .. #GOALS, g.title)
	local text, color = goalReward(g)
	setSub(goalCounter(g), text, color)
end
local function finishGoal(i: number, nextGoal: number)
	busy = true
	local g = GOALS[i]
	celebrate()
	if g and g.reward.cash then
		cashBurst(centre(sub), goalCash(g.reward))
	elseif g then
		local text, color = goalReward(g)
		prizePop(if g.reward.boost then text .. " BOOST!" else text .. "!", color)
	end
	task.wait(1)
	fadeOut()
	task.wait(0.22)
	goalShown = nextGoal
	if GOALS[nextGoal] then paintGoal(nextGoal) fadeIn() else mode = "finished" end -- (see finishStep)
	busy = false
end

-- World guidance ------------------------------------------------------------------
-- 2 Nov (reference tutorial): a thick glowing trail from your feet, a white core
-- on top (skipped in lite mode), moving fast toward the target
local path = GuidePath.new({ color = GOLD, core = if Style.lite() then nil else Color3.fromRGB(255, 252, 230),
	scale = 1.7, spacing = 3.2, speed = 12, stopDistance = 8, startAt = 1.5 })
-- a glowing disc on the floor under the target (the reference lights up the pad)
local pad = make("Part", { Name = "TutorialPad", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false,
	CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = GOLD, Transparency = 1, Size = Vector3.new(0.12, 8, 8) }, Workspace)
-- (a Highlight only draws when parented to what it outlines)
local outline = make("Highlight", { Name = "TutorialOutline", FillTransparency = 1, OutlineColor = GOLD, OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, nil)

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

-- 2 Nov (Willem): an empty bay needs a crusher to put in it. With no spare
-- crusher (every owned one is already in a bay) the arrow goes to rolling first:
-- (target, label, hint) for "get a crusher", or nil when you have a spare one.
local function spareCrusher(): boolean
	local placed = {}
	for _, id in state.bays do placed[id] = true end
	for _, item in state.items do if not placed[item.id] then return true end end
	return false
end
local function getCrusher(plot: Model): (Instance?, string?, string?)
	if spareCrusher() then return nil end
	local price = C.Rarities[1].price
	local rolling = state.rollReadyAt - Workspace:GetServerTimeNow() > 0
	if find(plot, "OfferCrusher") and not rolling then
		if state.cash < price then
			if state.carried > 0 then return find(plot, "SellStation"), "SELL", "You need " .. Format.cash(price) .. " for a crusher. Sell your scrap!" end
			return find(plot, "CollectStation"), "COLLECT", "You need " .. Format.cash(price) .. " for a crusher. Collect scrap!"
		end
		return pedestal(plot), "BUY", "Buy a crusher from the pedestal."
	end
	return find(plot, "RollStation"), "ROLL", "Roll for a new crusher first!"
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
		local gt, gl, gh = getCrusher(plot)
		if gt then return gt, gl, gh end
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

-- HUD buttons (Rewards, Index) get a bobbing arrow instead of a floor path
local uiArrow = make("TextLabel", { Name = "GoalArrow", Text = "▲", Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1,
	TextScaled = true, Visible = false, ZIndex = 40, AnchorPoint = Vector2.new(0.5, 0) }, gui)
Style.text(uiArrow, 3) uiArrow.TextColor3 = GOLD
local function hudButton(name: string): GuiObject?
	for _, d in me.PlayerGui:GetDescendants() do
		if d.Name == name and d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.X > 0 then return d end
	end
	return nil
end
-- What a goal points at: (instance, label, hint override, hud button)
local function goalTarget(g: any): (Instance?, string?, string?, GuiObject?)
	local plot = plotModel()
	if not plot then return nil end
	local cash = state.cash
	-- 2 Nov (Willem): can't afford it yet? First the cheap things that raise your
	-- income: a factory upgrade, then a crusher level-up (each only when it costs
	-- at most half of what you're saving for, so saving still happens); else
	-- collect / sell.
	local function earn(need: number): (Instance?, string?, string?)
		local level = state.plotLevel or 0
		local upCost = math.huge
		for _, id in { "Damage", "Speed", "Yield" } do
			if (state.upgrades[id] or 0) < C.upgradeMax(id, level) then upCost = math.min(upCost, C.globalCost(id, state.upgrades[id] or 0)) end
		end
		if upCost <= cash and upCost <= need * 0.5 then
			return find(plot, "ProductionStation"), "UPGRADE", "Upgrade your factory first: more cash from every crusher!"
		end
		local best, lvCost = nil, math.huge
		for key, id in state.bays do
			for _, item in state.items do
				if item.id == id and item.level < C.levelCap(level) and item.cost < lvCost then best, lvCost = tonumber(key), item.cost end
			end
		end
		if best and lvCost <= cash and lvCost <= need * 0.5 then
			return bayModel(plot, best), "LEVEL UP", "Level up a crusher first: it earns more!"
		end
		local text = "Saving: " .. Format.cash(cash) .. " / " .. Format.cash(need) .. ". "
		if state.carried > 0 then return find(plot, "SellStation"), "SELL", text .. "Sell your scrap!" end
		return find(plot, "CollectStation"), "COLLECT", text .. "Collect your scrap!"
	end
	local function emptyBay(): Instance?
		for i = 1, state.unlocked do if not state.bays[tostring(i)] then return bayModel(plot, i) end end
		return nil
	end
	local t = g.target
	if t == "NextBayOrEmpty" then t = if emptyBay() then "EmptyBay" else "NextBay" end
	if t == "NextBay" then
		local cost = C.BayCosts[state.unlocked + 1]
		if not cost or state.unlocked >= C.bayCapacity(state.plotLevel or 0) then return emptyBay(), "PLACE" end
		if cash < cost then return earn(cost) end
		return bayModel(plot, state.unlocked + 1), "UNLOCK " .. Format.cash(cost)
	elseif t == "EmptyBay" then
		local e = emptyBay()
		if e then
			local gt, gl, gh = getCrusher(plot)
			if gt then return gt, gl, gh end
			return e, "PLACE", if holding() then "Press E at the empty bay to place it." else "Pick your crusher in the hotbar, then press E at the empty bay."
		end
		-- no empty bay: unlock one if you can, else roll for a crusher
		local cost = C.BayCosts[state.unlocked + 1]
		if cost and cash >= cost and state.unlocked < C.bayCapacity(state.plotLevel or 0) then return bayModel(plot, state.unlocked + 1), "UNLOCK" end
		return find(plot, "RollStation"), "ROLL"
	elseif t == "Roll" then
		local rolling = state.rollReadyAt - Workspace:GetServerTimeNow() > 0
		if find(plot, "OfferCrusher") and not rolling and #state.items < C.MaxInventory and cash >= C.Rarities[1].price then return pedestal(plot), "BUY" end
		return find(plot, "RollStation"), "ROLL"
	elseif t == "Production" then
		local cheapest = math.huge
		for _, id in { "Damage", "Speed", "Yield" } do cheapest = math.min(cheapest, C.globalCost(id, state.upgrades[id])) end
		if cash < cheapest then return earn(cheapest) end
		return find(plot, "ProductionStation"), "UPGRADE"
	elseif t == "LevelBay" then
		local best, cost = nil, math.huge
		for key, id in state.bays do
			for _, item in state.items do if item.id == id and item.cost < cost then best, cost = tonumber(key), item.cost end end
		end
		if not best then return emptyBay(), "PLACE" end
		if cash < cost then return earn(cost) end
		return bayModel(plot, best), "LEVEL UP"
	elseif t == "PlotUpgrade" then
		local cost = C.plotCost((state.plotLevel or 0) + 1) or 0
		local e = emptyBay()
		if e then
			local gt, gl, gh = getCrusher(plot)
			if gt then return gt, gl, gh end
			return e, "PLACE", "Fill every bay first."
		end
		if cash < cost then return earn(cost) end
		return find(plot, "PlotUpgradeStation"), "UPGRADE!"
	elseif t == "RewardsButton" or t == "BookButton" then
		return nil, nil, nil, hudButton(t)
	elseif t == "SmashButton" then
		return nil, nil, nil, hudButton("Smash")
	elseif t == "TurboStation" then
		return find(plot, "TurboStation"), "TURBO"
	elseif t == "GoldenToy" then
		local toy = plot:FindFirstChild("GoldenToy")
		if toy then return toy, "GRAB!" end
		return nil, nil, "Stay at your factory: the next golden toy lands soon!"
	end
	return nil
end

-- Next goal after the tutorial (Factory III+): (target, label over it, tag, title, counter, hint)
local function nextGoal(): (Instance?, string?, string, string, string, string)
	local plot = plotModel()
	local level = state.plotLevel or 0
	local name = C.PlotUpgrade.Names[level + 1] or "NEXT PLOT"
	local cap = C.bayCapacity(level)
	local cash = state.cash
	local tag = "NEXT GOAL · " .. name
	if state.unlocked < cap then
		local n = state.unlocked + 1 local price = C.BayCosts[n] or 0
		local counter = state.unlocked .. " / " .. cap
		if cash >= price and plot then return bayModel(plot, n), "UNLOCK", tag, "Unlock all bays", counter, "Unlock bay " .. n .. " for " .. Format.cash(price) .. "!" end
		return nil, nil, tag, "Unlock all bays", counter, "Bay " .. n .. " costs " .. Format.cash(price) .. ". Collect and sell scrap, level up your crushers!"
	end
	local filled = 0
	for i = 1, state.unlocked do if state.bays[tostring(i)] then filled += 1 end end
	if filled < state.unlocked then
		for i = 1, state.unlocked do
			if not state.bays[tostring(i)] then
				local gt, gl, gh
				if plot then gt, gl, gh = getCrusher(plot) end
				if gt then return gt, gl, tag, "Fill every bay", filled .. " / " .. state.unlocked, gh or "" end
				return plot and bayModel(plot, i), "PLACE", tag, "Fill every bay", filled .. " / " .. state.unlocked, "Roll, buy and place a crusher in every empty bay."
			end
		end
	end
	local cost = C.plotCost(level + 1) or 0
	local counter = Format.cash(cash) .. " / " .. Format.cash(cost)
	if cash >= cost and plot then return find(plot, "PlotUpgradeStation"), "UPGRADE!", tag, "Buy " .. name .. "!", counter, "Press UPGRADE on the green board." end
	return nil, nil, tag, "Save for " .. name, counter, "Level up your crushers to get there faster!"
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
local cached: { target: Instance?, text: string?, override: string?, ui: GuiObject?, padAt: CFrame?, padSize: number? } = {}
local nextLook = 0
local function look(target: Instance?, labelText: string?, override: string?, ui: GuiObject?)
	cached = { target = target, text = labelText, override = override, ui = ui }
	-- the floor disc: under the target's footprint
	if target and (target:IsA("Model") or target:IsA("BasePart")) then
		local cf, size
		if target:IsA("Model") then cf, size = target:GetBoundingBox() else cf, size = (target :: BasePart).CFrame, (target :: BasePart).Size end
		local d = math.clamp(math.max(size.X, size.Z) + 3, 6, 18)
		cached.padAt = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 0.08, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		cached.padSize = d
	end
end
-- draw the trail, outline, floor disc and HUD arrow for the cached target
local function guide(root: BasePart)
	local target = cached.target
	if target and not target:IsDescendantOf(Workspace) then target = nil end
	local top = target and topOf(target)
	path:update(root.Position, top, cached.text)
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 5)
	if top and target then
		if outline.Parent ~= target then outline.Parent = target end
		outline.Enabled = true
		outline.OutlineTransparency = 0.15 + 0.35 * pulse
	else outline.Enabled = false end
	if top and cached.padAt then
		local d = (cached.padSize or 8) * (1 + 0.05 * pulse)
		pad.Size = Vector3.new(0.12, d, d) pad.CFrame = cached.padAt pad.Transparency = 0.35 + 0.3 * pulse
	else pad.Transparency = 1 end
	local ui = cached.ui
	if ui and ui.Visible then
		uiArrow.Visible = true
		uiArrow.Position = UDim2.fromOffset(ui.AbsolutePosition.X + ui.AbsoluteSize.X / 2, ui.AbsolutePosition.Y + ui.AbsoluteSize.Y + 4 + 8 * math.sin(os.clock() * 6))
	else uiArrow.Visible = false end
end
local function hideGuide()
	path:update(Vector3.zero, nil)
	outline.Enabled = false pad.Transparency = 1 uiArrow.Visible = false
end
local function switch(to: string?)
	if mode == to then return end
	mode = to
	if to == nil then fadeOut() hideGuide() return end
	if to == "tutorial" then shown = state.tutorial paint(shown)
	elseif to == "goals" then goalShown = state.goal paintGoal(goalShown) end
	nextLook = 0
	fadeIn()
end

local lastPlace = 0
RunService.RenderStepped:Connect(function()
	if not state then return end
	-- 31 Oct: during a factory event the event's own core path takes over
	local eventOn = me:GetAttribute("FactoryEventRunning") == true
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if busy then
		-- mid-celebration: keep the trail moving, change nothing else
		if root and not eventOn and mode ~= nil then guide(root) else hideGuide() end
		return
	end
	local want: string? = nil
	if not eventOn and root then
		if STEPS[state.tutorial] then want = "tutorial"
		elseif state.goal ~= nil and GOALS[state.goal] then want = "goals" end
		-- 2 Nov (Willem): after the goals (Factory II bought) the guide is done for
		-- good; the old NEXT GOAL mode (nextGoal) is no longer shown
	end
	switch(want)
	if not want or not root then return end
	if os.clock() - lastPlace > 0.5 then lastPlace = os.clock() placeHeadline() end
	-- a step finished since the last frame (the state handler catches most)
	if want == "tutorial" and state.tutorial > shown then task.spawn(finishStep, shown, state.tutorial) return end
	if want == "goals" and state.goal > goalShown then task.spawn(finishGoal, goalShown, state.goal) return end
	if os.clock() >= nextLook then
		nextLook = os.clock() + 0.25
		if want == "tutorial" then
			local step = STEPS[state.tutorial]
			sameStep("t" .. state.tutorial)
			local t, l, o = goal()
			look(t, l, o)
			showHint(step.text, o)
		elseif want == "goals" then
			local g = GOALS[state.goal]
			sameStep("g" .. state.goal)
			local t, l, o, ui = goalTarget(g)
			look(t, l, o, ui)
			local text, color = goalReward(g)
			setSub(goalCounter(g), text, color)
			showHint(g.text, o)
		else
			local t, l, tg, ti, counter, h = nextGoal()
			sameStep("n" .. ti)
			look(t, l)
			setHeadline(tg, ti) setSub(counter, nil)
			showHint(h, nil)
		end
	end
	guide(root)
end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.tutorial) ~= "number" then return end
	local before = state and state.tutorial
	state = v
	if busy then return end
	if before ~= nil and mode == "tutorial" and v.tutorial > shown then
		task.spawn(finishStep, shown, v.tutorial)
	elseif mode == "goals" and v.goal and v.goal > goalShown and GOALS[goalShown] then
		task.spawn(finishGoal, goalShown, v.goal)
	end
end)
