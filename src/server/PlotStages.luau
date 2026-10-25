--!strict
-- Plot stage look: the fusion wing with the fuser (Factory III) and the props
-- and trim that make each plot upgrade feel like an upgrade. Built once per
-- plot, hidden, then shown by plot level in V.sync. Coordinates are plot-local
-- (+Z toward the entrance, -X is left when you face the plot from its entrance).
local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local C=require(RS.Shared.CrusherConfig)
local Style=require(RS.Shared.Kit.Style)
local World=require(RS.Shared.Config).World
local W=require(script.Parent.Kit.CrusherWorkshop)
local Build=require(script.Parent.Kit.Build)
local V={}
local V3=Vector3.new
local Navy,Blue,Yellow=W.Navy,W.Blue,W.Yellow
local Orange=Color3.fromRGB(255,140,40)
local Cyan=Color3.fromRGB(70,225,255)
local Silver=Color3.fromRGB(205,215,228)
local Gold=Style.Colors.Gold
local Cobalt=Style.Colors.Cobalt
-- trim colour per plot level (level 0 shows no trim)
V.TrimColors={Yellow,Orange,Silver,Gold}

-- Remember each part's look, then show or hide the whole model.
local function show(model,visible)
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") then
			if p:GetAttribute("StageT")==nil then p:SetAttribute("StageT",p.Transparency) p:SetAttribute("StageC",p.CanCollide) p:SetAttribute("StageQ",p.CanQuery) p:SetAttribute("StageS",p.CastShadow) end
			p.Transparency=if visible then p:GetAttribute("StageT") else 1
			p.CanCollide=visible and p:GetAttribute("StageC") p.CanQuery=visible and p:GetAttribute("StageQ")
			p.CastShadow=visible and p:GetAttribute("StageS")
		elseif p:IsA("SurfaceGui") then p.Enabled=visible
		elseif p:IsA("Light") then p.Enabled=visible
		elseif p:IsA("ProximityPrompt") then p.Enabled=visible end
	end
end
V.show=show

local function cylinder(parent,name,length,diameter,cf,color,solid)
	-- Roblox cylinders run along X; cf's X axis is the cylinder's axis
	local p=W.part(parent,name,V3(length,diameter,diameter),cf,color,solid)
	p.Shape=Enum.PartType.Cylinder
	return p
end
local UP=CFrame.Angles(0,0,math.pi/2) -- turns a cylinder upright
local ALONG_Z=CFrame.Angles(0,math.pi/2,0) -- turns a cylinder to run along Z

-- The fuser: navy base, glowing tank, four input rings, two orange arms.
-- The prompt the owner's client listens for (Fusion.client opens the screen):
-- small, at the front where you stand (prompt range counts from this part).
local function fusionPrompt(m,cf)
	local hit=W.part(m,"FusionPromptPart",V3(2,2,1),cf*CFrame.new(0,2.6,5.6),Navy)
	hit.Transparency=1 hit.CanQuery=false
	local prompt=Instance.new("ProximityPrompt") prompt.Name="FusionPrompt" prompt.ActionText="Fuse crushers"
	prompt.ObjectText="Fusion Machine" prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.HoldDuration=0
	prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=hit
	return hit
end
-- Willem's Blender fuser (place-only template, saved with the place, not in
-- Git): ServerStorage.FusionMeshes.FusionMachine, 14.4 x 8 x 10 studs, front
-- = the input rings; turned and placed by those and its bounding box. Decorative meshes do not
-- collide; one invisible box keeps players out of it.
local function fuserModel(parent,cf)
	local folder=ServerStorage:FindFirstChild("FusionMeshes")
	local template=folder and folder:FindFirstChild("FusionMachine")
	if not template or not template:IsA("Model") then return nil end
	local m=Instance.new("Model") m.Name="Fuser" m.Parent=parent
	local mesh=template:Clone()
	-- turn its front (the input rings) toward the plot entrance (+Z of cf),
	-- then stand it on the floor centred on cf, by its bounding box, so the
	-- imported pivot's position and turn don't matter
	mesh:PivotTo(cf)
	local ring=mesh:FindFirstChild("Input1Ring",true)
	if ring and ring:IsA("BasePart") and cf:PointToObjectSpace(ring.Position).Z<0 then
		mesh:PivotTo(cf*CFrame.Angles(0,math.pi,0))
	end
	local box,size=mesh:GetBoundingBox()
	local bottom=box.Position-Vector3.new(0,size.Y/2,0)
	mesh:PivotTo(mesh:GetPivot()+(cf.Position-bottom))
	for _,p in mesh:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
	mesh.Parent=m
	local box=W.part(m,"FuserCollision",V3(14.4,7,10),cf*CFrame.new(0,3.5,0),Navy,true)
	box.Transparency=1 box.CanQuery=false
	return m,fusionPrompt(m,cf)
