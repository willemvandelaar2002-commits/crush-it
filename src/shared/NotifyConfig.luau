--!strict
-- 4 Nov: experience notifications (vault: Experience Notifications and Return Prompts;
-- Roblox docs Oct 2026). One notification per player per day at most (Roblox's rule);
-- only players 13+ who opted in get them; Roblox may still drop some (spam filter).
--
-- Willem: Creator Dashboard > Crush It > Engagement > Notifications > create a string
-- (max 99 characters, no parameters needed), copy its asset id into DailyReady.
-- Suggested text:
--   Your next daily reward is ready, and your factory kept crushing while you were away!
-- "" = notifications off (nothing is scheduled or sent).
return {
	DailyReady = "",
	-- when a player leaves, the ping is due this many hours later (about the same time
	-- tomorrow, when they are likely free again), and never before tomorrow's daily
	-- reward can be claimed
	DelayHours = 22,
	-- a session shorter than this schedules nothing (a quick bounce isn't a player yet)
	MinSessionMinutes = 3,
}
