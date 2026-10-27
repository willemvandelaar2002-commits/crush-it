--!strict
-- Shop offers (shop Featured / Crates / Packs tabs, server/Offers).
-- TEST DEFAULTS ONLY: prices, bundle contents and crate odds are not approved
-- yet. Robux product ids live in Shared/Store (0 = shows SOON, can't be
-- bought); the price the shop shows always comes from Roblox, never from here.
--
--   Starter Pack   once per player: guaranteed Candy Colossus + cash + a boost
--   Factory Crate  one random Mythic: Jackpot Press, Seraph Press or Phantom Pirate
--                  (paid random item: odds shown before purchase, PolicyService
--                  eligibility checked per player, server picks and saves the result)
--   Prism Mech     once per player: guaranteed, shown on every plot's showroom pad
local CrusherConfig = require(script.Parent.CrusherConfig)
local BoostConfig = require(script.Parent.BoostConfig)

local O = {}

O.StarterPack = {
	id = "StarterPack", product = "StarterPack", once = true,
	title = "Starter Pack", tag = "ONE-TIME PACK",
	crusher = "CandyColossus", rarity = "Mythic",
	cash = CrusherConfig.CashPacks.CashMedium, -- test default: the "Cash Stack" amount
	boost = { id = "Cash", minutes = (BoostConfig.find("Cash") :: any).minutes }, -- test default: the 2x Cash boost
}

-- Crates: `bundles` = what can be bought (one product each); only x1 for now.
-- Weights are relative; equal weights are PROVISIONAL Studio test data.
O.Crates = {
	{
		id = "FactoryCrate", title = "Factory Crate", rarity = "Mythic", provisional = true,
		items = {
			{ type = "JackpotPress", weight = 1 },
			{ type = "SeraphPress", weight = 1 },
			{ type = "PhantomPirate", weight = 1 },
		},
		bundles = {
			{ product = "FactoryCrate1", count = 1 },
		},
	},
}

O.Showroom = {
	id = "PrismMech", product = "Mythic_PrismMech", once = true,
	title = "Prism Mech", tag = "GUARANTEED CRUSHER",
	crusher = "PrismMech", rarity = "Mythic",
	-- plot-local pad (measured 27 Oct): front yard left of the walkway, behind
	-- the Production board's back (z 46) and in front of the Sell station (z 72),
	-- 10 studs off the walkway; the collector -> Sell route passes west of it.
	-- yaw: the machine faces the walkway, so you see it walking in.
	pad = { x = -22, z = 56, size = 11, yaw = math.pi / 2 },
	demoEvery = 4, -- seconds between showroom press strokes (visual only)
}

O.MaxReveals = 20 -- unseen crate reveals kept in the save (oldest dropped; rewards already granted)

O.RoundingNote = "Probabilities are rounded; total of displayed individual probabilities may not equal 100%."

function O.crate(id: any): any
	for _, c in O.Crates do if c.id == id then return c end end
	return nil
end

-- product key -> { kind = "starter" | "crate" | "showroom", offer, count? }
function O.byProduct(product: any): any
	if product == O.StarterPack.product then return { kind = "starter", offer = O.StarterPack } end
	if product == O.Showroom.product then return { kind = "showroom", offer = O.Showroom } end
	for _, c in O.Crates do
		for _, b in c.bundles do
			if b.product == product then return { kind = "crate", offer = c, count = b.count } end
		end
	end
	return nil
end

-- Odds as percentages, plus the text the shop prints. Exact values print as
-- they are; others keep 4 digits past the first non-zero digit and the
-- rounding note is shown (Roblox paid-random-items disclosure rules).
function O.odds(crate: any): ({ { type: string, percent: number, text: string } }, boolean)
	local total = 0
	for _, item in crate.items do total += item.weight end
	local out, rounded = {}, false
	for _, item in crate.items do
		local p = item.weight / total * 100
		local text
		if math.abs(p * 100 - math.round(p * 100)) < 1e-9 then
			text = string.format("%g%%", math.round(p * 100) / 100)
		else
			rounded = true
			local digits = 4 - math.floor(math.log10(p)) -- 4 places past the first non-zero digit
			text = string.format("%." .. math.max(0, digits) .. "f%%", p)
		end
		table.insert(out, { type = item.type, percent = p, text = text })
	end
	return out, rounded
end

-- Server pick: `r` is a number in [0, 1).
function O.pick(crate: any, r: number): string
	local total = 0
	for _, item in crate.items do total += item.weight end
	local x = r * total
	for _, item in crate.items do
		x -= item.weight
		if x < 0 then return item.type end
	end
	return crate.items[#crate.items].type
end

return O
