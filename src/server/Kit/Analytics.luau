--!strict
-- Thin, safe wrapper around AnalyticsService: every call is pcall'd so
-- analytics can never break gameplay. Reusable between games.
--
--   Analytics.funnelStep(player, data, step, name)  -- onboarding funnel, once per step,
--                                                   -- only for saves with data.funnel = true
--   Analytics.custom(player, name, value?, extra?)  -- custom event (CustomField01 = extra)

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

function Analytics.custom(player: Player, name: string, value: number?, extra: string?)
	safe("custom", function()
		local fields = if extra then { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = extra } else nil
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields)
	end)
	if DEBUG then
		print(`[Analytics] {player.Name} {name} {value or 1} {extra or ""}`)
	end
end

return Analytics
