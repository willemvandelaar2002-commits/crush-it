--!strict
-- Base glow plus pooled Epic/Legendary accents; gameplay remains server-owned.
local Tags=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Effects=require(script.Parent.RowSetEffects).new(workspace)
local candidates={} local active={} local order=0 local scan=.2 local elapsed=0
local connections={}
local function add(model)
 if candidates[model] then return end order+=1
 local state={sequence=order,active=model:GetAttribute("RowSetActive"),rarity=model:GetAttribute("RowRarity"),activatedAt=nil :: number?,signals={} :: {RBXScriptConnection}}
 candidates[model]=state
 local function changed()
  local enabled=model:GetAttribute("RowSetActive") local rarity=model:GetAttribute("RowRarity")
  if enabled and (not state.active or rarity~=state.rarity) then state.activatedAt=workspace:GetServerTimeNow() end
  state.active=enabled state.rarity=rarity scan=.2
  if not enabled then Effects.forget(model) end
 end
 state.signals={model:GetAttributeChangedSignal("RowSetActive"):Connect(changed),model:GetAttributeChangedSignal("RowRarity"):Connect(changed)}
end
local function reset(model,parts)
	for _,p in parts do if p.Parent then p.Transparency=if model:GetAttribute("RowSetActive") then .18 else 1 end end
end
table.insert(connections,Tags:GetInstanceAddedSignal("CrusherRarityRow"):Connect(add))
table.insert(connections,Tags:GetInstanceRemovedSignal("CrusherRarityRow"):Connect(function(model)
 local state=candidates[model] if state then for _,c in state.signals do c:Disconnect() end end
 Effects.forget(model)
	candidates[model]=nil if active[model] then reset(model,active[model]) active[model]=nil end
end))
for _,model in Tags:GetTagged("CrusherRarityRow") do add(model) end
table.insert(connections,Run.Heartbeat:Connect(function(dt)
	scan+=dt elapsed+=dt
	if scan>=.2 then
		scan=0 local ranked={} local camera=workspace.CurrentCamera
		local now=workspace:GetServerTimeNow()
		local ownPlot="Plot"..tostring(Players.LocalPlayer:GetAttribute("Plot"))
		if camera then for model,state in candidates do
			if model:IsDescendantOf(workspace) and model:GetAttribute("RowSetActive") then
				local distance=(model:GetPivot().Position-camera.CFrame.Position).Magnitude
				if distance<=135 then table.insert(ranked,{model=model,distance=distance,sequence=state.sequence,own=model.Parent~=nil and model.Parent.Name==ownPlot,activatedAt=state.activatedAt}) end
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
  table.sort(ranked,function(a,b)
   if a.own~=b.own then return a.own end
   return if a.distance==b.distance then a.sequence<b.sequence else a.distance<b.distance
  end)
  Effects.sync(ranked,now)
 end
 if elapsed<1/20 then return end elapsed=0
	local now=workspace:GetServerTimeNow()
	Effects.step(now)
	for model,parts in active do if model:GetAttribute("RowSetActive") then
		local alpha=.16+.08*(.5+.5*math.sin(now*2))
		for _,p in parts do if p.Parent then p.Transparency=alpha end end
	end end
end))
script.Destroying:Connect(function()
 for _,c in connections do c:Disconnect() end
 for _,state in candidates do for _,c in state.signals do c:Disconnect() end end
 for model,parts in active do reset(model,parts) end
 Effects.destroy()
end)
