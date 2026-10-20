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

export type Api = {
	getData: (Player) -> any, -- nil until loaded
	whenLoaded: (Player) -> any,
	save: (Player) -> boolean,
	addCash: (Player, number) -> (),
	sync: (Player) -> (),
	cashPerSecond: (Player) -> number, -- normal earning rate (for offline earnings)
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

local pendingOffline: { [Player]: { seconds: number, cash: number } } = {}

local function payOffline(player: Player)
	local pending = pendingOffline[player]
	if not pending then
		return
	end
	pendingOffline[player] = nil
	api.addCash(player, pending.cash)
	ShopNotice:FireClient(player, { kind = "offline", owned = true, seconds = pending.seconds, cash = pending.cash })
end

local function onLoaded(player: Player)
	local data = api.whenLoaded(player)
	if not data then
		return
	end
	local seconds, cash = offlineAmount(player, data)
	data.lastSeen = os.time()
	local deadline = os.clock() + 15
	while player.Parent and not passChecked[player] and os.clock() < deadline do
		task.wait(0.25)
	end
	if not player.Parent or cash <= 0 then
		return
	end
	pendingOffline[player] = { seconds = seconds, cash = cash }
	if Store.hasPass(player, "OfflineEarnings") then
		payOffline(player)
	else
		-- Show what they missed; buying the pass now pays it out.
		ShopNotice:FireClient(player, { kind = "offline", owned = false, seconds = seconds, cash = cash })
	end
end

-- Products -------------------------------------------------------------------

local function grant(player: Player, productId: string)
	local data = api.getData(player)
	if productId == "FinishSmelt" then
		require(script.Parent.Scrap).finishSmelt(player, data)
		Purchased:FireClient(player, { id = productId, text = "Smelting done!" })
	elseif productId == "GoldenRush" then
		data.goldenRush = (data.goldenRush or 0) + Store.GoldenRushCount
		player:SetAttribute("GoldenRush", data.goldenRush)
		Purchased:FireClient(player, { id = productId, text = Store.GoldenRushCount .. " Golden objects coming up!" })
	else
		local amount = Store.cashPackAmount(productId, data.tier)
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

local function processReceipt(receipt: any)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local id = productHandlers[receipt.ProductId]
	local data = player and api.getData(player)
	if not player or not id or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.purchases = data.purchases or {}
	if table.find(data.purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
	end
	local ok, err = pcall(grant, player, id)
	if not ok then
		warn(`[Shop] grant {id} failed: {err}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.purchases, receipt.PurchaseId)
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
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Shop.start(gameApi: Api)
	api = gameApi
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if not purchased then
			return
		end
		for _, pass in Store.Passes do
			if pass.gamePassId == passId then
				setPass(player, pass.perk, true)
				Analytics.custom(player, "PassPurchase", 1, pass.perk)
				Purchased:FireClient(player, { id = pass.perk, text = pass.title .. " unlocked!" })
				if pass.perk == "OfflineEarnings" then
					payOffline(player)
				end
			end
		end
	end)
	Net.event("ShopOpened").OnServerEvent:Connect(function(player, tab)
		Analytics.custom(player, "ShopOpened", 1, if typeof(tab) == "string" then tab:sub(1, 30) else nil)
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
		pendingOffline[player] = nil
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
			if owned and perk == "OfflineEarnings" then
				payOffline(player)
			end
			return true
		end
		devPass.Parent = game:GetService("ServerStorage")
		local devProduct = Instance.new("BindableFunction")
		devProduct.Name = "DevProduct"
		devProduct.OnInvoke = function(player: Player, productId: string)
			grant(player, productId)
			return true
		end
		devProduct.Parent = game:GetService("ServerStorage")
		local devOffline = Instance.new("BindableFunction")
		devOffline.Name = "DevOffline" -- pretend the player was away `hours`
		devOffline.OnInvoke = function(player: Player, hours: number)
			local data = api.getData(player)
			data.lastSeen = os.time() - hours * 3600
			local seconds, cash = offlineAmount(player, data)
			pendingOffline[player] = { seconds = seconds, cash = cash }
			if Store.hasPass(player, "OfflineEarnings") then
				payOffline(player)
			else
				ShopNotice:FireClient(player, { kind = "offline", owned = false, seconds = seconds, cash = cash })
			end
			return cash
		end
		devOffline.Parent = game:GetService("ServerStorage")
	end
end

return Shop
