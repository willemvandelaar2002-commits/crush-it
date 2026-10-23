--!strict
-- Roll camera + smooth display (reference video): when you roll near your roll
-- machine the camera eases in on the reveal plinth, drifts slowly while the
-- silhouettes flicker, then punches out with a quick FOV kick at the reveal.
-- (The slow spin of the model on the plinth is done by the server: rollShow.)
-- Visual only, local player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)

local me = Players.LocalPlayer
local NEAR = 70

local function station(): Model?
	local index = me:GetAttribute("Plot")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = index and plots and plots:FindFirstChild("Plot" .. index)
	return plot and plot:FindFirstChild("RollStation") :: Model?
end
local function plinthTop(): Vector3?
	local st = station()
	local plinth = st and st:FindFirstChild("RevealPlinth") :: BasePart?
	return plinth and plinth.Position + Vector3.new(0, plinth.Size.Y / 2, 0)
end

-- Camera move for your own roll.
local busy = false
local function rollCamera(seconds: number)
	local cam = Workspace.CurrentCamera
	local char = me.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local top = plinthTop()
	if busy or not (cam and root and top) or (root.Position - top).Magnitude > NEAR then return end
	busy = true
	local fov = cam.FieldOfView
	local look = top + Vector3.new(0, 5, 0) -- between the model and its card
	-- look across the plinth with the ROLLING banner behind it as a backdrop
	local st = station()
	local banner = st and st:FindFirstChild("RevealPanel") :: BasePart?
	local from = if banner then banner.Position else cam.CFrame.Position
	local dir = (look - from) * Vector3.new(1, 0, 1)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(0, 0, 1)
	-- the side away from the banner is the open plaza edge, so a fixed distance is clear
	local reach = 18
	local close = CFrame.lookAt(look + dir * reach + Vector3.new(0, 4, 0), look)
	-- hide the top HUD lines so the reveal card stays readable
	local hud = me.PlayerGui:FindFirstChild("CrushHud")
	local hidden = {}
	for _, name in { "Tutorial", "FactoryBalances" } do
		local g = hud and hud:FindFirstChild(name) :: GuiObject?
		if g and g.Visible then g.Visible = false table.insert(hidden, g) end
	end
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { CFrame = close, FieldOfView = 42 }):Play()
	task.wait(0.55)
	-- slow drift around the plinth while rolling
	local t0 = os.clock()
	local hold = math.max(0, seconds - 0.55)
	while os.clock() - t0 < hold do
		local a = math.sin((os.clock() - t0) * 0.6) * 0.18 -- gentle sway, stays on the plaza side
		local offset = (CFrame.Angles(0, a, 0) * CFrame.new(dir * reach)).Position
		local d = (os.clock() - t0) / math.max(hold, 0.01)
		cam.CFrame = CFrame.lookAt(look + offset * (1 - d * 0.15) + Vector3.new(0, 4 - d * 0.8, 0), look)
		RunService.RenderStepped:Wait()
	end
	-- reveal: quick punch out with an FOV kick, then hand back to the player
	local out = CFrame.lookAt(look + (cam.CFrame.Position - look).Unit * 22 + Vector3.new(0, 4, 0), look)
	cam.FieldOfView = 36
	TweenService:Create(cam, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = out, FieldOfView = fov + 12 }):Play()
	task.wait(0.9)
	TweenService:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
	cam.CameraType = Enum.CameraType.Custom
	for _, g in hidden do g.Visible = true end
	task.wait(0.4)
	busy = false
end

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) == "table" and v.result and type(v.rollReadyAt) == "number" then
		local seconds = math.max(1.2, v.rollReadyAt - Workspace:GetServerTimeNow())
		task.spawn(rollCamera, seconds)
	end
end)
