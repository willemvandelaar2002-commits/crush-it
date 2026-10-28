--!strict
-- Local bounded cosmetics. Production and inventory continue on the server.
local RS=game:GetService("ReplicatedStorage")
local Tags=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local E=require(RS.Shared.FactoryEventConfig)
local Motion=require(RS.Shared.FactoryEventMotion)
local C=require(RS.Shared.CrusherConfig)
local V=Vector3.new
local INK=Color3.fromRGB(19,23,42)
local GOLD=Color3.fromRGB(255,211,45)
local PURPLE=Color3.fromRGB(173,65,255)
local RED=Color3.fromRGB(255,55,85)
local CYAN=Color3.fromRGB(62,235,255)
local function part(parent,name,size,cf,color,shape,neon)
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
	p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
	p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if shape then p.Shape=shape end p.Parent=parent return p
end
local BearRig=require(RS.Shared.FactoryBearRig)
local Players=game:GetService("Players")
local me=Players.LocalPlayer
local function bearTemplate()
	local library=RS:FindFirstChild("FactoryEventMeshes")
	local t=library and library:FindFirstChild("FactoryBear")
	return if t and t:IsA("Model") and t:GetAttribute("FactoryBearReady")==true then t else nil
end
local function core(parent,origin,scale)
	-- 28 Oct: the bear's own reactor + ring when the Factory Bear template is in
	local template=bearTemplate()
	if template then
		local ok,m=pcall(BearRig.core,template,origin,5.25*scale)
		if ok and m then
			m.Name="CorruptedCore" m.Parent=parent
			local light=Instance.new("PointLight") light.Color=PURPLE light.Range=8*scale+6 light.Brightness=1.5 light.Parent=m:FindFirstChild("Core")
			return {model=m,template=true,base=m:GetScale(),origin=origin,scale=scale,heart=m:FindFirstChild("Core"),shell=m:FindFirstChild("CoreRing"),bands={}}
		end
	end
	local m=Instance.new("Model") m.Name="CorruptedCore" m.Parent=parent
	local shell=part(m,"CoreShell",V(5.25,5.25,4.75)*scale,origin,Color3.fromRGB(119,40,205),Enum.PartType.Ball,true)
	local heart=part(m,"PurpleHeart",V(4.75,4.75,5.2)*scale,origin,PURPLE,Enum.PartType.Ball,true)
	local bands={}
	for _,a in {0,math.pi/2,math.pi/4} do
		table.insert(bands,part(m,"CoreBand",V(.42,5.35,5.35)*scale,origin*CFrame.Angles(a,0,.3),GOLD,Enum.PartType.Cylinder))
	end
	return {model=m,shell=shell,heart=heart,bands=bands,origin=origin,scale=scale}
