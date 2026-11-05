--!strict
-- Robux: gamepass ownership, developer product receipts and offline earnings.
-- Game.server calls Shop.start(api) with the few things it needs from the game.
--
-- Receipts: grant, remember the PurchaseId in the save (data.purchases, last
-- 50), save, and only then answer PurchaseGranted. If anything fails Roblox
-- re-sends the receipt later; the saved id stops a double grant.
-- Roblox allows ONE ProcessReceipt per game: this is it.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Store = require(ReplicatedStorage.Shared.Store)
local Net = require(ReplicatedStorage.Shared.Net)
local Format = require(ReplicatedStorage.Shared.Format)
local Analytics = require(script.Parent.Kit.Analytics)
local HttpService = game:GetService("HttpService")

-- Shop funnel (31 Oct, recurring): 1 Opened -> 2 Prompted (a Robux prompt was
-- shown) -> 3 Purchased. One session per shop visit; a prompt or purchase
-- without an open visit (signs, offer buttons) starts its own session.
local SHOP_SESSION = 600 -- seconds a shop visit stays the same funnel session
local shopFunnel: { [Player]: { id: string, at: number } } = {}
local function shopStep(player: Player, step: number, name: string, fresh: boolean?)
	local s = shopFunnel[player]
	if fresh or not s or os.clock() - s.at > SHOP_SESSION then
		s = { id = HttpService:GenerateGUID(false), at = os.clock() }
		shopFunnel[player] = s
	end
	s.at = os.clock()
	Analytics.funnel(player, "Shop", s.id, step, name)
end

export type Api = {
	getData: (Player) -> any, -- nil until loaded
	canSave: (Player) -> boolean, -- false when this session can't persist (SaveOff)
	whenLoaded: (Player) -> any,
	save: (Player) -> boolean,
	addCash: (Player, number, string?, string?) -> (), -- amount, economy sku, transaction type
	sync: (Player) -> (),
	cashPerSecond: (Player) -> number, -- normal earning rate (for offline earnings)
	finishLegacyProduct: ((Player) -> ())?,
	giveCrusher: (Player, string, string?, boolean?) -> string?,
}

local Shop = {}

local api: Api
local passChecked: { [Player]: boolean } = {}
local ShopNotice = Net.event("ShopNotice")
local Purchased = Net.event("Purchased")

local function setPass(player: Player, perk: string, owned: boolean)
	player:SetAttribute(Store.passAttr(perk), if owned then true else nil)
end

local function checkPasses(player: Player)
	for _, pass in Store.Passes do
		if pass.gamePassId ~= 0 then
			-- 5 Nov (vault V2 audit): retry with backoff, so a short Roblox hiccup at
			-- join doesn't switch off a paid pass for the whole session
			for attempt = 1, 4 do
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
				end)
				if ok then
					if owns then setPass(player, pass.perk, true) end
					break
				end
				if not player.Parent then return end
				task.wait(2 * attempt)
			end
		end
	end
	passChecked[player] = true
end

-- 5 Nov (vault V2 audit; Analytics and Funnels: "no free text in custom fields", max
-- 8,000 value combinations): the shop-opened analytics only accepts names the game
-- itself sends; anything else is logged as "Other", at most one event per 0.5 s.
local SHOP_SOURCES: { [string]: boolean } = {}
for _, n in { "ShopButton", "QuickShopMore", "AutoButton", "DoubleCashOffer", "FeaturedOffer", "StarterOffer",
	"OfferStarterPack", "OfflineX2", "OfflineX5", "OfferPrismMech", "OfferFactoryCrate", "OfferStarterPack" } do
	SHOP_SOURCES[n] = true
end
for _, tab in { "FEATURED", "CRATES", "PACKS", "BOOSTS", "PASSES", "CASH" } do SHOP_SOURCES["Tab" .. tab] = true end
for _, product in Store.Products do
	SHOP_SOURCES["Moment" .. product.id] = true
	SHOP_SOURCES["Offer" .. product.id] = true
end
local lastShopEvent: { [Player]: number } = {}
local function shopSource(player: Player, tab: any): string?
	if os.clock() - (lastShopEvent[player] or 0) < 0.5 then return nil end
	lastShopEvent[player] = os.clock()
	return if typeof(tab) == "string" and SHOP_SOURCES[tab] then tab else "Other"
