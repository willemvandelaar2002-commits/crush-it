--!strict
-- Crush It HUD: cash, the object on your press (name + HP bar), a big CRUSH
-- button (hold it, or hold F / gamepad R2), and the upgrade cards (Power,
-- Speed, Value, Size). Plus the feel: press sounds, sparks, camera shake on
-- your own press and floating "+$X" when something gets flattened.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Objects = require(ReplicatedStorage.Shared.Objects)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)

local player = Players.LocalPlayer
local CrushRemote = Net.event("Crush")
local BuyRemote = Net.event("BuyUpgrade")

local FONT = Enum.Font.FredokaOne
local DARK = Color3.fromRGB(28, 30, 38)
local GREEN = Color3.fromRGB(80, 200, 110)
local RED = Color3.fromRGB(230, 80, 70)
local GREY = Color3.fromRGB(110, 112, 120)
local GOLD = Color3.fromRGB(255, 200, 50)

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local i = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(i :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = i
	end
	if props.Parent then
		i.Parent = props.Parent
	end
	return i
end

local function corner(r: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(t: number): UIStroke
	return make("UIStroke", { Thickness = t, Color = Color3.new(0, 0, 0), Transparency = 0.2 })
end

local gui = make("ScreenGui", { Name = "CrushHud", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- Cash: big in the bottom-left corner like Destroy a Vault (top centre on
-- phones, where the thumbstick lives bottom-left). The goal bar is top centre
-- (Goal.client.luau).
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local CASH_SIZE = if TOUCH then Vector2.new(180, 40) else Vector2.new(320, 64)
local cashLabel = make("TextLabel", {
	Name = "Cash",
	AnchorPoint = if TOUCH then Vector2.new(0.5, 0) else Vector2.new(0, 1),
	Position = if TOUCH then UDim2.new(0.5, 0, 0, 74) else UDim2.new(0, 84, 1, -42),
	Size = UDim2.fromOffset(CASH_SIZE.X, CASH_SIZE.Y), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextXAlignment = if TOUCH then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(110, 255, 90), Text = "$0", Parent = gui,
}, { make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(20, 40, 15) }) })
if not TOUCH then
	local cashIcon = make("Frame", {
		Name = "CashIcon", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -40), Size = UDim2.fromOffset(66, 66),
		BackgroundTransparency = 1, Rotation = -10, Parent = gui,
	})
	Style.image(cashIcon, Icons.Cash)
end

local multLabel = make("TextLabel", {
	AnchorPoint = if TOUCH then Vector2.new(0, 0.5) else Vector2.new(0, 1),
	Position = if TOUCH then UDim2.new(1, 4, 0.5, 0) else UDim2.new(0, 2, 0, 2),
	Size = UDim2.fromOffset(if TOUCH then 52 else 110, 24),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = GOLD, Text = "", Parent = cashLabel,
}, { stroke(2) })

-- Friend boost line under the cash ("Friend Boost: 20%  [+]"); the + opens
-- Roblox's invite dialog. The server sets FriendBoost (server/FriendBoost.luau).
local friendRow = make("Frame", {
	Name = "FriendBoost", AnchorPoint = Vector2.new(0, 1),
	Position = if TOUCH then UDim2.new(0.5, -96, 0, 145) else UDim2.new(0, 14, 1, -10), Size = UDim2.fromOffset(if TOUCH then 192 else 260, if TOUCH then 26 else 30),
	BackgroundTransparency = 1, Parent = gui,
})
local friendLabel = make("TextLabel", {
	Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Friend Boost: 0%", Parent = friendRow,
})
Style.text(friendLabel, 2.5)
local inviteButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(if TOUCH then 24 else 30, if TOUCH then 24 else 30),
	Text = "+", TextScaled = true, Parent = friendRow,
})
Style.button(inviteButton)
local function refreshFriends()
	local boost = (player:GetAttribute("FriendBoost") :: number?) or 0
	friendLabel.Text = string.format("Friend Boost: %d%%", math.floor(boost * 100 + 0.5))
	friendLabel.TextColor3 = if boost > 0 then Color3.fromRGB(120, 255, 120) else Color3.new(1, 1, 1)
	inviteButton.Position = UDim2.new(0, friendLabel.TextBounds.X + 8, 0.5, 0)
	inviteButton.AnchorPoint = Vector2.new(0, 0.5)
end
player:GetAttributeChangedSignal("FriendBoost"):Connect(refreshFriends)
friendLabel:GetPropertyChangedSignal("TextBounds"):Connect(refreshFriends)
refreshFriends()
inviteButton.Activated:Connect(function()
	local SocialService = game:GetService("SocialService")
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if ok and can then
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	end
end)

-- Object + HP bar (under the cash) -------------------------------------------
local objFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, if TOUCH then 154 else 122), Size = UDim2.fromOffset(if TOUCH then 220 else 280, 48),
	BackgroundTransparency = 1, Parent = gui,
})
local objName = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = objFrame,
}, { stroke(2) })
local hpBack = make("Frame", {
	Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = DARK, Parent = objFrame,
}, { corner(8), stroke(2) })
local hpFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = RED, Parent = hpBack }, { corner(8) })
hpFill.BackgroundColor3 = Color3.new(1, 1, 1)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 149, 130), RED), Parent = hpFill })
Style.studsImage(hpFill, 18, 0.85)

