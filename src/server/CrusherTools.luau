--!strict
-- Owned crushers that are not in a bay live in the Roblox backpack (the
-- standard hotbar at the bottom), like the reference game's ores: one Tool per
-- crusher, named "Gearbox Crusher [Lvl 3]". Holding one shows a mini model in
-- your hand and its name/rarity above you; walk to a bay and use its prompt or
-- EQUIP button to place it there (CrusherGame). The data stays authoritative:
-- tools are rebuilt from the profile, never trusted.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.Shared.CrusherConfig)
local Style = require(RS.Shared.Kit.Style)
local Finish = require(RS.Shared.CrusherFinish)
local T = {}

local HOLD_SIZE = 2.2 -- studs, the mini model in your hand

local function toolName(item: any): string
	return C.typeById(item.type).name .. " [Lvl " .. item.level .. "]"
end

-- Mini copy of the crusher welded to the handle (only while held).
local function holdModel(tool: Tool, item: any)
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local folder = RS:FindFirstChild("CrusherPreviewModels")
	local source = folder and folder:FindFirstChild(item.type)
	if not handle or tool:FindFirstChild("Held") then return end
	local held = Instance.new("Model")
	held.Name = "Held"
	local holder: BasePart = handle
	if source and source:IsA("Model") then
		for _, child in source:Clone():GetChildren() do child.Parent = held end
		Finish.apply(held,item.modifier)
		local _, size = held:GetBoundingBox()
		held:ScaleTo(HOLD_SIZE / math.max(size.X, size.Y, size.Z, 0.1))
		-- carried in front of the chest, upright, front facing the way you face.
		-- Welded to the body (not the hand) so the arm pose can't tilt it.
		local char = tool.Parent
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then held:Destroy() return end
		local facing = root.CFrame.Rotation * CFrame.Angles(0, math.pi, 0) -- preview fronts face +Z
		local centre = held:GetBoundingBox().Position
		local at = (root.CFrame * CFrame.new(0, 0.3, -1.9)).Position
		held:PivotTo(CFrame.new(at) * facing * CFrame.new(-centre) * held:GetPivot())
		holder = root
	end
	for _, p in held:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false p.CanCollide = false p.CanTouch = false p.CanQuery = false p.Massless = true
			local weld = Instance.new("WeldConstraint") weld.Part0 = holder weld.Part1 = p weld.Parent = p
		end
	end
	if tool:FindFirstChild("Held") then held:Destroy() return end -- equipped twice quickly
	held.Parent = tool
	-- name, rarity and level above your head while you hold it
	local r = C.rarity(item.rarity)
	local tag = Instance.new("BillboardGui")
	tag.Name = "HeldTag" tag.Size = UDim2.fromOffset(220, 70) tag.StudsOffset = Vector3.new(0, 4.6, 0)
	tag.MaxDistance = 60 tag.LightInfluence = 0 tag.Parent = handle
	local function line(text: string, y: number, h: number, color: Color3)
		local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextScaled = true
		l.Position = UDim2.fromScale(0, y) l.Size = UDim2.fromScale(1, h) l.Parent = tag
		Style.text(l, 2) l.TextColor3 = color
	end
	line(C.typeById(item.type).name, 0, 0.45, Color3.new(1, 1, 1))
	line(item.rarity .. (if item.modifier ~= "Standard" then " · " .. item.modifier else ""), 0.45, 0.28, r.color:Lerp(Color3.new(1, 1, 1), 0.2))
	line("Lvl " .. item.level, 0.73, 0.27, Color3.fromRGB(255, 230, 140))
end

local function dropHold(tool: Tool)
	local held = tool:FindFirstChild("Held") if held then held:Destroy() end
	local handle = tool:FindFirstChild("Handle")
	local tag = handle and handle:FindFirstChild("HeldTag") if tag then tag:Destroy() end
end

local function makeTool(item: any): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolName(item)
	tool.ToolTip = item.rarity .. (if item.modifier~="Standard" then " · "..item.modifier else "") .. " crusher · place it in a bay"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.GripPos = Vector3.new(0, -0.6, 0.9)
	tool:SetAttribute("InventoryId", item.id)
	tool:SetAttribute("Level", item.level)
	tool:SetAttribute("Modifier",item.modifier)
	local handle = Instance.new("Part")
	handle.Name = "Handle" handle.Size = Vector3.new(1, 1, 1) handle.Transparency = 1
	handle.CanCollide = false handle.CanTouch = false handle.CanQuery = false handle.Massless = true
	handle.Parent = tool
	tool.Equipped:Connect(function() task.spawn(holdModel, tool, item) end)
	tool.Unequipped:Connect(function() dropHold(tool) end)
	return tool
end

-- Make the backpack (plus the tool in hand) match the unequipped crushers.
function T.sync(player: Player, d: any)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	local inBay = {}
	for _, id in d.crushers.equipped do inBay[id] = true end
	local want = {}
	for _, item in d.crushers.owned do if not inBay[item.id] then want[item.id] = item end end
	local have = {}
	local function scan(container: Instance?)
		if not container then return end
		for _, tool in container:GetChildren() do
			local id = tool:IsA("Tool") and tool:GetAttribute("InventoryId")
			if typeof(id) == "string" then
				local item = want[id]
				if not item or have[id] or tool:GetAttribute("Level") ~= item.level or tool:GetAttribute("Modifier")~=item.modifier then tool:Destroy()
				else have[id] = true end
			end
		end
	end
	scan(backpack) scan(player.Character)
	-- in owned order, so the hotbar keeps a stable order (new ones at the end)
	for _, item in d.crushers.owned do
		if want[item.id] and not have[item.id] then makeTool(item).Parent = backpack end
	end
end

-- The crusher the player is holding, if any (its inventory id).
function T.held(player: Player): string?
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	local id = tool and tool:GetAttribute("InventoryId")
	return if typeof(id) == "string" then id else nil
end

return T