end
-- Code-built fuser, used when the Blender template is missing.
local function fuser(parent,cf)
	local built,hit=fuserModel(parent,cf)
	if built then return built,hit end
	local m=Instance.new("Model") m.Name="Fuser" m.Parent=parent
	W.part(m,"FuserBase",V3(15,1.6,10),cf*CFrame.new(0,.8,0),Navy,true)
	W.part(m,"FuserDeck",V3(13.6,.3,8.6),cf*CFrame.new(0,1.75,0),Color3.fromRGB(46,70,120),true)
	W.part(m,"FuserBack",V3(13,5.5,1.6),cf*CFrame.new(0,4.6,-4),Navy,true)
	W.part(m,"FuserBackStripe",V3(13,.4,1.7),cf*CFrame.new(0,7.1,-4),Orange)
	-- glowing tank in a glass shell
	local tank=cf*CFrame.new(0,1.9,-1)
	cylinder(m,"TankFoot",.8,5.4,tank*CFrame.new(0,.4,0)*UP,Navy,true)
	local core=cylinder(m,"TankCore",5.6,3.4,tank*CFrame.new(0,3.6,0)*UP,Color3.fromRGB(90,255,120))
	core.Material=Enum.Material.Neon core.CastShadow=false
	local glass=cylinder(m,"TankGlass",5.8,4.6,tank*CFrame.new(0,3.7,0)*UP,Color3.fromRGB(200,255,220))
	glass.Material=Enum.Material.Glass glass.Transparency=.55
	cylinder(m,"TankCap",1,5.4,tank*CFrame.new(0,7.1,0)*UP,Navy,true)
	cylinder(m,"TankLight",.5,2.2,tank*CFrame.new(0,7.8,0)*UP,Orange)
	local light=Instance.new("PointLight") light.Color=Color3.fromRGB(90,255,120) light.Range=14 light.Brightness=1.4 light.Parent=core
	-- four input rings in front: three copies plus the main crusher
	local ringColors={Color3.fromRGB(250,60,70),Color3.fromRGB(65,151,255),Color3.fromRGB(45,230,45),Color3.fromRGB(170,90,255)}
	for i,color in ringColors do
		local x=(i-2.5)*3.1
		local at=cf*CFrame.new(x,1.9,3)
		cylinder(m,"InputRing",.5,2.6,at*CFrame.new(0,.25,0)*UP,color,true)
		local glow=cylinder(m,"InputGlow",.12,1.7,at*CFrame.new(0,.52,0)*UP,color:Lerp(Color3.new(1,1,1),.45))
		glow.Material=Enum.Material.Neon glow.CastShadow=false
	end
	-- orange robot arms on both sides, leaning over the tank
	for _,side in {-1,1} do
		local base=cf*CFrame.new(side*6.2,1.6,-.5)
		cylinder(m,"ArmBase",1,2.4,base*CFrame.new(0,.5,0)*UP,Navy,true)
		W.part(m,"ArmLower",V3(1.1,4.2,1.1),base*CFrame.new(0,3,0)*CFrame.Angles(0,0,side*.25),Orange,true)
		cylinder(m,"ArmJoint",1.4,1.4,base*CFrame.new(-side*.55,5.1,0)*ALONG_Z,Navy)
		W.part(m,"ArmUpper",V3(3.6,1,1),base*CFrame.new(-side*2.2,5.9,0)*CFrame.Angles(0,0,-side*.35),Orange,true)
		W.part(m,"ArmClaw",V3(.5,1.4,1.4),base*CFrame.new(-side*3.9,5.4,0),Navy)
	end
	-- front name plate
	local plate=W.part(m,"FuserSign",V3(8,1.5,.3),cf*CFrame.new(0,1.1,5.1)*CFrame.Angles(math.rad(-15),0,0),Navy)
	W.text(W.sign(plate),"Label","FUSION",UDim2.fromScale(.03,.05),UDim2.fromScale(.94,.9))
	return m,fusionPrompt(m,cf)