-- CRUSH button (bottom right) -------------------------------------------------
local crushButton = make("TextButton", {
	Name = "CrushButton",
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(150, 150),
	BackgroundColor3 = RED, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "CRUSH",
	AutoButtonColor = false, Parent = gui,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 5, Color = Color3.fromRGB(120, 20, 20) }), make("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }) })
-- Solid red with white text (a Style.button gradient would tint the text too); press feedback only.
Style.feedback(crushButton)
local keyHint = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(150, 18),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "hold  [F]",
	Parent = crushButton,
}, { stroke(1.5) })
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	keyHint.Visible = false
	crushButton.Position = UDim2.new(1, -16, 1, -110)
	crushButton.Size = UDim2.fromOffset(120, 120)
end

-- Holding ---------------------------------------------------------------------
local holds = 0 -- button / key / gamepad can all hold at once
local function setHold(delta: number)
	if Style.hasModal() then delta = 0; holds = 0 end
	holds = math.max(0, holds + delta)
	crushButton.BackgroundColor3 = if holds > 0 then Color3.fromRGB(190, 50, 45) else RED
end
crushButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setHold(1)
		local c
		c = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				c:Disconnect()
				setHold(-1)
			end
		end)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
		setHold(1)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
		setHold(-1)
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	holds = 0
	setHold(0)
end)
task.spawn(function()
	while true do
		if Style.hasModal() then setHold(0) end
		if holds > 0 then
			CrushRemote:FireServer() -- the server enforces the Speed cooldown
		end
		task.wait(0.1)
	end
end)

