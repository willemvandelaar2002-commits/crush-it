--!strict
-- Spins the roll pedestal crushers (silhouettes and offers) on this client.
-- The server only sets attributes (BasePivot, SpinCentre, SpinSpeed,
-- SpinStart, SpinLift) and tags the model "RollSpin", so no part movement is
-- replicated. Only models near the camera are moved, 30 times a second.
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
local RollLook = require(RS.Shared.CrusherRollPresentation)

local models: { [Model]: boolean } = {}
local function add(m: Instance) if m:IsA("Model") then models[m] = true end end
for _, m in Tags:GetTagged("RollSpin") do add(m) end
Tags:GetInstanceAddedSignal("RollSpin"):Connect(add)
Tags:GetInstanceRemovedSignal("RollSpin"):Connect(function(m) models[m :: Model] = nil end)

local MAX_AGE = 30 -- stop turning after this long (as before)
local acc = 0
Run.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local camera = workspace.CurrentCamera
	if not camera then return end
	local eye = camera.CFrame.Position
	local now = workspace:GetServerTimeNow()
	for m in models do
		if not m.Parent then models[m] = nil continue end
		local base = m:GetAttribute("BasePivot")
		local centre = m:GetAttribute("SpinCentre")
		local start = m:GetAttribute("SpinStart")
		local speed = m:GetAttribute("SpinSpeed")
		if typeof(base) ~= "CFrame" or typeof(centre) ~= "Vector3" or type(start) ~= "number" or type(speed) ~= "number" then continue end
		if (centre - eye).Magnitude > 140 then continue end
		local age = math.clamp(now - start, 0, MAX_AGE)
		if age >= MAX_AGE and m:GetAttribute("SpinDone") then continue end
		local rarity = m:GetAttribute("SpinLift")
		local lift = if type(rarity) == "string" then RollLook.lift(rarity, age) else 0
		m:PivotTo(CFrame.new(0, lift, 0) * CFrame.new(centre) * CFrame.Angles(0, age * speed, 0) * CFrame.new(-centre) * base)
		if age >= MAX_AGE then m:SetAttribute("SpinDone", true) end
	end
end)
