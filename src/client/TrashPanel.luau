--!strict
-- Trash can picker (opened from the trash can on the plot). Lists every
-- crusher that isn't in a bay; tap cards to select them, or use the quick
-- "all <rarity>" buttons, then TRASH (second press confirms). The server
-- (Rules "TrashMany") checks ownership and never takes an equipped crusher.
-- Same look as the Index and Rewards screens.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.Shared.CrusherConfig)
local Style = require(RS.Shared.Kit.Style)
local CrusherIcon = require(script.Parent.CrusherIcon)

local T = {}

local INK = Color3.fromRGB(12, 14, 20)
local RED = Color3.fromRGB(226, 52, 58)
local WHITE = Color3.new(1, 1, 1)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do (i :: any)[k] = v end
	i.Parent = parent
	return i
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, outline: number?): TextLabel
	local l = make("TextLabel", { Text = text, Position = pos, Size = size, BackgroundTransparency = 1, TextScaled = true, ZIndex = 8 }, parent)
	Style.text(l, outline or 3)
	return l
end
-- a chunky button with its text in a child label (the gradient would tint its own text)
local function button(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, onClick: () -> ()): (TextButton, TextLabel)
	local b = make("TextButton", { Text = "", Position = pos, Size = size, AutoButtonColor = false, ZIndex = 7 }, parent)
	Style.button(b, color)
	local corner = b:FindFirstChildOfClass("UICorner")
	if corner then corner.CornerRadius = UDim.new(0, 4) end
	local t = label(b, text, UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.76), 2.5)
	t.ZIndex = 8
	b.Activated:Connect(onClick)
	return b, t
end

