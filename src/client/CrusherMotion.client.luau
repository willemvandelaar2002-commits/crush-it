--!strict
-- 11 Nov (audit 8): plays the crusher strikes locally. The server sends one small event
-- per strike (server/CrusherMotionServer) to the players near that factory; this script
-- tweens the moving parts on this client only (Shared.CrusherMotion), timed so contact
-- lands on the server's impact time like the sound and squash (CrusherFeel).
-- Models with a MotionLoop attribute (the Prism showroom, the dev Eternal preview)
-- strike on a loop by themselves, with nothing sent at all.
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
if not Config.Crushers.Enabled then return end
local Motion = require(RS.Shared.CrusherMotion)
local Net = require(RS.Shared.Net)

local function near(model: Model): boolean
	local cam = workspace.CurrentCamera
	if not cam then return true end
	return (model:GetPivot().Position - cam.CFrame.Position).Magnitude <= Motion.PlayDistance
end

Net.event(Motion.Remote).OnClientEvent:Connect(function(list: any)
	if type(list) ~= "table" then return end
	local now = workspace:GetServerTimeNow()
	for _, e in list do
		local model = e.m
		-- not streamed in here (nil), already gone, or far from the camera: nothing to show
		if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent or not near(model) then continue end
		local v = Motion.view(model)
		if not v then continue end
		local cycle = tonumber(e.c) or 1.8
		local late = now - ((tonumber(e.t) or now) - Motion.hitTime(v, cycle))
		if late <= Motion.MaxLate then
			Motion.play(v, { cycle = cycle, completed = e.k == 1, y = e.y }, math.max(0, late))
		end
	end
end)

-- MotionLoop models: found by attribute when they stream in
local looping: { [Model]: boolean } = {}
local function watch(model: Instance)
	if not model:IsA("Model") or looping[model] then return end
	local every = model:GetAttribute("MotionLoop")
	if type(every) ~= "number" then return end
	looping[model] = true
	task.spawn(function()
		task.wait(math.random() * every) -- not every showroom in step
		while model.Parent and looping[model] do
			if near(model) then
				local v = Motion.view(model)
				if v then Motion.play(v, { cycle = 1.8, completed = true }) end
			end
			task.wait(every)
		end
		looping[model] = nil
	end)
end
for _, d in workspace:GetDescendants() do if d:IsA("Model") and d:GetAttribute("MotionKind") then watch(d) end end
workspace.DescendantAdded:Connect(function(d) if d:IsA("Model") and d:GetAttribute("MotionKind") then watch(d) end end)
