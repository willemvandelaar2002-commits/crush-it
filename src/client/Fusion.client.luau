--!strict
-- Fusion screen. Opens from the Fusion Machine on your own plot (prompt
-- "FusionPrompt", Factory III and up). Left: crusher types you can fuse (a main
-- plus three spare copies). Right: the main crusher (keeps its level, coating
-- and bay; arrows pick another), the three copies that get used up, the result,
-- and FUSE (click twice). The server checks and does everything (action "Fuse").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Rules = require(RS.Shared.CrusherRules)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local Format = require(RS.Shared.Format)
local CrusherIcon = require(script.Parent.CrusherIcon)

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local INK = Style.Colors.Ink
local GREEN = Color3.fromRGB(70, 225, 86)
local ORANGE = Color3.fromRGB(255, 140, 40)
local GOLD = Color3.fromRGB(255, 205, 60)
local GREY = Color3.fromRGB(104, 116, 138)
local W, H = 860, 540

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function label(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, textSize: number?): TextLabel
	local l = make("TextLabel", { Name = name, Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
		TextSize = textSize or 22, TextWrapped = true, ZIndex = 8 }, parent)
	Style.text(l, 2)
	return l
end
local function button(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, color: Color3, onClick: () -> ()): TextButton
	local b = make("TextButton", { Name = name, Text = text, Position = pos, Size = size, TextSize = 22, TextWrapped = true, ZIndex = 8 }, parent)
	Style.button(b, color)
	b.Activated:Connect(onClick)
	return b
end

local gui = make("ScreenGui", { Name = "FusionHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "FusionWindow", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .53),
	Size = UDim2.fromOffset(W, H), BackgroundColor3 = INK, BackgroundTransparency = .06, BorderSizePixel = 0, Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, panel)
make("UIStroke", { Color = INK, Thickness = 4 }, panel)
make("UIScale", { Name = "Fit" }, panel)
Style.modal(panel)
local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 70), ZIndex = 6 }, panel)
Style.collectionPanel(header, Color3.fromRGB(70, 200, 90), Color3.fromRGB(30, 130, 60))
local title = label(header, "Title", "FUSION MACHINE", UDim2.fromOffset(20, 4), UDim2.new(1, -110, 1, -8), 42)
title.TextXAlignment = Enum.TextXAlignment.Left
button(header, "Close", "X", UDim2.new(1, -64, 0, 9), UDim2.fromOffset(52, 52), Style.Colors.Red, function() Style.setOpen(panel, false) end)
local hint = label(panel, "Hint", "Four of the same crusher become one FUSED crusher with " .. C.Fusion.Mult .. "x output.",
	UDim2.fromOffset(16, 76), UDim2.new(1, -32, 0, 26), 18)

-- left: types you can fuse
local list = make("ScrollingFrame", { Name = "Types", Position = UDim2.fromOffset(14, 108), Size = UDim2.fromOffset(250, H - 122),
	BackgroundColor3 = Color3.fromRGB(34, 46, 70), BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6, ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 5) }, list)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }, list)
local empty = label(list, "Empty", "No crusher has 4 copies yet. Roll more and keep the copies unequipped.", UDim2.new(), UDim2.new(1, 0, 0, 120), 18)

-- right: main, copies, result, fuse
local right = make("Frame", { Name = "Detail", Position = UDim2.fromOffset(278, 108), Size = UDim2.fromOffset(W - 292, H - 122), BackgroundTransparency = 1, ZIndex = 6 }, panel)
local function card(name: string, pos: UDim2, size: UDim2, color: Color3): Frame
	local f = make("Frame", { Name = name, Position = pos, Size = size, ZIndex = 6 }, right)
	Style.collectionPanel(f, color, Style.darken(color, .3))
	return f
end
local mainCard = card("Main", UDim2.fromOffset(0, 0), UDim2.fromOffset(196, 236), GOLD)
label(mainCard, "Tag", "MAIN · KEPT", UDim2.fromOffset(4, 2), UDim2.new(1, -8, 0, 24), 18)
local mainName = label(mainCard, "Name", "", UDim2.new(0, 4, 1, -66), UDim2.new(1, -8, 0, 26), 19)
local mainInfo = label(mainCard, "Info", "", UDim2.new(0, 4, 1, -40), UDim2.new(1, -8, 0, 36), 15)
local prev = button(right, "PrevMain", "<", UDim2.fromOffset(0, 242), UDim2.fromOffset(94, 34), Style.Colors.Blue, function() end)
local nextB = button(right, "NextMain", ">", UDim2.fromOffset(102, 242), UDim2.fromOffset(94, 34), Style.Colors.Blue, function() end)
local copyCards = {}
for i = 1, C.Fusion.Copies do
	local f = card("Copy" .. i, UDim2.fromOffset(210 + (i - 1) * 124, 0), UDim2.fromOffset(116, 150), ORANGE)
	label(f, "Tag", "USED UP", UDim2.fromOffset(2, 2), UDim2.new(1, -4, 0, 20), 15)
	local info = label(f, "Info", "", UDim2.new(0, 2, 1, -38), UDim2.new(1, -4, 0, 34), 14)
	copyCards[i] = { frame = f, info = info, icon = nil :: Frame?, type = nil :: string? }
