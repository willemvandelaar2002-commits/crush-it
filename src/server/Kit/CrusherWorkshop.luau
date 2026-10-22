--!strict
-- Reusable physical furniture and world-control templates for crusher plots.
local RS=game:GetService("ReplicatedStorage")
local Style=require(RS.Shared.Kit.Style)
local C=require(RS.Shared.CrusherConfig)
local Icons=require(RS.Shared.Icons)
local Build=require(script.Parent.Build)
local W={}
W.Blue=Color3.fromRGB(35,99,210) W.Navy=Color3.fromRGB(25,43,73)
W.Yellow=Color3.fromRGB(248,199,53) W.Green=Color3.fromRGB(53,201,79)
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
	gui.LightInfluence=.15 gui.MaxDistance=125 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("CrusherWorldControls",true) gui.Parent=part return gui
end
function W.beacon(parent,cf)
	W.part(parent,"BeaconFoot",V(1.8,.6,1.8),cf,W.Navy)
	local p=W.part(parent,"WarmBeacon",V(1.3,1.2,1.3),cf*CFrame.new(0,.9,0),W.Yellow)
	p.Material=Enum.Material.Neon p.CastShadow=false
end
function W.panel(parent,cf,width,height,color)
	W.part(parent,"PanelCasing",V(width+1.4,height+1.4,1.4),cf,W.Navy)
	local face=W.part(parent,"Panel",V(width,height,.6),cf*CFrame.new(0,0,.8),color)
	for _,x in {-1,1} do for _,y in {-1,1} do
		local bolt=W.part(parent,"Bolt",V(.7,.7,.5),cf*CFrame.new(x*(width/2+.1),y*(height/2+.1),1.25),Color3.fromRGB(211,222,235))
		bolt.Shape=Enum.PartType.Ball
	end end
	return face,W.surface(face)
end
W.UpgradeIcons={Damage=Icons.Power,Speed=Icons.Speed,Yield=Icons.Value,Luck=Icons.Lucky,RollSpeed=Icons.Rebirth}
W.UpgradeColors={Damage=Color3.fromRGB(223,62,62),Speed=Color3.fromRGB(240,180,30),Yield=Color3.fromRGB(53,190,79),
	Luck=Color3.fromRGB(150,62,229),RollSpeed=Color3.fromRGB(106,76,224)}
-- Upgrade board: one colour band per upgrade with icon, name, level step and
-- a green price button (the button is the purchase control).
function W.board(parent,cf,kind)
	local color=if kind=="Production" then W.Blue else W.Purple
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	for _,x in {-9,9} do
		W.part(m,"Support",V(2,12,2),cf*CFrame.new(x,6,0),W.Navy)
		W.part(m,"Foot",V(5,1,7),cf*CFrame.new(x,.5,0),W.Blue)
		W.beacon(m,cf*CFrame.new(x,16,0))
	end
	local face,gui=W.panel(m,cf*CFrame.new(0,8.6,0),22,13,color)
	W.text(gui,"Heading",string.upper(kind).." UPGRADES",UDim2.fromScale(.04,.025),UDim2.fromScale(.92,.15))
	local rows={} local count=if kind=="Production" then 3 else 2 local rowIndex=0
	local top,span=.2,.77
	for _,id in C.UpgradeOrder do if C.Upgrades[id].group==kind then
		rowIndex+=1 local row=Instance.new("Frame") row.Name="Row_"..id
		local h=span/count
		row.Position=UDim2.fromScale(.03,top+(rowIndex-1)*h) row.Size=UDim2.fromScale(.94,h-.03)
		Style.panel(row,W.UpgradeColors[id],Style.darken(W.UpgradeColors[id],.35)) row.Parent=gui
		W.icon(row,"UpgradeIcon",W.UpgradeIcons[id],UDim2.fromScale(.015,.08),UDim2.fromScale(.15,.84))
		local title=W.text(row,"UpgradeName",string.upper(C.Upgrades[id].name),UDim2.fromScale(.18,.06),UDim2.fromScale(.5,.5))
		title.TextXAlignment=Enum.TextXAlignment.Left
		local level=W.text(row,"LevelStep","Lv 0 > 1",UDim2.fromScale(.18,.56),UDim2.fromScale(.5,.38))
		level.TextXAlignment=Enum.TextXAlignment.Left level.TextColor3=Color3.fromRGB(255,240,170)
		local b=W.button(row,"Buy","$0",UDim2.fromScale(.7,.12),UDim2.fromScale(.28,.76),"Upgrade",id)
		rows[id]={label=level,button=b}
	end end
	return {part=face,rows=rows}
