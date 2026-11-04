--!strict
-- 4 Nov (vault: Live Ops Events and Updates, Update Cadence "use a consistent day";
-- Retention "D30 hooks are events"): LUCKY WEEKEND, every week, for everyone.
--   Saturday 00:00 to Monday 00:00 UTC (01:00 Dutch winter time): 2x luck on crusher
--   rolls for every player, stacking with the Lucky pass, boosts and rebirth luck.
--   From Friday 00:00 UTC the HUD counts down to it; during it, to its end.
-- Real timers only (vault: "every timer is real"): it happens every weekend, as shown.
-- Willem: add a weekly Experience Event "Lucky Weekend" (Creator Hub > Events) so
-- players can tap Notify Me, and say "2x luck every weekend" in the description.
local W = {}

W.Enabled = true
W.Name = "LUCKY WEEKEND"
W.Luck = 2
W.TeaseDays = 1 -- show "in 9h" from this many days before

local DAY = 86400
-- weekday with Monday = 0 (1 Jan 1970 was a Thursday = 3)
local function weekday(t: number): (number, number)
	local day = t // DAY
	return (day + 3) % 7, day
end

-- is it on at unix time t?
function W.on(t: number): boolean
	if not W.Enabled then return false end
	local wd = weekday(t)
	return wd >= 5
end
-- (on, seconds until it ends / starts); `starts` is nil when the tease isn't showing
function W.status(t: number): (boolean, number?)
	if not W.Enabled then return false, nil end
	local wd, day = weekday(t)
	if wd >= 5 then return true, (day - wd + 7) * DAY - t end
	local startsAt = (day - wd + 5) * DAY
	if startsAt - t <= W.TeaseDays * DAY then return false, startsAt - t end
	return false, nil
end
function W.luck(t: number): number return if W.on(t) then W.Luck else 1 end

return W
