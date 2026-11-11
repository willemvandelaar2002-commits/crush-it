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
	check(act(d, "Rebirth") and s.rebirths == 1 and s.gems == 0, "9 Nov: rebirths pay no Gems (the Gem Mine does)")
	s.gems = 10000
	check(act(d, "GemUpgrade", { id = "Cash" }) and s.gemUps.Cash == 1 and s.gems == 10000 - G.cost("Cash", 0), "Gem Cash level 1 charges its cost")
	check(not act(d, "GemUpgrade", { id = "Nope" }), "unknown upgrade refused")
	s.plotLevel = C.Rebirth.MinPlot d.cash = C.rebirthCost(1)
	local before = s.gems
	check(act(d, "Rebirth") and s.gemUps.Cash == 1 and s.gems == before, "upgrades and Gems survive a rebirth")
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

	-- 9 Nov: no bay trickle any more
	local e = R.migrate({ cash = 10 }, id) e.crushers.bays = 3
	local ex = { id = id(), type = C.rarity("Divine").types[1], rarity = "Divine", modifier = "Standard", level = 1 }
	table.insert(e.crushers.owned, ex) e.crushers.equipped["2"] = ex.id
	check(R.gemRate(e) == 0, "a Divine in a bay makes no Gems: all Gems come from the mine")

	-- 8 Nov: the Gem Pedestal adds a 6th roll pedestal
	local q = R.migrate({ cash = 10 }, id) local qs = q.crushers
	qs.upgrades.Pedestals = C.upgradeMax("Pedestals")
	check(R.pedestalCount(qs) == C.MaxPedestals, "five pedestals from the board")
	qs.rebirths = 1 qs.gems = 10000
	check(act(q, "GemUpgrade", { id = "Pedestal" }) and R.pedestalCount(qs) == C.MaxPedestals + 1 and #C.PedestalSpots == C.MaxPedestals + 1, "Gem Pedestal: a 6th pedestal")
	check(not act(q, "GemUpgrade", { id = "Pedestal" }), "only one Gem Pedestal")
	local _, _, offers = R.act(q, {}, "Roll", {}, 100, function() return 0.5 end, id, {})
	check(type(offers) == "table" and #offers == C.MaxPedestals + 1, "a roll fills all six")

	-- 9 Nov: THE GEM MINE numbers (GemConfig.Mine; the server part is server/GemMine)
	local m = R.migrate({ cash = 10 }, id) local ms = m.crushers
	check(G.mineCrushSeconds(ms) == G.Mine.CrushSeconds and G.mineDrops(ms) == G.Mine.Drops and G.mineValue(ms) == 1 and G.mineMagnet(ms) == G.Mine.Magnet, "a fresh mine: base numbers")
	check(math.abs(G.minePerMinute(ms) - 30) < 1e-9, "base: 30 Gems a minute (10 Nov: a crush every 2 s, 1 gem)")
	for _, u in G.Upgrades do if u.group == "mine" then ms.gemUps[u.id] = u.max end end
	check(G.mineCrushSeconds(ms) >= 1 and G.mineDrops(ms) == 3 and G.mineValue(ms) == 2 and G.mineMagnet(ms) == 20, "every mine upgrade has a cap")
	ms.rebirths = G.Mine.AwakenRebirths
	check(G.mineAwake(ms) and G.mineValue(ms) == 2 * G.Mine.AwakenValue, "rebirth 5 awakens the crusher (x1.5 value)")
	check(G.minePerMinute(ms) <= 750, "fully upgraded and awake stays under ~750 Gems a minute (" .. math.floor(G.minePerMinute(ms)) .. ")")
	-- 11 Nov: the max of More Gems, Gem Value and Gem Magnet grows by 1 every 5 rebirths, at most +2
	local mags = G.upgrade("Magnet")
	local step = mags.rebirthBonus
	check(G.maxLevel(mags, 4) == mags.max and G.maxLevel(mags, 5) == mags.max + step and G.maxLevel(mags, 10) == mags.max + 2 * step and G.maxLevel(mags, 50) == mags.max + 2 * step, "rebirths 5 and 10 raise the magnet max, then it stops")
	check(G.maxLevel(G.upgrade("MineSpeed"), 50) == G.upgrade("MineSpeed").max and G.maxLevel(G.upgrade("Cash"), 50) == G.upgrade("Cash").max, "Crush Speed and the other upgrades keep their max")
	check(G.cost("Magnet", mags.max, 4) == nil and G.cost("Magnet", mags.max, 5) ~= nil, "a level past the old max only after rebirth 5")
	check(G.nextCapRebirth(mags, 0) == 5 and G.nextCapRebirth(mags, 7) == 10 and G.nextCapRebirth(mags, 10) == nil, "the shop can say when the next level opens")
	local cap = R.migrate({ cash = 10 }, id) local cs = cap.crushers
	cs.rebirths = 4 cs.gems = 10 ^ 7 cs.gemUps.Magnet = mags.max
	check(not act(cap, "GemUpgrade", { id = "Magnet" }), "rebirth 4: the magnet is maxed")
	cs.rebirths = 5
	check(act(cap, "GemUpgrade", { id = "Magnet" }) and cs.gemUps.Magnet == mags.max + 1, "rebirth 5: more magnet levels")
	check(R.migrate(cap, id).crushers.gemUps.Magnet == mags.max + 1, "a raised level survives a reload")
	-- 11 Nov: more, smaller levels; a save from before converts once (x5, the magnet x3)
	local old = R.migrate({ cash = 10 }, id)
	old.crushers.gemUpsV = nil old.crushers.gemUps = { MineSpeed = 4, MineDrops = 2, MineValue = 1, Magnet = 5, Cash = 3 }
	local os2 = R.migrate(old, id).crushers
	check(os2.gemUps.MineSpeed == 20 and os2.gemUps.MineDrops == 10 and os2.gemUps.MineValue == 5 and os2.gemUps.Magnet == 15 and os2.gemUps.Cash == 3, "old mine levels convert (x5, magnet x3), others stay")
	check(G.mineCrushSeconds(os2) == 1 and G.mineDrops(os2) == 3 and G.mineValue(os2) == 1.5 and G.mineMagnet(os2) == 20, "a converted save keeps exactly what it had")
	local again = R.migrate(old, id).crushers
	check(again.gemUps.MineDrops == 10 and again.gemUps.Magnet == 15, "converted only once")
	local fr = R.migrate({ cash = 10 }, id).crushers fr.gemUps.MineDrops = 3
	local hits = 0 for i = 1, 100 do hits += G.dropsNow(fr, (i - 0.5) / 100) end
	check(G.mineDrops(fr) > 1.59 and G.mineDrops(fr) < 1.61 and hits == 160, "More Gems level 3: 1.6 gems a crush on average (" .. hits .. " in 100)")
	for _, u in G.Upgrades do if u.group == "mine" then ms.gemUps[u.id] = G.maxLevel(u, 10) end end
	ms.rebirths = 10
	check(G.minePerMinute(ms) <= 1400, "rebirth 10, everything maxed: at most ~1,350 Gems a minute (" .. math.floor(G.minePerMinute(ms)) .. ")")
	ms.rebirths = G.Mine.AwakenRebirths
	for _, u in G.Upgrades do if u.group == "mine" then ms.gemUps[u.id] = u.max end end
	check(G.upgrade("MineSpeed").group == "mine" and G.Upgrades[1].group == "mine", "mine upgrades are listed first in the Gem Shop")
	check(G.Crate.Cost >= 500, "the Gem Crate costs more now that the mine pays Gems")
	for _, r in C.Rarities do for _, t in r.types do check(not C.gemCrusher(t), "no bay Gem Crusher any more") end end
	local reb = R.migrate({ cash = 10 }, id) reb.crushers.plotLevel = C.Rebirth.MinPlot reb.cash = C.rebirthCost(0)
	local okR, msgR = act(reb, "Rebirth")
	check(okR and msgR:find("GEM MINE"), "rebirth 1 says the Gem Mine is open")

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
	hs.gems = 10000 hs.gemUps.HeadStart = 0
	check(act(h, "GemUpgrade", { id = "HeadStart" }) and act(h, "GemUpgrade", { id = "HeadStart" }) and not act(h, "GemUpgrade", { id = "HeadStart" })
		and hs.gems == 10000 - G.cost("HeadStart", 0) - G.cost("HeadStart", 1), "Head Start: two levels, 120 + 360 Gems")
	print("Gems spec: " .. checks .. " checks passed")
end
