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
export type Product = { id: string, productId: number, price: number, title: string, desc: string, color: Color3 }

Store.Passes = {
	{ perk = "AutoCrush", gamePassId = 0, price = 199, title = "Auto Crush", desc = "Crushes for you, even while you're AFK", color = Color3.fromRGB(230, 80, 70) },
	{ perk = "DoubleCash", gamePassId = 0, price = 249, title = "2x Cash", desc = "Double cash from every crush, forever", color = Color3.fromRGB(80, 200, 110) },
	{ perk = "Lucky", gamePassId = 0, price = 149, title = "Lucky", desc = "2x chance of Golden and Diamond objects", color = Color3.fromRGB(255, 200, 50) },
	{ perk = "OfflineEarnings", gamePassId = 0, price = 149, title = "Offline Earnings", desc = "Earn cash while you're offline (up to 8h)", color = Color3.fromRGB(110, 140, 230) },
} :: { Pass }

Store.Products = {
	{ id = "CashSmall", productId = 0, price = 29, title = "Cash Pile", desc = "25% of your next press", color = Color3.fromRGB(80, 200, 110) },
	{ id = "CashMedium", productId = 0, price = 79, title = "Cash Stack", desc = "A whole next press", color = Color3.fromRGB(60, 180, 90) },
	{ id = "CashLarge", productId = 0, price = 199, title = "Cash Vault", desc = "4x your next press", color = Color3.fromRGB(40, 160, 80) },
	{ id = "GoldenRush", productId = 0, price = 49, title = "Golden Rush", desc = "Your next 10 objects are Golden", color = Color3.fromRGB(255, 200, 50) },
} :: { Product }

-- What a cash pack pays: a share of the next press (or of the current one at max size).
Store.CashPackShare = { CashSmall = 0.25, CashMedium = 1, CashLarge = 4 }
Store.GoldenRushCount = 10

function Store.cashPackAmount(productId: string, tier: number): number
	local share = Store.CashPackShare[productId] or 0
	return math.floor(Config.SizeCost(math.min(tier, Config.MaxTier - 1)) * share)
end

-- Offline earnings: owners get this share of their normal rate for up to MaxHours.
Store.Offline = { Share = 0.5, MaxHours = 8, MinAwayMinutes = 5 }

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

return Store
