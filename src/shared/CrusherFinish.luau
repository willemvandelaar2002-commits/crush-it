--!strict
-- Coating and fusion looks on a crusher model: bays, the held crusher and the
-- 3D pictures in the Coating Lab / Fusion screens all use this, so a coating
-- looks the same everywhere. Recolours the machine into the finish's palette
-- (keeping its light/dark structure so every type stays recognisable), turns
-- small details into glowing accents, and adds the finish's own dressing:
--   Fire: real flames on top and at the feet, embers, flickering orange light
--   Frost: ice crystal clusters, icicles, cold mist, snow, icy light
--   Charged: energy orbs with lightning arcs between them, sparks, purple light
--   Polished: the machine's own colours turned into reflective chrome, glints
-- Dressing sits in the "CrusherFinish" model (tag CoatingFx; the client
-- CoatingAnimator flickers lights and arcs). Moving groups keep working.
local Tags=game:GetService("CollectionService")
local F={}

type Look={dark: Color3,light: Color3,mix: number,material: Enum.Material,darkMaterial: Enum.Material?,
	reflect: number?,glow: Color3,fx: string,keepTexture: boolean?}
F.Looks={
	Polished={dark=Color3.fromRGB(104,116,136),light=Color3.fromRGB(250,252,255),mix=.25,material=Enum.Material.Metal,reflect=.45,keepTexture=true,
		glow=Color3.fromRGB(255,255,255),fx="glint"},
	Frost={dark=Color3.fromRGB(38,112,178),light=Color3.fromRGB(214,248,255),mix=.88,material=Enum.Material.Ice,
		glow=Color3.fromRGB(120,235,255),fx="snow"},
	Fire={dark=Color3.fromRGB(120,22,8),light=Color3.fromRGB(255,118,26),mix=.95,material=Enum.Material.SmoothPlastic,
		darkMaterial=Enum.Material.CrackedLava,glow=Color3.fromRGB(255,120,30),fx="flame"},
	Charged={dark=Color3.fromRGB(46,20,98),light=Color3.fromRGB(206,150,255),mix=.85,material=Enum.Material.SmoothPlastic,
		glow=Color3.fromRGB(190,110,255),fx="spark"},
} :: {[string]: Look}
local FUSED=Color3.fromRGB(90,255,110)

local function bounds(model: Instance, front: CFrame): (Vector3, Vector3)
	local lo=Vector3.new(math.huge,math.huge,math.huge) local hi=-lo
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=front:PointToObjectSpace(p.CFrame*Vector3.new(p.Size.X*x/2,p.Size.Y*y/2,p.Size.Z*z/2))
			lo=lo:Min(v) hi=hi:Max(v)
		end end end
	end end
	return lo,hi
end
local function lum(c: Color3): number return .299*c.R+.587*c.G+.114*c.B end
local function accent(p: BasePart, span: number): boolean
	if p.Material==Enum.Material.Neon then return true end
	local n=p.Name:lower()
	if n:find("light") or n:find("glow") or n:find("strip") or n:find("bolt") or n:find("lamp") or n:find("led") then return true end
	return math.max(p.Size.X,p.Size.Y,p.Size.Z)<span*.07
end
-- the emitter sits on the biggest part (snow, glints, sparks) or the highest
-- one (flames)
local function host(model: Instance, top: boolean): BasePart?
	local best,score=nil,-math.huge
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
		local s=if top then p.Position.Y+p.Size.Y/2+p.Size.X*p.Size.Z*.001 else p.Size.X*p.Size.Y*p.Size.Z
		if s>score then best,score=p,s end
	end end
	return best
