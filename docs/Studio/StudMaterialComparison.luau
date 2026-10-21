--!strict
-- Temporary diagnostic: paste into Studio's SERVER Command Bar during Play,
-- after the world finishes loading. Stop Play to remove it. Not Rojo-managed.
local Workspace = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")
local Style = require(game:GetService("ReplicatedStorage").Shared.Kit.Style)

local previous = Workspace:FindFirstChild("StudMaterialComparison")
if previous then
	assert(previous:GetAttribute("StyleMaterialComparison") == true, "Comparison name is already in use")
	previous:Destroy()
end

local source: BasePart? = nil
for _, item in Workspace:GetDescendants() do
	if item:IsA("BasePart") and item.Name == "Top" and item.Parent
		and item.Parent.Name == "Floor" then
		source = item
		break
	end
end
assert(source, "Start Play and wait for a plot Floor.Top before running this comparison")

local variant = MaterialService:FindFirstChild(Style.Studs.MaterialVariant)
-- Match the imported tile on the sample's legacy image, not by editing the
-- shared variant. World defaults remain at Style.Studs.PerTile (2 studs).
local tile = if variant and variant:IsA("MaterialVariant") then variant.StudsPerTile else Style.Studs.PerTile
local model = Instance.new("Model")
model.Name = "StudMaterialComparison"
model:SetAttribute("StyleMaterialComparison", true)
model:SetAttribute("UseImportedStuds", true)
model:SetAttribute("ComparisonTile", tile)
model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

-- A representative portion of the actual floor, safely above the hub.
-- Both parts have identical colour, size, orientation and existing textures.
local origin = CFrame.new(0, 140, 0)
local function sample(name: string, x: number): BasePart
	local p = source:Clone() :: BasePart
	p.Name = name
	p.Size = Vector3.new(24, source.Size.Y, 20)
	p.CFrame = origin * CFrame.new(x, -p.Size.Y / 2, 0)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	Style.studs(p, { Enum.NormalId.Top }, tile)
	p.Parent = model
	return p
end
sample("A_LegacyTexture", -15)
local imported = sample("B_ImportedStuds", 15)

local function apply()
	local applied = Style.materialStuds(imported, model:GetAttribute("UseImportedStuds") == true)
	model:SetAttribute("MaterialApplied", applied)
end
apply()
model:GetAttributeChangedSignal("UseImportedStuds"):Connect(apply)
model.Parent = Workspace

print("Stud comparison: LEFT = legacy image, RIGHT = imported Studs. Tile:", tile)
print("Toggle Workspace.StudMaterialComparison.UseImportedStuds; Stop Play to clean up.")
if not model:GetAttribute("MaterialApplied") then
	warn("Imported Studs variant is missing; both samples use the legacy texture fallback.")
end
