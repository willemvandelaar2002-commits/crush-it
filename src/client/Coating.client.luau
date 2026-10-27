--!strict
-- Coating Lab screen (Willem's mockup). Opens from the coating booth on your
-- own plot (prompt "CoatingPrompt", Factory II and up).
--   left: YOUR CRUSHERS, a grid of your unequipped crushers (3D pictures)
--   middle: the chosen crusher now, an arrow, and how it looks with the picked coating
--   right: CHOOSE A COATING (4 cards), the output multiplier and APPLY
-- Picking a coating asks the server for a quote (QuoteCoating); APPLY confirms
-- it (ApplyCoating). The server checks, charges and saves; numbers shown are
-- the real ones.
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
local Icons = require(RS.Shared.Icons)
local CrusherIcon = require(script.Parent.CrusherIcon)
local L = require(script.Parent.LabUi)
local make = L.make

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local W, H = 1000, 640
local PURPLE = Color3.fromRGB(150, 80, 235)
local INDIGO = Color3.fromRGB(56, 54, 150)
local CYAN = Color3.fromRGB(90, 230, 255)
local LOOK = {
	Polished = { a = Color3.fromRGB(178, 186, 200), b = Color3.fromRGB(116, 126, 146), glyph = "💧", icon = Icons.FinishPolished, spark = nil, sparkColor = Color3.new(1, 1, 1) },
	Frost = { a = Color3.fromRGB(70, 204, 245), b = Color3.fromRGB(28, 120, 205), glyph = "❄️", icon = Icons.FinishFrost, spark = { "❄️", "❄️" }, sparkColor = Color3.fromRGB(200, 250, 255) },
	Fire = { a = Color3.fromRGB(252, 124, 42), b = Color3.fromRGB(205, 62, 22), glyph = "🔥", icon = Icons.FinishFire, spark = nil, sparkColor = Color3.fromRGB(255, 210, 90) },
	Charged = { a = Color3.fromRGB(162, 92, 242), b = Color3.fromRGB(98, 40, 182), glyph = "⚡", icon = Icons.FinishCharged, spark = nil, sparkColor = Color3.fromRGB(235, 170, 255) },
}

local gui = make("ScreenGui", { Name = "CoatingHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local panel = L.window(gui, { name = "CoatingWindow", w = W, h = H, color = PURPLE, colorDark = Color3.fromRGB(100, 44, 190),
	title = "COATING LAB", subtitle = "Choose a crusher and a coating.", icon = Icons.CoatingLab, glyph = "🎨" })

-- left: your crushers
local left = L.section(panel, "YourCrushers", "YOUR CRUSHERS", UDim2.fromOffset(14, 140), UDim2.fromOffset(330, H - 154), INDIGO)
local grid = make("ScrollingFrame", { Name = "Grid", Position = UDim2.fromOffset(8, 64), Size = UDim2.new(1, -16, 1, -72), BackgroundTransparency = 1,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 8 }, left)
make("UIGridLayout", { CellSize = UDim2.fromOffset(146, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, grid)
local empty = L.text(left, "Empty", "All your crushers are equipped. Swap one out at its bay to coat it.", UDim2.fromOffset(14, 80), UDim2.new(1, -28, 0, 120), 22)

-- middle: before -> after
local mid = L.panel(panel, "Preview", UDim2.fromOffset(354, 140), UDim2.fromOffset(276, H - 154), PURPLE, Color3.fromRGB(110, 52, 200), 14)
local midName = L.text(mid, "Name", "", UDim2.fromOffset(6, 8), UDim2.new(1, -12, 0, 44), 34, 4)
local midLevel = L.pill(mid, "Level", "", UDim2.new(.5, -64, 0, 54), UDim2.fromOffset(128, 36))
local before = make("Frame", { Name = "Before", Position = UDim2.new(.5, -110, 0, 96), Size = UDim2.fromOffset(220, 160), BackgroundTransparency = 1, ZIndex = 8 }, mid)
L.arrow(mid, UDim2.new(.5, -26, 0, 260), UDim2.fromOffset(52, 56))
local after = make("Frame", { Name = "After", Position = UDim2.new(.5, -118, 0, 318), Size = UDim2.fromOffset(236, 168), BackgroundTransparency = 1, ZIndex = 8 }, mid)
local afterHint = L.text(mid, "AfterHint", "?", UDim2.new(.5, -118, 0, 318), UDim2.fromOffset(236, 168), 90, 5)
local status = L.text(mid, "Status", "", UDim2.new(0, 6, 1, -44), UDim2.new(1, -12, 0, 38), 20, 2)

-- right: coatings
local right = L.section(panel, "Coatings", "CHOOSE A COATING", UDim2.fromOffset(640, 140), UDim2.fromOffset(346, 334), INDIGO)
local cards: { [string]: any } = {}
for i, recipe in C.Coatings do
	local look = LOOK[recipe.name]
	local b = make("TextButton", { Name = "Card_" .. recipe.name, Text = "", AutoButtonColor = false, ZIndex = 8,
		Position = UDim2.fromOffset(10 + ((i - 1) % 2) * 166, 62 + math.floor((i - 1) / 2) * 132), Size = UDim2.fromOffset(160, 128) }, right)
	Style.panel(b :: any, look.a, look.b)
	;(b:FindFirstChild("Corner") :: UICorner).CornerRadius = UDim.new(0, 14)
	L.art(b, look.icon, look.glyph, UDim2.new(.5, -26, 0, 4), UDim2.fromOffset(52, 44), 9)
	L.text(b, "Name", recipe.name, UDim2.fromOffset(0, 46), UDim2.new(1, 0, 0, 24), 24, 3)
	local mult = L.text(b, "Mult", "x" .. C.modifier(recipe.name).mult, UDim2.fromOffset(0, 69), UDim2.new(1, 0, 0, 24), 24, 3)
	local price = L.pill(b, "Price", "", UDim2.new(.08, 0, 1, -33), UDim2.new(.84, 0, 0, 28), L.GREEN, nil, 22)
	cards[recipe.name] = { button = b, price = price, mult = mult }
end
local info = L.panel(panel, "Multiplier", UDim2.fromOffset(640, 482), UDim2.fromOffset(346, 72), Color3.fromRGB(30, 34, 62), Color3.fromRGB(20, 22, 44), 12)
local infoTitle = L.text(info, "Title", "Output multiplier:", UDim2.fromOffset(12, 4), UDim2.fromOffset(190, 24), 18, 2)
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
local infoMult = make("TextLabel", { Name = "Mult", RichText = true, Text = "", Position = UDim2.fromOffset(12, 28), Size = UDim2.fromOffset(190, 40),
	BackgroundTransparency = 1, Font = L.Font, TextSize = 34, TextColor3 = L.WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10 }, info)
make("UIStroke", { Thickness = 3, Color = L.INK }, infoMult)
make("Frame", { Name = "Divider", Position = UDim2.fromOffset(204, 10), Size = UDim2.new(0, 2, 1, -20), BackgroundColor3 = Color3.fromRGB(80, 90, 130), BorderSizePixel = 0, ZIndex = 10 }, info)
local infoNote = L.text(info, "Note", "Replaces the current coating.", UDim2.fromOffset(212, 6), UDim2.new(1, -220, 1, -12), 18, 2)
infoNote.TextColor3 = Color3.fromRGB(170, 185, 225)
local apply = L.button(panel, "Apply", "PICK A COATING", UDim2.fromOffset(640, 560), UDim2.fromOffset(346, 66), L.GREY, 36)

local state: any = nil
local selectedId: string? = nil
local picked: string? = nil -- coating we asked a quote for
local tiles: { Instance } = {}
local beforeKey, afterKey = "", ""
local beforeIcon: Frame?, afterIcon: Frame?, afterSparks: Frame?

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
local function multText(m: number): string return "x" .. (math.floor(m * 100 + .5) / 100) end

local function redraw()
	if not state or not panel.Visible then return end
	for _, t in tiles do t:Destroy() end
	table.clear(tiles)
	local items = unequipped()
	empty.Visible = #items == 0
	local chosen
	for _, item in items do if item.id == selectedId then chosen = item end end
	if not chosen then chosen = items[1] selectedId = chosen and chosen.id picked = nil end
	for i, item in items do
		local t = L.tile(grid, "Crusher_" .. i, UDim2.fromOffset(146, 150), item, C.typeById(item.type).name,
			"Lv. " .. item.level .. (if item.fused then " ★" else ""))
		t.LayoutOrder = i
		L.select(t, item == chosen)
		t.Activated:Connect(function() selectedId = item.id picked = nil status.Text = "" redraw() end)
		table.insert(tiles, t)
	end
	mid.Visible = chosen ~= nil
	for _, c in cards do c.button.Visible = chosen ~= nil end
	if not chosen then
		apply.Text = "NOTHING TO COAT" Style.setButtonColor(apply, L.GREY) infoMult.Text = "" return
	end
	midName.Text = C.typeById(chosen.type).name
	L.setPill(midLevel, "Lv. " .. chosen.level .. (if chosen.modifier ~= "Standard" then " · " .. chosen.modifier else ""))
	-- before: as it is now; after: with the picked coating
	local key = chosen.type .. ":" .. chosen.modifier .. ":" .. tostring(chosen.fused)
	if key ~= beforeKey then
		if beforeIcon then beforeIcon:Destroy() end
		beforeIcon = CrusherIcon.new(before, chosen.type, { zIndex = 9, model = true,
			modifier = if chosen.modifier ~= "Standard" then chosen.modifier else nil, fused = chosen.fused })
		beforeKey = key
	end
	local akey = if picked then chosen.type .. ":" .. picked .. ":" .. tostring(chosen.fused) else ""
	if akey ~= afterKey then
		if afterIcon then afterIcon:Destroy() afterIcon = nil end
		if afterSparks then afterSparks:Destroy() afterSparks = nil end
		if picked then
			afterIcon = CrusherIcon.new(after, chosen.type, { zIndex = 9, modifier = picked, fused = chosen.fused })
			local look = LOOK[picked]
			afterSparks = L.sparkles(after, 7, look.sparkColor, look.spark)
		end
		afterKey = akey
	end
	afterHint.Visible = picked == nil
	local current = C.modifier(chosen.modifier)
	for _, recipe in C.Coatings do
		local c = cards[recipe.name]
		local mult = C.modifier(recipe.name).mult
		local better = current and mult > current.mult
		local stroke = c.button:FindFirstChild("Outline") :: UIStroke
		stroke.Color = if picked == recipe.name then CYAN else L.INK
		stroke.Thickness = if picked == recipe.name then 6 else 4
		local old = c.button:FindFirstChild("Check") if old then old:Destroy() end
		if picked == recipe.name then L.check(c.button, Color3.fromRGB(40, 160, 230)) end
		if better then L.setPill(c.price, Format.cash(P.cost(chosen, recipe.name) or 0), L.GREEN)
		else L.setPill(c.price, if chosen.modifier == recipe.name then "CURRENT" else "LOWER", L.GREY) end
		c.button:SetAttribute("Usable", better)
		c.button.BackgroundTransparency = 0
		;(c.button:FindFirstChild("PanelFill") :: UIGradient).Transparency = NumberSequence.new(if better then 0 else .35)
	end
	local now = current and current.mult or 1
	if picked then
		infoMult.Text = string.format('%s → <font color="#5AE6FF">%s</font>', multText(now), multText(C.modifier(picked).mult))
	else
		infoMult.Text = multText(now)
	end
	infoNote.Text = if chosen.modifier ~= "Standard" then "Replaces " .. chosen.modifier .. "." else "Replaces the current coating."
	local quote = state.coating
	local ready = picked ~= nil and quote ~= nil and quote.id == chosen.id and quote.target == picked
	local cost = if picked then P.cost(chosen, picked) or 0 else 0
	apply.Text = if not picked then "PICK A COATING" elseif not ready then "CHECKING..." else "APPLY " .. picked:upper() .. " – " .. Format.cash(cost)
	Style.setButtonColor(apply, if ready and state.cash >= cost then L.GREEN else L.GREY)
end
for name, c in cards do
	c.button.Activated:Connect(function()
		if not state or not selectedId or c.button:GetAttribute("Usable") ~= true then return end
		picked = name status.Text = ""
		actionRemote:FireServer("QuoteCoating", { id = name, item = selectedId })
		redraw()
	end)
end
local lastSent = 0
apply.Activated:Connect(function()
	local quote = state and state.coating
	if not picked or not quote or quote.id ~= selectedId or quote.target ~= picked then return end
	if state.cash < quote.cost then status.Text = "Need " .. Format.cash(quote.cost - state.cash) .. " more." status.TextColor3 = Color3.fromRGB(255, 130, 130) return end
	if os.clock() - lastSent < .5 then return end
	lastSent = os.clock()
	status.Text = "Coating..." status.TextColor3 = L.WHITE
	actionRemote:FireServer("ApplyCoating", { token = quote.token, item = selectedId })
end)

local previewing = false
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if previewing then return end
	state = v
	if panel.Visible and type(v.message) == "string" then
		if v.result and v.result.coating then
			status.Text = "COATED! " .. v.result.coating .. " applied." status.TextColor3 = L.GOLD
			picked = nil
		elseif v.message ~= "Done!" and v.message ~= "Review the coating preview, then confirm." then
			status.Text = v.message status.TextColor3 = Color3.fromRGB(255, 130, 130)
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
	picked = nil status.Text = "" status.TextColor3 = L.WHITE previewing = false
	L.fit(panel, W, H)
	Style.setOpen(panel, true)
	actionRemote:FireServer("Sync")
	redraw()
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then redraw() else picked = nil previewing = false end end)
-- Studio only: show the screen with a made-up state and a picked coating
-- (visual only; the server refuses ids you don't own).
if game:GetService("RunService"):IsStudio() then
	local probe = make("BindableFunction", { Name = "CoatingPreview" }, script)
	probe.OnInvoke = function(fake: any, pick: string?, id: string?)
		previewing = true state = fake picked = pick selectedId = id L.fit(panel, W, H) Style.setOpen(panel, true) redraw()
		return true
	end
end
