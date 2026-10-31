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
local FRONT=require(RS.Shared.Config).Plots.Front -- plot entrance edge (plot-local z)
local W=require(script.Parent.Kit.CrusherWorkshop)
local Build=require(script.Parent.Kit.Build)
local Assets=require(script.Parent.PlotAssets)
-- Blender props (ServerStorage.PlotAssets, see PlotAssets.luau) per plot level,
-- plot-local x/z and the way the front faces (yaw: 0 = toward the entrance).
-- Ones that replace a code-built prop list it as `replaces`.
local PROPS={
	{level=0,name="ToolCabinet",x=-46,z=79,yaw=math.rad(60),replaces="ToolTrolley"},
	{level=0,name="ScrapBin",x=-40,z=56,yaw=math.rad(90)},
	{level=1,name="AirCompressor",x=71.5,z=30,yaw=math.rad(-90),replaces="Compressor"},
	{level=2,name="MaintenanceBot",x=-86,z=68,yaw=math.rad(-40),replaces="MaintenanceRobot"},
	{level=2,name="PipeManifold",x=73,z=56,yaw=math.rad(-90)},
	{level=3,name="ScrapSorter",x=-41,z=71,yaw=math.rad(90)},
	{level=3,name="FactoryLamp",x=-42,z=FRONT-6,yaw=0},
	{level=3,name="FactoryLamp",x=42,z=FRONT-6,yaw=0},
	{level=4,name="Workbench",x=-106,z=71,yaw=math.rad(90)},
}
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

-- 30 Oct (less busy plot): trims only on the outer columns of each bank
-- (smallest and largest plot-local X per bank model), not on every column.
local function outerColumns(banks,o,names)
	local byBank={}
	for _,p in (banks and banks:GetDescendants() or {}) do
		if p:IsA("BasePart") and names[p.Name] then
			local x=o:PointToObjectSpace(p.Position).X
			local b=byBank[p.Parent] if not b then b={lo=math.huge,hi=-math.huge} byBank[p.Parent]=b end
			b.lo=math.min(b.lo,x) b.hi=math.max(b.hi,x)
		end
	end
	return function(p)
		local b=byBank[p.Parent] if not b then return false end
		local x=o:PointToObjectSpace(p.Position).X
		return math.abs(x-b.lo)<.5 or math.abs(x-b.hi)<.5
	end
end

