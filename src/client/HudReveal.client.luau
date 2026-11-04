--!strict
-- 3 Nov (vault: First-Time User Experience and Onboarding, "HUD reveal driven by
-- one onboarding state"; audit round 2 item 2): during the 8 tutorial steps a new
-- player sees only what the steps need - the tutorial headline, cash, the hotbar
-- and the world.
-- 4 Nov (Willem; funnel: 21% left between "tutorial done" and the first goal, right
-- when ~10 HUD items appeared at once): the rest now arrives in steps with the goals
-- (state.goal = the goal you are on):
--   goal 1 (tutorial done)  Equip Best / travel row       (helps fill the bays)
--   goal 2                  Rewards (gift chip), SMASH
--   goal 3                  Shop, Index, Boosts, Quests    (starter offer waits for this)
--   goal 5                  Leaderboard, Rebirth, event countdown, Lucky Weekend
--   goal 6                  Turbo                          (its goal)
-- One rule, from the server's state. Returning players (all goals done, or an older
-- save without goals) see everything at once.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Net = require(RS.Shared.Net)
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local playerGui = me:WaitForChild("PlayerGui")

-- the goal number from which each piece shows (whole ScreenGuis, or single buttons)
local GUIS: { [string]: number } = {
	TravelButtons = 1,
	RewardsHud = 2, FrenzyHud = 2,
	ShopHud = 3, BoostsHud = 3, QuestsHud = 3,
	LeaderboardHud = 5, RebirthHud = 5, EventCountdown = 5, WeekendHud = 5,
	TurboHud = 6,
}
local BUTTONS: { [string]: number } = { BookButton = 3 }

-- before the first state everything listed is hidden (no flash of the shop for new
-- players; returning players see their HUD as soon as the first state arrives)
local stage = 0 -- 0 = in the tutorial; else the goal number (math.huge = all)
local guards: { [Instance]: RBXScriptConnection } = {}

local function shown(from: number): boolean return stage >= from end

local function apply(gui: Instance)
	local from = if gui:IsA("ScreenGui") then GUIS[gui.Name] elseif gui:IsA("GuiObject") then BUTTONS[gui.Name] else nil
	if not from then return end
	local prop = if gui:IsA("ScreenGui") then "Enabled" else "Visible"
	if not shown(from) then
		(gui :: any)[prop] = false
		-- other scripts (cutscenes) may switch it back on: keep it off until its goal
		if not guards[gui] then
			guards[gui] = gui:GetPropertyChangedSignal(prop):Connect(function()
				if not shown(from) and (gui :: any)[prop] then (gui :: any)[prop] = false end
			end)
		end
	elseif guards[gui] then
		guards[gui]:Disconnect() guards[gui] = nil
		;(gui :: any)[prop] = true
	end
end

local function applyAll()
	for _, child in playerGui:GetChildren() do apply(child) end
	for _, d in playerGui:GetDescendants() do if BUTTONS[d.Name] then apply(d) end end
end

playerGui.ChildAdded:Connect(function(child) task.defer(apply, child) end)
playerGui.DescendantAdded:Connect(function(d) if BUTTONS[d.Name] then task.defer(apply, d) end end)

applyAll()
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) ~= "table" or type(v.tutorial) ~= "number" then return end
	local now = if v.tutorial <= #C.TutorialSteps then 0
		elseif type(v.goal) ~= "number" or not C.Goals2[v.goal] then math.huge
		else v.goal
	-- (stages only go up within a session: a goal list change never hides things again)
	if now <= stage then return end
	stage = now
	applyAll()
end)
