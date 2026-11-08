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
		-- 8 Nov (Willem): up to SECRET
		{ rarity = "Rare", weight = 52 },
		{ rarity = "Epic", weight = 32 },
		{ rarity = "Legendary", weight = 13 },
		{ rarity = "Secret", weight = 3 },
	},
	CashMinutes = 20,
	-- plot-local spot (studs; x across, z toward the plaza), beside the walkway near the
	-- entrance, off the tutorial arrows
	Spot = { x = 14, z = 84, yaw = 0 },
	Away = { AfterMinutes = 8, Seconds = 12 },
	-- 8 Nov (Willem: "very interesting with an animation dropping"): client animation timings
	-- (seconds). A new crate falls from the sky (Drop), opening shakes it, blows the lid off
	-- with a beam in the rarity's colour (Open), and the next crate drops NextDropAfter later.
	Drop = { Warn = 0.9, Fall = 1.15, Height = 90 },
	Open = { Shake = 0.7, Burst = 1.4 },
	NextDropAfter = 3.6,
}
