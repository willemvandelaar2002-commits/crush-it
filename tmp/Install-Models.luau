--!strict
-- Studio EDIT Command Bar: select the imported outer Models, then run this file.
-- Rebuilt installer; verifies all selected models before storing any clones.
-- Workspace originals are preserved. Existing templates are backed up.
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(not RunService:IsRunning(), "Stop Play mode before installing models")
local Rigs = {["ShadowShredder"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 3.91499996185, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 7.82999992371, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.88250017166, 0.0799999833107), ["size"] = Vector3.new(3.96000003815, 0.784999847412, 3.32000017166)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["Rotor_L"] = {["center"] = Vector3.new(-1.20000004768, 7.98000049591, -0.550000071526), ["size"] = Vector3.new(1.41999995708, 1.36275339127, 2.20000004768)}, ["Rotor_R"] = {["center"] = Vector3.new(1.20000004768, 7.98000049591, -0.550000071526), ["size"] = Vector3.new(1.41999995708, 1.36275339127, 2.20000004768)}}}, ["VoidVise"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 4.26999998093, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 8.53999996185, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.82250022888, 0.0799999833107), ["size"] = Vector3.new(3.96000003815, 0.905000209808, 3.32000017166)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["VoidRing"] = {["center"] = Vector3.new(0, 8.02000045776, -0.670000016689), ["size"] = Vector3.new(1.75999999046, 1.6200003624, 0.22000002861)}}}, ["EclipseEngine"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 3.91499996185, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 7.82999992371, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.9375, 0.124999940395), ["size"] = Vector3.new(4.36000013351, 0.894999504089, 3.40999984741)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["EclipseDial"] = {["center"] = Vector3.new(0, 7.71999979019, -0.480399996042), ["size"] = Vector3.new(2.27070021629, 2.27069950104, 0.348000109196)}}}, ["NightRipper"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 4.40000009537, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 8.80000019073, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.58750009537, 0.175000011921), ["size"] = Vector3.new(3.55999994278, 1.375, 3.11000013351)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}}}, ["HaloHammer"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 3.91499996185, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 7.82999992371, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.94000005722, 0.0799999833107), ["size"] = Vector3.new(4.57999992371, 1.35999965668, 3.11999988556)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["Halo"] = {["center"] = Vector3.new(0, 8.11999988556, -0.550000011921), ["size"] = Vector3.new(2.01999998093, 2.02000045776, 0.280000090599)}}}, ["CelestialCrusher"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 4.00500011444, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 8.01000022888, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.88250017166, 0.0949999690056), ["size"] = Vector3.new(4.15999984741, 0.784999847412, 3.34999990463)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["Planet"] = {["center"] = Vector3.new(0.0176221728325, 7.92000007629, -0.565562069416), ["size"] = Vector3.new(1.52475571632, 1.47999954224, 1.51112449169)}}}, ["ArchangelAnvil"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 4.42000007629, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 8.84000015259, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.88250017166, 0.0799999237061), ["size"] = Vector3.new(3.8599998951, 0.784999847412, 3.01999998093)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["Shield_L"] = {["center"] = Vector3.new(-3.27500009537, 6.40000009537, 0.422500014305), ["size"] = Vector3.new(1.55000019073, 2, 0.625)}, ["Shield_R"] = {["center"] = Vector3.new(3.27500009537, 6.40000009537, 0.422500014305), ["size"] = Vector3.new(1.55000019073, 2, 0.625)}}}, ["AuroraPress"] = {["parts"] = {["Frame"] = {["center"] = Vector3.new(0, 4.21192121506, 0.0587433576584), ["size"] = Vector3.new(7.69999980927, 8.42384243011, 6.01748657227)}, ["Ram"] = {["center"] = Vector3.new(0, 4.88250017166, 0.114999949932), ["size"] = Vector3.new(4.21000003815, 0.784999847412, 3.38999986649)}, ["PistonShaft"] = {["center"] = Vector3.new(0, 5.73750019073, -0.550000011921), ["size"] = Vector3.new(0.479999989271, 0.925000190735, 0.480000019073)}, ["AuroraStar"] = {["center"] = Vector3.new(0, 8.26397895813, -0.475000023842), ["size"] = Vector3.new(1.27441573143, 1.21204137802, 0.250000029802)}}}}
local plans = {}
local selected = Selection:Get()
assert(#selected > 0, "Select the imported crusher Models first")
local seen = {}
for _, original in selected do
 assert(original:IsA("Model"), "Select outer Models, not individual MeshParts")
 local rig = Rigs[original.Name]
 assert(rig, "Unknown crusher Model name: " .. original.Name)
 assert(not seen[original.Name], "Duplicate selected Model: " .. original.Name)
 seen[original.Name] = true
 local found = {}
 for _, item in original:GetDescendants() do
  if item:IsA("BasePart") then
   assert(rig.parts[item.Name], original.Name .. ": unexpected part " .. item.Name)
   assert(not found[item.Name], original.Name .. ": duplicate channel " .. item.Name)
   found[item.Name] = item
  end
 end
 for name in rig.parts do
  assert(found[name], original.Name .. ": missing channel " .. name)
 end
 local frame = found.Frame
 local expectedFrame = rig.parts.Frame
 local ratio = frame.Size.Magnitude / expectedFrame.size.Magnitude
 assert(ratio > 0.000001 and ratio < 1000000, "Invalid import scale")
 local origin = frame.Position - expectedFrame.center * ratio
 for name, authored in rig.parts do
  local part = found[name]
  local expectedSize = authored.size * ratio
  for _, axis in {"X", "Y", "Z"} do
   assert(math.abs(part.Size[axis] / expectedSize[axis] - 1) < 0.025,
    original.Name .. "/" .. name .. ": rotated/non-uniform import; reimport at original orientation")
  end
  local expectedCenter = origin + authored.center * ratio
  assert((part.Position - expectedCenter).Magnitude / ratio < 0.08,
   original.Name .. "/" .. name .. ": channel positions do not match; reimport without moving individual parts")
 end
 table.insert(plans, {original = original, ratio = ratio, rig = rig})
end
local clones = {}
local ok, problem = pcall(function()
 for _, plan in plans do
  local clone = plan.original:Clone()
  assert(clone, "Model is not Archivable: " .. plan.original.Name)
  table.insert(clones, clone)
  clone:ScaleTo(clone:GetScale() / plan.ratio)
  local frame = clone:FindFirstChild("Frame", true)
  assert(frame and frame:IsA("BasePart"), "Missing cloned Frame")
  local ground = frame.Position - plan.rig.parts.Frame.center
  clone.WorldPivot = CFrame.new(ground)
  clone:PivotTo(CFrame.new())
  for _, item in clone:GetDescendants() do
   if item:IsA("BasePart") then
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = true
    item.Color = Color3.new(1, 1, 1)
   end
  end
  clone:SetAttribute("BayFrontYaw", math.pi)
  clone:SetAttribute("Ready", true)
  clone:SetAttribute("ChaseModelRevision", 1)
 end
end)
if not ok then
 for _, clone in clones do clone:Destroy() end
 error(tostring(problem))
end
local destination = ServerStorage:FindFirstChild("SpecialCrusherMeshes")
assert(not destination or destination:IsA("Folder"), "SpecialCrusherMeshes must be a Folder")
local backups = ServerStorage:FindFirstChild("ChaseCrusherBackups")
assert(not backups or backups:IsA("Folder"), "ChaseCrusherBackups must be a Folder")
if not destination then
 destination = Instance.new("Folder")
 destination.Name = "SpecialCrusherMeshes"
 destination.Parent = ServerStorage
end
if not backups then
 backups = Instance.new("Folder")
 backups.Name = "ChaseCrusherBackups"
 backups.Parent = ServerStorage
end
for _, clone in clones do
 local previous = destination:FindFirstChild(clone.Name)
 if previous then
  previous.Name = clone.Name .. "_" .. tostring(DateTime.now().UnixTimestampMillis)
  previous.Parent = backups
 end
 clone.Parent = destination
 print("Installed " .. clone.Name)
end
print("Installed " .. tostring(#clones) .. " models. Save/publish the place. Merge motion metadata and upload icons separately.")
