--!strict
-- Free rewards: playtime gifts (per session) and a 7-day daily check-in.
-- Numbers in Config.Rewards. Game.server calls Rewards.start(api).
--
-- Server decides everything: session start time, what's claimed, the streak.
-- The client gets a state snapshot (Rewards remote) on join, after each claim
-- and every minute (so cash amounts follow your earning rate).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Analytics = require(script.Parent.Kit.Analytics)
local Notify = require(script.Parent.Notify)

export type Api = {
	getData: (Player) -> any,
	whenLoaded: (Player) -> any,
	addCash: (Player, number, string?, string?) -> (), -- amount, economy sku, transaction type
	sync: (Player) -> (),
	cashPerSecond: (Player) -> number,
	giveCrusher: ((Player, string) -> string?)?,
}

local Rewards = {}

local DAY = 86400
local api: Api
local sessions: { [Player]: { joined: number, claimed: { [number]: boolean }, readyAt: number? } } = {}
local RewardsRemote = Net.event("Rewards")
local Purchased = Net.event("Purchased")

local function today(): number
	return math.floor(os.time() / DAY)
end

-- Where the streak stands: (next day index 1..7, can claim now).
-- 3 Nov (Willem: "it's day 1 for me every day"; vault: Retention and Return Hooks,
-- "streak with grace"): days are UTC days (they flip at 01:00 in the Netherlands),
-- so someone who plays around midnight can skip a UTC day without missing an
-- evening. One missed day now keeps the streak, at most once a week (d.grace =
-- the UTC day the grace was last used).
local function dailyState(data: any): (number, boolean, boolean)
	local d = data.daily
	local t = today()
	if d.day == t then
		return d.streak, false, false -- already claimed today; `streak` is today's day
	end
	local gap = t - d.day
	local cycle = #Config.Rewards.Daily
	if gap == 1 then return (d.streak % cycle) + 1, true, false end
	if gap == 2 and d.streak > 0 and t - (tonumber(d.grace) or -math.huge) >= cycle then
		return (d.streak % cycle) + 1, true, true
	end
	return 1, true, false
end

local function send(player: Player)
	local s = sessions[player]
	local data = api.getData(player)
	if not s or not data then
		return
	end
	local claimed = {}
	for i in s.claimed do
		table.insert(claimed, i)
	end
	local day, canClaim = dailyState(data)
	-- 4 Nov (vault: "a timer that resolves tomorrow" is the D1 hook): what tomorrow's
	-- daily gives, shown after today's claim (cash at today's earning rate)
	local tomorrow: string? = nil
	if not canClaim then
		local r = Config.Rewards.Daily[(day % #Config.Rewards.Daily) + 1]
		if r and r.kind == "crusher" then tomorrow = "FREE " .. string.upper(r.rarity) .. " CRUSHER"
		elseif r and r.seconds then tomorrow = Format.cash(math.max(Config.Rewards.MinCash, math.floor(api.cashPerSecond(player) * r.seconds))) .. " CASH" end
	end
	-- (for the "daily ready" notification when they leave)
	s.readyAt = if canClaim then os.time() else (today() + 1) * DAY
	RewardsRemote:FireClient(player, {
		joined = s.joined,
		claimed = claimed,
		cps = api.cashPerSecond(player),
		daily = { day = day, canClaim = canClaim, nextAt = (today() + 1) * DAY, tomorrow = tomorrow,
			tomorrowDay = (day % #Config.Rewards.Daily) + 1 },
	})
end

-- Pays out one reward entry; returns the celebration text.
local function grant(player: Player, data: any, reward: any): string
	if reward.kind == "crusher" then
		local rarity = reward.rarity
		if type(reward.mythicChance) == "number" and math.random() < reward.mythicChance then rarity = "Mythic" end
		local name = api.giveCrusher and api.giveCrusher(player, rarity)
		local bonus = ""
		if type(reward.bonusSeconds) == "number" then
			local extra = math.max(Config.Rewards.MinCash, math.floor(api.cashPerSecond(player) * reward.bonusSeconds))
			api.addCash(player, extra, "GiftBonus", "TimedReward")
			bonus = " +" .. Format.cash(extra)
		end
		if name then return (if rarity == "Mythic" then "MYTHIC DROP! " else "New " .. rarity .. " crusher: ") .. name .. "!" .. bonus end
		-- inventory full: pay cash instead
		reward = { seconds = Config.Rewards.FullInventorySeconds }
	elseif reward.kind == "golden" then -- older config entries
		data.goldenRush = (data.goldenRush or 0) + reward.count
		player:SetAttribute("GoldenRush", data.goldenRush)
		api.sync(player)
		return reward.count .. " Golden production bonuses!"
	end
	local amount = math.max(Config.Rewards.MinCash, math.floor(api.cashPerSecond(player) * reward.seconds))
	api.addCash(player, amount, "Gift", "TimedReward")
	return "+" .. Format.cash(amount)
end

local function claim(player: Player, kind: any, index: any)
	local s = sessions[player]
	local data = api.getData(player)
	if not s or not data then
		return
	end
	local text: string
	if kind == "playtime" then
		local i = tonumber(index)
		local reward = i and Config.Rewards.Playtime[i]
		if not i or not reward or s.claimed[i] then
			return
		end
		if Workspace:GetServerTimeNow() - s.joined < reward.minutes * 60 - 1 then
			return
		end
		s.claimed[i] = true
		text = grant(player, data, reward)
		Analytics.custom(player, "PlaytimeReward", i)
	elseif kind == "daily" then
		local day, canClaim, usedGrace = dailyState(data)
		if not canClaim then
			return
		end
		if usedGrace then data.daily.grace = today() end
		data.daily.day = today()
		data.daily.streak = day
		text = "Day " .. day .. ": " .. grant(player, data, Config.Rewards.Daily[day])
		Analytics.custom(player, "DailyReward", day)
	else
		return
	end
	data.stats = data.stats or {} data.stats.gifts = (data.stats.gifts or 0) + 1 -- goals: "claim a free gift"
	Purchased:FireClient(player, { id = "Reward", text = text })
	send(player)
end

-- "Skip All" (Robux): every playtime gift is ready now.
function Rewards.skipAll(player: Player)
	local s = sessions[player]
	if not s then return end
	local longest = 0
	for _, r in Config.Rewards.Playtime do longest = math.max(longest, r.minutes) end
	s.joined = math.min(s.joined, Workspace:GetServerTimeNow() - longest * 60)
	send(player)
end

function Rewards.start(a: Api)
	api = a
	local function join(player: Player)
		sessions[player] = { joined = Workspace:GetServerTimeNow(), claimed = {} }
		Notify.joined(player.UserId)
		local data = api.whenLoaded(player)
		if not data or not player.Parent then
			return
		end
		if typeof(data.daily) ~= "table" then
			data.daily = { day = 0, streak = 0 }
		end
		data.daily.day = math.floor(tonumber(data.daily.day) or 0)
		data.daily.streak = math.clamp(math.floor(tonumber(data.daily.streak) or 0), 0, #Config.Rewards.Daily)
		data.daily.grace = if tonumber(data.daily.grace) then math.floor(data.daily.grace) else nil
		send(player)
	end
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local s = sessions[player]
		sessions[player] = nil
		if s and s.readyAt then Notify.leave(player.UserId, Workspace:GetServerTimeNow() - s.joined, s.readyAt) end
	end)
	Notify.start()
	Net.event("ClaimReward").OnServerEvent:Connect(claim)
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				send(player)
			end
		end
	end)
end

return Rewards
