--!strict
-- 2 Nov: SMASH + FRENZY (CrusherConfig.Frenzy). The client sends a Smash per
-- tap; the server counts at most MaxTaps a second, pays TapPay seconds of income
-- per counted tap and fills the meter. Full meter: FRENZY for Seconds, during
-- which perks.speed = Speed (CrusherGame.perks). The meter can't fill during a
-- frenzy. State goes to the owner as FrenzyState { meter, max, untilTime }.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.Config).Crushers
local Analytics = require(script.Parent.Kit.Analytics)

local M = {}
type S = { meter: number, untilTime: number, lastTap: number, window: number, taps: number }
local st: { [Player]: S } = {}
local F = C.Frenzy

local function get(p: Player): S
	local s = st[p]
	if not s then s = { meter = 0, untilTime = 0, lastTap = 0, window = 0, taps = 0 } st[p] = s end
	return s
end
-- is this player in a frenzy right now (server time)?
function M.speed(p: Player): number
	local s = st[p]
	return if s and s.untilTime > workspace:GetServerTimeNow() then F.Speed else 1
end

function M.start(api: any)
	local event = Net.event("FrenzyState")
	local function push(p: Player, s: S, pay: number?)
		event:FireClient(p, { meter = s.meter, max = F.Meter, untilTime = s.untilTime, pay = pay })
	end
	Net.event("Smash").OnServerEvent:Connect(function(p: Player)
		local d = api.getData(p)
		if not d then return end
		local s = get(p)
		local now = workspace:GetServerTimeNow()
		local clock = os.clock()
		if clock - s.window >= 1 then s.window = clock s.taps = 0 end
		if s.taps >= F.MaxTaps then return end -- extra taps this second count for nothing
		s.taps += 1
		s.lastTap = clock
		local pay = math.max(F.MinTapCash, math.floor(api.cashPerSecond(p) * F.TapPay))
		api.addCash(p, pay, "Smash", "Gameplay")
		if s.untilTime <= now then
			s.meter = math.min(F.Meter, s.meter + 1)
			if s.meter >= F.Meter then
				s.meter = 0
				s.untilTime = now + F.Seconds
				d.stats = d.stats or {}
				d.stats.frenzies = (d.stats.frenzies or 0) + 1
				Analytics.custom(p, "Frenzy", 1)
				api.sync(p)
			end
		end
		push(p, s, pay)
	end)
	-- drain the meter when nobody taps
	task.spawn(function()
		while true do
			task.wait(0.5)
			local clock = os.clock()
			for p, s in st do
				if p.Parent and s.meter > 0 and clock - s.lastTap > F.Idle then
					s.meter = math.max(0, s.meter - F.Drain * 0.5)
					push(p, s)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) st[p] = nil end)
end

return M
