--!nocheck
-- From Willem's coating asset pack (26 Oct 2026), unchanged below this line.
-- Cosmetic ModuleScript; no coating eligibility, currency, inventory or remote logic.
-- Run SetupInStudio once, place/scale the machine, then create a controller.
local RunService = game:GetService("RunService")
local CoatingVisuals = {}
CoatingVisuals.__index = CoatingVisuals
local colours = {
	Polished = Color3.fromRGB(255, 207, 80),
	Frost = Color3.fromRGB(48, 230, 243),
	Fire = Color3.fromRGB(255, 108, 63),
	Charged = Color3.fromRGB(190, 112, 255),
}
function CoatingVisuals.new(model: Model)
	local self = setmetatable({model = model, busy = false, destroyed = false, parts = {}, rest = {}, emitters = {}}, CoatingVisuals)
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then self.parts[item.Name] = item; self.rest[item.Name] = item:GetPivot() end
	end
	for _, name in {"Coat_Body", "Coat_Turntable", "Coat_LSprayArm", "Coat_RSprayArm", "Coat_LSprayHead", "Coat_RSprayHead", "Coat_ActivateButton"} do
		assert(self.parts[name], "Missing coating mesh " .. name)
	end
	local attachments = {}
	for _, side in {"L", "R"} do
		local a = self.parts["Coat_" .. side .. "SprayHead"]:FindFirstChild(side .. "Nozzle")
		assert(a and a:IsA("Attachment"), "Run SetupInStudio before creating a controller")
		table.insert(attachments, a)
	end
	-- All prerequisites checked before creating effects.
	for _, a in attachments do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "CoatingMist"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.2, 0.4)
		emitter.Speed = NumberRange.new(2.5, 3.5)
		emitter.SpreadAngle = Vector2.new(10, 10)
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0)})
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
		emitter.LightEmission = 0.4
		emitter.Parent = a
		table.insert(self.emitters, emitter)
	end
	self.scale = self.parts.Coat_Body.Size.X / 14.4
	return self
end
function CoatingVisuals:_restore()
	for name, cf in self.rest do local part = self.parts[name]; if part and part.Parent then part:PivotTo(cf) end end
end
function CoatingVisuals:Play(coating: string)
	if self.destroyed or self.busy or not self.model.Parent then return false end
	local colour = colours[coating]
	if not colour then return false end
	self.busy = true
	for _, emitter in self.emitters do emitter.Color = ColorSequence.new(colour) end
	local elapsed, sprayElapsed = 0, 0
	self.connection = RunService.Heartbeat:Connect(function(dt)
		if not self.model.Parent then self:Destroy(); return end
		elapsed += dt; sprayElapsed += dt
		local t = math.clamp(elapsed / 2.6, 0, 1)
		local envelope = math.sin(math.pi * t)^2
		local sweep = math.sin(t * math.pi * 4) * math.rad(9) * envelope
		for _, side in {"L", "R"} do
			local name = "Coat_" .. side .. "SprayArm"
			local rest = self.rest[name]
			local sign = if side == "L" then 1 else -1
			local motion = CFrame.new(rest.Position) * CFrame.fromAxisAngle(Vector3.yAxis, sweep * sign) * CFrame.new(-rest.Position)
			self.parts[name]:PivotTo(motion * rest)
			local headName = "Coat_" .. side .. "SprayHead"
			self.parts[headName]:PivotTo(motion * self.rest[headName])
		end
		local turn = self.rest.Coat_Turntable
		local rotate = CFrame.new(turn.Position) * CFrame.fromAxisAngle(Vector3.yAxis, math.sin(t * math.pi * 2) * 0.3) * CFrame.new(-turn.Position)
		self.parts.Coat_Turntable:PivotTo(rotate * turn)
		self.parts.Coat_ActivateButton:PivotTo(self.rest.Coat_ActivateButton + Vector3.new(0, -0.06 * envelope * self.scale, 0))
		if t > 0.12 and t < 0.85 and sprayElapsed >= 0.1 then
			sprayElapsed = 0
			for _, emitter in self.emitters do emitter:Emit(2) end
		end
		if t >= 1 then
			self.connection:Disconnect(); self.connection = nil
			self:_restore(); self.busy = false
		end
	end)
	return true
end
function CoatingVisuals:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	if self.connection then self.connection:Disconnect(); self.connection = nil end
	self:_restore()
	for _, emitter in self.emitters do emitter:Destroy() end
	self.busy = false
end
return CoatingVisuals