end
local function superPress(parent,r)
	local model=Instance.new("Model") model.Name="SuperCrusher_"..r.userId model.Parent=parent
	local o=r.origin*CFrame.new(E.VisualOrigin)
	local color=(C.rarity(r.dominant) or C.Rarities[1]).color
	local moving={} local rotors={} local all={}
	local S=E.SuperScale
	local function box(name,size,x,y,z,paint,move,shape,neon)
		local p=part(model,name,size*S,o*CFrame.new(x*S,y*S,z*S),paint,shape,neon)
		table.insert(all,{part=p,rest=p.CFrame})
		if move then table.insert(moving,{part=p,rest=p.CFrame}) end
		return p
	end
	box("NavyPlinth",V(18,2,14),0,1,0,INK)
	box("ColouredBed",V(17,1,13),0,2.3,0,color)
	box("Anvil",V(12,1,9),0,3.2,0,GOLD)
	for _,side in {-1,1} do
		box("Tower",V(3.2,20,9),side*7.2,12,0,INK)
		box("TowerFace",V(2.4,17,.35),side*7.2,12,4.7,color)
		box("NeonGauge",V(.4,11,.4),side*7.2,12,5,CYAN,nil,nil,true)
		box("FootCap",V(3.7,1,10),side*7.2,3.5,0,GOLD)
		for _,z in {-3.5,3.5} do
			box("ChromeGuide",V(.65,18,.65),side*5.15,12,z,Color3.fromRGB(220,235,255))
		end
	end
	box("BeamOutline",V(19,3.8,10),0,22,0,INK)
	box("GlossyBeam",V(18,2.8,.35),0,22.1,5.05,color)
	box("BeamHighlight",V(17,.25,9.2),0,24.05,0,Color3.fromRGB(255,239,184))
	box("RamOutline",V(11,3.2,9),0,15.8,0,INK,true)
	box("RamFace",V(10.3,2.4,.35),0,15.8,4.6,color,true)
	box("CrushingPlate",V(12,.8,9.5),0,13.8,0,GOLD,true)
	-- Diagonal navy hazard stripes on the front of the gold crushing plate.
	for x=-5,5,2 do
		local p=box("HazardStripe",V(.8,.8,.16),x,13.8,4.85,INK,true)
		p.CFrame*=CFrame.Angles(0,0,-.4)
		moving[#moving].rest=p.CFrame all[#all].rest=p.CFrame
	end
	local shafts={}
	for _,x in (if r.grade>=2 then {-2.6,2.6} else {0}) do
		box("HydraulicHousing",V(3.3,5,3.3),x,24,0,color,nil,Enum.PartType.Ball)
		local p=box("ExtendingRod",V(1.25,4,1.25),x,19.3,0,Color3.fromRGB(225,237,252))
		table.insert(shafts,{part=p,top=21.3*S,x=x*S})
	end
	if r.grade>=3 then
		for _,side in {-1,1} do
			box("ShoulderArmour",V(4,5,10),side*7.3,19,0,color)
			box("ReactorMount",V(3.6,3.6,.7),side*7.3,19,5.3,INK)
			local p=box("SpinningReactor",V(2.6,2.6,.8),side*7.3,19,5.4,GOLD,nil,Enum.PartType.Ball,true)
			table.insert(rotors,{part=p,rest=p.CFrame})
		end
	end
	if r.grade>=4 then
		for _,x in {-5,5} do
			box("AuxiliaryCylinder",V(2.3,4,2.3),x,25,0,INK)
			box("CylinderBeacon",V(2.4,.6,2.4),x,27,0,CYAN,nil,nil,true)
		end
		box("CrownedBeam",V(14,1.6,5),0,25,0,GOLD)
	end
	if r.grade>=5 then
		box("ReactorCrown",V(4,4,4),0,27,0,PURPLE,nil,Enum.PartType.Ball,true)
		for _,x in {-4,0,4} do
			box("ExtraCrushingHead",V(2.6,1.4,7),x,12.8,0,GOLD,true)
			box("PoweredTooth",V(1.8,.6,.35),x,12.6,3.6,CYAN,true,nil,true)
		end
	end
	local heart=core(model,o*CFrame.new(0,6.5*S,0),S)
	local source=part(model,"EnergySource",V(.1,.1,.1),o*CFrame.new(0,22*S,0),CYAN)
	source.Transparency=1
	local sparks={}
	local slots=r.slots or {}
	for i=1,math.min(8,#slots) do
		local slot=slots[math.ceil(i*#slots/math.min(8,#slots))]
		local l=C.bayLayout(slot)
		local from=(r.origin*C.bayFrame(l)*CFrame.new(l.x,l.y+7,l.z)).Position
		local p=part(model,"AssemblyEnergy",V(.9,.9,.9),CFrame.new(from),color,Enum.PartType.Ball,true)
		p.Transparency=1 table.insert(sparks,{part=p,from=from})
	end
	return {model=model,origin=o,moving=moving,all=all,shafts=shafts,rotors=rotors,core=heart,
		source=source,sparks=sparks,color=color,record=r}
end
local Visuals={}
Visuals.__index=Visuals
function Visuals.new()
	local self=setmetatable({},Visuals)
	self.folder=Instance.new("Folder") self.folder.Name="LocalFactoryEvent" self.folder.Parent=workspace
	self.rigs={} self.hidden={} self.disabled={} self.marked={} self.packet=nil self.roundId=nil self.central=nil
	return self
end
function Visuals:restoreMasks()
	for p,old in self.hidden do if p.Parent then p.LocalTransparencyModifier=old end end
	for p,old in self.disabled do if p.Parent then p.Enabled=old end end
	for plot in self.marked do if plot.Parent then plot:SetAttribute("LocalEventHidden",nil) end end
	for p,was in self.solid or {} do if p.Parent then p.CanCollide=was[1] p.CanQuery=was[2] end end
	self.solid={} self.zoned={}
	self.hidden={} self.disabled={}
	self.marked={}
end
function Visuals:hide(root,withSelf)
	local list=root:GetDescendants() if withSelf then table.insert(list,root) end
	for _,p in list do
		if p:IsA("BasePart") then
			if self.hidden[p]==nil then self.hidden[p]=p.LocalTransparencyModifier end
			p.LocalTransparencyModifier=1
			-- no invisible walls/stairs (local: your own character's physics)
			if p.CanCollide or p.CanQuery then
				self.solid=self.solid or {}
				if self.solid[p]==nil then self.solid[p]={p.CanCollide,p.CanQuery} end
				p.CanCollide=false p.CanQuery=false
			end
		elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Light") or p:IsA("SurfaceGui") or p:IsA("BillboardGui") or p:IsA("ProximityPrompt") then
			if self.disabled[p]==nil then self.disabled[p]=p.Enabled end p.Enabled=false
		end
	end
end
-- Night for the event (local): from the intro's flash until the round ends the
-- sky goes dark purple with stars and the hall's light dims; all restored after.
local NIGHT={ClockTime=0.3,Brightness=2.2,Ambient=Color3.fromRGB(125,95,165),OutdoorAmbient=Color3.fromRGB(140,105,190),
	ExposureCompensation=0.15,EnvironmentDiffuseScale=0.6,EnvironmentSpecularScale=0.5}
function Visuals:darkSky(packet)
	local age=workspace:GetServerTimeNow()-packet.started
	local want=packet.phase~="Announce" or age>=2.6
	if want and not self.night then
		local saved={props={},kids={}}
		for k,v in NIGHT do saved.props[k]=Lighting[k] end
		for _,c in Lighting:GetChildren() do
			if c:IsA("Sky") or c:IsA("Atmosphere") then table.insert(saved.kids,c) c.Parent=nil end
		end
		local sky=Instance.new("Sky") sky.Name="BearEventSky" sky.StarCount=4000 sky.CelestialBodiesShown=false sky.Parent=Lighting
		local atmo=Instance.new("Atmosphere") atmo.Name="BearEventAtmosphere" atmo.Density=.22 atmo.Color=Color3.fromRGB(120,60,190)
		atmo.Decay=Color3.fromRGB(60,20,110) atmo.Glare=0 atmo.Haze=1.6 atmo.Parent=Lighting
		saved.sky=sky saved.atmo=atmo
		game:GetService("TweenService"):Create(Lighting,TweenInfo.new(.6),NIGHT):Play()
		self.night=saved
	end
end
function Visuals:restoreSky()
	local s=self.night if not s then return end self.night=nil
	s.sky:Destroy() s.atmo:Destroy()
	for _,c in s.kids do c.Parent=Lighting end
	game:GetService("TweenService"):Create(Lighting,TweenInfo.new(1.2),s.props):Play()
end
function Visuals:clear()
	self:restoreMasks()
	self:restoreSky()
	if self.bear and self.bear.ready then
		-- the event bear goes, the normal teddy comes back (with a puff)
		for _,p in self.bear.teddyParts do if p.Parent then p.LocalTransparencyModifier=0 end end
		if self.teddyModel and self.teddyModel.Parent and self.teddyRest then local s0=self.teddyScale or 1 if self.teddyModel:GetScale()~=s0 then self.teddyModel:ScaleTo(s0) end self.teddyModel:PivotTo(self.teddyRest) end
		local puff=part(workspace,"TeddyReturnPuff",V(1,1,1),CFrame.new(self.bear.bottom+V(0,10,0)),PURPLE) puff.Transparency=1
		local e=self.bear.smoke:Clone() e.Parent=puff e:Emit(40)
		game:GetService("Debris"):AddItem(puff,3)
	end
	self.teddyModel=nil self.teddyRest=nil self.teddyBox=nil self.teddyScale=nil
	self.hazards={} self.flyers=nil
	self.folder:ClearAllChildren() self.rigs={} self.central=nil self.bear=nil
	if self.tint then self.tint:Destroy() self.tint=nil end
end
local function findMega()
	for _,m in Tags:GetTagged("MegaCrusher") do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			local ram=m:FindFirstChild("Ram")
			if ram and ram:IsA("BasePart") and type(m:GetAttribute("BedTop"))=="number" then return m,ram end
		end
	end
	return nil,nil
end
function Visuals:centralRig(mega,ram)
	local bed=mega:GetAttribute("BedTop")
	local o=CFrame.new(ram.Position.X,bed,ram.Position.Z)*mega:GetPivot().Rotation
	local folder=Instance.new("Folder") folder.Name="MegaTransformation" folder.Parent=self.folder
	local width=math.clamp(ram.Size.X,10,28)
	local rest=mega:GetAttribute("RestY") or ram.Position.Y
	local room=math.max(1,(rest-ram.Size.Y/2)-bed)
	local scale=math.min(width*.55/5,room*.65/5)
	local heart=core(folder,o*CFrame.new(0,scale*2.6,0),scale)
	local shield=part(folder,"CoreShield",V(6,6,6)*scale,heart.origin,CYAN,Enum.PartType.Ball,true)
	shield.Transparency=.72
	local panels={}
	for _,side in {-1,1} do
		local cf=o*CFrame.new(side*(width/2+4),room+4,0)
		local p=part(folder,"UnfoldingArmour",V(5,8,10),cf,INK)
		local face=part(folder,"ArmourPaint",V(4.4,7,.3),cf*CFrame.new(0,.2,5.2),GOLD)
		table.insert(panels,{part=p,rest=cf,side=side})
		table.insert(panels,{part=face,rest=face.CFrame,side=side})
		local housing=part(folder,"AuxiliaryHydraulic",V(3.4,10,3.4),o*CFrame.new(side*(width/2+7),room*.65,0),PURPLE)
		table.insert(panels,{part=housing,rest=housing.CFrame,side=side})
	end
	local reactor=part(folder,"Reactor",V(5,5,2),o*CFrame.new(0,room+9,6),CYAN,Enum.PartType.Ball,true)
	return {model=mega,ram=ram,folder=folder,origin=o,core=heart,shield=shield,panels=panels,reactor=reactor,
		reactorRest=reactor.CFrame,scale=scale,room=room,burst=nil}
end
-- The normal teddy (server, World) and where it stands.
local teddyOriginal=setmetatable({},{__mode="k"})
local function teddy()
	local bear=workspace:FindFirstChild("FactoryTeddy",true)
	return if bear and bear:IsA("Model") then bear else nil
end
function Visuals:bearSpot()
	local bear=self.teddyModel or teddy()
	if not bear then return nil end
	local cf,size
	if self.teddyBox then cf,size=self.teddyBox,self.teddySize else cf,size=bear:GetBoundingBox() end
	return {bottom=cf.Position-V(0,size.Y/2,0),head=cf.Position+V(0,size.Y*.25,0),height=size.Y,width=size.X}
end
function Visuals:bearRig()
	local bear=teddy()
	if not bear then return nil end
	-- 28 Oct: the rigged Factory Bear is only the EVENT bear. A local copy stands
	-- in the teddy's place for the round; the teddy itself is hidden (or rises
	-- away during the intro) and comes back afterwards.
	local template=bearTemplate()
	if template then
		-- measured once per teddy (never mid-shrink); the place builds it at scale 4
		local orig=teddyOriginal[bear]
		if not orig then
			local bcf,bsize=bear:GetBoundingBox()
			orig={pivot=bear:GetPivot(),scale=bear:GetScale(),box=bcf,size=bsize} teddyOriginal[bear]=orig
		end
		local cf,size=orig.box,orig.size
		self.teddyModel=bear self.teddyRest=orig.pivot self.teddyBox=cf self.teddySize=size self.teddyScale=orig.scale
		local copy=template:Clone() copy.Name="EventFactoryBear"
		local _,own=copy:GetBoundingBox()
		copy:ScaleTo(copy:GetScale()*size.Y/own.Y)
		local bottom=cf.Position-V(0,size.Y/2,0)
		local facing=V(-bottom.X,0,-bottom.Z).Unit -- the teddy faces the middle of the hall
		copy:PivotTo(CFrame.lookAt(bottom,bottom+facing))
		copy.Parent=self.folder
		local ok,rig=pcall(BearRig.capture,copy)
		if ok then
			local parts={} for _,p in copy:GetDescendants() do if p:IsA("BasePart") then table.insert(parts,p) end end
			local teddyParts={} for _,p in bear:GetDescendants() do if p:IsA("BasePart") then table.insert(teddyParts,p) end end
			-- purple smoke for the change, and a landing ring
			local smoke=part(self.folder,"TransformSmoke",V(size.X,2,size.X),CFrame.new(bottom+V(0,4,0)),PURPLE) smoke.Transparency=1
			local emitter=Instance.new("ParticleEmitter") emitter.Color=ColorSequence.new(Color3.fromRGB(150,60,255),Color3.fromRGB(60,20,120))
			emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,10),NumberSequenceKeypoint.new(1,26)})
			emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)})
			emitter.Lifetime=NumberRange.new(1.6,2.6) emitter.Speed=NumberRange.new(10,22) emitter.SpreadAngle=Vector2.new(70,70)
			emitter.Rate=0 emitter.LightEmission=.4 emitter.Parent=smoke
			return {model=copy,folder=Instance.new("Folder"),ready=true,rig=rig,parts=parts,teddyParts=teddyParts,
				smoke=emitter,bottom=bottom,height=size.Y,ring=nil}
		end
		copy:Destroy()
		warn("[FactoryEvent] Factory Bear rig: "..tostring(rig))
	end
	local folder=Instance.new("Folder") folder.Name="EvilBearAura" folder.Parent=self.folder
	local cf,size=bear:GetBoundingBox()
	local pivot=bear:GetPivot()
	local eyes={}
	-- Named eyes are exact for the procedural fallback and separated imported rigs.
	for _,p in bear:GetDescendants() do
		if p:IsA("BasePart") and p.Name:lower():match("eye") and not p.Name:lower():match("glint") then
			table.insert(eyes,part(folder,"RedEye",p.Size*1.08,p.CFrame,RED,Enum.PartType.Ball,true))
		end
	end
	-- If the import has one combined mesh, put an evil floating mask just in
	-- front of its measured head. This overlay never edits the place template.
	if #eyes==0 then
		-- measured on the place's TeddyBear_Details mesh (27 Oct): eyes sit on the
		-- face surface, a little above the head's middle
		local head=cf.Position+V(0,size.Y*.285,0)
		local forward=pivot.LookVector
		for _,side in {-1,1} do
			local at=head+pivot.RightVector*side*size.X*.12+forward*size.Z*.47
			table.insert(eyes,part(folder,"RedEye",V(size.X*.13,size.X*.13,size.Z*.06),CFrame.new(at)*pivot.Rotation,RED,Enum.PartType.Ball,true))
		end
	end
	local halo=part(folder,"CorruptionHalo",V(.5,size.X*.7,size.X*.7),CFrame.new(cf.Position+V(0,size.Y*.52,0))*CFrame.Angles(0,0,math.pi/2),PURPLE,Enum.PartType.Cylinder,true)
	halo.Transparency=.3
	-- a dark purple glow around the whole bear while it's corrupted
	local glow=Instance.new("Highlight") glow.Name="CorruptionGlow" glow.Adornee=bear
	glow.FillColor=Color3.fromRGB(70,20,110) glow.FillTransparency=.45 glow.OutlineColor=Color3.fromRGB(255,60,200) glow.OutlineTransparency=0
	glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=folder
	return {model=bear,folder=folder,eyes=eyes,halo=halo,rest=halo.CFrame,glow=glow}
