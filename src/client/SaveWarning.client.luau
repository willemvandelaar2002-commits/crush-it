--!strict
-- 2 Nov (vault: Data Loss Prevention): when this session can't save (the
-- DataStore failed on join, or another server took the profile) the server sets
-- the player attribute SaveOff. Say so plainly, so nobody plays an hour for
-- nothing; Robux product prompts are refused while it is on.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)

local me = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "SaveWarning" gui.ResetOnSpawn = false gui.DisplayOrder = 50
gui.Parent = me:WaitForChild("PlayerGui")
local bar = Instance.new("TextLabel")
bar.Name = "Bar" bar.AnchorPoint = Vector2.new(0.5, 1) bar.Position = UDim2.new(0.5, 0, 1, -8)
bar.Size = UDim2.fromOffset(620, 40) bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50) bar.TextScaled = true
bar.Text = "Saving is off: Roblox couldn't load your save. Rejoin to keep your progress!"
bar.Visible = false bar.Parent = gui
Style.text(bar, 2)
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 10) corner.Parent = bar
local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 5) pad.PaddingBottom = UDim.new(0, 5) pad.Parent = bar
Style.phoneFit(bar, { scale = 0.7, width = 0.9 })

local function update() bar.Visible = me:GetAttribute("SaveOff") == true end
me:GetAttributeChangedSignal("SaveOff"):Connect(update)
update()
