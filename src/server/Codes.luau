--!strict
-- 2 Nov: redeem codes (Shared/CodesConfig). Server only decides: the code must
-- exist, not be expired, not used by this player before; then it is marked used
-- (data.codesUsed) BEFORE the rewards are paid, with no yield in between, and
-- saved. Cash goes through api.addCash with an economy reason.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local Codes = require(RS.Shared.CodesConfig)

local M = {}

function M.start(api: any)
	local result = Net.event("CodeResult")
	local last: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
	Net.event("RedeemCode").OnServerEvent:Connect(function(p: Player, input: any)
		if last[p] and os.clock() - last[p] < Codes.Cooldown then return end
		last[p] = os.clock()
		local d = api.getData(p)
		if not d then result:FireClient(p, { ok = false, text = "Still loading, try again!" }) return end
		local entry = Codes.find(input)
		if not entry then result:FireClient(p, { ok = false, text = "That code doesn't exist." }) return end
		if Codes.expired(entry, os.time()) then result:FireClient(p, { ok = false, text = "That code has expired." }) return end
		d.codesUsed = d.codesUsed or {}
		if d.codesUsed[entry.code] then result:FireClient(p, { ok = false, text = "You already used this code." }) return end
		d.codesUsed[entry.code] = os.time()
		local parts = {}
		for _, r in entry.reward do
			if r.cash then
				local amount = math.max(Codes.MinCash, math.floor(api.cashPerSecond(p) * r.cash))
				api.addCash(p, amount, "Code", "TimedReward")
				table.insert(parts, "+" .. Format.cash(amount))
			elseif r.boost then
				require(script.Parent.Boosts).add(p, r.boost, r.minutes)
				table.insert(parts, "2x " .. r.boost .. " for " .. r.minutes .. " min")
			elseif r.crusher then
				local name = api.giveCrusher(p, r.crusher, nil, true)
				if name then table.insert(parts, r.crusher .. " crusher: " .. name) end
			end
		end
		api.sync(p)
		task.spawn(api.save, p)
		result:FireClient(p, { ok = true, text = "Code redeemed! " .. table.concat(parts, ", ") })
	end)
end

return M
