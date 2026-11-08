--!strict
-- 2 Nov: SMASH + FRENZY (server/Frenzy, CrusherConfig.Frenzy) and the golden toy
-- feedback (server/GoldenToys). A big SMASH button on the right (key F on PC):
-- every tap pays a little cash and fills the meter; a full meter starts FRENZY
-- (all your crushers work twice as fast for 10 s), shown with a big banner.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local Config = require(RS.Shared.Config)
local C = Config.Crushers
if not C.Enabled then return end

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local smash = Net.event("Smash")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function sound(id: number, volume: number, pitch: number?)
	local s = make("Sound", { SoundId = "rbxassetid://" .. id, Volume = volume, PlaybackSpeed = pitch or 1 }, SoundService)
	s:Play()
	task.delay(3, function() s:Destroy() end)
end

local gui = make("ScreenGui", { Name = "FrenzyHud", ResetOnSpawn = false, DisplayOrder = 3, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
-- the SMASH button: right side, a little above the middle
local holder = make("Frame", { Name = "SmashHolder", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 30),
	Size = UDim2.fromOffset(150, 190), BackgroundTransparency = 1 }, gui)
Style.phoneFit(holder, { scale = 0.5, anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -8, 0.36, 0) }) -- 6 Nov (Willem): smaller (0.72 -> 0.5) and higher (0.42 -> 0.36) on phones; the 2X CASH button sits under it
local button = make("TextButton", { Name = "Smash", Size = UDim2.fromOffset(150, 150), Text = "", AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(235, 60, 50), ZIndex = 3 }, holder)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, button)
local ring = make("UIStroke", { Thickness = 6, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 120, 90), Color3.fromRGB(200, 30, 30)) }, button)
local word = make("TextLabel", { Size = UDim2.fromScale(0.8, 0.34), Position = UDim2.fromScale(0.1, 0.33), BackgroundTransparency = 1,
	TextScaled = true, Text = "SMASH!", ZIndex = 4 }, button)
Style.text(word, 3)
local key = make("TextLabel", { Size = UDim2.fromScale(0.5, 0.16), Position = UDim2.fromScale(0.25, 0.68), BackgroundTransparency = 1,
	TextScaled = true, Text = "[F]", ZIndex = 4, Visible = not UserInputService.TouchEnabled }, button)
Style.text(key, 2)
local press = make("UIScale", { Scale = 1 }, button)
-- meter under the button
local meter = make("Frame", { Name = "Meter", Position = UDim2.fromOffset(5, 160), Size = UDim2.fromOffset(140, 22),
	BackgroundColor3 = Color3.fromRGB(24, 28, 46), ZIndex = 3 }, holder)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, meter)
make("UIStroke", { Thickness = 3, Color = INK }, meter)
local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(255, 200, 40), ZIndex = 4 }, meter)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 130, 20)) }, fill)
local meterText = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Text = "FRENZY", ZIndex = 5 }, meter)
Style.text(meterText, 2)

-- FRENZY banner
local banner = make("TextLabel", { Name = "FrenzyBanner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.66),
	Size = UDim2.fromOffset(520, 80), BackgroundTransparency = 1, TextScaled = true, Text = "FRENZY x2!", Visible = false, ZIndex = 6 }, gui)
Style.bold(banner, 4)
banner.TextColor3 = Color3.fromRGB(255, 210, 40)
local bannerScale = make("UIScale", { Scale = 1 }, banner)
local edge = make("Frame", { Name = "FrenzyGlow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 1 }, gui)
local edgeStroke = make("UIStroke", { Thickness = 14, Color = Color3.fromRGB(255, 120, 30), Transparency = 0.4 }, edge)

local untilTime = 0
local function tap()
	smash:FireServer()
	sound(Config.Sounds.Thud, 0.35, 0.9 + math.random() * 0.3)
	press.Scale = 0.86
	TweenService:Create(press, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- a small camera kick
	local cam = workspace.CurrentCamera
	if cam then cam.CFrame *= CFrame.Angles(math.rad(math.random(-6, 6) / 10), math.rad(math.random(-6, 6) / 10), 0) end
end
button.Activated:Connect(tap)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then tap() end
end)

-- a floating "+$12" from the button for each paid tap
local function payPop(amount: number)
	local p = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, math.random(-40, 40), 0, -4), Size = UDim2.fromOffset(120, 30),
		BackgroundTransparency = 1, TextScaled = true, Text = "+" .. Format.cash(amount), ZIndex = 6 }, holder)
	Style.text(p, 2.5)
	p.TextColor3 = Color3.fromRGB(140, 255, 110)
	TweenService:Create(p, TweenInfo.new(0.7), { Position = p.Position - UDim2.fromOffset(0, 50), TextTransparency = 1 }):Play()
	task.delay(0.75, function() p:Destroy() end)
end

Net.event("FrenzyState").OnClientEvent:Connect(function(s: any)
	if type(s) ~= "table" then return end
	local wasOn = untilTime > workspace:GetServerTimeNow()
	untilTime = tonumber(s.untilTime) or 0
	local on = untilTime > workspace:GetServerTimeNow()
	if not on then
		TweenService:Create(fill, TweenInfo.new(0.12), { Size = UDim2.fromScale(math.clamp((s.meter or 0) / (s.max or 1), 0, 1), 1) }):Play()
	end
	if type(s.pay) == "number" then payPop(s.pay) end
	if on and not wasOn then
		-- FRENZY starts
		sound(Config.Sounds.LevelUp, 0.6)
		banner.Visible = true edge.Visible = true
		bannerScale.Scale = 0.3
		TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end)

-- golden toys: a ding when one lands, a pop when you grab it
Net.event("GoldenToy").OnClientEvent:Connect(function(r: any)
	if type(r) ~= "table" then return end
	if r.spawned then sound(Config.Sounds.Coin, 0.5, 1.6) return end
	sound(Config.Sounds.LevelUp, 0.45, 1.3)
	local pop = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(460, 60),
		BackgroundTransparency = 1, TextScaled = true, Text = "GOLDEN TOY! " .. tostring(r.text or ""), ZIndex = 7 }, gui)
	Style.bold(pop, 4)
	pop.TextColor3 = Color3.fromRGB(255, 215, 60)
	local sc = make("UIScale", { Scale = 0.4 }, pop)
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(1.6, function()
		TweenService:Create(sc, TweenInfo.new(0.25), { Scale = 0 }):Play()
		task.delay(0.3, function() pop:Destroy() end)
	end)
end)

-- frenzy countdown, pulse and the meter showing time left
task.spawn(function()
	while true do
		task.wait(0.05)
		local left = untilTime - workspace:GetServerTimeNow()
		if left > 0 then
			banner.Text = string.format("FRENZY x%d!  %d", C.Frenzy.Speed, math.ceil(left))
			bannerScale.Scale = 1 + 0.05 * math.sin(os.clock() * 10)
			edgeStroke.Transparency = 0.3 + 0.3 * (0.5 + 0.5 * math.sin(os.clock() * 8))
			fill.Size = UDim2.fromScale(math.clamp(left / C.Frenzy.Seconds, 0, 1), 1)
			ring.Color = Color3.fromRGB(255, 210, 40)
		elseif banner.Visible then
			banner.Visible = false edge.Visible = false ring.Color = INK
			fill.Size = UDim2.fromScale(0, 1)
		end
	end
end)