-- Upgrades (left side) ------------------------------------------------------
local panel = make("ScrollingFrame", {
	Name = "Upgrades",
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(300, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BackgroundTransparency = 1,
	BorderSizePixel = 0, Parent = gui,
}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
Style.scroll(panel)
local panelScale = make("UIScale", { Parent = panel })
local function fitPanel()
	local viewport = Workspace.CurrentCamera.ViewportSize
	panelScale.Scale = if Style.compact() then 0.64 else math.clamp((viewport.Y - 250) / 444, 0.65, 0.95)
	panel.Position = UDim2.new(0, 10, 0.5, 18)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Size = UDim2.fromOffset(316, 444)
	-- On landscape phones the rows scroll in the space above the thumbstick.
	if TOUCH then
		local top = if viewport.Y > viewport.X then 246 else 88
		local height = math.clamp(viewport.Y - top - 170, 72, 444 * panelScale.Scale)
		panel.Position = UDim2.fromOffset(10, top)
		panel.AnchorPoint = Vector2.zero
		panel.Size = UDim2.fromOffset(316, height / panelScale.Scale)
	end
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
fitPanel()
-- Hidden since 20 Oct: the same upgrades are walk-on pads on the plot (Pads.luau) and
-- on the board next to the press. Kept (not deleted) so the board code keeps working.
panel.Visible = false

type Card = { frame: Frame, title: TextLabel, info: TextLabel, buy: TextButton, id: string }
local cards: { Card } = {}

-- Upgrade rows in the "Destroy a Vault" style: a coloured row with an icon,
-- the name, what the next level does and a big green price button. The same
-- rows are used in the HUD panel and on the board next to your press.
-- `image` (an uploaded icon) is used instead of the emoji `icon` when set.
local ROW_STYLE: { [string]: { a: Color3, b: Color3, icon: string, image: string? } } = {
	-- two-colour gradients like Destroy a Vault's boards (pink>purple, cyan>blue ...)
	Power = { a = Color3.fromRGB(255, 95, 80), b = Color3.fromRGB(200, 30, 90), icon = "💥", image = Icons.Power },
	Speed = { a = Color3.fromRGB(70, 220, 255), b = Color3.fromRGB(40, 90, 230), icon = "⚡", image = Icons.Speed },
	Value = { a = Color3.fromRGB(255, 225, 70), b = Color3.fromRGB(240, 140, 20), icon = "💰", image = Icons.Value },
	Size = { a = Color3.fromRGB(240, 90, 255), b = Color3.fromRGB(120, 50, 220), icon = "🔨", image = Icons.Press },
	Rebirth = { a = Color3.fromRGB(255, 170, 60), b = Color3.fromRGB(230, 70, 40), icon = "🔄", image = Icons.Rebirth },
}

local function studsOverlay(parent: GuiObject, tile: number, transparency: number)
	Style.studsImage(parent, tile, transparency)
end

local function makeCard(id: string, order: number, parent: Instance?): Card
	local style = ROW_STYLE[id] or { a = DARK, b = DARK, icon = "" }
	local frame = make("Frame", {
		Name = "Card_" .. id, Size = UDim2.fromOffset(300, 80), LayoutOrder = order, Parent = parent or panel,
	})
	Style.panel(frame, style.a, style.b)
	if style.image then
		make("ImageLabel", {
			Name = "Icon", Position = UDim2.fromOffset(4, 10), Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 1,
			Image = style.image, ScaleType = Enum.ScaleType.Fit, Parent = frame,
		})
	else
		make("TextLabel", {
			Position = UDim2.fromOffset(4, 8), Size = UDim2.fromOffset(52, 58), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
			Text = style.icon, Parent = frame,
		})
	end
	local title = make("TextLabel", {
		Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -72, 0, 27), BackgroundTransparency = 1, TextScaled = true, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
	})
	Style.text(title, 2.5)
	local info = make("TextLabel", {
		Position = UDim2.fromOffset(62, 42), Size = UDim2.new(1, -164, 0, 25), BackgroundTransparency = 1, TextScaled = true, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
	})
	Style.text(info, 2)
	info.TextColor3 = Color3.fromRGB(255, 250, 200)
	local buy = make("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(88, 36), TextScaled = true, Parent = frame,
	}, { make("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7) }) })
	Style.button(buy)
	local confirmUntil = 0
	local function onBuy()
		if not buy.Active then return end
		if id == "Rebirth" then
			-- Two taps: the first one asks "SURE?".
			if os.clock() > confirmUntil then
				confirmUntil = os.clock() + 3
				buy.Text = "SURE?"
				task.delay(3, function()
					if os.clock() >= confirmUntil then
						buy.Text = ""
						buy:SetAttribute("Refresh", os.clock())
					end
				end)
				return
			end
			confirmUntil = 0
			buy.Text = ""
		end
		BuyRemote:FireServer(id)
	end
	buy.Activated:Connect(onBuy)
	if TOUCH and not parent then
		-- The whole HUD row is a comfortable tap target; the board keeps its price button.
		local tap = make("TextButton", { Name = "TapRow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, Selectable = false, ZIndex = 2, Parent = frame })
		tap.Activated:Connect(onBuy)
	end
	local card = { frame = frame, title = title, info = info, buy = buy, id = id }
	table.insert(cards, card)
	return card
end

for i, u in Config.Upgrades do
	makeCard(u.id, i)
end
makeCard("Size", #Config.Upgrades + 1)
local rebirthCard = makeCard("Rebirth", #Config.Upgrades + 2)

local function fmtEffect(id: string, v: number): string
	if id == "Power" then
		return (if v < 100 then string.format("%.1f", v) else Format.compact(v)) .. " dmg"
	elseif id == "Speed" then
		return string.format("%.2fs", v)
	else
		return string.format("x%.1f", v)
	end
end

local function refresh()
	local cash = (player:GetAttribute("Cash") :: number?) or 0
	local tier = (player:GetAttribute("Tier") :: number?) or 1
	for _, card in cards do
		local cost: number?
		if card.id == "Rebirth" then
			local r = (player:GetAttribute("Rebirths") :: number?) or 0
			local need = Config.Rebirth.RequiredTier(r)
			card.title.Text = "Rebirth" .. (if r > 0 then "  (" .. r .. ")" else "")
			if card.buy.Text == "SURE?" then
				continue
			end
			if tier >= need then
				card.info.Text = string.format("Cash x%.1f > x%.1f", Config.rebirthMult(r), Config.rebirthMult(r + 1))
				card.buy.Text = "REBIRTH"
				Style.setButtonColor(card.buy, GOLD)
			else
				card.info.Text = "Reach the " .. Config.Objects[need].name
				card.buy.Text = "LOCKED"
				Style.setButtonColor(card.buy, GREY)
			end
			continue
		elseif card.id == "Size" then
			local maxed = tier >= Config.MaxTier
			card.title.Text = "Bigger Press"
			card.info.Text = if maxed then "Biggest press!" else "Next: " .. Config.Objects[tier + 1].name
			cost = if maxed then nil else Config.SizeCost(tier)
		else
			local u
			for _, x in Config.Upgrades do
				if x.id == card.id then
					u = x
				end
			end
			local lv = (player:GetAttribute(card.id .. "Lv") :: number?) or 0
			card.title.Text = u.title .. "  Lv " .. lv
			if lv >= u.max then
				card.info.Text = fmtEffect(u.id, u.effect(lv)) .. " (max)"
				cost = nil
			else
				local now, nxt = fmtEffect(u.id, u.effect(lv)), fmtEffect(u.id, u.effect(lv + 1))
				card.info.Text = string.gsub(now, " dmg", "") .. " > " .. nxt
				cost = u.cost(lv)
			end
		end
		if cost then
			card.buy.Text = Format.cash(cost)
			Style.setButtonColor(card.buy, if cash >= cost then Style.GREEN else Color3.fromRGB(110, 130, 110))
			card.buy.Active = true
		else
			card.buy.Text = "MAX"
			Style.setButtonColor(card.buy, GREY)
			card.buy.Active = false
		end
	end
	local hp = (player:GetAttribute("Hp") :: number?) or 0
	local maxHp = (player:GetAttribute("MaxHp") :: number?) or 1
	local variant = (player:GetAttribute("ObjVariant") :: string?) or "Normal"
	local vdef = Config.VariantById[variant]
	objName.Text = (if variant ~= "Normal" then string.upper(variant) .. " " else "") .. ((player:GetAttribute("ObjName") :: string?) or "") .. "  " .. Format.compact(math.ceil(hp)) .. " HP"
	objName.TextColor3 = if vdef and vdef.text then vdef.text else Color3.new(1, 1, 1)
	local mult = (player:GetAttribute("CashMult") :: number?) or 1
	multLabel.Text = if mult > 1.001 then string.format("x%.2f", mult) else ""
	TweenService:Create(hpFill, TweenInfo.new(0.12), { Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1) }):Play()
end

for _, name in { "Cash", "Tier", "PowerLv", "SpeedLv", "ValueLv", "Hp", "MaxHp", "ObjName", "ObjVariant", "Rebirths", "CashMult" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
rebirthCard.buy:GetAttributeChangedSignal("Refresh"):Connect(refresh)

-- Upgrade board next to your press (Plots builds the board; the clickable
-- rows live in a SurfaceGui here, adorned to it, so only you use yours).
task.spawn(function()
	while not player:GetAttribute("Plot") do
		player:GetAttributeChangedSignal("Plot"):Wait()
	end
	local plots = Workspace:WaitForChild("Plots")
	local plotModel = plots:WaitForChild("Plot" .. tostring(player:GetAttribute("Plot")))
	local boardModel = plotModel:WaitForChild("Board", 30)
	local boardPart = boardModel and boardModel:WaitForChild("UpgradeBoard", 30) :: BasePart?
	if not boardPart then
		return
	end
	local surface = make("SurfaceGui", {
		Name = "UpgradeBoardGui", Adornee = boardPart, Face = Enum.NormalId.Back, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 30, ZOffset = 1, LightInfluence = 0, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player.PlayerGui,
	})
	local bg = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(40, 46, 60), Parent = surface }, { corner(16) })
	studsOverlay(bg, 40, 0.45)
	local list = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 432), BackgroundTransparency = 1, Parent = bg,
	}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local listScale = make("UIScale", { Parent = list })
	local function fit()
		-- fill the board's width
		local size = surface.AbsoluteSize
		listScale.Scale = math.min((size.X * 0.94) / 300, (size.Y * 0.95) / 432)
	end
	surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	for i, u in Config.Upgrades do
		makeCard(u.id, i, list)
	end
	makeCard("Size", #Config.Upgrades + 1, list)
	local boardRebirth = makeCard("Rebirth", #Config.Upgrades + 2, list)
	boardRebirth.buy:GetAttributeChangedSignal("Refresh"):Connect(refresh)
	refresh()
end)

-- Smooth cash display; purchases snap down so the visible balance never lags a spend.
local displayedCash = make("NumberValue", { Value = (player:GetAttribute("Cash") :: number?) or 0, Parent = gui })
local cashTween: Tween? = nil
displayedCash.Changed:Connect(function(value)
	cashLabel.Text = Format.cash(math.floor(value + 0.5))
end)
cashLabel.Text = Format.cash(displayedCash.Value)
local lastCash = (player:GetAttribute("Cash") :: number?) or 0
local cashPop = make("TextLabel", {
	Name = "CashGain", AnchorPoint = if TOUCH then Vector2.new(1, 0.5) else Vector2.new(0, 0.5),
	Position = if TOUCH then UDim2.new(0, -8, 0.5, 0) else UDim2.new(0, cashLabel.TextBounds.X + 90, 0.5, 0),
	Size = UDim2.fromOffset(if TOUCH then 72 else 160, if TOUCH then 22 else 28),
	BackgroundTransparency = 1, TextScaled = true, Text = "", Visible = false, ZIndex = 3, Parent = cashLabel,
})
Style.text(cashPop, 2)
cashPop.TextColor3 = Color3.fromRGB(169, 255, 117)
local popToken = 0
player:GetAttributeChangedSignal("Cash"):Connect(function()
	local cash = (player:GetAttribute("Cash") :: number?) or 0
	if cashTween then cashTween:Cancel() end
	if cash > lastCash then
		local tween = TweenService:Create(displayedCash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Value = cash })
		cashTween = tween
		tween:Play()
	else
		displayedCash.Value = cash
	end
	if cash > lastCash then
		popToken += 1
		local token = popToken
		cashPop.Text = "+" .. Format.cash(cash - lastCash)
		if not TOUCH then
			-- just right of the (new) cash text, on the same line
			cashPop.Position = UDim2.new(0, Format.cash(cash):len() * CASH_SIZE.Y * 0.5 + 12, 0.5, 0)
		end
		cashPop.Visible = true
		task.delay(0.9, function() if token == popToken then cashPop.Visible = false end end)
	end
	lastCash = cash
end)

-- Notices -------------------------------------------------------------------
local noticeLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, if TOUCH then 205 else 176), Size = UDim2.new(0.65, 0, 0, 30),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(255, 220, 90), Text = "",
	TextTransparency = 1, Parent = gui,
}, { stroke(2) })
local noticeStroke = noticeLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
local noticeToken = 0
Net.event("Notice").OnClientEvent:Connect(function(msg)
	noticeToken += 1
	local token = noticeToken
	gui:SetAttribute("NoticeActive", true)
	noticeLabel.Text = msg.text
	noticeLabel.TextTransparency = 0
	noticeStroke.Transparency = 0.2
	task.delay(1.5, function()
		if token ~= noticeToken then return end
		gui:SetAttribute("NoticeActive", false)
		TweenService:Create(noticeLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(noticeStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end)

-- Effects -------------------------------------------------------------------
local fxFolder = Instance.new("Folder")
fxFolder.Name = "CrushFx"
fxFolder.Parent = Workspace

local function sound(id: string, pos: Vector3, volume: number, pitch: number): Sound
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.RollOffMaxDistance = 200
	s.Parent = anchor
	s:Play()
	Debris:AddItem(anchor, 6)
	return s
end

-- A sound from Config.Sounds by name.
local function sfx(key: string, pos: Vector3, volume: number, pitch: number): Sound?
	local id = Config.Sounds[key]
	if not id then
		return nil
	end
	return sound("rbxassetid://" .. id, pos, volume, pitch)
end

task.spawn(function()
	local list = {}
	for _, id in Config.Sounds do
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. id
		table.insert(list, s)
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(list)
	end)
end)

local function burst(pos: Vector3, color: Color3, count: number, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size, 0)
	e.Lifetime = NumberRange.new(0.3, 0.7)
	e.Speed = NumberRange.new(size * 8, size * 16)
	e.SpreadAngle = Vector2.new(80, 80)
	e.Acceleration = Vector3.new(0, -60, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = anchor
	e:Emit(count)
	Debris:AddItem(anchor, 1.5)
end

type EmitOpts = {
	color: ColorSequence,
	count: number,
	size: NumberSequence,
	lifetime: NumberRange,
	speed: NumberRange,
	spread: number?,
	gravity: number?,
	light: number?,
	transparency: NumberSequence?,
	drag: number?,
	rot: boolean?,
}

local function emit(pos: Vector3, o: EmitOpts)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Color = o.color
	e.Size = o.size
	e.Lifetime = o.lifetime
	e.Speed = o.speed
	local spread = o.spread or 80
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Acceleration = Vector3.new(0, -(o.gravity or 60), 0)
	e.LightEmission = o.light or 0
	e.Transparency = o.transparency or NumberSequence.new(0)
	e.Drag = o.drag or 0
	if o.rot then
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-120, 120)
	end
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = anchor
	e:Emit(o.count)
	Debris:AddItem(anchor, o.lifetime.Max + 0.5)
end

local shake = 0
RunService:BindToRenderStep("CrushShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake > 0.01 then
		local cam = Workspace.CurrentCamera
		local r = shake
		cam.CFrame = cam.CFrame * CFrame.Angles((math.random() - 0.5) * r * 0.05, (math.random() - 0.5) * r * 0.05, 0)
		shake = math.max(0, shake - dt * 4)
	end
end)

local function floatText(pos: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = fxFolder
	local bb = make("BillboardGui", { Size = UDim2.fromOffset(200, 60), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 2, 0), Parent = anchor })
	local label = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = color, Text = text, Parent = bb }, { stroke(3) })
	TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), { TextTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.3)
