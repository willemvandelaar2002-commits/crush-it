--!strict
-- Reusable physical furniture and world-control templates for crusher plots.
local RS=game:GetService("ReplicatedStorage")
local Style=require(RS.Shared.Kit.Style)
local C=require(RS.Shared.CrusherConfig)
local Icons=require(RS.Shared.Icons)
local UpgradeView=require(RS.Shared.CrusherUpgradeView)
local Build=require(script.Parent.Build)
local W={}
W.Blue=Color3.fromRGB(35,99,210) W.Navy=Color3.fromRGB(25,43,73)
W.Yellow=Style.Colors.Yellow W.Green=Style.Colors.Green
W.Purple=Color3.fromRGB(156,66,221)
local V=Vector3.new
function W.part(parent,name,size,cf,color,solid)
	local p=Build.block(parent,name,size,cf,color,{})
	p.CanCollide=solid==true p.CanTouch=false p.CanQuery=solid==true
	return p
end
function W.text(parent,name,value,pos,size)
	local t=Instance.new("TextLabel") t.Name=name t.Text=value t.Position=pos t.Size=size
	t.BackgroundTransparency=1 t.TextScaled=true t.TextWrapped=true Style.text(t,2) t.Parent=parent return t
end
function W.icon(parent,name,image,pos,size)
	local img=Instance.new("ImageLabel") img.Name=name img.Image=image img.BackgroundTransparency=1
	img.Position=pos img.Size=size img.ScaleType=Enum.ScaleType.Fit img.Parent=parent return img
end
function W.button(parent,name,value,pos,size,action,id,bay)
	local b=Instance.new("TextButton") b.Name=name b.Text=value b.Position=pos b.Size=size
	b.TextScaled=true b.TextWrapped=true b:SetAttribute("Action",action)
	if id then b:SetAttribute("UpgradeId",id) end if bay then b:SetAttribute("Bay",bay) end
	Style.button(b,W.Green) b.TextTransparency=1 b.Parent=parent
	-- the visible text is the Caption below; hide the button's own text outline
	-- (it still draws behind the caption as a dark second copy)
	local outline=b:FindFirstChild("TextOutline") if outline then outline.Enabled=false end
	-- A separate caption keeps the glossy green gradient off the white lettering.
	local caption=W.text(b,"Caption",value,UDim2.fromScale(.02,.04),UDim2.fromScale(.96,.92))
	b:GetPropertyChangedSignal("Text"):Connect(function() caption.Text=b.Text end)
	return b
end
function W.surface(part)
	-- SurfaceGui mouse hit testing needs a queryable adornee; it remains non-colliding.
	part.CanQuery=true
	local gui=Instance.new("SurfaceGui") gui.Name="WorkshopControls" gui.Face=Enum.NormalId.Back
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=32
	gui.LightInfluence=.15 gui.MaxDistance=C.ControlsMaxDistance gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("CrusherWorldControls",true) gui.Parent=part return gui
end
function W.beacon(parent,cf)
	W.part(parent,"BeaconFoot",V(1.8,.6,1.8),cf,W.Navy)
	local p=W.part(parent,"WarmBeacon",V(1.3,1.2,1.3),cf*CFrame.new(0,.9,0),W.Yellow)
	p.Material=Enum.Material.Neon p.CastShadow=false
end
-- solid: the casing blocks players (boards and stations); plaques stay walk-through
function W.panel(parent,cf,width,height,color,solid)
	W.part(parent,"PanelCasing",V(width+1.4,height+1.4,1.4),cf,W.Navy,solid==true)
	local face=W.part(parent,"Panel",V(width,height,.6),cf*CFrame.new(0,0,.8),color)
	for _,x in {-1,1} do for _,y in {-1,1} do
		local bolt=W.part(parent,"Bolt",V(.7,.7,.5),cf*CFrame.new(x*(width/2+.1),y*(height/2+.1),1.25),Color3.fromRGB(211,222,235))
		bolt.Shape=Enum.PartType.Ball
	end end
	return face,W.surface(face)
end
W.UpgradeIcons={Damage=Icons.Power,Speed=Icons.Speed,Yield=Icons.Value,Luck=Icons.Lucky,Pedestals=Icons.Rebirth}
W.UpgradeColors={Damage=Style.Colors.Red,Speed=Style.Colors.Yellow,Yield=Style.Colors.Green,
	Luck=Color3.fromRGB(150,62,229),Pedestals=Color3.fromRGB(106,76,224)}
