--!strict
-- Brings coating dressing to life on your screen (CrusherFinish, tag
-- CoatingFx): Charged lightning arcs flicker and jump, Fire light flickers,
-- Frost and Polished lights shimmer. Only coated crushers near the camera
-- are animated (12 times a second). Visual only.
local Tags = game:GetService("CollectionService")
local Run = game:GetService("RunService")

local roots: { [Instance]: { arcs: { Beam }, lights: { PointLight }, finish: string } } = {}
local function add(root: Instance)
	local entry = { arcs = {}, lights = {}, finish = tostring(root:GetAttribute("Finish")) }
	for _, d in root:GetDescendants() do
		if d:IsA("Beam") then table.insert(entry.arcs, d)
		elseif d:IsA("PointLight") then table.insert(entry.lights, d) end
	end
	roots[root] = entry
end
for _, r in Tags:GetTagged("CoatingFx") do add(r) end
Tags:GetInstanceAddedSignal("CoatingFx"):Connect(function(r) task.defer(add, r) end)
Tags:GetInstanceRemovedSignal("CoatingFx"):Connect(function(r) roots[r] = nil end)

local rng = Random.new()
local acc = 0
Run.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 12 then return end
	acc = 0
	local camera = workspace.CurrentCamera
	if not camera then return end
	local eye = camera.CFrame.Position
	for root, e in roots do
		if not root.Parent then roots[root] = nil continue end
		local first = e.arcs[1] or e.lights[1]
		local holder = first and first.Parent
		if not (holder and holder:IsA("BasePart")) or (holder.Position - eye).Magnitude > 150 then continue end
		if e.finish == "Charged" then
			for _, b in e.arcs do
				b.Enabled = rng:NextNumber() < .85
				local s = (b.Width0 * 18)
				b.CurveSize0 = rng:NextNumber(-s, s) b.CurveSize1 = rng:NextNumber(-s, s)
			end
			for _, l in e.lights do l.Brightness = rng:NextNumber(1, 2.6) end
		elseif e.finish == "Fire" then
			for _, l in e.lights do l.Brightness = rng:NextNumber(1.6, 2.8) end
		else
			for _, l in e.lights do l.Brightness = 1.2 + .4 * math.sin(os.clock() * 3) end
		end
	end
end)
