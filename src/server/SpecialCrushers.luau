--!strict
-- Imported rigid assemblies: clone/fit as a whole, then translate only named rams.
local Storage=game:GetService("ServerStorage")
local Tween=game:GetService("TweenService")
local Assets=require(game.ReplicatedStorage.Shared.SpecialCrusherAssets)
local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
local B={}
local function parts(node)
	local out={} if node:IsA("BasePart") then table.insert(out,node) end
	for _,v in node:GetDescendants() do if v:IsA("BasePart") then table.insert(out,v) end end return out
end
local function component(root,name)
	-- Locate the named component through any importer-introduced Model wrappers.
	if root.Name==name and #parts(root)>0 then return root end
	for _,v in root:GetChildren() do local found=component(v,name) if found then return found end end
end
function B.build(origin,id,source: Model?)
	local metadata=Assets[id] local folder=Storage:FindFirstChild("SpecialCrusherMeshes")
	local template=source or (folder and folder:FindFirstChild(id))
	if not metadata or not template or not template:IsA("Model") then return nil end
	local model=template:Clone() local frame=component(model,"Frame") local named={}
	if not frame then model:Destroy() return nil end
	for _,spec in metadata.rams do local ram=component(model,spec.name)
		if not ram then model:Destroy() return nil end table.insert(named,{node=ram,spec=spec})
	end
	for _,p in parts(model) do p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end
	local _,imported=model:GetBoundingBox() local size=metadata.size local l=C.Layout
	-- Recover the importer's uniform unit factor without editing the stored asset.
	local unitScale=math.max(imported.X/size.X,imported.Y/size.Y,imported.Z/size.Z)
	local fit=math.min(if metadata.grow then math.huge else 1,l.MachineWidth/size.X,l.MachineHeight/size.Y,l.MachineDepth/size.Z)
	-- These FBX imports face -Z in Studio (verified against Toyzilla's eyes).
	-- Turn the whole clone, preserving every component's imported local transform.
	local yaw=template:GetAttribute("BayFrontYaw")
	local placed=origin*CFrame.Angles(0,if type(yaw)=="number" then yaw else math.pi,0)
	model:ScaleTo(model:GetScale()*fit/unitScale) model:PivotTo(placed)
	local groups={} local lowest=math.huge
	for _,entry in named do local rest={}
		local lift=(entry.spec.lift or 0)*fit
		for _,p in parts(entry.node) do
			if lift~=0 then p.CFrame=CFrame.new(placed.UpVector*lift)*p.CFrame end
			table.insert(rest,{part=p,cf=p.CFrame})
			for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
				local point=origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2))
				if not entry.spec.side then lowest=math.min(lowest,point.Y) end
			end end end
		end
		table.insert(groups,{name=entry.spec.name,rest=rest,stroke=entry.spec.stroke*fit})
	end
	model:SetAttribute("SpecialTemplate",id) model:SetAttribute("ManifestFit",fit)
	local bedY=metadata.bedTop*fit
	return {model=model,groups=groups,frame=frame,special=id,origin=placed,
		base=origin*CFrame.new(0,bedY,0),clearance=lowest-bedY,bedWidth=6*fit,strikes=0}
end
function B.strike(v,event)
	v.strikes+=1 local duration=math.min(.6,event.cycle*.7)
	for i,group in v.groups do
		-- Twin Titan alternates, with a simultaneous finishing stroke. Visual only:
		-- the existing rules transaction still awards exactly one completed input.
		if #v.groups>1 and not event.completed and i~=((v.strikes-1)%#v.groups+1) then continue end
		for _,entry in group.rest do
			local p=entry.part local rest=entry.cf
			local down=CFrame.new(-v.origin.UpVector*group.stroke)*rest
			Tween:Create(p,TweenInfo.new(duration*.38,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=down}):Play()
			task.delay(duration*.48,function()
				if v.model.Parent and p.Parent then Tween:Create(p,TweenInfo.new(duration*.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=rest}):Play() end
			end)
		end
	end
end
return B