end
Players.PlayerRemoving:Connect(function(p) lastShopEvent[p] = nil end)

-- Offline earnings -----------------------------------------------------------

local function offlineAmount(player: Player, data: any): (number, number)
	local last = tonumber(data.lastSeen) or 0
	if last <= 0 then
		return 0, 0
	end
	local away = os.time() - last
	if away < Store.Offline.MinAwayMinutes * 60 then
		return 0, 0
	end
	-- 4 Nov: VIP keeps up to 12 h instead of 6
	local hours = if Store.hasPass(player, "VIP") then Store.Vip.OfflineHours else Store.Offline.MaxHours
	local seconds = math.min(away, hours * 3600)
	return seconds, math.floor(api.cashPerSecond(player) * seconds * Store.Offline.Share)
end

-- 30 Oct: offline cash is free; the record is saved (data.offline) so a 2x/5x
-- receipt that arrives late (or after a rejoin) still knows what to multiply.
--   data.offline = { cash, seconds, paid } -- paid: multiplier already paid out (0 = nothing yet)
local function sendOffline(player: Player, data: any)
	local rec = data.offline
	if type(rec) ~= "table" then return end
	ShopNotice:FireClient(player, { kind = "offline", seconds = rec.seconds, cash = rec.cash, paid = rec.paid })
end

local function collectOffline(player: Player)
	local data = api.getData(player)
	local rec = data and data.offline
	if type(rec) ~= "table" or rec.paid ~= 0 then return end
	rec.paid = 1 -- no yield between the check and the payout
	api.addCash(player, rec.cash, "OfflineCash", "TimedReward")
	Purchased:FireClient(player, { id = "OfflineCollect", text = "+" .. Format.cash(rec.cash) })
end

-- multiplier receipt: pays up to mult x the away cash (minus what was already paid)
local function multiplyOffline(player: Player, data: any, mult: number): string
	local rec = data.offline
	if type(rec) ~= "table" or type(rec.cash) ~= "number" then
		local amount = math.floor(api.cashPerSecond(player) * Store.Offline.FallbackMinutes * 60 * mult)
		api.addCash(player, amount, "OfflineMultiplier", "IAP")
		return "+" .. Format.cash(amount)
	end
	local amount = math.max(rec.cash, rec.cash * mult - rec.cash * (rec.paid or 0))
	rec.paid = math.max(rec.paid or 0, mult)
	api.addCash(player, amount, "OfflineMultiplier", "IAP")
	return "+" .. Format.cash(amount) .. " (" .. mult .. "x offline cash)!"
end

local function onLoaded(player: Player)
	local data = api.whenLoaded(player)
	if not data then
		return
	end
	-- last time's card was never answered: that cash still arrives (1x)
	local old = data.offline
	if type(old) == "table" and old.paid == 0 and type(old.cash) == "number" then
		old.paid = 1 api.addCash(player, old.cash, "OfflineCash", "TimedReward")
	end
	local seconds, cash = offlineAmount(player, data)
	data.lastSeen = os.time()
	if not player.Parent or cash <= 0 then
		return
	end
	data.offline = { cash = cash, seconds = seconds, paid = 0 }
	sendOffline(player, data)
end

-- Products -------------------------------------------------------------------