-- Attributes also carry the price state to the owner's PlayerGui SurfaceGui.
function W.purchase(button,view)
	button.Text=view.button
	if button:GetAttribute("PurchaseState")~=view.state then Style.setButtonColor(button,UpgradeView.Colors[view.state]) end
	button:SetAttribute("PurchaseState",view.state)
	button:SetAttribute("PurchaseCost",view.cost)
	button:SetAttribute("PurchaseHint",view.hint)
	button:SetAttribute("SuccessText",view.success)
end
function W.clearPurchase(button)
	if button:GetAttribute("PurchaseState") then Style.setButtonColor(button,W.Green) end
	for _,key in {"PurchaseState","PurchaseCost","PurchaseHint","SuccessText"} do button:SetAttribute(key,nil) end
end
-- Upgrade board: one colour band per upgrade with icon, name, level step and
-- a green price button (the button is the purchase control).
function W.board(parent,cf,kind)
	local color=if kind=="Production" then W.Blue else W.Purple
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	for _,x in {-7.2,7.2} do
		W.part(m,"Support",V(1.6,8.6,1.6),cf*CFrame.new(x,4.3,0),W.Navy,true)
		W.part(m,"Foot",V(4,1,6),cf*CFrame.new(x,.5,0),W.Blue)
		W.beacon(m,cf*CFrame.new(x,10.1,0))
	end
	local face,gui=W.panel(m,cf*CFrame.new(0,5.4,0),17,8,color,true)
	local copy=UpgradeView.Boards[kind]
	W.text(gui,"Heading",copy.heading,UDim2.fromScale(.04,.025),UDim2.fromScale(.92,.13))
	local scope=Instance.new("Frame") scope.Name="Scope" scope.Position=UDim2.fromScale(.12,.17) scope.Size=UDim2.fromScale(.76,.09)
	Style.panel(scope,Style.darken(color,.5),Style.darken(color,.65)) scope.Parent=gui
	W.text(scope,"ScopeText",copy.scope,UDim2.fromScale(.02,.02),UDim2.fromScale(.96,.96))
	local rows={} local count=if kind=="Production" then 3 else 2 local rowIndex=0
	local top,span=.29,.69
	for _,id in C.UpgradeOrder do if C.Upgrades[id].group==kind then
		rowIndex+=1 local row=Instance.new("Frame") row.Name="Row_"..id
		local h=span/count
		row.Position=UDim2.fromScale(.03,top+(rowIndex-1)*h) row.Size=UDim2.fromScale(.94,h-.03)
		Style.panel(row,W.UpgradeColors[id],Style.darken(W.UpgradeColors[id],.35)) row.Parent=gui
		W.icon(row,"UpgradeIcon",W.UpgradeIcons[id],UDim2.fromScale(.015,.08),UDim2.fromScale(.15,.84))
		local title=W.text(row,"UpgradeName",string.upper(C.Upgrades[id].name),UDim2.fromScale(.18,.06),UDim2.fromScale(.5,.5))
		title.TextXAlignment=Enum.TextXAlignment.Left
		local level=W.text(row,"LevelStep","",UDim2.fromScale(.18,.56),UDim2.fromScale(.5,.38))
		level.TextXAlignment=Enum.TextXAlignment.Left level.TextColor3=Color3.fromRGB(255,240,170)
		local b=W.button(row,"Buy","$0",UDim2.fromScale(.7,.12),UDim2.fromScale(.28,.76),"Upgrade",id)
		rows[id]={label=level,button=b}
	end end
	return {part=face,rows=rows}