end
-- Bay plaque, laid out like a collectible card: name, rarity + modifier,
-- level + output, a big green level-up price and a small swap button.
function W.plaque(parent,cf,index)
	local face,gui=W.panel(parent,cf,8.6,4,W.Blue)
	local name=W.text(gui,"CrusherName","LOCKED",UDim2.fromScale(.04,.04),UDim2.fromScale(.6,.34))
	name.TextXAlignment=Enum.TextXAlignment.Left
	local rarity=W.text(gui,"Rarity","",UDim2.fromScale(.04,.39),UDim2.fromScale(.6,.24))
	rarity.TextXAlignment=Enum.TextXAlignment.Left
	local stats=W.text(gui,"Output","",UDim2.fromScale(.04,.66),UDim2.fromScale(.6,.28))
	stats.TextXAlignment=Enum.TextXAlignment.Left stats.TextColor3=Color3.fromRGB(255,240,170)
	local buy=W.button(gui,"Level","",UDim2.fromScale(.66,.07),UDim2.fromScale(.32,.55),"Bay",nil,index)
	local manage=W.button(gui,"Manage","SWAP",UDim2.fromScale(.7,.67),UDim2.fromScale(.24,.27),"Manage",nil,index)
	Style.setButtonColor(manage,Color3.fromRGB(70,140,230))
	return face,{name=name,rarity=rarity,stats=stats},buy,manage
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
-- Front control panel shared by the three stations: heading, live line, button.
local function stationPanel(m,cf,color,heading,action)
	local face,gui=W.panel(m,cf,20,6.2,color)
	W.text(gui,"Heading",heading,UDim2.fromScale(.04,.03),UDim2.fromScale(.92,.3))
	local label=W.text(gui,"StationInfo","",UDim2.fromScale(.04,.33),UDim2.fromScale(.92,.2))
	label.TextColor3=Color3.fromRGB(255,240,170)
	local button=W.button(gui,"Action",action,UDim2.fromScale(.1,.56),UDim2.fromScale(.8,.38),action:sub(1,1)..action:sub(2):lower())
	return face,label,button
