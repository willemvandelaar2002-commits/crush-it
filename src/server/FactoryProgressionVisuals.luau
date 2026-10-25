--!strict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.CrusherConfig)
local P=require(RS.Shared.FactoryProgression)
local Style=require(RS.Shared.Kit.Style)
local Format=require(RS.Shared.Format)
local W=require(script.Parent.Kit.CrusherWorkshop)
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
	local extension=Instance.new("Model") extension.Name="RearExpansion" extension.Parent=root
	local o=plot.origin
	local floor=W.part(extension,"ExpansionDeck",Vector3.new(70,2,24),o*CFrame.new(0,-1,-42),Style.theme("Island").platform,true)
	Style.studs(floor)
	for _,x in {-35,35} do W.part(extension,"ExpansionSide",Vector3.new(.8,1,24),o*CFrame.new(x,.5,-42),W.Navy,true) end
	W.part(extension,"ExpansionRearTrim",Vector3.new(70,1,.8),o*CFrame.new(0,.5,-54),Style.Colors.Gold,true)
	for _,x in {-32,32} do W.lamp(extension,o*CFrame.new(x,0,-50),3) end
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
		for _,side in {-1,1} do W.part(m,"BoardPost",Vector3.new(.8,5,.8),cf*CFrame.new(side*(width/2-.5),2.5,0),W.Navy) end
		local face,gui=W.panel(m,cf*CFrame.new(0,6,0),width,height,color)
		local content=Instance.new("Frame") content.Name="Content" content.Size=UDim2.fromScale(1,1) content.BackgroundTransparency=1 content.Parent=gui
		Style.panel(content,color,Style.darken(color,.25))
		return {model=m,part=face,content=content,frame=cf}
	end
	local upgrade=board("PlotUpgradeStation",-22,15,16,7,Style.Colors.Green)
	W.text(upgrade.content,"Heading","UPGRADE PLOT",UDim2.fromScale(.03,.03),UDim2.fromScale(.94,.22))
	upgrade.info=W.text(upgrade.content,"Benefits","+6 BAYS · NEW ROW · COATING LAB",UDim2.fromScale(.03,.28),UDim2.fromScale(.94,.23))
	upgrade.button=W.button(upgrade.content,"UpgradePlot","",UDim2.fromScale(.12,.58),UDim2.fromScale(.76,.33),"UpgradePlot")
	local lab=board("CoatingLab",22,15,18,10,Style.Colors.Purple)
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
	plot.progression={extension=extension,accents=accents,upgrade=upgrade,lab=lab,gateParts={},levelText=levelText}
	local rear=C.Layout.BayZ-C.Layout.UpperBack-C.Layout.BayDepth/2-4
	for _,p in plot.model:GetDescendants() do if p:IsA("BasePart") and p.Name=="RimBlock" then
		local at=o:PointToObjectSpace(p.Position)
		if math.abs(at.Z-(rear+1))<.2 and math.abs(at.X)<8 then table.insert(plot.progression.gateParts,p) end
	end end
	show(extension,false) show(accents,false) show(upgrade.model,false) show(lab.model,false)
	upgrade.content.Visible=false lab.content.Visible=false
end
function V.sync(plot,d,quote,now,preview)
	local v=plot.progression if not v then return end
	local level=if d then P.level(d) else 0
	local expanded=level>=1
	local boardVisible=d and (expanded or P.full(d)) or false
	local signature=tostring(expanded)..":"..tostring(boardVisible)
	if v.signature~=signature then
		v.signature=signature show(v.extension,expanded) show(v.accents,expanded)
		show(v.upgrade.model,boardVisible) v.upgrade.content.Visible=boardVisible
		show(v.lab.model,expanded) v.lab.content.Visible=expanded
		for _,part in v.gateParts do
			part.Transparency=if expanded then 1 else 0 part.CanCollide=not expanded part.CanQuery=not expanded
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
		success=if level==0 then "FACTORY II!" else "FACTORY III!"}
	W.purchase(v.upgrade.button,view)
	v.upgrade.info.Text=if maxed then C.MaxBays.." BAYS · 3 FLOORS · TOP CAPS"
		elseif level==1 then "+12 BAYS · 3RD FLOOR · HIGHER LV CAPS"
		else "+6 BAYS · COATING LAB · HIGHER LV CAPS"
	if d then v.levelText.Text=C.PlotUpgrade.Names[math.max(1,level)] end
	local valid=quote and now<quote.expires
	v.lab.info.Text=if valid then preview else "Hold an unequipped crusher. Select a finish to preview."
	W.purchase(v.lab.button,{state=if not valid then "Max" elseif d.cash>=quote.cost then "Ready" else "Short",cost=if valid then quote.cost else 0,
		button=if valid then "CONFIRM "..string.upper(quote.target).." · "..Format.cash(quote.cost) else "SELECT A FINISH",
		hint="Hold your crusher and review a coating first.",success="COATING APPLIED!"})
end
return V