end
local result = card("Result", UDim2.fromOffset(210, 160), UDim2.fromOffset(364, 116), Color3.fromRGB(70, 200, 90))
label(result, "Tag", "RESULT", UDim2.fromOffset(6, 2), UDim2.new(1, -12, 0, 22), 17)
local resultText = label(result, "Text", "", UDim2.fromOffset(6, 26), UDim2.new(1, -12, 1, -30), 18)
local fuse = button(right, "Fuse", "FUSE!", UDim2.fromOffset(210, 290), UDim2.fromOffset(364, 64), GREEN, function() end)
fuse.TextSize = 30
local status = label(right, "Status", "", UDim2.fromOffset(0, 362), UDim2.new(1, 0, 0, 44), 18)
local mainIcon: Frame? = nil
local mainIconType: string? = nil

local state: any = nil
local selectedType: string? = nil
local mainIndex = 1
local pending = false
local function fitWindow()
	local view = workspace.CurrentCamera.ViewportSize
	local fit = panel:FindFirstChild("Fit") :: UIScale
	fit.Scale = math.min(1, (view.X - 40) / W, (view.Y - 60) / H)
end

-- Fusion candidates for the current state: per type, unfused copies (mains)
-- and the copies a main would use. Mirrors CrusherRules.fusionCopies.
local function profile(): any return { crushers = { owned = state.items, equipped = state.bays, plotLevel = state.plotLevel } } end
local function groups(): { any }
	local byType: { [string]: any } = {}
	for _, item in state.items do
		if not item.fused then
			byType[item.type] = byType[item.type] or { type = item.type, items = {} }
			table.insert(byType[item.type].items, item)
		end
	end
	local out = {}
	for _, g in byType do
		local d = profile()
		local mains = {}
		for _, item in g.items do
			local _, spare = Rules.fusionCopies(d, item)
			if spare >= C.Fusion.Copies then table.insert(mains, item) end
		end
		if #mains > 0 then
			-- best main first: highest level, then best coating
			table.sort(mains, function(a, b)
				if a.level ~= b.level then return a.level > b.level end
				return C.modifier(a.modifier).mult > C.modifier(b.modifier).mult
			end)
			g.mains = mains
			table.insert(out, g)
		end
	end
	table.sort(out, function(a, b) return C.rarity(a.items[1].rarity).rank > C.rarity(b.items[1].rarity).rank or
		(C.rarity(a.items[1].rarity).rank == C.rarity(b.items[1].rarity).rank and a.type < b.type) end)
	return out
end
local function itemLine(item: any): string
	return "LV " .. item.level .. (if item.modifier ~= "Standard" then " · " .. item.modifier else "")
end
local function setIcon(holder: Frame, current: Frame?, typeId: string, size: UDim2, pos: UDim2): Frame
	if current then current:Destroy() end
	return CrusherIcon.new(holder, typeId, { position = pos, size = size, zIndex = 7 })
end

