--!strict
-- Crusher toolbar at the bottom of the screen (replaces Roblox's backpack bar
-- and the old OWNED tab). One tile per crusher that isn't in a bay: picture
-- (coated/fused shown in 3D), rarity colour, level and coating. Click a tile
-- to hold that crusher, click again to put it away; holding one, press E at a
-- bay to place or swap it. REMOVE on a bay plaque sends a crusher here. The
-- bin at the end recycles duplicates (click twice). Tools stay server-owned.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Rules = require(RS.Shared.CrusherRules)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local CrusherIcon = require(script.Parent.CrusherIcon)

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local INK = Style.Colors.Ink
local GOLD = Color3.fromRGB(255, 214, 60)
local TILE = 74

-- hide Roblox's own backpack bar (retry: SetCoreGuiEnabled can fail early)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) then return end
		task.wait(.5)
	end
end)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function text(parent: Instance, value: string, pos: UDim2, size: UDim2, textSize: number, z: number): TextLabel
	local t = make("TextLabel", { Text = value, Position = pos, Size = size, BackgroundTransparency = 1, Font = Enum.Font.FredokaOne,
		TextSize = textSize, TextColor3 = Color3.new(1, 1, 1), ZIndex = z }, parent)
	make("UIStroke", { Thickness = 2, Color = INK }, t)
	return t
end

local gui = make("ScreenGui", { Name = "CrusherHotbar", ResetOnSpawn = false, DisplayOrder = 3, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local bar = make("Frame", { Name = "Bar", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -8), Size = UDim2.fromOffset(300, TILE + 16),
	BackgroundColor3 = Color3.fromRGB(24, 28, 56), BackgroundTransparency = .25, Visible = false }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, bar)
make("UIStroke", { Color = INK, Thickness = 3 }, bar)
local list = make("ScrollingFrame", { Name = "Tiles", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -78, 1, -8), BackgroundTransparency = 1,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 4, ZIndex = 2 }, bar)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center }, list)
make("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, list)
local bin = make("TextButton", { Name = "RecycleDupes", Text = "🗑", AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, -6),
	Size = UDim2.fromOffset(58, 52), TextSize = 30, ZIndex = 3 }, bar)
Style.button(bin, Style.Colors.Red)
local binLabel = text(bar, "DUPES", UDim2.new(1, -66, 1, -20), UDim2.fromOffset(58, 16), 13, 4)
local count = text(bar, "", UDim2.fromOffset(10, -22), UDim2.fromOffset(140, 20), 16, 4)
count.TextXAlignment = Enum.TextXAlignment.Left
local hint = text(gui, "", UDim2.new(.5, -200, 1, -TILE - 52), UDim2.fromOffset(400, 26), 20, 4)
hint.AnchorPoint = Vector2.new(0, 0)

local state: any = nil
local tiles: { [string]: any } = {}
local signature = ""

local function character(): Model? return me.Character end
local function heldTool(): Tool?
	local char = character()
	local t = char and char:FindFirstChildOfClass("Tool")
	return if t and t:GetAttribute("InventoryId") ~= nil then t else nil
end
local function toolFor(id: string): Tool?
	local held = heldTool()
	if held and held:GetAttribute("InventoryId") == id then return held end
	local backpack = me:FindFirstChildOfClass("Backpack")
	if not backpack then return nil end
	for _, t in backpack:GetChildren() do
		if t:IsA("Tool") and t:GetAttribute("InventoryId") == id then return t end
	end
	return nil
end
local function extras(): { any }
	if not state then return {} end
	return Rules.duplicateExtras(state.items, state.bays, function(item) return item.stats and item.stats.cps or 0 end)
end

local function select(id: string)
	local char = character()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local held = heldTool()
	if held and held:GetAttribute("InventoryId") == id then hum:UnequipTools() return end
	local tool = toolFor(id)
	if tool then hum:EquipTool(tool) end
end

local function paintSelection()
	local held = heldTool()
	local id = held and held:GetAttribute("InventoryId")
	for key, t in tiles do
		local on = key == id
		t.stroke.Color = if on then GOLD else INK
		t.stroke.Thickness = if on then 4 else 2
		t.frame.Position = UDim2.fromOffset(0, if on then -4 else 0)
	end
	hint.Text = if held then "Press E at a bay to place it" else ""
