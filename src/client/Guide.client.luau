--!strict
-- Ground guide (Kit/GuidePath): glowing chevrons that lead the player to
--   * the sell pad of their scrap shop when they carry scrap (always in the first
--     session, later once it would pay for an upgrade),
--   * the upgrade board while the tutorial says "Buy An Upgrade"
--     (first session, enough cash, no upgrades yet), and
--   * back to their own press once they're off their plot (RETURN_DISTANCE).
-- Otherwise hidden.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GuidePath = require(ReplicatedStorage.Shared.Kit.GuidePath)

local player = Players.LocalPlayer
local RETURN_DISTANCE = 65 -- a bit past the plot edge (plots are 120 wide)

local path = GuidePath.new({ color = Color3.new(1, 1, 1) })

local function attr(name: string): number
	return (player:GetAttribute(name) :: number?) or 0
end

local function myPlot(): Model?
	local index = player:GetAttribute("Plot")
	local plots = Workspace:FindFirstChild("Plots")
	return if index and plots then plots:FindFirstChild("Plot" .. tostring(index)) :: Model? else nil
end

-- (target position, label) or nil
local function goal(root: BasePart): (Vector3?, string?)
	local plot = myPlot()
	if not plot then
		return nil
	end
	local bed = plot:FindFirstChild("Bed", true) :: BasePart?
	if not bed then
		return nil
	end
	-- carrying scrap: to the sell pad (unless Auto Collect sells it for you)
	local scrap = attr("Scrap")
	if scrap > 0 and player:GetAttribute("Pass_AutoCollect") ~= true then
		local firstSession = attr("Tier") <= 1 and attr("Rebirths") == 0
		local cheapest = Config.SizeCost(math.max(1, attr("Tier")))
		for _, u in Config.Upgrades do
			local lv = attr(u.id .. "Lv")
			if lv < u.max then
				cheapest = math.min(cheapest, u.cost(lv))
			end
		end
		if firstSession or scrap + attr("Cash") >= cheapest then
			local pad = plot:FindFirstChild("SellPadFill", true) :: BasePart?
			if pad then
				return pad.Position, "Sell Scrap"
			end
		end
	end
	-- tutorial step: first upgrade
	local firstSession = attr("Tier") <= 1 and attr("Rebirths") == 0
	local noUpgrades = attr("PowerLv") + attr("SpeedLv") + attr("ValueLv") == 0
	if firstSession and noUpgrades and attr("Crushed") > 0 and attr("Cash") >= Config.Upgrades[1].cost(0) then
		local board = plot:FindFirstChild("Board") :: Model?
		if board then
			local pivot = board:GetPivot()
			-- stand in front of the board (its face points +Z)
			return (pivot * CFrame.new(0, 0, 6)).Position, "Upgrades!"
		end
	end
	-- wandered off: back to the press
	local flat = Vector3.new(bed.Position.X - root.Position.X, 0, bed.Position.Z - root.Position.Z)
	if flat.Magnitude > RETURN_DISTANCE then
		return bed.Position, "Your Press"
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		path:update(Vector3.zero, nil)
		return
	end
	local target, label = goal(root)
	local feet = root.Position - Vector3.new(0, 3, 0)
	path:update(feet, target, label)
end)