end


-- Pieces of the object fly off on the final hit (client-only, physics, short-lived).
local function debris(pos: Vector3, tier: number, count: number, shards: boolean?)
	local def = Config.Objects[tier]
	local unit = math.clamp(def.width / 6, 0.3, 5)
	for _ = 1, count do
		local spec = def.parts[math.random(1, #def.parts)]
		local p = Instance.new("Part")
		if shards then
			p.Size = Vector3.new(unit * (0.3 + math.random() * 0.4), 0.08, unit * (0.2 + math.random() * 0.3))
			p.Color = Color3.fromRGB(200, 235, 255)
			p.Material = Enum.Material.Glass
			p.Transparency = 0.3
			p.Reflectance = 0.3
		else
			p.Size = Vector3.new(unit * (0.3 + math.random() * 0.5), unit * (0.15 + math.random() * 0.25), unit * (0.3 + math.random() * 0.5))
			p.Color = spec.color
			p.Material = spec.material or Enum.Material.SmoothPlastic
		end
		p.CanCollide = true
		p.CanQuery = false
		p.CanTouch = false
		p.CollisionGroup = "Default"
		p.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * def.width * 0.6, unit * 0.3, (math.random() - 0.5) * def.width * 0.6))
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = fxFolder
		local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
		p.AssemblyLinearVelocity = dir * (12 + math.random() * 18) * math.sqrt(unit) + Vector3.new(0, 25 + math.random() * 20, 0) * math.sqrt(unit)
		p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		task.delay(1.2 + math.random() * 0.4, function()
			TweenService:Create(p, TweenInfo.new(0.3), { Transparency = 1, Size = p.Size * 0.3 }):Play()
		end)
		Debris:AddItem(p, 2)
	end
