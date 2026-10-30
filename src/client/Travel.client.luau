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
row.Size = UDim2.fromOffset(600, 54)
-- 30 Oct (phone patch): top right on phones, clear of the INDEX/SHOP/REWARDS icons
Style.phoneFit(row, { scale = 0.75, margin = 230, anchor = Vector2.new(1, 0), position = UDim2.new(1, -8, 0, 6) })
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
travelButton("ToHub", "Mega Crusher", Color3.fromRGB(170, 80, 255), "Hub", 2)
travelButton("ToPlot", "My Factory", Color3.fromRGB(255, 160, 20), "Plot", 3)

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
	-- would Equip Best change anything? (same ranking as the server: output, then id)
	local list = table.clone(v.items)
	table.sort(list, function(a, b)
		if a.stats.cps == b.stats.cps then return a.id < b.id end
		return a.stats.cps > b.stats.cps
	end)
	local inBay = {}
	for _, id in v.bays or {} do inBay[id] = true end
	local better = false
	for i = 1, math.min(v.unlocked or 0, #list) do
		if not inBay[list[i].id] then better = true break end
	end
	mark.Visible = better
end)
