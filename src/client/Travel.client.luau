--!strict
-- Two chunky travel buttons at the top centre (like the reference game's
-- "Market" / "To Base"): MEGA CRUSHER takes you to the hub, MY FACTORY back to
-- your plot. The server does the teleport (Net "Travel").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local me = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TravelButtons"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.Parent = me:WaitForChild("PlayerGui")

local row = Instance.new("Frame")
row.Name = "Row"
row.AnchorPoint = Vector2.new(0.5, 0)
row.Position = UDim2.new(0.5, 0, 0, 6)
row.Size = UDim2.fromOffset(800, 54) -- room for REBUILD
-- 30 Oct (phone patch): top right on phones, clear of the INDEX/SHOP/REWARDS icons
-- 3 Nov (vault: Responsive UI, 44 px taps): on phones the buttons are narrower and the
-- row is only as wide as its visible buttons, so the scale stays high enough that
-- the buttons draw at least ~44 px tall; margin leaves room for the 4 HUD icons
Style.phoneFit(row, { scale = 0.9, margin = 285, anchor = Vector2.new(1, 0), position = UDim2.new(1, -8, 0, 6) })
row.BackgroundTransparency = 1
row.Parent = gui
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 12)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = row

local function travelButton(name: string, label: string, color: Color3, where: string?, order: number?): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.Size = UDim2.fromOffset(190, 54)
	b.LayoutOrder = order or 0
	b.Parent = row
	Style.button(b, color)
	local outline = b:FindFirstChild("Outline") :: UIStroke?
	if outline then outline.Thickness = 4 end
	-- 30 Oct: studs tinted with the button colour, clearly visible (still)
	local studs = Style.studsImage(b, 20, 0.15)
	studs.ZIndex = 2 studs.ImageColor3 = color
	-- the label is a child so it draws above the stud texture
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Text = label
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.new(1, -18, 1, -14)
	t.TextScaled = true
	t.ZIndex = 3
	t.Parent = b
	Style.text(t, 3)
	Style.bold(t, 3.5)
	if where then b.Activated:Connect(function() Net.event("Travel"):FireServer(where) end) end
	return b
end
local toHub = travelButton("ToHub", "Mega Crusher", Color3.fromRGB(170, 80, 255), "Hub", 2)
local toPlot = travelButton("ToPlot", "My Factory", Color3.fromRGB(255, 160, 20), "Plot", 3)
-- 3 Nov (Willem): only the button that goes somewhere else shows: on your own plot
-- MEGA CRUSHER, anywhere else MY FACTORY (same 140-stud plot radius as golden toys)
local function onOwnPlot(): boolean
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	local origin = plot and plot:GetAttribute("Origin") :: CFrame?
	if not root or not origin then return true end
	return (root.Position - origin.Position).Magnitude <= 140
end
task.spawn(function()
	while true do
		local home = onOwnPlot()
		if toHub.Visible ~= home then toHub.Visible = home end
		if toPlot.Visible == home then toPlot.Visible = not home end
		task.wait(0.4)
	end
end)

-- EQUIP BEST (reference: "Equip Best" next to "Market"): the server puts your
-- highest-output crushers in your bays. A red "!" shows when it would help.
local equipBest = travelButton("EquipBest", "Equip Best", Color3.fromRGB(50, 225, 70), nil, 1)
equipBest.Activated:Connect(function() Net.event("CrusherAction"):FireServer("EquipBest") end)
local mark = Instance.new("Frame")
mark.Name = "Better"
mark.AnchorPoint = Vector2.new(0.5, 0.5)
mark.Position = UDim2.new(1, -6, 0, 6)
mark.Size = UDim2.fromOffset(28, 28)
mark.BackgroundColor3 = Color3.fromRGB(225, 45, 50)
mark.Visible = false
mark.ZIndex = 5
mark.Parent = equipBest
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 5) corner.Parent = mark
local stroke = Instance.new("UIStroke") stroke.Thickness = 3 stroke.Color = Style.Colors.Ink stroke.Parent = mark
local bang = Instance.new("TextLabel")
bang.Text = "!" bang.BackgroundTransparency = 1 bang.TextScaled = true bang.ZIndex = 6
bang.Position = UDim2.fromScale(0.15, 0.08) bang.Size = UDim2.fromScale(0.7, 0.84) bang.Parent = mark
Style.text(bang, 2)
Style.wobble(mark, 10, 5)
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.items) ~= "table" then return end
	-- would Equip Best change anything? The server runs the real rule (rows included)
	local better = v.equipBetter == true
	mark.Visible = better
end)

