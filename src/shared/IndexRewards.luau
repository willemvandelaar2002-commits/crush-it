--!strict
-- Index milestone rewards (like the reference game's "Unlocks needed" bar):
-- find N different crushers, claim the milestone once. Found = ever owned
-- (crushers.seen, kept even after recycling). Each milestone pays one or more:
--   { kind = "cash", seconds = n }          n seconds of your current earnings
--   { kind = "boost", id = "Luck", minutes = n }   a timed hub boost (BoostConfig)
--   { kind = "crusher", rarity = "Epic" }   a random crusher of that rarity
--   { kind = "luck", percent = n }          PERMANENT: +n% chance of better-than-Common rolls
-- The server (server/IndexRewards) checks the count and pays; this module is
-- the shared list and the maths.
local C = require(script.Parent.CrusherConfig)

local M = {}

M.List = {
	{ need = 5, rewards = { { kind = "cash", seconds = 600 } } },
	{ need = 10, rewards = { { kind = "luck", percent = 2 }, { kind = "boost", id = "Luck", minutes = 15 } } },
	{ need = 20, rewards = { { kind = "crusher", rarity = "Epic" }, { kind = "cash", seconds = 1800 } } },
	{ need = 30, rewards = { { kind = "luck", percent = 3 }, { kind = "boost", id = "Cash", minutes = 30 } } },
	{ need = 40, rewards = { { kind = "crusher", rarity = "Legendary" }, { kind = "luck", percent = 3 } } },
	{ need = 50, rewards = { { kind = "crusher", rarity = "Mythic" }, { kind = "luck", percent = 5 } } },
}

-- How many different crushers this save has found.
function M.found(s: any): number
	local n = 0
	for id in (if type(s) == "table" and type(s.seen) == "table" then s.seen else {}) do
		if C.typeById(id) then n += 1 end
	end
	return n
end

local function claimedSet(s: any): { [number]: boolean }
	local out = {}
	for _, i in (if type(s) == "table" and type(s.indexClaimed) == "table" then s.indexClaimed else {}) do out[i] = true end
	return out
end
M.claimedSet = claimedSet

-- Permanent luck bonus from claimed milestones, as a fraction (0.13 = +13%).
function M.luck(s: any): number
	local total = 0
	local claimed = claimedSet(s)
	for i, m in M.List do
		if claimed[i] then
			for _, r in m.rewards do if r.kind == "luck" then total += r.percent end end
		end
	end
	return total / 100
end

-- The first milestone not claimed yet (index, entry), or nil when all are done.
function M.next(s: any): (number?, any)
	local claimed = claimedSet(s)
	for i, m in M.List do
		if not claimed[i] then return i, m end
	end
	return nil, nil
end

-- Can milestone i be claimed now?
function M.ready(s: any, i: number): boolean
	local m = M.List[i]
	return m ~= nil and not claimedSet(s)[i] and M.found(s) >= m.need
end

-- Short text for one reward (cash amounts need the earning rate).
function M.text(r: any, cps: number?, cash: ((number) -> string)?): string
	if r.kind == "cash" then
		local amount = math.max(100, math.floor((cps or 0) * r.seconds))
		return if cash then cash(amount) else tostring(amount)
	elseif r.kind == "boost" then
		return "2x " .. r.id .. " " .. r.minutes .. "m"
	elseif r.kind == "crusher" then
		return r.rarity
	elseif r.kind == "luck" then
		return "+" .. r.percent .. "% luck"
	end
	return ""
end

return M
