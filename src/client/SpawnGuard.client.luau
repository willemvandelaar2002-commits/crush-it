--!strict
-- Never fall through floors that haven't loaded yet (StreamingEnabled): right
-- after you spawn, and after any teleport (a big jump in position), your
-- character is held in place until there is ground under you, then released.
-- The client owns its character's physics, so the local anchor holds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
local G = Config.SpawnGuard

local me = Players.LocalPlayer

local function groundBelow(root: BasePart, char: Model): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	params.RespectCanCollide = true -- look through decorative non-solid strips to the real floor
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -G.Probe, 0), params)
	return hit ~= nil
end

local function guard(char: Model)
	local root = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not root then return end
	local holding = false
	local holdSince = 0
	local watchUntil = os.clock() + G.WatchSeconds
	local last = root.Position
	local function hold()
		if holding then return end
		holding, holdSince = true, os.clock()
		root.Anchored = true
		local at = root.Position
		task.spawn(pcall, function() me:RequestStreamAroundAsync(at, G.StreamTimeout) end)
	end
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not root.Parent then conn:Disconnect() return end
		local pos = root.Position
		-- a teleport: watch the new spot for a moment too
		if (pos - last).Magnitude > G.TeleportJump then watchUntil = os.clock() + G.WatchSeconds end
		last = pos
		if holding then
			if groundBelow(root, char) or os.clock() - holdSince > G.MaxHold then
				holding = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.Anchored = false
			end
		elseif os.clock() < watchUntil and not root.Anchored and not groundBelow(root, char) then
			hold()
		end
	end)
end

me.CharacterAdded:Connect(guard)
if me.Character then task.spawn(guard, me.Character) end