end
-- Goals board (reference): three rows - like/favorite, join the group, free
-- time skip - each with its own button. Same posts/panel as the upgrade boards.
function W.goals(parent,cf)
	local color=Color3.fromRGB(255,146,38)
	local m=Instance.new("Model") m.Name="GoalsStation" m.Parent=parent
	for _,x in {-6.6,6.6} do
		W.part(m,"Support",V(1.6,8.6,1.6),cf*CFrame.new(x,4.3,0),W.Navy,true)
		W.part(m,"Foot",V(4,1,6),cf*CFrame.new(x,.5,0),W.Blue)
		W.beacon(m,cf*CFrame.new(x,10.1,0))
	end
	local face,gui=W.panel(m,cf*CFrame.new(0,5.4,0),15.5,8,color,true)
	W.text(gui,"Heading","GOALS",UDim2.fromScale(.04,.02),UDim2.fromScale(.92,.16))
	local rows={}
	local specs={
		{id="Like",icon="★",title="FAVORITE THE GAME",sub="Confirm the Roblox favorite prompt",button="★ FAVORITE",action="Favorite",color=Color3.fromRGB(64,160,255)},
		{id="Group",icon="👥",title="JOIN THE GROUP",sub="Unlocks the free time skip",button="JOIN",action="JoinGroup",color=Color3.fromRGB(150,80,230)},
		{id="Skip",icon="⏱",title="FREE "..C.Goals.SkipMinutes.." MIN TIME SKIP",sub="Complete BOTH goals above",button="FAVORITE",action="TimeSkip",color=Color3.fromRGB(53,190,79)},
	}
	for i,spec in specs do
		local row=Instance.new("Frame") row.Name="Row_"..spec.id
		row.Position=UDim2.fromScale(.03,.2+(i-1)*.265) row.Size=UDim2.fromScale(.94,.24)
		Style.panel(row,spec.color,Style.darken(spec.color,.35)) row.Parent=gui
		W.text(row,"Number",i..".",UDim2.fromScale(.01,.1),UDim2.fromScale(.07,.8))
		W.text(row,"Icon",spec.icon,UDim2.fromScale(.08,.08),UDim2.fromScale(.11,.84))
		local title=W.text(row,"Title",spec.title,UDim2.fromScale(.2,.06),UDim2.fromScale(.48,.52))
		title.TextXAlignment=Enum.TextXAlignment.Left
		local sub=W.text(row,"Sub",spec.sub,UDim2.fromScale(.2,.58),UDim2.fromScale(.48,.36))
		sub.TextXAlignment=Enum.TextXAlignment.Left sub.TextColor3=Color3.fromRGB(255,240,170)
		local b=W.button(row,"Go",spec.button,UDim2.fromScale(.69,.12),UDim2.fromScale(.29,.76),spec.action)
		rows[spec.id]={label=sub,button=b}
	end
	return {part=face,rows=rows}
end
-- Bay plaque, laid out like a collectible card: name, rarity + modifier,
-- level + output, a big green level-up price and a small swap button.
-- Bay plaque (30 Oct): two looks on one panel. COMPACT (default, readable
-- from the normal camera distance): crusher name, one short line ("LV 3 ·
-- $1.2K/min") and one big LEVEL UP button. DETAIL (the owner's client swaps
-- to it within C.PlaqueDetailDistance): rarity/coating, LV a > b, $/min a > b,
-- MAX and REMOVE. The name label drives the compact title.
function W.plaque(parent,cf,index)
	local face,gui=W.panel(parent,cf,8.6,4,W.Blue)
	local compact=Instance.new("Frame") compact.Name="Compact" compact.Size=UDim2.fromScale(1,1) compact.BackgroundTransparency=1 compact.Parent=gui
	local detail=Instance.new("Frame") detail.Name="Detail" detail.Size=UDim2.fromScale(1,1) detail.BackgroundTransparency=1 detail.Visible=false detail.Parent=gui
	local title=W.text(compact,"Title","LOCKED",UDim2.fromScale(.04,.06),UDim2.fromScale(.6,.46))
	title.TextXAlignment=Enum.TextXAlignment.Left
	local line=W.text(compact,"Line","",UDim2.fromScale(.04,.56),UDim2.fromScale(.6,.36))
	line.TextXAlignment=Enum.TextXAlignment.Left line.TextColor3=Color3.fromRGB(255,240,170) line.TextWrapped=false -- one line, as big as fits
	local scope=W.text(detail,"UpgradeScope","BAY "..index,UDim2.fromScale(.04,.025),UDim2.fromScale(.6,.14))
	scope.TextXAlignment=Enum.TextXAlignment.Left scope.TextColor3=Color3.fromRGB(255,240,170)
	local name=W.text(detail,"CrusherName","LOCKED",UDim2.fromScale(.04,.19),UDim2.fromScale(.6,.27))
	name.TextXAlignment=Enum.TextXAlignment.Left
	name:GetPropertyChangedSignal("Text"):Connect(function() title.Text=name.Text end)
	local rarity=W.text(detail,"Rarity","",UDim2.fromScale(.04,.48),UDim2.fromScale(.6,.17))
	rarity.TextXAlignment=Enum.TextXAlignment.Left
	local stats=W.text(detail,"Output","",UDim2.fromScale(.04,.68),UDim2.fromScale(.6,.29))
	stats.TextXAlignment=Enum.TextXAlignment.Left stats.TextColor3=Color3.fromRGB(255,240,170)
	-- the one button both looks share (the client moves/resizes it per look)
	local buy=W.button(gui,"Level","",UDim2.fromScale(.66,.07),UDim2.fromScale(.32,.86),"Bay",nil,index)
	-- detail only: MAX (buy as many levels as the cash covers) and REMOVE
	local max=W.button(detail,"LevelMax","MAX",UDim2.fromScale(.66,.67),UDim2.fromScale(.17,.27),"LevelMax",nil,index)
	local manage=W.button(detail,"Manage","REMOVE",UDim2.fromScale(.84,.67),UDim2.fromScale(.14,.27),"Manage",nil,index)
	Style.setButtonColor(manage,Color3.fromRGB(235,60,60))
	gui:SetAttribute("BayPlaque",index)
	return face,{name=name,rarity=rarity,stats=stats,scope=scope,title=title,line=line},buy,manage,max