end

-- A flat shockwave ring on the bed.
local function shockwave(pos: Vector3, radius: number, color: Color3)
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = fxFolder
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.5)
end

-- Crush styles ----------------------------------------------------------------
-- Each Config.Kinds entry names a hitFx / crushFx drawn here.
-- (pos = top of the squashed object, def = the object, s = size scale, big = final hit)

local function seq(...: Color3): ColorSequence
	local c = { ... }
	if #c == 1 then
		return ColorSequence.new(c[1])
	end
	return ColorSequence.new(c[1], c[2])
end

local SPARK_YELLOW = Color3.fromRGB(255, 230, 120)
local SPARK_ORANGE = Color3.fromRGB(255, 120, 30)

local styles: { [string]: (pos: Vector3, def: any, s: number, big: boolean) -> () } = {}

styles.droplets = function(pos, def, s, big)
	emit(pos, {
		color = seq(def.parts[1].color), count = if big then 40 else 10,
		size = NumberSequence.new(0.35 * s, 0.05), lifetime = NumberRange.new(0.4, 0.8),
		speed = NumberRange.new(10 * s, 22 * s), spread = 75, gravity = 90,
	})
end

styles.splat = function(pos, def, s, big)
	styles.droplets(pos, def, s, big)
	local disc = Instance.new("Part")
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch = true, false, false, false
	disc.Shape = Enum.PartType.Cylinder
	disc.Color = def.parts[1].color
	disc.Material = Enum.Material.SmoothPlastic
	disc.Size = Vector3.new(0.1, def.width * 0.6, def.width * 0.6)
	disc.CFrame = CFrame.new(pos.X, pos.Y - 0.05, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Parent = fxFolder
	TweenService:Create(disc, TweenInfo.new(0.15), { Size = Vector3.new(0.1, def.width * 1.8, def.width * 1.6) }):Play()
	TweenService:Create(disc, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.9), { Transparency = 1 }):Play()
	Debris:AddItem(disc, 1.6)
