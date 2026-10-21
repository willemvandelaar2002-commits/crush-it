--!strict
-- Animates the Mega Crusher in the hub (server/MegaCrusher.luau, tag "MegaCrusher"):
-- every Period seconds the ram slams down on the giant toy blocks, which squash;
-- sparks, a "CRUSH!" pop-up and (when you are close) a screen shake; then the ram
-- rises slowly and the toys bounce back. Synced to the server clock.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer

type ToyPart = { part: BasePart, size: Vector3, cf: CFrame }
type Rig = { press: Model, ram: BasePart, toys: { ToyPart }, lastHit: number }
local rigs: { [Model]: Rig } = {}

local function rig(press: Model): Rig?
	local r = rigs[press]
	if r and r.ram.Parent then
		return r
	end
	local ram = press:FindFirstChild("Ram") :: BasePart?
	local toy = press:FindFirstChild("Toy")
	if not ram or not toy then
		return nil
	end
	local toys = {}
	for _, p in toy:GetChildren() do
		if p:IsA("BasePart") then
			table.insert(toys, { part = p, size = p.Size, cf = p.CFrame })
		end
	end
	r = { press = press, ram = ram, toys = toys, lastHit = -1 }
	rigs[press] = r
	return r
end

local function burst(at: Vector3)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Speed = NumberRange.new(18, 34)
	e.SpreadAngle = Vector2.new(80, 80)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Size = NumberSequence.new(0.9, 0)
	e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 130), Color3.fromRGB(255, 120, 40))
	e.LightEmission = 1
	e.Acceleration = Vector3.new(0, -50, 0)
	e.Enabled = false
	e.Parent = a
	e:Emit(60)
	Debris:AddItem(a, 1.2)
end

local function pop(at: Vector3)
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.CanTouch = false
	a.Transparency = 1
	a.Size = Vector3.one
	a.CFrame = CFrame.new(at)
	a.Parent = Workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(22, 7)
	gui.LightInfluence = 0
	gui.MaxDistance = 220
	gui.Parent = a
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = "CRUSH!"
	l.Parent = gui
	Style.text(l, 5)
	l.TextColor3 = Color3.fromRGB(255, 214, 80)
	TweenService:Create(a, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = CFrame.new(at + Vector3.new(0, 8, 0)) }):Play()
	TweenService:Create(l, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	Debris:AddItem(a, 1.3)
end

local shakeUntil, shakeStrength = 0, 0
local function shake(distance: number)
	shakeStrength = math.clamp(1.2 - distance / 90, 0, 1) * 0.9
	shakeUntil = os.clock() + 0.35
end

RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for _, press in CollectionService:GetTagged("MegaCrusher") do
		if not press:IsA("Model") then
			continue
		end
		local r = rig(press)
		if not r then
			continue
		end
		local period = (press:GetAttribute("Period") :: number?) or 6
		local rest = press:GetAttribute("RestY") :: number
		local hit = press:GetAttribute("HitY") :: number
		local bedTop = press:GetAttribute("BedTop") :: number
		local cycle = now / period
		local t = cycle % 1
		-- 0..0.55 rise slowly, hold until 0.86, slam to 0.9, stay down to 1
		local f: number
		if t < 0.55 then
			f = 1 - t / 0.55
			f = f * f
		elseif t < 0.86 then
			f = 0
		elseif t < 0.9 then
			f = (t - 0.86) / 0.04
		else
			f = 1
		end
		local y = rest + (hit - rest) * f
		r.ram.CFrame = CFrame.new(r.ram.Position.X, y, r.ram.Position.Z) * r.ram.CFrame.Rotation
		-- toys: squashed while the ram is down, bounce back as it lifts off
		local k: number
		if t >= 0.9 then
			k = 0.3
		elseif t < 0.12 then
			local s = t / 0.12
			k = 0.3 + 0.7 * (1 + math.sin(s * math.pi) * 0.12) * s
		elseif t >= 0.86 then
			k = 1 - 0.7 * ((t - 0.86) / 0.04)
		else
			k = 1
		end
		for _, toy in r.toys do
			local centre = toy.cf.Position
			local cy = bedTop + (centre.Y - bedTop) * k
			toy.part.Size = Vector3.new(toy.size.X * (1 + (1 - k) * 0.25), toy.size.Y * k, toy.size.Z * (1 + (1 - k) * 0.25))
			toy.part.CFrame = CFrame.new(centre.X, cy, centre.Z) * toy.cf.Rotation
		end
		local n = math.floor(cycle)
		if t >= 0.9 and r.lastHit ~= n then
			r.lastHit = n
			local cam = Workspace.CurrentCamera.CFrame.Position
			local base = Vector3.new(r.ram.Position.X, bedTop + 2, r.ram.Position.Z)
			local dist = (cam - base).Magnitude
			if dist < 260 then
				burst(base)
				pop(base + Vector3.new(0, 30, 0))
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and (root.Position - base).Magnitude < 100 then
				shake((root.Position - base).Magnitude)
			end
		end
	end
	-- screen shake through the humanoid's camera offset
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if os.clock() < shakeUntil then
			local s = shakeStrength * (shakeUntil - os.clock()) / 0.35
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
		elseif humanoid.CameraOffset ~= Vector3.zero and shakeStrength > 0 then
			humanoid.CameraOffset = Vector3.zero
			shakeStrength = 0
		end
	end
end)