end
-- Yellow/navy hazard band (alternating chunky blocks).
function W.hazard(parent,cf,width,height,depth)
	local n=math.max(2,math.floor(width/1.6)) local w=width/n
	for i=0,n-1 do
		W.part(parent,"Hazard",V(w,height,depth or .5),cf*CFrame.new(-width/2+w*(i+.5),0,0),if i%2==0 then W.Yellow else W.Navy)
	end
end
-- A non-clickable SurfaceGui (rendered from the world part for everyone).
function W.sign(part)
	local gui=W.surface(part) gui:SetAttribute("CrusherWorldControls",false) part.CanQuery=false return gui
end
-- Six-faced die model with red pips; returns the model (pivot = die centre).
function W.die(parent,cf,size)
	local m=Instance.new("Model") m.Name="Dice" m.Parent=parent
	local body=W.part(m,"DiceBody",V(size,size,size),cf,Color3.fromRGB(255,250,240)) m.PrimaryPart=body
	local red=Color3.fromRGB(222,48,72) local g=size*.27 local half=size/2
	local layouts={[1]={{0,0}},[2]={{-1,1},{1,-1}},[3]={{-1,1},{0,0},{1,-1}},[4]={{-1,1},{1,1},{-1,-1},{1,-1}},
		[5]={{-1,1},{1,1},{0,0},{-1,-1},{1,-1}},[6]={{-1,1},{1,1},{-1,0},{1,0},{-1,-1},{1,-1}}}
	local faces={{1,CFrame.new(0,0,half)},{6,CFrame.new(0,0,-half)*CFrame.Angles(0,math.pi,0)},
		{2,CFrame.new(half,0,0)*CFrame.Angles(0,math.pi/2,0)},{5,CFrame.new(-half,0,0)*CFrame.Angles(0,-math.pi/2,0)},
		{3,CFrame.new(0,half,0)*CFrame.Angles(-math.pi/2,0,0)},{4,CFrame.new(0,-half,0)*CFrame.Angles(math.pi/2,0,0)}}
	for _,f in faces do for _,xy in layouts[f[1]] do
		local pip=W.part(m,"DicePip",V(size*.2,size*.2,size*.08),cf*f[2]*CFrame.new(xy[1]*g,xy[2]*g,0),red)
		pip.Shape=Enum.PartType.Cylinder pip.Size=V(size*.08,size*.2,size*.2)
		pip.CFrame=cf*f[2]*CFrame.new(xy[1]*g,xy[2]*g,0)*CFrame.Angles(0,math.pi/2,0)
	end end
	return m
end
-- Toy brick with round studs on top (2 x n), for plaza decoration.
function W.brick(parent,cf,nx,nz,color,h)
	h=h or 1.6
	local m=Instance.new("Model") m.Name="ToyBrick" m.Parent=parent
	W.part(m,"BrickBody",V(nx*1.6,h,nz*1.6),cf*CFrame.new(0,h/2,0),color,true)
	for i=1,nx do for k=1,nz do
		local stud=W.part(m,"BrickStud",V(.5,1,1),cf*CFrame.new((i-(nx+1)/2)*1.6,h+.25,(k-(nz+1)/2)*1.6)*CFrame.Angles(0,0,math.pi/2),color)
		stud.Shape=Enum.PartType.Cylinder
	end end
	return m
end
-- Lamp post: navy post with a warm yellow light box.
function W.lamp(parent,cf,h)
	h=h or 3.2
	W.part(parent,"LampPost",V(.9,h,.9),cf*CFrame.new(0,h/2,0),W.Navy,true)
	local light=W.part(parent,"LampLight",V(1.5,1.2,1.5),cf*CFrame.new(0,h+.6,0),W.Yellow)
	light.Material=Enum.Material.Neon light.CastShadow=false
	W.part(parent,"LampCap",V(1.8,.3,1.8),cf*CFrame.new(0,h+1.35,0),W.Navy)
