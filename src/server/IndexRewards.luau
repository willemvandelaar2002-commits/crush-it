--!strict
-- Index milestone rewards (list and maths in Shared/IndexRewards). The client
-- fires ClaimIndexReward(i); the server checks the found count, marks the
-- milestone claimed (saved in crushers.indexClaimed) and pays every reward.
-- Permanent luck needs no payout: CrusherGame's perks() reads it from the
-- claimed list. A crusher reward with a full inventory still arrives (force).

local RS = game:GetService("ReplicatedStorage")
local M = require(RS.Shared.IndexRewards)
local Format = require(RS.Shared.Format)
local Net = require(RS.Shared.Net)
local Boosts = require(script.Parent.Boosts)

local IndexRewards = {}

function IndexRewards.claim(api: any, player: Player, index: any): (boolean, string?)
	local d = api.getData(player)
	local i = tonumber(index)
	if not d or not i then return false, nil end
	local s = d.crushers
	if not M.ready(s, i) then return false, nil end
	table.insert(s.indexClaimed, i)
	local parts = {}
	for _, r in M.List[i].rewards do
		if r.kind == "cash" then
			local amount = math.max(100, math.floor(api.cashPerSecond(player) * r.seconds))
			api.addCash(player, amount)
			table.insert(parts, "+" .. Format.cash(amount))
		elseif r.kind == "boost" then
			Boosts.add(player, r.id, r.minutes)
			table.insert(parts, "2x " .. r.id .. " for " .. r.minutes .. " min")
		elseif r.kind == "crusher" then
			local name = api.giveCrusher(player, r.rarity, nil, true)
			if name then table.insert(parts, r.rarity .. " crusher: " .. name) end
		elseif r.kind == "luck" then
			table.insert(parts, "+" .. r.percent .. "% luck forever")
		end
	end
	api.sync(player)
	local text = "Index reward! " .. table.concat(parts, ", ")
	Net.event("Purchased"):FireClient(player, { id = "Reward", text = text })
	return true, text
end

function IndexRewards.start(api: any)
	Net.event("ClaimIndexReward").OnServerEvent:Connect(function(player: Player, index: any)
		IndexRewards.claim(api, player, index)
	end)
end

return IndexRewards
