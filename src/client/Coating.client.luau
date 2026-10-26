--!strict
-- Coating screen. Opens from the coating booth on your own plot (prompt
-- "CoatingPrompt", Factory II and up). Left: your unequipped crushers. Right:
-- the chosen crusher, the four finishes with price and output preview, and
-- COAT. Picking a finish asks the server for a quote (QuoteCoating); COAT
-- confirms it (ApplyCoating). The server checks, charges and saves.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local P = require(RS.Shared.FactoryProgression)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local Format = require(RS.Shared.Format)
local CrusherIcon = require(script.Parent.CrusherIcon)

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local INK = Style.Colors.Ink
local PURPLE = Color3.fromRGB(153, 83, 238)
local GREEN = Color3.fromRGB(70, 225, 86)
local GREY = Color3.fromRGB(104, 116, 138)
local W, H = 880, 540

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
	local b = make("TextButton", { Name = name, Text = text, Position = pos, Size = size, TextSize = 20, TextWrapped = true, ZIndex = 8 }, parent)
	Style.button(b, color)
	b.Activated:Connect(onClick)
	return b
end

local gui = make("ScreenGui", { Name = "CoatingHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "CoatingWindow", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .53),
	Size = UDim2.fromOffset(W, H), BackgroundColor3 = INK, BackgroundTransparency = .06, BorderSizePixel = 0, Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, panel)
make("UIStroke", { Color = INK, Thickness = 4 }, panel)
local fit = make("UIScale", { Name = "Fit" }, panel)
Style.modal(panel)
local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 70), ZIndex = 6 }, panel)
Style.collectionPanel(header, PURPLE, Color3.fromRGB(95, 40, 170))
local title = label(header, "Title", "COATING LAB", UDim2.fromOffset(20, 4), UDim2.new(1, -110, 1, -8), 42)
title.TextXAlignment = Enum.TextXAlignment.Left
button(header, "Close", "X", UDim2.new(1, -64, 0, 9), UDim2.fromOffset(52, 52), Style.Colors.Red, function() Style.setOpen(panel, false) end)
label(panel, "Hint", "Pick an unequipped crusher and a finish. A finish replaces the old one and boosts its scrap value.",
	UDim2.fromOffset(16, 76), UDim2.new(1, -32, 0, 26), 17)

local list = make("ScrollingFrame", { Name = "Crushers", Position = UDim2.fromOffset(14, 108), Size = UDim2.fromOffset(260, H - 122),
	BackgroundColor3 = Color3.fromRGB(34, 46, 70), BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6, ZIndex = 6 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 5) }, list)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }, list)
local empty = label(list, "Empty", "All your crushers are equipped. Swap one out at its bay to coat it.", UDim2.new(), UDim2.new(1, 0, 0, 110), 18)

local right = make("Frame", { Name = "Detail", Position = UDim2.fromOffset(288, 108), Size = UDim2.fromOffset(W - 302, H - 122), BackgroundTransparency = 1, ZIndex = 6 }, panel)
local cardFrame = make("Frame", { Name = "Chosen", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(200, 250), ZIndex = 6 }, right)
Style.collectionPanel(cardFrame, PURPLE, Style.darken(PURPLE, .3))
local cardName = label(cardFrame, "Name", "", UDim2.new(0, 4, 1, -66), UDim2.new(1, -8, 0, 26), 19)
local cardInfo = label(cardFrame, "Info", "", UDim2.new(0, 4, 1, -40), UDim2.new(1, -8, 0, 36), 15)
local cardIcon: Frame? = nil
local cardType: string? = nil
local finishButtons: { [string]: TextButton } = {}
for i, recipe in C.Coatings do
	local b = button(right, "Finish_" .. recipe.name, "", UDim2.fromOffset(214 + ((i - 1) % 2) * 182, math.floor((i - 1) / 2) * 76), UDim2.fromOffset(172, 68), recipe.color, function() end)
	b.TextSize = 18
	finishButtons[recipe.name] = b
end
local preview = make("Frame", { Name = "Preview", Position = UDim2.fromOffset(214, 160), Size = UDim2.fromOffset(354, 90), ZIndex = 6 }, right)
Style.collectionPanel(preview, Color3.fromRGB(49, 67, 98), INK)
local previewText = label(preview, "Text", "Pick a finish to see the price and output.", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8), 18)
local coat = button(right, "Coat", "PICK A FINISH", UDim2.fromOffset(214, 264), UDim2.fromOffset(354, 62), GREY, function() end)
coat.TextSize = 26
local status = label(right, "Status", "", UDim2.fromOffset(0, 340), UDim2.new(1, 0, 0, 44), 18)

local state: any = nil
local selectedId: string? = nil
local picked: string? = nil -- finish we asked a quote for
local function fitWindow()
	local view = workspace.CurrentCamera.ViewportSize
	fit.Scale = math.min(1, (view.X - 40) / W, (view.Y - 60) / H)
end
local function unequipped(): { any }
	local busy = {} for _, id in state.bays do busy[id] = true end
	local out = {}
	for _, item in state.items do if not busy[item.id] then table.insert(out, item) end end
	table.sort(out, function(a, b)
		local ca, cb = a.stats and a.stats.cps or 0, b.stats and b.stats.cps or 0
		if ca ~= cb then return ca > cb end
		return a.id < b.id
	end)
	return out
end
local function finishText(item: any): string
	return "LV " .. item.level .. " · " .. (if item.modifier == "Standard" then "no finish" else item.modifier) .. (if item.fused then " · FUSED" else "")