end
local function emitter(parent: BasePart, kind: string, span: number, color: Color3)
	local e=Instance.new("ParticleEmitter") e.Name="FinishFx"
	e.LightEmission=1 e.LightInfluence=0 e.Shape=Enum.ParticleEmitterShape.Box e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
	e.Rotation=NumberRange.new(0,360) e.EmissionDirection=Enum.NormalId.Top
	local s=math.clamp(span*.05,.15,1.2)
	if kind=="flame" then
		e.Texture="rbxasset://textures/particles/fire_main.dds" e.Rate=7 e.Lifetime=NumberRange.new(.45,.8)
		e.Speed=NumberRange.new(span*.15,span*.25) e.SpreadAngle=Vector2.new(15,15) e.LightEmission=.85
		e.Color=ColorSequence.new(Color3.fromRGB(255,210,80),Color3.fromRGB(255,70,20))
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,s*1.6),NumberSequenceKeypoint.new(1,0)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)})
		e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface e.ShapePartial=0
	else
		e.Texture="rbxasset://textures/particles/sparkles_main.dds"
		e.Color=ColorSequence.new(color:Lerp(Color3.new(1,1,1),.5),color)
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,0),NumberSequenceKeypoint.new(1,1)})
		if kind=="snow" then
			e.Rate=4 e.Lifetime=NumberRange.new(1.4,2.2) e.Speed=NumberRange.new(span*.02,span*.05) e.Acceleration=Vector3.new(0,-span*.06,0)
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,s),NumberSequenceKeypoint.new(1,s*.3)}) e.RotSpeed=NumberRange.new(-60,60)
		elseif kind=="spark" then
			e.Rate=6 e.Lifetime=NumberRange.new(.15,.35) e.Speed=NumberRange.new(span*.3,span*.5) e.SpreadAngle=Vector2.new(180,180)
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,s*1.3),NumberSequenceKeypoint.new(1,0)})
		elseif kind=="rise" then
			e.Rate=4 e.Lifetime=NumberRange.new(1,1.6) e.Speed=NumberRange.new(span*.06,span*.12)
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,s),NumberSequenceKeypoint.new(1,0)})
		else -- glint
			e.Rate=4 e.Lifetime=NumberRange.new(.35,.55) e.Speed=NumberRange.new(0,0)
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,s*3),NumberSequenceKeypoint.new(1,0)})
		end
	end
	e.Parent=parent
end
local function part(root: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number?)
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.Neon
	p.Transparency=transparency or 0 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=root
	return p
end

