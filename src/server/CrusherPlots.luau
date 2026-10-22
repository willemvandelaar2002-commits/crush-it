--!strict
-- Same eight island origins/footprints and rail access; new short factory route.
local S=game:GetService("ReplicatedStorage").Shared
local Config=require(S.Config)
local C=Config.Crushers
local Build=require(script.Parent.Kit.Build)
local Style=require(S.Kit.Style)
local Decor=require(script.Parent.PlotDecor)
local Moat=require(script.Parent.Moat)
local P={}
local V=Vector3.new
local blue=Color3.fromRGB(45,114,207)
local navy=Color3.fromRGB(30,54,88)
local yellow=Color3.fromRGB(241,192,72)
local green=Color3.fromRGB(79,196,111)
function P.prompt(part,action,title)
	local p=Instance.new("ProximityPrompt") p.Name="FactoryPrompt" p.ActionText=action p.ObjectText=title p.HoldDuration=0 p.MaxActivationDistance=12 p.RequiresLineOfSight=false p.Parent=part return p
end
local function label(part,text,face)
	local gui=Instance.new("SurfaceGui") gui.Face=face or Enum.NormalId.Back gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=6 gui.LightInfluence=0 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=part
	local l=Instance.new("TextLabel") l.Size=UDim2.fromScale(.94,.9) l.Position=UDim2.fromScale(.03,.05) l.BackgroundTransparency=1 l.TextScaled=true l.Text=text Style.text(l,2) l.Parent=gui return l
end
function P.create(root,Plots)
	require(script.Parent.Hub).create(root)
	local theme=Style.theme(Config.Look.Theme)
	for i=1,Config.Plots.Count do
		local o=Plots.originFor(i) local m=Instance.new("Model") m.Name="Plot"..i m:SetAttribute("Index",i) m:SetAttribute("Origin",o)
		local depth=Config.Plots.Front+Config.Plots.Back
		Build.platform(m,"Floor",o*CFrame.new(0,0,(Config.Plots.Front-Config.Plots.Back)/2),Config.Plots.FloorSize,depth,o.Position.Y-.05,theme.platform,theme.edge,2)
		local decor=Instance.new("Model") decor.Name="Decor" decor.Parent=m
		local sign=Decor.gate(decor,o*CFrame.new(0,0,Config.Plots.Front-2.2),11,blue,theme)
		Build.path(m,(o*CFrame.new(0,0,Config.Plots.Front-1)).Position,(o*CFrame.new(0,0,-16)).Position,8)
		Build.path(m,(o*CFrame.new(-42,0,-16)).Position,(o*CFrame.new(42,0,-16)).Position,7)
		local plot={index=i,origin=o,model=m,owner=nil,sign=sign,bays={},stations={}}
		for bay=1,C.MaxBays do
			local cf=o*CFrame.new(C.BayX[bay],0,C.BayZ)
			local holder=Instance.new("Model") holder.Name="WorkingBay"..bay holder:SetAttribute("Bay",bay) holder.Parent=m
			Build.platform(holder,"BayPlatform",cf,28,29,.5,navy,yellow,1)
			local face=Build.block(holder,"BayCard",V(25,5,.7),o*CFrame.new(C.BayX[bay],1.8,-19)*CFrame.Angles(math.rad(-60),0,0),blue,{})
			face.CanCollide=false face.CanTouch=false face.CanQuery=false
			local text=label(face,"BAY "..bay.."\nEmpty")
			plot.bays[bay]={model=holder,origin=cf,label=text,prompt=P.prompt(face,"Manage","Working bay "..bay)}
		end
		for _,spec in {
			{id="Roll",x=22,z=45,color=Color3.fromRGB(162,97,228),text="ROLL A CRUSHER\n$"..C.RollCost},
			{id="Collect",x=-24,z=0,color=blue,text="COLLECT SCRAP\n$0 ready"},
			{id="Sell",x=-32,z=36,color=green,text="SELL CARRIED SCRAP\nInstant cash"},
			{id="Production",x=-35,z=16,color=blue,text="PRODUCTION UPGRADES\nDamage / Speed / Scrap yield"},
			{id="Rolling",x=35,z=16,color=Color3.fromRGB(162,97,228),text="ROLLING UPGRADES\nLuck / Rolling speed"},
		} do
			local cf=o*CFrame.new(spec.x,0,spec.z)
			local frame=Instance.new("Model") frame.Name=spec.id.."Station" frame.Parent=m
			Build.block(frame,"Foot",V(24,.4,10),cf*CFrame.new(0,.2,0),navy)
			for _,x in {-10,10} do Build.block(frame,"Post",V(1.4,8,1.4),cf*CFrame.new(x,4,0),navy,{}) end
			local face=Build.block(frame,"Panel",V(25,10,1),cf*CFrame.new(0,9,0),spec.color,{})
			local station={label=label(face,spec.text),prompt=P.prompt(face,if spec.id=="Production" or spec.id=="Rolling" then "Upgrades" else spec.id,spec.id.." station")}
			if spec.id=="Collect" then
				for _,x in {-9,9} do local side=Build.block(frame,"BinSide",V(1,4,9),cf*CFrame.new(x,2,5),blue,{}) side.CanCollide=false side.CanTouch=false side.CanQuery=false end
				for _,z in {.5,9.5} do local edge=Build.block(frame,"BinEnd",V(19,4,1),cf*CFrame.new(0,2,z),blue,{}) edge.CanCollide=false edge.CanTouch=false edge.CanQuery=false end
				local fill=Build.block(frame,"StoredScrap",V(15,2.3,6),cf*CFrame.new(0,1.3,5),Color3.fromRGB(152,172,190),{}) fill.CanCollide=false fill.CanQuery=false fill.CanTouch=false station.fill=fill
			end
			plot.stations[spec.id]=station
			for _,part in frame:GetDescendants() do if part:IsA("BasePart") then part.CanCollide=false part.CanTouch=false part.CanQuery=false end end
		end
		m.Parent=root Moat.build(m,o) table.insert(Plots.all(),plot)
	end
end
return P
