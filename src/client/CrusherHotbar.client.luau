--!strict
-- Crusher toolbar at the bottom of the screen (replaces Roblox's backpack bar
-- and the old OWNED tab). One tile per crusher that isn't in a bay: picture
-- (coated/fused shown in 3D), rarity colour, level and coating. Click a tile
-- (or press its number key 1-9, 0 for the 10th) to hold that crusher, again to
-- put it away; holding one, press E at a bay to place or swap it. REMOVE on a
-- bay plaque sends a crusher here. Tools stay server-owned.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local CrusherIcon = require(script.Parent.CrusherIcon)

local me = Players.LocalPlayer
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
local list = make("ScrollingFrame", { Name = "Tiles", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -8), BackgroundTransparency = 1,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 4, ZIndex = 2 }, bar)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center }, list)
make("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, list)
local hint = text(gui, "", UDim2.new(.5, -200, 1, -TILE - 82), UDim2.fromOffset(400, 26), 22, 4)
hint.AnchorPoint = Vector2.new(0, 0)
-- 30 Oct (phone patch): 48 px tiles on phones, still easy to tap
Style.phoneFit(bar, { scale = 0.65 })
Style.phoneFit(hint, { scale = 0.65, anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 1, -TILE * 0.65 - 46) })

local state: any = nil
local tiles: { [string]: any } = {}
local signature = ""
local order_: { [number]: string } = {}

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

-- 28 Oct: hidden while a factory event runs (you carry cores then; a click
-- on a tile would swap them for a crusher). FactoryEvent.client sets the flag.
local itemCount = 0
local function eventOn(): boolean return me:GetAttribute("FactoryEventRunning") == true end
local function showBar() bar.Visible = itemCount > 0 and not eventOn() end
me:GetAttributeChangedSignal("FactoryEventRunning"):Connect(function()
	showBar()
	if eventOn() then
		local char = me.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local t = char and char:FindFirstChildOfClass("Tool")
		if hum and t and t:GetAttribute("InventoryId") ~= nil then hum:UnequipTools() end -- put a held crusher away
	end
end)
local function select(id: string)
	if eventOn() then return end
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
		table.clear(tiles) table.clear(order_)
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
			if order <= 10 then
				local key = text(frame, tostring(order % 10), UDim2.new(1, -20, 0, 1), UDim2.fromOffset(18, 16), 15, 5)
				key.TextXAlignment = Enum.TextXAlignment.Right
			end
			frame.Activated:Connect(function() select(item.id) end)
			tiles[item.id] = { holder = holder, frame = frame, stroke = stroke }
			order_[order] = item.id
		end
		local view = workspace.CurrentCamera.ViewportSize
		local want = #items * (TILE + 6) + 4
		bar.Size = UDim2.fromOffset(math.clamp(want, 80, math.max(300, view.X * .6)) + 16, TILE + 16)
		itemCount = #items
		showBar()
	end
	paintSelection()
end

-- number keys: 1-9, 0 = 10th tile (not while typing in chat or a text box)
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9, [Enum.KeyCode.Zero] = 10 }
-- Bound above Roblox's own backpack keys and sunk, so a press only toggles once.
local CAS = game:GetService("ContextActionService")
local list_: { Enum.KeyCode } = {}
for key in KEYS do table.insert(list_, key) end
CAS:BindActionAtPriority("CrusherHotbarKeys", function(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if UIS:GetFocusedTextBox() or eventOn() then return Enum.ContextActionResult.Pass end
	local id = order_[KEYS[input.KeyCode]]
	if id then select(id) end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 100, table.unpack(list_))

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
