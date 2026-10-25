--!strict
-- Static finishing details only: no emitters, sounds, lights or rig transforms.
-- Existing paint/mesh textures and all moving groups remain identifiable.
local C=require(script.Parent.CrusherConfig)
local F={}
function F.apply(model,modifier,front)
	if modifier=="Standard" or modifier=="Rusty" or model:FindFirstChild("CrusherFinish") then return end
	local recipe
	for _,r in C.Coatings do if r.name==modifier then recipe=r break end end
	if not recipe then return end
	front=front or CFrame.new()
	local lo=Vector3.new(math.huge,math.huge,math.huge) local hi=-lo
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=front:PointToObjectSpace(p.CFrame*Vector3.new(p.Size.X*x/2,p.Size.Y*y/2,p.Size.Z*z/2))
			lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
			hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
		end end end
		local name=p.Name:lower()
		if modifier=="Polished" and not p:IsA("MeshPart") and (name:find("armour") or name:find("housing") or name:find("coloured base")) then p.Material=Enum.Material.Metal end
	end end
	if lo.X==math.huge then return end
	local size=hi-lo local centre=(lo+hi)/2
	local root=Instance.new("Model") root.Name="CrusherFinish" root:SetAttribute("Finish",modifier) root.Parent=model
	local function part(name,x,y,z,sx,sy,sz,rot)
		local p=Instance.new("Part") p.Name=name p.Size=Vector3.new(sx,sy,sz)
		p.CFrame=front*CFrame.new(x,y,z)*(rot or CFrame.new()) p.Color=recipe.color
		p.Material=if modifier=="Polished" then Enum.Material.Metal else Enum.Material.Neon
		p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=root
	end
	-- Small badges follow the front edge of the base, below the working bed.
	-- They do not add parts to the moving ram or edit imported texture maps.
	local y=lo.Y+size.Y*.045 local z=hi.Z+.035
	part("Finish strip",centre.X,y,z,size.X*.37,size.Y*.025,size.Z*.025)
	for side=-1,1,2 do
		part(if modifier=="Frost" then "Ice facet" elseif modifier=="Fire" then "Hot vent" elseif modifier=="Charged" then "Charged cell" else "Chrome badge",
			centre.X+side*size.X*.29,y,z,size.X*.055,size.Y*(if modifier=="Frost" then .06 else .04),size.Z*.045,
			if modifier=="Frost" then CFrame.Angles(0,0,side*.2) else nil)
	end
	model:SetAttribute("VisualModifier",modifier)
end
return F
