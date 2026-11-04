--!strict
-- 2 Nov: TURBO fuel (Shared/TurboConfig). The server prices and sells it; the
-- end times live in player attributes Turbo_<id> (server time) and in the save
-- (data.turbo, unix time), so a turbo keeps running across a rejoin.
-- CrusherGame multiplies perks.mult by Turbo.active(player).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local T = require(RS.Shared.TurboConfig)
local Analytics = require(script.Parent.Kit.Analytics)

local M = {}
M.active = T.active

-- income without the turbo itself and without other short boosts (2x Cash boost
-- from a golden toy or goal, frenzy): the price must not jump because one runs.
-- The highest seen this session, so unequipping crushers can't make it cheap.
local peak: { [Player]: number } = {}
local function baseIncome(api: any, p: Player): number
	local cps = api.cashPerSecond(p) / T.active(p, workspace:GetServerTimeNow()) / require(script.Parent.Frenzy).speed(p) / api.shortBoost(p)
	peak[p] = math.max(peak[p] or 0, cps)
	return peak[p]
end

-- 2 Nov evening: a rebirth drops income on purpose, so the price follows it down
function M.resetPeak(p: Player) peak[p] = nil end

local savedApi: any = nil
-- 4 Nov: the Instant Turbo product: your strongest unlocked turbo for
-- Store.TurboNowMinutes, added to its time (paid: may go past MaxMinutes).
-- Returns the turbo's title, nil if the player isn't loaded.
function M.grantNow(p: Player): string?
	local d = savedApi and savedApi.getData(p)
	if not d then return nil end
	local best = T.List[1]
	for _, t in T.List do if (d.crushers.plotLevel or 0) >= t.plot then best = t end end
	local now = workspace:GetServerTimeNow()
	local ends = math.max(now, (p:GetAttribute(T.attr(best.id)) :: number?) or 0) + require(RS.Shared.Store).TurboNowMinutes * 60
	p:SetAttribute(T.attr(best.id), ends)
	d.turbo = d.turbo or {}
	d.turbo[best.id] = os.time() + (ends - now)
	savedApi.sync(p)
	return best.title
end

function M.start(api: any)
	savedApi = api
	local result = Net.event("TurboState")
	local function state(p: Player, message: string?)
		local d = api.getData(p)
		if not d then return end
		local cps = baseIncome(api, p)
		local prices = {}
		for _, t in T.List do prices[t.id] = T.price(t, cps) end
		result:FireClient(p, { prices = prices, plotLevel = d.crushers.plotLevel or 0, cash = d.cash, message = message })
	end
	local last: { [Player]: number } = {}
	Net.event("TurboAction").OnServerEvent:Connect(function(p: Player, what: any, id: any)
		if last[p] and os.clock() - last[p] < 0.3 then return end
		last[p] = os.clock()
		if what == "State" then state(p) return end
		if what ~= "Buy" then return end
		local d = api.getData(p)
		local t = T.find(id)
		if not d or not t then return end
		if (d.crushers.plotLevel or 0) < t.plot then state(p, "Unlocks with a bigger factory.") return end
		local now = workspace:GetServerTimeNow()
		local ends = math.max(now, (p:GetAttribute(T.attr(t.id)) :: number?) or 0)
		if ends - now + t.minutes * 60 > T.MaxMinutes * 60 + 1 then state(p, "That turbo is full (" .. T.MaxMinutes .. " min).") return end
		local price = T.price(t, baseIncome(api, p))
		if d.cash < price then state(p, "Not enough cash: " .. Format.cash(price) .. ".") return end
		local before = d.cash
		d.cash -= price
		Analytics.cash(p, t.id, "Shop", before, d.cash)
		ends += t.minutes * 60
		p:SetAttribute(T.attr(t.id), ends)
		d.stats = d.stats or {}
		d.stats.turbos = (d.stats.turbos or 0) + 1
		d.turbo = d.turbo or {}
		d.turbo[t.id] = os.time() + (ends - now)
		api.sync(p)
		state(p, t.title .. "! x" .. t.mult .. " cash")
	end)
	-- restore running turbos on join
	local function restore(p: Player)
		local d = api.whenLoaded(p)
		if not d or type(d.turbo) ~= "table" then return end
		local now = workspace:GetServerTimeNow()
		for id, untilUnix in d.turbo do
			local left = (tonumber(untilUnix) or 0) - os.time()
			if T.find(id) and left > 0 then p:SetAttribute(T.attr(id), now + left) else d.turbo[id] = nil end
		end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(restore, p) end)
	for _, p in Players:GetPlayers() do task.spawn(restore, p) end
	Players.PlayerRemoving:Connect(function(p) peak[p] = nil last[p] = nil end)
end

return M
