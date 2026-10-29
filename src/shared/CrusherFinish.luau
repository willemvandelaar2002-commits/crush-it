--!strict
-- Persistent coating/fusion looks shared by working bays, held copies and UI previews.
-- API compatible: Looks, dress, apply(model,modifier,front?), fused(model,front?).
-- Static dressing is readable without particles; the client animator budgets motion/emitters.
local Tags = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local F = {}
F.Looks = {
	Polished = {dark=Color3.fromRGB(92,111,139),light=Color3.fromRGB(247,253,255),mix=.88,
		material=Enum.Material.Metal,reflect=.28,keepTexture=true,glow=Color3.fromRGB(231,250,255),fx="glint"},
	Frost = {dark=Color3.fromRGB(25,120,190),light=Color3.fromRGB(137,236,255),mix=.88,
		material=Enum.Material.SmoothPlastic,glow=Color3.fromRGB(94,231,255),fx="snow"},
	Fire = {dark=Color3.fromRGB(123,36,27),light=Color3.fromRGB(255,157,46),mix=.78,
		material=Enum.Material.SmoothPlastic,glow=Color3.fromRGB(255,166,54),fx="ember"},
	Charged = {dark=Color3.fromRGB(60,30,111),light=Color3.fromRGB(207,156,255),mix=.76,
		material=Enum.Material.SmoothPlastic,glow=Color3.fromRGB(195,124,255),fx="spark"},
} :: {[string]: any}
local WHITE = Color3.fromRGB(255,249,224)
local NAVY = Color3.fromRGB(19,23,42)
local LIME = Color3.fromRGB(114,255,159)
local GOLD = Color3.fromRGB(255,204,73)

local function decorated(p: Instance, model: Instance): boolean
	local a = p.Parent
	while a and a ~= model do
		if a.Name == "CrusherFinish" or a.Name == "FusedLook" then return true end
		a = a.Parent
	end
	return false
end
local function bounds(model: Instance, frame: CFrame): (Vector3, Vector3)
	local lo=Vector3.new(math.huge,math.huge,math.huge) local hi=-lo
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency<.99 and not decorated(p,model) then
			for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
				local v=frame:PointToObjectSpace(p.CFrame*Vector3.new(p.Size.X*x/2,p.Size.Y*y/2,p.Size.Z*z/2))
				lo=lo:Min(v) hi=hi:Max(v)
			end end end
		end
	end
	return lo,hi
end
local function part(root: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,alpha: number?): BasePart
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
	p.Material=material or Enum.Material.Neon p.Transparency=alpha or 0
	p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=root
	return p
end
local function mesh(root: Instance,kind: string,name: string,size: Vector3,cf: CFrame,color: Color3): BasePart
	local folder=RS:FindFirstChild("CrusherFinishMeshes")
	local source=folder and folder:FindFirstChild(kind)
	if source and source:IsA("MeshPart") then
		local p=source:Clone() p:ClearAllChildren() p.Name=name p.Size=size p.CFrame=cf p.Color=color
		p.TextureID="" p.Material=Enum.Material.Neon p.Anchored=true
		p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=root
		return p
	end
	-- Small native fallback. Import the optional meshes for pointed crystals and curved flames.
	local p=part(root,name,size,cf,color,Enum.Material.SmoothPlastic)
	if kind=="FinishFlame" then
		local wedge=Instance.new("SpecialMesh") wedge.MeshType=Enum.MeshType.Wedge wedge.Parent=p
	elseif kind=="FinishCrystal" then p.CFrame=cf*CFrame.Angles(0,math.pi/4,.22)
	end
	return p
