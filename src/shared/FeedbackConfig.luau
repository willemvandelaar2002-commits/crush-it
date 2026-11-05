--!strict
-- 5 Nov (Willem; vault: Community Building "a feedback path"): the one-tap survey.
-- Answers go to Creator Analytics as custom events (Analytics > Explore):
--   FeedbackRating  value 1 (bad) / 2 (okay) / 3 (great), Custom Field 1 = the key
--   (6 Nov: keys without spaces/apostrophes; "IT'S OK" showed up as N/A; older data: LOVE IT / NOT FUN / N/A)
--   FeedbackWish    value 1, Custom Field 1 = the wish key (break down by Custom Field 1)
-- Shown once per save after AskAfterMinutes of play (tutorial done, nothing else open);
-- the FEEDBACK button on the Codes tab of Rewards opens it again any time.
return {
	AskAfterMinutes = 10,
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
