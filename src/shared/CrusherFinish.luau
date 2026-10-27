--!strict
-- Coating and fusion looks on a crusher model: bays, the held crusher and the
-- 3D pictures in the Coating Lab / Fusion screens all use this, so a coating
-- looks the same everywhere. Recolours the whole machine into the finish's
-- palette (keeping its light/dark structure so every type stays
-- recognisable), turns small details into glowing accents and adds one
-- low-rate particle emitter. Moving groups keep working (no transforms).
local F={}

type Look={dark: Color3,light: Color3,mix: number,material: Enum.Material,darkMaterial: Enum.Material?,
	reflect: number?,glow: Color3,fx: string}
F.Looks={
	Polished={dark=Color3.fromRGB(70,80,96),light=Color3.fromRGB(238,243,250),mix=.75,material=Enum.Material.Metal,reflect=.2,
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
			e.Rate=1.2 e.Lifetime=NumberRange.new(.4,.6) e.Speed=NumberRange.new(0,0)
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,s*1.8),NumberSequenceKeypoint.new(1,0)})
		end
	end
	e.Parent=parent
end
local function part(root: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number?)
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.Neon
	p.Transparency=transparency or 0 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=root
	return p
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
			if p:IsA("MeshPart") then p.TextureID="" end
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
