--!strict
-- Feedback for the world-mounted purchase controls (boards and bay plaques):
-- hover grows and outlines the whole row, a click punches it, and the server's
-- answer either flashes it with a rising "+1 LEVEL!" or shakes it red.
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local Fx = {}
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
local BOUNCE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function play(id: number?, volume: number?)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.6
	SoundService:PlayLocalSound(s)
	task.delay(3, function() s:Destroy() end)
end

-- The animated holder for a button: its board row, or the plaque/station gui.
function Fx.rowOf(button: GuiObject): GuiObject
	local parent = button.Parent
	if parent and parent:IsA("Frame") and parent.Name:match("^Row_") then return parent end
	return button
end

local function scaleOf(g: GuiObject): UIScale
	local s = g:FindFirstChild("FxScale") :: UIScale?
	if not s then
		local n = Instance.new("UIScale")
		n.Name = "FxScale"
		n.Parent = g
		s = n
	end
	return s :: UIScale
end

-- Hover and click animate only the button itself (the green price button).
function Fx.bind(button: GuiButton)
	-- one scale only: drop Style.button's own press scale
	local own = button:FindFirstChild("FeedbackScale")
	if own then own:Destroy() end
	local scale = scaleOf(button)
	local glow = Instance.new("UIStroke")
	glow.Name = "HoverGlow"
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Thickness = 0
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = button
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, QUICK, { Scale = 1.08 }):Play()
		TweenService:Create(glow, QUICK, { Thickness = 3 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, QUICK, { Scale = 1 }):Play()
		TweenService:Create(glow, QUICK, { Thickness = 0 }):Play()
	end)
	button.Activated:Connect(function()
		scale.Scale = 0.92
		TweenService:Create(scale, BOUNCE, { Scale = 1.08 }):Play()
	end)
end

-- Server accepted the purchase.
function Fx.success(row: GuiObject, text: string?)
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0.25
	flash.ZIndex = 20
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = flash
	flash.Parent = row
	TweenService:Create(flash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	task.delay(0.5, function() flash:Destroy() end)
	-- rising "+1 LEVEL!" over the row, inside the same surface
	local gui = row:FindFirstAncestorWhichIsA("LayerCollector") or row
	local pop = Instance.new("TextLabel")
	pop.Name = "LevelPop"
	pop.BackgroundTransparency = 1
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Size = UDim2.fromScale(0.6, 0.22)
	local at = row.AbsolutePosition + row.AbsoluteSize / 2 - (gui :: any).AbsolutePosition
	local total = (gui :: any).AbsoluteSize
	pop.Position = UDim2.fromScale(at.X / math.max(1, total.X), at.Y / math.max(1, total.Y))
	pop.Text = text or "+1 LEVEL!"
	pop.TextScaled = true
	pop.ZIndex = 30
	Style.text(pop, 3)
	pop.TextColor3 = Color3.fromRGB(120, 255, 110)
	pop.Parent = gui
	TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Position = pop.Position - UDim2.fromScale(0, 0.25) }):Play()
	TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	task.delay(1, function() pop:Destroy() end)
	play(Config.Sounds.LevelUp, 0.5)
end

-- Server refused (not enough cash, too far away, ...).
function Fx.fail(row: GuiObject)
	local start = row.Position
	local tint = Instance.new("Frame")
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
	tint.BackgroundTransparency = 0.35
	tint.ZIndex = 20
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tint
	tint.Parent = row
	task.spawn(function()
		for i = 1, 6 do
			row.Position = start + UDim2.fromOffset(if i % 2 == 0 then 8 else -8, 0)
			task.wait(0.04)
		end
		row.Position = start
		TweenService:Create(tint, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.wait(0.35)
		tint:Destroy()
	end)
end

return Fx
