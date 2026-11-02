--!strict
-- 2 Nov (vault: Social Design - "rare moments visible to the whole server"):
-- when anyone rolls a Legendary or better, every player sees a short banner
-- ("Willem rolled a LEGENDARY Quantum!"). Sent by CrusherGame.rollShow as RarePull.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Config = require(RS.Shared.Config)

local me = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RarePullHud" gui.ResetOnSpawn = false gui.DisplayOrder = 8
gui.Parent = me:WaitForChild("PlayerGui")

local queue: { any } = {}
local busy = false
local function show(msg: any)
	busy = true
	local bar = Instance.new("TextLabel")
	bar.AnchorPoint = Vector2.new(0.5, 0) bar.Position = UDim2.new(0.5, 0, 0, -60) bar.Size = UDim2.fromOffset(620, 46)
	bar.BackgroundColor3 = Color3.fromRGB(24, 28, 46) bar.BackgroundTransparency = 0.15 bar.TextScaled = true bar.RichText = true
	local color = if typeof(msg.color) == "Color3" then msg.color else Color3.fromRGB(255, 200, 55)
	local mine = msg.userId == me.UserId
	bar.Text = if type(msg.text) == "string" then msg.text else string.format('%s rolled a <font color="#%s">%s %s</font>!', if mine then "You" else tostring(msg.player),
		color:ToHex(), string.upper(tostring(msg.rarity)), tostring(msg.name))
	Style.text(bar, 2.5)
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = bar
	local s = Instance.new("UIStroke") s.Thickness = 3 s.Color = color s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = bar
	local p = Instance.new("UIPadding") p.PaddingTop = UDim.new(0, 6) p.PaddingBottom = UDim.new(0, 6) p.PaddingLeft = UDim.new(0, 14) p.PaddingRight = UDim.new(0, 14) p.Parent = bar
	Style.phoneFit(bar, { scale = 0.7, width = 0.92 })
	bar.Parent = gui
	local sound = Instance.new("Sound") sound.SoundId = "rbxassetid://" .. Config.Sounds.LevelUp sound.Volume = if mine then 0.5 else 0.25
	sound.Parent = SoundService sound:Play() task.delay(3, function() sound:Destroy() end)
	-- below the HUD buttons, above the tutorial headline area's right side
	TweenService:Create(bar, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 1, -120) }):Play()
	bar.Position = UDim2.new(0.5, 0, 1, 20)
	task.wait(3.2)
	local out = TweenService:Create(bar, TweenInfo.new(0.25), { Position = UDim2.new(0.5, 0, 1, 20) })
	out:Play() out.Completed:Wait()
	bar:Destroy()
	busy = false
	local nextMsg = table.remove(queue, 1)
	if nextMsg then task.spawn(show, nextMsg) end
end
Net.event("RarePull").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" then return end
	if busy then if #queue < 3 then table.insert(queue, msg) end return end
	task.spawn(show, msg)
end)