function T.new(gui: ScreenGui, act: (string, any) -> ())
	local self = {}
	local state: any = nil
	local selected: { [string]: boolean } = {}
	local cards: { [string]: any } = {}
	local signature = ""
	local confirmUntil = 0

	local W, H = 900, 620
	local panel = make("Frame", { Name = "TrashPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 20),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = Color3.fromRGB(48, 52, 58), Visible = false, ZIndex = 5 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, panel)
	make("UIStroke", { Color = INK, Thickness = 5 }, panel)
	Style.modal(panel)
	panel:SetAttribute("FitWidth", W + 40)
	panel:SetAttribute("FitHeight", H + 70)

	-- header: red, drifting studs, a drawn trash can poking out of the corner
	local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 0, 84), BackgroundColor3 = WHITE, ZIndex = 6 }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, header)
	make("UIStroke", { Color = INK, Thickness = 5 }, header)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 110)), ColorSequenceKeypoint.new(0.5, RED), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 24, 34)),
	}) }, header)
	Style.flowingStuds(header, 34, 0.74, panel).ImageColor3 = Color3.fromRGB(255, 210, 210)
	local can = make("Frame", { Name = "CanIcon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(52, 34), Size = UDim2.fromOffset(84, 100),
		BackgroundTransparency = 1, Rotation = -10, ZIndex = 9 }, header)
	local body = make("Frame", { Position = UDim2.fromScale(0.12, 0.28), Size = UDim2.fromScale(0.76, 0.72), BackgroundColor3 = Color3.fromRGB(90, 110, 130), ZIndex = 9 }, can)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, body)
	make("UIStroke", { Color = INK, Thickness = 4 }, body)
	for _, x in { 0.25, 0.5, 0.75 } do
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0.14), Size = UDim2.new(0, 6, 0.72, 0), BackgroundColor3 = Color3.fromRGB(60, 76, 92), BorderSizePixel = 0, ZIndex = 10 }, body)
	end
	local lid = make("Frame", { Position = UDim2.fromScale(0.02, 0.12), Size = UDim2.fromScale(0.96, 0.16), BackgroundColor3 = RED, Rotation = -14, ZIndex = 10 }, can)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, lid)
	make("UIStroke", { Color = INK, Thickness = 4 }, lid)
	Style.wobble(can, 4, 1.7)
	local title = label(header, "Trash", UDim2.fromOffset(108, 8), UDim2.fromOffset(240, 68), 5)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local count = label(header, "", UDim2.new(1, -330, 0, 18), UDim2.fromOffset(230, 46), 4)
	count.TextXAlignment = Enum.TextXAlignment.Right
	local close = button(header, "X", UDim2.new(1, -80, 0, 9), UDim2.fromOffset(66, 66), RED, function() Style.setOpen(panel, false) end)
	close.ZIndex = 8

	-- quick select row
	local quick = make("Frame", { Name = "Quick", Position = UDim2.fromOffset(14, 92), Size = UDim2.new(1, -28, 0, 40), BackgroundTransparency = 1, ZIndex = 6 }, panel)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, quick)

	-- cards
	local content = make("ScrollingFrame", { Name = "Content", Position = UDim2.fromOffset(12, 142), Size = UDim2.new(1, -24, 1, -228),
		BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 7, ZIndex = 6 }, panel)
	Style.scroll(content)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(160, 176), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	local empty = label(panel, "Nothing to trash: every crusher you own is in a bay.", UDim2.fromOffset(40, 300), UDim2.new(1, -80, 0, 40), 3)
	empty.Visible = false

	-- footer
	local hint = label(panel, "Crushers in a bay are kept. The Index remembers everything you found.", UDim2.fromOffset(18, H - 74), UDim2.new(1, -330, 0, 26), 2.5)
	hint.TextXAlignment = Enum.TextXAlignment.Left hint.TextColor3 = Color3.fromRGB(220, 224, 232)
	local clearButton = button(panel, "CLEAR", UDim2.fromOffset(18, H - 44), UDim2.fromOffset(130, 34), Color3.fromRGB(110, 116, 130), function()
		table.clear(selected) confirmUntil = 0 self.refresh()
	end)
	local _ = clearButton
	local trash, trashText = button(panel, "TRASH 0", UDim2.new(1, -310, 1, -76), UDim2.fromOffset(292, 62), RED, function()
		local ids = {}
		for id in selected do table.insert(ids, id) end
		if #ids == 0 then return end
		if os.clock() > confirmUntil then confirmUntil = os.clock() + 3 self.refresh() return end
		confirmUntil = 0
		act("TrashMany", { ids = ids })
		table.clear(selected)
		self.refresh()
	end)

	local function unequipped(): { any }
		local out = {}
		if not state then return out end
		local inBay = {}
		for _, id in state.bays do inBay[id] = true end
		for _, item in state.items do if not inBay[item.id] then table.insert(out, item) end end
		table.sort(out, function(a, b)
			local ra, rb = C.rarity(a.rarity), C.rarity(b.rarity)
			if ra and rb and ra.rank ~= rb.rank then return ra.rank < rb.rank end
			if a.type ~= b.type then return a.type < b.type end
			return a.level < b.level
		end)
		return out
	end

	local function paintCard(item: any)
		local card = cards[item.id]
		if not card then return end
		local on = selected[item.id] == true
		card.mark.Visible = on
		card.stroke.Color = if on then RED else INK
		card.stroke.Thickness = if on then 5 else 3.5
	end

	local quickKey = ""
	local function buildQuick(list: { any })
		local counts: { [string]: number } = {}
		for _, item in list do counts[item.rarity] = (counts[item.rarity] or 0) + 1 end
		local keys = {}
		for _, r in C.Rarities do if counts[r.name] then table.insert(keys, r.name .. counts[r.name]) end end
		local key = table.concat(keys, ",")
		if key == quickKey then return end
		quickKey = key
		for _, c in quick:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		for order, r in C.Rarities do
			local n = counts[r.name]
			if n then
				local b = button(quick, "All " .. r.name .. " (" .. n .. ")", UDim2.new(), UDim2.fromOffset(132, 40), r.color, function()
					-- toggle: select every unequipped crusher of this rarity, or clear them
					local all = true
					for _, item in unequipped() do if item.rarity == r.name and not selected[item.id] then all = false end end
					for _, item in unequipped() do if item.rarity == r.name then selected[item.id] = if all then nil else true end end
					confirmUntil = 0
					self.refresh()
				end)
				b.LayoutOrder = order
			end
		end
	end

	local function rebuild(list: { any })
		for _, card in cards do card.frame:Destroy() end
		table.clear(cards)
		for order, item in list do
			local r = C.rarity(item.rarity) or C.Rarities[1]
			local def = C.typeById(item.type)
			local f = make("TextButton", { Name = "Card_" .. item.id, LayoutOrder = order, Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, ZIndex = 6 }, content)
			make("UICorner", { CornerRadius = UDim.new(0, 3) }, f)
			local stroke = make("UIStroke", { Color = INK, Thickness = 3.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
			make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Style.darken(r.color, 0.12)), ColorSequenceKeypoint.new(0.45, Style.lighten(r.color, 0.3)), ColorSequenceKeypoint.new(1, Style.darken(r.color, 0.25)),
			}) }, f)
			local name = label(f, if def then def.name else item.type, UDim2.fromOffset(4, 4), UDim2.new(1, -8, 0, 24), 2.5)
			name.ZIndex = 8
			CrusherIcon.new(f, item.type, { position = UDim2.fromOffset(10, 28), size = UDim2.new(1, -20, 0, 96), modifier = item.modifier, zIndex = 7 })
			local info = label(f, item.rarity .. " · Lv " .. item.level .. (if item.modifier ~= "Standard" then " · " .. item.modifier else "") .. (if item.fused then " · FUSED" else ""),
				UDim2.new(0, 4, 1, -46), UDim2.new(1, -8, 0, 22), 2.5)
			info.ZIndex = 8
			local mark = make("Frame", { Name = "Selected", Size = UDim2.fromScale(1, 1), BackgroundColor3 = RED, BackgroundTransparency = 0.45, Visible = false, ZIndex = 9 }, f)
			make("UICorner", { CornerRadius = UDim.new(0, 3) }, mark)
			local x = label(mark, "X", UDim2.fromScale(0.3, 0.22), UDim2.fromScale(0.4, 0.4), 5)
			x.ZIndex = 10
			f.Activated:Connect(function()
				selected[item.id] = if selected[item.id] then nil else true
				confirmUntil = 0
				self.refresh()
			end)
			cards[item.id] = { frame = f, mark = mark, stroke = stroke }
		end
	end

	function self.refresh()
		if not state then return end
		local list = unequipped()
		-- forget selections of crushers that are gone or went into a bay
		local present = {}
		for _, item in list do present[item.id] = true end
		for id in selected do if not present[id] then selected[id] = nil end end
		local keys = {}
		for _, item in list do table.insert(keys, item.id .. item.level .. item.modifier .. tostring(item.fused)) end
		local sig = table.concat(keys, "|")
		if sig ~= signature and panel.Visible then signature = sig rebuild(list) end
		buildQuick(list)
		local n, top = 0, false
		for _, item in list do
			if selected[item.id] then
				n += 1
				local r = C.rarity(item.rarity)
				if r and r.rank >= 4 then top = true end
			end
			paintCard(item)
		end
		empty.Visible = #list == 0
		count.Text = #state.items .. " / " .. C.MaxInventory
		local confirming = os.clock() <= confirmUntil
		trashText.Text = if confirming then (if top then "SURE? INCLUDES RARE ONES!" else "CONFIRM: TRASH " .. n) else "TRASH " .. n
		Style.setButtonColor(trash, if n > 0 then RED else Color3.fromRGB(110, 116, 130))
	end

	function self.update(value: any)
		state = value
		self.refresh()
	end
	function self.open()
		signature = ""
		Style.setOpen(panel, true)
		self.refresh()
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then signature = "" self.refresh() else table.clear(selected) confirmUntil = 0 end
	end)
	-- the confirm window runs out on its own
	task.spawn(function()
		while true do
			task.wait(0.5)
			if panel.Visible and confirmUntil > 0 and os.clock() > confirmUntil then confirmUntil = 0 self.refresh() end
		end
	end)
	self.panel = panel
	return self
end

return T
