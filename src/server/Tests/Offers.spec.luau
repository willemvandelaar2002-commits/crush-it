--!strict
-- Offer config + fulfilment, pure (no players, no Robux, no saves).
return function()
	local S = game.ReplicatedStorage.Shared
	local O = require(S.OfferConfig)
	local R = require(S.OfferRules)
	local Store = require(S.Store)
	local checks = 0
	local function check(v: any, message: string) checks += 1 assert(v, message) end

	-- every offer product exists in Store and maps back
	for _, key in { O.StarterPack.product, O.Showroom.product, O.Crates[1].bundles[1].product } do
		check(Store.productById(key) ~= nil, key .. " is a Store product")
		check(O.byProduct(key) ~= nil, key .. " maps to an offer")
	end
	check(O.byProduct("CashSmall") == nil, "other products are not offers")

	-- odds: all three outcomes, percentages that add to 100
	local crate = O.Crates[1]
	local odds, rounded = O.odds(crate)
	check(#odds == 9, "nine outcomes")
	local total = 0
	for _, o in odds do total += o.percent end
	check(math.abs(total - 100) < 1e-9, "odds add to 100%")
	check(rounded and odds[1].text == "18%" and odds[9].text == "3.3333%", "exact odds print exactly, others with 4 digits + the rounding note: " .. odds[9].text)
	local exact = O.odds({ items = { { type = "A", weight = 1 }, { type = "B", weight = 3 } } })
	check(exact[1].text == "25%" and exact[2].text == "75%", "exact odds print exactly")
	check(O.pick(crate, 0) == "DuckyDynamo" and O.pick(crate, 0.55) == "ArcadeClaw" and O.pick(crate, 0.999) == "PhantomPirate", "pick follows the weights")
	local C = require(S.CrusherConfig)
	for _, o in odds do check(C.rarityOf(o.type) ~= nil and C.typeById(o.type) ~= nil, o.type .. " is a known type with a rarity") end

	local function profile() return { cash = 0 } end
	local log
	local function hooks(r: number?)
		log = { crushers = {}, cash = 0, boosts = {} }
		return {
			giveCrusher = function(rarity, t) table.insert(log.crushers, rarity .. ":" .. t) return t end,
			addCash = function(n) log.cash += n end,
			cashFor = function(seconds) return seconds end,
			addBoost = function(id, m) table.insert(log.boosts, id .. ":" .. m) end,
			random = function() return r or 0.5 end,
		}
	end

	-- Starter Pack: crusher + cash + boost, once
	local d = profile()
	local ok, res = R.fulfil(d, O.StarterPack.product, "p1", hooks())
	check(ok and #log.crushers == 1 and log.crushers[1] == "Mythic:CandyColossus", "starter gives Candy Colossus")
	check(log.cash == O.StarterPack.cashMinutes * 60 and log.boosts[1] == "Cash:" .. O.StarterPack.boost.minutes, "starter gives its cash and boost")
	check(R.owns(d, "StarterPack") and not res.repeatOnce, "starter owned after purchase")
	ok, res = R.fulfil(d, O.StarterPack.product, "p2", hooks())
	check(ok and res.repeatOnce and #log.crushers == 1, "a second paid starter receipt still delivers (and is flagged)")

	-- Prism Mech
	d = profile()
	ok = R.fulfil(d, O.Showroom.product, "p3", hooks())
	check(ok and log.crushers[1] == "Mythic:PrismMech" and log.cash == 0 and R.owns(d, "PrismMech"), "Prism Mech: just the crusher, owned")

	-- Crate: picked, granted and saved as a reveal; seen removes only the reveal
	d = profile()
	ok, res = R.fulfil(d, "FactoryCrate1", "p4", hooks(0.999))
	check(ok and res.reveal and log.crushers[1] == "Mythic:PhantomPirate", "crate grants the picked crusher")
	check(#d.offers.reveals == 1 and d.offers.reveals[1].type == "PhantomPirate" and d.offers.reveals[1].id == "p4#1", "crate result saved for the reveal")
	ok = R.fulfil(d, "FactoryCrate1", "p4b", hooks(0.1))
	check(ok and log.crushers[1] == "Epic:DuckyDynamo", "crate crushers arrive with their own rarity")
	R.seen(d, "p4b#1")
	local saved = game.HttpService:JSONDecode(game.HttpService:JSONEncode(d))
	R.migrate(saved)
	check(saved.offers.reveals[1].type == "PhantomPirate", "reveal survives a save round trip (same result after rejoin)")
	check(not R.seen(d, "nope") and #d.offers.reveals == 1, "unknown reveal id changes nothing")
	check(R.seen(d, "p4#1") and #d.offers.reveals == 0, "seen clears the reveal")
	check(not R.owns(d, "FactoryCrate"), "crates are never 'owned'")
	for i = 1, O.MaxReveals + 5 do R.fulfil(d, "FactoryCrate1", "q" .. i, hooks()) end
	check(#d.offers.reveals == O.MaxReveals, "unseen reveals are capped")

	-- refusals change nothing
	d = profile()
	ok = R.fulfil(d, "CashSmall", "p5", hooks())
	check(not ok and #log.crushers == 0, "non-offer product refused")
	-- a failed crusher grant raises before cash/boost are paid (receipt retried, no partial grant)
	d = profile()
	local h = hooks() h.giveCrusher = function() return nil end
	local good = pcall(R.fulfil, d, O.StarterPack.product, "p6", h)
	check(not good and log.cash == 0 and #log.boosts == 0 and not R.owns(d, "StarterPack"), "failed grant leaves nothing half-done")

	-- migrate drops broken reveals
	d = { offers = { owned = "x", reveals = { { id = "a", type = "NotAType" }, 5, { id = "b", type = "SeraphPress" } } } }
	R.migrate(d)
	check(type(d.offers.owned) == "table" and #d.offers.reveals == 1 and d.offers.reveals[1].id == "b", "migrate repairs offers")
	print("Offers: " .. checks .. " checks passed")
	return { passed = checks }
end
