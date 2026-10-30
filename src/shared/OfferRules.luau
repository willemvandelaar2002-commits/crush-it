--!strict
-- Offer fulfilment, no Roblox services: server/Offers calls it from inside
-- Shop's receipt handler (which already remembers PurchaseIds and saves before
-- answering PurchaseGranted). Everything is checked first and then applied in
-- one go without yielding, so a receipt is either fully granted or not at all.
--
-- Save: d.offers = { owned = { StarterPack = true, PrismMech = true },
--                    reveals = { { id, crate, type, at } ... } }  -- crate results not shown yet
local O = require(script.Parent.OfferConfig)
local C = require(script.Parent.CrusherConfig)

local R = {}

function R.migrate(d: any)
	local o = if type(d.offers) == "table" then d.offers else {}
	o.owned = if type(o.owned) == "table" then o.owned else {}
	o.reveals = if type(o.reveals) == "table" then o.reveals else {}
	for i = #o.reveals, 1, -1 do
		local r = o.reveals[i]
		if type(r) ~= "table" or type(r.id) ~= "string" or not C.typeById(r.type) then table.remove(o.reveals, i) end
	end
	d.offers = o
	return o
end

function R.owns(d: any, offerId: string): boolean
	return type(d.offers) == "table" and type(d.offers.owned) == "table" and d.offers.owned[offerId] == true
end

local function validType(rarity: string, typeId: string): boolean
	local r = C.rarity(rarity)
	return r ~= nil and C.rarityOf(typeId) == r
end

-- hooks = { giveCrusher(rarity, type) -> name?, addCash(n), addBoost(id, minutes), random() -> [0,1) }
-- Returns ok, { text, reveal?, repeatOnce? } or false, problem (nothing changed).
function R.fulfil(d: any, product: string, purchaseId: string, hooks: any): (boolean, any)
	local entry = O.byProduct(product)
	if not entry then return false, "not an offer product" end
	local offers = R.migrate(d)
	local offer = entry.offer
	if entry.kind == "starter" or entry.kind == "showroom" then
		if not validType(offer.rarity, offer.crusher) then return false, "bad offer crusher" end
		if entry.kind == "starter" and offer.boost and offer.boost.minutes <= 0 then return false, "bad boost" end
		-- A second paid receipt for a one-time offer (two servers racing a
		-- prompt) still delivers what was paid for; it is only logged.
		local again = offers.owned[offer.id] == true
		local name = hooks.giveCrusher(offer.rarity, offer.crusher)
		if not name then error("offer crusher grant failed") end
		local parts = { name }
		if entry.kind == "starter" then
			if (offer.cashMinutes or 0) > 0 then hooks.addCash(hooks.cashFor(offer.cashMinutes * 60)) table.insert(parts, "cash") end
			if offer.boost then hooks.addBoost(offer.boost.id, offer.boost.minutes) table.insert(parts, "boost") end
		end
		offers.owned[offer.id] = true
		return true, { text = offer.title .. ": " .. table.concat(parts, " + ") .. "!", repeatOnce = again }
	end
	-- crate: pick every result first, then grant them all
	local picks = {}
	for i = 1, entry.count do
		local t = O.pick(offer, hooks.random())
		local r = C.rarityOf(t)
		if not r or not validType(r.name, t) then return false, "bad crate item" end
		picks[i] = { type = t, rarity = r.name }
	end
	local names = {}
	for i, pick in picks do
		local t = pick.type
		local name = hooks.giveCrusher(pick.rarity, t)
		if not name then error("crate crusher grant failed") end
		names[i] = name
		table.insert(offers.reveals, { id = purchaseId .. "#" .. i, crate = offer.id, type = t })
	end
	while #offers.reveals > O.MaxReveals do table.remove(offers.reveals, 1) end
	return true, { text = offer.title .. ": " .. table.concat(names, ", ") .. "!", reveal = true }
end

-- The player saw (or skipped) a reveal: forget it. The crusher was granted with the receipt.
function R.seen(d: any, revealId: any): boolean
	local offers = R.migrate(d)
	for i, r in offers.reveals do
		if r.id == revealId then table.remove(offers.reveals, i) return true end
	end
	return false
end

return R
