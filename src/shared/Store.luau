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
	{ perk = "AutoCrush", gamePassId = 0, price = 199, title = "Auto Crush", desc = "Crushes for you, even while you're AFK", color = Color3.fromRGB(230, 80, 70) },
	{ perk = "DoubleCash", gamePassId = 0, price = 249, title = "2x Cash", desc = "Double cash from every crush, forever", color = Color3.fromRGB(80, 200, 110) },
	{ perk = "Lucky", gamePassId = 0, price = 149, title = "Lucky", desc = "2x chance of Golden and Diamond objects", color = Color3.fromRGB(255, 200, 50) },
	{ perk = "AutoCollect", gamePassId = 0, price = 99, title = "Auto Collect", desc = "Scrap flies to you, smelts and the cash collects itself", color = Color3.fromRGB(255, 160, 50) },
	-- (30 Oct: the Offline Earnings pass is gone: offline cash is free for everyone,
	-- with paid 2x / 5x boosts on the welcome-back card, see Store.Offline)
} :: { Pass }

Store.Products = {
	{ id = "CashSmall", productId = 3723657331, price = 19, title = "Cash Pile", desc = "25% of your next press", color = Color3.fromRGB(80, 200, 110) },
	{ id = "CashMedium", productId = 3723657452, price = 59, title = "Cash Stack", desc = "A whole next press", color = Color3.fromRGB(60, 180, 90) },
	{ id = "CashLarge", productId = 3723657672, price = 129, title = "Cash Vault", desc = "4x your next press", color = Color3.fromRGB(40, 160, 80) },
	-- 30 Oct: no longer sold (Willem); kept hidden for old code paths
	{ id = "FinishSmelt", productId = 0, price = 19, title = "Finish Now", desc = "Your smelter finishes all its scrap at once", color = Color3.fromRGB(255, 140, 40), hidden = true },
	{ id = "GoldenRush", productId = 0, price = 49, title = "Golden Rush", desc = "Your next 10 objects are Golden", color = Color3.fromRGB(255, 200, 50), hidden = true },
	-- Rewards panel "Skip All": every playtime gift unlocks now (not in the shop list)
	-- Hub Boosts station (Shared/BoostConfig); hidden from the shop list
	{ id = "BoostCash", productId = 3723657898, price = 19, title = "2x Cash Boost", desc = "15 minutes of double cash", color = Color3.fromRGB(230, 70, 60), hidden = true },
	{ id = "BoostLuck", productId = 3723657981, price = 19, title = "2x Luck Boost", desc = "15 minutes of double luck", color = Color3.fromRGB(60, 190, 90), hidden = true },
	{ id = "BoostSuper", productId = 3723658049, price = 29, title = "Super Boost", desc = "15 minutes of 2x cash and 2x luck", color = Color3.fromRGB(160, 80, 235), hidden = true },
	-- 30 Oct: welcome-back card multipliers (the card shows these Robux prices until
	-- the productIds are filled in from the Creator Dashboard; 0 = "SOON")
	{ id = "OfflineX2", productId = 0, price = 25, title = "2x Offline Cash", desc = "Double what you earned while away", color = Color3.fromRGB(70, 150, 255), hidden = true },
	{ id = "OfflineX5", productId = 0, price = 59, title = "5x Offline Cash", desc = "Five times what you earned while away", color = Color3.fromRGB(255, 190, 40), hidden = true },
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
Store.CashPackShare = { CashSmall = 0.25, CashMedium = 1, CashLarge = 4 }
-- 30 Oct: cash packs pay minutes of YOUR current earnings, so they stay worth it
-- at every stage (Pile 10 min, Stack 1 h, Vault 4 h). Never less than MinPackCash.
Store.CashPackMinutes = { CashSmall = 10, CashMedium = 60, CashLarge = 240 }
Store.MinPackCash = 100
-- cash for `seconds` of earnings at `cps` cash per second
function Store.cashFor(cps: number, seconds: number): number
	return math.max(Store.MinPackCash, math.floor((cps or 0) * seconds))
end
Store.GoldenRushCount = 10

-- cps: current cash per second (server: api.cashPerSecond; client: attribute CashRate)
function Store.cashPackAmount(productId: string, tier: number, cps: number?): number
	if Config.Crushers.Enabled then return Store.cashFor(cps or 0, (Store.CashPackMinutes[productId] or 0) * 60) end
	local share = Store.CashPackShare[productId] or 0
	return math.floor(Config.SizeCost(math.min(tier, Config.MaxTier - 1)) * share)
end

-- Offline earnings (30 Oct: free for everyone): this share of the normal rate
-- for up to MaxHours. On the welcome-back card the player collects it, or pays
-- for a multiplier (product id -> multiplier) that pays that many times it.
Store.Offline = { Share = 0.5, MaxHours = 8, MinAwayMinutes = 5,
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
		if pass.perk == "Lucky" then pass.desc = "Doubles uncommon-and-rarer crusher roll weights." end
		if pass.perk == "AutoCollect" then pass.desc = "Automatically collects and sells your finished scrap." end
	end
	for _, product in Store.Products do
		if product.id == "FinishSmelt" then product.title = "Sell All Scrap" product.desc = "Collect and sell all finished scrap instantly." end
		if product.id == "GoldenRush" then product.title = "Golden Batch" product.desc = "Next 10 completed inputs award 10x scrap value." end
		if Store.CashPackShare[product.id] then product.desc = (Store.CashPackMinutes[product.id] or 0) // 60 > 0 and ((Store.CashPackMinutes[product.id] // 60) .. "h of your earnings, instantly.") or (Store.CashPackMinutes[product.id] .. " min of your earnings, instantly.") end
	end
end
return Store