end

-- Small maintenance robot: tracks, orange body, cyan eyes.
local function robot(parent,cf)
	local m=Instance.new("Model") m.Name="MaintenanceRobot" m.Parent=parent
	for _,x in {-.8,.8} do W.part(m,"RobotTrack",V3(.6,.7,2),cf*CFrame.new(x,.35,0),Navy,true) end
	W.part(m,"RobotBody",V3(1.8,1.6,1.4),cf*CFrame.new(0,1.5,0),Orange,true)
	W.part(m,"RobotHead",V3(1.4,1,1.2),cf*CFrame.new(0,2.8,0),Navy,true)
	for _,x in {-.35,.35} do
		local eye=W.part(m,"RobotEye",V3(.3,.3,.1),cf*CFrame.new(x,2.85,.62),Cyan) eye.Material=Enum.Material.Neon
	end
	W.part(m,"RobotAntenna",V3(.15,.8,.15),cf*CFrame.new(0,3.7,0),Silver)
	local tip=W.part(m,"RobotAntennaTip",V3(.35,.35,.35),cf*CFrame.new(0,4.15,0),Orange) tip.Shape=Enum.PartType.Ball
	return m
end

-- Air compressor on a skid with a gauge.
local function compressor(parent,cf)
	local m=Instance.new("Model") m.Name="Compressor" m.Parent=parent
	W.part(m,"Skid",V3(4,.5,6.4),cf*CFrame.new(0,.25,0),Navy,true)
	cylinder(m,"Tank",5.2,3,cf*CFrame.new(0,2.1,0)*ALONG_Z,Color3.fromRGB(235,70,60),true)
	for _,z in {-2.7,2.7} do cylinder(m,"TankEnd",.4,3.2,cf*CFrame.new(0,2.1,z)*ALONG_Z,Navy) end
	W.part(m,"Motor",V3(2,1.4,1.6),cf*CFrame.new(0,4.1,-1),Navy,true)
	cylinder(m,"Gauge",.25,1.1,cf*CFrame.new(-1.6,2.6,1.2),Color3.fromRGB(245,245,240))
	cylinder(m,"GaugeRim",.2,1.3,cf*CFrame.new(-1.5,2.6,1.2),Navy)
	return m
end

-- Rolling tool trolley.
local function trolley(parent,cf)
	local m=Instance.new("Model") m.Name="ToolTrolley" m.Parent=parent
	W.part(m,"TrolleyBody",V3(3,2.4,2),cf*CFrame.new(0,1.6,0),Color3.fromRGB(230,48,58),true)
	for i=0,2 do W.part(m,"TrolleyDrawer",V3(2.6,.5,.1),cf*CFrame.new(0,.9+i*.7,1.02),Color3.fromRGB(180,30,40)) end
	W.part(m,"TrolleyTop",V3(3.2,.25,2.2),cf*CFrame.new(0,2.9,0),Navy)
	W.part(m,"TrolleyHandle",V3(3,.2,.2),cf*CFrame.new(0,3.5,-1.1),Silver)
	for _,x in {-1.2,1.2} do for _,z in {-.7,.7} do cylinder(m,"Wheel",.3,.6,cf*CFrame.new(x,.3,z)*CFrame.Angles(0,math.pi/2,0),Navy) end end
	W.part(m,"Wrench",V3(1.6,.15,.35),cf*CFrame.new(.4,3.1,.3)*CFrame.Angles(0,.4,0),Silver)
	return m
end