end
function Visuals:update(packet)
	if self.roundId~=packet.roundId then self:clear() self.roundId=packet.roundId end
	self.packet=packet
	-- Announce: only the corrupted bear and the shielded core under the Mega
	-- Crusher (for the intro cutscene); no super crushers, nothing hidden yet.
	local announce=packet.phase=="Announce"
	if not Motion.controls(packet.phase) and not announce then self:clear() return end
	self:darkSky(packet)
	if not self.tint then
		self.tint=Instance.new("ColorCorrectionEffect") self.tint.Name="BearEventTint"
		self.tint.TintColor=Color3.fromRGB(235,226,255) self.tint.Saturation=.06 self.tint.Parent=Lighting
	end
	local desired={}
	local camera=workspace.CurrentCamera
	local list=if announce then {} else table.clone(packet.participants)
	if camera then table.sort(list,function(a,b) return (a.origin.Position-camera.CFrame.Position).Magnitude<(b.origin.Position-camera.CFrame.Position).Magnitude end) end
	for i,r in list do
		if i<=E.MaxVisiblePlots and (not camera or (r.origin.Position-camera.CFrame.Position).Magnitude<E.VisualDistance) then
			desired[r.userId]=true
			local rig=self.rigs[r.userId]
			if not rig then rig=superPress(self.folder,r) self.rigs[r.userId]=rig end
			rig.record=r
		end
	end
	for id,rig in self.rigs do if not desired[id] then
		if rig.beamEnd then rig.beamEnd:Destroy() end
		rig.model:Destroy() self.rigs[id]=nil
	end end
	if self.central and not self.central.model:IsDescendantOf(workspace) then
		self.central.folder:Destroy() self.central=nil
		for _,rig in self.rigs do
			if rig.beam then rig.beam:Destroy() end
			rig.beam=nil rig.beamEnd=nil
		end
	end
	if not self.central then local m,ram=findMega() if m and ram then self.central=self:centralRig(m,ram) end end
	if self.bear and not self.bear.model:IsDescendantOf(workspace) then self.bear.folder:Destroy() self.bear=nil end
	if not self.bear then self.bear=self:bearRig() end
	-- Re-scan only on replicated updates, including freshly spawned production inputs.
	self:restoreMasks()
	for _,rig in self.rigs do
		local plot=workspace:FindFirstChild("Plot"..tostring(rig.record.plotIndex),true)
		if plot then
			plot:SetAttribute("LocalEventHidden",true) self.marked[plot]=true
			for _,child in plot:GetDescendants() do
				if child:IsA("Model") and child.Name=="EquippedCrusher" then self:hide(child) end
			end
			-- 28 Oct: the bays and row plaques go too once the crushers have flown
			-- off (their screens live in PlayerGui, adorned to the plaques)
			local bayAge=workspace:GetServerTimeNow()-packet.started
			if packet.phase~="Assemble" or bayAge>=E.Assemble*.4 then
				local roots={}
				for _,child in plot:GetChildren() do
					-- the whole crusher platform: bays, row plaques, the bank buildings
					-- with their floors/stairs/signs, and their trim braces
					if child:IsA("Model") and (child.Name:match("^WorkingBay%d+$") or child.Name:match("^RarityRow%d+$") or child.Name=="WorkshopBanks") then
						self:hide(child) roots[child]=true
					end
				end
				local trim=plot:FindFirstChild("TrimKit")
				local o=rig.record.origin
				if trim then for _,m in trim:GetChildren() do
					if m:IsA("Model") then
						local l=o:PointToObjectSpace(m:GetPivot().Position)
						if m.Name:match("^CornerBrace") or (m.Name:match("^BoardFrame") and l.Y>15) then self:hide(m) roots[m]=true end
					end
				end end
				-- 28 Oct: plot-stage upgrades decorate the platform too (stripes, gold
				-- caps/feet, walkway lights, corner caps, support beams): anything of
				-- PlotStages/FactoryProgression/TrimKit standing over the platform goes
				self.zoned=self.zoned or {}
				if not self.zoned[plot] then
					self.zoned[plot]=true
					local Z=E.PlatformZone
					for _,folderName in {"PlotStages","FactoryProgression","TrimKit"} do
						local f=plot:FindFirstChild(folderName)
						if f then for _,p in f:GetDescendants() do
							if p:IsA("BasePart") and not p.Parent.Name:match("^BoardFrame") then
								local l=o:PointToObjectSpace(p.Position)
								if math.abs(l.X)<Z.HalfWidth and l.Z>Z.Back and l.Z<Z.Front and l.Y>Z.Above then self:hide(p,true) end
							end
						end end
					end
				end
				for _,g in me.PlayerGui:GetDescendants() do
					if (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) and g.Adornee then
						for root in roots do
							if g.Adornee:IsDescendantOf(root) then
								if self.disabled[g]==nil then self.disabled[g]=g.Enabled end g.Enabled=false break
							end
						end
					end
				end
			end
		end
	end
	if self.central then local toy=self.central.model:FindFirstChild("Toy") if toy then self:hide(toy) end end
