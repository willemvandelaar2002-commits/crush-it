--!strict
-- STUDIO EDIT MODE ONLY. First sync FactoryBearRigData + FactoryBearRig into
-- ReplicatedStorage.Shared, import Model/FactoryBear.fbx, select its Model,
-- then run this file in the Command Bar. This does not replace the old teddy.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and not Run:IsRunning(),"Stop Play before installing the bear")
local RS=game:GetService("ReplicatedStorage")
local Selection=game:GetService("Selection")
local D=require(RS.Shared.FactoryBearRigData)
local selected=Selection:Get()
assert(#selected==1 and selected[1]:IsA("Model"),"Select only the imported FactoryBear Model")
local m=selected[1]:Clone() m.Name="FactoryBear" m.PrimaryPart=nil
local parts={}
for _,p in m:GetDescendants() do
	if p:IsA("BasePart") then
		assert(not parts[p.Name],"Repeated imported mesh name: "..p.Name)
		parts[p.Name]=p p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=true
		p.Color=Color3.new(1,1,1)
	elseif p:IsA("LuaSourceContainer") or p:IsA("Constraint") or p:IsA("JointInstance") then p:Destroy() end
end
local sourceHeight=D.source_bounds.size[3]
local bounds,size=m:GetBoundingBox()
assert(size.Y>size.X and size.Y>size.Z,"Bear must be upright before setup; check FBX import orientation")
local unit=size.Y/sourceHeight
local center=D.source_bounds.center
-- 28 Oct (checked in Studio): the importer already turns the meshes 180 degrees
-- about Y (as with the crate crushers), so the raw import faces -Z. No extra
-- turn; the source centre is mirrored to match. FrontYaw stays pi for the rig basis.
local sourceOrigin=bounds.Position-Vector3.new(-center[1],center[3],center[2])*unit
local frontYaw=math.pi
m.WorldPivot=CFrame.new(sourceOrigin)
m:PivotTo(CFrame.identity)
local desiredHeight=sourceHeight
m:ScaleTo(m:GetScale()*desiredHeight/size.Y)
local sourceScale=desiredHeight/sourceHeight
local basis=CFrame.Angles(0,frontYaw,0)*CFrame.fromMatrix(Vector3.zero,
	Vector3.new(1,0,0),Vector3.new(0,0,-1),Vector3.new(0,1,0))
local groundShift=Vector3.new(0,-D.source_bounds.min[3]*sourceScale,0)
for _,p in parts do p.CFrame+=groundShift end
m.WorldPivot=CFrame.identity
for _,def in D.parts do
	local p=assert(parts[def.name],"Missing FBX mesh: "..def.name)
	local v=def.pivot
	p:SetAttribute("RigPivot",basis:VectorToWorldSpace(Vector3.new(v[1],v[2],v[3])*sourceScale)+groundShift)
	p:SetAttribute("RigRest",m:GetPivot():ToObjectSpace(p.CFrame))
	p:SetAttribute("RigParent",def.parent or "")
end
-- MeshPart Color doesn't tint a texture: clear it so the eyes/core take their colour
for _,name in {"Eye_L","Eye_R","Core"} do parts[name].TextureID="" end
for _,name in {"Eye_L","Eye_R"} do parts[name].Color=Color3.fromRGB(91,232,255) parts[name].Material=Enum.Material.Neon end
parts.Core.Color=Color3.fromRGB(174,77,255) parts.Core.Material=Enum.Material.Neon
m:SetAttribute("FactoryBearReady",true) m:SetAttribute("RigCapturedScale",m:GetScale())
m:SetAttribute("FrontYaw",frontYaw) m:SetAttribute("AuthoredHeight",sourceHeight)
m:SetAttribute("AssetVersion",1)
local library=RS:FindFirstChild("FactoryEventMeshes")
if not library then library=Instance.new("Folder") library.Name="FactoryEventMeshes" library.Parent=RS end
local old=library:FindFirstChild("FactoryBear")
if old then
	if not library:FindFirstChild("FactoryBear_Previous") then old.Name="FactoryBear_Previous" else old:Destroy() end
end
m.Parent=library
print("Factory Bear ready in ReplicatedStorage.FactoryEventMeshes.FactoryBear. Save/Publish the place after verification.")