end

local rows: { Instance } = {}
local function redraw()
	if not state or not panel.Visible then return end
	for _, r in rows do r:Destroy() end
	table.clear(rows)
	local items = unequipped()
	empty.Visible = #items == 0
	local chosen
	for _, item in items do if item.id == selectedId then chosen = item end end
	if not chosen then chosen = items[1] selectedId = chosen and chosen.id picked = nil end
	for i, item in items do
		local def = C.typeById(item.type)
		local r = make("TextButton", { Name = "Crusher_" .. i, Text = "", Size = UDim2.new(1, 0, 0, 58), LayoutOrder = i, ZIndex = 7, AutoButtonColor = false }, list)
		Style.button(r, if item == chosen then Color3.fromRGB(255, 205, 60) else C.rarity(item.rarity).color)
		local t = label(r, "Name", def.name, UDim2.fromOffset(8, 2), UDim2.new(1, -16, 0, 30), 20) t.ZIndex = 9
		t.TextXAlignment = Enum.TextXAlignment.Left
		local n = label(r, "Info", finishText(item), UDim2.fromOffset(8, 30), UDim2.new(1, -16, 0, 22), 15) n.ZIndex = 9
		n.TextXAlignment = Enum.TextXAlignment.Left
		r.Activated:Connect(function() selectedId = item.id picked = nil status.Text = "" redraw() end)
		table.insert(rows, r)
	end
	right.Visible = chosen ~= nil
	if not chosen then return end
	if cardType ~= chosen.type then
		if cardIcon then cardIcon:Destroy() end
		cardIcon = CrusherIcon.new(cardFrame, chosen.type, { position = UDim2.fromOffset(8, 8), size = UDim2.new(1, -16, 0, 160), zIndex = 7, modifier = chosen.modifier })
		cardType = chosen.type
	end
	cardName.Text = C.typeById(chosen.type).name
	cardInfo.Text = finishText(chosen)
	local current = C.modifier(chosen.modifier)
	for _, recipe in C.Coatings do
		local b = finishButtons[recipe.name]
		local mult = C.modifier(recipe.name).mult
		local better = current and mult > current.mult
		b.Text = recipe.name .. " x" .. mult .. "\n" .. (if better then Format.cash(P.cost(chosen, recipe.name)) else "already as good")
		Style.setButtonColor(b, if better then (if picked == recipe.name then Color3.fromRGB(255, 255, 255) else recipe.color) else GREY)
		b:SetAttribute("Usable", better)
	end
	local quote = state.coating
	local ready = picked ~= nil and quote ~= nil and quote.id == chosen.id and quote.target == picked
	if picked then
		local now = (chosen.stats and chosen.stats.cps or 0) * 60
		local after = now * C.modifier(picked).mult / (current and current.mult or 1)
		previewText.Text = C.typeById(chosen.type).name .. ": " .. chosen.modifier .. " → " .. picked .. "\n"
			.. Format.cash(now) .. " → " .. Format.cash(after) .. "/min · " .. Format.cash(P.cost(chosen, picked))
	else
		previewText.Text = "Pick a finish to see the price and output."
	end
	local cost = if picked then P.cost(chosen, picked) or 0 else 0
	coat.Text = if not picked then "PICK A FINISH" elseif not ready then "CHECKING..." else "COAT · " .. Format.cash(cost)
	Style.setButtonColor(coat, if ready and state.cash >= cost then GREEN else GREY)
end
for name, b in finishButtons do
	b.Activated:Connect(function()
		if not state or not selectedId or b:GetAttribute("Usable") ~= true then return end
		picked = name status.Text = ""
		actionRemote:FireServer("QuoteCoating", { id = name, item = selectedId })
		redraw()
	end)
end
local lastSent = 0
coat.Activated:Connect(function()
	local quote = state and state.coating
	if not picked or not quote or quote.id ~= selectedId or quote.target ~= picked then return end
	if state.cash < quote.cost then status.Text = "Need " .. Format.cash(quote.cost - state.cash) .. " more. Collect and sell scrap." return end
	if os.clock() - lastSent < .5 then return end
	lastSent = os.clock()
	status.Text = "Coating..." status.TextColor3 = Color3.new(1, 1, 1)
	actionRemote:FireServer("ApplyCoating", { token = quote.token, item = selectedId })
end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	state = v
	if panel.Visible and type(v.message) == "string" then
		if v.result and v.result.coating then
			status.Text = "COATED! " .. v.result.coating .. " applied." status.TextColor3 = Color3.fromRGB(255, 205, 60)
			picked = nil
		elseif v.message ~= "Done!" and v.message ~= "Review the coating preview, then confirm." then
			status.Text = v.message status.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end
	redraw()
end)

local function mine(prompt: ProximityPrompt): boolean
	local node: Instance? = prompt
	while node and not (node:IsA("Model") and node:GetAttribute("Index") ~= nil) do node = node.Parent end
	return node ~= nil and node:GetAttribute("Index") == me:GetAttribute("Plot")
end
PPS.PromptTriggered:Connect(function(prompt)
	if prompt.Name ~= "CoatingPrompt" or not mine(prompt) then return end
	picked = nil status.Text = "" status.TextColor3 = Color3.new(1, 1, 1)
	fitWindow()
	Style.setOpen(panel, true)
	actionRemote:FireServer("Sync")
	redraw()
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then redraw() else picked = nil end end)
