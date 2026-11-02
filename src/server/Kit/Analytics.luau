--!strict
-- Thin, safe wrapper around AnalyticsService: every call is pcall'd so
-- analytics can never break gameplay. Reusable between games.
--
--   Analytics.funnelStep(player, data, step, name)  -- onboarding funnel, once per step,
--                                                   -- only for saves with data.funnel = true
--   Analytics.custom(player, name, value?, extra?)  -- custom event (CustomField01 = extra)
--   Analytics.funnel(player, funnel, sessionId, step, name) -- recurring funnel (e.g. the shop)
--   Analytics.cash(player, sku, tx, before, after)   -- a cash change with its reason
--   Analytics.cashBalance(player, cash)              -- every few s: unexplained change = "Passive"/"Other"
--
-- Economy (2 Nov, vault: Analytics and Funnels): sources and sinks of the one
-- soft currency "Cash", summed per player / flow / reason and sent once a
-- minute (and on leave), so the dashboard shows where money comes from and
-- goes without hitting rate limits. tx is a Roblox transaction type name:
-- "Gameplay", "Shop", "IAP", "TimedReward", "Onboarding", "ContextualPurchase".

local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local Analytics = {}

local DEBUG = RunService:IsStudio()

local function safe(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok and DEBUG then
		warn(`[Analytics] {label} failed: {err}`)
	end
end

function Analytics.funnelStep(player: Player, data: any, step: number, name: string)
	if not data or data.funnel ~= true then
		return
	end
	if (data.funnelStep or 0) >= step then
		return
	end
	data.funnelStep = step
	safe("funnelStep", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
	if DEBUG then
		print(`[Analytics] {player.Name} funnel {step} {name}`)
	end
end

function Analytics.funnel(player: Player, funnel: string, sessionId: string, step: number, name: string)
	safe("funnel", function()
		AnalyticsService:LogFunnelStepEvent(player, funnel, sessionId, step, name)
	end)
	if DEBUG then
		print(`[Analytics] {player.Name} {funnel} funnel {step} {name}`)
	end
end

function Analytics.custom(player: Player, name: string, value: number?, extra: string?)
	safe("custom", function()
		local fields = if extra then { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = extra } else nil
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields)
	end)
	if DEBUG then
		print(`[Analytics] {player.Name} {name} {value or 1} {extra or ""}`)
	end
end

-- Economy -------------------------------------------------------------------------
local Players = game:GetService("Players")
local CURRENCY = "Cash"
local FLUSH = 60
type Bucket = { flow: Enum.AnalyticsEconomyFlowType, tx: string, sku: string, amount: number }
local accounted: { [Player]: number } = {}
local buckets: { [Player]: { [string]: Bucket } } = {}
local balance: { [Player]: number } = {}

local function add(player: Player, delta: number, tx: string, sku: string)
	if delta ~= delta or math.abs(delta) < 1 or math.abs(delta) == math.huge then return end
	local flow = if delta > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
	local key = flow.Name .. "|" .. tx .. "|" .. sku
	local list = buckets[player]
	if not list then list = {} buckets[player] = list end
	local b = list[key]
	if not b then b = { flow = flow, tx = tx, sku = sku, amount = 0 } list[key] = b end
	b.amount += math.abs(delta)
end

local function flush(player: Player)
	local list = buckets[player]
	buckets[player] = nil
	if not list then return end
	local ending = balance[player] or 0
	for _, b in list do
		safe("economy", function()
			AnalyticsService:LogEconomyEvent(player, b.flow, CURRENCY, math.floor(b.amount), math.floor(ending), b.tx, b.sku)
		end)
		if DEBUG then print(`[Analytics] {player.Name} economy {b.flow.Name} {b.tx} {b.sku} {math.floor(b.amount)}`) end
	end
end

-- A cash change we know the reason for. Call with the balance before and after.
function Analytics.cash(player: Player, sku: string, tx: string, before: number, after: number)
	if type(before) ~= "number" or type(after) ~= "number" then return end
	add(player, after - before, tx, sku)
	accounted[player] = (accounted[player] or before) + (after - before)
	balance[player] = after
end

-- Called every few seconds with the real balance: the part no Analytics.cash
-- call explained (auto-sell, offline cash, small systems) is logged as
-- "Passive" (gain) or "Other" (loss). The first call only sets the baseline.
function Analytics.cashBalance(player: Player, cash: number)
	if type(cash) ~= "number" or cash ~= cash then return end
	local known = accounted[player]
	if known then add(player, cash - known, "Gameplay", if cash > known then "Passive" else "Other") end
	accounted[player] = cash
	balance[player] = cash
end

task.spawn(function()
	while true do
		task.wait(FLUSH)
		for player in buckets do task.spawn(flush, player) end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	flush(player)
	accounted[player] = nil balance[player] = nil
end)

return Analytics
