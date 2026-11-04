--!strict
-- 4 Nov: "your daily reward is ready" experience notifications (vault: Experience
-- Notifications and Return Prompts; Roblox docs Oct 2026).
--   * When a player leaves (Rewards calls Notify.leave), one job is stored in a shared
--     MemoryStore sorted map, sorted by its due time: DelayHours after leaving, never
--     before tomorrow's daily can be claimed.
--   * Joining any server removes the job (they came back by themselves).
--   * Every server polls for due jobs, claims one before sending (so two servers never
--     both send) and sends it with Roblox's Open Cloud package
--     (ServerScriptService.OpenCloud, Creator Store asset 16584168800, saved in the place).
--   * Roblox only delivers to opted-in players 13+, one per day per game; a refusal is
--     logged once and the job is dropped (never retried in a loop).
-- Off until NotifyConfig.DailyReady has the string's asset id.
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local N = require(RS.Shared.NotifyConfig)

local Notify = {}

local DAY = 86400
local MAX_TTL = 3_888_000 -- MemoryStore items live at most 45 days
local CLAIM_SECONDS = 120
local SERVER = HttpService:GenerateGUID(false)
local queue: MemoryStoreSortedMap? = nil
local function map(): MemoryStoreSortedMap?
	if queue then return queue end
	local ok, m = pcall(function() return MemoryStoreService:GetSortedMap("NotifyDaily_v1") end)
	if ok then queue = m end
	return queue
end
local function on(): boolean return N.DailyReady ~= "" end

-- when a ping for someone leaving now would go out
function Notify.dueAt(dailyReadyAt: number): number
	return math.max(os.time() + N.DelayHours * 3600, dailyReadyAt + 600)
end

-- the player left; dailyReadyAt = unix time their next daily can be claimed;
-- params = the string's {placeholders} (day, reward), worked out for the due day
function Notify.leave(userId: number, sessionSeconds: number, dailyReadyAt: number, params: { [string]: string }?)
	if not on() or sessionSeconds < N.MinSessionMinutes * 60 then return end
	local due = Notify.dueAt(dailyReadyAt)
	local m = map() if not m then return end
	task.spawn(function()
		pcall(function()
			(m :: any):SetAsync("u" .. userId, { u = userId, p = params }, math.clamp(due - os.time() + 6 * 3600, 60, MAX_TTL), due)
		end)
	end)
end

function Notify.joined(userId: number)
	if not on() then return end
	local m = map() if not m then return end
	task.spawn(function() pcall(function() (m :: any):RemoveAsync("u" .. userId) end) end)
end

local sender: any = nil
local warned = false
local function send(userId: number, params: { [string]: string }?): boolean
	if not sender then
		local oc = ServerScriptService:FindFirstChild("OpenCloud")
		local mod = oc and oc:FindFirstChild("V2") and oc.V2:FindFirstChild("UserNotification")
		if not mod then
			if not warned then warned = true warn("[Notify] ServerScriptService.OpenCloud package missing: nothing sent") end
			return false
		end
		sender = require(mod :: ModuleScript)
	end
	local parameters = {}
	for k, v in params or { day = "1", reward = "a cash gift" } do parameters[k] = { stringValue = v } end
	local ok, result = pcall(sender.createUserNotification, userId, {
		payload = {
			type = "MOMENT",
			messageId = N.DailyReady,
			parameters = parameters,
			joinExperience = { launchData = "daily" },
			analyticsData = { category = "DailyReady" },
		},
	})
	if not ok or (result and result.statusCode ~= 200) then
		-- not opted in, under 13, throttled, ...: Roblox's answer; drop the job
		if not warned then
			warned = true
			warn("[Notify] not sent:", if ok and result then result.statusCode else result, if ok and result and result.error then result.error.code else "")
		end
	end
	return true
end

local function claim(m: any, key: string): (number?, any)
	local got: number?, params: any = nil, nil
	pcall(function()
		m:UpdateAsync(key, function(old: any, sortKey: any)
			if type(old) ~= "table" then return nil end
			local now = os.time()
			if old.by and old.at and now - old.at < CLAIM_SECONDS then return nil end -- another server has it
			old.by = SERVER old.at = now
			got = old.u params = old.p
			return old, sortKey
		end, 600)
	end)
	return got, params
end

function Notify.start()
	if RunService:IsStudio() then return end -- Studio never sends (test players are not real players)
	task.spawn(function()
		while true do
			task.wait(20 + math.random() * 10) -- jitter so servers don't poll in step
			local m = map()
			if on() and m then
				local ok, items = pcall(function()
					return (m :: any):GetRangeAsync(Enum.SortDirection.Ascending, 20, nil, { sortKey = os.time() + 1 })
				end)
				if ok and items then
					for _, item in items do
						local userId, params = claim(m, item.key)
						if userId then
							if not Players:GetPlayerByUserId(userId) then send(userId, params) end
							pcall(function() (m :: any):RemoveAsync(item.key) end)
						end
					end
				end
			end
		end
	end)
end

Notify.DAY = DAY
return Notify
