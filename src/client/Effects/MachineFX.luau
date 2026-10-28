--!nonstrict
-- From Willem's machine-effects pack (28 Oct 2026); only MAX_PREVIEW_PARTS changed.
-- Client-only cosmetic add-on. Does not grant, consume, recolour or move owned crushers.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sequence = require(script.Parent.MachineFXSequence)
local FX = {}
local jobs = {}
local connection = nil
local MAX_ACTIVE = 2
-- Crush It: raised from the pack's 48. The game's preview models reach ~70
-- parts and coatings add dressing; 48 cut real crushers in half.
local MAX_PREVIEW_PARTS = 120
local NAVY = Color3.fromRGB(19, 23, 42)
local WHITE = Color3.fromRGB(255, 249, 225)
local PURPLE = Color3.fromRGB(176, 91, 255)
local CYAN = Color3.fromRGB(86, 240, 255)
local TAU = math.pi * 2
local serial = 0

local function part(parent, name, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.one * 0.1
	p.Transparency = 1
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function prefab(name, parent, color)
	local folder = ReplicatedStorage:FindFirstChild("MachineFXMeshes")
	local source = folder and folder:FindFirstChild(name)
	if not source or not source:IsA("MeshPart") then return nil end
	local p = source:Clone()
	p:ClearAllChildren()
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color, p.Transparency = color, 1
	p.Parent = parent
	return p
end

-- Safe visual snapshot: copies appearance, strips scripts, constraints, emitters and lights.
-- Caller owns returned unparented Model and should Destroy it after starting the effect.
function FX.captureModel(source)
	if not source or not (source:IsA("Model") or source:IsA("BasePart")) then return nil end
	local model = Instance.new("Model")
	model.Name = "MachineFXSnapshot"
	local candidates = source:IsA("BasePart") and { source } or source:GetDescendants()
	local count = 0
	for _, original in candidates do
		if count >= MAX_PREVIEW_PARTS then break end
		if original:IsA("BasePart") and original.Transparency < 0.98 then
			local ok, p = pcall(function() return original:Clone() end)
			if ok and p then
				for _, child in p:GetChildren() do
					if not (child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance")
						or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy()
					else
						for _, descendant in child:GetDescendants() do descendant:Destroy() end
					end
				end
				p.Anchored = true
				p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
				p.LocalTransparencyModifier = 0
				p.CastShadow = false
				p.Parent = model
				count += 1
			end
		end
	end
	if count == 0 then model:Destroy(); return nil end
	local box = model:GetBoundingBox()
	model:PivotTo(CFrame.new(-box.Position) * model:GetPivot())
	return model
end

local function fallbackPreview(parent, color)
	local m = Instance.new("Model")
	m.Name = "MissingPreview_StandIn"
	local function block(name, pos, size, c)
		local p = part(m, name, c)
		p.Material = Enum.Material.SmoothPlastic
		p.Size, p.CFrame, p.Transparency = size, CFrame.new(pos), 0
	end
	block("Base", Vector3.new(0, -0.55, 0), Vector3.new(1.4, 0.22, 1.15), NAVY)
	for _, x in { -0.5, 0.5 } do
		block("Post", Vector3.new(x, 0, 0.25), Vector3.new(0.18, 1.1, 0.18), color)
	end
	block("Top", Vector3.new(0, 0.55, 0.2), Vector3.new(1.4, 0.3, 0.7), color)
	block("Ram", Vector3.new(0, 0, 0), Vector3.new(0.7, 0.3, 0.65), WHITE)
	m.Parent = parent
	return m
end

local function preview(source, parent, color, size)
	local model = FX.captureModel(source) or fallbackPreview(parent, color)
	model.Parent = parent
	local _, bounds = model:GetBoundingBox()
	local targetScale = size / math.max(bounds.X, bounds.Y, bounds.Z, 0.01)
	model:ScaleTo(model:GetScale() * targetScale)
	local initialScale = model:GetScale()
	local parts = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then table.insert(parts, { p, p.Transparency }) end
	end
	return { model = model, scale = initialScale, parts = parts, lastScale = 1 }
end

local function posePreview(p, cf, scale, alpha)
	if math.abs(p.lastScale - scale) > 0.003 then
		p.model:ScaleTo(p.scale * math.max(scale, 0.01)); p.lastScale = scale
	end
	p.model:PivotTo(cf)
	for _, item in p.parts do item[1].Transparency = 1 - (1 - item[2]) * alpha end
end

local function makeRing(parent, color)
	local mesh = prefab("FXRing", parent, color)
	if mesh then return { mesh = mesh, color = color } end
	local segments = {}
	for i = 1, 24 do table.insert(segments, part(parent, "RingSegment_" .. i, color)) end
	return { segments = segments, color = color }
end

local function poseRing(ring, cf, radius, thickness, alpha, color)
	color = color or ring.color
	if ring.mesh then
		ring.mesh.Size = Vector3.new(radius * 2, thickness, radius * 2)
		ring.mesh.CFrame, ring.mesh.Transparency, ring.mesh.Color = cf, 1 - alpha, color
	else
		for i, p in ring.segments do
			local a = i / #ring.segments * TAU
			p.Size = Vector3.new(2 * radius * math.tan(math.pi / #ring.segments) * 1.015, thickness, thickness)
			p.CFrame = cf * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, radius)
			p.Transparency, p.Color = 1 - alpha, color
		end
	end
end

local function line(p, origin, a, b, width, alpha)
	local delta = b - a
	p.Size = Vector3.new(width, width, math.max(delta.Magnitude, 0.01))
	if delta.Magnitude > 0.0001 then p.CFrame = origin * CFrame.lookAt((a + b) / 2, b) end
	p.Transparency = 1 - alpha
end

local function destroyJob(job, completed)
	if job.done then return end
	job.done = true
	jobs[job.id] = nil
	job.root:Destroy()
	if job.onFinished then
		task.defer(function()
			local ok, err = pcall(job.onFinished, completed)
			if not ok then warn("MachineFX onFinished:", err) end
		end)
	end
end

local function tickJob(job, dt)
	if (job.started and not job.root.Parent) or (job.owner and not job.owner.Parent) then destroyJob(job, false); return end
	job.elapsed += dt
	local s = Sequence.sample(job.kind, job.elapsed / job.duration)
	local origin = job.origin
	local scale = job.scale
	local function at(x, y, z) return origin * CFrame.new(x * scale, y * scale, z * scale) end
	local function vec(x, y, z) return Vector3.new(x, y, z) * scale end
	local fusion = job.kind == "Fusion"
	local color = job.color
	poseRing(job.rings[1], at(0, 0.12, 0) * CFrame.Angles(0, s.angle, 0), (fusion and 3.05 or 2.25) * scale, 0.11 * scale, s.ring * 0.65)
	poseRing(job.rings[2], at(0, fusion and 2.2 or s.scanHeight, 0) * CFrame.Angles(fusion and 0.34 or 0, -s.angle, fusion and 0.2 or 0),
		(fusion and (1.7 * (1 - s.gather) + 0.5) or 1.48) * scale, 0.08 * scale, (fusion and s.charge or s.spray) * 0.85)
	poseRing(job.rings[3], at(0, 0.16 + s.burst * 0.22, 0), (0.35 + s.burst * 3.15) * scale, 0.13 * scale, s.burstAlpha * 0.9, color:Lerp(WHITE, 0.35))
	local outputY = fusion and (1.9 + math.sin(s.reveal * math.pi) * 0.28) or 1.7
	posePreview(job.output, at(0, outputY, 0) * CFrame.Angles(0, fusion and (1 - s.reveal) * 0.8 or math.sin(s.t * TAU) * 0.08, 0),
		s.outputScale, job.before and s.reveal * (1 - s.finish) or s.outputAlpha)
	if job.before then
		posePreview(job.before, at(0, outputY, 0) * CFrame.Angles(0, math.sin(s.t * TAU) * 0.08, 0),
			1, (1 - s.reveal) * (1 - s.finish))
	end
	for i, p in job.inputs do
		local a = s.angle + (i - 1) * math.pi / 2
		local pos = vec(math.cos(a) * s.inputRadius, 1.8 + math.sin(a * 2) * 0.16, math.sin(a) * s.inputRadius)
		posePreview(p, origin * CFrame.new(pos) * CFrame.Angles(0, -a, 0), s.inputScale, s.inputAlpha)
		line(job.links[i], origin, pos, vec(0, 2.0, 0), 0.055 * scale, s.charge * s.inputAlpha * 0.48)
	end
	job.flash.Size = Vector3.one * (0.10 + s.flash * (fusion and 2.0 or 1.15)) * scale
	job.flash.CFrame = at(0, 1.9, 0)
	job.flash.Transparency = 1 - s.flash * 0.60
	for i, p in job.motes do
		local seed = i * 2.399963
		if fusion then
			local inward = (s.t * 2.0 + i / #job.motes) % 1
			local r = 3.1 * (1 - inward)
			local a = seed + s.angle
			p.CFrame = at(math.cos(a) * r, 0.6 + inward * 1.8, math.sin(a) * r) * CFrame.Angles(0, a, a)
			p.Size = Vector3.one * (0.06 + inward * 0.10) * scale
			p.Transparency = 1 - s.charge * math.sin(inward * math.pi) * 0.8
		else
			local u = (s.t * 6 + i / #job.motes) % 1
			local a = (i % 4) * math.pi / 2 + 0.3
			local r = 2.45 - 1.75 * u
			local y = 2.9 + (s.scanHeight - 2.9) * u + math.sin(u * math.pi) * 0.15
			p.CFrame = at(math.cos(a) * r, y + math.sin(seed) * 0.12, math.sin(a) * r)
			p.Size = Vector3.new(0.09, 0.13, 0.09) * scale
			p.Transparency = 1 - s.spray * math.sin(u * math.pi) * 0.85
		end
	end
	for i, p in job.stars do
		local a = i / #job.stars * TAU + 0.2
		local r = 0.35 + s.burst * (1.5 + (i % 3) * 0.35)
		local y = 1.6 + math.sin(a * 3) * s.burst * 0.7 + math.sin(s.burst * math.pi) * 0.7
		local cf = at(math.cos(a) * r, y, math.sin(a) * r)
		local camera = workspace.CurrentCamera
		if camera then cf = CFrame.lookAt(cf.Position, camera.CFrame.Position) * CFrame.Angles(0, 0, a + s.t * 2) end
		p.CFrame = cf
		p.Size = Vector3.new(0.2, 0.2, job.meshStars and 0.035 or 0.10) * scale * (0.5 + s.burstAlpha)
		p.Transparency = 1 - s.burstAlpha * 0.9
	end
	if job.elapsed >= job.duration then destroyJob(job, true) end
end

local function begin(kind, options)
	assert(RunService:IsClient(), "MachineFX must run from a LocalScript")
	options = options or {}
	assert(typeof(options.origin) == "CFrame", "MachineFX needs origin = an upright CFrame at the effect floor")
	if options.owner and not options.owner.Parent then return nil, "InvalidOwner" end
	local active = 0
	for _, j in jobs do
		if options.owner and j.owner == options.owner then destroyJob(j, false)
		else active += 1 end
	end
	-- Hard budget: skip ambient/remote requests rather than interrupt the player's current reveal.
	if active >= MAX_ACTIVE then return nil, "EffectBudget" end
	serial += 1
	local root = Instance.new("Folder")
	root.Name = "LocalMachineFX_" .. serial
	local color = options.color or (kind == "Fusion" and PURPLE or CYAN)
	local scale = math.clamp(options.scale or 1, 0.1, 4)
	local j = { id = serial, kind = kind, root = root, owner = options.owner, origin = options.origin,
		color = color, scale = scale, elapsed = 0, inputs = {}, links = {}, motes = {}, stars = {},
		duration = math.clamp(options.duration or (kind == "Fusion" and Sequence.FusionDuration or Sequence.CoatingDuration), 1, 12),
		onFinished = options.onFinished, done = false }
	-- Assemble unparented: incomplete clones/effects never briefly appear at the world origin.
	local ok, err = pcall(function()
		j.rings = { makeRing(root, color), makeRing(root, WHITE), makeRing(root, color) }
		j.flash = part(root, "ImpactGlow", WHITE, Enum.PartType.Ball)
		j.output = preview(options.result or options.preview, root, color, 2.35 * scale)
		if kind == "Coating" and options.before then
			j.before = preview(options.before, root, color, 2.35 * scale)
		end
		if kind == "Fusion" then
			for i = 1, 4 do
				j.inputs[i] = preview(options.inputs and options.inputs[i], root, i % 2 == 0 and CYAN or PURPLE, 1.25 * scale)
				j.links[i] = part(root, "FusionLink_" .. i, i % 2 == 0 and CYAN or PURPLE)
			end
		end
		for i = 1, kind == "Fusion" and 16 or 28 do
			j.motes[i] = kind == "Coating" and prefab("FXDroplet", root, color) or nil
			j.motes[i] = j.motes[i] or part(root, "Mote_" .. i, i % 3 == 0 and WHITE or color, Enum.PartType.Ball)
		end
		for i = 1, 12 do
			j.stars[i] = prefab("FXSpark", root, i % 3 == 0 and WHITE or color)
			if j.stars[i] then j.meshStars = true end
			j.stars[i] = j.stars[i] or part(root, "Spark_" .. i, i % 3 == 0 and WHITE or color)
		end
		tickJob(j, 0)
	end)
	if not ok then root:Destroy(); warn("MachineFX setup:", err); return nil, "SetupFailed" end
	root.Parent = workspace
	j.started = true
	jobs[j.id] = j
	if not connection then
		connection = RunService.RenderStepped:Connect(function(dt)
			for _, job in jobs do
				local success, message = pcall(tickJob, job, dt)
				if not success then warn("MachineFX playback:", message); destroyJob(job, false) end
			end
			if next(jobs) == nil then connection:Disconnect(); connection = nil end
		end)
	end
	local handle = {}
	function handle:Cancel() destroyJob(j, false) end
	function handle:IsPlaying() return not j.done end
	return handle
end

function FX.playCoating(options) return begin("Coating", options) end
function FX.playFusion(options) return begin("Fusion", options) end
function FX.cancelAll()
	for _, j in jobs do destroyJob(j, false) end
	if connection then connection:Disconnect(); connection = nil end
end

return FX
