--!strict
-- 11 Nov (audit 8): plays the crusher strikes locally. The server sends one small event
-- per strike (server/CrusherMotionServer) to the players near that factory; this script
-- tweens the moving parts on this client only (Shared.CrusherMotion), timed so contact
-- lands on the server's impact time like the sound and squash (CrusherFeel).
-- 11 Nov (8b): the toy on each crusher's bed is built here too, from the model's Toy
-- attribute ("number:toy index:scale", bed at ToyBase), and squashed at each strike's
-- contact (the event's f). CrusherFeel animates the squash of the nearest ones.
-- Models with a MotionLoop attribute (the Prism showroom, the dev Eternal preview)
-- strike on a loop by themselves, with nothing sent at all.
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
if not Config.Crushers.Enabled then return end
local Motion = require(RS.Shared.CrusherMotion)
local Net = require(RS.Shared.Net)
local Objects = require(RS.Shared.Objects)
local F = require(RS.Shared.CrusherFeedback)
local LINGER = require(RS.Shared.CrusherConfig).CrushedLinger

-- the toy on the bed ------------------------------------------------------------------
local toys: { [Model]: Model } = setmetatable({}, { __mode = "k" }) :: any
local function newToy(model: Model)
	local spec = model:GetAttribute("Toy")
	local base = model:GetAttribute("ToyBase")
	if type(spec) ~= "string" or typeof(base) ~= "CFrame" then return end
	local _, index, scale = string.match(spec, "^(%d+):(%d+):([%d%.]+)$")
	local i, k = tonumber(index), tonumber(scale)
	if not i or not k then return end
	-- 31 Oct: the flattened toy stays on the bed a moment under the new one
	local old = toys[model]
	if old then
		old.Name = "CrushedInput"
		if ((old:GetAttribute("SquashFraction") :: number?) or 1) < 1 then
			task.delay(LINGER, function() old:Destroy() end)
		else old:Destroy() end
	end
	local ok, toy = pcall(Objects.build, i, base, "Normal")
	if not ok or not toy then return end
	Objects.scale(toy, base, k)
	toy.Name = "ProductionInput"
	toy:SetAttribute("SquashFraction", 1)
	for _, p in toy:GetDescendants() do if p:IsA("BasePart") then p.CanQuery = false end end
	toy.Parent = model
	toys[model] = toy
end
local function squashAt(model: Model, f: number, at: number)
	local toy = toys[model]
	local base = model:GetAttribute("ToyBase")
	if not toy or typeof(base) ~= "CFrame" then return end
	-- after CrusherFeel's own squash animation ends, so the two don't fight
	local wait = at + F.SquashTail + .02 - workspace:GetServerTimeNow()
	task.delay(math.max(0, wait), function()
		if toys[model] == toy and toy.Parent then
			Objects.setSquash(toy, base, f)
			toy:SetAttribute("SquashFraction", f)
		end
	end)
end
local watchedToys: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function watchToy(model: Model)
	if watchedToys[model] then return end
	watchedToys[model] = true
	newToy(model)
	model:GetAttributeChangedSignal("Toy"):Connect(function() newToy(model) end)
end

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
		if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then continue end
		if type(e.f) == "number" then squashAt(model, e.f, tonumber(e.t) or now) end
		if not near(model) then continue end
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
local function found(d: Instance)
	if d:IsA("Model") and d:GetAttribute("MotionKind") then
		watch(d)
		if d.Name == "EquippedCrusher" then watchToy(d) end
	end
end
for _, d in workspace:GetDescendants() do found(d) end
workspace.DescendantAdded:Connect(found)
