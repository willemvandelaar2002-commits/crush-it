--!strict
-- Everything sold for Robux. IDs are 0 until the passes / products exist on
-- the Creator Dashboard: a 0 id shows "SOON" in the shop and can't be bought.
-- Fill in the ids here and nothing else needs to change.
--
-- Pass ownership lives in the player attribute "Pass_<perk>" (server sets it;
-- Store.hasPass reads it on both sides).

local Config = require(script.Parent.Config)

local Store = {}

export type Pass = { perk: string, gamePassId: number, price: number, title: string, desc: string, color: Color3 }
export type Product = { id: string, productId: number, price: number, title: string, desc: string, color: Color3, hidden: boolean?, mythic: string? }

Store.Passes = {
	-- AutoCrush is sold as "Production Boost" (pass 2060699266); the old Auto Crush
	-- (2041790315) and Offline Earnings (2039938725) passes are not used.
	-- 3 Nov (vault audit, "see exactly what you get"): the shop card said "Auto Crush:
	-- crushes for you while AFK", but crushers always work; it now says what it does.
	{ perk = "AutoCrush", gamePassId = 2060699266, price = 199, title = "Production Boost", desc = "+25% damage for all your crushers, forever", color = Color3.fromRGB(230, 80, 70) },
	{ perk = "DoubleCash", gamePassId = 2039584674, price = 249, title = "2x Cash", desc = "Double cash from every crush, forever", color = Color3.fromRGB(80, 200, 110) },
	{ perk = "Lucky", gamePassId = 2041580327, price = 149, title = "Lucky", desc = "2x luck on crusher rolls: Uncommon or better about 30% -> 46% of rolls", color = Color3.fromRGB(255, 200, 50) },
	{ perk = "AutoCollect", gamePassId = 2057934074, price = 99, title = "Auto Collect", desc = "Scrap flies to you, smelts and the cash collects itself", color = Color3.fromRGB(255, 160, 50) },
	-- 4 Nov (monetization round 2, vault: Price Points "the 299-599 rung was empty"; Willem):
	-- VIP. Id 0 until Willem creates the pass (hidden in the shop until then).
	{ perk = "VIP", gamePassId = 0, price = 399, title = "VIP", desc = "x1.5 cash forever, offline cash up to 12 h (not 6), a gold [VIP] tag in chat", color = Color3.fromRGB(255, 200, 40) },
	-- (30 Oct: the Offline Earnings pass is gone: offline cash is free for everyone,
	-- with paid 2x / 5x boosts on the welcome-back card, see Store.Offline)
} :: { Pass }