end
local function emitter(parent: BasePart,name: string,kind: string,unit: number,color: Color3): ParticleEmitter
	local e=Instance.new("ParticleEmitter") e.Name=name e.Enabled=false e.Rate=0
	e.LightInfluence=0 e.LightEmission=.6 e.EmissionDirection=Enum.NormalId.Top
	e.Texture="rbxasset://textures/particles/sparkles_main.dds"
	e.Lifetime=NumberRange.new(.65,1.15) e.Speed=NumberRange.new(unit*.035,unit*.09)
	e.SpreadAngle=Vector2.new(20,20) e.Rotation=NumberRange.new(0,360)
	e.Color=ColorSequence.new(color:Lerp(WHITE,.25),color)
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.18),NumberSequenceKeypoint.new(1,1)})
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,unit*.025),NumberSequenceKeypoint.new(1,0)})
	local rate=2
	if kind=="mist" then
		e.Texture="rbxasset://textures/particles/smoke_main.dds" e.Lifetime=NumberRange.new(.65,1.05)
		e.Speed=NumberRange.new(unit*.015,unit*.035) e.SpreadAngle=Vector2.new(65,65)
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,unit*.08),NumberSequenceKeypoint.new(1,unit*.18)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.84),NumberSequenceKeypoint.new(1,1)})
	elseif kind=="ember" then
		rate=3 e.Acceleration=Vector3.new(0,unit*.08,0)
		e.Color=ColorSequence.new(WHITE,Color3.fromRGB(255,112,38))
	elseif kind=="snow" then e.Acceleration=Vector3.new(0,-unit*.025,0)
	elseif kind=="glint" then
		rate=1 e.Speed=NumberRange.new(0) e.Lifetime=NumberRange.new(.3,.55)
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,unit*.09),NumberSequenceKeypoint.new(1,0)})
	end
	e:SetAttribute("FinishRate",rate) e.Parent=parent
	return e
end
local function lamp(parent: BasePart,color: Color3,unit: number)
	local l=Instance.new("PointLight") l.Name="CoatingLight" l.Enabled=false l.Shadows=false
	l.Range=unit*.65 l.Brightness=.65 l.Color=color l.Parent=parent
end
local function glint(root: Instance,cf: CFrame,r: number)
	-- Star mesh faces local +Z; front convention of this module is +Z.
	local folder=RS:FindFirstChild("CrusherFinishMeshes")
	if folder and folder:FindFirstChild("FinishStar") then
		mesh(root,"FinishStar","Gleam",Vector3.new(r,r,r*.08),cf,WHITE)
	else
		part(root,"Gleam",Vector3.new(r,r*.12,r*.10),cf,WHITE)
		part(root,"Gleam",Vector3.new(r*.12,r,r*.10),cf,WHITE)
	end
end

