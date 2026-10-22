--!strict
-- Studio-only rendering/rig test. Uses disposable clones, never edits templates.
return function()
	assert(game:GetService("RunService"):IsStudio(),"Studio only")
	local Builder=require(script.Parent.Parent.SpecialCrushers)
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local count=0 local results={}
	local function check(v,message) assert(v,message) count+=1 end
	for _,id in {"TwinTitan","RocketPress","Magnetron","GoldenKing","Toyzilla"} do
		local v=Builder.build(CFrame.new(),id) check(v~=nil,id.." template resolves")
		v.model.Parent=game.ServerStorage
		local _,size=v.model:GetBoundingBox()
		check(size.X<=C.Layout.MachineWidth+.01 and size.Y<=C.Layout.MachineHeight+.01 and size.Z<=C.Layout.MachineDepth+.01,id.." fits bay")
		local frames={}
		if v.frame:IsA("BasePart") then frames[v.frame]=v.frame.CFrame end
		for _,p in v.frame:GetDescendants() do if p:IsA("BasePart") then frames[p]=p.CFrame end end
		local anchored=true for _,p in v.model:GetDescendants() do if p:IsA("BasePart") and not p.Anchored then anchored=false end end
		check(anchored,id.." all parts anchored")
		local original=game.ServerStorage.SpecialCrusherMeshes[id]:FindFirstChild("Frame",true)
		check(v.frame.Material==original.Material and v.frame.Color==original.Color,id.." imported material and tint preserved")
		local map,originalMap=v.frame:FindFirstChildOfClass("SurfaceAppearance"),original:FindFirstChildOfClass("SurfaceAppearance")
		check((map==nil and originalMap==nil) or (map and originalMap and map.ColorMap==originalMap.ColorMap and map.NormalMap==originalMap.NormalMap and map.RoughnessMap==originalMap.RoughnessMap and map.MetalnessMap==originalMap.MetalnessMap),id.." imported maps preserved")
		check(#v.groups==(if id=="TwinTitan" then 2 else 1),id.." moving groups")
		Builder.strike(v,{cycle=1,completed=true}) task.wait(.26)
		for _,g in v.groups do for _,entry in g.rest do
			check(math.abs((entry.cf.Position-entry.part.Position).Magnitude-g.stroke)<.025,id.." uses scaled manifest stroke")
		end end
		for p,cf in frames do check((p.CFrame.Position-cf.Position).Magnitude<.0001,id.." frame stays stationary") end
		task.wait(.45)
		for _,g in v.groups do for _,entry in g.rest do check((entry.cf.Position-entry.part.Position).Magnitude<.001,id.." ram returns to imported rest transform") end end
		if id=="TwinTitan" then
			Builder.strike(v,{cycle=1,completed=false}) task.wait(.26)
			check((v.groups[1].rest[1].part.Position-v.groups[1].rest[1].cf.Position).Magnitude<.001,"Twin left waits for right's turn")
			check((v.groups[2].rest[1].part.Position-v.groups[2].rest[1].cf.Position).Magnitude>1,"Twin right alternates")
			task.wait(.45)
			Builder.strike(v,{cycle=1,completed=false}) task.wait(.26)
			check((v.groups[1].rest[1].part.Position-v.groups[1].rest[1].cf.Position).Magnitude>1,"Twin left alternates")
			task.wait(.45)
		end
		results[id]={size=tostring(size),fit=v.model:GetAttribute("ManifestFit"),groups=#v.groups}
		v.model:Destroy()
	end
	-- Importers can wrap named components in Models rather than MeshParts.
	local source=game.ServerStorage.SpecialCrusherMeshes.RocketPress:Clone()
	for _,name in {"Frame","Ram"} do
		local node=source:FindFirstChild(name,true) local parent=node.Parent
		local wrapper=Instance.new("Model") wrapper.Name=name wrapper.WorldPivot=node:GetPivot() wrapper.Parent=parent
		node.Name="Geometry" node.Parent=wrapper
	end
	local wrapped=Builder.build(CFrame.new(10,20,30),"RocketPress",source)
	check(wrapped~=nil and wrapped.frame:IsA("Model") and #wrapped.groups[1].rest==1,"nested Frame/Ram Model wrappers supported")
	check((wrapped.model:GetPivot().Position-Vector3.new(10,20,30)).Magnitude<.001,"imported root pivot anchors the placed model")
	wrapped.model:Destroy() source:Destroy()
	return {passed=count,models=results}
end
