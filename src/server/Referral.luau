--!strict
-- 4 Nov (Willem: "invite reward, Legendary"; vault: Friend Invites Referrals and
-- Experience Invites - pay on QUALIFIED ARRIVAL, two-sided, capped, mailbox, idempotent).
--   * A brand-new save that arrives through a friend's invite or referral link
--     (Player:GetJoinData().ReferredByPlayerId) remembers who invited it.
--   * When that new player has finished the tutorial AND played 10 minutes (the
--     vault's qualification bar: makes alt farming slow), BOTH get a FREE LEGENDARY
--     crusher: the new player at once, the inviter through a mailbox (they may be
--     offline or in another server).
--   * One credit per invited player ever (ReferralClaims), at most 5 per inviter in
--     total and 2 per day (enforced when the mailbox is written; Willem's banner in
--     Creator Dashboard > Engagement > Referral Rewards must say the same).
--   * The inviter's own server applies mailbox entries it hasn't applied yet
--     (d.referral.applied), on join, on a MessagingService nudge and every 5 minutes.
-- Never needed to progress; nothing for opening the invite menu (Roblox doesn't say
-- who was invited, so only arrivals can be rewarded). Studio uses separate stores.
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local Config = require(RS.Shared.Config)
local Analytics = require(script.Parent.Kit.Analytics)
local C = Config.Crushers

local Referral = {}

Referral.Reward = "Legendary"
Referral.QualifySeconds = 10 * 60
Referral.LifetimeCap = 5
Referral.DailyCap = 2

local suffix = if RunService:IsStudio() then "_studio" else ""
local MAILBOX = DataStoreService:GetDataStore("ReferralMailbox_v1" .. suffix)
local CLAIMS = DataStoreService:GetDataStore("ReferralClaims_v1" .. suffix)
local TOPIC = "ReferralCredit" .. suffix

local api: any
local busy: { [Player]: boolean } = {}

local function ref(d: any): any
	if type(d.referral) ~= "table" then d.referral = { applied = {}, credits = 0 } end
	local r = d.referral
	if type(r.applied) ~= "table" then r.applied = {} end
	r.credits = tonumber(r.credits) or 0
	return r
end
local function notice(p: Player, text: string) Net.event("Notice"):FireClient(p, { text = text }) end
local function name(userId: number): string
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	return if ok and type(n) == "string" then n else "your friend"
end
local function give(p: Player): string
	return api.giveCrusher(p, Referral.Reward, nil, true) or Referral.Reward -- force: always arrives
end

-- the inviter's server: apply what isn't applied yet
local function drain(p: Player)
	local d = api.getData(p)
	if not d or busy[p] then return end
	busy[p] = true
	local ok, box = pcall(function() return MAILBOX:GetAsync("inbox_" .. p.UserId) end)
	if ok and type(box) == "table" and type(box.entries) == "table" then
		local r = ref(d)
		for _, e in box.entries do
			local key = tostring(e.invitee)
			if not r.applied[key] and p.Parent then
				r.applied[key] = true
				r.credits += 1
				local got = give(p)
				local who = name(tonumber(e.invitee) or 0)
				notice(p, who .. " joined through your invite: FREE LEGENDARY " .. got .. "!")
				Net.event("RarePull"):FireAllClients({ text = p.DisplayName .. " invited a friend and got a FREE LEGENDARY crusher!",
					userId = p.UserId, color = Color3.fromRGB(255, 200, 60) })
				Analytics.custom(p, "ReferralCredited", r.credits)
			end
		end
	end
	busy[p] = false
end

-- the invited player's server, once they qualify (safe to call twice: the claim key)
-- returns true when settled (credited, or already claimed before); false = try again later
local function credit(inviteeId: number, inviterId: number): boolean
	local claimed = false
	local okClaim = pcall(function()
		CLAIMS:UpdateAsync("invitee_" .. inviteeId, function(old: any)
			if old ~= nil then return nil end
			claimed = true
			return { by = inviterId, at = os.time() }
		end)
	end)
	if not okClaim then return false end -- DataStore trouble: the invitee's server retries
	if not claimed then return true end
	local appended = false
	pcall(function()
		MAILBOX:UpdateAsync("inbox_" .. inviterId, function(old: any)
			local box = if type(old) == "table" and type(old.entries) == "table" then old else { entries = {} }
			if #box.entries >= Referral.LifetimeCap then return nil end
			local today = os.time() // 86400
			local todayCount = 0
			for _, e in box.entries do
				if e.invitee == inviteeId then return nil end
				if (tonumber(e.at) or 0) // 86400 == today then todayCount += 1 end
			end
			if todayCount >= Referral.DailyCap then return nil end
			table.insert(box.entries, { invitee = inviteeId, at = os.time() })
			appended = true
			return box
		end)
	end)
	if appended then
		local online = Players:GetPlayerByUserId(inviterId)
		if online then task.spawn(drain, online)
		else pcall(function() MessagingService:PublishAsync(TOPIC, inviterId) end) end
	end
	return true
end

local function joined(p: Player)
	local d = api.whenLoaded(p)
	if not d or not p.Parent then return end
	local r = ref(d)
	task.spawn(drain, p)
	-- only a brand-new save, on its first visit, can be an invited player
	if r.checked then return end
	r.checked = true
	local fresh = (tonumber(d.playSeconds) or 0) <= 30 and (d.crushers.rolls or 0) == 0
	if not fresh then return end
	-- (join data can arrive a few seconds late)
	local by: number? = nil
	for _ = 1, 10 do
		if not p.Parent then return end
		local jd = p:GetJoinData()
		local id = tonumber(jd.ReferredByPlayerId)
		if id and id > 0 then by = id break end
		task.wait(1)
	end
	if not by or by == p.UserId then return end
	r.by = by
	Analytics.custom(p, "ReferralArrived", 1)
	local who = name(by)
	task.delay(8, function()
		if p.Parent then notice(p, who .. " invited you! Play 10 minutes for a FREE LEGENDARY crusher (" .. who .. " gets one too).") end
	end)
end

function Referral.start(a: any)
	api = a
	Players.PlayerAdded:Connect(joined)
	for _, p in Players:GetPlayers() do task.spawn(joined, p) end
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
	task.spawn(function()
		pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				local p = Players:GetPlayerByUserId(tonumber(message.Data) or 0)
				if p then drain(p) end
			end)
		end)
	end)
	-- qualification check every 15 s; mailbox re-check every 5 min (long sessions)
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(15)
			tick += 1
			for _, p in Players:GetPlayers() do
				local d = api.getData(p)
				local r = d and d.referral
				if d and type(r) == "table" and r.by and not r.done
					and (d.crushers.tutorial or 1) > #C.TutorialSteps and (tonumber(d.playSeconds) or 0) >= Referral.QualifySeconds then
					r.done = true
					r.pending = true
					local got = give(p)
					notice(p, "Thanks for joining your friend: FREE LEGENDARY " .. got .. "!")
					Analytics.custom(p, "ReferralQualified", 1)
				end
				-- the inviter's credit: now, and again later if the DataStore failed
				if d and type(r) == "table" and r.pending and r.by and (r.done and (tick % 20 == 1 or not r.tried)) then
					r.tried = true
					local by = r.by
					task.spawn(function() if credit(p.UserId, by) then r.pending = nil end end)
				end
				if tick % 20 == 0 then task.spawn(drain, p) end
			end
		end
	end)
end

return Referral
