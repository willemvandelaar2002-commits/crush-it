--!strict
-- Fusion Machine screen (Willem's mockup). Opens from the Fusion Machine on
-- your own plot (prompt "FusionPrompt", Factory III and up).
--   left: YOUR CRUSHERS, one tile per crusher type with how many of the 4 you have
--   right: 4 MATCHING CRUSHERS (MAIN + 3 COPY), joined by green lines to the
--          FUSED result with its 2x OUTPUT badge, a note and FUSE 4 -> 1
-- The main keeps its id, level, coating and bay; the three copies are used
-- up. Click the MAIN tile to switch which one is kept. FUSE asks once more
-- before it sends. The server checks and does everything (action "Fuse").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Rules = require(RS.Shared.CrusherRules)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local Icons = require(RS.Shared.Icons)
local CrusherIcon = require(script.Parent.CrusherIcon)
local L = require(script.Parent.LabUi)
local make = L.make

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local W, H = 1000, 640
local LIME = Color3.fromRGB(110, 220, 50)
local INDIGO = Color3.fromRGB(56, 54, 150)
local VIOLET = Color3.fromRGB(78, 60, 175)
local NEON = Color3.fromRGB(90, 255, 110)
local ORANGE = Color3.fromRGB(255, 140, 40)
local NEED = C.Fusion.Copies + 1

local gui = make("ScreenGui", { Name = "FusionHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = L.window(gui, { name = "FusionWindow", w = W, h = H, color = LIME, colorDark = Color3.fromRGB(50, 160, 30),
	title = "FUSION MACHINE", subtitle = "Fuse " .. NEED .. " identical crushers into 1 FUSED crusher.", icon = Icons.FusionMachine, glyph = "🧪" })

-- left: crusher types
local left = L.section(panel, "YourCrushers", "YOUR CRUSHERS", UDim2.fromOffset(14, 140), UDim2.fromOffset(330, H - 154), INDIGO)
local grid = make("ScrollingFrame", { Name = "Grid", Position = UDim2.fromOffset(8, 64), Size = UDim2.new(1, -16, 1, -112), BackgroundTransparency = 1,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 8 }, left)
make("UIGridLayout", { CellSize = UDim2.fromOffset(146, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, grid)
local footer = L.panel(left, "Footer", UDim2.new(0, 10, 1, -44), UDim2.new(1, -20, 0, 34), Color3.fromRGB(30, 34, 62), Color3.fromRGB(20, 22, 44), 10)
local footerText = L.text(footer, "Text", "Select a type to see matching copies.", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 18, 2)
footerText.TextColor3 = Color3.fromRGB(190, 205, 240)
local empty = L.text(left, "Empty", "", UDim2.fromOffset(14, 80), UDim2.new(1, -28, 0, 140), 22)

-- right: slots, result, fuse
local right = L.section(panel, "Matching", NEED .. " MATCHING CRUSHERS", UDim2.fromOffset(354, 140), UDim2.fromOffset(632, H - 154), VIOLET)
local slots = {}
for i = 1, NEED do
	local f = make("TextButton", { Name = "Slot" .. i, Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(14 + (i - 1) * 152, 64),
		Size = UDim2.fromOffset(144, 160), ZIndex = 8 }, right)
	Style.panel(f :: any, L.TILE, Color3.fromRGB(168, 180, 202))
	;(f:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 14)
	local name = L.text(f, "Name", "", UDim2.new(0, 2, 0, 90), UDim2.new(1, -4, 0, 24), 20, 3)
	name.TextScaled = true make("UITextSizeConstraint", { MaxTextSize = 22 }, name)
	local tag = L.pill(f, "Tag", "COPY", UDim2.new(.05, 0, 1, -46), UDim2.new(.9, 0, 0, 40))
	local note = L.text(tag, "Note", "", UDim2.new(0, 2, .56, 0), UDim2.new(1, -4, .4, 0), 12, 2)
	note.ZIndex = 13
	slots[i] = { frame = f, name = name, tag = tag, note = note, icon = nil :: Frame?, key = "" }
end
-- green connectors: down from each slot, along, then down into the result
local LINE_Y = 236
for i = 1, NEED do
	make("Frame", { Name = "Drop" .. i, Position = UDim2.fromOffset(14 + (i - 1) * 152 + 70, 222), Size = UDim2.fromOffset(10, LINE_Y - 222 + 10),
		BackgroundColor3 = NEON, BorderSizePixel = 0, ZIndex = 7 }, right)
end
make("Frame", { Name = "Rail", Position = UDim2.fromOffset(84, LINE_Y), Size = UDim2.fromOffset(152 * (NEED - 1) + 10, 10), BackgroundColor3 = NEON, BorderSizePixel = 0, ZIndex = 7 }, right)
L.arrow(right, UDim2.fromOffset(84 + 76 - 26, LINE_Y + 6), UDim2.fromOffset(52, 44), NEON)
for _, line in right:GetChildren() do if line:IsA("Frame") and (line.Name:match("^Drop") or line.Name == "Rail") then
	make("UIStroke", { Color = Color3.fromRGB(30, 110, 40), Thickness = 2 }, line)
end end

local resultBox = make("Frame", { Name = "Result", Position = UDim2.fromOffset(50, 282), Size = UDim2.fromOffset(220, 124), BackgroundTransparency = 1, ZIndex = 8 }, right)
local glow = make("Frame", { Name = "Glow", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .55), Size = UDim2.fromScale(.9, .7),
	BackgroundColor3 = NEON, BackgroundTransparency = .75, ZIndex = 8 }, resultBox)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
L.sparkles(resultBox, 8, Color3.fromRGB(170, 255, 170))
local resultIcon: Frame? = nil
local resultKey = ""
local resultLabel = L.panel(right, "ResultLabel", UDim2.fromOffset(20, 404), UDim2.fromOffset(300, 74), Color3.fromRGB(26, 30, 56), Color3.fromRGB(16, 18, 40), 14)
local resultName = L.text(resultLabel, "Name", "", UDim2.fromOffset(6, 2), UDim2.new(1, -12, 0, 30), 26, 3)
resultName.TextScaled = true make("UITextSizeConstraint", { MaxTextSize = 26 }, resultName)
local badge = L.pill(resultLabel, "Output", C.Fusion.Mult .. "x OUTPUT", UDim2.new(.5, -92, 0, 34), UDim2.fromOffset(184, 34), L.GREEN, nil, 26)
local noteBox = L.panel(right, "Note", UDim2.fromOffset(350, 282), UDim2.fromOffset(266, 96), Color3.fromRGB(26, 30, 56), Color3.fromRGB(16, 18, 40), 12)
local noteText = L.text(noteBox, "Text", "Main keeps its level and coating.\n" .. C.Fusion.Copies .. " copies are consumed.", UDim2.fromOffset(8, 6), UDim2.new(1, -16, 1, -12), 20, 2)
noteText.TextColor3 = Color3.fromRGB(200, 215, 245)
local fuse = L.button(right, "Fuse", "FUSE " .. NEED .. " → 1", UDim2.fromOffset(340, 392), UDim2.fromOffset(278, 86), L.GREEN, 52)
local status = L.text(right, "Status", "", UDim2.fromOffset(340, 456), UDim2.fromOffset(278, 26), 18, 2)

local state: any = nil
local selectedType: string? = nil
local mainIndex = 1
local pending = false
local tiles: { Instance } = {}

-- Per type: unfused copies, the possible mains (with 3 spare copies) and the
-- best count toward 4. Mirrors CrusherRules.fusionCopies.
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
	local d = profile()
	for _, g in byType do
		g.mains = {} g.count = 0 g.best = nil
		for _, item in g.items do
			local _, spare = Rules.fusionCopies(d, item)
			local n = 1 + math.min(spare, C.Fusion.Copies)
			if n > g.count then g.count = n g.best = item end
			if spare >= C.Fusion.Copies then table.insert(g.mains, item) end
		end
		table.sort(g.mains, function(a, b)
			if a.level ~= b.level then return a.level > b.level end
			return C.modifier(a.modifier).mult > C.modifier(b.modifier).mult
		end)
		table.insert(out, g)
	end
	table.sort(out, function(a, b)
		if a.count ~= b.count then return a.count > b.count end
		local ra, rb = C.rarity(a.items[1].rarity).rank, C.rarity(b.items[1].rarity).rank
		if ra ~= rb then return ra > rb end
		return a.type < b.type
	end)
	return out
end

local function setSlot(s: any, item: any?, typeId: string, role: string)
	local key = if item then item.id .. ":" .. item.modifier .. ":" .. role else "empty:" .. typeId
	if s.key == key then return end
	s.key = key
	if s.icon then s.icon:Destroy() s.icon = nil end
	local old = s.frame:FindFirstChild("Check") if old then old:Destroy() end
	s.icon = CrusherIcon.new(s.frame, typeId, { position = UDim2.new(.12, 0, 0, 6), size = UDim2.new(.76, 0, 0, 82), zIndex = 9,
		modifier = if item and item.modifier ~= "Standard" then item.modifier else nil, hidden = item == nil })
	s.name.Text = C.typeById(typeId).name
	if item then L.check(s.frame, L.GREEN) end
	local text = s.tag:FindFirstChild("Text") :: TextLabel
	if role == "main" then
		L.setPill(s.tag, "MAIN", Color3.fromRGB(26, 30, 52), LIME) s.note.Text = "Keeps level + coating"
		text.Size = UDim2.fromScale(1, .6) text.TextSize = 22
	else
		L.setPill(s.tag, if item then "COPY" else "NEED 1", Color3.fromRGB(26, 30, 52)) s.note.Text = ""
		text.Size = UDim2.fromScale(1, 1) text.TextSize = 24
	end
	;(s.frame:FindFirstChild("PanelFill") :: UIGradient).Transparency = NumberSequence.new(if item then 0 else .4)
end

local function redraw()
	if not state or not panel.Visible then return end
	for _, t in tiles do t:Destroy() end
	table.clear(tiles)
	local locked = (state.plotLevel or 0) < C.Fusion.PlotLevel
	local list = if locked then {} else groups()
	empty.Visible = #list == 0
	empty.Text = if locked then "Upgrade to FACTORY III to use the Fusion Machine." else "No crushers to fuse yet. Roll more of the same type!"
	local chosen
	for _, g in list do if g.type == selectedType then chosen = g end end
	if not chosen then chosen = list[1] selectedType = chosen and chosen.type mainIndex = 1 end
	for i, g in list do
		local t = L.tile(grid, "Type_" .. g.type, UDim2.fromOffset(146, 150), g.best or g.items[1], C.typeById(g.type).name, g.count .. "/" .. NEED)
		t.LayoutOrder = i
		L.select(t, g == chosen)
		if g.count >= NEED then L.setPill(t:FindFirstChild("Pill") :: Frame, g.count .. "/" .. NEED, Color3.fromRGB(26, 30, 52), Color3.fromRGB(255, 225, 60)) end
		t.Activated:Connect(function() selectedType = g.type mainIndex = 1 pending = false status.Text = "" redraw() end)
		table.insert(tiles, t)
	end
	right.Visible = chosen ~= nil
	if not chosen then return end
	local ready = #chosen.mains > 0
	mainIndex = if ready then (mainIndex - 1) % #chosen.mains + 1 else 1
	local main = if ready then chosen.mains[mainIndex] else chosen.best
	local copies = Rules.fusionCopies(profile(), main)
	setSlot(slots[1], main, chosen.type, "main")
	for i = 2, NEED do setSlot(slots[i], copies[i - 1], chosen.type, "copy") end
	slots[1].note.Text = if #chosen.mains > 1 then "Tap to switch main" else "Keeps level + coating"
	local key = chosen.type .. ":" .. main.modifier
	if key ~= resultKey then
		if resultIcon then resultIcon:Destroy() end
		resultIcon = CrusherIcon.new(resultBox, chosen.type, { zIndex = 9, fused = true,
			modifier = if main.modifier ~= "Standard" then main.modifier else nil })
		resultKey = key
	end
	resultName.Text = "FUSED " .. C.typeById(chosen.type).name
	fuse.Text = if not ready then "NEED " .. NEED elseif pending then "SURE? USES " .. C.Fusion.Copies else "FUSE " .. NEED .. " → 1"
	fuse.TextSize = if pending or not ready then 38 else 52
	Style.setButtonColor(fuse, if not ready then L.GREY elseif pending then ORANGE else L.GREEN)
	fuse:SetAttribute("Main", if ready then main.id else nil)
	local ids = {} for i, item in copies do ids[i] = item.id end
	fuse:SetAttribute("Inputs", if ready then table.concat(ids, ",") else nil)
	footerText.Text = if ready then "Ready to fuse!" else "Need " .. NEED .. " " .. C.typeById(chosen.type).name .. " (spares unequipped)."
end
slots[1].frame.Activated:Connect(function() mainIndex += 1 pending = false redraw() end)
local lastSent = 0
fuse.Activated:Connect(function()
	if not state or fuse:GetAttribute("Main") == nil then return end
	if not pending then
		pending = true redraw()
		task.delay(3, function() if pending then pending = false redraw() end end)
		return
	end
	pending = false
	local main = fuse:GetAttribute("Main") local inputs = fuse:GetAttribute("Inputs")
	if type(main) ~= "string" or type(inputs) ~= "string" or os.clock() - lastSent < .5 then return end
	lastSent = os.clock()
	status.Text = "Fusing..." status.TextColor3 = L.WHITE
	actionRemote:FireServer("Fuse", { main = main, inputs = string.split(inputs, ",") })
end)

local previewing = false
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if previewing then return end
	state = v
	if panel.Visible and v.message then
		if v.message == "Done!" and v.result and v.result.fused then
			status.Text = "FUSED! " .. C.Fusion.Mult .. "x output" status.TextColor3 = L.GOLD
		elseif v.message ~= "Done!" then
			status.Text = v.message status.TextColor3 = Color3.fromRGB(255, 130, 130)
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
	if prompt.Name ~= "FusionPrompt" or not mine(prompt) then return end
	pending = false status.Text = "" status.TextColor3 = L.WHITE previewing = false
	L.fit(panel, W, H)
	Style.setOpen(panel, true)
	actionRemote:FireServer("Sync")
	redraw()
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then redraw() else pending = false previewing = false end end)
-- Studio only: preview the screen with a made-up state (visual only; the
-- server still owns the real inventory and refuses ids you don't own).
if game:GetService("RunService"):IsStudio() then
	local preview = make("BindableFunction", { Name = "FusionPreview" }, script)
	preview.OnInvoke = function(fake: any)
		previewing = true state = fake pending = false L.fit(panel, W, H) Style.setOpen(panel, true) redraw()
		return true
	end
end
