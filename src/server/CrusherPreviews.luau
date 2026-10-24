--!strict
-- One static, sanitised copy of each live type for collection ViewportFrames.
-- Source templates remain in ServerStorage. This folder contains visuals only.
local RS = game:GetService("ReplicatedStorage")
local Tags = game:GetService("CollectionService")
local C = require(RS.Shared.CrusherConfig)
local PressBuilder = require(script.Parent.PressBuilder)
local Special = require(script.Parent.SpecialCrushers)
local Catalog = require(script.Parent.CatalogCrushers)
local P = {}

local function clean(model: Model)
	for _, node in model:GetDescendants() do
		for _, tag in Tags:GetTags(node) do Tags:RemoveTag(node, tag) end
		if node:IsA("BasePart") then
			node.Anchored = true
			node.CanCollide = false
			node.CanTouch = false
			node.CanQuery = false
		elseif not (node:IsA("Model") or node:IsA("Folder") or node:IsA("DataModelMesh")
			or node:IsA("SurfaceAppearance") or node:IsA("Texture") or node:IsA("Decal")) then
			node:Destroy()
		end
	end
	for _, tag in Tags:GetTags(model) do Tags:RemoveTag(model, tag) end
end

function P.start()
	if RS:FindFirstChild("CrusherPreviewModels") then return end
	local folder = Instance.new("Folder")
	folder.Name = "CrusherPreviewModels"
	folder.Parent = RS
	for _, def in C.Types do
		local ok, problem = pcall(function()
			local special = Catalog.build(CFrame.new(),def.id) or (if def.template then Special.build(CFrame.new(), def.template) else nil)
			local model = if special then special.model else PressBuilder.build(CFrame.new(), def.tier).model
			clean(model)
			local cf, size = model:GetBoundingBox()
			-- Centre in a common small preview space; preserve the whole assembly.
			model:PivotTo(model:GetPivot() - cf.Position)
			model:ScaleTo(model:GetScale() * 8 / math.max(size.X, size.Y, size.Z))
			model.Name = def.id
			model:SetAttribute("CrusherType", def.id)
			model:SetAttribute("ImportedSpecial", def.template ~= nil and special ~= nil)
			model.Parent = folder
		end)
		if not ok then warn("Crusher preview unavailable for " .. def.id .. ": " .. tostring(problem)) end
	end
end

return P