-- The fuser: navy base, glowing tank, four input rings, two orange arms.
-- The prompt the owner's client listens for (Fusion.client opens the screen):
-- small, at the front where you stand (prompt range counts from this part).
local function fusionPrompt(m,cf,scale)
	local hit=W.part(m,"FusionPromptPart",V3(2,2,1),cf*CFrame.new(0,2.6,5.6*(scale or 1)),Navy)
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
	-- only once it's checked in Studio: set the attribute Ready=true on the template
	if not template or not template:IsA("Model") or template:GetAttribute("Ready")~=true then return nil end
	local m=Instance.new("Model") m.Name="Fuser" m.Parent=parent
	local mesh=template:Clone()
	local S=C.Fusion.MachineScale or 1 -- 28 Oct: bigger fuser
	if S~=1 then mesh:ScaleTo(mesh:GetScale()*S) end
	-- turn its front (the input rings) toward the plot entrance (+Z of cf),
	-- then stand it on the floor centred on cf, by its bounding box, so the
	-- imported pivot's position and turn don't matter
	local function centre()
		local box,size=mesh:GetBoundingBox()
		local bottom=box.Position-Vector3.new(0,size.Y/2,0)
		mesh:PivotTo(mesh:GetPivot()+(cf.Position-bottom))
	end
	mesh:PivotTo(cf) centre()
	local ring=mesh:FindFirstChild("Input1Ring",true)
	if ring and ring:IsA("BasePart") and cf:PointToObjectSpace(ring.Position).Z<0 then
		-- half a turn round its own centre (cf), not round the imported pivot
		mesh:PivotTo(cf*CFrame.Angles(0,math.pi,0)*cf:Inverse()*mesh:GetPivot())
		centre()
	end
	for _,p in mesh:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
	mesh.Parent=m
	local box=W.part(m,"FuserCollision",V3(14.4,7,10)*S,cf*CFrame.new(0,3.5*S,0),Navy,true)
	box.Transparency=1 box.CanQuery=false
	return m,fusionPrompt(m,cf,S)
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
	local front=FRONT local rear=L.BayZ-L.UpperBack-L.BayDepth/2-4
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
	if not Assets.template("AirCompressor") then compressor(s2,o*CFrame.new(71.5,0,30)) end
	-- the tool trolley moves to Factory II only when there's no Blender cabinet (that one is in the starter plot)
	if not Assets.template("ToolCabinet") then trolley(s2,o*CFrame.new(-46,0,77)*CFrame.Angles(0,.5,0)) end

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
	local fuserModel,fuserHit=fuser(wing,o*CFrame.new(-97,0,57)*CFrame.Angles(0,math.pi/2,0)) -- 28 Oct: front (input rings) toward the plot (+X)
	if not Assets.template("MaintenanceBot") then robot(wing,o*CFrame.new(-86,0,68)*CFrame.Angles(0,-.7,0)) end
	for _,c in {{-108,1.3,48,Orange},{-108,1.3,51,Color3.fromRGB(65,151,255)},{-108,3.9,49.5,Orange}} do
		W.part(wing,"FusionCrate",V3(2.6,2.6,2.6),o*CFrame.new(c[1],c[2],c[3]),c[4],true)
	end
	-- low cyan pipes with orange brackets along the inside of the side rims
	local function pipe(x,z0,z1)
		cylinder(s3,"UtilityPipe",z1-z0,.9,o*CFrame.new(x,.75,(z0+z1)/2)*ALONG_Z,Cyan,false)
		for z=z0+2,z1-2,8 do W.part(s3,"PipeBracket",V3(1.3,1.3,.5),o*CFrame.new(x,.65,z),Orange) end
	end
	pipe(half-2.4,-26,FRONT-6) pipe(-half+2.4,76,FRONT-6)
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
	local function byLevelModel(level,name)
		for _,r in records do if r.level==level then return r.model end end
		return stage(level,name)
	end
	for _,x in {-half+4,half-4} do
		local cf=o*CFrame.new(x,0,front-4)
		W.part(s5,"TowerFoot",V3(2.4,1,2.4),cf*CFrame.new(0,.5,0),Navy,true)
		W.part(s5,"TowerPost",V3(1,12,1),cf*CFrame.new(0,7,0),Navy,true)
		local lamp=W.part(s5,"TowerLamp",V3(2.2,1.4,2.2),cf*CFrame.new(0,13.7,0),Color3.fromRGB(255,240,190))
		lamp.Material=Enum.Material.Neon lamp.CastShadow=false
		W.part(s5,"TowerCap",V3(2.8,.6,2.8),cf*CFrame.new(0,14.7,0),Gold)
		local pl=Instance.new("PointLight") pl.Color=Color3.fromRGB(255,225,170) pl.Range=26 pl.Brightness=1.2 pl.Parent=lamp
	end

	-- Rear yard (Factory III on): toy-coloured stripes on the plain back walls
	local s3b=byLevelModel(2,"Stage3Props")
	local stripeColors={Color3.fromRGB(250,60,70),Yellow,Color3.fromRGB(45,200,70)}
	local banks=plot.model:FindFirstChild("WorkshopBanks")
	local backWalls={}
	for _,p in (banks and banks:GetDescendants() or {}) do
		if p:IsA("BasePart") and (p.Name=="BankBackWall" or p.Name=="BankBackWallUpper" or p.Name=="TopBackWall") then table.insert(backWalls,p) end
	end
	for _,wall in backWalls do
		-- the back face is the wall's -Z side (bays face +Z)
		for i,y in {-wall.Size.Y*.25,wall.Size.Y*.25} do
			local band=W.part(s3b,"BackStripe",V3(wall.Size.X-.6,1.1,.2),wall.CFrame*CFrame.new(0,y,-wall.Size.Z/2-.1),stripeColors[(i+#wall.Name)%#stripeColors+1])
			band.CastShadow=false
		end
	end

	-- Factory V, the master factory: gold column caps, warm light strips under
	-- every walkway, a gold entrance arch, banners on the rear yard backs and a
	-- tall gold beacon in the rear yard you can see from the front.
	local outerCol=outerColumns(banks,o,{GroundColumn=true,UpperColumn=true,TopColumn=true})
	for _,p in (banks and banks:GetDescendants() or {}) do
		if p:IsA("BasePart") and (p.Name=="GroundColumn" or p.Name=="UpperColumn" or p.Name=="TopColumn") and outerCol(p) then
			local cap=W.part(s5,"GoldCap",V3(1.6,.5,1.6),p.CFrame*CFrame.new(0,p.Size.Y/2-.25,0),Gold) cap.Material=Enum.Material.Metal
			local foot=W.part(s5,"GoldFoot",V3(1.5,.4,1.5),p.CFrame*CFrame.new(0,-p.Size.Y/2+.2,0),Gold) foot.Material=Enum.Material.Metal
		elseif p:IsA("BasePart") and (p.Name=="DeckFascia" or p.Name=="TopFascia") then
			local strip=W.part(s5,"WalkwayLight",V3(p.Size.X-1.5,.22,.22),p.CFrame*CFrame.new(0,-p.Size.Y/2-.12,p.Size.Z/2),Color3.fromRGB(255,225,150))
			strip.Material=Enum.Material.Neon strip.CastShadow=false
		end
	end
	-- entrance arch over the bridge
	local arch=o*CFrame.new(0,0,front+.5)
	for _,x in {-9.5,9.5} do
		W.part(s5,"ArchPillar",V3(2.2,15,2.2),arch*CFrame.new(x,7.5,0),Navy,true)
		for _,y in {3,8,13} do local b=W.part(s5,"ArchBand",V3(2.5,.5,2.5),arch*CFrame.new(x,y,0),Gold) b.Material=Enum.Material.Metal end
		local top=W.part(s5,"ArchFinial",V3(1.4,1.4,1.4),arch*CFrame.new(x,16.2,0),Gold) top.Shape=Enum.PartType.Ball top.Material=Enum.Material.Metal
	end
	W.part(s5,"ArchBeam",V3(22,2,2.2),arch*CFrame.new(0,15.5,0),Gold).Material=Enum.Material.Metal
	-- W.sign draws on the part's Back face (+Z), which here faces the bridge
	local plate=W.part(s5,"ArchSign",V3(15,3.2,.4),arch*CFrame.new(0,18.3,0),Navy)
	W.part(s5,"ArchSignFrame",V3(15.8,4,.3),arch*CFrame.new(0,18.3,-.3),Gold)
	local gui=W.sign(plate)
	local t=W.text(gui,"Label","MASTER FACTORY",UDim2.fromScale(.03,.08),UDim2.fromScale(.94,.84)) t.TextColor3=Gold
	-- banners on the rear yard's upper back walls
	for _,wall in backWalls do
		if wall:FindFirstAncestor("RearUpper1") or wall:FindFirstAncestor("RearUpper2") then
			-- turned round so its Back face (+Z, where W.sign draws) points away from the wall
			local banner=W.part(s5,"RearBanner",V3(24,5,.3),wall.CFrame*CFrame.new(0,0,-wall.Size.Z/2-.35)*CFrame.Angles(0,math.pi,0),Navy)
			W.part(s5,"RearBannerTrim",V3(25,6,.2),wall.CFrame*CFrame.new(0,0,-wall.Size.Z/2-.2),Gold)
			local g=W.sign(banner)
			local l=W.text(g,"Label","CRUSH IT",UDim2.fromScale(.03,.08),UDim2.fromScale(.94,.84)) l.TextColor3=Gold
		end
	end
	-- gold beacon tower at the end of the rear yard road
	local yardBack=L.BayZ+L.RearShift-L.UpperBack-L.BayDepth/2-6
	local tower=o*CFrame.new(0,0,yardBack+4.5)
	W.part(s5,"BeaconBase",V3(5,1.2,5),tower*CFrame.new(0,.6,0),Navy,true)
	W.part(s5,"BeaconMast",V3(1.6,52,1.6),tower*CFrame.new(0,27,0),Navy,true)
	for y=8,48,10 do local b=W.part(s5,"BeaconBand",V3(2,.6,2),tower*CFrame.new(0,y,0),Gold) b.Material=Enum.Material.Metal end
	local head=W.part(s5,"BeaconLight",V3(3.6,3.6,3.6),tower*CFrame.new(0,55,0),Color3.fromRGB(255,215,90))
	head.Shape=Enum.PartType.Ball head.Material=Enum.Material.Neon head.CastShadow=false
	local pl2=Instance.new("PointLight") pl2.Color=Color3.fromRGB(255,215,90) pl2.Range=40 pl2.Brightness=1.5 pl2.Parent=head
	W.part(s5,"BeaconCap",V3(4.4,.6,4.4),tower*CFrame.new(0,57.2,0),Gold).Material=Enum.Material.Metal

	-- Blender props, each in the stage model of its plot level
	local byLevel={} for _,r in records do byLevel[r.level]=byLevel[r.level] or r.model end
	for _,prop in PROPS do
		local parent=byLevel[prop.level] or stage(prop.level,"Stage"..(prop.level+1).."Props")
		byLevel[prop.level]=parent
		-- yaw 0: front toward +Z (entrance); the template's front is its pivot LookVector (-Z)
		Assets.place(prop.name,parent,o*CFrame.new(prop.x,0,prop.z)*CFrame.Angles(0,math.pi+prop.yaw,0))
	end
	for _,r in records do show(r.model,false) end
	show(trim,false)
	-- Side walls: one version per plot level (only the current one shows), taller
	-- and more colourful each upgrade. Left and right of the plot, and of the rear
	-- yard from Factory III. The front stays open; the fusion wing doorway too.
	local walls={}
	local toy={Color3.fromRGB(250,60,70),Yellow,Color3.fromRGB(45,200,70),Style.Colors.Blue,Style.Colors.Purple,Orange}
	local yardBack=L.BayZ+L.RearShift-L.UpperBack-L.BayDepth/2-6
	local looks={
		{h=3,panels={Cobalt,Yellow},post=Navy,cap=Yellow},
		{h=5,panels={Cobalt,Style.Colors.Blue},post=Orange,cap=Orange,stripe=Orange},
		{h=7,panels={Style.Colors.Blue,Color3.fromRGB(40,190,200)},post=Silver,cap=Silver,glow=Cyan},
		{h=9,panels=toy,post=Navy,cap=Gold,glow=Gold,flags=true},
	}
	for level,look in looks do
		local m=Instance.new("Model") m.Name="StageWalls"..(level+1) m.Parent=root
		local seg=8
		local function run(x,z0,z1)
			local n=math.max(1,math.floor((z1-z0)/seg+.5)) local len=(z1-z0)/n
			for i=0,n-1 do
				local z=z0+len*(i+.5)
				local panel=W.part(m,"WallPanel",V3(1,look.h,len-.4),o*CFrame.new(x,look.h/2,z),look.panels[(i+math.floor(z0))%#look.panels+1],true)
				Style.materialStuds(panel,true,{Enum.NormalId.Left,Enum.NormalId.Right},2)
				if look.stripe then W.part(m,"WallStripe",V3(1.15,.6,len-.4),o*CFrame.new(x,look.h*.55,z),look.stripe) end
				if look.flags and i%2==0 then
					W.part(m,"FlagPole",V3(.3,4,.3),o*CFrame.new(x,look.h+2,z),Navy)
					local flag=W.part(m,"Flag",V3(.15,1.6,2.4),o*CFrame.new(x,look.h+3.1,z+1.2),toy[(i//2)%#toy+1])
					flag.CastShadow=false
				end
			end
			for i=0,n do
				local z=z0+len*i
				W.part(m,"WallPost",V3(1.6,look.h+.6,1.6),o*CFrame.new(x,(look.h+.6)/2,z),look.post,true)
				local cap=W.part(m,"WallCap",V3(1.9,.5,1.9),o*CFrame.new(x,look.h+.85,z),look.cap) cap.Material=Enum.Material.Metal
			end
			if look.glow then
				local g=W.part(m,"WallGlow",V3(1.1,.25,z1-z0-1),o*CFrame.new(x,look.h-.35,(z0+z1)/2),look.glow)
				g.Material=Enum.Material.Neon g.CastShadow=false
			end
		end
		local wx=half+.6
		local backZ=if level>=2 then yardBack+1 else rear+1
		run(wx,backZ,front-2)
		if level>=2 then run(-wx,backZ,46) run(-wx,76,front-2) -- doorway to the fusion wing
		else run(-wx,backZ,front-2) end
		show(m,false)
		walls[level]=m
	end
	plot.stages={records=records,trim=trim,trimParts=trimParts,door=door,fuser=fuserModel,fuserPart=fuserHit,walls=walls,level=-1}
end

-- Trim kit (Willem's Blender CornerBrace / SupportBeam / BoardFrame), one
-- colour version per plot level from Factory II: frames round the station
-- boards, posts along both road edges and guards at the foot of the ground
-- columns. Rebuilt on each upgrade; spots with something already there are
-- skipped.
local KIT_SUFFIX={"","_Plot3Orange","_Plot4Silver","_Plot5Gold"}
local BOARDS={PlotUpgradeStation=true,ProductionStation=true,RollingStation=true,CollectStation=true,
	SellStation=true,RollStation=true,GoalsStation=true,TrashStation=true,FloorSign1=true,FloorSign2=true}
local function buildKit(plot,level)
	if plot.stages.kit then plot.stages.kit:Destroy() plot.stages.kit=nil end
	local suffix=KIT_SUFFIX[level] if not suffix then return end
	local o=plot.origin
	local kit=Instance.new("Model") kit.Name="TrimKit" kit.Parent=plot.model
	plot.stages.kit=kit
	-- frames: just in front of each board's face, a little larger than the panel
	for _,p in plot.model:GetDescendants() do
		if p:IsA("BasePart") and p.Name=="Panel" and p.Parent and BOARDS[p.Parent.Name] then
			local casing=p.Parent:FindFirstChild("PanelCasing")
			local w=math.max(p.Size.X,casing and casing.Size.X or 0)+1 local h=math.max(p.Size.Y,casing and casing.Size.Y or 0)+1
			Assets.placeSized("BoardFrame"..suffix,kit,p.CFrame*CFrame.new(0,0,p.Size.Z/2+.3)*CFrame.Angles(0,math.pi,0),Vector3.new(w,h,.7))
		end
	end
	-- road posts, only where nothing solid or planned stands
	local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={plot.model}
	local function clear(cf,size)
		for _,h in workspace:GetPartBoundsInBox(cf,size,params) do
			if not h:IsDescendantOf(kit) and h.Name~="AssetCollision" and (h.Position.Y-o.Position.Y)+h.Size.Y/2>.7 then return false end
		end
		return true
	end
	local L=C.Layout
	for _,x in {-1,1} do
		for z=-90,FRONT-8,C.TrimPostSpacing do -- 30 Oct: every 24 studs (was 12)
			local cf=o*CFrame.new(x*(L.RoadHalf+3.6),0,z)
			if clear(cf*CFrame.new(0,2.2,0),Vector3.new(1.6,3.6,1.6)) then
				local post=Assets.place("SupportBeam"..suffix,kit,cf)
				-- 29 Oct: the black body's top sat exactly level with the trim's top and
				-- flickered (z-fighting) as you walked past; sink it a hair into the trim
				local body=post and post:FindFirstChild("Beam_Body",true)
				if body and body:IsA("BasePart") then
					body.Size-=Vector3.new(0,.08,0) body.CFrame*=CFrame.new(0,-.04,0)
				end
			end
		end
	end
	-- column guards at the plaza side of each visible ground column
	local banks=plot.model:FindFirstChild("WorkshopBanks")
	local outerGround=outerColumns(banks,o,{GroundColumn=true})
	for _,p in (banks and banks:GetDescendants() or {}) do
		if p:IsA("BasePart") and p.Name=="GroundColumn" and not outerGround(p) then continue end
		-- front banks always; the rear ground banks from Factory III (level 2)
		local inRear=p.Parent and p.Parent.Name:match("^RearGround")
		if p:IsA("BasePart") and p.Name=="GroundColumn" and (p.Parent==banks or (inRear and level>=2)) then
			local foot=p.CFrame*CFrame.new(0,-p.Size.Y/2,p.Size.Z/2+.35)
			Assets.place("CornerBrace"..suffix,kit,foot,{solid=false})
		end
	end
end

V.buildKit=buildKit -- Studio tests call it with {model, origin, stages={}}

function V.sync(plot,level)
	local v=plot.stages if not v or v.level==level then return end
	v.level=level
	buildKit(plot,level)
	for _,r in v.records do show(r.model,level>=r.level) end
	for wl,m in v.walls or {} do show(m,wl==level) end
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
	-- 31 Oct: floor colour per plot level (C.FloorColors; levels without one keep the authored colour)
	local want=C.FloorColors[level]
	local floors={}
	for _,p in plot.model:GetDescendants() do
		if p:IsA("BasePart") and ((p.Name=="Top" and p.Parent and p.Parent.Name=="Floor") or p.Name=="YardFloor" or p.Name=="FusionFloor") then
			if p:GetAttribute("FloorColor")==nil then p:SetAttribute("FloorColor",p.Color) end
			p.Color=want or p:GetAttribute("FloorColor")
			table.insert(floors,p)
		end
	end
	-- Lighter blocky patches over the floor (like the reference's two-tone
	-- grass), so the floor still has depth from a distance where the studs fade.
	-- Cells of C.FloorPatchCell studs picked by smooth noise; runs merged per row.
	local old=plot.model:FindFirstChild("FloorPatches") if old then old:Destroy() end
	local patch=C.FloorPatchColors[level]
	if patch then
		local folder=Instance.new("Model") folder.Name="FloorPatches"
		local CELL=C.FloorPatchCell local o=plot.origin
		for _,top in floors do
			local cf,size=top.CFrame,top.Size
			local nx,nz=math.floor(size.X/CELL),math.floor(size.Z/CELL)
			for iz=0,nz-1 do
				local runStart=nil
				for ix=0,nx do
					local on=false
					if ix<nx then
						local l=o:PointToObjectSpace(cf*Vector3.new(-size.X/2+(ix+.5)*CELL,0,-size.Z/2+(iz+.5)*CELL))
						on=math.abs(l.X)>C.Layout.RoadHalf+3 and math.noise(l.X/38,l.Z/38,7.3)>.08
					end
					if on and not runStart then runStart=ix
					elseif not on and runStart then
						local x0,x1=-size.X/2+runStart*CELL,-size.X/2+ix*CELL
						local p=Instance.new("Part") p.Name="FloorPatch" p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
						p.Size=Vector3.new(x1-x0,.12,CELL) p.CFrame=cf*CFrame.new((x0+x1)/2,size.Y/2+.06,-size.Z/2+(iz+.5)*CELL)
						p.Color=patch p.Material=top.Material p.MaterialVariant=top.MaterialVariant p.Parent=folder
						runStart=nil
					end
				end
			end
		end
		folder.Parent=plot.model
	end
end
return V