Store.Products = {
	{ id = "CashSmall", productId = 3723657331, price = 19, title = "10m Time Skip", desc = "10 minutes of your earnings, right away", color = Color3.fromRGB(80, 200, 110) },
	-- 4 Nov (monetization round 2; vault: RNG genre "social luck sells", Price Points
	-- "the moment beats the price"). Id 0 = not created yet (hidden everywhere).
	{ id = "ServerLuck", productId = 0, price = 99, title = "Server Luck", desc = "2x luck for EVERYONE in this server for 15 minutes", color = Color3.fromRGB(80, 220, 90) },
	{ id = "TurboNow", productId = 0, price = 49, title = "Instant Turbo", desc = "15 minutes of your strongest TURBO, right away", color = Color3.fromRGB(255, 140, 40) },
	{ id = "CashMedium", productId = 3723657452, price = 59, title = "1H Time Skip", desc = "1 hour of your earnings, right away", color = Color3.fromRGB(60, 180, 90) },
	{ id = "CashLarge", productId = 3723657672, price = 129, title = "4H Time Skip", desc = "4 hours of your earnings, right away", color = Color3.fromRGB(40, 160, 80) },
	-- 5 Nov (Willem's references: a time-skip ladder up to 24 h with the cash amount on
	-- every card; vault: 3-5 rungs, value per Robux rising: 0.5 / 1.0 / 1.9 / 2.4 / 2.9 min
	-- per Robux). Id 0 until created (hidden until then).
	{ id = "CashHuge", productId = 0, price = 299, title = "12H Time Skip", desc = "12 hours of your earnings, right away", color = Color3.fromRGB(40, 150, 120) },
	{ id = "CashMega", productId = 0, price = 499, title = "24H Time Skip", desc = "24 hours of your earnings, right away", color = Color3.fromRGB(230, 170, 30) },
	-- 30 Oct: no longer sold (Willem); kept hidden for old code paths
	{ id = "FinishSmelt", productId = 0, price = 19, title = "Finish Now", desc = "Your smelter finishes all its scrap at once", color = Color3.fromRGB(255, 140, 40), hidden = true },
	{ id = "GoldenRush", productId = 0, price = 49, title = "Golden Rush", desc = "Your next 10 objects are Golden", color = Color3.fromRGB(255, 200, 50), hidden = true },
	-- Rewards panel "Skip All": every playtime gift unlocks now (not in the shop list)
	-- Hub Boosts station (Shared/BoostConfig); hidden from the shop list
	{ id = "BoostCash", productId = 3723657898, price = 19, title = "2x Cash Boost", desc = "15 minutes of double cash", color = Color3.fromRGB(230, 70, 60), hidden = true },
	{ id = "BoostLuck", productId = 3723657981, price = 19, title = "2x Luck Boost", desc = "15 minutes of 2x luck on crusher rolls (stacks with the Lucky pass)", color = Color3.fromRGB(60, 190, 90), hidden = true },
	{ id = "BoostSuper", productId = 3723658049, price = 29, title = "Super Boost", desc = "15 minutes of 2x cash and 2x luck", color = Color3.fromRGB(160, 80, 235), hidden = true },
	-- 30 Oct: welcome-back card multipliers (the card shows these Robux prices until
	-- the productIds are filled in from the Creator Dashboard; 0 = "SOON")
	{ id = "OfflineX2", productId = 3724354876, price = 32, title = "2x Offline Cash", desc = "Double what you earned while away", color = Color3.fromRGB(70, 150, 255), hidden = true },
	{ id = "OfflineX5", productId = 3724355041, price = 49, title = "5x Offline Cash", desc = "Five times what you earned while away", color = Color3.fromRGB(255, 190, 40), hidden = true },
	{ id = "SkipRewards", productId = 3723658147, price = 99, title = "Skip All", desc = "Unlock every playtime gift now", color = Color3.fromRGB(255, 200, 40), hidden = true },
	-- Shop offers (Shared/OfferConfig, server/Offers). price = 0: not approved
	-- yet; once a productId is set the shop shows Roblox's own price.
	{ id = "StarterPack", productId = 3723658249, price = 69, title = "Starter Pack", desc = "Candy Colossus + cash + 2x Cash boost (once)", color = Color3.fromRGB(255, 80, 170), hidden = true },
	{ id = "FactoryCrate1", productId = 3723658442, price = 39, title = "Factory Crate", desc = "One random crate crusher (Epic, Legendary or Mythic)", color = Color3.fromRGB(150, 70, 230), hidden = true },
	-- Mythic crushers (exclusive: never rolled). productId 0 shows SOON.
	-- Hidden: the Factory Crate and the Prism Mech showroom sell these now; the
	-- entries stay so receipts for their product ids keep being honoured.
	{ id = "Mythic_JackpotPress", productId = 0, price = 499, title = "Jackpot Press", desc = "MYTHIC crusher · 3x Legendary output", color = Color3.fromRGB(255, 70, 190), mythic = "JackpotPress", hidden = true },
	{ id = "Mythic_SeraphPress", productId = 0, price = 499, title = "Seraph Press", desc = "MYTHIC crusher · 3x Legendary output", color = Color3.fromRGB(255, 70, 190), mythic = "SeraphPress", hidden = true },
	{ id = "Mythic_PrismMech", productId = 3723658620, price = 399, title = "Prism Mech", desc = "MYTHIC crusher · 3x Legendary output", color = Color3.fromRGB(255, 70, 190), mythic = "PrismMech", hidden = true },
	{ id = "Mythic_PhantomPirate", productId = 0, price = 499, title = "Phantom Pirate", desc = "MYTHIC crusher · 3x Legendary output", color = Color3.fromRGB(255, 70, 190), mythic = "PhantomPirate", hidden = true },
	{ id = "Mythic_CandyColossus", productId = 0, price = 499, title = "Candy Colossus", desc = "MYTHIC crusher · 3x Legendary output", color = Color3.fromRGB(255, 70, 190), mythic = "CandyColossus", hidden = true },
} :: { Product }

-- What a cash pack pays: a share of the next press (or of the current one at max size).
Store.CashPackShare = { CashSmall = 0.25, CashMedium = 1, CashLarge = 4, CashHuge = 12, CashMega = 24 }
-- 30 Oct: cash packs pay minutes of YOUR current earnings, so they stay worth it
-- at every stage (Pile 10 min, Stack 1 h, Vault 4 h). Never less than MinPackCash.
Store.CashPackMinutes = { CashSmall = 10, CashMedium = 60, CashLarge = 240, CashHuge = 720, CashMega = 1440 }
Store.MinPackCash = 100
-- cash for `seconds` of earnings at `cps` cash per second
function Store.cashFor(cps: number, seconds: number): number
	return math.max(Store.MinPackCash, math.floor((cps or 0) * seconds))