end
-- Clean raised rim round a plot top (local frame cf at floor height, plot
-- spans x -w/2..w/2, z rear..front) with an opening at the front centre.
function W.border(parent,cf,w,rear,front,gap)
	local m=Instance.new("Model") m.Name="PlotBorder" m.Parent=parent
	local light=Color3.fromRGB(78,140,232)
	local function run(a,b,along,fixed,isX)
		local len=b-a local n=math.max(1,math.floor(len/6+.5)) local seg=len/n
		for i=0,n-1 do
			local mid=a+seg*(i+.5)
			local pos=if isX then CFrame.new(mid,.8,fixed) else CFrame.new(fixed,.8,mid)
			local size=if isX then V(seg-.2,1.6,2) else V(2,1.6,seg-.2)
			local block=W.part(m,"RimBlock",size,cf*pos,if i%2==0 then W.Blue else light,true)
			Style.materialStuds(block,true,{Enum.NormalId.Top},2)
		end
	end
	local half=w/2-1
	run(-half,-gap/2,"x",front-1,true) run(gap/2,half,"x",front-1,true)
	run(-half,half,"x",rear+1,true)
	run(rear+2,front-2,"z",-half,false) run(rear+2,front-2,"z",half,false)
	for _,x in {-half,half} do for _,z in {rear+1,front-1} do
		W.part(m,"RimCorner",V(2.6,2.2,2.6),cf*CFrame.new(x,1.1,z),W.Navy,true)
		W.lamp(m,cf*CFrame.new(x,2.2,z),2.2)
	end end
	for _,x in {-gap/2-1,gap/2+1} do W.lamp(m,cf*CFrame.new(x,1.6,front-1),2.6) end
	for t=1,3 do local z=rear+(front-rear)*t/4
		for _,x in {-half,half} do W.lamp(m,cf*CFrame.new(x,1.6,z),2) end
	end
	return m
end
-- Low yellow entrance arch with hazard posts; returns the owner sign label.
function W.entrance(parent,cf,width)
	local m=Instance.new("Model") m.Name="Entrance" m.Parent=parent
	for _,x in {-width/2,width/2} do
		W.part(m,"GatePost",V(2,7,2),cf*CFrame.new(x,3.5,0),W.Navy,true)
		for k=0,3 do W.part(m,"PostStripe",V(2.1,.7,2.1),cf*CFrame.new(x,1+k*1.6,0),W.Yellow) end
		W.beacon(m,cf*CFrame.new(x,9,0))
	end
	local beam=W.part(m,"GateBeam",V(width+3,1.8,2.4),cf*CFrame.new(0,7.9,0),W.Yellow)
	Style.materialStuds(beam,true,{Enum.NormalId.Top},2)
	local plate=W.part(m,"NamePlate",V(width-3,1.4,.4),cf*CFrame.new(0,7.9,1.35),W.Navy)
	local gui=W.sign(plate)
	return W.text(gui,"OwnerName","Free factory",UDim2.fromScale(.03,.06),UDim2.fromScale(.94,.88))
end
-- Dark walkway with yellow edge dashes and white arrows pointing in.
function W.walkway(parent,cf,width,z0,z1)
	local m=Instance.new("Model") m.Name="Walkway" m.Parent=parent
	local len=z1-z0
	local top=W.part(m,"WalkTop",V(width,.14,len),cf*CFrame.new(0,.07,(z0+z1)/2),Color3.fromRGB(52,58,72))
	top.Material=Enum.Material.SmoothPlastic
	Style.studs(top) -- 30 Oct: studded road like the floors (Willem: keep)
	local function paint(name,size,pcf,color)
		local p=W.part(m,name,size,cf*pcf,color) p.CastShadow=false
	end
	for z=z0+2,z1-2,4 do for _,x in {-width/2+.6,width/2-.6} do
		paint("EdgeDash",V(.5,.04,2),CFrame.new(x,.16,z),W.Yellow)
	end end
	local white=Color3.fromRGB(240,242,236)
	for _,z in {z0+(len*.25),z0+len*.6,z0+len*.9} do
		-- Arrow pointing into the plot (-Z): shaft, then a chevron whose tip is at z-1.6.
		paint("ArrowShaft",V(.7,.04,3.2),CFrame.new(0,.16,z+.6),white)
		for _,side in {-1,1} do paint("ArrowHead",V(.7,.04,2.4),CFrame.new(side*.78,.16,z-.75)*CFrame.Angles(0,side*math.pi/4,0),white) end
	end
	return m