-- 3 Nov (Willem, from a player's idea): press the FILL ROW board at a row's sign
-- to pick a rarity; the server fills that row with your
-- best crushers of it, so the row bonus is one press away.
local C = Config.Crushers
local menu = Instance.new("Frame")
menu.Name = "RarityPicker" menu.BackgroundColor3 = Color3.fromRGB(30, 34, 52) menu.Visible = false menu.ZIndex = 10
menu.AnchorPoint = Vector2.new(0.5, 0.5) menu.Position = UDim2.fromScale(0.5, 0.5)
menu.AutomaticSize = Enum.AutomaticSize.Y menu.Size = UDim2.fromOffset(280, 0) menu.Parent = gui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = menu
local ms = Instance.new("UIStroke") ms.Thickness = 4 ms.Color = Style.Colors.Ink ms.Parent = menu
local mp = Instance.new("UIPadding") mp.PaddingTop = UDim.new(0, 8) mp.PaddingBottom = UDim.new(0, 8) mp.PaddingLeft = UDim.new(0, 8) mp.PaddingRight = UDim.new(0, 8) mp.Parent = menu
local ml = Instance.new("UIListLayout") ml.Padding = UDim.new(0, 6) ml.SortOrder = Enum.SortOrder.LayoutOrder ml.Parent = menu
local menuTitle = Instance.new("TextLabel")
menuTitle.Text = "FILL ROW" menuTitle.BackgroundTransparency = 1 menuTitle.TextScaled = true menuTitle.Size = UDim2.new(1, 0, 0, 30)
menuTitle.ZIndex = 11 menuTitle.LayoutOrder = 0 menuTitle.Parent = menu
Style.text(menuTitle, 2)
local scale = Instance.new("UIScale") scale.Parent = menu
local last: any = nil
local rowIndex = 1
local function choice(order: number, label: string, color: Color3, onPick: () -> ())
	local b = Instance.new("TextButton")
	b.Name = "Pick" .. order b.Text = "" b.Size = UDim2.new(1, 0, 0, 42) b.LayoutOrder = order b.ZIndex = 11 b.Parent = menu
	Style.button(b, color)
	local t = Instance.new("TextLabel")
	t.Text = label t.BackgroundTransparency = 1 t.TextScaled = true t.ZIndex = 12
	t.AnchorPoint = Vector2.new(0.5, 0.5) t.Position = UDim2.fromScale(0.5, 0.5) t.Size = UDim2.new(1, -14, 1, -12) t.Parent = b
	Style.text(t, 2.5)
	b.Activated:Connect(function() menu.Visible = false onPick() end)
end
local function openPicker(index: number)
	rowIndex = index
	for _, c in menu:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
	local counts: { [string]: number } = {}
	for _, item in (last and last.items) or {} do counts[item.rarity] = (counts[item.rarity] or 0) + 1 end
	local first = (index - 1) * C.Layout.PerWing + 1
	menuTitle.Text = "FILL ROW " .. index .. " (BAYS " .. first .. "-" .. (first + C.Layout.PerWing - 1) .. ")"
	for i, r in C.Rarities do
		local n = counts[r.name]
		if n and n > 0 then
			local bonus = math.floor((C.RowBonuses[r.name] or 0) * 100 + 0.5)
			choice(i, string.upper(r.name) .. " x" .. n .. "  (+" .. bonus .. "%)", r.color, function()
				Net.event("CrusherAction"):FireServer("FillRow", { row = rowIndex, rarity = r.name })
			end)
		end
	end
	choice(99, "CLOSE", Color3.fromRGB(120, 124, 134), function() end)
	scale.Scale = if Style.compact() then 0.75 else 1
	menu.Visible = true
end
-- the FILL ROW board's button (bound in CrusherHud) fires this with the row number
local openEvent = Instance.new("BindableEvent") openEvent.Name = "OpenFillRow" openEvent.Parent = gui
openEvent.Event:Connect(function(index: any) if type(index) == "number" then openPicker(index) end end)

-- 3 Nov (a player's idea + vault: a run after a rebirth must feel faster):
-- REBUILD, only after your first rebirth and while you have bays left to buy
local rebuild = travelButton("Rebuild", "REBUILD", Color3.fromRGB(255, 120, 40), nil, 4)
rebuild.Visible = false
rebuild.Activated:Connect(function() Net.event("CrusherAction"):FireServer("Rebuild") end)
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" then return end
	last = v
	local capacity = C.bayCapacity(v.plotLevel or 0)
	rebuild.Visible = (v.rebirths or 0) >= 1 and (v.unlocked or 0) < capacity
end)

-- 3 Nov: phone sizing (see the phoneFit note above)
local function phoneWidths()
	local compact = Style.compact()
	for _, b in row:GetChildren() do
		if b:IsA("TextButton") then b.Size = UDim2.fromOffset(if compact then 128 else 190, 54) end
	end
	-- (AbsoluteContentSize already includes the phone UIScale, so add up the
	-- unscaled widths of the visible buttons instead)
	local w, n = 0, 0
	for _, b in row:GetChildren() do
		if b:IsA("TextButton") and b.Visible then w += b.Size.X.Offset n += 1 end
	end
	w = math.max(54, w + math.max(0, n - 1) * list.Padding.Offset)
	row.Size = UDim2.fromOffset(if compact then w else 800, 54)
end
for _, b in row:GetChildren() do if b:IsA("TextButton") then b:GetPropertyChangedSignal("Visible"):Connect(phoneWidths) end end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(phoneWidths)
phoneWidths()
