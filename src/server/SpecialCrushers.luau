--!strict
-- Imported rigid assemblies: clone/fit as a whole, then translate only named rams.
-- kit="motion" (crate crushers) also rotates hinges and stretches pistons (B.rig).
local Storage=game:GetService("ServerStorage")
local Tween=game:GetService("TweenService")
local Assets=require(game.ReplicatedStorage.Shared.SpecialCrusherAssets)
local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
local Feedback=require(game.ReplicatedStorage.Shared.CrusherFeedback)
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
	local rig=nil
	if metadata.kit=="motion" then
		rig=B.rig(model,metadata,fit)
		for name,alpha in metadata.transparent or {} do local p=component(model,name) if p and p:IsA("BasePart") then p.Transparency=alpha end end
		for _,name in metadata.contact do for _,p in parts(component(model,name)) do
			for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
				lowest=math.min(lowest,origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)).Y)
			end end end
		end end
	end
	return {model=model,groups=groups,frame=frame,special=id,origin=placed,rig=rig,
		base=origin*CFrame.new(0,bedY,0),clearance=lowest-bedY,bedWidth=6*fit,strikes=0}
end

-- kit="motion" rigs (crate crushers). Everything is worked out once at build:
-- the pose of every moving part at each key time of the Blender demo curves.
-- A strike then only tweens from key to key (no per-frame loop per crusher).
local CURVES={ -- (frame-1)/71 -> amount, from the pack's build.py
	press={{0,0},{15/71,0},{26/71,.25},{33/71,1},{39/71,1},{56/71,0},{1,0}},
	wind={{0,0},{11/71,.18},{24/71,.76},{33/71,1},{43/71,1},{62/71,0},{1,0}},
}
local function amount(curve,t)
	local keys=CURVES[curve] or CURVES.press
	for i=2,#keys do local a,b=keys[i-1],keys[i]
		if t<=b[1] then return a[2]+(b[2]-a[2])*(t-a[1])/math.max(1e-6,b[1]-a[1]) end
	end
	return keys[#keys][2]
end
function B.rig(model,metadata,fit)
	local Pm=metadata.parts
	local frame=component(model,"Frame")
	-- FBX -> world: anchor on the Frame, scale from its size, and the turn about Y
	-- from the part that sits furthest from the Frame horizontally.
	local scale=frame.Size.Magnitude/Pm.Frame.size.Magnitude
	local best,far=nil,-1
	for name,info in Pm do if name~="Frame" then
		local d=info.center-Pm.Frame.center local h=Vector2.new(d.X,d.Z).Magnitude
		if h>far then best,far=name,h end
	end end
	local yaw=0
	if best and far>1e-3 then
		local fd=Pm[best].center-Pm.Frame.center
		local wd=component(model,best).Position-frame.Position
		yaw=math.atan2(wd.X,wd.Z)-math.atan2(fd.X,fd.Z)
	end
	local turn=CFrame.Angles(0,yaw,0)
	local function point(p) return frame.Position+turn:VectorToWorldSpace((p-Pm.Frame.center)*scale) end
	local function vector(v) return turn:VectorToWorldSpace(v*scale) end
	local motions={} for _,m in metadata.motion do motions[m.name]=motions[m.name] or {} table.insert(motions[m.name],m) end
	local moving={}
	for name,info in Pm do if motions[name] or (info.parent and motions[info.parent]) then moving[name]=true end end
	local rest={} for name in moving do local p=component(model,name) rest[name]={part=p,cf=p.CFrame,size=p.Size} end
	for name in moving do if Pm[name].parent and not rest[Pm[name].parent] then local q=component(model,Pm[name].parent) rest[Pm[name].parent]={part=q,cf=q.CFrame,size=q.Size} end end
	local times,seen={}, {}
	for _,keys in CURVES do for _,k in keys do if not seen[k[1]] then seen[k[1]]=true table.insert(times,k[1]) end end end
	table.sort(times)
	local function pose(name,t)
		local r=rest[name] local cf,size=r.cf,r.size
		local o=point(Pm[name].origin)
		for _,m in motions[name] or {} do
			local a=amount(m.curve,t)
			if m.kind=="move" then
				local d=vector(m.vector)*a cf=cf+d o+=d
			elseif m.kind=="rotate" then
				cf=CFrame.new(o)*CFrame.fromAxisAngle(turn:VectorToWorldSpace(m.axis),m.angle*a)*CFrame.new(-o)*cf
			elseif m.kind=="extend" then
				local k=1+(m.ratio-1)*a
				local want=turn:VectorToWorldSpace(if m.axis=="X" then Vector3.xAxis elseif m.axis=="Z" then Vector3.zAxis else Vector3.yAxis)
				local axis,dot=Vector3.yAxis,-1
				for _,c in {Vector3.xAxis,Vector3.yAxis,Vector3.zAxis} do local d=math.abs(cf:VectorToWorldSpace(c):Dot(want)) if d>dot then axis,dot=c,d end end
				local rel=cf:PointToObjectSpace(o):Dot(axis)
				cf=cf*CFrame.new(axis*rel*(1-k)) size=size+axis*size:Dot(axis)*(k-1)
			end
		end
		local parent=Pm[name].parent
		if parent and rest[parent] then local pc=pose(parent,t) cf=(pc.cf*rest[parent].cf:Inverse())*cf end
		return {cf=cf,size=size}
	end
	local poses={} for name in moving do poses[name]={} for i,t in times do poses[name][i]=pose(name,t) end end
	return {times=times,poses=poses,rest=rest,busy=false}
end
local function rigStrike(v,event)
	local rig=v.rig if rig.busy then return end rig.busy=true
	-- contact (key 33/71) lands when the shared feedback expects the hit; the
	-- return stroke takes the rest of the time
	local cycle=event.cycle or 1.8
	local hit=Feedback.timing(cycle,true).hit
	local back=math.clamp(cycle*.55,.45,1)
	local CONTACT=33/71
	task.spawn(function()
		for i=2,#rig.times do
			local t0,t1=rig.times[i-1],rig.times[i]
			local dt=if t1<=CONTACT then (t1-t0)/CONTACT*hit else (t1-t0)/(1-CONTACT)*back
			for name,list in rig.poses do
				local part=rig.rest[name].part local a,b=list[i-1],list[i]
				if part.Parent and (a.cf~=b.cf or a.size~=b.size) then
					Tween:Create(part,TweenInfo.new(dt,Enum.EasingStyle.Linear),{CFrame=b.cf,Size=b.size}):Play()
				end
			end
			task.wait(dt)
			if not v.model.Parent then break end
		end
		for _,r in rig.rest do if r.part.Parent then r.part.CFrame=r.cf r.part.Size=r.size end end
		rig.busy=false
	end)
end
function B.strike(v,event)
	if v.rig then rigStrike(v,event) return end
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