end
-- Sloped conveyor from a to b (world points on the belt surface): dark belt,
-- yellow side rails, navy legs and end rollers. The belt carries attributes
-- the client uses to roll toy parts along it (Conveyor.client.luau).
function W.conveyor(parent,a,b,width,floorY)
	local m=Instance.new("Model") m.Name="ScrapConveyor" m.Parent=parent
	local len=(b-a).Magnitude local mid=(a+b)/2 local cf=CFrame.lookAt(mid,b)
	local belt=W.part(m,"ConveyorBelt",V(width,.5,len),cf*CFrame.new(0,-.25,0),Color3.fromRGB(45,50,62),true)
	belt:SetAttribute("ConveyorFrom",a) belt:SetAttribute("ConveyorTo",b) belt:SetAttribute("ConveyorWidth",width)
	for _,x in {-1,1} do
		W.part(m,"ConveyorRail",V(.4,.9,len),cf*CFrame.new(x*(width/2+.2),.2,0),W.Yellow,true)
		W.part(m,"ConveyorSkirt",V(.3,.8,len),cf*CFrame.new(x*(width/2+.15),-.6,0),W.Navy)
	end
	for _,t in {-.5,.5} do
		local r=W.part(m,"ConveyorRoller",V(width+.6,1,1),cf*CFrame.new(0,-.4,t*len),Color3.fromRGB(150,160,175))
		r.Shape=Enum.PartType.Cylinder r.CFrame=cf*CFrame.new(0,-.4,t*len)
	end
	local n=math.max(2,math.floor(len/7))
	for i=0,n do
		local p=a:Lerp(b,i/n) local h=p.Y-floorY
		if h>1.2 then for _,x in {-1,1} do
			local foot=(cf*CFrame.new(x*(width/2-.3),0,0)).Position-cf.Position+p
			W.part(m,"ConveyorLeg",V(.6,h-.6,.6),CFrame.new(foot.X,p.Y-.5-(h-.6)/2,foot.Z),W.Navy)
		end end
	end
	return m
end
-- Front control panel shared by the three stations: heading, live line, button.
local function stationPanel(m,cf,color,heading,action,width)
	local face,gui=W.panel(m,cf,width or 20,6.2,color,true)
	W.text(gui,"Heading",heading,UDim2.fromScale(.04,.03),UDim2.fromScale(.92,.3))
	local label=W.text(gui,"StationInfo","",UDim2.fromScale(.04,.33),UDim2.fromScale(.92,.2))
	label.TextColor3=Color3.fromRGB(255,240,170)
	local button=W.button(gui,"Action",action,UDim2.fromScale(.1,.56),UDim2.fromScale(.8,.38),action:sub(1,1)..action:sub(2):lower())
	return face,label,button
