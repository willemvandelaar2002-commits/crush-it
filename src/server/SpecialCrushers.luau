--!strict
-- Imported rigid assemblies: clone/fit as a whole, then translate only named rams.
-- kit="motion" (crate crushers) also rotates hinges and stretches pistons (B.rig).
local Storage=game:GetService("ServerStorage")
local Assets=require(game.ReplicatedStorage.Shared.SpecialCrusherAssets)
local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
local Motion=require(game.ReplicatedStorage.Shared.CrusherMotion)
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
function B.build(origin,id,source: Model?,scale: number?)
	local metadata=Assets[id] local folder=Storage:FindFirstChild("SpecialCrusherMeshes")
	local template=source or (folder and folder:FindFirstChild(id))
	if not metadata or not template or not template:IsA("Model") then return nil end
	local model=template:Clone() local frame=component(model,"Frame") local named={}
	if not frame then model:Destroy() return nil end
	for _,spec in metadata.rams or {} do local ram=component(model,spec.name)
		if not ram then model:Destroy() return nil end table.insert(named,{node=ram,spec=spec})
	end
	if metadata.kit=="motion" then for name in metadata.parts do
		if not component(model,name) then model:Destroy() return nil end
	end end
	for _,p in parts(model) do p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end
	local _,imported=model:GetBoundingBox() local size=metadata.size local l=C.Layout
	-- Recover the importer's uniform unit factor without editing the stored asset.
	local unitScale=math.max(imported.X/size.X,imported.Y/size.Y,imported.Z/size.Z)
	local fit=math.min(if metadata.grow then math.huge else 1,l.MachineWidth/size.X,l.MachineHeight/size.Y,l.MachineDepth/size.Z)*(scale or 1) -- scale: optional extra size (the Prism showroom pad)
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
	local rig=nil
	if metadata.kit=="motion" then
		rig=B.rig(model,metadata,fit)
		for name,alpha in metadata.transparent or {} do local p=component(model,name) if p and p:IsA("BasePart") then p.Transparency=alpha end end
		for _,name in metadata.contact or {} do for _,p in parts(component(model,name)) do
			for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
				lowest=math.min(lowest,origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)).Y)
			end end end
		end end
	end
	-- 5 Nov (new Secret/Divine pack): the scrap sits at the model's own input point
	-- (between the rollers, in the jaws, floating in the Celestial orbit) at a set size
	if metadata.inputCenter and metadata.inputSize then
		local s=metadata.inputSize*fit
		local at=placed:PointToWorldSpace(metadata.inputCenter*fit-Vector3.new(0,s/2,0))
		local v={model=model,groups=groups,frame=frame,special=id,origin=placed,rig=rig,
			base=CFrame.new(at)*origin.Rotation,clearance=s,bedWidth=s*1.1,strikes=0}
		B.tag(v) return v
	end
	local v={model=model,groups=groups,frame=frame,special=id,origin=placed,rig=rig,
		base=origin*CFrame.new(0,bedY,0),clearance=lowest-bedY,bedWidth=6*fit,strikes=0}
	B.tag(v) return v
end

-- kit="motion" rigs (crate crushers): the keyframed poses are worked out in
-- Shared.CrusherMotion (11 Nov: moved there, the clients rebuild them for local playback).
function B.rig(model,metadata,_fit) return Motion.rig(model,metadata) end
-- the contact pose of every moving part, for the clients (Shared.CrusherMotion)
function B.tag(v)
	if v.rig then Motion.tagRig(v.model) return end
	local groups={}
	for i,group in v.groups do
		local list={}
		for _,entry in group.rest do table.insert(list,{part=entry.part,down=CFrame.new(-v.origin.UpVector*group.stroke)*entry.cf}) end
		groups[i]=list
	end
	Motion.tagGroups(v.model,.38,groups)
end
-- 11 Nov: in the game the server only sends a strike event (CrusherMotionServer) and
-- each client plays it; this server playback is kept for the specs and dev tools.
function B.strike(v,event)
	local view=Motion.view(v.model) if view then Motion.play(view,event) end
end
return B
