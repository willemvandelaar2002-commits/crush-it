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
	whenLoaded: (Player) -> any,
	save: (Player) -> boolean,
	addCash: (Player, number) -> (),
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
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
			end)
			if ok and owns then
				setPass(player, pass.perk, true)
			end
		end
	end
	passChecked[player] = true
end

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
	local seconds = math.min(away, Store.Offline.MaxHours * 3600)
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
	api.addCash(player, rec.cash)
	Purchased:FireClient(player, { id = "OfflineCollect", text = "+" .. Format.cash(rec.cash) })
end

-- multiplier receipt: pays up to mult x the away cash (minus what was already paid)
local function multiplyOffline(player: Player, data: any, mult: number): string
	local rec = data.offline
	if type(rec) ~= "table" or type(rec.cash) ~= "number" then
		local amount = math.floor(api.cashPerSecond(player) * Store.Offline.FallbackMinutes * 60 * mult)
		api.addCash(player, amount)
		return "+" .. Format.cash(amount)
	end
	local amount = math.max(rec.cash, rec.cash * mult - rec.cash * (rec.paid or 0))
	rec.paid = math.max(rec.paid or 0, mult)
	api.addCash(player, amount)
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
		old.paid = 1 api.addCash(player, old.cash)
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

local function grant(player: Player, productId: string, purchaseId: string)
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
	elseif productId == "SkipRewards" then
		require(script.Parent.Rewards).skipAll(player)
		Purchased:FireClient(player, { id = productId, text = "All playtime gifts unlocked!" })
	elseif productId == "GoldenRush" then
		data.goldenRush = (data.goldenRush or 0) + Store.GoldenRushCount
		player:SetAttribute("GoldenRush", data.goldenRush)
		Purchased:FireClient(player, { id = productId, text = Store.GoldenRushCount .. " Golden production bonuses!" })
	else
		local amount = Store.cashPackAmount(productId, data.tier, api.cashPerSecond(player))
		api.addCash(player, amount)
		Purchased:FireClient(player, { id = productId, text = "+" .. Format.cash(amount) })
	end
end

local productHandlers: { [number]: string } = {}
for _, p in Store.Products do
	if p.productId ~= 0 then
		productHandlers[p.productId] = p.id
	end
end

-- One receipt (also used by Studio's DevReceipt with a made-up PurchaseId).
-- The check-grant-remember part never yields, so two simultaneous callbacks
-- for the same PurchaseId can't both grant.
local function processFor(player: Player?, id: string?, purchaseId: string): Enum.ProductPurchaseDecision
	local data = player and api.getData(player)
	if not player or not id or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.purchases = data.purchases or {}
	if table.find(data.purchases, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
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
	if not api.save(player) then
		-- Not saved: Roblox retries; the grant stays in memory for this session
		-- and the id isn't persisted, so a retry may grant again after a rejoin.
		-- That's the safe side for the player.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Analytics.custom(player, "RobuxPurchase", 1, id)
	shopStep(player, 3, "Purchased")
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
		shopStep(player, 2, "Prompted")
		if not purchased then
			return
		end
		shopStep(player, 3, "Purchased")
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
	Net.event("ShopOpened").OnServerEvent:Connect(function(player, tab)
		Analytics.custom(player, "ShopOpened", 1, if typeof(tab) == "string" then tab:sub(1, 30) else nil)
		-- tab switches ("Tab...") are the same visit
		if not (typeof(tab) == "string" and tab:sub(1, 3) == "Tab") then shopStep(player, 1, "Opened", true) end
	end)
	-- every developer-product prompt that was shown (client or server prompted)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number)
		local player = Players:GetPlayerByUserId(userId)
		if player then shopStep(player, 2, "Prompted") end
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
