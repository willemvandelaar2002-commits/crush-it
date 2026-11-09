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
	-- 8 Nov: the Gem Pedestal adds a 6th roll pedestal
	local q = R.migrate({ cash = 10 }, id) local qs = q.crushers
	qs.upgrades.Pedestals = C.upgradeMax("Pedestals")
	check(R.pedestalCount(qs) == C.MaxPedestals, "five pedestals from the board")
	qs.rebirths = 1 qs.gems = 1000
	check(act(q, "GemUpgrade", { id = "Pedestal" }) and R.pedestalCount(qs) == C.MaxPedestals + 1 and #C.PedestalSpots == C.MaxPedestals + 1, "Gem Pedestal: a 6th pedestal")
	check(not act(q, "GemUpgrade", { id = "Pedestal" }), "only one Gem Pedestal")
	local _, _, offers = R.act(q, {}, "Roll", {}, 100, function() return 0.5 end, id, {})
	check(type(offers) == "table" and #offers == C.MaxPedestals + 1, "a roll fills all six")

	-- 8 Nov: the Gem Crusher at rebirth 5, awakened at rebirth 10
	local g = R.migrate({ cash = 10 }, id) local gs = g.crushers
	local function gemItems() local list = {} for _, v in gs.owned do if C.gemCrusher(v.type) then table.insert(list, v) end end return list end
	local function rebirthTo(n) gs.rebirths = n - 1 gs.plotLevel = C.Rebirth.MinPlot g.cash = C.rebirthCost(n - 1) return act(g, "Rebirth") end
	check(rebirthTo(4) and #gemItems() == 0, "no Gem Crusher before rebirth 5")
	local ok5, message5 = rebirthTo(5)
	local list = gemItems()
	check(ok5 and #list == 1 and list[1].type == "GemCrusher" and list[1].rarity == "Mythic" and message5:find("GEM CRUSHER"), "rebirth 5 gives the Gem Crusher")
	check(gs.seen.GemCrusher == true, "the Gem Crusher is in the Index")
	local gemId = list[1].id
	gs.equipped["1"] = gemId list[1].level = 7
	check(rebirthTo(6) and #gemItems() == 1, "later rebirths don't give another")
	check(not act(g, "TrashMany", { ids = { gemId } }) and #gemItems() == 1, "the Gem Crusher can't be trashed (equipped)")
	gs.equipped = {}
	local extra = { id = id(), type = "Bumper", rarity = "Common", modifier = "Standard", level = 1 } table.insert(gs.owned, extra)
	act(g, "TrashMany", { ids = { gemId, extra.id } })
	check(#gemItems() == 1 and not R.find(g, extra.id), "trashing a pile keeps the Gem Crusher")
	check(not act(g, "Recycle", { id = gemId }), "the Gem Crusher can't be recycled")
	local okA, messageA = rebirthTo(10)
	list = gemItems()
	check(okA and #list == 1 and list[1].id == gemId and list[1].type == "GemCrusherAwakened" and messageA:find("AWAKENED"), "rebirth 10 awakens the same crusher")
	gs.bays = 3 gs.equipped["2"] = gemId
	check(math.abs(R.gemRate(g) - C.GemCrushers[2].gems) < 1e-9, "the Awakened Gem Crusher makes " .. C.GemCrushers[2].gems .. " Gems / min in a bay")
	check(C.typeById("GemCrusherAwakened").value > C.typeById("GemCrusher").value and C.typeById("GemCrusher").value > 660, "stronger than every Mythic, awakened stronger still")
	-- old saves past rebirth 5 / 10 get theirs on load
	local old = R.migrate({ cash = 10 }, id) old.crushers.rebirths = 7 old = R.migrate(old, id)
	local found = 0 for _, v in old.crushers.owned do if v.type == "GemCrusher" then found += 1 end end
	check(found == 1 and #R.migrate(R.copy(old), id).crushers.owned == #old.crushers.owned, "a rebirth 7 save gets one Gem Crusher, once")
	for _, r in C.Rarities do for _, t in r.types do check(not C.gemCrusher(t), "the Gem Crusher is never rolled") end end
	-- 9 Nov: the first rebirth pays enough for something in the Gem Shop
	local cheapest = G.Crate.Cost for _, u in G.Upgrades do cheapest = math.min(cheapest, G.cost(u.id, 0)) end
	check(G.forRebirth(1) == 25 and G.forRebirth(1) >= G.Crate.Cost and G.forRebirth(2) == 15 and G.forRebirth(10) == 55, "rebirth 1 pays 25 (a crate or an upgrade), later ones unchanged")
	-- 9 Nov: Gems are whole numbers; old fractional saves split into gems + gemDust
	local f = R.migrate({ cash = 10 }, id) f.crushers.gems = 12.75 f = R.migrate(f, id)
	check(f.crushers.gems == 12 and math.abs(f.crushers.gemDust - 0.75) < 1e-9, "12.75 Gems -> 12 Gems + 0.75 dust")
	f.crushers.gems = 3.5 f.crushers.gemDust = 0.75 f = R.migrate(f, id)
	check(f.crushers.gems == 4 and math.abs(f.crushers.gemDust - 0.25) < 1e-9, "dust over 1 becomes a Gem")
	-- 9 Nov: HEAD START and NEST EGG change where a rebirth starts
	local h = R.migrate({ cash = 10 }, id) local hs = h.crushers
	local function rebirthOnce() hs.plotLevel = C.Rebirth.MinPlot h.cash = C.rebirthCost(hs.rebirths) return act(h, "Rebirth") end
	check(rebirthOnce() and hs.plotLevel == 0 and hs.bays == 1 and h.cash == C.Rebirth.StartCash, "no Gem upgrades: a rebirth starts from scratch")
	hs.gemUps.HeadStart = 1
	local ok1, msg1 = rebirthOnce()
	check(ok1 and hs.plotLevel == 1 and hs.bays == C.bayCapacity(0) and msg1:find("Head Start"), "Head Start 1: FACTORY II with Factory I's 12 bays open")
	hs.gemUps.HeadStart = 2 hs.gemUps.NestEgg = 5
	local price = C.rebirthCost(hs.rebirths)
	check(rebirthOnce() and hs.plotLevel == 2 and hs.bays == C.bayCapacity(1), "Head Start 2: FACTORY III with 24 bays open")
	check(h.cash == C.Rebirth.StartCash + math.floor(price * 0.05), "Nest Egg 5: start with 5% of the rebirth price")
	check(hs.plotLevel < C.Rebirth.MinPlot and not act(h, "Rebirth"), "a Head Start never skips the run to the next rebirth")
	hs.gems = 1000 hs.gemUps.HeadStart = 0
	check(act(h, "GemUpgrade", { id = "HeadStart" }) and act(h, "GemUpgrade", { id = "HeadStart" }) and not act(h, "GemUpgrade", { id = "HeadStart" })
		and hs.gems == 1000 - G.cost("HeadStart", 0) - G.cost("HeadStart", 1), "Head Start: two levels, 40 + 120 Gems")
	print("Gems spec: " .. checks .. " checks passed")
end