-- The finish's own objects round the machine (in its frame: +Z front, +Y up).
local ICE=Color3.fromRGB(150,230,255)
function F.dress(root: Instance, modifier: string, frame: CFrame, lo: Vector3, hi: Vector3)
	local size=hi-lo local span=size.Magnitude local c=(lo+hi)/2
	local small=span<7 -- the held copy and other minis: no Fire objects or lights
	local function at(x: number, y: number, z: number): CFrame return frame*CFrame.new(x,y,z) end
	local function anchor(name: string, cf: CFrame): Part
		local p=part(root,name,Vector3.new(.2,.2,.2),cf,Color3.new(1,1,1),1) return p
	end
	local function light(parent: BasePart, color: Color3, range: number, brightness: number)
		if small then return end
		local l=Instance.new("PointLight") l.Name="CoatingLight" l.Color=color l.Range=range l.Brightness=brightness l.Shadows=false l.Parent=parent
	end
	local corners={{lo.X,lo.Z},{hi.X,lo.Z},{lo.X,hi.Z},{hi.X,hi.Z}}
	if modifier=="Fire" then
		-- flames along the top beam and at the two front feet
		local spots={{lo.X+size.X*.18,hi.Y,c.Z,1},{c.X,hi.Y,c.Z,1.25},{hi.X-size.X*.18,hi.Y,c.Z,1},
			{lo.X+size.X*.08,lo.Y+size.Y*.05,hi.Z-size.Z*.12,.7},{hi.X-size.X*.08,lo.Y+size.Y*.05,hi.Z-size.Z*.12,.7}}
		for i,sp in spots do
			local a=anchor("FireSpot"..i,at(sp[1],sp[2],sp[3]))
			if small then emitter(a,"flame",span*sp[4]*1.4,Color3.fromRGB(255,120,30))
			else
				local f=Instance.new("Fire") f.Size=math.clamp(span*.16*sp[4],2,7) f.Heat=math.clamp(span*.35,4,12)
				f.Color=Color3.fromRGB(255,140,30) f.SecondaryColor=Color3.fromRGB(255,40,10) f.Parent=a
			end
			if i==2 then light(a,Color3.fromRGB(255,130,40),span*1.1,2.2) end
		end
		local embers=anchor("Embers",at(c.X,c.Y,c.Z)) embers.Size=Vector3.new(size.X*.8,size.Y*.6,size.Z*.6)
		local e=Instance.new("ParticleEmitter") e.Name="Embers" e.Texture="rbxasset://textures/particles/sparkles_main.dds"
		e.Rate=10 e.Lifetime=NumberRange.new(.8,1.6) e.Speed=NumberRange.new(span*.08,span*.18) e.SpreadAngle=Vector2.new(25,25)
		e.Acceleration=Vector3.new(0,span*.08,0) e.LightEmission=1 e.LightInfluence=0
		e.Color=ColorSequence.new(Color3.fromRGB(255,220,90),Color3.fromRGB(255,80,20))
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,span*.02),NumberSequenceKeypoint.new(1,0)}) e.Parent=embers
	elseif modifier=="Frost" then
		-- crystal clusters on the four corners (base front, top back), like the crystal icon
		local rng=Random.new(math.floor(span*100))
		local function crystal(base: CFrame, h: number, w: number)
			local body=part(root,"IceCrystal",Vector3.new(w,h,w),base*CFrame.new(0,h/2,0)*CFrame.Angles(0,math.pi/4,0),ICE,.18)
			body.Material=Enum.Material.Glass
			local tip=part(root,"IceTip",Vector3.new(w*.72,w*.72,w*.72),base*CFrame.new(0,h,0)*CFrame.Angles(math.pi/4,math.pi/4,0),Color3.fromRGB(225,250,255),.1)
			tip.Material=Enum.Material.Glass
			part(root,"IceCore",Vector3.new(w*.3,h*.8,w*.3),base*CFrame.new(0,h*.45,0),Color3.fromRGB(120,235,255),.35)
		end
		-- (front corners get 3 crystals, back corners 2)
		for i,cr in corners do
			local z=if i<=2 then hi.Z-size.Z*.08 else lo.Z+size.Z*.08
			local base=at(cr[1]+(if cr[1]<c.X then size.X*.06 else -size.X*.06),lo.Y,z)
			local n=if i<=2 then 3 else 2
			for k=1,n do
				local tilt=CFrame.Angles(rng:NextNumber(-.45,.45),0,rng:NextNumber(-.5,.5))
				crystal(base*CFrame.new(rng:NextNumber(-.4,.4)*size.X*.06,0,rng:NextNumber(-.4,.4)*size.Z*.06)*tilt,
					size.Y*rng:NextNumber(.16,.3)*(if k==1 then 1.2 else .8),math.max(.12,size.X*.055))
			end
		end
		-- icicles under the top front edge
		for k=1,5 do
			local x=lo.X+size.X*(k/6) local h=size.Y*(if k%2==0 then .16 else .1)
			local ic=part(root,"Icicle",Vector3.new(size.X*.035,h,size.X*.035),at(x,hi.Y-size.Y*.04-h/2,hi.Z-size.Z*.05)*CFrame.Angles(0,math.pi/4,0),ICE,.15)
			ic.Material=Enum.Material.Glass
		end
		local mist=anchor("FrostMist",at(c.X,lo.Y+size.Y*.06,c.Z)) mist.Size=Vector3.new(size.X,.2,size.Z)
		local e=Instance.new("ParticleEmitter") e.Name="Mist" e.Texture="rbxasset://textures/particles/smoke_main.dds"
		e.Rate=5 e.Lifetime=NumberRange.new(1.5,2.5) e.Speed=NumberRange.new(span*.01,span*.03) e.SpreadAngle=Vector2.new(60,60)
		e.Color=ColorSequence.new(Color3.fromRGB(220,245,255)) e.LightEmission=.4 e.LightInfluence=0 e.RotSpeed=NumberRange.new(-20,20)
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,span*.08),NumberSequenceKeypoint.new(1,span*.16)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.6),NumberSequenceKeypoint.new(1,1)}) e.Parent=mist
		light(mist,Color3.fromRGB(140,220,255),span*.9,1.6)
	elseif modifier=="Charged" then
		-- energy orbs on the top corners and at the front feet, lightning arcs between them
		local function orb(name: string, cf: CFrame): Part
			local r=math.max(.15,size.X*.075)
			local o=part(root,name,Vector3.new(r,r,r),cf,Color3.fromRGB(235,190,255))
			o.Shape=Enum.PartType.Ball
			local halo=part(root,name.."Halo",Vector3.new(r*1.8,r*1.8,r*1.8),cf,Color3.fromRGB(170,80,255),.6) halo.Shape=Enum.PartType.Ball
			return o
		end
		local tl=orb("OrbTL",at(lo.X+size.X*.06,hi.Y,c.Z)) local tr=orb("OrbTR",at(hi.X-size.X*.06,hi.Y,c.Z))
		local bl=orb("OrbBL",at(lo.X+size.X*.06,lo.Y+size.Y*.08,hi.Z-size.Z*.1)) local br=orb("OrbBR",at(hi.X-size.X*.06,lo.Y+size.Y*.08,hi.Z-size.Z*.1))
		light(tl,Color3.fromRGB(190,110,255),span*.9,2) light(tr,Color3.fromRGB(190,110,255),span*.9,1.6)
		for i,pair in {{tl,tr},{tl,bl},{tr,br}} do
			local a0=Instance.new("Attachment") a0.Parent=pair[1] local a1=Instance.new("Attachment") a1.Parent=pair[2]
			local b=Instance.new("Beam") b.Name="Arc"..i b.Attachment0=a0 b.Attachment1=a1 b.Segments=12 b.FaceCamera=true
			b.Width0=math.max(.05,size.X*.02) b.Width1=b.Width0 b.LightEmission=1 b.LightInfluence=0
			b.Color=ColorSequence.new(Color3.fromRGB(245,215,255),Color3.fromRGB(180,90,255)) b.Transparency=NumberSequence.new(.05)
			b.CurveSize0=size.Y*.15 b.CurveSize1=-size.Y*.15 b.Parent=pair[1]
		end
	elseif modifier=="Polished" then
		local shine=anchor("Shine",at(c.X,c.Y,hi.Z)) shine.Size=Vector3.new(size.X*.9,size.Y*.9,.2)
		emitter(shine,"glint",span,Color3.new(1,1,1))
		light(shine,Color3.fromRGB(235,245,255),span*.7,1)
	end
