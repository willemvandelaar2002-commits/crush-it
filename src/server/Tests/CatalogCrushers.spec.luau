--!strict
-- Disposable Studio fixtures; no live inventory or place template is edited.
return function()
	assert(game:GetService("RunService"):IsStudio(),"Studio only")
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local B=require(script.Parent.Parent.CatalogCrushers)
	local checks=0 local designs=0
	local function check(ok,message) checks+=1 assert(ok,message) end
	for _,def in C.Types do if def.design then
		designs+=1 local v=B.build(CFrame.new(),def.id) v.model.Parent=game.ServerStorage
		local _,size=v.model:GetBoundingBox()
		check(size.X<=C.Layout.MachineWidth+.01 and size.Y<=C.Layout.MachineHeight+.01 and size.Z<=C.Layout.MachineDepth+.01,def.id.." fits bay")
		check(v.clearance>0 and v.bedWidth>0 and #v.groups>0,def.id.." has a usable bed and moving rig")
		local static={}
		for _,p in v.frame:GetDescendants() do if p:IsA("BasePart") then static[p]=p.CFrame end end
		local parts=0
		for _,p in v.model:GetDescendants() do if p:IsA("BasePart") then
			parts+=1 check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,def.id.." safe visual parts")
		end end
		check(parts<240,def.id.." bounded part count")
		for sample=0,4 do local amount=sample/4
			for _,g in v.groups do
				for _,entry in g.rest do
					local cf=B.target(v,g,entry,amount)
					for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
						local point=cf*Vector3.new(x*entry.part.Size.X/2,y*entry.part.Size.Y/2,z*entry.part.Size.Z/2)
						check(point.Y>=v.base.Position.Y-.015,def.id.." moving geometry clears work surface")
					end end end
				end
				for _,entry in g.rods do
					local cf,size=B.rodTarget(v,g,entry,amount)
					local top=cf*Vector3.new(size.X/2,0,0)
					check((top-entry.cf*Vector3.new(entry.size.X/2,0,0)).Magnitude<.001,def.id.." telescoping shaft stays connected")
				end
			end
		end
		B.strike(v,{cycle=1,completed=true}) task.wait(.27)
		for part,cf in static do check((part.Position-cf.Position).Magnitude<.001,def.id.." frame stays fixed") end
		task.wait(.5)
		for _,g in v.groups do
			for _,entry in g.rest do check((entry.part.Position-entry.cf.Position).Magnitude<.001,def.id.." returns to rest") end
			for _,entry in g.rods do check((entry.part.Size-entry.size).Magnitude<.001,def.id.." rod length resets") end
		end
		v.model:Destroy()
	end end
	check(designs==29 and #C.Types==40+#C.Mythics,"all forty definitions (plus Mythics) and twenty-nine new rigs")
	return {passed=checks,designs=designs}
end
