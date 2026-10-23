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
row.Size = UDim2.fromOffset(392, 54)
row.BackgroundTransparency = 1
row.Parent = gui
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 12)
list.Parent = row

local function travelButton(name: string, label: string, color: Color3, where: string)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.Size = UDim2.fromOffset(190, 54)
	b.Parent = row
	Style.button(b, color)
	local outline = b:FindFirstChild("Outline") :: UIStroke?
	if outline then outline.Thickness = 4 end
	local studs = Style.studsImage(b, 18, 0.82)
	studs.ZIndex = 2
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
	b.Activated:Connect(function() Net.event("Travel"):FireServer(where) end)
end
travelButton("ToHub", "Mega Crusher", Color3.fromRGB(150, 70, 225), "Hub")
travelButton("ToPlot", "My Factory", Color3.fromRGB(255, 150, 30), "Plot")
