--!strict
-- Twenty-nine self-contained toy-factory rigs. Built from Roblox parts, so no
-- asset upload/import is required. Each has a distinct silhouette/mechanism.
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local C=require(RS.Shared.CrusherConfig)
local Style=require(RS.Shared.Kit.Style)
local B={}
local V=Vector3.new local F=CFrame.new local A=CFrame.Angles
local ink=Color3.fromRGB(19,23,42) local steel=Color3.fromRGB(200,222,240)
local gold=Color3.fromRGB(255,200,58) local cyan=Color3.fromRGB(80,230,255)
local white=Color3.fromRGB(241,247,255)

function B.build(origin,typeId)
	local def=C.typeById(typeId)
	if not def or not def.design then return nil end
	local model=Instance.new("Model") model.Name=def.name model.WorldPivot=CFrame.new()
	local frame=Instance.new("Model") frame.Name="Frame" frame.Parent=model
	local groups={} local accent=def.accent local design=def.design
	local function part(parent,name,size,pos,color,shape,rotation)
		local p=Instance.new("Part") p.Name=name p.Size=size
		p.CFrame=F(pos)*(rotation or CFrame.new()) p.Color=color or accent
		p.Material=Enum.Material.SmoothPlastic p.Shape=shape or Enum.PartType.Block
		p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
		p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent
		return p
	end
	local function box(parent,name,x,y,z,sx,sy,sz,color,rotation)
		return part(parent,name,V(sx,sy,sz),V(x,y,z),color,nil,rotation)
	end
	local function cylinder(parent,name,x,y,z,length,diameter,color,axis)
		local rot=if axis=="Y" then A(0,0,math.pi/2) elseif axis=="Z" then A(0,math.pi/2,0) else CFrame.new()
		return part(parent,name,V(length,diameter,diameter),V(x,y,z),color,Enum.PartType.Cylinder,rot)
	end
	local function ball(parent,name,x,y,z,diameter,color)
		return part(parent,name,V(diameter,diameter,diameter),V(x,y,z),color,Enum.PartType.Ball)
	end
	local function beam(parent,name,a,b,width,depth,color)
		return part(parent,name,V(width,depth,(b-a).Magnitude),(a+b)/2,color,nil,CFrame.lookAt(Vector3.zero,b-a))
	end
	local function ring(parent,name,centre,radius,color,plane,count)
		local n=count or 12
		for i=1,n do
			local a=i*math.pi*2/n local b=(i+1)*math.pi*2/n
			local p=if plane=="XY" then V(math.cos(a)*radius,math.sin(a)*radius,0) else V(math.cos(a)*radius,0,math.sin(a)*radius)
			local q=if plane=="XY" then V(math.cos(b)*radius,math.sin(b)*radius,0) else V(math.cos(b)*radius,0,math.sin(b)*radius)
			beam(parent,name,centre+p,centre+q,.24,.24,color)
		end
	end
	local function gear(parent,x,y,z,radius)
		cylinder(parent,"Gear hub",x,y,z,.32,radius*1.35,ink,"Z")
		ring(parent,"Gear rim",V(x,y,z),radius,accent,"XY",10)
		for i=1,8 do local a=i*math.pi/4
			box(parent,"Gear tooth",x+math.cos(a)*radius,y+math.sin(a)*radius,z,.5,.5,.42,gold,A(0,0,a))
		end
		cylinder(parent,"Gear axle",x,y,z+.25,.24,.42,steel,"Z")
	end
	local function group(name,axis,stroke,pivot,angle)
		local node=Instance.new("Model") node.Name=name node.Parent=model
		local g={node=node,axis=axis or V(0,-1,0),stroke=stroke or 2.95,pivot=pivot,angle=angle,rest={}}
		table.insert(groups,g) return node
	end
	local function head(parent,x,y,z,w,d)
		box(parent,"Ram",x,y,z,w,.65,d,ink)
		box(parent,"Coloured ram cap",x,y+.36,z,w+.08,.18,d+.1,accent)
		box(parent,"Crushing sole",x,y-.37,z,w-.1,.12,d-.1,steel)
		for xx=-1,1 do box(parent,"Safety stripe",x+xx*w*.26,y,z+d/2+.025,w*.16,.35,.06,gold) end
	end
	local function pillar(x,y,height)
		box(frame,"Navy column",x,y/2+.8,0,1,height,2.8,ink)
		box(frame,"Column face",x,y/2+.8,1.43,.7,height-.3,.12,accent)
		for z=-1,1,2 do cylinder(frame,"Column foot",x,.75,z*1.05,.2,.35,steel,"Y") end
	end
	local function gantry(height,width)
		local h=height or 7.7 local w=width or 6.8
		pillar(-w/2,h,h-1.0) pillar(w/2,h,h-1.0)
		box(frame,"Crossbeam",0,h,0,w+1,1,3.1,ink)
		box(frame,"Coloured crossbeam",0,h,1.6,w+.8,.7,.16,accent)
		for x=-1,1,2 do cylinder(frame,"Shoulder bolt",x*w*.44,h,1.74,.18,.48,gold,"Z") end
	end
	local function piston(parent,x,y,z,height)
		local shaft=cylinder(parent,"Piston shaft",x,y,z,height,.38,steel,"Y")
		shaft:SetAttribute("TelescopingRod",true)
		cylinder(frame,"Piston sleeve",x,7.0,z,1.1,.73,ink,"Y")
	end
	local bed=box(frame,"Bed",0,1.0,0,6.0,.55,5.2,steel)
	local plinth=box(frame,"Plinth",0,.38,0,8,.76,6.8,ink)
	box(frame,"Base face",0,.42,3.45,7.5,.4,.12,accent)
	Style.materialStuds(plinth,Style.Studs.UseWorldMaterials,{Enum.NormalId.Top},2)
	local conventional={Spring=true,Screw=true,Bottle=true,Gearbox=true,Pneumatic=true,DoubleStamp=true,Conveyor=true,Thunder=true,Frost=true,Furnace=true,SteamHammer=true,Laser=true,Plasma=true,Quake=true,Cyclone=true,Starforge=true,Clockwork=true,FactoryHeart=true}
	if conventional[design] then
		gantry(if design=="SteamHammer" then 8.4 else 7.7,if design=="Quake" then 7.2 else 6.8)
	end
	local ram
	if design=="Clamp" then
		-- Open C-frame, with the spine behind the work surface.
		box(frame,"C spine",-3.15,4.45,0,1.4,7.4,3.2,ink)
		box(frame,"C top",-.25,7.7,0,6.8,1.1,3.2,accent)
		box(frame,"C lower jaw",-.25,1.5,0,6.8,.55,3.2,accent)
		ram=group("Ram",nil,2.35) head(ram,.3,4.6,0,4.8,3.9)
		cylinder(ram,"Clamp screw",.3,6.0,0,2.8,.65,steel,"Y")
		box(ram,"Handle",.3,7.3,0,3.1,.3,.3,accent)
	elseif design=="Bench" then
		-- Horizontal vise; the work surface/input remains centred between jaws.
		box(frame,"Fixed vise jaw",-2.5,2.9,0,1,3.1,4.3,accent)
		for z=-1.5,1.5,3 do cylinder(frame,"Vise rail",0,1.65,z,6.8,.35,steel,"X") end
		ram=group("Ram",V(-1,0,0),2.4)
		box(ram,"Moving vise jaw",2.5,2.9,0,1,3.1,4.3,accent)
		cylinder(ram,"Vise screw",3.2,2.6,0,1.4,.5,steel,"X")
		cylinder(ram,"Vise handle",3.7,2.6,0,2.4,.24,gold,"Y")
	elseif design=="Rivet" then
		box(frame,"Offset mast",-2.7,4.3,-.8,1.3,7.6,2.5,ink)
		beam(frame,"Offset arm",V(-2.7,7.4,-.8),V(.3,6.6,0),1.1,1.3,accent)
		cylinder(frame,"Round anvil",.3,1.5,0,.5,3.5,ink,"Y")
		ram=group("Ram",nil,1.8)
		cylinder(ram,"Narrow punch",.3,4.7,0,2.2,.9,steel,"Y")
		cylinder(ram,"Punch collar",.3,5.6,0,.55,1.65,accent,"Y")
	elseif design=="Flywheel" then
		gantry(7.3,5.7)
		gear(frame,-2.65,5.1,2.4,2.05)
		ram=group("Ram",nil,2.65) head(ram,.5,4.4,0,4.3,3.8)
		beam(ram,"Crank linkage",V(.5,4.8,0),V(-.6,6.6,0),.4,.5,steel)
	elseif design=="Boiler" then
		cylinder(frame,"Boiler body",0,6.5,-1.1,3.8,4.4,ink,"Y")
		cylinder(frame,"Copper boiler jacket",0,6.5,-1.1,3.35,4.15,accent,"Y")
		for x=-2.5,2.5,5 do cylinder(frame,"Steam stack",x,6.7,-1.3,3,.75,ink,"Y") end
		cylinder(frame,"Boiler gauge",0,6.9,1.05,.25,1.3,white,"Z")
		box(frame,"Gauge needle",0,7.05,1.22,.15,.65,.12,ink,A(0,0,-.5))
		ram=group("Ram",nil,2.45) head(ram,0,4.2,0,4.8,4.2)
		cylinder(ram,"Bell hammer",0,4.8,0,1.2,3.0,gold,"Y")
	elseif design=="ScrapShark" or design=="DragonJaw" then
		local dragon=design=="DragonJaw"
		box(frame,"Lower jaw",0,1.55,.3,5.8,.65,4.8,accent)
		box(frame,"Rear skull support",0,4,-2.0,4.3,6.5,2,ink)
		ram=group("Ram",nil,nil,V(0,5.8,-2.3),math.rad(24))
		box(ram,"Upper jaw",0,5.15,.3,5.9,1.2,5.2,accent)
		box(ram,"Dark mouth",0,4.65,.3,5.4,.2,4.9,ink)
		for x=-2,2 do
			cylinder(ram,"Eye socket",x,5.8,2.3,.3,1.0,ink,"Z")
			cylinder(ram,"Eye",x,5.8,2.5,.1,.65,if dragon then gold else cyan,"Z")
			for z=-.8,2,1.4 do
				local tooth=box(ram,"Upper tooth",x,4.15,z,.42,.9,.55,white)
				tooth.Shape=Enum.PartType.Block
			end
		end
		if dragon then
			for side=-1,1,2 do
				beam(ram,"Horn",V(side*1.6,5.6,-1.3),V(side*2.6,7.6,-1.9),.55,.6,gold)
				beam(frame,"Wing spar",V(side*1.9,4,-2),V(side*3.7,6.5,-2),.5,.6,accent)
				beam(frame,"Wing web",V(side*2.2,4,-2),V(side*3.4,4.9,-2),.7,.65,accent)
			end
		else
			beam(ram,"Dorsal fin",V(0,5.6,-.4),V(0,7.8,-1.6),1.1,.65,accent)
		end
	elseif design=="JunkyardJaw" then
		box(frame,"Excavator pedestal",-2.5,2.4,-1.5,2.3,3.8,3.3,ink)
		beam(frame,"Boom",V(-2.6,3.7,-1.5),V(-1.7,7.8,-1.5),1.0,1.1,accent)
		beam(frame,"Dipper",V(-1.7,7.8,-1.5),V(1.6,6.5,-1.5),.9,1.0,accent)
		ram=group("Ram",nil,nil,V(1.6,6.5,-1.5),math.rad(26))
		box(ram,"Claw spine",1.2,4.8,-.4,2.4,1.1,4.3,accent)
		for z=-1.8,1.8,1.8 do beam(ram,"Claw tine",V(1,4.4,z),V(-.9,3.5,z),.6,.65,ink) end
	elseif design=="Gravity" or design=="BlackHole" then
		local black=design=="BlackHole"
		if black then
			ring(frame,"Outer event horizon",V(0,4.8,-.6),3.7,gold,"XY",16)
			for side=-1,1,2 do
				beam(frame,"Curved field claw",V(side*3.1,1.3,-1.6),V(side*3.6,4.7,-1.3),.65,.8,ink)
				beam(frame,"Upper field claw",V(side*3.6,4.7,-1.3),V(side*1.8,8,-1.0),.65,.8,accent)
			end
		else gantry(7.9,6.8) end
		ram=group("Ram")
		ball(ram,"Dense sphere",0,4.7,0,3.7,if black then ink else accent)
		box(ram,"Flat crushing shoe",0,2.93,0,3.7,.4,3.7,steel)
		ring(frame,"Gravity cage",V(0,5.0,0),3.1,accent,"XY",14)
		ring(frame,"Horizontal orbit",V(0,5.0,0),2.8,if black then gold else cyan,"XZ",12)
		for x=-1,1,2 do box(frame,"Floating weight",x*3,5,0,.7,.8,.8,steel,A(.2,.5,.3)) end
		groups[#groups].stroke=1.4
	elseif design=="Mecha" then
		box(frame,"Back armour",0,5.3,-2.2,4.8,5,1.1,ink)
		for x=-1,1,2 do
			ball(frame,"Shoulder",x*2.7,6.6,-1.0,1.7,accent)
			beam(frame,"Robot arm",V(x*2.7,6.6,-1),V(x*1.7,5.1,0),1,1.1,steel)
		end
		ram=group("Ram",nil,2.05)
		box(ram,"Robot palm",0,4.5,0,3.8,1.8,3.1,accent)
		for x=-1.35,1.35,.9 do box(ram,"Knuckle",x,4.3,1.8,.72,1.4,1.0,ink) end
		box(ram,"Thumb",2.2,4.4,.5,1.0,1.8,1.3,gold,A(0,0,-.25))
	else
		ram=group("Ram") head(ram,0,4.7,0,5.25,4.3)
		piston(ram,0,5.8,0,1.6)
	end
	-- Recognisable mechanisms added to the appropriate frame/head, not paint-only variants.
	if design=="Spring" then
		for x=-3.4,3.4,6.8 do
			cylinder(frame,"Spring guide",x,4.6,0,5.5,.3,steel,"Y")
			for y=2.2,6.5,.55 do ring(frame,"Spring coil",V(x,y,0),.5,gold,"XZ",6) end
		end
	elseif design=="Screw" then
		for y=5.1,8.1,.4 do cylinder(ram,"Screw thread",0,y,0,.14,.83,gold,"Y") end
		cylinder(ram,"Handwheel",0,8,0,.22,3.1,accent,"Y")
	elseif design=="Bottle" then
		groups[1].stroke=2.85
		for x=-2.2,2.2,1.1 do box(frame,"Bottle guide",x,2.3,-2,.18,2.1,1.2,accent) end
		for x=-2,2 do box(ram,"Flattening rib",x,4.31,0,.16,.25,3.7,gold) end
	elseif design=="Gearbox" then
		gear(frame,-2.4,5.8,2.05,1.25) gear(frame,1.0,6.5,2.05,.85)
		box(frame,"Gearbox cover",0,7.7,0,4,1.2,3.3,accent)
	elseif design=="Pneumatic" then
		for x=-2.6,2.6,5.2 do
			cylinder(frame,"Air tank",x,4.0,-1.8,3.7,1.2,accent,"Y")
			ball(frame,"Tank cap",x,5.85,-1.8,1.2,accent)
			cylinder(frame,"Tank collar",x,3.0,-1.8,.2,1.3,ink,"Y")
		end
	elseif design=="DoubleStamp" then
		ram:Destroy() table.clear(groups)
		for x=-1.45,1.45,2.9 do local moving=group(if x<0 then "Ram_L" else "Ram_R")
			head(moving,x,4.7,0,2.3,4.1) piston(moving,x,5.8,0,1.6)
		end
	elseif design=="Conveyor" then
		groups[1].stroke=2.55
		for z=-3,3,1 do cylinder(frame,"Feed roller",0,1.45,z,5.5,.42,ink,"X") end
		for x=-3,3,6 do box(frame,"Belt guard",x,1.5,0,.35,.6,6.5,accent) end
	elseif design=="Thunder" then
		for side=-1,1,2 do
			for y=3,6,1.4 do box(frame,"Capacitor",side*2.7,y,-1.7,1.2,.7,1.2,gold) end
			beam(frame,"Lightning brace",V(side*3.2,7,1.8),V(side*2.3,5.5,1.8),.28,.3,cyan)
		end
	elseif design=="Frost" then
		for side=-1,1,2 do
			for n=1,3 do box(frame,"Ice shard",side*(2.6+n*.18),3+n*.65,-.8, .65,1.6+n*.35,.8,accent,A(.1,0,side*.2*n)) end
		end
		box(ram,"Crystalline cap",0,5.45,0,3,.9,2.5,white,A(0,.45,0))
	elseif design=="Furnace" then
		groups[1].stroke=2.75
		box(frame,"Furnace back",0,4.2,-2.45,6.4,5.7,.9,ink)
		box(frame,"Orange lining",0,4.2,-1.96,5.4,4.5,.16,accent)
		for x=-2.1,2.1,1.4 do cylinder(frame,"Exhaust",x,8.1,-1.7,1.6,.65,ink,"Y") end
		box(ram,"Hot die",0,4.22,0,4.4,.25,3.7,gold)
	elseif design=="SteamHammer" then
		box(ram,"Pile driver",0,5.6,0,2.8,2.7,2.8,ink)
		for x=-2.6,2.6,5.2 do cylinder(frame,"Steam valve",x,6.8,1.4,.35,1.25,accent,"Z") end
	elseif design=="Laser" then
		for x=-2.6,2.6,5.2 do
			beam(frame,"Triangular strut",V(x,1.5,-1.6),V(0,8.6,-1.6),.6,.7,accent)
			cylinder(frame,"Lens emitter",x,5.7,1.5,.55,.9,cyan,"Y")
		end
		box(ram,"Lens platen",0,5.15,0,3.8,.25,3.0,cyan)
	elseif design=="Plasma" then
		cylinder(frame,"Core housing",0,6.7,-1.0,2.0,3.4,ink,"Y")
		cylinder(frame,"Plasma core",0,6.7,-1,1.5,3.0,cyan,"Y")
		for y=6.1,7.3,.6 do ring(frame,"Core ring",V(0,y,-1),1.85,accent,"XZ",10) end
	elseif design=="Quake" then
		for x=-2.7,2.7,5.4 do box(frame,"Wide stabiliser",x,.65,0,2.9,1.3,6.4,accent) end
		box(ram,"Impact weight",0,5.4,0,4.7,1.2,3.7,ink)
		for x=-1.7,1.7,1.7 do box(ram,"Impact rib",x,5.5,2.0,.3,1.2,.4,gold) end
	elseif design=="Cyclone" then
		for x=-2.55,2.55,5.1 do
			cylinder(frame,"Turbine housing",x,6.3,0,1.8,2.1,ink,"Z")
			for n=1,4 do box(frame,"Turbine blade",x,6.3,1.0,.27,1.55,.18,accent,A(0,0,n*math.pi/4)) end
		end
		for y=2.4,6.8,1.1 do ring(frame,"Spiral cage",V(0,y,-.8),2.3,accent,"XZ",8) end
	elseif design=="Starforge" then
		local centre=V(0,7.4,1.9)
		for i=1,5 do local a=i*math.pi*2/5
			beam(frame,"Star ray",centre,centre+V(math.sin(a)*2.1,math.cos(a)*2.1,0),.65,.6,gold)
		end
		ball(ram,"Forge heart",0,5.5,0,1.6,white)
	elseif design=="Clockwork" then
		cylinder(frame,"Clock bezel",0,6.7,1.9,.42,3.6,gold,"Z")
		cylinder(frame,"Clock face",0,6.7,2.15,.12,3.1,ink,"Z")
		box(frame,"Minute hand",0,7.2,2.25,.14,1.05,.12,white)
		box(frame,"Hour hand",.43,6.7,2.27,.9,.14,.12,white)
		gear(frame,-2.7,5.8,1.9,.8)
		for x=-1.3,1.3,2.6 do box(ram,"Crown prong",x,5.5,0,.45,1.1,2.8,gold) end
	elseif design=="FactoryHeart" then
		ball(frame,"Heart lobe",-.55,7.65,1.9,1.55,accent)
		ball(frame,"Heart lobe",.55,7.65,1.9,1.55,accent)
		box(frame,"Heart point",0,6.95,1.9,1.3,1.3,1.1,accent,A(0,0,math.pi/4))
		for x=-1.8,1.8,3.6 do for z=-1.4,1.4,2.8 do piston(ram,x,5.8,z,1.6) end end
	end
	-- Record a moving assembly per group, fit its full rest pose uniformly and
-- place it with the bay's complete orientation. No welded/unanchored parts.
	local _,size=model:GetBoundingBox()
	local l=C.Layout local fit=math.min(1,l.MachineWidth/size.X,l.MachineHeight/size.Y,l.MachineDepth/size.Z)
	model:ScaleTo(fit) model:PivotTo(origin)
	local top=({Clamp=1.8,Rivet=1.77,Conveyor=1.68,ScrapShark=1.9,DragonJaw=1.9})[design] or 1.28
	local lowest=math.huge
	for _,g in groups do
		g.rods={}
		for _,p in g.node:GetDescendants() do if p:IsA("BasePart") then
			if p:GetAttribute("TelescopingRod") then table.insert(g.rods,{part=p,cf=p.CFrame,size=p.Size})
			else
				table.insert(g.rest,{part=p,cf=p.CFrame})
				for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
					local point=origin:PointToObjectSpace(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2))
					lowest=math.min(lowest,point.Y)
				end end end
			end
		end end
		g.stroke*=fit
		if g.pivot then g.pivot=origin*F(g.pivot*fit) end
	end
	model:SetAttribute("CrusherType",typeId) model:SetAttribute("CatalogDesign",design)
	model:SetAttribute("RigFit",fit)
	return {model=model,frame=frame,catalog=true,origin=origin,groups=groups,
		base=origin*F(0,top*fit,0),clearance=math.max(.2,lowest-top*fit),bedWidth=3.8*fit,strikes=0}
