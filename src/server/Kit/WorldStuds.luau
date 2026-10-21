--!strict
-- Explicit environment-only rollout. Legacy Style.studs and press builders
-- remain unchanged; only selected plastic world surfaces opt into materials.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local WorldStuds = {}
local PLOT_SCENERY: { [string]: boolean } = { Floor = true, Island = true, Decor = true, PileZone = true }

local function hasStudTreatment(p: BasePart): (boolean, boolean)
	local overlays, backup = false, false
	for _, item in p:GetChildren() do
		if item:IsA("Texture") and item.Name == "Studs" and item.Texture == Style.Studs.Texture then
			overlays = true
		elseif item:IsA("Folder") and item:GetAttribute("StyleStudMaterialBackup") == true then
			backup = true
		end
	end
	return overlays, backup
end

-- Returning false prunes these complete subtrees, including animated parts.
local function excluded(item: Instance): boolean
	return item.Name == "Press" or item.Name == "MegaCrusher" or item.Name == "HelperYard"
end

function WorldStuds.apply(): number
	local enabled = Style.Studs.UseWorldMaterials
	local changed, visited = 0, 0
	local function visit(item: Instance)
		if excluded(item) then return end
		if item:IsA("BasePart") then
			local overlays, backup = hasStudTreatment(item)
			local plastic = item.Material == Enum.Material.SmoothPlastic or item.Material == Enum.Material.Plastic
			if backup or (enabled and overlays and plastic) then
				if Style.materialStuds(item, enabled) then changed += 1 end
			end
			visited += 1
			if visited % 128 == 0 then task.wait() end
		end
		-- Snapshot after conversion; the helper's backup contains only textures.
		for _, child in item:GetChildren() do
			if child:IsA("BasePart") or child:IsA("Model")
				or (child:IsA("Folder") and child:GetAttribute("StyleStudMaterialBackup") ~= true) then
				visit(child)
			end
		end
	end

	local world = Workspace:FindFirstChild("World")
	if world then visit(world) end
	for _, root in Workspace:GetChildren() do
		if root.Name ~= "Plots" then continue end
		for _, model in root:GetChildren() do
			if model.Name == "Hub" then
				visit(model)
			elseif model.Name:match("^Plot%d+$") then
				for _, child in model:GetChildren() do
					if PLOT_SCENERY[child.Name] then visit(child) end
				end
			end
		end
	end
	return changed
end

return WorldStuds