end

-- Apply a coating look. front: the model's frame (+Z = its front); optional.
function F.apply(model: Model, modifier: string, front: CFrame?)
	local look=F.Looks[modifier]
	if not look or model:FindFirstChild("CrusherFinish") then return end
	local frame=front or model:GetPivot()
	local lo,hi=bounds(model,frame)
	if lo.X==math.huge then return end
	local span=(hi-lo).Magnitude
	for _,p in model:GetDescendants() do
		if p:IsA("SurfaceAppearance") then p:Destroy()
		elseif p:IsA("BasePart") and p.Transparency<1 then
			if p:IsA("MeshPart") and not look.keepTexture then p.TextureID="" end
			if accent(p,span) then
				p.Color=look.glow p.Material=Enum.Material.Neon
			else
				local l=lum(p.Color)
				p.Color=p.Color:Lerp(look.dark:Lerp(look.light,math.clamp(l*1.15,0,1)),look.mix)
				p.Material=if look.darkMaterial and l<.38 then look.darkMaterial else look.material
				if look.reflect then p.Reflectance=look.reflect end
			end
		end
	end
	local root=Instance.new("Model") root.Name="CrusherFinish" root:SetAttribute("Finish",modifier) root.Parent=model
	local at=host(model,look.fx=="flame")
	if at then emitter(at,look.fx,span,look.glow) end
	F.dress(root,modifier,frame,lo,hi)
	Tags:AddTag(root,"CoatingFx")
	model:SetAttribute("VisualModifier",modifier)
end

-- Fused look: a glowing green plate under the machine, green lights on the
-- top corners and rising green sparkles.
function F.fused(model: Model, front: CFrame?)
	if model:FindFirstChild("FusedLook") then return end
	local frame=front or model:GetPivot()
	local lo,hi=bounds(model,frame)
	if lo.X==math.huge then return end
	local size=hi-lo local span=size.Magnitude
	local root=Instance.new("Model") root.Name="FusedLook" root.Parent=model
	local base=part(root,"FusedPlate",Vector3.new(size.X*1.02,math.max(.06,size.Y*.02),size.Z*1.02),
		frame*CFrame.new((lo.X+hi.X)/2,lo.Y+size.Y*.01,(lo.Z+hi.Z)/2),FUSED,.15)
	local c=math.max(.12,math.min(size.X,size.Z)*.08)
	for _,x in {lo.X+c/2,hi.X-c/2} do for _,z in {lo.Z+c/2,hi.Z-c/2} do
		part(root,"FusedLight",Vector3.new(c,c,c),frame*CFrame.new(x,hi.Y-c/2,z),FUSED)
	end end
	emitter(base,"rise",span,FUSED)
	model:SetAttribute("Fused",true)
end
return F
