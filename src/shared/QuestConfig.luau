--!strict
-- Quests (reference style): daily and weekly lists that pay Quest Tokens, and a
-- token shop. Progress is "stat now - stat when the period started", so every
-- stat is a plain counter in the profile (QuestRules.stat).
--   stat: play (seconds online), rolls, crushed, sells, buys, levels, upgrades, spins
--   icon: a key of Shared/Icons; unit "time" shows minutes/hours
local Q = {}

Q.TokenName = "Quest Tokens"

Q.Daily = {
	{ id = "play", title = "Play for 30 minutes!", stat = "play", goal = 1800, reward = 10, icon = "Offline", unit = "time" },
	{ id = "roll", title = "Roll 25 times!", stat = "rolls", goal = 25, reward = 5, icon = "Lucky" },
	{ id = "crush", title = "Crush 250 toys!", stat = "crushed", goal = 250, reward = 5, icon = "Press" },
	{ id = "sell", title = "Sell scrap 15 times!", stat = "sells", goal = 15, reward = 5, icon = "Cash" },
	{ id = "spin", title = "Spin the Daily Spin!", stat = "spins", goal = 1, reward = 5, icon = "Rewards" },
	{ id = "level", title = "Level up crushers 5 times!", stat = "levels", goal = 5, reward = 5, icon = "Power" },
}

Q.Weekly = {
	{ id = "play", title = "Play for 5 hours!", stat = "play", goal = 18000, reward = 30, icon = "Offline", unit = "time" },
	{ id = "roll", title = "Roll 400 times!", stat = "rolls", goal = 400, reward = 25, icon = "Lucky" },
	{ id = "crush", title = "Crush 5,000 toys!", stat = "crushed", goal = 5000, reward = 20, icon = "Press" },
	{ id = "buy", title = "Buy 25 crushers!", stat = "buys", goal = 25, reward = 20, icon = "Rebirth" },
	{ id = "spin", title = "Spin the Daily Spin 5 times!", stat = "spins", goal = 5, reward = 20, icon = "Rewards" },
	{ id = "level", title = "Level up crushers 50 times!", stat = "levels", goal = 50, reward = 20, icon = "Power" },
	{ id = "upgrade", title = "Buy 10 factory upgrades!", stat = "upgrades", goal = 10, reward = 15, icon = "Speed" },
}

-- Token shop. kind "cash": `seconds` of your current earnings (at least MinCash);
-- kind "crusher": a random crusher of that rarity into the backpack.
Q.MinCash = 100
Q.Shop = {
	{ id = "skip15", title = "15m Time Skip", kind = "cash", seconds = 900, cost = 20, icon = "Offline" },
	{ id = "skip60", title = "1h Time Skip", kind = "cash", seconds = 3600, cost = 60, icon = "Offline" },
	{ id = "uncommon", title = "Uncommon Crusher", kind = "crusher", rarity = "Uncommon", cost = 30 },
	{ id = "rare", title = "Rare Crusher", kind = "crusher", rarity = "Rare", cost = 80 },
	{ id = "epic", title = "Epic Crusher", kind = "crusher", rarity = "Epic", cost = 200 },
	{ id = "legendary", title = "Legendary Crusher", kind = "crusher", rarity = "Legendary", cost = 500 },
}

Q.Periods = { "Daily", "Weekly" }
function Q.list(period: string): { any } return if period == "Weekly" then Q.Weekly else Q.Daily end

return Q