end

local function rebuild()
	if not state then return end
	local busy = {} for _, id in state.bays do busy[id] = true end
	local items = {}
	for _, item in state.items do if not busy[item.id] then table.insert(items, item) end end
	table.sort(items, function(a, b)
		local ra, rb = C.rarity(a.rarity).rank, C.rarity(b.rarity).rank
		if ra ~= rb then return ra > rb end
		local ca, cb = a.stats and a.stats.cps or 0, b.stats and b.stats.cps or 0
		if ca ~= cb then return ca > cb end
		return a.id < b.id
	end)
	local keys = {}
	for _, item in items do table.insert(keys, item.id .. ":" .. item.level .. ":" .. item.modifier .. ":" .. tostring(item.fused)) end
	local sig = table.concat(keys, "|")
	if sig ~= signature then
		signature = sig
		for _, t in tiles do t.holder:Destroy() end
		table.clear(tiles)
		for order, item in items do
			local r = C.rarity(item.rarity)
			local holder = make("Frame", { Name = "Slot", Size = UDim2.fromOffset(TILE, TILE), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 2 }, list)
			local frame = make("TextButton", { Name = "Tile", Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(TILE, TILE), ZIndex = 3 }, holder)
			Style.panel(frame :: any, r.color, Style.darken(r.color, .35))
			;(frame:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 10)
			local stroke = frame:FindFirstChild("Outline") :: UIStroke
			stroke.Thickness = 2
			CrusherIcon.new(frame, item.type, { position = UDim2.fromOffset(4, 2), size = UDim2.new(1, -8, 1, -20), zIndex = 4,
				modifier = if item.modifier ~= "Standard" then item.modifier else nil, fused = item.fused })
			local lv = text(frame, "Lv " .. item.level, UDim2.new(0, 0, 1, -20), UDim2.new(1, 0, 0, 18), 15, 5)
			if item.modifier ~= "Standard" or item.fused then
				local tag = text(frame, (if item.fused then "★" else "") .. (if item.modifier ~= "Standard" then item.modifier:sub(1, 1) else ""),
					UDim2.fromOffset(3, 1), UDim2.fromOffset(24, 16), 14, 5)
				tag.TextColor3 = GOLD tag.TextXAlignment = Enum.TextXAlignment.Left
			end
			local _ = lv
			frame.Activated:Connect(function() select(item.id) end)
			tiles[item.id] = { holder = holder, frame = frame, stroke = stroke }
		end
		local view = workspace.CurrentCamera.ViewportSize
		local want = #items * (TILE + 6) + 4
		bar.Size = UDim2.fromOffset(math.clamp(want, 120, math.max(300, view.X * .6)) + 86, TILE + 16)
		bar.Visible = true
	end
	count.Text = #items .. " IN HOTBAR · " .. #state.items .. "/" .. C.MaxInventory
	local n = #extras()
	binLabel.Text = if n > 0 then n .. " DUPES" else "DUPES"
	Style.setButtonColor(bin, if n > 0 then Style.Colors.Red else Color3.fromRGB(104, 116, 138))
	paintSelection()
end

local binPending = false
bin.Activated:Connect(function()
	local n = #extras()
	if n == 0 then hint.Text = "No duplicates to recycle." return end
	if not binPending then
		binPending = true binLabel.Text = "SURE?" hint.Text = "Click the bin again to recycle " .. n .. " duplicate" .. (if n == 1 then "" else "s") .. "."
		task.delay(3, function() if binPending then binPending = false rebuild() end end)
		return
	end
	binPending = false
	actionRemote:FireServer("RecycleDuplicates", {})
end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.items) ~= "table" then return end
	state = v
	rebuild()
end)
local function watchCharacter(char: Model)
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then paintSelection() end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then paintSelection() end end)
	paintSelection()
end
me.CharacterAdded:Connect(watchCharacter)
if me.Character then watchCharacter(me.Character) end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() signature = "" rebuild() end)