end
-- Lego studs on the station bodies (the imported Studs material variant)
local function studs(p) Style.studs(p) return p end
local TOY={W.Yellow,W.Green,W.Blue,Color3.fromRGB(230,69,77),Color3.fromRGB(255,140,40)}
function W.station(parent,cf,kind)
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	local station
	if kind=="Collect" then
		-- Blue hopper: low walls so the pile shows, panel on the front wall.
		studs(W.part(m,"MachineFoot",V(24,1,16),cf*CFrame.new(0,.5,0),W.Navy,true))
		studs(W.part(m,"HopperFloor",V(22,1,14),cf*CFrame.new(0,1.5,0),Style.darken(W.Blue,.25)))
		studs(W.part(m,"HopperBack",V(22,7,1),cf*CFrame.new(0,4.5,-6.5),W.Blue,true))
		for _,x in {-10.5,10.5} do studs(W.part(m,"HopperSide",V(1,7,14),cf*CFrame.new(x,4.5,0),W.Blue,true)) end
		studs(W.part(m,"HopperFront",V(22,6.4,1),cf*CFrame.new(0,4.2,6.5),W.Blue,true))
		W.hazard(m,cf*CFrame.new(0,8.25,6.5),22,.5,1.1)
		for _,x in {-10.5,10.5} do for _,z in {-6.5,6.5} do studs(W.part(m,"CornerCap",V(1.6,.6,1.6),cf*CFrame.new(x,8.3,z),W.Navy)) end end
		local fill=Instance.new("Model") fill.Name="StoredScrap" fill.Parent=m
		local rng=Random.new(7)
		-- 30 Oct: three layers inside the hopper, then a heap that rises well above
		-- the walls (narrower each layer). Pieces are listed bottom-up, so showing
		-- the first N grows the pile from the floor (CrusherGame sets N).
		local i=0
		for layer=0,8 do
			local count=if layer<=2 then 8 else 11-layer
			local shrink=if layer<=2 then 1 else 1-.13*(layer-2)
			for _=1,count do
				i+=1
				local x,z=rng:NextNumber(-8.5,8.5)*shrink,rng:NextNumber(-5,4.5)*shrink
				studs(W.part(fill,"ToyScrap",V(rng:NextNumber(2,3.4),rng:NextNumber(1.4,2.4),rng:NextNumber(2,3)),
					cf*CFrame.new(x,2.6+layer*1.6,z)*CFrame.Angles(rng:NextNumber(-.4,.4),rng:NextNumber(0,6),rng:NextNumber(-.4,.4)),TOY[(i-1)%#TOY+1]))
			end
		end
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.1,7.6),W.Blue,"COLLECT SCRAP","COLLECT")
		station={part=face,label=label,button=button,fill=fill}
	elseif kind=="Sell" then
		-- Compact green counter with a register and a SELL SCRAP sign on low posts.
		studs(W.part(m,"MachineFoot",V(20,1,12),cf*CFrame.new(0,.5,0),W.Navy,true))
		studs(W.part(m,"CounterBody",V(18,6.6,10),cf*CFrame.new(0,4.3,0),W.Green,true))
		studs(W.part(m,"CounterTop",V(19,.9,11),cf*CFrame.new(0,8,0),W.Navy))
		W.hazard(m,cf*CFrame.new(0,1.4,5.1),18,.8,.4)
		W.part(m,"Register",V(4.6,3,3.6),cf*CFrame.new(5,10,-1.5),W.Navy)
		W.part(m,"RegisterKeys",V(4,.5,1.8),cf*CFrame.new(5,8.7,1.6)*CFrame.Angles(math.rad(-15),0,0),Color3.fromRGB(70,80,100))
		local screen=W.part(m,"RegisterDisplay",V(3.4,1.5,.3),cf*CFrame.new(5,10.6,.35),Color3.fromRGB(120,255,140))
		screen.Material=Enum.Material.Neon screen.CastShadow=false
		for i,x in {-6,-3.5,-1} do
			W.part(m,"CashStack",V(2.2,.5+i*.35,1.4),cf*CFrame.new(x,8.7+i*.17,-2.5),Color3.fromRGB(80,200,90))
		end
		for _,x in {-7.5,7.5} do studs(W.part(m,"SignPost",V(1.1,6,1.1),cf*CFrame.new(x,11.5,-4.2),W.Navy)) end
		local board=W.part(m,"SellSign",V(15,3.2,.8),cf*CFrame.new(0,14.2,-4.2),W.Green)
		studs(W.part(m,"SignFrame",V(16.2,4.4,.6),cf*CFrame.new(0,14.2,-4.8),W.Navy))
		local gui=W.sign(board)
		W.icon(gui,"CashIcon",Icons.Cash,UDim2.fromScale(.02,.05),UDim2.fromScale(.18,.9))
		W.text(gui,"SignText","SELL SCRAP",UDim2.fromScale(.2,.08),UDim2.fromScale(.76,.84))
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.2,5.9),W.Green,"SELL SCRAP","SELL",16)
		station={part=face,label=label,button=button}
	elseif kind=="Trash" then
		-- Toy trash can (29 Oct): a studded bin with its lid flipped open, scrap
		-- bricks peeking out, a red TRASH sign and the panel on the front.
		local red=Color3.fromRGB(226,52,58) local bin=Color3.fromRGB(64,82,100)
		studs(W.part(m,"MachineFoot",V(13,1,12),cf*CFrame.new(0,.5,0),W.Navy,true))
		studs(W.part(m,"BinBody",V(10,7.4,9),cf*CFrame.new(0,4.7,-.4),bin,true))
		for _,x in {-3,0,3} do studs(W.part(m,"BinRib",V(1,7.4,.5),cf*CFrame.new(x,4.7,4.2),Style.darken(bin,.25))) end
		studs(W.part(m,"BinRim",V(11,.9,10),cf*CFrame.new(0,8.8,-.4),W.Navy))
		W.hazard(m,cf*CFrame.new(0,1.4,4.25),10,.8,.3)
		-- lid hinged at the back, flipped up and over
		studs(W.part(m,"BinLid",V(11,.8,9.6),cf*CFrame.new(0,9.4,-5.4)*CFrame.Angles(math.rad(70),0,0)*CFrame.new(0,0,-4.6),red))
		studs(W.part(m,"LidHandle",V(3,.6,.8),cf*CFrame.new(0,13.6,-6.6),W.Navy))
		local rng=Random.new(11)
		for i=1,7 do
			studs(W.part(m,"TrashBrick",V(rng:NextNumber(1.6,2.8),rng:NextNumber(1,1.8),rng:NextNumber(1.6,2.6)),
				cf*CFrame.new(rng:NextNumber(-3.2,3.2),9.1+rng:NextNumber(0,.8),rng:NextNumber(-3.4,2))*CFrame.Angles(rng:NextNumber(-.6,.6),rng:NextNumber(0,6),rng:NextNumber(-.6,.6)),TOY[(i-1)%#TOY+1]))
		end
		for _,x in {-5.2,5.2} do studs(W.part(m,"SignPost",V(.9,6,.9),cf*CFrame.new(x,12,-5.6),W.Navy)) end
		local board=W.part(m,"TrashSign",V(11,2.8,.7),cf*CFrame.new(0,15.6,-5.6),red)
		studs(W.part(m,"SignFrame",V(12,3.8,.5),cf*CFrame.new(0,15.6,-6.1),W.Navy))
		local gui=W.sign(board)
		W.text(gui,"SignText","TRASH",UDim2.fromScale(.05,.08),UDim2.fromScale(.9,.84))
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.3,5),red,"TRASH CAN","TRASH",12)
		label.Text="Throw away crushers"
		station={part=face,label=label,button=button}
	else
		-- Purple roll machine: crushing rollers, a big die and a reveal stand.
		studs(W.part(m,"MachineFoot",V(24,1,16),cf*CFrame.new(0,.5,0),W.Navy,true))
		studs(W.part(m,"MachineBody",V(22,7,13),cf*CFrame.new(0,4.5,0),W.Purple,true))
		W.hazard(m,cf*CFrame.new(0,8.25,6.3),22,.5,.6)
		local rollers={}
		for _,x in {-10,-1} do studs(W.part(m,"RollerCheek",V(1.2,4,7),cf*CFrame.new(x,10,-1.5),Style.darken(W.Purple,.3))) end
		for i,z in {-3.4,.4} do
			local r=W.part(m,"Roller",V(8,2.6,2.6),cf*CFrame.new(-5.5,9.6,z),Color3.fromRGB(150,160,175))
			r.Shape=Enum.PartType.Cylinder r.Material=Enum.Material.DiamondPlate table.insert(rollers,r)
		end
		studs(W.part(m,"DiePedestal",V(5,2,5),cf*CFrame.new(6.5,9,-3),W.Yellow))
		local die=W.die(m,cf*CFrame.new(6.5,13,-3)*CFrame.Angles(.35,.6,.2),5.2)
		W.beacon(m,cf*CFrame.new(-10,8,6)) W.beacon(m,cf*CFrame.new(10,8,6))
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.3,7.4),W.Purple,"ROLL A CRUSHER","ROLL")
		-- Pedestals in an arc in front of the machine (like the reference): a roll
		-- fills every unlocked one with an offer; each has a card and a Buy prompt.
		-- Listed in unlock order: centre first, then outwards.
		local pedestals={}
		for i,at in C.PedestalSpots do
			local pcf=cf*CFrame.new(at.X,0,at.Y)*CFrame.Angles(0,math.atan2(at.X,at.Y),0)
			local base=studs(W.part(m,"PedestalBase",V(5.4,1,5.4),pcf*CFrame.new(0,.5,0),W.Navy,true))
			local plinth=studs(W.part(m,"Pedestal",V(4.4,2.2,4.4),pcf*CFrame.new(0,2.1,0),W.Yellow,true))
			plinth:SetAttribute("Slot",i)
			studs(W.part(m,"PedestalTrim",V(4.8,.3,4.8),pcf*CFrame.new(0,3.3,0),W.Navy))
			local anchor=W.part(m,"PedestalCardAnchor",V(.2,.2,.2),pcf*CFrame.new(0,3.4,0),W.Navy)
			anchor.Transparency=1
			local card=Instance.new("BillboardGui") card.Name="OfferCard" card.Size=UDim2.fromScale(9,5.4)
			card.StudsOffset=Vector3.new(0,10.4,0) card.MaxDistance=110 card.LightInfluence=0 card.Parent=anchor
			local function line(name,y,h,color)
				local t=W.text(card,name,"",UDim2.fromScale(0,y),UDim2.fromScale(1,h)) t.TextColor3=color return t
			end
			local lines={name=line("CrusherName",0,.25,Color3.new(1,1,1)),rarity=line("Rarity",.25,.18,Color3.new(1,1,1)),
				odds=line("Odds",.43,.16,Color3.fromRGB(120,200,255)),value=line("Value",.59,.18,Color3.fromRGB(120,255,110)),
				price=line("Price",.77,.23,Color3.fromRGB(255,220,80))}
			local prompt=Instance.new("ProximityPrompt") prompt.Name="BuyPrompt" prompt.ActionText="Buy" prompt.ObjectText="Pedestal "..i
			prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.HoldDuration=0 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
			prompt.Enabled=false prompt.Parent=plinth
			pedestals[i]={top=pcf*CFrame.new(0,3.2,0),part=plinth,base=base,card=lines,prompt=prompt}
		end
		station={part=face,label=label,button=button,die=die,rollers=rollers,pedestals=pedestals}
	end
	return station
end
return W
