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

export type Api = {
	getData: (Player) -> any,
	whenLoaded: (Player) -> any,
	addCash: (Player, number) -> (),
	sync: (Player) -> (),
	cashPerSecond: (Player) -> number,
	giveCrusher: ((Player, string) -> string?)?,
}

local Rewards = {}

local DAY = 86400
local api: Api
local sessions: { [Player]: { joined: number, claimed: { [number]: boolean } } } = {}
local RewardsRemote = Net.event("Rewards")
local Purchased = Net.event("Purchased")

local function today(): number
	return math.floor(os.time() / DAY)
end

-- Where the streak stands: (next day index 1..7, can claim now).
local function dailyState(data: any): (number, boolean)
	local d = data.daily
	local t = today()
	if d.day == t then
		return d.streak, false -- already claimed today; `streak` is today's day
	end
	local nextDay = if d.day == t - 1 then (d.streak % #Config.Rewards.Daily) + 1 else 1
	return nextDay, true
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
	RewardsRemote:FireClient(player, {
		joined = s.joined,
		claimed = claimed,
		cps = api.cashPerSecond(player),
		daily = { day = day, canClaim = canClaim, nextAt = (today() + 1) * DAY },
	})
end

-- Pays out one reward entry; returns the celebration text.
local function grant(player: Player, data: any, reward: any): string
	if reward.kind == "crusher" then
		local rarity = reward.rarity
		if type(reward.mythicChance) == "number" and math.random() < reward.mythicChance then rarity = "Mythic" end
		local name = api.giveCrusher and api.giveCrusher(player, rarity)
		if name then return (if rarity == "Mythic" then "MYTHIC DROP! " else "New " .. rarity .. " crusher: ") .. name .. "!" end
		-- inventory full: pay cash instead
		reward = { seconds = Config.Rewards.FullInventorySeconds }
	elseif reward.kind == "golden" then -- older config entries
		data.goldenRush = (data.goldenRush or 0) + reward.count
		player:SetAttribute("GoldenRush", data.goldenRush)
		api.sync(player)
		return reward.count .. " Golden production bonuses!"
	end
	local amount = math.max(Config.Rewards.MinCash, math.floor(api.cashPerSecond(player) * reward.seconds))
	api.addCash(player, amount)
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
		local day, canClaim = dailyState(data)
		if not canClaim then
			return
		end
		data.daily.day = today()
		data.daily.streak = day
		text = "Day " .. day .. ": " .. grant(player, data, Config.Rewards.Daily[day])
		Analytics.custom(player, "DailyReward", day)
	else
		return
	end
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
		local data = api.whenLoaded(player)
		if not data or not player.Parent then
			return
		end
		if typeof(data.daily) ~= "table" then
			data.daily = { day = 0, streak = 0 }
		end
		data.daily.day = math.floor(tonumber(data.daily.day) or 0)
		data.daily.streak = math.clamp(math.floor(tonumber(data.daily.streak) or 0), 0, #Config.Rewards.Daily)
		send(player)
	end
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
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
