--!strict
-- 4 Nov (monetization round 2; vault: Robux Price Points and Offer Design "the moment
-- beats the price", "after a success", "one gate, caps, never in the first minutes";
-- Ethical Design "dismissible, exact effect and duration"). A small card at the bottom,
-- never a full-screen window, closes by itself after 12 s:
--   * you just rolled a LEGENDARY or MYTHIC  -> Server Luck (2x for everyone, 15 min);
--     before that product exists: the 2x Luck boost
--   * your TURBO just ran out                -> Instant Turbo (15 min of your best);
--     before that product exists: the 2x Cash boost
-- At most ONE per session, not in the first 4 minutes, not during the tutorial, a
-- cutscene, an event or while any window is open. The price is Roblox's own.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Style = require(RS.Shared.Kit.Style)
local Store = require(RS.Shared.Store)
local Icons = require(RS.Shared.Icons)
local Net = require(RS.Shared.Net)
local T = require(RS.Shared.TurboConfig)
local Config = require(RS.Shared.Config)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local joinedAt = os.clock()
local shown = false
local tutorialDone = false
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) == "table" and type(v.tutorial) == "number" then tutorialDone = v.tutorial > #Config.Crushers.TutorialSteps end
end)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function words(parent: Instance, text: string, pos: UDim2, size: UDim2, max: number, color: Color3?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 4,
		TextXAlignment = Enum.TextXAlignment.Left }, parent)
	Style.text(l, 2.5)
	l.TextColor3 = color or Color3.new(1, 1, 1)
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = max }, l)
	return l
end

local gui = make("ScreenGui", { Name = "MomentOfferHud", ResetOnSpawn = false, DisplayOrder = 8, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local card = make("Frame", { Name = "MomentOffer", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(440, 112),
	BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 18) }, card)
make("UIStroke", { Thickness = 4, Color = INK }, card)
local grad = make("UIGradient", { Rotation = 90 }, card)
local icon = make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(58, 56), Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1,
	ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, card)
local title = words(card, "", UDim2.fromOffset(108, 12), UDim2.fromOffset(196, 34), 30)
local desc = words(card, "", UDim2.fromOffset(108, 48), UDim2.fromOffset(196, 50), 22, C(235, 240, 255))
desc.TextWrapped = true
local buy = make("TextButton", { Name = "Buy", Position = UDim2.fromOffset(312, 24), Size = UDim2.fromOffset(112, 64), Text = "", ZIndex = 3 }, card)
Style.button(buy, C(255, 196, 40)) -- (gold: stands out on the green and orange cards)
local price = words(buy, "", UDim2.fromOffset(8, 10), UDim2.new(1, -16, 1, -20), 30)
price.TextXAlignment = Enum.TextXAlignment.Center
local close = make("TextButton", { Name = "Close", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(44, 44), Text = "", ZIndex = 5 }, card)
Style.button(close, C(228, 36, 44))
local x = words(close, "X", UDim2.fromOffset(8, 6), UDim2.new(1, -16, 1, -12), 26)
x.TextXAlignment = Enum.TextXAlignment.Center
local fit = Style.phoneFit(card, { scale = 0.85, width = 0.62 })
local pop = make("UIScale", { Scale = 1 }, card)
fit.Parent = nil -- (one UIScale per object: the pop folds the phone fit in)

local current: any = nil
local token = 0
local function hide()
	token += 1
	if not card.Visible then return end
	local t = TweenService:Create(pop, TweenInfo.new(0.15), { Scale = 0.8 * fit.Scale })
	t:Play()
	t.Completed:Once(function() card.Visible = false end)
end
close.Activated:Connect(hide)
buy.Activated:Connect(function()
	if not current or me:GetAttribute("SaveOff") then return end
	MarketplaceService:PromptProductPurchase(me, current.productId)
	hide()
end)

local function calm(): boolean
	return not shown and me:GetAttribute("AutoOfferShown") ~= true and tutorialDone and os.clock() - joinedAt > 240 and Style.popCalm()
		and me:GetAttribute("CutscenePlaying") ~= true and me:GetAttribute("FactoryEventRunning") ~= true
end

-- product: the first of `ids` that exists on Roblox (id ~= 0)
local function offer(ids: { string }, head: string, body: string, image: string, a: Color3, b: Color3)
	if not calm() then return end
	local product = nil
	for _, id in ids do
		local p = Store.productById(id)
		if p and p.productId ~= 0 then product = p break end
	end
	if not product then return end
	shown = true
	me:SetAttribute("AutoOfferShown", true)
	Style.markPop()
	current = product
	title.Text = head
	desc.Text = body
	icon.Image = image
	grad.Color = ColorSequence.new(a, b)
	price.Text = "R$ " .. product.price
	Store.livePrice("product", product.productId, product.price, function(n) price.Text = "R$ " .. n end)
	Net.event("ShopOpened"):FireServer("Moment" .. product.id) -- shop funnel: offer seen
	card.Visible = true
	pop.Scale = 0.7 * fit.Scale
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = fit.Scale }):Play()
	token += 1
	local mine = token
	task.delay(12, function() if token == mine then hide() end end)
end

-- 1. right after your own Legendary / Mythic roll
Net.event("RarePull").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" or msg.userId ~= me.UserId or msg.text then return end
	if msg.rarity ~= "Legendary" and msg.rarity ~= "Mythic" then return end
	task.delay(3, function() -- after the pull banner
		local server = Store.productById("ServerLuck")
		if server and server.productId ~= 0 then
			offer({ "ServerLuck" }, "LUCKY STREAK!", "2x luck for EVERYONE here, 15 min", Icons.Lucky, C(80, 210, 90), C(30, 140, 60))
		else
			offer({ "BoostLuck" }, "LUCKY STREAK!", "Keep it going: 2x luck for 15 min", Icons.Lucky, C(80, 210, 90), C(30, 140, 60))
		end
	end)
end)

-- 2. your turbo just ran out
local running: { [string]: boolean } = {}
task.spawn(function()
	while true do
		task.wait(1)
		local now = workspace:GetServerTimeNow()
		for _, t in T.List do
			local on = ((me:GetAttribute(T.attr(t.id)) :: number?) or 0) > now
			if running[t.id] and not on then
				offer({ "TurboNow", "BoostCash" }, "TURBO RAN OUT", "Keep the cash flowing: 15 more minutes", Icons.Speed, C(255, 170, 60), C(220, 90, 20))
			end
			running[t.id] = on
		end
	end
end)
