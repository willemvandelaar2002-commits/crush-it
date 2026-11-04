--!strict
-- 3 Nov (vault: First-Time User Experience and Onboarding, "HUD reveal driven by
-- one onboarding state"; audit round 2 item 2): during the 8 tutorial steps a new
-- player sees only what the steps need - the tutorial headline, cash, the hotbar
-- and the world. Shop, rewards, the top row, SMASH, rebirth, leaderboard and the
-- event countdown appear together when the tutorial is done (the first goal is
-- SMASH, so its button arrives right when it is needed).
-- One rule, from the server's tutorial step (CrusherState.tutorial). Returning
-- players are past the tutorial, so nothing is hidden for them.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Net = require(RS.Shared.Net)
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local playerGui = me:WaitForChild("PlayerGui")

-- whole ScreenGuis hidden during the tutorial
local GUIS = { "ShopHud", "RewardsHud", "TravelButtons", "FrenzyHud", "RebirthHud", "LeaderboardHud",
	"EventCountdown", "BoostsHud", "TurboHud", "QuestsHud", "WeekendHud" }
-- single buttons inside shared ScreenGuis
local BUTTONS = { BookButton = true }

-- hidden until the first state says otherwise (no flash of the shop for new players;
-- returning players see their HUD as soon as the first state arrives)
local hiding = true
local guards: { [Instance]: RBXScriptConnection } = {}

local function apply(gui: Instance)
	if gui:IsA("ScreenGui") and table.find(GUIS, gui.Name) then
		if hiding then
			gui.Enabled = false
			-- other scripts (cutscenes) may switch it back on: keep it off until the tutorial ends
			if not guards[gui] then
				guards[gui] = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
					if hiding and (gui :: ScreenGui).Enabled then (gui :: ScreenGui).Enabled = false end
				end)
			end
		else
			if guards[gui] then guards[gui]:Disconnect() guards[gui] = nil end
			gui.Enabled = true
		end
	elseif gui:IsA("GuiObject") and BUTTONS[gui.Name] then
		if hiding then
			gui.Visible = false
			if not guards[gui] then
				guards[gui] = gui:GetPropertyChangedSignal("Visible"):Connect(function()
					if hiding and (gui :: GuiObject).Visible then (gui :: GuiObject).Visible = false end
				end)
			end
		else
			if guards[gui] then guards[gui]:Disconnect() guards[gui] = nil end
			gui.Visible = true
		end
	end
end

local function applyAll()
	for _, child in playerGui:GetChildren() do apply(child) end
	for _, d in playerGui:GetDescendants() do if BUTTONS[d.Name] then apply(d) end end
end

playerGui.ChildAdded:Connect(function(child) if hiding then task.defer(apply, child) end end)
playerGui.DescendantAdded:Connect(function(d) if hiding and BUTTONS[d.Name] then task.defer(apply, d) end end)

applyAll()
local known = false
Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) ~= "table" or type(v.tutorial) ~= "number" then return end
	local want = v.tutorial <= #C.TutorialSteps
	if known and want == hiding then return end
	known = true
	hiding = want
	applyAll()
end)