-- Permanent decorative geometry. Never spans the open crushing window.
function F.dress(root: Instance,modifier: string,frame: CFrame,lo: Vector3,hi: Vector3)
	if not F.Looks[modifier] then return end
	local s=hi-lo local c=(lo+hi)/2 local unit=math.max(s.X,s.Y,s.Z)
	local function at(x: number,y: number,z: number): CFrame return frame*CFrame.new(x,y,z) end
	local glow=F.Looks[modifier].glow
	root:SetAttribute("FinishUnit",unit)
	if modifier=="Frost" then
		for _,sign in {-1,1} do
			local x=c.X+sign*s.X*.40
			for k=1,2 do
				local h=s.Y*(if k==1 then .25 else .17)
				mesh(root,"FinishCrystal","IceCrystal",Vector3.new(s.X*.10,h,s.Z*.12),
					at(x+sign*s.X*.055*(k-1),lo.Y+h*.5,hi.Z-s.Z*.10)*CFrame.Angles(0,0,-sign*.17),
					if k==1 then glow else Color3.fromRGB(201,249,255))
			end
			mesh(root,"FinishCrystal","IceCrown",Vector3.new(s.X*.07,s.Y*.15,s.Z*.08),
				at(x,hi.Y+s.Y*.03,lo.Z+s.Z*.16)*CFrame.Angles(0,0,-sign*.16),glow)
		end
		local a=part(root,"FrostMist",Vector3.new(s.X*.65,.05,s.Z*.55),at(c.X,lo.Y+s.Y*.035,c.Z),WHITE,nil,1)
		emitter(a,"Mist","mist",unit,Color3.fromRGB(215,249,255)) emitter(a,"Snow","snow",unit,glow) lamp(a,glow,unit)
	elseif modifier=="Fire" then
		for i=1,5 do
			local x,y,z,h,w
			if i<=3 then x=lo.X+s.X*(.20+.30*(i-1)); y=hi.Y;z=lo.Z+s.Z*.23;h=s.Y*(if i==2 then .25 else .18);w=s.X*.14
			else x=c.X+(if i==4 then -1 else 1)*s.X*.4;y=lo.Y+s.Y*.05;z=hi.Z-s.Z*.12;h=s.Y*.17;w=s.X*.12 end
			local outer=mesh(root,"FinishFlame","FlameOuter",Vector3.new(w,h,s.Z*.10),at(x,y+h*.40,z),Color3.fromRGB(255,103,30))
			outer:SetAttribute("FinishPulse",true)
			mesh(root,"FinishFlame","FlameCore",Vector3.new(w*.48,h*.67,s.Z*.105),at(x,y+h*.28,z+s.Z*.01),Color3.fromRGB(255,228,95))
		end
		local a=part(root,"EmberSource",Vector3.new(s.X*.7,.05,s.Z*.5),at(c.X,hi.Y,c.Z),WHITE,nil,1)
		emitter(a,"Embers","ember",unit,glow) lamp(a,glow,unit)
	elseif modifier=="Charged" then
		local points={}
		for i=1,2 do
			local sign=if i==1 then -1 else 1 local x=c.X+sign*s.X*.38
			part(root,"CoilHousing",Vector3.new(s.X*.16,s.Y*.075,s.Z*.18),at(x,hi.Y,lo.Z+s.Z*.22),NAVY,Enum.Material.SmoothPlastic)
			local o=part(root,"CoilCore",Vector3.new(s.X*.09,s.Y*.08,s.Z*.10),at(x,hi.Y+s.Y*.055,lo.Z+s.Z*.22),glow)
			o.Shape=Enum.PartType.Ball
			part(root,"CoilBand",Vector3.new(s.X*.18,s.Y*.023,s.Z*.20),at(x,hi.Y+s.Y*.015,lo.Z+s.Z*.22),glow)
			points[i]=o
		end
		-- Thin zig-zag confined to the rear top beam. Not a bright X across the crusher.
		local anchors={}
		for i=0,4 do
			local p=part(root,"ArcAnchor",Vector3.new(.03,.03,.03),at(lo.X+s.X*(.12+.19*i),hi.Y+s.Y*(.08+(if i%2==1 then .035 else 0)),lo.Z+s.Z*.22),glow,nil,1)
			local a=Instance.new("Attachment") a.Parent=p anchors[i+1]=a
		end
		for i=1,4 do
			local b=Instance.new("Beam") b.Name="Arc" b.Attachment0=anchors[i] b.Attachment1=anchors[i+1]
			b.Width0=unit*.022 b.Width1=b.Width0*.7 b.FaceCamera=true b.Segments=5 b.Enabled=false
			b.Color=ColorSequence.new(WHITE,glow) b.Transparency=NumberSequence.new(.15) b.LightEmission=1 b.Parent=points[1]
		end
		-- lightning down the two rear pillars, from each coil to the foot
		for i,sign in {-1,1} do
			local foot=part(root,"ArcAnchor",Vector3.new(.03,.03,.03),at(c.X+sign*s.X*.42,lo.Y+s.Y*.06,lo.Z+s.Z*.12),glow,nil,1)
			local mid=part(root,"ArcAnchor",Vector3.new(.03,.03,.03),at(c.X+sign*s.X*.47,lo.Y+s.Y*.5,lo.Z+s.Z*.14),glow,nil,1)
			local a0=Instance.new("Attachment") a0.Parent=points[i]
			local a1=Instance.new("Attachment") a1.Parent=mid
			local a2_=Instance.new("Attachment") a2_.Parent=foot
			for k,pair in {{a0,a1},{a1,a2_}} do
				local b=Instance.new("Beam") b.Name="Arc" b.Attachment0=pair[1] b.Attachment1=pair[2]
				b.Width0=unit*.02 b.Width1=b.Width0*.6 b.FaceCamera=true b.Segments=5 b.Enabled=false
				b.Color=ColorSequence.new(WHITE,glow) b.Transparency=NumberSequence.new(.1) b.LightEmission=1 b.Parent=points[i]
				local _=k
			end
		end
		emitter(points[1],"ChargeSpark","spark",unit,glow) lamp(points[1],glow,unit)
	elseif modifier=="Polished" then
		glint(root,at(lo.X+s.X*.13,hi.Y-s.Y*.07,hi.Z+s.Z*.015),s.X*.12)
		glint(root,at(hi.X-s.X*.10,lo.Y+s.Y*.15,hi.Z+s.Z*.015),s.X*.08)
		local a=part(root,"ChromeGlint",Vector3.new(s.X*.65,s.Y*.6,.04),at(c.X,c.Y,hi.Z),WHITE,nil,1)
		emitter(a,"PolishGlints","glint",unit,WHITE)
	end
