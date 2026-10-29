--!strict
-- STUDIO EDIT MODE ONLY. Import the three FBXs in this folder (3D Importer, keep
-- the mesh names) so Workspace has Models named PumpkinForeman, PumpkinCore and
-- CandySoul, sync Shared.HalloweenRigData, then run this file in the Command Bar.
-- Copies land in ReplicatedStorage.FactoryEventMeshes; the Workspace imports are
-- left alone (move or delete them afterwards). The normal Factory Bear stays.
-- Same maths as assets/factory-bear/Install-Bear.luau (Studio's importer turns
-- these FBXs 180 degrees about Y, so the source centre is mirrored and the rig
-- basis keeps FrontYaw = pi).
local Run = game:GetService("RunService")
assert(Run:IsStudio() and not Run:IsRunning(), "Stop Play before installing the Halloween models")
local RS = game:GetService("ReplicatedStorage")
local Data = require(RS.Shared.HalloweenRigData)

local LIME = Color3.fromRGB(184, 255, 68)
local CANDLE = Color3.fromRGB(255, 196, 70)

local library = RS:FindFirstChild("FactoryEventMeshes")
if not library then
	library = Instance.new("Folder")
	library.Name = "FactoryEventMeshes"
	library.Parent = RS
end

local function prepare(name: string): (Model, { [string]: BasePart }, any)
	local source = workspace:FindFirstChild(name)
	assert(source and source:IsA("Model"), "Import " .. name .. ".fbx into Workspace first")
	local m = source:Clone()
	m.Name = name
	m.PrimaryPart = nil
	local parts: { [string]: BasePart } = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			assert(not parts[p.Name], name .. ": repeated mesh name " .. p.Name)
			parts[p.Name] = p
			p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false p.CastShadow = true
			p.Color = Color3.new(1, 1, 1)
		elseif p:IsA("LuaSourceContainer") or p:IsA("Constraint") or p:IsA("JointInstance") then
			p:Destroy()
		end
	end
	local D = Data[name]
	for _, def in D.parts do assert(parts[def.name], name .. ": missing mesh " .. def.name) end
	return m, parts, D
end

local function glow(p: BasePart, color: Color3)
	if p:IsA("MeshPart") then p.TextureID = "" end
	p.Color = color
	p.Material = Enum.Material.Neon
	p.CastShadow = false
end

local function store(m: Model)
	local old = library:FindFirstChild(m.Name)
	if old then old:Destroy() end
	m.Parent = library
end

-- 1. The boss: rigged like the Factory Bear (same 20 channels)
do
	local m, parts, D = prepare("PumpkinForeman")
	local sourceHeight = D.source_bounds.size[3]
	local bounds, size = m:GetBoundingBox()
	assert(size.Y > size.X and size.Y > size.Z, "PumpkinForeman must be upright; check the FBX import orientation")
	local unit = size.Y / sourceHeight
	local center = D.source_bounds.center
	local sourceOrigin = bounds.Position - Vector3.new(-center[1], center[3], center[2]) * unit
	local frontYaw = math.pi
	m.WorldPivot = CFrame.new(sourceOrigin)
	m:PivotTo(CFrame.identity)
	m:ScaleTo(m:GetScale() * sourceHeight / size.Y)
	local basis = CFrame.Angles(0, frontYaw, 0) * CFrame.fromMatrix(Vector3.zero, Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0))
	local groundShift = Vector3.new(0, -D.source_bounds.min[3], 0)
	for _, p in parts do p.CFrame += groundShift end
	m.WorldPivot = CFrame.identity
	for _, def in D.parts do
		local p = parts[def.name]
		local v = def.pivot
		p:SetAttribute("RigPivot", basis:VectorToWorldSpace(Vector3.new(v[1], v[2], v[3])) + groundShift)
		p:SetAttribute("RigRest", m:GetPivot():ToObjectSpace(p.CFrame))
		p:SetAttribute("RigParent", def.parent or "")
	end
	glow(parts.Eye_L, CANDLE) glow(parts.Eye_R, CANDLE) glow(parts.Core, LIME)
	m:SetAttribute("FactoryBearReady", true) -- the shared rig (FactoryBearRig) accepts it
	m:SetAttribute("RigCapturedScale", m:GetScale())
	m:SetAttribute("FrontYaw", frontYaw)
	m:SetAttribute("AuthoredHeight", sourceHeight)
	m:SetAttribute("EyeColor", CANDLE)
	m:SetAttribute("EyeAngryColor", LIME)
	m:SetAttribute("CoreColor", LIME)
	m:SetAttribute("AssetVersion", 1)
	store(m)
end

-- 2/3. The crush target and the carried candy: authored size, pivot in the middle
for _, spec in { { name = "PumpkinCore", glow = "Glow" }, { name = "CandySoul", glow = "CandyGlow" } } do
	local m, parts, D = prepare(spec.name)
	local _, size = m:GetBoundingBox()
	local sourceHeight = D.source_bounds.size[3]
	m:ScaleTo(m:GetScale() * sourceHeight / size.Y)
	local box = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(box.Position)
	m:PivotTo(CFrame.identity)
	glow(parts[spec.glow], LIME)
	m:SetAttribute("HalloweenReady", true)
	m:SetAttribute("AssetVersion", 1)
	store(m)
end

print("Halloween models ready in ReplicatedStorage.FactoryEventMeshes (PumpkinForeman, PumpkinCore, CandySoul). Save/Publish the place.")
