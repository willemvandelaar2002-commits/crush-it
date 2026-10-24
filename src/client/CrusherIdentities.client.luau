--!strict
-- Mechanical ornaments only. Rams remain controlled by the existing server.
-- No emitters, sounds, lights, hit listeners, or per-hit instance allocations.
local RS=game:GetService("ReplicatedStorage")
local Tags=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local Motion=require(RS.Shared.CrusherIdentityMotion)
local tag="CrusherIdentity"
local candidates={} local active={} local sequence=0
local function add(model)
	if candidates[model] then return end
	sequence+=1 candidates[model]=sequence
end
local function restore(state)
	state.connection:Disconnect()
	for node,entry in state.entries do if node.Parent then
		if entry.kind=="Glow" then node.Transparency=entry.rest
		else node:PivotTo(entry.rest) end
	end end
end
Tags:GetInstanceAddedSignal(tag):Connect(add)
Tags:GetInstanceRemovedSignal(tag):Connect(function(model)
	candidates[model]=nil
	if active[model] then restore(active[model]) active[model]=nil end
end)
for _,model in Tags:GetTagged(tag) do add(model) end
local function start(model)
	local state={entries={},fit=model:GetAttribute("RigFit") or 1}
	local function collect(node)
		if state.entries[node] then return end
		if node:IsA("Model") and node:GetAttribute("IdentityAxis") then
			state.entries[node]={kind=if node:GetAttribute("IdentityBeat") then "Beat" else "Spin",
				rest=node:GetPivot(),axis=node:GetAttribute("IdentityAxis"),rate=node:GetAttribute("IdentityRate") or 0}
		elseif node:IsA("BasePart") and node:GetAttribute("IdentityPulse") then
			state.entries[node]={kind="Glow",rest=node.Transparency}
		end
	end
	state.connection=model.DescendantAdded:Connect(collect)
	for _,node in model:GetDescendants() do collect(node) end
	return state
end
local selection=Motion.SelectionInterval local elapsed=0
Run.Heartbeat:Connect(function(dt)
	selection+=dt elapsed+=dt
	if selection>=Motion.SelectionInterval then
		selection=0
		local camera=workspace.CurrentCamera
		local selected=if camera then Motion.nearest(candidates,camera.CFrame.Position) else {}
		for model,state in active do
			if not selected[model] then restore(state) active[model]=nil end
		end
		for model in selected do if not active[model] then active[model]=start(model) end end
	end
	if elapsed<Motion.Step then return end elapsed=0
	local now=workspace:GetServerTimeNow()
	for model,state in active do if model.Parent then
		for node,entry in state.entries do
			if not node:IsDescendantOf(model) then state.entries[node]=nil continue end
			if entry.kind=="Glow" then node.Transparency=Motion.glow(entry.rest,now)
			elseif entry.kind=="Beat" then node:PivotTo(Motion.beat(entry.rest,state.fit,now))
			else node:PivotTo(Motion.turn(entry.rest,entry.axis,entry.rate,now)) end
		end
	end end
end)