end
local function animateCore(c,now,shrink)
	if c.template then
		local pulse=1+.04*math.sin(now*5)
		local s=math.max(.01,c.base*shrink*pulse)
		if math.abs(c.model:GetScale()-s)>1e-3 then c.model:ScaleTo(s) end
		c.model:PivotTo(c.origin*CFrame.Angles(0,now*.8,0))
		return
	end
	local rotation=CFrame.Angles(now*.35,now*.8,0)
	local cf=c.origin*rotation
	c.shell.CFrame=cf c.heart.CFrame=cf
	local pulse=1+.04*math.sin(now*5)
	c.heart.Size=V(4.75,4.75,5.2)*c.scale*pulse*shrink
	c.shell.Size=V(5.25,5.25,4.75)*c.scale*shrink
	for i,p in c.bands do
		p.CFrame=cf*CFrame.Angles((i-1)*math.pi/3,0,now*.5)
		p.Size=V(.42,5.35,5.35)*c.scale*shrink
	end
end
function Visuals:step(now)
	local packet=self.packet if not packet or not (Motion.controls(packet.phase) or packet.phase=="Announce") then return end
	local age=now-packet.started
	local progress=if packet.maxHp>0 then 1-packet.hp/packet.maxHp else 0
	local recovery=if packet.phase=="Recover" then math.clamp(1-age/E.Recover,0,1) else 1
	for _,rig in self.rigs do
		local assembly=if packet.phase=="Assemble" then math.clamp((age-E.Assemble*.5)/(E.Assemble*.35),0,1) else 1
		assembly=assembly*assembly*(3-2*assembly)
		local stroke=if packet.phase=="Active" and rig.record.present then Motion.plotStroke(age) else 0
		local S=E.SuperScale
		local lift=V(0,(-18*(1-assembly)-18*(1-recovery))*S,0)
		for _,v in rig.all do v.part.CFrame=v.rest+lift end
		for _,v in rig.moving do v.part.CFrame=v.rest+lift-V(0,stroke*7.2*S,0) end
		for _,v in rig.shafts do
			local bottom=(17.3-stroke*7.2)*S local height=v.top-bottom
			v.part.Size=V(1.25*S,height,1.25*S)
			v.part.CFrame=rig.origin*CFrame.new(v.x,bottom+height/2,0)+lift
		end
		for _,v in rig.rotors do v.part.CFrame=v.rest*CFrame.Angles(0,0,now*2)+lift end
		local shrink=math.max(.12,1-stroke*.7)
		rig.core.origin=rig.origin*CFrame.new(0,(3.7+2.5*shrink)*S,0)+lift
		animateCore(rig.core,now,shrink)
		local boosted=(rig.record.pulseUntil or 0)>now
		rig.core.heart.Color=if boosted then GOLD else PURPLE
		for i,spark in rig.sparks do
			local t=math.clamp((age-(i-1)*.35)/2.4,0,1)
			spark.part.Transparency=if packet.phase=="Assemble" and t>0 and t<1 then .1 else 1
			local target=(rig.origin*CFrame.new(0,18*S,0)).Position
			spark.part.CFrame=CFrame.new(spark.from*(1-t)+target*t+V(0,math.sin(t*math.pi)*12,0))
		end
		if self.central then
			local beam=rig.beam
			if not beam then
				local a=Instance.new("Attachment") a.Parent=rig.source
				local b=Instance.new("Attachment") b.Parent=self.central.reactor
				beam=Instance.new("Beam") beam.Name="FactoryEnergy" beam.Attachment0=a beam.Attachment1=b
				beam.FaceCamera=true beam.Segments=12 beam.CurveSize0=18 beam.CurveSize1=-18
				beam.Width0=1 beam.Width1=.45 beam.Color=ColorSequence.new(rig.color,CYAN)
				beam.LightEmission=1 beam.Transparency=NumberSequence.new(.2) beam.Parent=rig.model
				rig.beam=beam rig.beamEnd=b
			end
			beam.Enabled=packet.phase=="Active" and rig.record.present
			beam.Width0=if boosted then 2 else .75+.4*stroke
		end
	end
	local central=self.central
	if central then
		local exposed=packet.phase=="Finale" or packet.phase=="Victory"
		local shattered=packet.phase=="Victory" or (packet.phase=="Finale" and age>=2.85)
		central.shield.Transparency=if exposed then 1 else .6+.25*progress
		central.shield.CFrame=central.core.origin*CFrame.Angles(0,now*.5,0)
		animateCore(central.core,now,if shattered then .01 else 1)
		if shattered and not central.burst then
			central.burst=part(central.folder,"FinalShockwave",V(.2,1,1),central.origin*CFrame.Angles(0,0,math.pi/2),GOLD,Enum.PartType.Cylinder,true)
			central.burstAt=now
		end
		if central.burst then
			local t=math.clamp((now-central.burstAt)/1.8,0,1)
			central.burst.Size=V(.2,1+90*t,1+90*t) central.burst.Transparency=t
		end
		local stage=math.floor(progress*3)/3
		if exposed then stage=1 end
		for _,v in central.panels do
			v.part.CFrame=v.rest*CFrame.new(v.side*3*stage,stage*3,0)*CFrame.Angles(0,0,-v.side*.22*stage)
		end
		central.reactor.CFrame=central.reactorRest*CFrame.Angles(0,0,now*2)
		central.reactor.Color=if exposed then GOLD else CYAN
	end
	self:stepHazards(now,packet)
	self:stepWork(now,packet)
	self:stepFlyers(now,packet)
	if self.bear and self.bear.ready and self.central then
		local b=self.bear
		if not b.beam then
			local a0=Instance.new("Attachment") a0.Parent=b.rig.nodes.Core.part
			local a1=Instance.new("Attachment") a1.Parent=self.central.shield
			local beam=Instance.new("Beam") beam.Name="CorruptionBeam" beam.Attachment0=a0 beam.Attachment1=a1
			beam.FaceCamera=true beam.Segments=24 beam.CurveSize0=60 beam.CurveSize1=-30 beam.Width0=5 beam.Width1=2.5
			beam.Color=ColorSequence.new(Color3.fromRGB(200,90,255),Color3.fromRGB(120,40,230)) beam.LightEmission=1
			beam.Transparency=NumberSequence.new(.25) beam.TextureSpeed=2 beam.Parent=b.model
			b.beam=beam
		end
		local ph=packet.phase
		b.beam.Enabled=(ph=="Announce" and age>=7.2) or ph=="Assemble" or ph=="Active"
	end
	if self.bear and self.bear.ready then
		local b=self.bear
		local mode,t="Corrupted",9
		local ph=packet.phase
		-- intro timeline (seconds after the announcement): purple smoke 0-3.4,
		-- the teddy shakes then spins and shrinks away 1.2-2.6, flash, the event bear drops
		-- in 2.6-3.2, turns 3.6-5.2, roars 5.2-7.
		local intro=ph=="Announce"
		local teddyShown=intro and age<2.6
		for _,p in b.teddyParts do if p.Parent then p.LocalTransparencyModifier=if teddyShown then 0 else 1 end end
		if teddyShown and self.teddyModel and self.teddyRest then
			local rise=math.clamp((age-1.2)/1.4,0,1)
			local shake=if age<1.2 then math.sin(age*40)*.04*age else 0
			-- lifts a little, spins and shrinks away under the booth roof (a 45-stud
			-- rise went through the ceiling, 28 Oct); scales relative to its own scale (4)
			local sc=(self.teddyScale or 1)*math.max(.05,1-rise*rise*.95)
			if math.abs(self.teddyModel:GetScale()-sc)>1e-3 then self.teddyModel:ScaleTo(sc) end
			self.teddyModel:PivotTo(self.teddyRest*CFrame.new(0,rise*b.height*.35,0)*CFrame.Angles(0,rise*7+shake,shake))
		elseif self.teddyModel and self.teddyRest then
			local s0=self.teddyScale or 1
			if self.teddyModel:GetScale()~=s0 then self.teddyModel:ScaleTo(s0) end
			self.teddyModel:PivotTo(self.teddyRest)
		end
		b.smoke.Rate=if intro and age<3.4 then 45 else 0
		local drop=if intro then math.clamp((age-2.6)/.6,0,1) else 1
		local bearShown=not intro or age>=2.6
		for _,p in b.parts do p.LocalTransparencyModifier=if bearShown then 0 else 1 end
		b.model:PivotTo(CFrame.lookAt(b.bottom+V(0,(1-drop*drop)*40,0),b.bottom+V(-b.bottom.X,0,-b.bottom.Z).Unit))
		if intro and age>=3.2 and not b.ring then
			b.ring=part(self.folder,"LandingRing",V(.4,8,8),CFrame.new(b.bottom+V(0,.5,0))*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(230,180,255),Enum.PartType.Cylinder,true)
			b.ringAt=now
		end
		if b.ring then
			local s=math.clamp((now-b.ringAt)/.9,0,1)
			b.ring.Size=V(.4,8+b.height*2.2*s,8+b.height*2.2*s) b.ring.Transparency=s
		end
		if intro then
			if age<3.6 then mode="Friendly" t=age
			elseif age<5.2 then mode="Corrupted" t=age-3.6
			elseif age<7 then mode="Roar" t=age-5.2
			else mode="Corrupted" t=9 end
		elseif ph=="Active" then
			for _,h in packet.hazards or {} do
				if not h.result and now<h.at then
					mode="Windup" t=now-h.warnAt
				elseif now>=h.at and now-h.at<.9 then
					mode="Slam" t=now-h.at
				end
			end
		elseif ph=="Finale" then
			if age<2.85 then mode="Roar" t=age else mode="Defeated" t=age-2.85 end
		elseif ph=="Victory" then
			mode="Recover" t=age
		elseif ph=="Recover" then
			mode="Friendly" t=age
		end
		local cam=workspace.CurrentCamera
		if not cam or (cam.CFrame.Position-self.bear.model:GetPivot().Position).Magnitude<900 then BearRig.pose(self.bear.rig,mode,t) end
	elseif self.bear then
		local evil=packet.phase~="Victory" and packet.phase~="Recover"
		for _,eye in self.bear.eyes do eye.Transparency=if evil then .05+.15*math.sin(now*4)^2 else 1 end
		self.bear.halo.Transparency=if evil then .35 else 1
		self.bear.glow.Enabled=evil
		self.bear.glow.FillTransparency=.4+.12*math.sin(now*3)
		self.bear.halo.CFrame=self.bear.rest*CFrame.Angles(0,now*.7,0)
	end
	if self.tint then
		self.tint.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(235,226,255),recovery)
		if packet.phase=="Victory" then self.tint.TintColor=Color3.new(1,1,1) end
	end
