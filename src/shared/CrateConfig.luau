--!strict
-- 8 Nov (Willem: retention ideas "your factory keeps running" + "something that finishes
-- overnight"): the MYSTERY CRATE (server/OvernightCrate, client/OvernightCrate).
--   * After the tutorial a crate lands on your plot. It opens FirstHours later (so a new
--     player has a reason to come back the next day), then every Hours after opening.
--   * Opening it: one free crusher (Rewards, by weight) + CashMinutes of your earnings.
--   * The "away" card (client): once per session after Away.AfterMinutes of play, it says
--     your factory keeps earning while you're away (Store.Offline) and when the crate opens,
--     with REMIND ME (Roblox's notification opt-in) when Roblox allows asking.
return {
	FirstHours = 8,
	Hours = 20,
	Rewards = {
		{ rarity = "Rare", weight = 55 },
		{ rarity = "Epic", weight = 33 },
		{ rarity = "Legendary", weight = 12 },
	},
	CashMinutes = 20,
	-- plot-local spot (studs; x across, z toward the plaza), beside the walkway
	Spot = { x = -12, z = 84, yaw = 0 },
	Away = { AfterMinutes = 8, Seconds = 12 },
}