function V.create(plot)
	local o=plot.origin
	local root=Instance.new("Model") root.Name="PlotStages" root.Parent=plot.model
	local L=C.Layout
	local F=156 local half=F/2
	local front=92 local rear=L.BayZ-L.UpperBack-L.BayDepth/2-4
	local platform=Style.theme("Island").platform
	local records={}
	local function stage(level,name)
		local m=Instance.new("Model") m.Name=name m.Parent=root
		table.insert(records,{model=m,level=level})
		return m
	end

	-- Trim (every stage, recoloured per level): bolt studs on the front and
	-- side rims and collars on the rim lamps.
	local trim=Instance.new("Model") trim.Name="StageTrim" trim.Parent=root
	local trimParts={}
	local function bolt(x,z)
		local b=W.part(trim,"RimBolt",V3(.8,.8,.8),o*CFrame.new(x,1.75,z),Yellow) b.Shape=Enum.PartType.Ball
		table.insert(trimParts,b)
	end
	for x=-half+4,half-4,8 do if math.abs(x)>9 then bolt(x,front-1) end end
	for z=rear+5,front-5,8 do for _,x in {-half+1,half-1} do
		if not (x<0 and z>47 and z<75) then bolt(x,z) end -- left gap is the fusion wing's doorway
	end end
	for _,p in plot.model:GetDescendants() do
		if p:IsA("BasePart") and p.Name=="LampPost" and p.Parent and p.Parent.Name=="PlotBorder" then
			local at=o:PointToObjectSpace(p.Position)
			local collar=W.part(trim,"LampCollar",V3(1.6,.6,1.6),o*CFrame.new(at.X,at.Y-p.Size.Y/2+.3,at.Z),Yellow)
			collar:SetAttribute("LeftDoor",at.X<0 and at.Z>47 and at.Z<75)
			table.insert(trimParts,collar)
		end
	end

	-- Factory II: cobalt edging along the road, compressor beside the right
	-- stairs, tool trolley between the scrap hopper and the sell counter.
	local s2=stage(1,"Stage2Props")
	for _,x in {-1,1} do
		local edge=W.part(s2,"CobaltRoadEdge",V3(1.4,.12,front-rear-6),o*CFrame.new(x*(L.RoadHalf+1.1),.06,(front+rear)/2-1),Cobalt)
		edge.CastShadow=false
	end
	compressor(s2,o*CFrame.new(71.5,0,30))
	trolley(s2,o*CFrame.new(-46,0,77)*CFrame.Angles(0,.5,0))

	-- Factory III: the fusion wing (outward left of the scrap hopper) with the
	-- fuser, a maintenance robot, orange crates and low utility pipes.
	local s3=stage(2,"Stage3Props")
	local wing=Instance.new("Model") wing.Name="FusionWing" wing.Parent=s3
	local wx0,wx1,wz0,wz1=-half+.5,-half-34,44,78
	local wcx,wcz,ww,wd=(wx0+wx1)/2,(wz0+wz1)/2,math.abs(wx0-wx1),wz1-wz0
	Build.island(wing,o*CFrame.new(wcx,0,wcz),ww,wd,World.SeaY,
		{dirt=Color3.fromRGB(25,43,73),stone=Color3.fromRGB(46,84,156),stoneDark=Color3.fromRGB(25,43,73)},{rng=Random.new(31),curb=false,rocks=false})
	local wf=W.part(wing,"FusionFloor",V3(ww,2,wd),o*CFrame.new(wcx,-1,wcz),platform,true)
	Style.studs(wf)
	local light=Color3.fromRGB(78,140,232)
	local function rim(a,b,fixed,alongX)
		local len=b-a local n=math.max(1,math.floor(len/6+.5)) local seg=len/n
		for i=0,n-1 do
			local mid=a+seg*(i+.5)
			local pos=if alongX then CFrame.new(mid,.8,fixed) else CFrame.new(fixed,.8,mid)
			local block=W.part(wing,"RimBlock",if alongX then V3(seg-.2,1.6,2) else V3(2,1.6,seg-.2),o*pos,if i%2==0 then Blue else Orange,true)
			Style.materialStuds(block,true,{Enum.NormalId.Top},2)
		end
	end
	rim(wx1+2,wx0,wz0+1,true) rim(wx1+2,wx0,wz1-1,true) rim(wz0+2,wz1-2,wx1+1,false)
	for _,z in {wz0+1,wz1-1} do
		W.part(wing,"RimCorner",V3(2.6,2.2,2.6),o*CFrame.new(wx1+1,1.1,z),Navy,true)
		W.lamp(wing,o*CFrame.new(wx1+1,2.2,z),2.2)
	end
	local fuserModel,fuserHit=fuser(wing,o*CFrame.new(-97,0,57))
	robot(wing,o*CFrame.new(-86,0,68)*CFrame.Angles(0,-.7,0))
	for _,c in {{-108,1.3,48,Orange},{-108,1.3,51,Color3.fromRGB(65,151,255)},{-108,3.9,49.5,Orange}} do
		W.part(wing,"FusionCrate",V3(2.6,2.6,2.6),o*CFrame.new(c[1],c[2],c[3]),c[4],true)
	end
	-- low cyan pipes with orange brackets along the inside of the side rims
	local function pipe(x,z0,z1)
		cylinder(s3,"UtilityPipe",z1-z0,.9,o*CFrame.new(x,.75,(z0+z1)/2)*ALONG_Z,Cyan,false)
		for z=z0+2,z1-2,8 do W.part(s3,"PipeBracket",V3(1.3,1.3,.5),o*CFrame.new(x,.65,z),Orange) end
	end
	pipe(half-2.4,-26,86) pipe(-half+2.4,76,86)
	-- the left rim opens into the fusion wing
	local door={}
	for _,p in plot.model:GetDescendants() do
		if p:IsA("BasePart") and p.Parent and p.Parent.Name=="PlotBorder" then
			local at=o:PointToObjectSpace(p.Position)
			if at.X<-half+3 and at.Z>47 and at.Z<75 then table.insert(door,p) end
		end
	end

	-- Factory IV: cyan floor channels beside the cobalt road edging and gauges on the pipes.
	local s4=stage(3,"Stage4Props")
	for _,x in {-1,1} do
		local ch=W.part(s4,"CyanChannel",V3(.5,.13,front-rear-10),o*CFrame.new(x*(L.RoadHalf+2.3),.07,(front+rear)/2-1),Cyan)
		ch.Material=Enum.Material.Neon ch.CastShadow=false
	end
	for _,z in {-10,20,50,80} do
		local x=half-2.4
		cylinder(s4,"PipeGauge",.25,1.3,o*CFrame.new(x-.6,1.9,z),Color3.fromRGB(245,245,240))
		cylinder(s4,"PipeGaugeRim",.2,1.5,o*CFrame.new(x-.5,1.9,z),Silver)
		W.part(s4,"PipeGaugeStem",V3(.3,1,.3),o*CFrame.new(x,1.2,z),Silver)
	end

	-- Factory V: light towers at the front corners with gold caps.
	local s5=stage(4,"Stage5Props")
	for _,x in {-half+4,half-4} do
		local cf=o*CFrame.new(x,0,front-4)
		W.part(s5,"TowerFoot",V3(2.4,1,2.4),cf*CFrame.new(0,.5,0),Navy,true)
		W.part(s5,"TowerPost",V3(1,12,1),cf*CFrame.new(0,7,0),Navy,true)
		local lamp=W.part(s5,"TowerLamp",V3(2.2,1.4,2.2),cf*CFrame.new(0,13.7,0),Color3.fromRGB(255,240,190))
		lamp.Material=Enum.Material.Neon lamp.CastShadow=false
		W.part(s5,"TowerCap",V3(2.8,.6,2.8),cf*CFrame.new(0,14.7,0),Gold)
		local pl=Instance.new("PointLight") pl.Color=Color3.fromRGB(255,225,170) pl.Range=26 pl.Brightness=1.2 pl.Parent=lamp
	end

	for _,r in records do show(r.model,false) end
	show(trim,false)
	plot.stages={records=records,trim=trim,trimParts=trimParts,door=door,fuser=fuserModel,fuserPart=fuserHit,level=-1}
end

function V.sync(plot,level)
	local v=plot.stages if not v or v.level==level then return end
	v.level=level
	for _,r in v.records do show(r.model,level>=r.level) end
	show(v.trim,level>=1)
	local color=V.TrimColors[math.clamp(level,1,#V.TrimColors)]
	for _,p in v.trimParts do p.Color=color end
	-- the fusion wing doorway: hide the left rim (and its lamp) in the gap
	local open=level>=C.Fusion.PlotLevel
	for _,p in v.door do
		if p:GetAttribute("DoorT")==nil then p:SetAttribute("DoorT",p.Transparency) p:SetAttribute("DoorC",p.CanCollide) p:SetAttribute("DoorQ",p.CanQuery) end
		p.Transparency=if open then 1 else p:GetAttribute("DoorT") p.CanCollide=not open and p:GetAttribute("DoorC") p.CanQuery=not open and p:GetAttribute("DoorQ")
	end
	for _,p in v.trimParts do if p:GetAttribute("LeftDoor") and open then p.Transparency=1 end end
end
return V