end

styles.fluff = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(255, 250, 240), def.parts[1].color), count = if big then 35 else 8,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3 * s), NumberSequenceKeypoint.new(1, 0.7 * s) }),
		lifetime = NumberRange.new(1.0, 1.8), speed = NumberRange.new(6 * s, 14 * s), spread = 90, gravity = 4,
		drag = 3, rot = true, transparency = NumberSequence.new(0.1, 1),
	})
end

styles.zap = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(220, 245, 255), Color3.fromRGB(80, 170, 255)), count = if big then 30 else 12,
		size = NumberSequence.new(0.18 * s, 0), lifetime = NumberRange.new(0.15, 0.35),
		speed = NumberRange.new(20 * s, 40 * s), spread = 100, gravity = 30, light = 1,
	})
end

styles.shards = function(pos, def, s, big)
	styles.zap(pos, def, s, true)
	debris(pos, table.find(Config.Objects, def) or 1, 14, true)
end

styles.sparks = function(pos, def, s, big)
	emit(pos, {
		color = seq(SPARK_YELLOW, SPARK_ORANGE), count = if big then 60 else 16,
		size = NumberSequence.new(0.2 * s, 0), lifetime = NumberRange.new(0.25, 0.6),
		speed = NumberRange.new(25 * s, 50 * s), spread = 85, gravity = 120, light = 1,
	})
	if big then
		emit(pos, {
			color = seq(Color3.fromRGB(90, 90, 95)), count = 14,
			size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 * s), NumberSequenceKeypoint.new(1, 3 * s) }),
			lifetime = NumberRange.new(0.8, 1.4), speed = NumberRange.new(4 * s, 9 * s), spread = 90, gravity = -6,
			drag = 2, rot = true, transparency = NumberSequence.new(0.3, 1),
		})
	end
end

styles.dust = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(200, 185, 160), Color3.fromRGB(150, 140, 130)), count = if big then 30 else 8,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * s), NumberSequenceKeypoint.new(1, 2.6 * s) }),
		lifetime = NumberRange.new(0.8, 1.6), speed = NumberRange.new(5 * s, 14 * s), spread = 90, gravity = -2,
		drag = 2.5, rot = true, transparency = NumberSequence.new(0.2, 1),
	})
end

styles.fire = function(pos, def, s, big)
	emit(pos, {
		color = seq(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 60, 20)), count = if big then 50 else 12,
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * s), NumberSequenceKeypoint.new(1, 0) }),
		lifetime = NumberRange.new(0.3, 0.7), speed = NumberRange.new(10 * s, 25 * s), spread = 90, gravity = -10,
		light = 1, rot = true,
	})
end

styles.explosion = function(pos, def, s, big)
	styles.fire(pos, def, s * 1.6, true)
	styles.dust(pos, def, s * 1.4, true)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = def.width * 0.8
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Parent = fxFolder
end

local lastHiss = 0

Net.event("Hit").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local def = Config.Objects[msg.tier]
	local kind = Config.Kinds[def.kind]
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	local v = if mine then 1 else 0.3
	sfx("Thud", msg.position, 0.45 * v, 1.05 - scale * 0.08 + math.random() * 0.1)
	sfx(kind.hitSound, msg.position, 0.5 * v, 0.9 + math.random() * 0.2)
	local style = styles[kind.hitFx]
	if style then
		style(msg.position, def, scale, false)
	end
	if mine then
		shake = math.min(1, shake + 0.35)
		if os.clock() - lastHiss > 0.7 then
			lastHiss = os.clock()
			task.delay(0.12, function()
				local h = sfx("Hiss", msg.position + Vector3.new(0, Config.pressWidth(msg.tier), 0), 0.18, 1.25)
				if h then
					task.delay(0.35, function()
						TweenService:Create(h, TweenInfo.new(0.3), { Volume = 0 }):Play()
					end)
				end
			end)
		end
	end
end)

