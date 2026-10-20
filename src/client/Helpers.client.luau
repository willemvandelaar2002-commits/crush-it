--!strict
-- Animates the Mini Presses (server/Helpers.luau): every Period seconds the
-- ram (tag "HelperRam") slams down onto the object, which squashes, sparks
-- fly and (for your own helpers) a small "+$X" floats up; then the ram rises
-- slowly and the object pops back. All local, synced to the server clock.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Format = require(ReplicatedStorage.Shared.Format)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer

type Ram = { part: BasePart, object: BasePart?, objSize: Vector3, lastHit: number }
local rams: { [BasePart]: Ram } = {}

local function add(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	local model = p.Parent
	local obj = model and model:FindFirstChild("Object") :: BasePart?
	rams[p] = { part = p, object = obj, objSize = if obj then obj.Size else Vector3.one, lastHit = -1 }
end
for _, p in CollectionService:GetTagged("HelperRam") do
	add(p)
end
CollectionService:GetInstanceAddedSignal("HelperRam"):Connect(add)
CollectionService:GetInstanceRemovedSignal("HelperRam"):Connect(function(p)
	rams[p :: BasePart] = nil
end)

local function pop(at: Vector3, text: string)
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.Transparency = 1
	a.Size = Vector3.one
	a.CFrame = CFrame.new(at)
	a.Parent = Workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 1.8)
	gui.LightInfluence = 0
	gui.MaxDistance = 70
	gui.Parent = a
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = text
	l.Parent = gui
	Style.text(l, 3)
	l.TextColor3 = Color3.fromRGB(150, 255, 110)
	TweenService:Create(a, TweenInfo.new(1, Enum.EasingStyle.Quad), { CFrame = CFrame.new(at + Vector3.new(0, 4, 0)) }):Play()
	TweenService:Create(l, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	Debris:AddItem(a, 1.1)
end

local function sparks(at: Vector3)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = Workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Lifetime = NumberRange.new(0.25, 0.45)
	e.Size = NumberSequence.new(0.35, 0)
	e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 120, 40))
	e.LightEmission = 1
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Enabled = false
	e.Parent = a
	e:Emit(14)
	Debris:AddItem(a, 1)
end

RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for p, r in rams do
		if not p.Parent then
			rams[p] = nil
			continue
		end
		local period = (p:GetAttribute("Period") :: number?) or 3
		local rest = p:GetAttribute("RestY") :: number
		local hit = p:GetAttribute("HitY") :: number
		local cycle = now / period
		local t = cycle % 1
		-- 0..0.82: rise slowly / hold; 0.82..0.9: slam down; 0.9..1: stay down
		local f: number
		if t < 0.82 then
			f = 1 - math.clamp(t / 0.5, 0, 1) -- back up in the first half
		elseif t < 0.9 then
			f = (t - 0.82) / 0.08
		else
			f = 1
		end
		local y = rest + (hit - rest) * f
		p.CFrame = CFrame.new(p.Position.X, y, p.Position.Z) * (p.CFrame - p.CFrame.Position)
		local obj = r.object
		if obj and obj.Parent then
			local squash = if t >= 0.88 then 0.35 elseif t < 0.15 then 0.35 + 0.65 * (t / 0.15) else 1
			local h = r.objSize.Y * squash
			obj.Size = Vector3.new(r.objSize.X * (1 + (1 - squash) * 0.3), h, r.objSize.Z * (1 + (1 - squash) * 0.3))
			local bottom = hit - 0.45 - r.objSize.Y
			obj.CFrame = CFrame.new(obj.Position.X, bottom + h / 2, obj.Position.Z)
		end
		local n = math.floor(cycle)
		if t >= 0.88 and r.lastHit ~= n then
			r.lastHit = n
			local camPos = Workspace.CurrentCamera.CFrame.Position
			if (camPos - p.Position).Magnitude < 120 then
				sparks(Vector3.new(p.Position.X, hit - 0.4, p.Position.Z))
				if p:GetAttribute("Owner") == player.UserId then
					pop(p.Position + Vector3.new(0, 3, 0), "+" .. Format.cash((p:GetAttribute("Value") :: number?) or 0))
				end
			end
		end
	end
end)
