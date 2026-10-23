--!strict
-- Roll camera feel (reference video), without taking the camera away: when you
-- roll near your roll machine the view eases in a little (FOV) while the
-- pedestals flicker, then punches out with a quick FOV kick at the reveal.
-- The camera stays the normal follow camera, so you can walk and look around.
-- Visual only, local player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)

local me = Players.LocalPlayer
local NEAR = 60 -- only when you're at your own roll machine
local ZOOM_IN = 8 -- degrees of FOV narrower while rolling
local PUNCH = 7 -- degrees wider for a moment at the reveal

local function machine(): BasePart?
	local index = me:GetAttribute("Plot")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = index and plots and plots:FindFirstChild("Plot" .. index)
	local st = plot and plot:FindFirstChild("RollStation", true)
	return st and st:FindFirstChild("MachineBody") :: BasePart?
end

local busy = false
local function rollFeel(seconds: number)
	local cam = Workspace.CurrentCamera
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local body = machine()
	if busy or not (cam and root and body) or (root.Position - body.Position).Magnitude > NEAR then return end
	busy = true
	local fov = cam.FieldOfView
	TweenService:Create(cam, TweenInfo.new(math.min(0.8, seconds * 0.4), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov - ZOOM_IN }):Play()
	task.wait(seconds)
	-- reveal: quick punch out past normal, then settle back
	TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = fov + PUNCH }):Play()
	task.wait(0.3)
	TweenService:Create(cam, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
	task.wait(0.5)
	busy = false
end

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) == "table" and v.rolled and type(v.rollReadyAt) == "number" then
		task.spawn(rollFeel, math.max(1.2, v.rollReadyAt - Workspace:GetServerTimeNow()))
	end
end)