end

-- Kept separate from playback so bounds and endpoint checks can sample the
-- exact transform without waiting on a tween or touching live world models.
function B.target(v,g,entry,amount)
	if g.pivot then
		return g.pivot*A(g.angle*amount,0,0)*g.pivot:Inverse()*entry.cf
	end
	return F(v.origin:VectorToWorldSpace(g.axis)*g.stroke*amount)*entry.cf
end

function B.rodTarget(v,g,entry,amount)
	local travel=g.stroke*amount
	return F(-v.origin.UpVector*travel/2)*entry.cf, V(entry.size.X+travel,entry.size.Y,entry.size.Z)
end

function B.strike(v,event)
	v.strikes+=1 local duration=math.min(.6,event.cycle*.7)
	for i,g in v.groups do
		if #v.groups>1 and not event.completed and i~=((v.strikes-1)%#v.groups+1) then continue end
		for _,entry in g.rest do
			local p=entry.part local rest=entry.cf
			Tween:Create(p,TweenInfo.new(duration*.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=B.target(v,g,entry,1)}):Play()
			task.delay(duration*.48,function()
				if v.model.Parent and p.Parent then Tween:Create(p,TweenInfo.new(duration*.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=rest}):Play() end
			end)
		end
		for _,entry in g.rods do
			local p=entry.part local down,size=B.rodTarget(v,g,entry,1)
			Tween:Create(p,TweenInfo.new(duration*.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=down,Size=size}):Play()
			task.delay(duration*.48,function()
				if v.model.Parent and p.Parent then Tween:Create(p,TweenInfo.new(duration*.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=entry.cf,Size=entry.size}):Play() end
			end)
		end
	end
end

return B
