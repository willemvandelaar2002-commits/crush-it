--!strict
-- 8 Nov: GEMS (Shared/GemConfig, CrusherRules "Rebirth" / "GemUpgrade" / "GemCrate" / gemRate).
-- Run explicitly in Studio. Pure table fixtures never touch a live profile.
return function()
	local C = require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R = require(game.ReplicatedStorage.Shared.CrusherRules)
	local G = require(game.ReplicatedStorage.Shared.GemConfig)
	local n = 0
	local function id() n += 1 return "gem-fixture-" .. n end
	local checks = 0
	local function check(v, message) assert(v, message) checks += 1 end
	local function act(d, name, args, random) return R.act(d, {}, name, args or {}, 0, random or function() return 0.1 end, id, {}) end

	-- odds add up to 100% and every crate rarity has crushers
	local total = 0 for _, o in G.Crate.Odds do total += o.chance check(#C.rarity(o.rarity).types > 0, o.rarity .. " has crushers for the Gem Crate") end
	check(math.abs(total - 1) < 1e-9, "Gem Crate chances add up to 100%")

	-- migrate: fresh saves start at 0 Gems and level 0 upgrades
	local d = R.migrate({ cash = 10 }, id)
	local s = d.crushers
	check(s.gems == 0 and s.gemUps.Cash == 0 and s.gemUps.Rolls == 0, "fresh save: no Gems, no upgrades")
	check(not act(d, "GemCrate") and not act(d, "GemUpgrade", { id = "Cash" }), "Gem Shop is closed before the first rebirth")

	-- rebirth pays Gems and keeps Gems + upgrades
	s.plotLevel = C.Rebirth.MinPlot d.cash = C.rebirthCost(0)
	check(act(d, "Rebirth") and s.rebirths == 1 and s.gems == G.forRebirth(1), "rebirth 1 pays " .. G.forRebirth(1) .. " Gems")
	s.gems = 1000
	check(act(d, "GemUpgrade", { id = "Cash" }) and s.gemUps.Cash == 1 and s.gems == 1000 - G.cost("Cash", 0), "Gem Cash level 1 charges its cost")
	check(not act(d, "GemUpgrade", { id = "Nope" }), "unknown upgrade refused")
	s.plotLevel = C.Rebirth.MinPlot d.cash = C.rebirthCost(1)
	local before = s.gems
	check(act(d, "Rebirth") and s.gemUps.Cash == 1 and s.gems == before + G.forRebirth(2), "upgrades and Gems survive a rebirth")
	check(math.abs(G.cashMult(s) - 1.1) < 1e-9 and G.luckMult(s) == 1, "Gem Cash level 1 = x1.1 cash")

	-- max level
	s.gemUps.Rolls = G.upgrade("Rolls").max
	check(not act(d, "GemUpgrade", { id = "Rolls" }) and s.gemUps.Rolls == G.upgrade("Rolls").max, "no level past the max")

	-- the crate: charges Gems, adds a crusher of an odds rarity
	before = s.gems local owned = #s.owned
	local ok, _, item = act(d, "GemCrate", {}, function() return 0.99 end)
	check(ok and s.gems == before - G.Crate.Cost and #s.owned == owned + 1 and item.rarity == "Divine", "a 0.99 roll is the Divine slot")
	s.gems = G.Crate.Cost - 1
	check(not act(d, "GemCrate") and #s.owned == owned + 1, "not enough Gems: nothing happens")

	-- the trickle counts Exotic+ crushers in a bay only
	local e = R.migrate({ cash = 10 }, id)
	local es = e.crushers es.bays = 3
	local ex = { id = id(), type = C.rarity("Exotic").types[1], rarity = "Exotic", modifier = "Standard", level = 1 }
	table.insert(es.owned, ex)
	check(R.gemRate(e) == 0, "no Exotic in a bay: no trickle")
	es.equipped["2"] = ex.id
	check(math.abs(R.gemRate(e) - G.Trickle.Exotic) < 1e-9, "an Exotic in a bay trickles " .. G.Trickle.Exotic .. "/min")
	print("Gems spec: " .. checks .. " checks passed")
end
