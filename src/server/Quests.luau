--!strict
-- Quests server: counts time online, answers claims and token-shop buys, and
-- sends each player their lists (on join, on every change and twice a minute).
-- Rules in Shared/QuestRules, lists and prices in Shared/QuestConfig.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local Q = require(RS.Shared.QuestConfig)
local R = require(RS.Shared.QuestRules)
local Format = require(RS.Shared.Format)

local Quests = {}
local TICK = 15 -- seconds between online-time ticks / refreshes

function Quests.start(api: any)
	local state = Net.event("QuestState")
	local remote = Net.event("QuestAction")
	local last: { [Player]: number } = {}

	local function send(p: Player, toast: string?, gained: number?)
		local d = api.getData(p)
		if not d or not p.Parent then return end
		local now = os.time()
		R.refresh(d, now)
		local periods = {}
		for _, period in Q.Periods do
			local list = {}
			for _, q in Q.list(period) do
				table.insert(list, { id = q.id, title = q.title, goal = q.goal, reward = q.reward, icon = q.icon, unit = q.unit,
					progress = R.progress(d, period, q), claimed = d.quests[period].claimed[q.id] == true })
			end
			periods[period] = { nextAt = R.nextAt(period, now), quests = list }
		end
		local shop = {}
		for _, item in Q.Shop do
			local text = if item.kind == "cash" then Format.cash(math.max(Q.MinCash, math.floor(api.cashPerSecond(p) * item.seconds))) else nil
			table.insert(shop, { id = item.id, title = item.title, cost = item.cost, kind = item.kind, rarity = item.rarity, icon = item.icon, amount = text })
		end
		state:FireClient(p, { tokens = d.questTokens, now = now, periods = periods, shop = shop, ready = R.ready(d), toast = toast, gained = gained })
	end

	remote.OnServerEvent:Connect(function(p: Player, action: any, a: any, b: any)
		local d = api.getData(p)
		if not d then return end
		if os.clock() - (last[p] or 0) < 0.25 then return end
		last[p] = os.clock()
		if action == "State" then send(p) return end
		if action == "Claim" then
			local ok, result = R.claim(d, a, b, os.time())
			if ok then send(p, "+" .. result .. " " .. Q.TokenName .. "!", result) else send(p, result) end
		elseif action == "Buy" then
			local ok, item = R.buy(d, a)
			if not ok then send(p, item) return end
			if item.kind == "cash" then
				local amount = math.max(Q.MinCash, math.floor(api.cashPerSecond(p) * item.seconds))
				api.addCash(p, amount)
				send(p, item.title .. ": +" .. Format.cash(amount) .. "!")
			else
				local name = api.giveCrusher and api.giveCrusher(p, item.rarity)
				if not name then R.refund(d, item) send(p, "Your crusher inventory is full. Tokens refunded.") return end
				send(p, "New " .. item.rarity .. " crusher: " .. name .. "!")
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
	local function join(p: Player)
		if api.whenLoaded(p) then send(p) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end

	-- online time counts for the "Play for ..." quests
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, p in Players:GetPlayers() do
				local d = api.getData(p)
				if d then R.count(d, "play", TICK) send(p) end
			end
		end
	end)

	-- other systems call this after something quest-worthy happened
	function Quests.sync(p: Player) send(p) end
end

return Quests
