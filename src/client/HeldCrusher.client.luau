--!strict
-- 8 Nov (Willem: "the crushers in your hand bigger and working, so you can kinda show
-- it in your hand"): every crusher anyone holds works in their hands, on every client.
-- server/CrusherTools welds the held copy with a Weld "HoldWeld" (main part -> body) and,
-- for press crushers, a Weld "RamWeld" (ram -> main part) plus the model attribute Travel.
-- Here, every C.Hold.Stroke seconds: the ram slams down to the bed and rises again (or
-- the whole crusher thumps by C.Hold.Pump), with a small burst of sparks on the hit.
-- Visual only; changing a weld here never reaches the server.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local C = require(RS.Shared.CrusherConfig)
local Style = require(RS.Shared.Kit.Style)

type Rig = { model: Model, hold: Weld?, ram: Weld?, holdC0: CFrame, ramC0: CFrame, travel: number, offset: number, lastHit: number, spark: ParticleEmitter? }
local rigs: { [Model]: Rig } = {}

local function rarityColor(model: Model): Color3
	local tool = model.Parent
	local tip = tool and tool:IsA("Tool") and tool.ToolTip or ""
	for _, r in C.Rarities do
		if string.find(tip, r.name, 1, true) then return r.color end
	end
	return Color3.fromRGB(255, 210, 90)
end

local function add(model: Model)
	if rigs[model] then return end
	local ram = model:FindFirstChild("RamWeld", true) :: Weld?
	local hold = model:FindFirstChild("HoldWeld", true) :: Weld?
	if not hold then return end
	local spark: ParticleEmitter? = nil
	local at = (ram and ram.Part0) or hold.Part1
	if at then
		local a = Instance.new("Attachment")
		a.Name = "HeldSparks"
		a.Position = Vector3.new(0, (at :: BasePart).Size.Y / 2, 0)
		a.Parent = at
		local color = rarityColor(model)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0 e.Lifetime = NumberRange.new(0.25, 0.45) e.Speed = NumberRange.new(5, 10)
		e.SpreadAngle = Vector2.new(70, 70) e.Acceleration = Vector3.new(0, -25, 0)
		e.Size = NumberSequence.new(0.22, 0) e.LightEmission = 1
		e.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
		e.Parent = a
		spark = e
	end
	rigs[model] = { model = model, hold = hold, ram = ram, holdC0 = hold.C0, ramC0 = if ram then ram.C0 else CFrame.identity,
		travel = tonumber(model:GetAttribute("Travel")) or 0, offset = math.random() * C.Hold.Stroke, lastHit = 0, spark = spark }
end

-- watch every character's tools for a "Held" model
local function watchCharacter(char: Model)
	local function check(child: Instance)
		if child:IsA("Tool") then
			local function try()
				local held = child:FindFirstChild("Held")
				if held and held:IsA("Model") then task.delay(0.1, add, held) end
			end
			child.ChildAdded:Connect(function(c) if c.Name == "Held" then try() end end)
			try()
		end
	end
	char.ChildAdded:Connect(check)
	for _, c in char:GetChildren() do check(c) end
end
local function watchPlayer(p: Player)
	p.CharacterAdded:Connect(watchCharacter)
	if p.Character then watchCharacter(p.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in Players:GetPlayers() do watchPlayer(p) end

-- stroke shape: 0 = up, 1 = down (on the bed)
local function stroke(t: number): number
	if t < 0.16 then local k = t / 0.16 return k * k end -- slam (speeds up)
	if t < 0.3 then return 1 end -- squash
	if t < 0.75 then local k = (t - 0.3) / 0.45 return 1 - k * (2 - k) end -- rise (slows down)
	return 0
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for model, r in rigs do
		if not model.Parent or not (r.hold and r.hold.Parent) then rigs[model] = nil continue end
		local t = ((now + r.offset) % C.Hold.Stroke) / C.Hold.Stroke
		local f = stroke(t)
		if r.ram and r.ram.Parent and r.travel > 0 then
			r.ram.C0 = r.ramC0 * CFrame.new(0, -r.travel * f, 0)
			-- the hit makes the whole crusher kick a little too
			local kick = if t >= 0.16 and t < 0.3 then (1 - (t - 0.16) / 0.14) * C.Hold.Pump * 0.5 else 0
			r.hold.C0 = r.holdC0 * CFrame.new(0, -kick, 0)
		else
			r.hold.C0 = r.holdC0 * CFrame.new(0, -C.Hold.Pump * f, 0) * CFrame.Angles(math.rad(-4 * f), 0, 0)
		end
		-- sparks once per hit
		if t >= 0.16 and now - r.lastHit > C.Hold.Stroke * 0.5 then
			r.lastHit = now
			if r.spark and r.spark.Parent then r.spark:Emit(if Style.lite() then 4 else 10) end
		end
	end
end)