end
-- Bear paw slams: red danger circle with a filling countdown, then a giant
-- paw (the bear's own paw mesh when present) lands; shockwave on impact.
-- Assembly on your own plot: copies of your placed crushers lift out of their
-- bays and fly in arcs into the middle, shrinking, then the super crusher forms.
function Visuals:stepFlyers(now,packet)
	if packet.phase~="Assemble" then
		if self.flyers then for _,f in self.flyers do if f.model.Parent then f.model:Destroy() end end self.flyers=nil end
		return
	end
	local age=now-packet.started
	local rig=self.rigs[me.UserId]
	if not rig then return end
	if not self.flyers then
		self.flyers={}
		local plot=workspace:FindFirstChild("Plot"..tostring(rig.record.plotIndex),true)
		local target=(rig.origin*CFrame.new(0,14*E.SuperScale,0)).Position
		local models={}
		if plot then for _,m in plot:GetDescendants() do if m:IsA("Model") and m.Name=="EquippedCrusher" then table.insert(models,m) end end end
		table.sort(models,function(a,b) return a:GetPivot().X<b:GetPivot().X end)
		for i,m in models do
			if i>24 then break end
			local was=m.Archivable m.Archivable=true
			local ok,copy=pcall(function() return m:Clone() end)
			m.Archivable=was
			if ok and copy then
				for _,p in copy:GetDescendants() do
					if p:IsA("BasePart") then p.LocalTransparencyModifier=0 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
					elseif p:IsA("Script") or p:IsA("LocalScript") then p:Destroy() end
				end
				copy.Parent=self.folder
				table.insert(self.flyers,{model=copy,from=m:GetPivot(),to=target,scale=copy:GetScale(),delay=(i-1)/math.max(1,#models)*E.Assemble*.3})
			end
		end
	end
	for _,f in self.flyers do
		if not f.model.Parent then continue end
		local k=math.clamp((age-.6-f.delay)/(E.Assemble*.32),0,1)
		if k>=1 then
			local pop=part(self.folder,"MergeFlash",V(3,3,3),CFrame.new(f.to),Color3.fromRGB(235,200,255),Enum.PartType.Ball,true)
			game:GetService("TweenService"):Create(pop,TweenInfo.new(.4),{Size=V(9,9,9),Transparency=1}):Play()
			game:GetService("Debris"):AddItem(pop,.5)
			f.model:Destroy()
		else
			local e=k*k
			local p=f.from.Position:Lerp(f.to,e)+V(0,math.sin(k*math.pi)*22+math.min(1,k*6)*3,0)
			f.model:PivotTo(CFrame.new(p)*f.from.Rotation*CFrame.Angles(0,k*7,k*2))
			local s=f.scale*(1-.7*e)
			if math.abs(f.model:GetScale()-s)>1e-3 then f.model:ScaleTo(s) end
		end
	end
end
function Visuals:stepHazards(now,packet)
	self.hazards=self.hazards or {}
	local live={}
	for _,h in (if packet.phase=="Active" then packet.hazards or {} else {}) do
		live[h.id]=true
		local v=self.hazards[h.id]
		if not v then
			local ray=workspace:Raycast(h.position+V(0,6,0),V(0,-30,0),RaycastParams.new())
			local floor=if ray then ray.Position else h.position
			local base=CFrame.new(floor+V(0,.12,0))*CFrame.Angles(0,0,math.pi/2)
			local r=E.Slam.Radius
			local ring=part(self.folder,"SlamDanger",V(.15,r*2,r*2),base,RED,Enum.PartType.Cylinder,true) ring.Transparency=.45
			local inner=part(self.folder,"SlamCountdown",V(.2,.1,.1),base+V(0,.03,0),Color3.fromRGB(255,170,60),Enum.PartType.Cylinder,true)
			local paw
			local template=bearTemplate() local source=template and template:FindFirstChild("Paw_L",true)
			if source then
				paw=source:Clone() paw.Anchored=true paw.CanCollide=false paw.CanQuery=false paw.CanTouch=false
				paw.Size=paw.Size*(r*1.5/math.max(paw.Size.X,paw.Size.Z)) paw.Parent=self.folder
			else paw=part(self.folder,"SlamPaw",V(r*1.4,r*.7,r*1.4),base,Color3.fromRGB(190,130,80),Enum.PartType.Ball) end
			paw.Transparency=1
			v={ring=ring,inner=inner,paw=paw,floor=floor,mine=h.userId==me.UserId}
			self.hazards[h.id]=v
		end
		local k=math.clamp((now-h.warnAt)/math.max(.1,h.at-h.warnAt),0,1)
		local r=E.Slam.Radius
		v.inner.Size=V(.2,r*2*k,r*2*k)
		v.ring.Transparency=.35+.25*math.sin(now*14)^2
		local height=if now<h.at then 70*(1-k)^2+6*(1-k) else 0
		v.paw.Transparency=if k>.35 then 0 else 1
		v.paw.CFrame=CFrame.new(v.floor+V(0,height+v.paw.Size.Y/2,0))
		if now>=h.at and not v.boom then
			v.boom=part(self.folder,"SlamShock",V(.3,1,1),CFrame.new(v.floor+V(0,.4,0))*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,230,150),Enum.PartType.Cylinder,true)
			v.boomAt=now v.ring.Transparency=1 v.inner.Transparency=1
			if v.mine then
				local cam=workspace.CurrentCamera
				if cam then task.spawn(function() for i=1,8 do cam.CFrame*=CFrame.new(math.sin(i*7)*.4,math.cos(i*5)*.4,0) task.wait() end end) end
			end
		end
		if v.boom then
			local s=math.clamp((now-v.boomAt)/.6,0,1)
			v.boom.Size=V(.3,1+r*3*s,1+r*3*s) v.boom.Transparency=s
			v.paw.Transparency=math.clamp((now-v.boomAt-.5)/.5,0,1)
		end
	end
	for id,v in self.hazards do if not live[id] then v.ring:Destroy() v.inner:Destroy() v.paw:Destroy() if v.boom then v.boom:Destroy() end self.hazards[id]=nil end end
end
-- Core pickups spin and bob; each super crusher's loading port shows a purple
-- ring (gold + bigger during a critical window); other players' prompts hide.
function Visuals:stepWork(now,packet)
	local worldFolder=workspace:FindFirstChild("FactoryEventWorld")
	if worldFolder then
		for _,m in worldFolder:GetChildren() do
			if m.Name=="EventCorePickup" and m:IsA("Model") then
				local base=m:GetAttribute("BaseCF")
				if not base then base=m:GetPivot() m:SetAttribute("BaseCF",base) end
				m:PivotTo(base*CFrame.new(0,math.sin(now*2.2+base.X)*.5,0)*CFrame.Angles(0,now*1.5,0))
			end
		end
		if not self.promptHook then
			local function mark(d)
				if d:IsA("ProximityPrompt") then d.Enabled=d:GetAttribute("OwnerUserId")==me.UserId end
			end
			for _,d in worldFolder:GetDescendants() do mark(d) end
			self.promptHook=worldFolder.DescendantAdded:Connect(mark)
		end
	end
	for _,rig in self.rigs do
		local r=rig.record
		if not rig.port then
			local cf=r.origin*CFrame.new(E.Cores.Port)*CFrame.new(0,.15,0)*CFrame.Angles(0,0,math.pi/2)
			rig.port=part(rig.model,"CorePortRing",V(.12,7,7),cf,PURPLE,Enum.PartType.Cylinder,true)
			rig.portRest=cf
		end
		local active=packet.phase=="Active"
		local crit=active and now<=(r.critUntil or 0)
		rig.port.Transparency=if active then (if crit then .1 else .55) else 1
		rig.port.Color=if crit then GOLD else PURPLE
		local s=if crit then 8.5+math.sin(now*8) else 7
		rig.port.Size=V(.12,s,s)
	end
end
function Visuals:destroy()
	self:clear() self.folder:Destroy()
end
return Visuals
