--!strict
-- Pure quest transactions on a profile (server and tests). Times are os.time().
--   d.quests = { Daily = { key, base = { [stat] = value }, claimed = { [id] = true } }, Weekly = {...} }
--   d.questTokens, d.stats (counters the game bumps: play, sells, buys, levels, upgrades, spins)
local Q = require(script.Parent.QuestConfig)
local R = {}
local DAY = 86400
local STATS = { "play", "rolls", "crushed", "sells", "buys", "levels", "upgrades", "spins" }

function R.stat(d: any, key: string): number
	if key == "rolls" then return (d.crushers and d.crushers.rolls) or 0 end
	if key == "crushed" then return d.crushed or 0 end
	return (d.stats and d.stats[key]) or 0
end

-- Period index: days since 1970 (UTC); weeks start on Monday.
function R.key(period: string, now: number): number
	local day = math.floor(now / DAY)
	return if period == "Weekly" then math.floor((day + 3) / 7) else day
end
function R.nextAt(period: string, now: number): number
	local key = R.key(period, now)
	return if period == "Weekly" then ((key + 1) * 7 - 3) * DAY else (key + 1) * DAY
end

local function num(v: any): number
	return if type(v) == "number" and v == v and math.abs(v) < 1e15 then v else 0
end

function R.migrate(d: any)
	d.questTokens = math.max(0, math.floor(num(d.questTokens)))
	local stats = if type(d.stats) == "table" then d.stats else {}
	d.stats = {}
	for _, key in STATS do
		if key ~= "rolls" and key ~= "crushed" then d.stats[key] = math.max(0, num(stats[key])) end
	end
	local quests = if type(d.quests) == "table" then d.quests else {}
	d.quests = {}
	for _, period in Q.Periods do
		local p = quests[period]
		if type(p) == "table" and type(p.key) == "number" and type(p.base) == "table" and type(p.claimed) == "table" then
			local base, claimed = {}, {}
			for _, key in STATS do base[key] = num(p.base[key]) end
			for id, v in p.claimed do if type(id) == "string" and v == true then claimed[id] = true end end
			d.quests[period] = { key = p.key, base = base, claimed = claimed }
		end
	end
end

-- Count something for quests (e.g. R.count(d, "sells")).
function R.count(d: any, key: string, n: number?)
	d.stats = d.stats or {}
	d.stats[key] = (d.stats[key] or 0) + (n or 1)
end

-- A new day / week starts the lists over from the current stats.
function R.refresh(d: any, now: number)
	d.quests = d.quests or {}
	for _, period in Q.Periods do
		local key = R.key(period, now)
		local p = d.quests[period]
		if not p or p.key ~= key then
			local base = {}
			for _, stat in STATS do base[stat] = R.stat(d, stat) end
			d.quests[period] = { key = key, base = base, claimed = {} }
		end
	end
end

function R.find(period: string, id: any): any
	for _, q in Q.list(period) do if q.id == id then return q end end
	return nil
end

function R.progress(d: any, period: string, q: any): number
	local p = d.quests[period]
	if not p then return 0 end
	return math.clamp(R.stat(d, q.stat) - (p.base[q.stat] or 0), 0, q.goal)
end

function R.claim(d: any, period: any, id: any, now: number): (boolean, any)
	if period ~= "Daily" and period ~= "Weekly" then return false, "Unknown quest list." end
	R.refresh(d, now)
	local q = R.find(period, id)
	if not q then return false, "Unknown quest." end
	local p = d.quests[period]
	if p.claimed[q.id] then return false, "Already claimed." end
	if R.progress(d, period, q) < q.goal then return false, "Not finished yet." end
	p.claimed[q.id] = true
	d.questTokens += q.reward
	return true, q.reward
end

-- Pays the cost; the caller grants the item (and refunds with R.refund if it can't).
function R.buy(d: any, id: any): (boolean, any)
	for _, item in Q.Shop do
		if item.id == id then
			if d.questTokens < item.cost then return false, "Not enough " .. Q.TokenName .. "." end
			d.questTokens -= item.cost
			return true, item
		end
	end
	return false, "Unknown item."
end
function R.refund(d: any, item: any) d.questTokens += item.cost end

-- Anything ready to claim? (for the "!" badges)
function R.ready(d: any): boolean
	for _, period in Q.Periods do
		local p = d.quests[period]
		if p then
			for _, q in Q.list(period) do
				if not p.claimed[q.id] and R.progress(d, period, q) >= q.goal then return true end
			end
		end
	end
	return false
end

return R
