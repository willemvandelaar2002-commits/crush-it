--!strict
-- 2 Nov (vault: Live Ops Events and Updates): codes players type in the Rewards
-- menu (CODES tab). Each code works once per player. Post new ones in the group
-- and the game description with every update.
--   code      UPPER CASE, letters and digits (players' input is upper-cased)
--   reward    { cash = seconds of your earnings } | { boost = "Cash"|"Luck"|"Super", minutes = n }
--             | { crusher = "Rare"|"Epic"|... }   (several rewards: a list)
--   expires   optional "YYYY-MM-DD" (UTC, the code stops working at the start of that day)
local M = {}

M.Codes = {
	{ code = "CRUSHIT", reward = { { cash = 600 } } },
	{ code = "GOALS", reward = { { boost = "Luck", minutes = 15 }, { cash = 300 } }, expires = "2026-11-23" },
	-- 3 Nov (Willem): codes for the game description, one per reward kind
	{ code = "LUCKYROLL", reward = { { boost = "Luck", minutes = 15 } } },
	{ code = "REBIRTH", reward = { { boost = "Cash", minutes = 15 } } },
	{ code = "FREECRUSHER", reward = { { crusher = "Rare" } } },
	{ code = "PHONEUPDATE", reward = { { boost = "Super", minutes = 10 }, { cash = 600 } }, expires = "2026-11-17" },
}

M.MinCash = 100 -- a cash reward is never less than this
M.MaxLength = 20
M.Cooldown = 2 -- seconds between tries per player

local function expiry(text: string?): number?
	if not text then return nil end
	local y, m, d = string.match(text, "^(%d+)-(%d+)-(%d+)$")
	if not y then return nil end
	return os.time({ year = tonumber(y) :: number, month = tonumber(m) :: number, day = tonumber(d) :: number, hour = 0 })
end

-- The code entry for this input (trimmed, upper-cased), or nil.
function M.find(input: any): any
	if type(input) ~= "string" or #input > M.MaxLength then return nil end
	local clean = string.upper((string.gsub(input, "%s", "")))
	for _, entry in M.Codes do
		if entry.code == clean then return entry end
	end
	return nil
end

-- Has this code run out at `now` (unix seconds)?
function M.expired(entry: any, now: number): boolean
	local at = expiry(entry.expires)
	return at ~= nil and now >= at
end

return M
