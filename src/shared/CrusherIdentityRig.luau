--!strict
-- Presentation only. Hand-authored toy silhouettes; no economy or abilities.
-- Returns CatalogCrushers' existing rig contract, including exact rest poses.
local Tags = game:GetService("CollectionService")
local C = require(script.Parent.CrusherConfig)
local R = {}
R.Tag = "CrusherIdentity"
R.Types = {"Titan","Laser","Plasma","Gravity","Quake","Cyclone","Mecha",
	"Quantum","Starforge","DragonJaw","BlackHole","Clockwork","FactoryHeart",
	"Mega","Thunder","Frost","Furnace","ScrapShark","SteamHammer","JunkyardJaw",
	"Cobalt","Gearbox","Flywheel","Pneumatic","DoubleStamp","Boiler","Conveyor",
	"Bumper","Steel","Clamp","Spring","Screw","Rivet","Bottle","Bench"}
local supported = {} for _, id in R.Types do supported[id] = true end
-- Chase crushers without their own model borrow a rig through def.design.
function R.supports(id)
	if supported[id] then return true end
	local def = C.typeById(id)
	return def ~= nil and def.template == nil and def.design ~= nil and supported[def.design] == true
end
local V, F, A = Vector3.new, CFrame.new, CFrame.Angles
local ink = Color3.fromRGB(19,23,42)
local silver = Color3.fromRGB(208,231,247)
local gold = Color3.fromRGB(255,199,50)
local cyan = Color3.fromRGB(77,235,255)
local pink = Color3.fromRGB(255,94,145)
local colors = {Titan=gold,Quantum=cyan,Bumper=Color3.fromRGB(238,79,83),Steel=Color3.fromRGB(62,139,239),
	Cobalt=Color3.fromRGB(72,198,123),Mega=Color3.fromRGB(166,85,236)}

