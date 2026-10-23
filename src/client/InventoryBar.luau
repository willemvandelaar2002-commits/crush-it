--!strict
-- Bottom-centre inventory bar: your crushers (newest first) as rarity-coloured
-- slots with a 3D preview. Equipped ones get a green check. Clicking a slot (or
-- the "+N" slot) opens INDEX > OWNED. A crusher you buy from a pedestal flies
-- from the pedestal into the first slot, which pops with "NEW!".
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local C = require(RS.Shared.CrusherConfig)
local Style = require(RS.Shared.Kit.Style)
local Icons = require(RS.Shared.Icons)

local B = {}
local INK = Style.Colors.Ink
local SLOTS, SIZE, GAP = 8, 78, 8

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local node = Instance.new(class)
	for k, v in props do (node :: any)[k] = v end
	node.Parent = parent
	return node
end

-- Static 3D preview of a crusher type (server: CrusherPreviewModels).
local function preview(parent: GuiObject, typeId: string): boolean
	local folder = RS:FindFirstChild("CrusherPreviewModels")
	local source = folder and folder:FindFirstChild(typeId)
	if not (source and source:IsA("Model")) then return false end
	local viewport = make("ViewportFrame", { Name = "Preview", BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.04),
		Size = UDim2.fromScale(0.88, 0.74), Ambient = Color3.fromRGB(200, 210, 235), LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1), ZIndex = parent.ZIndex + 1 }, parent)
	local model = source:Clone()
	model.Parent = viewport
	local cf, size = model:GetBoundingBox()
	local camera = make("Camera", { FieldOfView = 34 }, viewport)
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.35, 0.18, 1).Unit * (size.Magnitude / 2) / math.sin(math.rad(17)) * 1.05, cf.Position)
	viewport.CurrentCamera = camera
	return true
end

-- hide a slot's look without removing it from the row (keeps the layout still)
local function conceal(frame: GuiObject, hidden: boolean)
	frame.BackgroundTransparency = if hidden then 1 else 0
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then child.Visible = not hidden
		elseif child:IsA("UIStroke") then child.Transparency = if hidden then 1 else 0 end
	end
end

local function slotLook(frame: GuiObject, item: any)
	local color = C.rarity(item.rarity).color
	frame.BackgroundColor3 = color
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Style.lighten(color, 0.15), Style.darken(color, 0.4)) }, frame)
	if not preview(frame, item.type) then
		Style.image(frame, Icons.Press, { Position = UDim2.fromScale(0.15, 0.08), Size = UDim2.fromScale(0.7, 0.66), ZIndex = frame.ZIndex + 1 })
	end
	local lv = make("TextLabel", { Text = "Lv " .. item.level, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 1, -22),
		Size = UDim2.new(1, -8, 0, 18), TextScaled = true, ZIndex = frame.ZIndex + 2 }, frame)
	Style.text(lv, 2)
end

function B.new(gui: ScreenGui, open: () -> ())
	local self = {}
	local bar = make("Frame", { Name = "InventoryBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(SLOTS * SIZE + (SLOTS - 1) * GAP + 20, SIZE + 20), BackgroundColor3 = INK, BackgroundTransparency = 0.35, ZIndex = 2 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)
	make("UIStroke", { Thickness = 3, Color = INK }, bar)
	local row = make("Frame", { Name = "Slots", Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, ZIndex = 2 }, bar)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center }, row)

	local signature = ""
	local newId: string? = nil
	local newUntil = 0
	local first: GuiObject? = nil

	local function slot(order: number): TextButton
		local b = make("TextButton", { Name = "Slot" .. order, LayoutOrder = order, Size = UDim2.fromOffset(SIZE, SIZE), Text = "",
			AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(40, 46, 70), ZIndex = 3 }, row)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
		make("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		Style.feedback(b)
		b.Activated:Connect(open)
		return b
	end

	function self.update(state: any)
		local items = table.clone(state.items or {})
		local equipped = {}
		for _, id in state.bays or {} do equipped[id] = true end
		-- newest first: the last bought crusher, then by output
		table.sort(items, function(a, b)
			if a.id == state.lastRoll then return true elseif b.id == state.lastRoll then return false end
			return a.stats.cps > b.stats.cps
		end)
		local key = {}
		for i = 1, math.min(#items, SLOTS) do local v = items[i] table.insert(key, v.id .. v.level .. tostring(equipped[v.id])) end
		table.insert(key, tostring(#items) .. tostring(newId))
		local sig = table.concat(key, ",")
		if sig == signature then return end
		signature = sig
		for _, child in row:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
		first = nil
		local shown = if #items > SLOTS then SLOTS - 1 else #items
		for i = 1, shown do
			local item = items[i]
			local b = slot(i)
			slotLook(b, item)
			if i == 1 then first = b end
			if equipped[item.id] then
				local check = make("TextLabel", { Text = "✓", BackgroundColor3 = Style.GREEN, AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 4, 0, -4), Size = UDim2.fromOffset(24, 24), TextScaled = true, ZIndex = 8 }, b)
				make("UICorner", { CornerRadius = UDim.new(1, 0) }, check)
				make("UIStroke", { Thickness = 2, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, check)
				Style.text(check, 1.5)
			end
			if item.id == newId and os.clock() < newUntil then
				local tag = make("TextLabel", { Text = "NEW!", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(70, 26), TextScaled = true, ZIndex = 9 }, b)
				Style.text(tag, 2.5)
				tag.TextColor3 = Color3.fromRGB(255, 226, 90)
				Style.wobble(tag, 8, 6)
			end
		end
		for i = shown + 1, SLOTS do
			local b = slot(i)
			if i == SLOTS and #items > SLOTS then
				local more = make("TextLabel", { Text = "+" .. (#items - shown), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), TextScaled = true, ZIndex = 5 }, b)
				Style.text(more, 2.5)
				make("UIPadding", { PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0) }, more)
			else
				b.BackgroundTransparency = 0.5
			end
		end
	end

	-- A bought crusher flies from a screen point into the first slot.
	function self.flyIn(item: any, from: Vector2?, state: any)
		newId = item.id
		newUntil = os.clock() + 6
		task.delay(6.1, function() if newId == item.id then newId = nil signature = "" self.update(state) end end)
		local start = from or (Workspace.CurrentCamera.ViewportSize / 2 - GuiService:GetGuiInset())
		local card = make("Frame", { Name = "FlyingCrusher", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(start.X, start.Y),
			Size = UDim2.fromOffset(40, 40), ZIndex = 40 }, gui)
		make("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
		make("UIStroke", { Thickness = 3, Color = INK }, card)
		slotLook(card, item)
		-- grow at the pedestal, then swoop down into the bar
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(120, 120) }):Play()
		task.wait(0.45)
		self.update(state)
		local target = if first then first.AbsolutePosition + first.AbsoluteSize / 2 else bar.AbsolutePosition + bar.AbsoluteSize / 2
		if first then conceal(first, true) end
		local fly = TweenService:Create(card, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(SIZE, SIZE) })
		fly:Play()
		fly.Completed:Wait()
		card:Destroy()
		if first and first.Parent then
			conceal(first, false)
			-- the slot pops when the crusher lands
			local pop = first:FindFirstChild("FeedbackScale") :: UIScale?
			if pop then
				pop.Scale = 1.35
				TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
	end

	return self
end

return B
