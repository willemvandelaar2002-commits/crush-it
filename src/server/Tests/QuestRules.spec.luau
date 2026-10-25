--!strict
-- Run explicitly in Studio. Quest periods, progress, claims and the token shop.
return function()
	local Q = require(game.ReplicatedStorage.Shared.QuestConfig)
	local R = require(game.ReplicatedStorage.Shared.QuestRules)
	local checks = 0
	local function check(v, message) assert(v, message) checks += 1 end
	local d: any = { crushers = { rolls = 4 }, crushed = 100 }
	R.migrate(d)
	local now = 1_800_000_000
	R.refresh(d, now)
	local roll = R.find("Daily", "roll")
	check(R.progress(d, "Daily", roll) == 0, "progress starts at zero for a new day")
	check(not R.claim(d, "Daily", "roll", now), "unfinished quest cannot be claimed")
	d.crushers.rolls += roll.goal + 5
	check(R.progress(d, "Daily", roll) == roll.goal, "progress counts from the period start and caps at the goal")
	local ok, gained = R.claim(d, "Daily", "roll", now)
	check(ok and gained == roll.reward and d.questTokens == roll.reward, "claim pays its tokens")
	check(not R.claim(d, "Daily", "roll", now), "a quest pays once per period")
	check(not R.claim(d, "Nope", "roll", now) and not R.claim(d, "Daily", "nope", now), "unknown lists and quests are rejected")
	R.refresh(d, now + 86400)
	check(not d.quests.Daily.claimed.roll and R.progress(d, "Daily", roll) == 0, "a new day starts the daily list over")
	check(R.key("Weekly", now) == R.key("Weekly", now + 1) and R.nextAt("Weekly", now) > now, "weekly key and refresh time")
	local item = Q.Shop[1]
	d.questTokens = item.cost - 1
	check(not R.buy(d, item.id) and d.questTokens == item.cost - 1, "shop needs enough tokens")
	d.questTokens = item.cost
	local bought = R.buy(d, item.id)
	check(bought and d.questTokens == 0, "buying pays the cost")
	R.refund(d, item) check(d.questTokens == item.cost, "refund gives the cost back")
	local saved: any = game.HttpService:JSONDecode(game.HttpService:JSONEncode(d))
	R.migrate(saved)
	check(saved.questTokens == d.questTokens and saved.quests.Daily.key == d.quests.Daily.key, "quest data survives a save round trip")
	return { passed = checks }
end