-- 5 Nov (vault V2 Monetization Overview: "a product that charged but granted nothing";
-- write a startup check that every product's grant is supported): every product id
-- the receipt handler knows how to grant. Anything else is refused (the receipt waits)
-- instead of quietly falling through to the cash-pack branch.
local SPECIAL: { [string]: boolean } = { FinishSmelt = true, BoostCash = true, BoostLuck = true, BoostSuper = true,
	ServerLuck = true, TurboNow = true, SkipRewards = true, GoldenRush = true }
local function canGrant(productId: string): boolean
	local product = Store.productById(productId)
	if not product then return false end
	if require(script.Parent.Offers).handles(productId) then return true end
	if Store.Offline.Multipliers[productId] then return true end
	if product.mythic then return true end
	return SPECIAL[productId] == true or Store.CashPackShare[productId] ~= nil
end

local function grant(player: Player, productId: string, purchaseId: string)
	if not canGrant(productId) then error("no grant for product " .. productId) end
	local data = api.getData(player)
	local product = Store.productById(productId)
	-- Shop offers (Starter Pack, crates, Prism Mech): server/Offers
	local Offers = require(script.Parent.Offers)
	if Offers.handles(productId) then
		local text = Offers.grant(player, data, productId, purchaseId)
		Purchased:FireClient(player, { id = productId, text = text })
		return
	end
	local offlineMult = Store.Offline.Multipliers[productId]
	if offlineMult then
		Purchased:FireClient(player, { id = productId, text = multiplyOffline(player, data, offlineMult) })
		return
	end
	if product and product.mythic then
		-- a bought Mythic always arrives, even with a full inventory (it's paid for)
		local name = api.giveCrusher(player, "Mythic", product.mythic, true)
		if not name then error("Mythic grant failed") end
		Purchased:FireClient(player, { id = productId, text = "MYTHIC " .. name .. " is yours!" })
		return
	end
	if productId == "FinishSmelt" then
		if api.finishLegacyProduct then api.finishLegacyProduct(player) Purchased:FireClient(player,{id=productId,text="All scrap sold!"}) return end
		require(script.Parent.Scrap).finishSmelt(player, data)
		Purchased:FireClient(player, { id = productId, text = "Smelting done!" })
	elseif productId == "BoostCash" or productId == "BoostLuck" or productId == "BoostSuper" then
		local b = require(ReplicatedStorage.Shared.BoostConfig).find(productId:sub(6))
		require(script.Parent.Boosts).add(player, b.id, b.minutes)
		Purchased:FireClient(player, { id = productId, text = b.title .. " for " .. b.minutes .. " minutes!" })
	elseif productId == "ServerLuck" then
		-- 4 Nov: 2x luck for everyone in this server (server/ServerLuck)
		require(script.Parent.ServerLuck).add(player)
		Purchased:FireClient(player, { id = productId, text = "SERVER LUCK for everyone! Thank you!" })
	elseif productId == "TurboNow" then
		-- 4 Nov: your strongest unlocked turbo, right away (server/Turbo)
		local title = require(script.Parent.Turbo).grantNow(player)
		if not title then error("Instant Turbo grant failed") end
		Purchased:FireClient(player, { id = productId, text = title .. " for " .. Store.TurboNowMinutes .. " minutes!" })
	elseif productId == "SkipRewards" then
		require(script.Parent.Rewards).skipAll(player)
		Purchased:FireClient(player, { id = productId, text = "All playtime gifts unlocked!" })
	elseif productId == "GoldenRush" then
		data.goldenRush = (data.goldenRush or 0) + Store.GoldenRushCount
		player:SetAttribute("GoldenRush", data.goldenRush)
		Purchased:FireClient(player, { id = productId, text = Store.GoldenRushCount .. " Golden production bonuses!" })
	else
		local amount = Store.cashPackAmount(productId, data.tier, api.cashPerSecond(player))
		api.addCash(player, amount, productId, "IAP")
		Purchased:FireClient(player, { id = productId, text = "+" .. Format.cash(amount) })
	end
end

local productHandlers: { [number]: string } = {}
for _, p in Store.Products do
	if p.productId ~= 0 then
		productHandlers[p.productId] = p.id
	end
end
-- the startup check (Output, every server): a sellable product without a grant
task.defer(function()
	for _, p in Store.Products do
		if not canGrant(p.id) then
			warn(`[Shop] product {p.id} (id {p.productId}) has NO grant: buying it would fail. Add it to Shop.grant.`)
		end
	end
end)

-- One receipt (also used by Studio's DevReceipt with a made-up PurchaseId).
-- The check-grant-remember part never yields, so two simultaneous callbacks
-- for the same PurchaseId can't both grant.
local function processFor(player: Player?, id: string?, purchaseId: string): Enum.ProductPurchaseDecision
	local data = player and api.getData(player)
	if not player or not id or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- 2 Nov: a session that can't save never grants (the receipt waits for a
	-- session that can, so the purchase is never lost)
	if not api.canSave(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.purchases = data.purchases or {}
	if table.find(data.purchases, purchaseId) then
		-- granted in memory already (earlier in this session or saved before):
		-- answer Granted only once that is safely saved
		return if api.save(player) then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(grant, player, id, purchaseId)
	if not ok then
		warn(`[Shop] grant {id} failed: {err}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.purchases, purchaseId)
	while #data.purchases > 50 do
		table.remove(data.purchases, 1)
	end
	-- 2 Nov: a short purchase log for support ("I bought X and got nothing")
	data.purchaseLog = data.purchaseLog or {}
	table.insert(data.purchaseLog, { k = id, t = os.time(), p = purchaseId })
	while #data.purchaseLog > 30 do
		table.remove(data.purchaseLog, 1)
	end
	if not api.save(player) then
		-- Not saved yet: Roblox re-sends the receipt; the id is in memory with
		-- the grant, so the retry only needs the save (no double grant).
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Analytics.custom(player, "RobuxPurchase", 1, id)
	shopStep(player, 3, "3 Bought something")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function processReceipt(receipt: any)
	return processFor(Players:GetPlayerByUserId(receipt.PlayerId), productHandlers[receipt.ProductId], receipt.PurchaseId)
end

function Shop.start(gameApi: Api)
	api = gameApi
	MarketplaceService.ProcessReceipt = processReceipt
	require(script.Parent.Offers).start(gameApi)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		shopStep(player, 2, "2 Saw a Robux price")
		if not purchased then
			return
		end
		shopStep(player, 3, "3 Bought something")
		for _, pass in Store.Passes do
			if pass.gamePassId == passId then
				setPass(player, pass.perk, true)
				Analytics.custom(player, "PassPurchase", 1, pass.perk)
				Purchased:FireClient(player, { id = pass.perk, text = pass.title .. " unlocked!" })
			end
		end
	end)
	Net.event("OfflineAction").OnServerEvent:Connect(function(player, action)
		if action == "Collect" then collectOffline(player) end
	end)
	Net.event("ShopOpened").OnServerEvent:Connect(function(player, raw)
		local tab = shopSource(player, raw)
		if not tab then return end
		Analytics.custom(player, "ShopOpened", 1, tab)
		-- tab switches ("Tab...") are the same visit
		if tab:sub(1, 3) ~= "Tab" then shopStep(player, 1, "1 Opened the shop", true) end
	end)
	-- every developer-product prompt that was shown (client or server prompted)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number)
		local player = Players:GetPlayerByUserId(userId)
		if player then shopStep(player, 2, "2 Saw a Robux price") end
	end)
	local function onPlayer(player: Player)
		task.spawn(checkPasses, player)
		task.spawn(onLoaded, player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		passChecked[player] = nil
		shopFunnel[player] = nil
	end)
	-- lastSeen for offline earnings (saved with the next autosave / leave).
	task.spawn(function()
		while true do
			task.wait(20)
			for _, p in Players:GetPlayers() do
				local data = api.getData(p)
				if data then
					data.lastSeen = os.time()
				end
			end
		end
	end)

	-- Studio only: ServerStorage.DevPass:Invoke(player, perk, owned) and
	-- ServerStorage.DevProduct:Invoke(player, productId) for testing without Robux.
	if RunService:IsStudio() then
		local devPass = Instance.new("BindableFunction")
		devPass.Name = "DevPass"
		devPass.OnInvoke = function(player: Player, perk: string, owned: boolean)
			setPass(player, perk, owned)
			return true
		end
		devPass.Parent = game:GetService("ServerStorage")
		local devProduct = Instance.new("BindableFunction")
		devProduct.Name = "DevProduct"
		devProduct.OnInvoke = function(player: Player, productId: string)
			grant(player, productId, "dev-" .. game:GetService("HttpService"):GenerateGUID(false))
			return true
		end
		devProduct.Parent = game:GetService("ServerStorage")
		-- DevReceipt:Invoke(player, productKey, purchaseId) -> decision name: the real
		-- receipt path (dedupe + save) with a made-up PurchaseId, for retry tests.
		local devReceipt = Instance.new("BindableFunction")
		devReceipt.Name = "DevReceipt"
		devReceipt.OnInvoke = function(player: Player, productId: string, purchaseId: string)
			return processFor(player, productId, purchaseId).Name
		end
		devReceipt.Parent = game:GetService("ServerStorage")
		local devOffline = Instance.new("BindableFunction")
		devOffline.Name = "DevOffline" -- pretend the player was away `hours`
		devOffline.OnInvoke = function(player: Player, hours: number)
			local data = api.getData(player)
			data.lastSeen = os.time() - hours * 3600
			local seconds, cash = offlineAmount(player, data)
			data.offline = { cash = cash, seconds = seconds, paid = 0 }
			sendOffline(player, data)
			return cash
		end
		devOffline.Parent = game:GetService("ServerStorage")
	end
end

return Shop
