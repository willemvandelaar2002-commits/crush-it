--!strict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.CrusherConfig)
local P=require(RS.Shared.FactoryProgression)
local Style=require(RS.Shared.Kit.Style)
local Format=require(RS.Shared.Format)
local W=require(script.Parent.Kit.CrusherWorkshop)
local Build=require(script.Parent.Kit.Build)
local World=require(RS.Shared.Config).World
local Stages=require(script.Parent.PlotStages)
local Assets=require(script.Parent.PlotAssets)
-- Coating booth (Willem's Blender model) beside the Coating Lab board, front
-- toward the entrance. One colour version per plot level; the base one is the
-- fallback. The board stays the input; the booth is a visual (CoatingFx.client
-- plays its animation after a confirmed coating).
local BOOTH_AT=CFrame.new(42,0,19)*CFrame.Angles(0,math.pi,0) -- LookVector = +Z
local BOOTH_VERSIONS={"CoatingMachine","CoatingMachine_Plot3Orange","CoatingMachine_Plot4Silver","CoatingMachine_Plot5Gold"}
local function boothName(level)
	for i=math.clamp(level,1,#BOOTH_VERSIONS),1,-1 do
		if Assets.template(BOOTH_VERSIONS[i]) then return BOOTH_VERSIONS[i] end
	end
	return nil
end
local V={}
local function show(model,visible)
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then
		if p:GetAttribute("ProgressT")==nil then p:SetAttribute("ProgressT",p.Transparency) p:SetAttribute("ProgressC",p.CanCollide) p:SetAttribute("ProgressQ",p.CanQuery) end
		p.Transparency=if visible then p:GetAttribute("ProgressT") else 1
		p.CanCollide=visible and p:GetAttribute("ProgressC") p.CanQuery=visible and p:GetAttribute("ProgressQ")
	end end
end
function V.create(plot)
	local root=Instance.new("Model") root.Name="FactoryProgression" root.Parent=plot.model
	local o=plot.origin
	-- Factory III rear yard behind the wings: island body, studded floor, rim,
	-- lamps and the road running on from the plot (its banks are in CrusherPlots)
	local plotRear=C.Layout.BayZ-C.Layout.UpperBack-C.Layout.BayDepth/2-4 -- back edge of the plot floor
	local yard=Instance.new("Model") yard.Name="RearYard" yard.Parent=root
	local F=156 local half=F/2 local yardBack=C.Layout.BayZ+C.Layout.RearShift-C.Layout.UpperBack-C.Layout.BayDepth/2-6
	local yardDepth=plotRear-yardBack
	Build.island(yard,o*CFrame.new(0,0,(plotRear+yardBack)/2),F,yardDepth,World.SeaY,
		{dirt=Color3.fromRGB(25,43,73),stone=Color3.fromRGB(46,84,156),stoneDark=Color3.fromRGB(25,43,73)},{rng=Random.new(77),curb=false,rocks=false})
	local platform=Style.theme("Island").platform
	local floor=W.part(yard,"YardFloor",Vector3.new(F,2,yardDepth),o*CFrame.new(0,-1,(plotRear+yardBack)/2),platform,true)
	Style.studs(floor)
	W.walkway(yard,o,C.Layout.RoadHalf*2,yardBack+4,plotRear)
	local light=Color3.fromRGB(78,140,232)
	local function rim(a,b,fixed,alongX)
		local len=b-a local n=math.max(1,math.floor(len/6+.5)) local seg=len/n
		for i=0,n-1 do
			local mid=a+seg*(i+.5)
			local pos=if alongX then CFrame.new(mid,.8,fixed) else CFrame.new(fixed,.8,mid)
			local block=W.part(yard,"RimBlock",if alongX then Vector3.new(seg-.2,1.6,2) else Vector3.new(2,1.6,seg-.2),o*pos,if i%2==0 then W.Blue else light,true)
			Style.materialStuds(block,true,{Enum.NormalId.Top},2)
		end
	end
	rim(-half+1,half-1,yardBack+1,true)
	for _,x in {-half+1,half-1} do
		rim(yardBack+2,plotRear,x,false)
		W.part(yard,"RimCorner",Vector3.new(2.6,2.2,2.6),o*CFrame.new(x,1.1,yardBack+1),W.Navy,true)
		W.lamp(yard,o*CFrame.new(x,2.2,yardBack+1),2.2)
	end
	-- Cosmetic finish appears with the upgrade, without enclosing the factory.
	local accents=Instance.new("Model") accents.Name="UpgradedPlotTrim" accents.Parent=root
	for _,x in {-7.75,7.75} do
		W.part(accents,"GoldGateTrim",Vector3.new(.25,7,.18),o*CFrame.new(x,3.5,89.08),Style.Colors.Gold)
	end
	local gate=W.part(accents,"FactoryLevelPlate",Vector3.new(8,1.4,.25),o*CFrame.new(0,10,89),W.Navy)
	for _,x in {-3,3} do W.part(accents,"LevelPlateStem",Vector3.new(.25,1.2,.25),o*CFrame.new(x,9.1,88.9),Style.Colors.Gold) end
	local levelText=W.text(W.sign(gate),"FactoryLevel","FACTORY II",UDim2.fromScale(.02,.02),UDim2.fromScale(.96,.96))
	for first=1,C.BaseMaxBays,C.Layout.PerWing do for _,bay in {first,first+C.Layout.PerWing-1} do
		local at=C.bayLayout(bay)
		local cap=W.part(accents,"FactoryCornerCap",Vector3.new(1.35,.6,1.5),o*C.wingFrame(at.side)*CFrame.new(at.x,at.y+C.Layout.TierHeight-1.3,at.z+C.Layout.BayDepth/2-.5),Style.Colors.Gold)
		cap.Material=Enum.Material.Metal
	end end
	local function board(name,x,z,width,height,color)
		local m=Instance.new("Model") m.Name=name m.Parent=root
		local cf=o*CFrame.new(x,0,z)*CFrame.Angles(0,if x<0 then .2 else -.2,0)
		for _,side in {-1,1} do W.part(m,"BoardPost",Vector3.new(.8,5,.8),cf*CFrame.new(side*(width/2-.5),2.5,0),W.Navy,true) end
		local face,gui=W.panel(m,cf*CFrame.new(0,6,0),width,height,color,true)
		local content=Instance.new("Frame") content.Name="Content" content.Size=UDim2.fromScale(1,1) content.BackgroundTransparency=1 content.Parent=gui
		Style.panel(content,color,Style.darken(color,.25))
		return {model=m,part=face,content=content,frame=cf}
	end
	local upgrade=board("PlotUpgradeStation",-22,15,16,7,Style.Colors.Green)
	W.text(upgrade.content,"Heading","UPGRADE PLOT",UDim2.fromScale(.03,.03),UDim2.fromScale(.94,.22))
	upgrade.info=W.text(upgrade.content,"Benefits","+6 BAYS · NEW ROW · COATING LAB",UDim2.fromScale(.03,.28),UDim2.fromScale(.94,.23))
	upgrade.button=W.button(upgrade.content,"UpgradePlot","",UDim2.fromScale(.12,.58),UDim2.fromScale(.76,.33),"UpgradePlot")
	-- Coating Lab: Willem's booth with a prompt that opens the coating screen
	-- (Coating.client); the old board only when the booth template is missing.
	local lab
	local boothVersion=boothName(1)
	if boothVersion then
		local m=Instance.new("Model") m.Name="CoatingLab" m.Parent=root
		lab={model=m}
		lab.booth=Assets.place(boothVersion,m,plot.origin*BOOTH_AT,{inset=.8})
	end
	if lab and lab.booth then
		lab.booth.Name="CoatingBooth" lab.booth:SetAttribute("Version",boothVersion)
		-- small part at the booth's front: prompt range and the server's reach check
		local front=W.part(lab.model,"CoatingPromptPart",Vector3.new(2,2,1),plot.origin*BOOTH_AT*CFrame.new(0,2.6,-5.6),W.Navy)
		front.Transparency=1 front.CanQuery=false
		local prompt=Instance.new("ProximityPrompt") prompt.Name="CoatingPrompt" prompt.ActionText="Coat a crusher"
		prompt.ObjectText="Coating Lab" prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.HoldDuration=0
		prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Enabled=false prompt.Parent=front
		lab.part=front lab.prompt=prompt
	else
		if lab then lab.model:Destroy() end
		lab=board("CoatingLab",22,15,18,10,Style.Colors.Purple)
		W.part(lab.model,"DispenserBase",Vector3.new(19,1,5),lab.frame*CFrame.new(0,.5,-.3),W.Navy)
		for i,recipe in C.Coatings do
			local x=(i-2.5)*4
			local tank=W.part(lab.model,"FinishCartridge",Vector3.new(2,1.6,1.6),lab.frame*CFrame.new(x,11.8,-.5)*CFrame.Angles(0,0,math.pi/2),recipe.color)
			tank.Shape=Enum.PartType.Cylinder
			W.part(lab.model,"CartridgeCap",Vector3.new(1.8,.25,1.8),lab.frame*CFrame.new(x,12.9,-.5),W.Navy)
		end
		W.text(lab.content,"Heading","COATING LAB",UDim2.fromScale(.03,.02),UDim2.fromScale(.94,.13))
		lab.info=W.text(lab.content,"Preview","Hold a crusher, then select a finish.",UDim2.fromScale(.04,.16),UDim2.fromScale(.92,.19))
		for i,recipe in C.Coatings do
			local x=if i%2==1 then .03 else .52 local y=if i<=2 then .38 else .59
			local b=W.button(lab.content,recipe.name,recipe.name.." x"..C.modifier(recipe.name).mult,UDim2.fromScale(x,y),UDim2.fromScale(.45,.17),"QuoteCoating",recipe.name)
			Style.setButtonColor(b,recipe.color)
		end
		lab.button=W.button(lab.content,"ApplyCoating","SELECT A FINISH",UDim2.fromScale(.1,.81),UDim2.fromScale(.8,.16),"ApplyCoating")
	end
	plot.progression={yard=yard,accents=accents,upgrade=upgrade,lab=lab,gateParts={},levelText=levelText}
	-- the plot's rear rim opens onto the rear yard
	for _,p in plot.model:GetDescendants() do if p:IsA("BasePart") and (p.Name=="RimBlock" or p.Name=="RimCorner" or p.Name=="LampPost" or p.Name=="LampLight" or p.Name=="LampCap") and p.Parent and p.Parent.Name=="PlotBorder" then
		local at=o:PointToObjectSpace(p.Position)
		if math.abs(at.Z-(plotRear+1))<.2 then p:SetAttribute("RimX",at.X) table.insert(plot.progression.gateParts,p) end
	end end
	Stages.create(plot)
	show(yard,false) show(accents,false) show(upgrade.model,false) show(lab.model,false)
	upgrade.content.Visible=false if lab.content then lab.content.Visible=false end
end
function V.sync(plot,d,quote,now,preview)
	local v=plot.progression if not v then return end
	local level=if d then P.level(d) else 0
	local expanded=level>=1
	local boardVisible=d and (expanded or P.full(d)) or false
	Stages.sync(plot,level)
	local yardOpen=level>=2
	local signature=tostring(level)..":"..tostring(boardVisible)
	if v.signature~=signature then
		v.signature=signature show(v.yard,yardOpen) show(v.accents,expanded)
		show(v.upgrade.model,boardVisible) v.upgrade.content.Visible=boardVisible
		-- booth colour follows the plot level (orange, silver, gold versions)
		local want=if v.lab.booth then boothName(math.max(level,1)) else nil
		if want and v.lab.booth:GetAttribute("Version")~=want then
			v.lab.booth:Destroy()
			v.lab.booth=Assets.place(want,v.lab.model,plot.origin*BOOTH_AT,{inset=.8})
			if v.lab.booth then v.lab.booth.Name="CoatingBooth" v.lab.booth:SetAttribute("Version",want) end
		end
		show(v.lab.model,expanded)
		if v.lab.content then v.lab.content.Visible=expanded end
		if v.lab.prompt then v.lab.prompt.Enabled=expanded end
		for _,part in v.gateParts do
			local open=yardOpen
			part.Transparency=if open then 1 else 0 part.CanCollide=not open part.CanQuery=not open
		end
	end
	-- next upgrade: Factory II (+6 rear bays), then Factory III (third floor), then complete
	local maxed=level>=C.PlotUpgrade.MaxLevel
	local cost=if maxed then 0 else C.plotCost(level+1)
	local full=d~=nil and P.full(d)
	local state=if maxed then "Max" elseif not full then "Short" elseif d.cash>=cost then "Ready" else "Short"
	local name=C.PlotUpgrade.Names[math.min(level+1,C.PlotUpgrade.MaxLevel)]
	local view={state=state,cost=cost,
		button=if maxed then C.PlotUpgrade.Names[C.PlotUpgrade.MaxLevel].." · COMPLETE" else name.."\n"..Format.cash(cost),
		hint=if full then "Collect and sell scrap for more cash." else "Fill all "..C.bayCapacity(level).." bays with crushers, then upgrade your plot.",
		success=name.."!"}
	W.purchase(v.upgrade.button,view)
	v.upgrade.info.Text=if maxed then C.MaxBays.." BAYS · MASTER FACTORY"
		elseif level==0 then "+12 BAYS · 3RD FLOOR · COATING LAB"
		elseif level==1 then "+12 BAYS · REAR YARD · FUSION MACHINE"
		elseif level==2 then "+6 BAYS · REAR UPPER LEFT · HIGHER LV CAPS"
		else "+6 BAYS · REAR UPPER RIGHT · HIGHER LV CAPS"
	if d then v.levelText.Text=C.PlotUpgrade.Names[math.max(1,level)] end
	if not v.lab.info then return end -- booth: the coating screen shows the preview
	local valid=quote and now<quote.expires
	v.lab.info.Text=if valid then preview else "Hold an unequipped crusher. Select a finish to preview."
	W.purchase(v.lab.button,{state=if not valid then "Max" elseif d.cash>=quote.cost then "Ready" else "Short",cost=if valid then quote.cost else 0,
		button=if valid then "CONFIRM "..string.upper(quote.target).." · "..Format.cash(quote.cost) else "SELECT A FINISH",
		hint="Hold your crusher and review a coating first.",success="COATING APPLIED!"})
end
return V