function R.build(origin, id)
	if not R.supports(id) then return nil end
	local def = C.typeById(id)
	local accent = def.accent or colors[id]
	local typeId = id
	id = if supported[id] then id else def.design -- the rig shape to build
	local model = Instance.new("Model") model.Name=def.name model.WorldPivot=F()
	local frame = Instance.new("Model") frame.Name="Frame" frame.Parent=model
	local groups = {}
	local function part(parent,name,pos,size,color,rot,shape)
		local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=F(pos)*(rot or F())
		p.Color=color or accent p.Shape=shape or Enum.PartType.Block
		p.Material=Enum.Material.SmoothPlastic p.Anchored=true
		p.CanCollide=false p.CanTouch=false p.CanQuery=false
		p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent
		return p
	end
	local function box(parent,name,x,y,z,sx,sy,sz,color,rot)
		return part(parent,name,V(x,y,z),V(sx,sy,sz),color,rot)
	end
	local function ball(parent,name,x,y,z,d,color)
		return part(parent,name,V(x,y,z),V(d,d,d),color,nil,Enum.PartType.Ball)
	end
	local function cyl(parent,name,x,y,z,len,d,color,axis)
		return part(parent,name,V(x,y,z),V(len,d,d),color,
			if axis=="Y" then A(0,0,math.pi/2) elseif axis=="Z" then A(0,math.pi/2,0) else F(),Enum.PartType.Cylinder)
	end
	local function beam(parent,name,a,b,w,d,color)
		return part(parent,name,(a+b)/2,V(w,d,(b-a).Magnitude),color,CFrame.lookAt(Vector3.zero,b-a))
	end
	local function glow(p)
		p.Material=Enum.Material.Neon p:SetAttribute("IdentityPulse",true) return p
	end
	local function triangle(parent,name,a,b,c,depth,color)
		-- An isosceles star point, split into two true triangular prisms.
		local middle=(b+c)/2
		for _,base in {b,c} do
			local up=(a-middle).Unit local back=(middle-base).Unit
			local p=Instance.new("WedgePart") p.Name=name
			p.Size=V(depth,(a-middle).Magnitude,(middle-base).Magnitude)
			p.CFrame=CFrame.fromMatrix((base+a)/2,up:Cross(back),up,back)
			p.Color=color p.Material=Enum.Material.SmoothPlastic p.Anchored=true
			p.CanCollide=false p.CanTouch=false p.CanQuery=false
			p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent
		end
	end
	local function ring(parent,name,centre,radius,color,plane,n)
		for i=0,(n or 16)-1 do
			local a=i*math.pi*2/(n or 16) local b=(i+1)*math.pi*2/(n or 16)
			local function point(t)
				return centre+(if plane=="XY" then V(math.cos(t)*radius,math.sin(t)*radius,0) else V(math.cos(t)*radius,0,math.sin(t)*radius))
			end
			beam(parent,name,point(a),point(b),.26,.26,color)
		end
	end
	local function spin(name,centre,axis,rate)
		local node=Instance.new("Model") node.Name=name node.WorldPivot=F(centre) node.Parent=frame
		node:SetAttribute("IdentityAxis",axis) node:SetAttribute("IdentityRate",rate)
		return node
	end
	local function gear(name,x,y,z,radius,rate)
		local node=spin(name,V(x,y,z),V(0,0,1),rate)
		cyl(node,"Navy gear disc",x,y,z,.38,radius*1.65,ink,"Z")
		cyl(node,"Gold gear face",x,y,z+.22,.12,radius*1.35,gold,"Z")
		for i=0,9 do local a=i*math.pi/5
			box(node,"Gear tooth",x+math.cos(a)*radius,y+math.sin(a)*radius,z,.45,.5,.44,gold,A(0,0,a))
		end
		cyl(node,"Axle cap",x,y,z+.35,.16,.43,accent,"Z")
	end
	local function group(name,stroke,pivot,angle)
		local node=Instance.new("Model") node.Name=name node.Parent=model
		table.insert(groups,{node=node,axis=V(0,-1,0),stroke=stroke or 2.7,pivot=pivot,angle=angle,rest={},rods={}})
		return node
	end
	local function shoe(node,y,w,d,offset)
		local x=offset or 0
		box(node,"Navy crushing die",x,y,0,w,.72,d,ink)
		box(node,"Glossy die armour",x,y+.48,0,w+.06,.32,d+.06,accent)
		box(node,"Steel sole",x,y-.4,0,w-.15,.1,d-.15,silver)
		for side=-1,1 do box(node,"Gold safety block",x+side*w*.27,y,d/2+.06,w*.14,.36,.12,gold) end
	end
	local function rod(node,x,z,y,h)
		local p=cyl(node,"Telescoping piston",x,y,z,h,.35,silver,"Y")
		p:SetAttribute("TelescopingRod",true)
		cyl(frame,"Fixed piston collar",x,y+h/2,z,.6,.72,ink,"Y")
	end
	local function supports(top,spread)
		for side=-1,1,2 do
			beam(frame,"Splayed navy buttress",V(side*3.2,.95,-1.45),V(side*spread,top,-1.1),.85,1.05,ink)
			beam(frame,"Painted buttress face",V(side*3.2,1.3,-.88),V(side*spread,top-.2,-.53),.38,.15,accent)
		end
	end
	local function arch(height,width)
		for side=-1,1,2 do
			box(frame,"Navy upright",side*width/2,(height+1)/2,-.6,.8,height-1,1.8,ink)
			box(frame,"Upright paint",side*width/2,(height+1)/2,.34,.43,height-1.35,.12,accent)
			cyl(frame,"Beam bolt",side*width/2,height,.5,.2,.5,gold,"Z")
		end
		box(frame,"Navy top beam",0,height,-.6,width+1,.8,2.2,ink)
		box(frame,"Painted beam face",0,height,.56,width+.6,.48,.12,accent)
	end
	local function gauge(x,y,z,d)
		cyl(frame,"Gauge bezel",x,y,z,.3,d,ink,"Z")
		cyl(frame,"Gauge dial",x,y,z+.19,.1,d*.78,silver,"Z")
		box(frame,"Gauge needle",x+.08,y+.12,z+.27,.1,d*.36,.07,accent,A(0,0,-.6))
	end
	box(frame,"Plinth",0,.38,0,8,.76,6.7,ink)
	box(frame,"Coloured base fascia",0,.42,3.39,7.55,.38,.12,accent)
	box(frame,"Bed",0,1,0,5.6,.55,4.9,silver)
	for side=-1,1,2 do for z=-2.5,2.5,5 do
		cyl(frame,"Base bolt",side*3.25,.81,z,.12,.37,gold,"Y")
	end end
	local ram
	if id=="Mega" then
		-- A heavy industrial cylinder, below the supernatural Epic/Legendary tier.
		arch(8,6.1)
		cyl(frame,"Oversized hydraulic housing",0,6.9,-.5,2.6,2.65,ink,"Y")
		cyl(frame,"Purple pressure jacket",0,7.0,-.5,1.65,2.8,accent,"Y")
		for y=6.3,7.7,1.4 do cyl(frame,"Housing flange",0,y,-.5,.25,3.1,gold,"Y") end
		gauge(0,7.1,1.02,1.0)
		ram=group("Ram",2.65) shoe(ram,4.45,4.8,3.9)
		rod(ram,0,-.5,5.3,1.8)
	elseif id=="Thunder" then
		for side=-1,1,2 do
			cyl(frame,"Tesla pillar",side*2.7,4.6,-.7,6.7,.55,ink,"Y")
			for y=3,6.7,.75 do cyl(frame,"Yellow insulator",side*2.7,y,-.7,.33,1.2,accent,"Y") end
			ball(frame,"Tesla cap",side*2.7,8,-.7,1.25,gold)
			beam(frame,"Navy lightning brace",V(side*1.9,7.2,.2),V(side*1.3,6,.2),.6,.4,ink)
			glow(beam(frame,"Electric blue zig",V(side*1.9,7.2,.45),V(side*1.3,6,.45),.25,.12,cyan))
			glow(beam(frame,"Electric blue zag",V(side*1.3,6,.45),V(side*2.0,4.9,.45),.25,.12,cyan))
		end
		beam(frame,"Conducting top bridge",V(-2.7,7.5,-.7),V(2.7,7.5,-.7),.55,.6,ink)
		ram=group("Ram",2.7) shoe(ram,4.5,4.4,3.8)
		cyl(ram,"Charged hammer cap",0,5.25,0,.7,2.7,gold,"Y") rod(ram,0,-.7,6.1,2.0)
	elseif id=="Frost" then
		supports(7.4,2.4)
		for side=-1,1,2 do for n=1,3 do
			local x=side*(2.5+n*.3) local y=3.4+n*.5 local h=1.2+n*.7
			triangle(frame,"Navy ice spike",V(x,y+h/2,-.5),V(x-.45,y-h/2,-.5),V(x+.45,y-h/2,-.5),.85,ink)
			triangle(frame,"Cyan ice facet",V(x,y+h/2-.15,.0),V(x-.3,y-h/2+.12,.0),V(x+.3,y-h/2+.12,.0),.18,accent)
		end end
		box(frame,"Ice arch cap",0,7.7,-.6,4.1,.9,1.6,accent,A(0,0,.07))
		ram=group("Ram",2.7) shoe(ram,4.5,4.3,3.8)
		box(ram,"Faceted frozen die",0,5.1,0,2.8,.8,2.5,silver,A(0,.5,0)) rod(ram,0,-.6,6.1,1.6)
	elseif id=="Furnace" then
		box(frame,"Furnace back shell",0,4.5,-1.95,5.8,6.3,1.2,ink)
		box(frame,"Orange furnace lining",0,4.5,-1.28,4.9,5.35,.15,accent)
		glow(box(frame,"Hot furnace window",0,5.9,-1.14,2.8,1.2,.12,gold))
		for x=-.9,.9,.6 do box(frame,"Window grate",x,5.9,-.99,.15,1.3,.12,ink) end
		for side=-1,1,2 do
			cyl(frame,"Factory chimney",side*1.9,7.7,-1.7,2.1,.8,ink,"Y")
			cyl(frame,"Chimney rim",side*1.9,8.7,-1.7,.2,1.0,accent,"Y")
			box(frame,"Insulated side cheek",side*2.6,3.4,0,.85,4.2,3.9,accent)
		end
		ram=group("Ram",2.6) shoe(ram,4.4,4.2,3.6)
		glow(box(ram,"Hot stamping sole",0,3.94,0,3.6,.08,3.0,gold))
	elseif id=="ScrapShark" then
		box(frame,"Shark lower jaw",0,1.62,.45,5.5,.66,4.8,accent)
		box(frame,"Tail hinge support",0,3.2,-1.8,3.5,4.8,2.0,ink)
		ram=group("Ram",0,V(0,5.5,-2),math.rad(27))
		box(ram,"Shark head",0,5.35,-.2,5.0,1.5,4.6,accent)
		box(ram,"Shark nose",0,5.02,2.0,4.15,.9,1.3,accent)
		triangle(ram,"Navy dorsal fin",V(0,8,-1.3),V(0,6,-2.6),V(0,6,0),.75,ink)
		triangle(ram,"Blue dorsal fin",V(.44,7.7,-1.3),V(.44,6.2,-2.3),V(.44,6.2,-.3),.16,accent)
		for side=-1,1,2 do
			ball(ram,"Shark eye socket",side*2.35,5.7,1,.8,ink)
			ball(ram,"Shark eye",side*2.45,5.73,1.18,.42,silver)
			for n=0,2 do box(ram,"Shark gill",side*2.55,5.4,-.4-n*.5,.1,.65,.13,ink,A(.15,0,0)) end
			for z=-.2,2.1,1.15 do box(ram,"Upper shark fang",side*1.8,4.18,z,.4,.85,.5,silver) end
		end
	elseif id=="SteamHammer" then
		arch(8.6,5.3)
		for side=-1,1,2 do
			cyl(frame,"Copper steam riser",side*2.5,4.9,-1.4,6.8,.65,gold,"Y")
			cyl(frame,"Stack cap",side*2.5,8.4,-1.4,.3,1.0,ink,"Y")
		end
		gauge(0,7.7,.7,1.7)
		local valve=spin("Turning steam valve",V(-2.5,6.4,.7),V(0,0,1),.38)
		ring(valve,"Valve rim",V(-2.5,6.4,.7),.68,accent,"XY",10)
		box(valve,"Valve spoke",-2.5,6.4,.7,1.1,.18,.2,gold)
		ram=group("Ram",2.6) shoe(ram,4.4,4.0,3.8)
		cyl(ram,"Copper pile driver",0,5.7,0,2.15,2.55,accent,"Y")
		cyl(ram,"Black hammer band",0,5.7,0,.4,2.7,ink,"Y") rod(ram,0,-.3,7.0,1.4)
	elseif id=="JunkyardJaw" then
		box(frame,"Excavator swivel base",-2.4,2.8,-1.3,2.0,4.0,2.9,ink)
		beam(frame,"Yellow excavator boom",V(-2.4,4,-1.3),V(-1.65,8.1,-1.3),.95,1.1,accent)
		beam(frame,"Excavator dipper",V(-1.65,8.1,-1.3),V(1.1,6.8,-1.3),.85,1.0,accent)
		for _,v in {V(-2.4,4,-.7),V(-1.65,8.1,-.7),V(1.1,6.8,-.7)} do cyl(frame,"Black arm pivot",v.X,v.Y,v.Z,.25,.8,ink,"Z") end
		ram=group("Ram",2.2)
		box(ram,"Hydraulic grabber spine",.3,4.5,-.1,4.4,.8,2.6,ink)
		for side=-1,1,2 do
			beam(ram,"Curved claw finger",V(side*1.9,4.5,0),V(side*1.45,3.9,1.9),.7,.8,accent)
			box(ram,"Claw tooth",side*1.4,3.8,2.1,.65,.35,.75,gold)
		end
		rod(ram,1,-1,5.55,2.5)
	elseif id=="Cobalt" or id=="Pneumatic" then
		local air=id=="Pneumatic"
		arch(7.4,5.9)
		for side=-1,1,2 do
			cyl(frame,"Rounded pressure tank",side*2.35,4.4,-1.35,3.7,1.35,accent,"Y")
			ball(frame,"Tank dome",side*2.35,6.25,-1.35,1.35,accent)
			cyl(frame,"Tank strap",side*2.35,4.5,-1.35,.22,1.45,ink,"Y")
		end
		gauge(0,6.6,.75,if air then 1.75 else 1.05)
		if not air then
			box(frame,"Cobalt double pump",0,7.65,-.6,3.4,.65,2.2,accent)
			for x=-1,1,2 do cyl(frame,"Pump cap",x,8,-.6,.3,.85,gold,"Y") end
		end
		ram=group("Ram",2.65) shoe(ram,4.45,4.25,3.7)
		for x=-1,1,2 do rod(ram,x,-.4,5.7,1.5) end
	elseif id=="Gearbox" or id=="Flywheel" then
		local fly=id=="Flywheel"
		arch(7.4,5.8)
		if fly then
			gear("Huge offset flywheel",-2.1,5.7,1.0,1.65,.65)
			box(frame,"Flywheel bearing",-2.1,3.0,.7,1.0,2.1,1.0,ink)
		else
			box(frame,"Gearbox casing",0,6.3,-.8,4.7,2.8,1.6,accent)
			gear("Main exposed drive gear",-1.25,6.15,.5,1.2,.65)
			gear("Counter rotating gear",1.1,6.7,.5,.85,-.9)
		end
		ram=group("Ram",2.6) shoe(ram,4.4,4.2,3.7)
		rod(ram,if fly then 1 else 0,-.7,5.6,1.7)
	elseif id=="DoubleStamp" then
		arch(7.5,6.1)
		for side=-1,1,2 do
			local x=side*1.4 local head=group(if side<0 then "Ram_L" else "Ram_R",2.65)
			shoe(head,4.45,2.2,3.8,x) rod(head,x,-.5,5.8,2)
			cyl(frame,"Twin cylinder housing",x,7,-.5,1.2,1.1,accent,"Y")
		end
	elseif id=="Boiler" then
		for side=-1,1,2 do box(frame,"Boiler leg",side*2.5,3.8,-1.0,.8,5.8,1.4,ink) end
		cyl(frame,"Round boiler shell",0,6.4,-.8,3.1,3.6,ink,"Y")
		cyl(frame,"Copper boiler jacket",0,6.4,-.8,2.7,3.35,accent,"Y")
		ball(frame,"Boiler dome",0,7.8,-.8,2.4,accent)
		gauge(0,6.7,1.0,1.5)
		for side=-1,1,2 do cyl(frame,"Short exhaust",side*2.2,7.3,-.8,2.2,.6,ink,"Y") end
		ram=group("Ram",2.6) shoe(ram,4.4,4.2,3.6)
		cyl(ram,"Bell shaped hammer",0,5.2,0,1.1,2.5,gold,"Y") rod(ram,0,-.8,5.9,1.2)
	elseif id=="Conveyor" then
		arch(7.3,6.2)
		-- Each roller gets its own local axle, so the belt silhouette stays fixed.
		for z=-2.7,2.7,.9 do
			local node=spin("Feed roller axle",V(0,1.5,z),V(1,0,0),.8)
			cyl(node,"Rubber feed roller",0,1.5,z,5.4,.5,ink,"X")
			cyl(node,"Coloured roller end",2.75,1.5,z,.2,.54,accent,"X")
		end
		for side=-1,1,2 do box(frame,"Belt guard",side*2.95,1.5,0,.38,.7,6.4,accent) end
		ram=group("Ram",2.5) shoe(ram,4.7,4.5,3.8) rod(ram,0,-.6,5.9,1.8)
	elseif id=="Bench" then
		-- Low horizontal vise, with the moving jaw sliding along an exposed rail.
		for z=-1.5,1.5,3 do cyl(frame,"Vise guide rail",0,1.4,z,6.8,.28,silver,"X") end
		box(frame,"Fixed vise jaw",-2.45,2.7,0,.8,2.7,3.8,accent)
		box(frame,"Fixed jaw teeth",-1.99,2.7,0,.1,2.35,3.6,ink)
		ram=group("Ram",3.3) groups[#groups].axis=V(-1,0,0)
		box(ram,"Sliding vise jaw",2.45,2.7,0,.8,2.7,3.8,accent)
		box(ram,"Sliding jaw teeth",1.99,2.7,0,.1,2.35,3.6,ink)
		cyl(ram,"Vise threaded shaft",3.1,2.7,0,1.4,.5,silver,"X")
		cyl(ram,"Vise handle",3.8,2.7,0,2.2,.22,gold,"Y")
	elseif id=="Clamp" or id=="Rivet" then
		local rivet=id=="Rivet"
		box(frame,"Open C spine",-2.7,3.9,-.6,1.2,6.2,2.2,ink)
		beam(frame,"Offset pressure arm",V(-2.7,6.6,-.6),V(.2,6.3,-.6),.95,1.4,accent)
		if rivet then
			cyl(frame,"Round rivet anvil",0,1.5,0,.4,3.3,ink,"Y")
			ram=group("Ram",.85)
			cyl(ram,"Narrow steel punch",0,3.65,0,2.1,.8,silver,"Y")
			cyl(ram,"Red punch collar",0,4.7,0,.5,1.6,accent,"Y") rod(ram,0,-.3,5.6,1.3)
		else
			ram=group("Ram",2.2) shoe(ram,4.0,4.4,3.8) rod(ram,0,-.6,5.15,2.3)
			box(frame,"C clamp upper jaw",0,6.3,-.6,4.6,.65,2.8,accent)
		end
	elseif id=="Screw" or id=="Spring" then
		local spring=id=="Spring"
		arch(7.3,5.8)
		ram=group("Ram",2.6) shoe(ram,4.4,4.2,3.7) rod(ram,0,-.6,5.8,1.8)
		if spring then
			for side=-1,1,2 do
				for i=0,19 do
					local a=i*math.pi*.6 local b=(i+1)*math.pi*.6
					beam(frame,"Exposed yellow return spring",V(side*2.6+math.cos(a)*.4,2.1+i*.24,math.sin(a)*.4),V(side*2.6+math.cos(b)*.4,2.1+(i+1)*.24,math.sin(b)*.4),.16,.16,gold)
				end
			end
		else
			for y=5.2,7.6,.3 do cyl(ram,"Exposed screw thread",0,y,-.6,.12,.65,gold,"Y") end
			local wheel=spin("Turning screw handwheel",V(0,7.85,-.6),V(0,1,0),.5)
			ring(wheel,"Screw handwheel rim",V(0,7.85,-.6),1.35,accent,"XZ",12)
			box(wheel,"Handwheel crossbar",0,7.85,-.6,2.4,.2,.2,ink)
		end
	elseif id=="Bottle" then
		arch(6.7,5.9)
		for side=-1,1,2 do
			box(frame,"Bottle chute side",side*2.5,2.2,-1.4,.25,1.7,2.0,accent)
		end
		for x=-1.4,1.4,1.4 do
			cyl(frame,"Bottle guide mould",x,2.0,-1.85,.8,.65,accent,"Y")
			cyl(frame,"Bottle guide neck",x,2.6,-1.85,.5,.3,gold,"Y")
		end
		ram=group("Ram",2.4) shoe(ram,4.2,4.2,3.7) rod(ram,0,-.6,5.3,1.7)
		for x=-1.3,1.3,1.3 do box(ram,"Flattening rib",x,3.75,0,.2,.12,3.2,silver) end
	elseif id=="Bumper" or id=="Steel" then
		local starter=id=="Bumper"
		arch(if starter then 6.3 else 7.0,if starter then 5.2 else 5.8)
		ram=group("Ram",if starter then 2.0 else 2.5)
		shoe(ram,if starter then 3.8 else 4.3,if starter then 3.8 else 4.5,3.5)
		rod(ram,0,-.6,if starter then 4.9 else 5.55,if starter then 1.5 else 1.8)
		if starter then
			cyl(frame,"Rounded red bumper cap",0,6.45,-.6,.65,2.4,accent,"Y")
		else
			box(frame,"Steel pump housing",0,7,-.6,3.2,1.0,2.0,accent)
			gauge(0,7,.5,1.0)
		end
	elseif id=="DragonJaw" then
		-- A horizontal creature silhouette, rather than a press with horns attached.
		box(frame,"Fixed lower jaw",0,1.62,.5,5.45,.66,5.2,accent)
		box(frame,"Rear hinge pedestal",0,3.15,-2.0,3.8,4.8,2.2,ink)
		for side=-1,1,2 do
			beam(frame,"Wing leading edge",V(side*1.5,3,-2.1),V(side*3.7,6.8,-2.2),.6,.75,ink)
			beam(frame,"Wing membrane",V(side*1.8,3.5,-2.1),V(side*3.5,5.7,-2.1),1.1,.3,accent)
			beam(frame,"Wing lower finger",V(side*1.7,3.2,-2.1),V(side*3.7,4.6,-2.1),.42,.5,gold)
		end
		ram=group("Ram",0,V(0,5.6,-2.3),math.rad(19))
		box(ram,"Dragon skull",0,5.7,-.6,4.8,1.7,3.1,accent)
		box(ram,"Long dragon snout",0,5.1,1.7,4.35,1.25,3.3,accent)
		box(ram,"Dark mouth opening",0,4.51,1,4.1,.15,4.15,ink)
		for side=-1,1,2 do
			ball(ram,"Eye socket",side*2.15,6.1,.4,.95,ink)
			glow(ball(ram,"Amber eye",side*2.25,6.15,.65,.52,gold))
			beam(ram,"Swept horn",V(side*1.4,6.25,-1.35),V(side*2.45,8.1,-2.4),.55,.6,gold)
			for z=-.3,2.6,1.45 do
				box(ram,"Upper fang",side*1.65,4.05,z,.42,.8,.55,silver)
				box(frame,"Lower fang",side*1.65,2.3,z,.35,.65,.45,gold)
			end
		end
		for z=-1.5,.5,1 do box(ram,"Crest scale",0,6.8,z,.6,.65,.75,gold,A(.25,0,0)) end
	elseif id=="BlackHole" then
		-- Wide horizontal accretion disc and three field claws; the Epic Gravity
		-- machine instead has a tall vertical circular cage and pale iron weights.
		for _,x in {-3,3} do
			beam(frame,"Outer field claw",V(x,1.0,-1.6),V(x*.85,7.4,-1.6),.8,.95,ink)
			beam(frame,"Hooked claw tip",V(x*.85,7.4,-1.6),V(x*.47,6.7,-1.6),.6,.7,accent)
			glow(ball(frame,"Field claw jewel",x*.85,7.45,-1.6,.6,pink))
		end
		beam(frame,"Rear field claw",V(0,1.1,-2.7),V(0,7.8,-2.7),.75,.85,ink)
		local disc=spin("Black hole accretion disc",V(0,5.4,0),V(0,1,0),-.65)
		ring(disc,"Outer purple event horizon",V(0,5.4,0),3.15,accent,"XZ",20)
		ring(disc,"Inner gold accretion stream",V(0,5.4,0),2.75,gold,"XZ",18)
		for i=0,5 do local a=i*math.pi/3
			box(disc,"Captured luminous shard",math.cos(a)*2.97,5.4,math.sin(a)*2.97,.5,.4,.55,gold,A(0,-a,0))
		end
		ram=group("Ram",1.35)
		ball(ram,"Dark singularity",0,4.65,0,3.65,ink)
		box(ram,"Singularity crushing sole",0,2.94,0,3.65,.36,3.65,silver)
		glow(box(ram,"Void die edge",0,2.72,0,3.4,.08,3.4,accent))
	elseif id=="Gravity" then
		supports(7.6,2.5)
		ring(frame,"Navy field cage",V(0,4.7,-.8),3.45,ink,"XY",18)
		ring(frame,"Luminous inner horizon",V(0,4.7,-.63),3.04,accent,"XY",18)
		local orbit=spin("Gravity weight rotor",V(0,4.7,-.4),V(0,0,1),.45)
		for i=0,5 do local a=i*math.pi/3
			local x,y=math.cos(a)*2.93,4.7+math.sin(a)*2.93
			box(orbit,"Floating gravity weight",x,y,-.35,.55,.7,.5,silver,A(0,0,a))
		end
		ram=group("Ram",1.35)
		ball(ram,"Gravity hammer",0,4.65,0,3.65,accent)
		box(ram,"Gravity crushing sole",0,2.94,0,3.65,.36,3.65,silver)
		ring(ram,"Equatorial band",V(0,4.65,0),1.88,cyan,"XZ",14)
		glow(ball(frame,"Field status core",0,8.03,-.6,.6,cyan))
	elseif id=="Clockwork" then
		supports(7.7,2.35)
		cyl(frame,"Oversized clock bezel",.55,6.65,-.5,.65,4.0,ink,"Z")
		cyl(frame,"Golden clock rim",.55,6.65,-.12,.16,3.65,gold,"Z")
		cyl(frame,"Dark clock dial",.55,6.65,.0,.12,3.2,ink,"Z")
		for i=0,11 do local a=i*math.pi/6
			box(frame,"Clock index",.55+math.sin(a)*1.35,6.65+math.cos(a)*1.35,.1,.14,.3,.08,silver,A(0,0,-a))
		end
		local minute=spin("Minute hand",V(.55,6.65,.22),V(0,0,1),-.7)
		box(minute,"Long clock hand",.55,7.2,.22,.16,1.25,.13,silver)
		local hour=spin("Hour hand",V(.55,6.65,.36),V(0,0,1),-.14)
		box(hour,"Short clock hand",1.0,6.65,.36,1.05,.22,.13,accent)
		gear("Large drive gear",-2.6,5.45,.1,1.0,.55)
		gear("Small drive gear",-1.45,7.7,.1,.68,-.8)
		ram=group("Ram",2.5) shoe(ram,4.3,4.6,3.8)
		for x=-1.4,1.4,1.4 do
			box(ram,"Crowned hammer prong",x,5.15,0,.5,1.25,2.8,gold)
			ball(ram,"Crown jewel",x,5.85,0,.52,accent)
		end
	elseif id=="FactoryHeart" then
		-- Four open corner pistons leave the centre and factory background visible.
		for x=-2.85,2.85,5.7 do for z=-1.8,1.8,3.6 do
			cyl(frame,"Heart pump tower",x,4.2,z,6.2,.8,ink,"Y")
			cyl(frame,"Pump tower collar",x,6.4,z,.55,1.2,gold,"Y")
		end end
		local core=spin("Beating mechanical heart",V(0,7.1,0),V(0,1,0),0)
		core:SetAttribute("IdentityBeat",true)
		ball(core,"Left heart lobe",-.65,7.45,0,1.9,accent)
		ball(core,"Right heart lobe",.65,7.45,0,1.9,accent)
		box(core,"Heart point",0,6.7,0,1.85,1.85,1.3,accent,A(0,0,math.pi/4))
		glow(box(core,"Core window",0,7.0,.85,.55,1.15,.12,pink))
		for side=-1,1,2 do
			beam(frame,"Heart feed pipe",V(side*2.8,6.6,-.4),V(side*1.4,7.2,-.4),.4,.4,gold)
		end
		ram=group("Ram",2.8) shoe(ram,4.6,4.8,4.0)
		for x=-1.8,1.8,3.6 do for z=-1.4,1.4,2.8 do rod(ram,x,z,5.6,1.3) end end
	elseif id=="Starforge" then
		supports(7.5,2.0)
		local star=spin("Five pointed forge crown",V(0,7.25,-.55),V(0,0,1),.16)
		cyl(star,"Navy star centre",0,7.25,-.55,.65,2.0,ink,"Z")
		cyl(star,"Gold star centre",0,7.25,-.16,.2,1.72,gold,"Z")
		for i=0,4 do local a=i*math.pi*2/5
			local function point(t,r,z) return V(math.sin(t)*r,7.25+math.cos(t)*r,z) end
			triangle(star,"Navy star point",point(a,2.25,-.55),point(a-math.pi/5,.94,-.55),point(a+math.pi/5,.94,-.55),.6,ink)
			triangle(star,"Gold star point",point(a,2.04,-.16),point(a-math.pi/5,.80,-.16),point(a+math.pi/5,.80,-.16),.2,gold)
		end
		glow(ball(star,"Star ruby",0,7.25,.1,1.05,pink))
		ram=group("Ram",2.8) shoe(ram,4.6,4.75,4.1)
		cyl(ram,"Golden forge bell",0,5.3,0,1.0,3.1,gold,"Y")
		rod(ram,0,0,6,1.6)
	elseif id=="Quantum" then
		supports(7.2,2.5)
		local gyro=spin("Quantum gyroscope",V(0,6.7,0),V(0,1,0),.55)
		ring(gyro,"Gold gyroscope",V(0,6.7,0),2.05,gold,"XY",16)
		ring(gyro,"Cyan gyroscope",V(0,6.7,0),2.4,cyan,"XZ",16)
		glow(ball(frame,"Quantum nucleus",0,6.7,0,1.7,cyan))
		ram=group("Ram",2.55) shoe(ram,4.3,4.8,3.9)
		for side=-1,1,2 do
			box(ram,"Quantum die fin",side*2.15,5.05,0,.55,.85,3.2,gold)
		end
	elseif id=="Mecha" then
		box(frame,"Armoured robot back",0,4.7,-2.05,4.0,6.5,1.05,ink)
		for side=-1,1,2 do
			ball(frame,"Oversized shoulder",side*2.8,6.4,-1.15,1.8,accent)
			beam(frame,"Chrome bicep",V(side*2.8,6.4,-1.15),V(side*2.0,4.9,.2),.8,.9,silver)
			box(frame,"Shoulder armour",side*2.8,6.7,-1.15,1.6,.75,1.7,accent)
		end
		ram=group("Ram",1.75)
		box(ram,"Robot fist palm",0,4.6,0,3.8,1.85,2.8,accent)
		for x=-1.35,1.35,.9 do
			box(ram,"Navy finger",x,4.1,1.45,.74,1.6,1.3,ink)
			box(ram,"Painted knuckle",x,4.8,1.65,.67,.58,1.0,accent)
		end
		box(ram,"Thumb",2.1,4.5,.1,1.0,1.6,1.4,gold,A(0,0,-.28))
		glow(box(frame,"Robot visor",0,7.15,-1.45,2,.3,.15,cyan))
	elseif id=="Quake" or id=="Titan" then
		local quake=id=="Quake"
		for side=-1,1,2 do
			box(frame,"Wide outrigger",side*2.8,.85,0,2.4,1.3,6.4,accent)
			cyl(frame,"Shock absorber",side*2.8,4.4,-.5,6.3,.75,ink,"Y")
			for y=2.2,6.2,.8 do cyl(frame,"Shock collar",side*2.8,y,-.5,.2,1.1,gold,"Y") end
		end
		box(frame,"Heavy upper bridge",0,7.8,-.5,6.7,1.0,2.1,ink)
		ram=group("Ram",2.8) shoe(ram,4.6,5.1,4.2)
		if quake then
			cyl(ram,"Enormous barrel hammer",0,5.55,0,2.0,3.8,accent,"Y")
			cyl(ram,"Hammer band",0,5.65,0,.55,3.95,ink,"Y")
		else
			box(ram,"Titan weight",0,5.6,0,4.9,1.7,3.8,accent)
			for side=-1,1,2 do box(ram,"Heavy navy cheek",side*2.15,5.6,0,.65,1.85,4.1,ink) end
		end
		rod(ram,0,0,6.8,1.1)
	elseif id=="Cyclone" then
		supports(7.4,2.3)
		cyl(frame,"Navy turbine housing",0,6.2,-1.35,1.1,4.9,ink,"Z")
		ring(frame,"Turbine rim",V(0,6.2,-.7),2.17,accent,"XY",16)
		local fan=spin("Six blade turbine",V(0,6.2,-.6),V(0,0,1),2.0)
		for i=0,5 do local a=i*math.pi/3
			beam(fan,"Turbine blade",V(math.cos(a)*.45,6.2+math.sin(a)*.45,-.6),V(math.cos(a+.32)*1.85,6.2+math.sin(a+.32)*1.85,-.6),.52,.2,silver)
		end
		cyl(fan,"Turbine hub",0,6.2,-.4,.35,.9,gold,"Z")
		ram=group("Ram",2.55) shoe(ram,4.3,4.6,3.7)
		for side=-1,1,2 do rod(ram,side*1.8,-.6,5.6,1.2) end
	elseif id=="Laser" then
		for side=-1,1,2 do
			beam(frame,"Triangular navy pylon",V(side*3.35,1.05,-1.1),V(0,8.3,-1.1),.95,1.0,ink)
			beam(frame,"Triangular coloured inset",V(side*3.1,1.6,-.53),V(0,8.1,-.53),.38,.15,accent)
			cyl(frame,"Side lens housing",side*2.05,5.7,.45,.6,1.2,ink,"Z")
			glow(cyl(frame,"Laser lens",side*2.05,5.7,.81,.12,.8,cyan,"Z"))
		end
		glow(ball(frame,"Focusing crystal",0,7.8,-.35,.85,pink))
		ram=group("Ram",2.7) shoe(ram,4.5,4.6,3.8)
		glow(box(ram,"Laser cutting edge",0,4.02,0,4.0,.08,3.2,pink))
		rod(ram,0,-.8,6.0,2)
	elseif id=="Plasma" then
		for side=-1,1,2 do
			cyl(frame,"Reactor column",side*2.6,4.7,-.6,6.3,1.3,ink,"Y")
			for y=3,6.6,1.2 do
				glow(cyl(frame,"Plasma chamber",side*2.6,y,-.6,.7,1.4,cyan,"Y"))
				cyl(frame,"Reactor band",side*2.6,y+.45,-.6,.2,1.7,accent,"Y")
			end
			ball(frame,"Reactor dome",side*2.6,7.9,-.6,1.65,accent)
		end
		local cage=spin("Plasma induction ring",V(0,6.8,-.6),V(0,1,0),-.7)
		ring(cage,"Induction arc",V(0,6.8,-.6),1.65,accent,"XZ",12)
		glow(ball(frame,"Suspended plasma core",0,6.8,-.6,1.3,cyan))
		ram=group("Ram",2.7) shoe(ram,4.5,4.5,3.8)
	end
	-- Fit the complete silhouette once. All motion is based on immutable fitted
	-- rest frames, and the input clearance excludes telescoping piston shafts.
	local cf,size=model:GetBoundingBox() local l=C.Layout
	local lo=cf.Position-size/2 local hi=cf.Position+size/2
	-- Include the full revolution of each ornament, not just its rest pose.
	-- The two authored rotation axes are Y/Z; corner radii give exact swept
	-- extents for these boxes. This also keeps animated crowns inside the bay.
	for _,node in frame:GetChildren() do if node:IsA("Model") and node:GetAttribute("IdentityAxis") then
		local pivot=node:GetPivot() local axis=node:GetAttribute("IdentityAxis")
		for _,p in node:GetDescendants() do if p:IsA("BasePart") then
			for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
				local v=pivot:PointToObjectSpace(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2))
				local r=if axis.Y==1 then math.sqrt(v.X*v.X+v.Z*v.Z) elseif axis.X==1 then math.sqrt(v.Y*v.Y+v.Z*v.Z) else math.sqrt(v.X*v.X+v.Y*v.Y)
				local extent=if node:GetAttribute("IdentityBeat") then V(math.abs(v.X)+.12,math.abs(v.Y)+.18,math.abs(v.Z))
					elseif axis.Y==1 then V(r,math.abs(v.Y),r) elseif axis.X==1 then V(math.abs(v.X),r,r) else V(r,r,math.abs(v.Z))
				local a=pivot.Position-extent local b=pivot.Position+extent
				lo=V(math.min(lo.X,a.X),math.min(lo.Y,a.Y),math.min(lo.Z,a.Z))
				hi=V(math.max(hi.X,b.X),math.max(hi.Y,b.Y),math.max(hi.Z,b.Z))
			end end end
		end end
	end end
	local fit=math.min(1,l.MachineWidth/(2*math.max(math.abs(lo.X),math.abs(hi.X))),
		l.MachineHeight/hi.Y,l.MachineDepth/(2*math.max(math.abs(lo.Z),math.abs(hi.Z))))
	model:ScaleTo(fit) model:PivotTo(origin)
	local bedTop=(if id=="DragonJaw" or id=="ScrapShark" then 1.95 elseif id=="Rivet" then 1.7 elseif id=="Conveyor" then 1.75 else 1.275)*fit
	local lowest=math.huge
	for _,g in groups do
		for _,p in g.node:GetDescendants() do if p:IsA("BasePart") then
			local entry={part=p,cf=p.CFrame,size=p.Size}
			if p:GetAttribute("TelescopingRod") then table.insert(g.rods,entry)
			else
				table.insert(g.rest,entry)
				for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
					local point=origin:PointToObjectSpace(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2))
					lowest=math.min(lowest,point.Y)
				end end end
			end
		end end
		g.stroke*=fit
		if g.pivot then g.pivot=origin*F(g.pivot*fit) end
	end
	model:SetAttribute("CrusherType",typeId) model:SetAttribute("IdentityVersion",2)
	model:SetAttribute("RigFit",fit)
	-- Plain starter rigs have no idle ornaments; do not let them occupy the
	-- four-machine cosmetic budget while a nearby special has moving parts.
	for _,node in model:GetDescendants() do
		if node:GetAttribute("IdentityPulse") or node:GetAttribute("IdentityBeat")
			or (node:GetAttribute("IdentityRate") and node:GetAttribute("IdentityRate")~=0) then
			Tags:AddTag(model,R.Tag) break
		end
	end
	return {model=model,frame=frame,catalog=true,origin=origin,groups=groups,
		base=origin*F(0,bedTop,0),clearance=if id=="Bench" then 2.4*fit else lowest-bedTop,bedWidth=3.65*fit,strikes=0}
end
return R
