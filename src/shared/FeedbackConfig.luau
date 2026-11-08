--!strict
-- 5 Nov (Willem; vault: Community Building "a feedback path"): the one-tap survey.
-- Answers go to Creator Analytics as custom events (Analytics > Explore):
--   FeedbackRating  value 1 (bad) / 2 (okay) / 3 (great), Custom Field 1 = the key
--   (6 Nov: keys without spaces/apostrophes; "IT'S OK" showed up as N/A; older data: LOVE IT / NOT FUN / N/A)
--   FeedbackWish    value 1, Custom Field 1 = the wish key (break down by Custom Field 1)
-- Shown once per save after AskAfterMinutes of play (tutorial done, nothing else open);
-- the FEEDBACK button on the Codes tab of Rewards opens it again any time.
return {
	-- 8 Nov (kid playtest): asked right after the FACTORY II upgrade (a happy moment),
	-- AskAfterUpgradeSeconds after its cutscene ends; players who don't get there are
	-- asked after AskAfterMinutes of play (was 10).
	AskAfterMinutes = 25,
	AskAfterUpgradeSeconds = 4,
	-- 6 Nov (Willem: 59% likes): after LOVE IT, one friendly page asks for a 👍 on the game
	-- page. No reward (vault Community Building: don't reward likes; a reminder is fine),
	-- only to players who just said they love it. Logged as FeedbackLikeAsk.
	LikeAsk = { Title = "Yay, thank you! 😍", Text = "Could you give Crush It a 👍 LIKE on the game page? It helps new players find the game!", Button = "SURE!" },
	Ratings = {
		{ value = 3, emoji = "😍", label = "LOVE IT", key = "LoveIt" },
		{ value = 2, emoji = "🙂", label = "IT'S OK", key = "ItsOk" },
		{ value = 1, emoji = "😕", label = "NOT FUN", key = "NotFun" },
	},
	Wishes = {
		{ key = "MoreCrushers", text = "More crushers" },
		{ key = "FasterProgress", text = "Faster progress" },
		{ key = "CheaperShop", text = "Cheaper shop" },
		{ key = "LessConfusing", text = "Less confusing" },
		{ key = "Friends", text = "More with friends" },
		{ key = "AllGood", text = "It's great already!" },
	},
}