end
function F.apply(model: Model,modifier: string,front: CFrame?)
	local look=F.Looks[modifier]
	if not look or model:FindFirstChild("CrusherFinish") then return end
	local frame=front or model:GetPivot() local lo,hi=bounds(model,frame)
	if lo.X==math.huge then return end
	-- No repaint: the crusher keeps its own colours, textures and SurfaceAppearance
	-- maps (Legendaries/Mythics stay recognisable). The coating shows through the
	-- dressing below and a smooth coloured glow the client lays over the model
	-- (CoatingAnimator, Highlight in the coating's glow colour).
	local root=Instance.new("Model") root.Name="CrusherFinish" root:SetAttribute("Finish",modifier)
	F.dress(root,modifier,frame,lo,hi) root.Parent=model
	model:SetAttribute("VisualModifier",modifier) Tags:AddTag(root,"CoatingFx")
end
function F.fused(model: Model,front: CFrame?)
	if model:FindFirstChild("FusedLook") then return end
	local frame=front or model:GetPivot() local lo,hi=bounds(model,frame)
	if lo.X==math.huge then return end
	local s=hi-lo local c=(lo+hi)/2 local unit=math.max(s.X,s.Y,s.Z)
	local function at(x: number,y: number,z: number): CFrame return frame*CFrame.new(x,y,z) end
	local root=Instance.new("Model") root.Name="FusedLook" root:SetAttribute("Finish","Fusion") root:SetAttribute("FinishUnit",unit)
	-- Thin gold base rails and lime corner cores, leaving the coated machine visible.
	for _,sign in {-1,1} do
		part(root,"FusionRail",Vector3.new(s.X*.025,s.Y*.025,s.Z*.93),at(c.X+sign*s.X*.475,lo.Y+s.Y*.03,c.Z),GOLD)
		for _,z in {lo.Z+s.Z*.065,hi.Z-s.Z*.065} do
			part(root,"FusionSocket",Vector3.new(s.X*.12,s.Y*.04,s.Z*.12),at(c.X+sign*s.X*.43,lo.Y+s.Y*.055,z),NAVY,Enum.Material.SmoothPlastic)
			local core=part(root,"FusionCore",Vector3.new(s.X*.07,s.Y*.045,s.Z*.07),at(c.X+sign*s.X*.43,lo.Y+s.Y*.08,z),LIME)
			core:SetAttribute("FinishPulse",true)
		end
	end
	part(root,"FusionBadgeBack",Vector3.new(s.X*.24,s.Y*.13,s.Z*.035),at(c.X,lo.Y+s.Y*.12,hi.Z+s.Z*.012),NAVY,Enum.Material.SmoothPlastic)
	for _,side in {-1,1} do
		local badge=part(root,"FusionChevron",Vector3.new(s.X*.105,s.Y*.026,s.Z*.04),at(c.X+side*s.X*.036,lo.Y+s.Y*.13,hi.Z+s.Z*.038)*CFrame.Angles(0,0,-side*.55),GOLD)
		badge:SetAttribute("FinishPulse",true)
	end
	for _,side in {-1,1} do
		local gem=mesh(root,"FinishCrystal","FusionGem",Vector3.new(s.X*.065,s.Y*.12,s.Z*.07),at(c.X+side*s.X*.34,hi.Y+s.Y*.035,lo.Z+s.Z*.13)*CFrame.Angles(0,0,-side*.28),LIME)
		gem:SetAttribute("FinishPulse",true)
	end
	local a=part(root,"FusionSparkSource",Vector3.new(s.X*.65,.03,s.Z*.5),at(c.X,lo.Y+s.Y*.06,c.Z),WHITE,nil,1)
	emitter(a,"FusionMotes","rise",unit,LIME)
	root.Parent=model model:SetAttribute("Fused",true) Tags:AddTag(root,"CoatingFx")
end
return F