end
Store.GoldenRushCount = 10
-- 4 Nov: Server Luck (stacks on time left, capped) and the VIP pass
Store.ServerLuck = { Mult = 2, Minutes = 15, MaxMinutes = 60 }
Store.Vip = { Mult = 1.5, OfflineHours = 12 }
-- the Instant Turbo (TurboNow) gives this many minutes of your best unlocked turbo
Store.TurboNowMinutes = 15

-- cps: current cash per second (server: api.cashPerSecond; client: attribute CashRate)
function Store.cashPackAmount(productId: string, tier: number, cps: number?): number
	if Config.Crushers.Enabled then return Store.cashFor(cps or 0, (Store.CashPackMinutes[productId] or 0) * 60) end
	local share = Store.CashPackShare[productId] or 0
	return math.floor(Config.SizeCost(math.min(tier, Config.MaxTier - 1)) * share)
end

-- Offline earnings (30 Oct: free for everyone): this share of the normal rate
-- for up to MaxHours. On the welcome-back card the player collects it, or pays
-- for a multiplier (product id -> multiplier) that pays that many times it.
-- 1 Nov: 10% for up to 6 h (was 50% for 8 h: a night away paid more than hours of play)
Store.Offline = { Share = 0.1, MaxHours = 6, MinAwayMinutes = 5,
	Multipliers = { OfflineX2 = 2, OfflineX5 = 5 },
	FallbackMinutes = 30, -- a multiplier receipt with no away amount on record pays this many minutes of earnings x the multiplier
}

function Store.passAttr(perk: string): string
	return "Pass_" .. perk
end

function Store.hasPass(player: Player, perk: string): boolean
	return player:GetAttribute(Store.passAttr(perk)) == true
end

function Store.passByPerk(perk: string): Pass?
	for _, p in Store.Passes do
		if p.perk == perk then
			return p
		end
	end
	return nil
end

-- 31 Oct: the Robux price Roblox has for a product/pass (Creator Dashboard is
-- the source of truth; the `price` fields above are only a fallback while it
-- loads or when the id is 0). Client-side cache; onPrice(price) runs at once
-- with the fallback and again when Roblox answers.
local livePrices: { [string]: number } = {}
function Store.livePrice(kind: string, id: number, fallback: number, onPrice: (number) -> ())
	onPrice(livePrices[kind .. id] or fallback)
	if id == 0 or livePrices[kind .. id] then return end
	task.spawn(function()
		local ok, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfoAsync(id, if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		if ok and info and type(info.PriceInRobux) == "number" then
			livePrices[kind .. id] = info.PriceInRobux
			onPrice(info.PriceInRobux)
		end
	end)
end

-- 5 Nov: the ids from `ids` whose product exists on Roblox (new products stay hidden
-- until Willem has created them; the older ones keep showing SOON as before)
local NEW = { ServerLuck = true, TurboNow = true, CashHuge = true, CashMega = true }
function Store.existing(ids: { string }): { string }
	local out = {}
	for _, id in ids do
		local p = Store.productById(id)
		if p and (p.productId ~= 0 or not NEW[id]) then table.insert(out, id) end
	end
	return out
end

function Store.productById(id: string): Product?
	for _, p in Store.Products do
		if p.id == id then
			return p
		end
	end
	return nil
end

if Config.Crushers.Enabled then
	for _, pass in Store.Passes do
		if pass.perk == "AutoCrush" then pass.title = "Production Boost" pass.desc = "+25% strike damage. Automatic crushing is free for everyone." end
		if pass.perk == "Lucky" then pass.desc = "2x luck on every roll: more Rare, Epic and Legendary crushers. Stacks with boosts." end -- 3 Nov: plain words
		if pass.perk == "AutoCollect" then pass.desc = "Automatically collects and sells your finished scrap." end
	end
	for _, product in Store.Products do
		if product.id == "FinishSmelt" then product.title = "Sell All Scrap" product.desc = "Collect and sell all finished scrap instantly." end
		if product.id == "GoldenRush" then product.title = "Golden Batch" product.desc = "Next 10 completed inputs award 10x scrap value." end
		if Store.CashPackShare[product.id] then product.desc = (Store.CashPackMinutes[product.id] or 0) // 60 > 0 and ((Store.CashPackMinutes[product.id] // 60) .. "h of your earnings, instantly.") or (Store.CashPackMinutes[product.id] .. " min of your earnings, instantly.") end
	end
end
return Store
