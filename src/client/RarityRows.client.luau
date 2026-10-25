--!strict
-- Gentle row-wide glow. Static rails still show beyond the local pulse budget.
local Tags=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local candidates={} local active={} local order=0 local scan=.2 local elapsed=0
local function add(model) order+=1 candidates[model]=order end
local function reset(model,parts)
	for _,p in parts do if p.Parent then p.Transparency=if model:GetAttribute("RowSetActive") then .18 else 1 end end
end
Tags:GetInstanceAddedSignal("CrusherRarityRow"):Connect(add)
Tags:GetInstanceRemovedSignal("CrusherRarityRow"):Connect(function(model)
	candidates[model]=nil if active[model] then reset(model,active[model]) active[model]=nil end
end)
for _,model in Tags:GetTagged("CrusherRarityRow") do add(model) end
Run.Heartbeat:Connect(function(dt)
	scan+=dt elapsed+=dt
	if scan>=.2 then
		scan=0 local ranked={} local camera=workspace.CurrentCamera
		if camera then for model,sequence in candidates do
			if model:IsDescendantOf(workspace) and model:GetAttribute("RowSetActive") then
				local distance=(model:GetPivot().Position-camera.CFrame.Position).Magnitude
				if distance<=135 then table.insert(ranked,{model=model,distance=distance,sequence=sequence}) end
			end
		end end
		table.sort(ranked,function(a,b) return if a.distance==b.distance then a.sequence<b.sequence else a.distance<b.distance end)
		local selected={}
		for i=1,math.min(4,#ranked) do selected[ranked[i].model]=true end
		for model,parts in active do if not selected[model] then reset(model,parts) active[model]=nil end end
		for model in selected do
			local parts={} for _,p in model:GetChildren() do if p:IsA("BasePart") and p.Name=="RarityRail" then table.insert(parts,p) end end
			active[model]=parts -- also picks up late-streamed rails
		end
	end
	if elapsed<1/20 then return end elapsed=0
	local now=workspace:GetServerTimeNow()
	for model,parts in active do if model:GetAttribute("RowSetActive") then
		local alpha=.16+.08*(.5+.5*math.sin(now*2))
		for _,p in parts do if p.Parent then p.Transparency=alpha end end
	end end
end)
