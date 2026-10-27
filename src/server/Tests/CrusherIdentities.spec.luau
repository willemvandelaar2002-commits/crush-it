--!strict
-- Disposable fixtures only; never grants items or edits profiles/place assets.
return function()
	assert(game:GetService("RunService"):IsStudio(),"Studio only")
	local RS=game:GetService("ReplicatedStorage")
	local R=require(RS.Shared.CrusherIdentityRig)
	local M=require(RS.Shared.CrusherIdentityMotion)
	local C=require(RS.Shared.CrusherConfig)
	local B=require(script.Parent.Parent.CatalogCrushers)
	local checks=0
	local function check(ok,message) checks+=1 assert(ok,message) end
	local function corners(cf,size,fn)
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			fn(cf*Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2))
		end end end
	end
	local origin=CFrame.new(230,17,-90)*CFrame.Angles(0,.63,0)
	for _,id in R.Types do
		local v=B.build(origin,id) v.model.Parent=game.ServerStorage
		check(v.catalog and v.model:GetAttribute("CrusherType")==id,id.." uses catalogue rig path")
		check(v.clearance>.2 and v.bedWidth>0,id.." input space")
		local parts=0 local ornaments=0
		for _,p in v.model:GetDescendants() do if p:IsA("BasePart") then
			parts+=1 check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,id.." safe part")
		end end
		check(parts<180,id.." bounded part count")
		for _,g in v.groups do
			for sample=0,20 do local amount=sample/20
				for _,entry in g.rest do
					corners(B.target(v,g,entry,amount),entry.part.Size,function(point)
						local p=origin:PointToObjectSpace(point)
						check(p.Y>=origin:PointToObjectSpace(v.base.Position).Y-.015,id.." stroke clears bed")
						check(math.abs(p.X)<=C.Layout.MachineWidth/2+.015 and math.abs(p.Z)<=C.Layout.MachineDepth/2+.015 and p.Y<=C.Layout.MachineHeight+.015,id.." stroke fits bay")
					end)
				end
				for _,entry in g.rods do
					local cf,size=B.rodTarget(v,g,entry,amount)
					check((cf*Vector3.new(size.X/2,0,0)-entry.cf*Vector3.new(entry.size.X/2,0,0)).Magnitude<.001,id.." fixed piston top")
				end
			end
		end
		for _,node in v.frame:GetChildren() do if node:IsA("Model") and node:GetAttribute("IdentityAxis") then
			ornaments+=1 local pivot=node:GetPivot()
			for sample=0,48 do
				local moved=if node:GetAttribute("IdentityBeat") then M.beat(pivot,v.model:GetAttribute("RigFit"),sample/7)
					else M.turn(pivot,node:GetAttribute("IdentityAxis"),1,sample*math.pi/24)
				for _,part in node:GetDescendants() do if part:IsA("BasePart") then
					corners(moved*pivot:ToObjectSpace(part.CFrame),part.Size,function(point)
						local p=origin:PointToObjectSpace(point)
						check(math.abs(p.X)<=C.Layout.MachineWidth/2+.02 and math.abs(p.Z)<=C.Layout.MachineDepth/2+.02 and p.Y>=-.02 and p.Y<=C.Layout.MachineHeight+.02,id.." cosmetic sweep fits bay")
					end)
				end end
			end
		end end
		local static={} for _,p in v.frame:GetDescendants() do if p:IsA("BasePart") then static[p]=p.CFrame end end
		B.strike(v,{cycle=.4,completed=true}) task.wait(.4)
		for p,cf in static do check((p.Position-cf.Position).Magnitude<.001,id.." frame stationary during strike") end
		for _,g in v.groups do for _,entry in g.rest do
			check((entry.part.Position-entry.cf.Position).Magnitude<.001,id.." returns to exact rest")
		end end
		v.model:Destroy()
	end
	check(#R.Types==35 and #C.Types==40+#C.Mythics,"thirty-five authored rigs plus five imported types plus the Mythics")
	check(not R.supports("GoldenKing") and not R.supports("Toyzilla") and not R.supports("TwinTitan"),"imported specials preserved")
	check(not R.supports("Magnetron") and not R.supports("RocketPress"),"all five imports preserved")
	for _,def in C.Types do check(R.supports(def.id)==(def.template==nil),"every code-built type covered; imported templates retained") end
	for i=0,200 do check(M.glow(0,i/13)>=0 and M.glow(0,i/13)<=1,"bounded core glow") end
	return {passed=checks,identities=#R.Types}
end