local rows: { Instance } = {}
local function redraw()
	if not state or not panel.Visible then return end
	for _, r in rows do r:Destroy() end
	table.clear(rows)
	local locked = (state.plotLevel or 0) < C.Fusion.PlotLevel
	local list_ = if locked then {} else groups()
	empty.Visible = #list_ == 0
	empty.Text = if locked then "Upgrade to FACTORY III to use the Fusion Machine." else "No crusher has 4 copies yet. Roll more and keep the copies unequipped."
	local chosen
	for i, g in list_ do
		if g.type == selectedType then chosen = g end
	end
	if not chosen then chosen = list_[1] selectedType = chosen and chosen.type mainIndex = 1 end
	for i, g in list_ do
		local def = C.typeById(g.type)
		local r = make("TextButton", { Name = "Type_" .. g.type, Text = "", Size = UDim2.new(1, 0, 0, 58), LayoutOrder = i, ZIndex = 7, AutoButtonColor = false }, list)
		Style.button(r, if g == chosen then GOLD else C.rarity(g.items[1].rarity).color)
		local t = label(r, "Name", def.name, UDim2.fromOffset(8, 2), UDim2.new(1, -16, 0, 30), 20) t.ZIndex = 9
		t.TextXAlignment = Enum.TextXAlignment.Left
		local n = label(r, "Count", #g.items .. " owned · " .. g.items[1].rarity, UDim2.fromOffset(8, 30), UDim2.new(1, -16, 0, 22), 15) n.ZIndex = 9
		n.TextXAlignment = Enum.TextXAlignment.Left
		r.Activated:Connect(function() selectedType = g.type mainIndex = 1 pending = false redraw() end)
		table.insert(rows, r)
	end
	right.Visible = chosen ~= nil
	if not chosen then return end
	mainIndex = math.clamp(mainIndex, 1, #chosen.mains)
	local main = chosen.mains[mainIndex]
	local copies = Rules.fusionCopies(profile(), main)
	local def = C.typeById(main.type)
	if mainIconType ~= main.type then mainIcon = setIcon(mainCard, mainIcon, main.type, UDim2.new(1, -16, 0, 140), UDim2.fromOffset(8, 28)) mainIconType = main.type end
	mainName.Text = def.name
	local equipped = false for _, id in state.bays do if id == main.id then equipped = true end end
	mainInfo.Text = itemLine(main) .. (if equipped then " · EQUIPPED" else "")
	prev.Visible = #chosen.mains > 1 nextB.Visible = #chosen.mains > 1
	for i, c in copyCards do
		local item = copies[i]
		if item and c.type ~= item.type then c.icon = setIcon(c.frame, c.icon, item.type, UDim2.new(1, -12, 0, 84), UDim2.fromOffset(6, 22)) c.type = item.type end
		c.info.Text = if item then itemLine(item) else ""
	end
	local nowRate = (main.stats and main.stats.cps or 0) * 60
	resultText.Text = "FUSED " .. def.name .. "\n" .. itemLine(main) .. " · " .. main.rarity .. " row still counts\n"
		.. Format.cash(nowRate) .. " → " .. Format.cash(nowRate * C.Fusion.Mult) .. "/min"
	fuse.Text = if pending then "CONFIRM · USES 3 COPIES" else "FUSE!"
	Style.setButtonColor(fuse, if pending then ORANGE else GREEN)
	fuse:SetAttribute("Main", main.id)
	local ids = {} for i, item in copies do ids[i] = item.id end
	fuse:SetAttribute("Inputs", table.concat(ids, ","))
end
prev.Activated:Connect(function() mainIndex -= 1 pending = false if mainIndex < 1 then mainIndex = 999 end redraw() end)
nextB.Activated:Connect(function() mainIndex += 1 pending = false redraw() end)
local lastSent = 0
fuse.Activated:Connect(function()
	if not state then return end
	if not pending then
		pending = true redraw()
		task.delay(3, function() if pending then pending = false redraw() end end)
		return
	end
	pending = false
	local main = fuse:GetAttribute("Main") local inputs = fuse:GetAttribute("Inputs")
	if type(main) ~= "string" or type(inputs) ~= "string" or os.clock() - lastSent < .5 then return end
	lastSent = os.clock()
	status.Text = "Fusing..."
	actionRemote:FireServer("Fuse", { main = main, inputs = string.split(inputs, ",") })
end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	state = v
	if panel.Visible and v.message then
		if v.message == "Done!" and v.result and v.result.fused then
			status.Text = "FUSED! " .. (C.typeById(v.result.type) and C.typeById(v.result.type).name or "") .. " now makes " .. C.Fusion.Mult .. "x"
			status.TextColor3 = GOLD
		elseif v.message ~= "Done!" then
			status.Text = v.message status.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end
	redraw()
end)

local function mine(prompt: ProximityPrompt): boolean
	local plot = prompt:FindFirstAncestorWhichIsA("Model")
	while plot and plot:GetAttribute("Index") == nil do plot = plot.Parent and plot.Parent:FindFirstAncestorWhichIsA("Model") or nil end
	return plot ~= nil and plot:GetAttribute("Index") == me:GetAttribute("Plot")
end
PPS.PromptTriggered:Connect(function(prompt)
	if prompt.Name ~= "FusionPrompt" then return end
	if not mine(prompt) then status.Text = "" return end
	pending = false status.Text = "" status.TextColor3 = Color3.new(1, 1, 1)
	fitWindow()
	Style.setOpen(panel, true)
	actionRemote:FireServer("Sync")
	redraw()
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then redraw() else pending = false end end)
