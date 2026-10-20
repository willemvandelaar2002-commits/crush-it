--!strict
-- Scrap HUD and effects:
--   * a pill at the bottom centre: how much scrap you carry (worth in cash) and
--     "Sell it at your Scrap Shop!" (hidden at 0)
--   * picking scrap up: a quick high "clink" and the pill pops
--   * selling (anyone's shop): the furnace flares, coins sound, big "+$X" over the
--     smelter; for your own sale also a toast near the cash
-- Server side: server/Scrap.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Store = require(ReplicatedStorage.Shared.Store)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ScrapHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local pill = Instance.new("Frame")
pill.Name = "ScrapPill"
pill.AnchorPoint = Vector2.new(0.5, 1)
pill.Position = UDim2.new(0.5, 0, 1, -14)
pill.Size = UDim2.fromOffset(250, 62)
pill.Visible = false
pill.Parent = gui
Style.panel(pill, Color3.fromRGB(255, 170, 60), Color3.fromRGB(205, 90, 30))
local scale = Instance.new("UIScale")
scale.Parent = pill

local icon = Instance.new("TextLabel")
icon.Position = UDim2.fromOffset(6, 4)
icon.Size = UDim2.fromOffset(54, 54)
icon.BackgroundTransparency = 1
icon.TextScaled = true
icon.Text = "⚙️"
icon.ZIndex = 2
icon.Parent = pill

local amount = Instance.new("TextLabel")
amount.Position = UDim2.fromOffset(64, 4)
amount.Size = UDim2.new(1, -72, 0, 32)
amount.BackgroundTransparency = 1
amount.TextScaled = true
amount.TextXAlignment = Enum.TextXAlignment.Left
amount.Text = "$0 scrap"
amount.ZIndex = 2
amount.Parent = pill
Style.text(amount, 3)

local hint = Instance.new("TextLabel")
hint.Position = UDim2.fromOffset(64, 36)
hint.Size = UDim2.new(1, -72, 0, 20)
hint.BackgroundTransparency = 1
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "Sell it at your Scrap Shop!"
hint.ZIndex = 2
hint.Parent = pill
Style.text(hint, 2)
hint.TextColor3 = Color3.fromRGB(255, 245, 200)

local function refresh()
	local scrap = (player:GetAttribute("Scrap") :: number?) or 0
	pill.Visible = scrap > 0 and not Store.hasPass(player, "AutoCollect")
	amount.Text = Format.cash(scrap) .. " scrap"
end
player:GetAttributeChangedSignal("Scrap"):Connect(refresh)
player:GetAttributeChangedSignal(Store.passAttr("AutoCollect")):Connect(refresh)
refresh()

local function pop(size: number)
	scale.Scale = size
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function sound(id: number, volume: number, pitch: number, at: Vector3?)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	if at then
		local holder = Instance.new("Attachment")
		holder.WorldPosition = at
		holder.Parent = Workspace.Terrain
		s.Parent = holder
		Debris:AddItem(holder, 3)
	else
		s.Parent = gui
		Debris:AddItem(s, 3)
	end
	s:Play()
end

-- A big floating "+$X" in the world.
local function floatText(at: Vector3, text: string, color: Color3, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = Workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(size, size * 0.3)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = text
	label.Parent = bb
	Style.text(label, 4)
	label.TextColor3 = color
	TweenService:Create(anchor, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { CFrame = CFrame.new(at + Vector3.new(0, 7, 0)) }):Play()
	task.delay(0.9, function()
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	end)
	Debris:AddItem(anchor, 1.5)
end

Net.event("ScrapPicked").OnClientEvent:Connect(function(msg)
	sound(Config.Sounds.Coin, 0.35, 1.7 + math.random() * 0.2)
	pop(1.12)
end)

Net.event("ScrapSold").OnClientEvent:Connect(function(msg)
	local mine = msg.owner == player
	-- furnace flare on that shop
	local plots = Workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(msg.plot))
	local furnace = plot and plot:FindFirstChild("Furnace", true) :: BasePart?
	if furnace then
		local light = furnace:FindFirstChildOfClass("PointLight")
		furnace.Color = Color3.fromRGB(255, 230, 120)
		TweenService:Create(furnace, TweenInfo.new(0.8), { Color = Color3.fromRGB(255, 130, 40) }):Play()
		if light then
			light.Brightness = 6
			TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 1.6 }):Play()
		end
	end
	if msg.auto then
		-- Auto Collect sells constantly: keep it quiet, a small pop near the player
		if mine then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				floatText(root.Position + Vector3.new(0, 3, 0), "+" .. Format.cash(msg.amount), Color3.fromRGB(150, 255, 110), 5)
			end
			sound(Config.Sounds.Coin, 0.3, 1.4)
		end
		return
	end
	floatText(msg.position + Vector3.new(0, 3, 0), "+" .. Format.cash(msg.amount), Color3.fromRGB(150, 255, 110), if mine then 12 else 8)
	sound(Config.Sounds.Coin, if mine then 0.8 else 0.4, 1, msg.position)
	if mine then
		task.delay(0.12, function()
			sound(Config.Sounds.Coin, 0.6, 1.25)
		end)
		task.delay(0.24, function()
			sound(Config.Sounds.Coin, 0.5, 1.5)
		end)
	end
end)

-- Lava/oil channels: slide their ripple textures slowly (tag "FlowTexture").
local CollectionService = game:GetService("CollectionService")
game:GetService("RunService").RenderStepped:Connect(function(dt)
	for _, t in CollectionService:GetTagged("FlowTexture") do
		if t:IsA("Texture") then
			local speed = (t:GetAttribute("Flow") :: number?) or 1
			t.OffsetStudsU = (t.OffsetStudsU + speed * dt) % t.StudsPerTileU
		end
	end
end)

-- Lava: slide the bright blobs and crust plates along their strip (tag
-- "LavaDrift", built by Build.lava). Local only, one BulkMoveTo per frame.
local drifters: { BasePart } = {}
local function addDrifter(p: Instance)
	if p:IsA("BasePart") then
		table.insert(drifters, p)
	end
end
for _, p in CollectionService:GetTagged("LavaDrift") do
	addDrifter(p)
end
CollectionService:GetInstanceAddedSignal("LavaDrift"):Connect(addDrifter)
local t0 = os.clock()
game:GetService("RunService").RenderStepped:Connect(function()
	local now = os.clock() - t0
	local parts: { BasePart } = {}
	local cfs: { CFrame } = {}
	for _, p in drifters do
		local len = p:GetAttribute("Len") :: number?
		if not len or not p.Parent then
			continue
		end
		local d = ((p:GetAttribute("Start") :: number) + now * (p:GetAttribute("Speed") :: number)) % len
		local pos = (p:GetAttribute("Origin") :: Vector3) + (p:GetAttribute("Axis") :: Vector3) * d
		table.insert(parts, p)
		table.insert(cfs, CFrame.new(pos) * (p.CFrame - p.CFrame.Position))
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
