--!strict
-- Reusable physical furniture and world-control templates for crusher plots.
local RS=game:GetService("ReplicatedStorage")
local Style=require(RS.Shared.Kit.Style)
local C=require(RS.Shared.CrusherConfig)
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
function W.board(parent,cf,kind)
	local color=if kind=="Production" then W.Blue else W.Purple
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	for _,x in {-9,9} do
		W.part(m,"Support",V(2,12,2),cf*CFrame.new(x,6,0),W.Navy)
		W.part(m,"Foot",V(5,1,7),cf*CFrame.new(x,.5,0),W.Blue)
		W.beacon(m,cf*CFrame.new(x,16,0))
	end
	local face,gui=W.panel(m,cf*CFrame.new(0,8.6,0),22,13,color)
	W.text(gui,"Heading",string.upper(kind).." UPGRADES",UDim2.fromScale(.03,.02),UDim2.fromScale(.94,.14))
	local rows={} local count=if kind=="Production" then 3 else 2 local rowIndex=0
	local colors={Damage=Color3.fromRGB(223,62,62),Speed=W.Yellow,Yield=W.Green,Luck=Color3.fromRGB(168,62,229),RollSpeed=Color3.fromRGB(116,76,224)}
	for _,id in C.UpgradeOrder do if C.Upgrades[id].group==kind then
		rowIndex+=1 local row=Instance.new("Frame") row.Name="Row_"..id
		row.Position=UDim2.fromScale(.035,.18+(rowIndex-1)*(.77/count)) row.Size=UDim2.fromScale(.93,.71/count)
		Style.panel(row,colors[id],color) row.Parent=gui
		local t=W.text(row,"Benefit",C.Upgrades[id].name,UDim2.fromScale(.02,.04),UDim2.fromScale(.64,.92))
		local b=W.button(row,"Buy","BUY",UDim2.fromScale(.69,.16),UDim2.fromScale(.28,.68),"Upgrade",id)
		rows[id]={label=t,button=b}
	end end
	return {part=face,rows=rows}
end
function W.plaque(parent,cf,index)
	local face,gui=W.panel(parent,cf,8.2,3.2,W.Blue)
	local label=W.text(gui,"MachineInfo","BAY "..index,UDim2.fromScale(.02,.02),UDim2.fromScale(.63,.96))
	local buy=W.button(gui,"Level","LOCKED",UDim2.fromScale(.67,.08),UDim2.fromScale(.31,.48),"Bay",nil,index)
	local manage=W.button(gui,"Manage","EQUIP",UDim2.fromScale(.67,.62),UDim2.fromScale(.31,.31),"Manage",nil,index)
	return face,label,buy,manage
end
function W.station(parent,cf,kind)
	local m=Instance.new("Model") m.Name=kind.."Station" m.Parent=parent
	local color=if kind=="Roll" then W.Purple else if kind=="Sell" then W.Green else W.Blue
	W.part(m,"MachineFoot",V(26,1,17),cf*CFrame.new(0,.5,0),W.Navy)
	W.part(m,"MachineBody",V(24,6,14),cf*CFrame.new(0,4,0),color)
	local face,gui=W.panel(m,cf*CFrame.new(0,5.5,7.7),23,6,color)
	local label=W.text(gui,"StationInfo",string.upper(kind).." SCRAP",UDim2.fromScale(.02,.02),UDim2.fromScale(.96,.39))
	local button=W.button(gui,"Action",string.upper(kind),UDim2.fromScale(.08,.47),UDim2.fromScale(.84,.47),kind)
	local station={part=face,label=label,button=button}
	if kind=="Roll" then
		W.part(m,"RevealBed",V(20,1,10),cf*CFrame.new(0,8,0),W.Yellow)
		for _,x in {-10,10} do W.part(m,"RevealPost",V(2,9,2),cf*CFrame.new(x,12,0),color) W.beacon(m,cf*CFrame.new(x,17,0)) end
		W.part(m,"RevealHeader",V(23,2,3),cf*CFrame.new(0,16,0),color)
		local die=W.part(m,"Dice",V(7,7,7),cf*CFrame.new(8,21,0)*CFrame.Angles(.15,0,.25),Color3.fromRGB(255,249,234))
		for _,pos in {V(-1.8,1.8,3.55),V(0,0,3.55),V(1.8,-1.8,3.55)} do
			local pip=W.part(m,"DicePip",V(1.3,1.3,.3),die.CFrame*CFrame.new(pos),Color3.fromRGB(221,53,89)) pip.Shape=Enum.PartType.Ball
		end
		for _,x in {-5,0,5} do W.part(m,"PreviewBlock",V(4,3,4),cf*CFrame.new(x,10,0),if x==0 then W.Yellow else W.Blue) end
		local display=W.part(m,"RevealPanel",V(17,4,.5),cf*CFrame.new(0,13,1),W.Navy)
		station.reveal=W.text(W.surface(display),"Reveal","ROLL A CRUSHER",UDim2.fromScale(.02,.03),UDim2.fromScale(.96,.94))
	elseif kind=="Collect" then
		for _,x in {-12,12} do W.part(m,"HopperWall",V(1,5,15),cf*CFrame.new(x,9,0),color) end
		for _,z in {-7,7} do W.part(m,"HopperEnd",V(25,5,1),cf*CFrame.new(0,9,z),color) end
		local fill=Instance.new("Model") fill.Name="StoredScrap" fill.Parent=m station.fill=fill
		local colors={W.Yellow,W.Green,W.Blue,Color3.fromRGB(230,69,77)}
		for i=1,12 do W.part(fill,"ToyScrap",V(4,3,3),cf*CFrame.new(-8+((i-1)%4)*5,9+math.floor((i-1)/8)*1.5,-4+math.floor((i-1)/4)%2*7)*CFrame.Angles(0,i*.7,.2),colors[(i-1)%4+1]) end
	else
		W.part(m,"CounterTop",V(27,1.3,17),cf*CFrame.new(0,8,0),W.Green)
		W.part(m,"CashRegister",V(6,4,5),cf*CFrame.new(7,10,0),W.Navy)
		local screen=W.part(m,"RegisterDisplay",V(4,2,.3),cf*CFrame.new(7,11,2.7),W.Green) screen.Material=Enum.Material.Neon
		for i=1,3 do W.part(m,"PackedScrap",V(3,2,3),cf*CFrame.new(-9+i*4,9.7,0),W.Yellow) end
	end
	return station
end
return W
