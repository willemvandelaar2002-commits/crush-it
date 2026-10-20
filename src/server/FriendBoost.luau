--!strict
-- Friend boost: +Config.FriendBoost.Per cash for every Roblox friend in the same
-- server (up to Max). Kept in the player attribute "FriendBoost" (0.2 = +20%);
-- Game.server multiplies crush cash by (1 + FriendBoost).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local FriendBoost = {}

-- friendship is symmetric: cache by the sorted pair
local cache: { [string]: boolean } = {}

local function key(a: Player, b: Player): string
	local x, y = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	return x .. ":" .. y
end

local function areFriends(a: Player, b: Player): boolean
	local k = key(a, b)
	if cache[k] == nil then
		local ok, yes = pcall(function()
			return a:IsFriendsWith(b.UserId)
		end)
		cache[k] = ok and yes == true
	end
	return cache[k]
end

local function update(player: Player)
	if not player.Parent then
		return
	end
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and areFriends(player, other) then
			count += 1
		end
	end
	player:SetAttribute("FriendBoost", math.min(Config.FriendBoost.Max, count * Config.FriendBoost.Per))
	player:SetAttribute("FriendsHere", count)
end

local function updateAll()
	for _, p in Players:GetPlayers() do
		task.spawn(update, p)
	end
end

function FriendBoost.mult(player: Player): number
	return 1 + ((player:GetAttribute("FriendBoost") :: number?) or 0)
end

function FriendBoost.start()
	Players.PlayerAdded:Connect(updateAll)
	Players.PlayerRemoving:Connect(function(player)
		task.defer(updateAll)
		for k in cache do
			if string.find(":" .. k .. ":", ":" .. player.UserId .. ":", 1, true) then
				cache[k] = nil
			end
		end
	end)
	updateAll()
end

return FriendBoost
