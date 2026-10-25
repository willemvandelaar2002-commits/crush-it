--!strict
-- Boosts: end times saved in the profile (d.boosts = { Cash = t, ... }, real
-- time, so they also run out while you're away) and mirrored to player
-- attributes Boost_<id> that CrusherGame's perks() reads. Free daily boost:
-- d.freeBoostDay = the UTC day it was last used.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local B = require(RS.Shared.BoostConfig)

local Boosts = {}
local api: any = nil
local DAY = 86400

local function now(): number return workspace:GetServerTimeNow() end

local function mirror(p: Player, d: any)
	for _, b in B.List do
		local t = d.boosts[b.id] or 0
		p:SetAttribute(B.attr(b.id), if t > now() then t else nil)
	end
	p:SetAttribute("FreeBoost", d.freeBoostDay ~= math.floor(os.time() / DAY))
end

local function migrate(d: any)
	d.boosts = if type(d.boosts) == "table" then d.boosts else {}
	for k, v in d.boosts do
		if not B.find(k) or type(v) ~= "number" or v ~= v then d.boosts[k] = nil end
	end
	d.freeBoostDay = if type(d.freeBoostDay) == "number" then d.freeBoostDay else -1
end

-- Add `minutes` to a boost (stacks on time left, capped at MaxMinutes).
function Boosts.add(p: Player, id: string, minutes: number): boolean
	local d = api and api.getData(p)
	if not d or not B.find(id) then return false end
	migrate(d)
	local start = math.max(now(), d.boosts[id] or 0)
	d.boosts[id] = math.min(start + minutes * 60, now() + B.MaxMinutes * 60)
	mirror(p, d)
	api.sync(p)
	return true
end

function Boosts.start(gameApi: any)
	api = gameApi
	local notice = Net.event("Notice")
	Net.event("BoostAction").OnServerEvent:Connect(function(p: Player, action: any, id: any)
		local d = api.getData(p)
		if not d or action ~= "Free" or not B.find(id) then return end
		migrate(d)
		local today = math.floor(os.time() / DAY)
		if d.freeBoostDay == today then notice:FireClient(p, { text = "You already used today's free boost." }) return end
		d.freeBoostDay = today
		Boosts.add(p, id, B.FreeMinutes)
		notice:FireClient(p, { text = B.find(id).title .. " for " .. B.FreeMinutes .. " minutes!" })
	end)
	local function join(p: Player)
		local d = api.whenLoaded(p)
		if d and p.Parent then migrate(d) mirror(p, d) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end
	-- expire boosts and roll the free one over at midnight
	task.spawn(function()
		while true do
			task.wait(5)
			for _, p in Players:GetPlayers() do
				local d = api.getData(p)
				if d then migrate(d) mirror(p, d) end
			end
		end
	end)
end

return Boosts