Net.event("Crushed").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local def = Config.Objects[msg.tier]
	local kind = Config.Kinds[def.kind]
	local scale = math.clamp(Config.pressWidth(msg.tier) / 10, 0.6, 4)
	local v = if mine then 1 else 0.3
	local style = styles[kind.crushFx]
	if style then
		style(msg.position, def, scale, true)
	end
	if kind.crushFx ~= "shards" then
		debris(msg.position, msg.tier, if mine then 12 else 5)
	end
	shockwave(msg.position, Config.pressWidth(msg.tier) * 0.9, Color3.fromRGB(255, 230, 160))
	sfx("Thud", msg.position, 0.8 * v, 0.6)
	sfx(kind.crushSound, msg.position, 0.8 * v, 1)
	local vdef = Config.VariantById[msg.variant or "Normal"]
	if vdef and vdef.tint then
		emit(msg.position, {
			color = seq(vdef.text, Color3.new(1, 1, 1)), count = if mine then 50 else 15,
			size = NumberSequence.new(0.6 * scale, 0), lifetime = NumberRange.new(0.6, 1.2),
			speed = NumberRange.new(15 * scale, 35 * scale), spread = 90, gravity = 25, light = 1, rot = true,
		})
		shockwave(msg.position, Config.pressWidth(msg.tier) * 1.4, vdef.text)
	end
	if mine then
		sfx("Coin", msg.position, 0.5, 1)
		if vdef and vdef.tint then
			sfx("Coin", msg.position, 0.6, 1.3)
			sfx("LevelUp", msg.position, 0.5, 1.2)
			floatText(msg.position + Vector3.new(0, 2, 0), string.upper(vdef.id) .. "!", vdef.text)
		end
		floatText(msg.position, "+" .. Format.cash(msg.value), GREEN)
		shake = 1
	end
end)

-- Bigger press: banner, confetti and a rising whoosh.
local banner = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(420, 110),
	BackgroundTransparency = 1, Visible = false, Parent = gui,
})
local bannerScale = make("UIScale", { Scale = 1, Parent = banner })
local bannerTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0.55, 0), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 210, 60), Text = "BIGGER PRESS!", Parent = banner,
}, { stroke(4) })
local bannerSub = make("TextLabel", {
	Position = UDim2.fromScale(0, 0.6), Size = UDim2.new(1, 0, 0.35, 0), BackgroundTransparency = 1, Font = FONT,
	TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = banner,
}, { stroke(3) })
local bannerToken = 0

local function showBanner(title: string, sub: string, color: Color3)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerTitle.TextColor3 = color
	bannerSub.Text = sub
	banner.Visible = true
	bannerScale.Scale = 0.2
	TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.4, function()
		if token ~= bannerToken then
			return
		end
		local t = TweenService:Create(bannerScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

Net.event("Upgraded").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	local W = Config.pressWidth(msg.tier)
	sound("rbxasset://sounds/collide.wav", msg.position, if mine then 0.8 else 0.3, 0.3) -- low rumble as it rises
	task.delay(0.9, function()
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(255, 80, 80), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(80, 200, 255), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		burst(msg.position + Vector3.new(0, W * 0.8, 0), Color3.fromRGB(255, 220, 60), if mine then 25 else 8, 0.4 * math.clamp(W / 10, 0.6, 4))
		shockwave(msg.position, W * 1.2, Color3.fromRGB(255, 210, 60))
		if mine then
			sfx("LevelUp", msg.position, 0.7, 1)
			shake = 0.8
		end
	end)
	if mine then
		showBanner(string.upper(Config.Presses[msg.tier].name) .. "!", "Now crushing: " .. Config.Objects[msg.tier].name, Config.Presses[msg.tier].accent)
	end
end)

-- Rebirth: banner, gold burst ---------------------------------------------------
Net.event("Rebirthed").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	task.delay(0.9, function()
		emit(msg.position + Vector3.new(0, 6, 0), {
			color = seq(GOLD, Color3.new(1, 1, 1)), count = if mine then 80 else 20,
			size = NumberSequence.new(0.8, 0), lifetime = NumberRange.new(0.8, 1.6),
			speed = NumberRange.new(20, 45), spread = 180, gravity = 20, light = 1, rot = true,
		})
		shockwave(msg.position, 30, GOLD)
		if mine then
			sfx("LevelUp", msg.position, 0.8, 0.9)
			shake = 1
		end
	end)
	if mine then
		showBanner("REBIRTH " .. msg.rebirths .. "!", string.format("All cash x%.2f forever", msg.mult), GOLD)
	end
end)

-- Collection book -----------------------------------------------------------
-- A grid of every object: a 3D preview (black until you've crushed one), and
-- how many Normal / Golden / Diamond ones you've crushed. Each first crush of
-- a version adds a permanent cash bonus (Config.CollectionBonus).

local collection: { [string]: { [string]: number } } = {}

local bookButton, bookDot = Style.iconButton(gui, {
	name = "BookButton", icon = "📖", image = Icons.Book, label = "BOOK", a = Color3.fromRGB(90, 160, 255), b = Color3.fromRGB(60, 70, 220),
})
Style.placeHudButton(bookButton, 0)
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() Style.placeHudButton(bookButton, 0) end)

