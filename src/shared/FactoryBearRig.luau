--!strict
-- Put beside FactoryBearRigData in ReplicatedStorage.Shared. One cosmetic
-- animator per bear; call capture AFTER cloning, scaling and positioning.
-- 29 Oct: also drives the Halloween Pumpkin Foreman (same 20 channels). A model
-- may carry its own parents (part attribute RigParent) and glow colours (model
-- attributes EyeColor, EyeAngryColor, CoreColor).
local D=require(script.Parent.FactoryBearRigData)
local Rig={}
local CYAN=Color3.fromRGB(91,232,255)
local RED=Color3.fromRGB(255,54,84)
local PURPLE=Color3.fromRGB(174,77,255)
local function smooth(a,b,t)
	local v=math.clamp((t-a)/(b-a),0,1) return v*v*(3-2*v)
end
local function rotationBasis(yaw)
	-- Authoring +Z up, -Y front -> FBX +Y up, +Z front, then FrontYaw.
	return CFrame.Angles(0,yaw,0)*CFrame.fromMatrix(Vector3.zero,
		Vector3.new(1,0,0),Vector3.new(0,0,-1),Vector3.new(0,1,0))
end
function Rig.capture(model)
	assert(model:IsA("Model") and model:GetAttribute("FactoryBearReady")==true,"Run Install-Bear on the imported model first")
	local baseScale=model:GetAttribute("RigCapturedScale") or model:GetScale()
	local scale=model:GetScale()/baseScale
	local basis=rotationBasis(model:GetAttribute("FrontYaw") or math.pi)
	local nodes={} local byName={}
	for _,part in model:GetDescendants() do if part:IsA("BasePart") then byName[part.Name]=part end end
	for _,def in D.parts do
		local part=assert(byName[def.name],"Factory Bear missing "..def.name)
		local rest=assert(part:GetAttribute("RigRest"),"Missing rest pose: "..def.name)
		local pivot=assert(part:GetAttribute("RigPivot"),"Missing pivot: "..def.name)
		local parent=part:GetAttribute("RigParent")
		if type(parent)~="string" then parent=def.parent elseif parent=="" then parent=nil end
		nodes[def.name]={part=part,rest=CFrame.new(rest.Position*scale)*rest.Rotation,pivot=pivot*scale,parent=parent}
	end
	return {model=model,nodes=nodes,basis=basis,basisInverse=basis:Inverse(),
		eye=model:GetAttribute("EyeColor") or CYAN,angry=model:GetAttribute("EyeAngryColor") or RED,heart=model:GetAttribute("CoreColor") or PURPLE}
end
function Rig.pose(rig,mode,age)
	local t=math.max(0,age or 0)
	local corrupt=if mode=="Friendly" then 0 elseif mode=="Recover" then 1-smooth(0,2,t)
		elseif mode=="Corrupted" then smooth(0,1.2,t) else 1
	local lift=if mode=="Windup" then smooth(0,1.5,t) elseif mode=="Slam" then 1-smooth(0,.3,t) else 0
	local roar=if mode=="Roar" then smooth(0,.35,t)*(1-smooth(1.2,1.8,t)) else 0
	local slump=if mode=="Defeated" then smooth(0,.7,t) else 0
	local angles={Head=Vector3.new(.035*math.sin(t*2)+.14*roar+.25*slump,0,.035*math.sin(t*1.3)),
		Jaw=Vector3.new(.13*corrupt+.33*roar,0,0),Core=Vector3.new(0,t*1.2*corrupt,0),CoreRing=Vector3.new(0,-t*.3*corrupt,0)}
	for _,pair in {{"L",-1},{"R",1}} do
		local side,s=pair[1],pair[2]
		angles["Brow_"..side]=Vector3.new(0,-s*.4*corrupt,0)
		angles["Ear_"..side]=Vector3.new(0,s*.1*corrupt+s*.03*math.sin(t*2),0)
		angles["Arm_"..side]=Vector3.new(-.08*(math.sin(t*1.8+s)-math.sin(s))-1.55*lift-.45*roar,s*.08*corrupt+s*.15*lift,0)
		angles["Paw_"..side]=Vector3.new(.13*lift-.12*roar,0,0)
		angles["Door_"..side]=Vector3.new(0,0,s*1.25*corrupt)
	end
	local transforms={}
	local function transform(name)
		if transforms[name] then return transforms[name] end
		local node=rig.nodes[name] local a=angles[name] or Vector3.zero
		local rotation=rig.basis*CFrame.Angles(a.X,a.Y,a.Z)*rig.basisInverse
		local localMotion=CFrame.new(node.pivot)*rotation*CFrame.new(-node.pivot)
		local parent=if node.parent then transform(node.parent) else CFrame.identity
		local result=parent*localMotion transforms[name]=result return result
	end
	local base=rig.model:GetPivot()
	for name,node in rig.nodes do
		if node.part.Parent then node.part.CFrame=base*transform(name)*node.rest end
	end
	for _,name in {"Eye_L","Eye_R"} do
		local p=rig.nodes[name].part p.Color=rig.eye:Lerp(rig.angry,corrupt) p.Material=Enum.Material.Neon
	end
	local heart=rig.nodes.Core.part heart.Color=rig.heart heart.Material=Enum.Material.Neon
end
function Rig.reset(rig)
	local base=rig.model:GetPivot()
	for _,node in rig.nodes do if node.part.Parent then node.part.CFrame=base*node.rest end end
	for _,name in {"Eye_L","Eye_R"} do rig.nodes[name].part.Color=rig.eye end
	rig.nodes.Core.part.Color=rig.heart
end
function Rig.core(template,at,diameter)
	assert(template:GetAttribute("FactoryBearReady")==true,"Factory Bear is not ready")
	local core=Instance.new("Model") core.Name="BearCore"
	local base=template:GetPivot()
	local source=template:FindFirstChild("Core",true)
	local ring=template:FindFirstChild("CoreRing",true)
	assert(source and ring,"Missing bear core meshes")
	local factor=template:GetScale()/(template:GetAttribute("RigCapturedScale") or template:GetScale())
	local pivot=source:GetAttribute("RigPivot")*factor
	local coreOrigin=base*CFrame.new(pivot)
	for _,part in {source,ring} do
		local clone=part:Clone() clone.Anchored=true clone.CanCollide=false clone.CanTouch=false clone.CanQuery=false
		local rest=part:GetAttribute("RigRest")
		rest=CFrame.new(rest.Position*factor)*rest.Rotation
		clone.CFrame=at*coreOrigin:ToObjectSpace(base*rest) clone.Parent=core
	end
	core.WorldPivot=at
	local _,size=core:GetBoundingBox()
	core:ScaleTo(core:GetScale()*diameter/math.max(size.X,size.Y,size.Z))
	core:FindFirstChild("Core").Color=template:GetAttribute("CoreColor") or PURPLE core:FindFirstChild("Core").Material=Enum.Material.Neon
	return core
end
return Rig
