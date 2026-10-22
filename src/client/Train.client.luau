--!strict
-- Drives the toy trains (server/Hub.luau, tag "ToyTrain") along the timetable in
-- shared/TrainRoute.luau, and lets you ride them:
--   * every car (attribute Offset = studs behind the engine) is placed on the rails
--     each frame, part by part from its Chassis (model pivots don't stream);
--   * press E on a wagon ("Ride") to sit in it; you move with the wagon. At each
--     plot the train stops for a few seconds; jump to hop off (you land beside the
--     track, and at a stop right at that plot's bridge).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local TrainRoute = require(ReplicatedStorage.Shared.TrainRoute)

local player = Players.LocalPlayer
local RADIUS = Config.Loop.TrainRadius

type Rig = { chassis: BasePart, lift: number, parts: { BasePart }, offsets: { CFrame }, count: number }
local rigs: { [Model]: Rig } = {}

local function rig(car: Model): Rig?
	local chassis = car:FindFirstChild("Chassis") :: BasePart?
	if not chassis then
		return nil
	end
	local count = #car:GetDescendants()
	local r = rigs[car]
	if r and r.count == count and r.chassis == chassis then
		return r
	end
	local parts, offsets = {}, {}
	for _, p in car:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			local stored = p:GetAttribute("TrainOffset")
			table.insert(offsets, if typeof(stored) == "CFrame" then stored else chassis.CFrame:ToObjectSpace(p.CFrame))
		end
	end
	r = { chassis = chassis, lift = (car:GetAttribute("ChassisY") :: number?) or 2.2, parts = parts, offsets = offsets, count = count }
	rigs[car] = r
	return r
end

-- where a car is right now: (CFrame on the floor, speed in studs/s, plot index it stands at)
local function carFrame(train: Instance, car: Instance, now: number): (CFrame, number, number?)
	local phase = (train:GetAttribute("Phase") :: number?) or 0
	local y = (train:GetAttribute("FloorY") :: number?) or 1.6
	local head, speed, stop = TrainRoute.at(now, phase)
	local a = head - ((car:GetAttribute("Offset") :: number?) or 0) / RADIUS
	return TrainRoute.frame(a, y), speed * RADIUS, stop
end

-- riding -----------------------------------------------------------------------
local riding: { train: Instance, car: Instance }? = nil

local hint = Instance.new("ScreenGui")
hint.Name = "TrainHud"
hint.ResetOnSpawn = false
hint.Enabled = false
hint.Parent = player:WaitForChild("PlayerGui")
local hintLabel = Instance.new("TextLabel")
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -150)
hintLabel.Size = UDim2.fromOffset(420, 40)
hintLabel.BackgroundTransparency = 1
hintLabel.TextScaled = true
hintLabel.Text = ""
hintLabel.Parent = hint
Style.text(hintLabel, 3)

local function ownerName(stop: number): string
	local plots = Workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. stop)
	if plot and plot:GetAttribute("Index") == player:GetAttribute("Plot") then
		return "Your plot!"
	end
	local sign = plot and plot:FindFirstChild("OwnerName", true) :: TextLabel?
	local name = sign and sign.Text or ""
	return if name ~= "" and name ~= "Free plot" then name else "Free plot"
end

local function setPrompts(enabled: boolean)
	for _, train in CollectionService:GetTagged("ToyTrain") do
		for _, d in train:GetDescendants() do
			if d:IsA("ProximityPrompt") then
				d.Enabled = enabled
			end
		end
	end
end

local function hopOff()
	local ride = riding
	if not ride then
		return
	end
	riding = nil
	hint.Enabled = false
	setPrompts(true)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid then
		humanoid.Sit = false
	end
	if not (root and humanoid and character) then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local cf, _, stop = carFrame(ride.train, ride.car, now)
	local spot: Vector3
	if stop then
		-- at a stop: onto that plot's bridge end
		local a = math.rad(22.5 + (stop - 1) * 45)
		local r = Config.Loop.Outer + 2
		spot = Vector3.new(math.sin(a) * r, cf.Position.Y, math.cos(a) * r)
	else
		-- between stops: beside the track, on the outside
		local p = cf.Position
		spot = p + Vector3.new(p.X, 0, p.Z).Unit * 7
	end
	local stand = humanoid.HipHeight + root.Size.Y / 2 + 0.3
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(CFrame.lookAt(spot + Vector3.new(0, stand, 0), Vector3.new(0, spot.Y + stand, 0)) * CFrame.Angles(0, math.pi, 0))
end

local function board(train: Instance, car: Instance)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	riding = { train = train, car = car }
	setPrompts(false)
	humanoid.Sit = true
	hint.Enabled = true
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or prompt.Name ~= "RidePrompt" then
		return
	end
	local car = prompt:FindFirstAncestorOfClass("Model")
	local train = car and car.Parent
	if car and train and CollectionService:HasTag(train, "ToyTrain") then
		board(train, car)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if riding then
		hopOff()
	end
end)

player.CharacterAdded:Connect(function()
	riding = nil
	hint.Enabled = false
	setPrompts(true)
end)

-- keep the rider in the wagon (before physics, so the humanoid doesn't fall out)
RunService.PreSimulation:Connect(function()
	local ride = riding
	if not ride then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and humanoid and root) or humanoid.Health <= 0 or not ride.car.Parent then
		riding = nil
		hint.Enabled = false
		setPrompts(true)
		return
	end
	local now = Workspace:GetServerTimeNow()
	local cf, speed, stop = carFrame(ride.train, ride.car, now)
	-- sitting on the wagon floor (top at 2.8 above the rails' floor)
	local seat = cf * CFrame.new(0, 2.8 + humanoid.HipHeight + root.Size.Y / 2 - 0.9, 0)
	root.CFrame = seat
	root.AssemblyLinearVelocity = cf.LookVector * speed
	root.AssemblyAngularVelocity = Vector3.zero
	if not humanoid.Sit then
		humanoid.Sit = true
	end
	if stop then
		hintLabel.Text = "Stop: " .. ownerName(stop) .. "  ·  jump to hop off"
		hintLabel.TextColor3 = Color3.fromRGB(150, 255, 110)
	else
		hintLabel.Text = "Riding the toy train  ·  jump to hop off"
		hintLabel.TextColor3 = Color3.new(1, 1, 1)
	end
end)

-- drive the trains ------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	local moveParts: { BasePart } = {}
	local moveTo: { CFrame } = {}
	for _, train in CollectionService:GetTagged("ToyTrain") do
		for _, car in train:GetChildren() do
			if car:IsA("Model") then
				local rg = rig(car)
				if rg then
					local cf = carFrame(train, car, now)
					local chassisCf = cf * CFrame.new(0, rg.lift, 0)
					for i, p in rg.parts do
						table.insert(moveParts, p)
						table.insert(moveTo, chassisCf * rg.offsets[i])
					end
				end
			end
		end
	end
	if #moveParts > 0 then
		Workspace:BulkMoveTo(moveParts, moveTo, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