local book = make("Frame", {
	Name = "Book", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0.8, 0),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.05, Visible = false, ZIndex = 10, Parent = gui,
}, { make("UISizeConstraint", { MaxSize = Vector2.new(820, 560) }) })
Style.panel(book, Color3.fromRGB(70, 145, 249), Color3.fromRGB(43, 62, 154))
Style.modal(book)
local bookTitle = make("TextLabel", {
	Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -80, 0, 34), BackgroundTransparency = 1, Font = FONT,
	TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Text = "Collection", ZIndex = 11, Parent = book,
})
local bookSub = make("TextLabel", {
	Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1, Font = FONT,
	TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(225, 240, 255), ZIndex = 11, Parent = book,
	Text = string.format("First crush of each version: Normal +%d%%, Golden +%d%%, Diamond +%d%% cash forever",
		Config.CollectionBonus.Normal * 100, Config.CollectionBonus.Golden * 100, Config.CollectionBonus.Diamond * 100),
})
Style.text(bookTitle, 2.5)
Style.text(bookSub, 1)
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = RED,
	Font = FONT, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "X", ZIndex = 11, Parent = book,
})
Style.button(closeButton, RED)
local grid = make("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 102), Size = UDim2.new(1, -24, 1, -114), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = book,
}, { make("UIGridLayout", { CellSize = UDim2.fromOffset(140, 170), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
Style.scroll(grid)
Style.grid(grid, 130, 170)

type BookCell = { frame: Frame, view: ViewportFrame, name: TextLabel, counts: { [string]: TextLabel }, shown: string? }
local cells: { BookCell } = {}

for tier, def in Config.Objects do
	local frame = make("Frame", { LayoutOrder = tier, ZIndex = 12, Parent = grid })
	Style.panel(frame, Color3.fromRGB(93, 134, 214), Color3.fromRGB(46, 64, 126))
	local view = make("ViewportFrame", {
		Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 100), BackgroundColor3 = Color3.fromRGB(70, 75, 95),
		Ambient = Color3.fromRGB(170, 170, 180), LightDirection = Vector3.new(-1, -2, -1), ZIndex = 12, Parent = frame,
	}, { corner(8) })
	local name = make("TextLabel", {
		Position = UDim2.fromOffset(6, 108), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Font = FONT, TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1), Text = "???", ZIndex = 12, Parent = frame,
	})
	local counts = {}
	Style.text(name, 2)
	for i, v in Config.Variants do
		counts[v.id] = make("TextLabel", {
			Position = UDim2.new((i - 1) / 3, 4, 0, 136), Size = UDim2.new(1 / 3, -8, 0, 26), BackgroundColor3 = Color3.fromRGB(30, 32, 40),
			Font = FONT, TextScaled = true, TextColor3 = v.text or Color3.new(1, 1, 1), Text = "0", ZIndex = 12, Parent = frame,
		}, { corner(6), make("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }) })
	end
	cells[tier] = { frame = frame, view = view, name = name, counts = counts, shown = nil }
end

-- (Re)builds a cell's 3D preview: best version crushed so far, or a black silhouette.
local function setPreview(tier: number, mode: string)
	local cell = cells[tier]
	if cell.shown == mode then
		return
	end
	cell.shown = mode
	cell.view:ClearAllChildren()
	corner(8).Parent = cell.view
	local def = Config.Objects[tier]
	local model = Objects.build(tier, CFrame.identity, if mode == "silhouette" then "Normal" else mode, mode == "silhouette")
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	model.Parent = cell.view
	local cam = Instance.new("Camera")
	local size = math.max(def.width, def.height)
	local centre = Vector3.new(0, def.height / 2, 0)
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(size * 0.9, size * 0.6, size * 1.6), centre)
	cam.Parent = cell.view
	cell.view.CurrentCamera = cam
end

local function refreshBook()
	local found, total = 0, #Config.Objects * #Config.Variants
	for tier, def in Config.Objects do
		local entry = collection[tostring(tier)] or {}
		local cell = cells[tier]
		local best = "silhouette"
		for _, v in Config.Variants do
			local n = entry[v.id] or 0
			cell.counts[v.id].Text = Format.compact(n)
			cell.counts[v.id].TextTransparency = if n > 0 then 0 else 0.6
			if n > 0 then
				found += 1
				best = v.id
			end
		end
		cell.name.Text = if best == "silhouette" then "???" else def.name
		if book.Visible then
			setPreview(tier, best)
		end
	end
	local mult = Config.collectionMult(collection)
	bookTitle.Text = string.format("Collection  %d/%d", found, total)
	bookSub.Text = string.format("Cash bonus x%.2f\nNormal +%d%% / Golden +%d%% / Diamond +%d%% per first crush",
		mult, Config.CollectionBonus.Normal * 100, Config.CollectionBonus.Golden * 100, Config.CollectionBonus.Diamond * 100)
end

bookButton.Activated:Connect(function()
	Style.setOpen(book, not book.Visible)
	bookDot.Visible = false
	refreshBook()
end)
closeButton.Activated:Connect(function()
	Style.setOpen(book, false)
end)

local gotFirst = false
Net.event("Collection").OnClientEvent:Connect(function(data)
	collection = data
	if gotFirst and not book.Visible then
		bookDot.Visible = true
	end
	gotFirst = true
	refreshBook()
end)

-- Spinning press parts (PressBuilder tags Models "PressSpin", attribute Speed rad/s).
local CollectionService = game:GetService("CollectionService")
RunService.RenderStepped:Connect(function(dt)
	for _, m in CollectionService:GetTagged("PressSpin") do
		if m:IsA("Model") then
			local speed = (m:GetAttribute("Speed") :: number?) or 1
			local axis = m:GetAttribute("Axis") :: Vector3?
			local centre = if axis then CFrame.new(axis) else m:GetBoundingBox()
			local turn = CFrame.Angles(0, speed * dt, 0)
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") then
					p.CFrame = centre * turn * centre:ToObjectSpace(p.CFrame)
				end
			end
		end
	end
end)