end
local TOY={W.Yellow,W.Green,W.Blue,Color3.fromRGB(230,69,77),Color3.fromRGB(255,140,40)}
function W.station(parent,cf,kind)
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	local station
	if kind=="Collect" then
		-- Blue hopper: low walls so the pile shows, panel on the front wall.
		W.part(m,"MachineFoot",V(24,1,16),cf*CFrame.new(0,.5,0),W.Navy)
		W.part(m,"HopperFloor",V(22,1,14),cf*CFrame.new(0,1.5,0),Style.darken(W.Blue,.25))
		W.part(m,"HopperBack",V(22,7,1),cf*CFrame.new(0,4.5,-6.5),W.Blue)
		for _,x in {-10.5,10.5} do W.part(m,"HopperSide",V(1,7,14),cf*CFrame.new(x,4.5,0),W.Blue) end
		W.part(m,"HopperFront",V(22,6.4,1),cf*CFrame.new(0,4.2,6.5),W.Blue)
		W.hazard(m,cf*CFrame.new(0,8.25,6.5),22,.5,1.1)
		for _,x in {-10.5,10.5} do for _,z in {-6.5,6.5} do W.part(m,"CornerCap",V(1.6,.6,1.6),cf*CFrame.new(x,8.3,z),W.Navy) end end
		local fill=Instance.new("Model") fill.Name="StoredScrap" fill.Parent=m
		local rng=Random.new(7)
		for i=1,24 do
			local x,z=rng:NextNumber(-8.5,8.5),rng:NextNumber(-5,4.5) local layer=math.floor((i-1)/8)
			W.part(fill,"ToyScrap",V(rng:NextNumber(2,3.4),rng:NextNumber(1.4,2.4),rng:NextNumber(2,3)),
				cf*CFrame.new(x,2.6+layer*1.6,z)*CFrame.Angles(rng:NextNumber(-.4,.4),rng:NextNumber(0,6),rng:NextNumber(-.4,.4)),TOY[(i-1)%#TOY+1])
		end
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.1,7.6),W.Blue,"COLLECT SCRAP","COLLECT")
		station={part=face,label=label,button=button,fill=fill}
	elseif kind=="Sell" then
		-- Green counter with a register and a SELL SCRAP sign on low posts.
		W.part(m,"MachineFoot",V(24,1,15),cf*CFrame.new(0,.5,0),W.Navy)
		W.part(m,"CounterBody",V(22,6.6,12),cf*CFrame.new(0,4.3,0),W.Green)
		W.part(m,"CounterTop",V(23,.9,13),cf*CFrame.new(0,8,0),W.Navy)
		W.hazard(m,cf*CFrame.new(0,1.4,6.1),22,.8,.4)
		W.part(m,"Register",V(5,3,4),cf*CFrame.new(6,10,-2),W.Navy)
		W.part(m,"RegisterKeys",V(4.4,.5,2),cf*CFrame.new(6,8.7,1)*CFrame.Angles(math.rad(-15),0,0),Color3.fromRGB(70,80,100))
		local screen=W.part(m,"RegisterDisplay",V(3.8,1.6,.3),cf*CFrame.new(6,10.6,0),Color3.fromRGB(120,255,140))
		screen.Material=Enum.Material.Neon screen.CastShadow=false
		for i,x in {-7,-4,-1} do
			W.part(m,"CashStack",V(2.6,.5+i*.35,1.5),cf*CFrame.new(x,8.7+i*.17,-3),Color3.fromRGB(80,200,90))
		end
		for _,x in {-9,9} do W.part(m,"SignPost",V(1.2,6,1.2),cf*CFrame.new(x,11.5,-5),W.Navy) end
		local board=W.part(m,"SellSign",V(18,3.4,.8),cf*CFrame.new(0,14.2,-5),W.Green)
		W.part(m,"SignFrame",V(19.2,4.6,.6),cf*CFrame.new(0,14.2,-5.6),W.Navy)
		local gui=W.sign(board)
		W.icon(gui,"CashIcon",Icons.Cash,UDim2.fromScale(.02,.05),UDim2.fromScale(.18,.9))
		W.text(gui,"SignText","SELL SCRAP",UDim2.fromScale(.2,.08),UDim2.fromScale(.76,.84))
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.2,6.9),W.Green,"SELL SCRAP","SELL")
		station={part=face,label=label,button=button}
	else
		-- Purple roll machine: crushing rollers, a big die and a reveal stand.
		W.part(m,"MachineFoot",V(24,1,16),cf*CFrame.new(0,.5,0),W.Navy)
		W.part(m,"MachineBody",V(22,7,13),cf*CFrame.new(0,4.5,0),W.Purple)
		W.hazard(m,cf*CFrame.new(0,8.25,6.3),22,.5,.6)
		local rollers={}
		for _,x in {-10,-1} do W.part(m,"RollerCheek",V(1.2,4,7),cf*CFrame.new(x,10,-1.5),Style.darken(W.Purple,.3)) end
		for i,z in {-3.4,.4} do
			local r=W.part(m,"Roller",V(8,2.6,2.6),cf*CFrame.new(-5.5,9.6,z),Color3.fromRGB(150,160,175))
			r.Shape=Enum.PartType.Cylinder r.Material=Enum.Material.DiamondPlate table.insert(rollers,r)
		end
		W.part(m,"DiePedestal",V(5,2,5),cf*CFrame.new(6.5,9,-3),W.Yellow)
		local die=W.die(m,cf*CFrame.new(6.5,13,-3)*CFrame.Angles(.35,.6,.2),5.2)
		W.beacon(m,cf*CFrame.new(-10,8,6)) W.beacon(m,cf*CFrame.new(10,8,6))
		-- Reveal stand on the right side: last rolled crusher + its name.
		local stand=W.part(m,"RevealStand",V(6,1,6),cf*CFrame.new(14.5,.5,1),W.Navy)
		W.part(m,"RevealPlinth",V(5,2.4,5),cf*CFrame.new(14.5,2.2,1),W.Yellow)
		local banner=W.part(m,"RevealPanel",V(7,2.2,.4),cf*CFrame.new(14.5,11.6,-1.4),W.Navy)
		for _,x in {12,17} do W.part(m,"RevealPost",V(.6,11,.6),cf*CFrame.new(x,6,-1.6),W.Navy) end
		local reveal=W.text(W.sign(banner),"Reveal","LAST ROLL",UDim2.fromScale(.03,.05),UDim2.fromScale(.94,.9))
		local face,label,button=stationPanel(m,cf*CFrame.new(0,4.3,7.4),W.Purple,"ROLL A CRUSHER","ROLL")
		station={part=face,label=label,button=button,reveal=reveal,die=die,rollers=rollers,
			pedestal=cf*CFrame.new(14.5,3.4,1),standPart=stand}
	end
	return station
end
return W
