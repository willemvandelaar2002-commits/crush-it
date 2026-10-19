--!strict
-- Builds the hydraulic press for a tier. Size follows Config.pressWidth;
-- the look follows Config.Presses (name, paint colour and stage). Every
-- upgrade repaints it, makes it bigger and lights one more level light on
-- the beam; every new stage adds a whole set of parts (see Config.Presses).
--
-- PressBuilder.build(origin, tier) -> { model, ram, bedTop, restBottom }
--   origin: plot floor centre, +Z toward the walkway (the front)
--   ram:    the anchored plate the game tweens up and down; every moving
--           part (rods, trims, glow ring) is welded to it
--   Spinning bits are Models tagged "PressSpin" (attribute Speed, rad/s);
--   the client turns them (Main.client.luau).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local PressBuilder = {}

local BED_HEIGHT = 2
local C = Color3.fromRGB
local M = Enum.Material

local CHROME = C(215, 220, 228)
local BLACK = C(28, 28, 32)
local GOLD = C(255, 196, 60)

type Style = {
	frame: Color3, frameMat: Enum.Material,
	trim: Color3, trimMat: Enum.Material,
	bed: Color3, bedMat: Enum.Material,
	ram: Color3, ramMat: Enum.Material,
	rod: Color3,
	neon: Color3?,
}

local function styleFor(tier: number): (Style, number)
	local p = Config.Presses[tier]
	local a = p.accent
	local stage = p.stage
	if stage == 1 then
		return { frame = a:Lerp(C(90, 85, 80), 0.45), frameMat = M.CorrodedMetal, trim = C(60, 55, 50), trimMat = M.CorrodedMetal,
			bed = C(125, 90, 58), bedMat = M.WoodPlanks, ram = C(85, 82, 80), ramMat = M.CorrodedMetal, rod = C(165, 165, 165) }, stage
	elseif stage == 2 then
		return { frame = a, frameMat = M.SmoothPlastic, trim = BLACK, trimMat = M.Metal,
			bed = C(70, 74, 82), bedMat = M.DiamondPlate, ram = C(60, 64, 72), ramMat = M.Metal, rod = CHROME }, stage
	elseif stage == 3 then
		return { frame = a, frameMat = M.Metal, trim = C(50, 52, 58), trimMat = M.Metal,
			bed = C(64, 68, 76), bedMat = M.DiamondPlate, ram = C(48, 50, 56), ramMat = M.Metal, rod = CHROME }, stage
	elseif stage == 4 then
		return { frame = C(38, 42, 54), frameMat = M.Metal, trim = C(22, 24, 32), trimMat = M.Metal,
			bed = C(30, 32, 42), bedMat = M.DiamondPlate, ram = C(34, 37, 48), ramMat = M.Metal, rod = C(200, 225, 245), neon = a }, stage
	end
	return { frame = C(24, 22, 30), frameMat = M.Metal, trim = GOLD, trimMat = M.Metal,
		bed = C(20, 18, 26), bedMat = M.DiamondPlate, ram = C(30, 26, 36), ramMat = M.Metal, rod = GOLD, neon = a }, stage
end

-- Part helpers ---------------------------------------------------------------

local function new(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.Parent = parent
	return p
end

-- Cylinder standing up (Y axis), `cf` = its centre.
local function vcyl(parent: Instance, name: string, height: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = new(parent, name, Vector3.new(height, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Cylinder lying along Z (a disc facing the front when thin).
local function zcyl(parent: Instance, name: string, length: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = new(parent, name, Vector3.new(length, d, d), cf * CFrame.Angles(0, math.pi / 2, 0), color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Cylinder lying along X.
local function xcyl(parent: Instance, name: string, length: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = new(parent, name, Vector3.new(length, d, d), cf, color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(parent: Instance, name: string, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = new(parent, name, Vector3.new(d, d, d), cf, color, mat)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Welds a part to the ram so it moves with it.
local function onRam(ram: BasePart, p: BasePart)
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = ram
	w.Part1 = p
	w.Parent = p
end

local function light(p: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = math.min(range, 60)
	l.Brightness = brightness or 2
	l.Parent = p
end

-- Black/colour hazard bands down a block's front face.
local function hazardBands(parent: Instance, cf: CFrame, width: number, height: number, depth: number, color: Color3)
	local band = math.max(0.6, height / 12)
	local n = math.floor(height / (band * 2))
	for i = 0, n - 1 do
		local y = -height / 2 + band * (2 * i + 1.5)
		new(parent, "Hazard", Vector3.new(width + 0.08, band, depth + 0.08), cf * CFrame.new(0, y, 0), color, M.SmoothPlastic)
	end
end

-- A ring of small blocks (a "hoop") as a Model the client can spin.
local function hoop(parent: Instance, centre: CFrame, radius: number, thickness: number, color: Color3, speed: number, tilt: CFrame?): Model
	local m = Instance.new("Model")
	m.Name = "Hoop"
	local count = 16
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local seg = 2 * math.pi * radius / count * 1.05
		local cf = centre * (tilt or CFrame.identity) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, radius)
		local p = new(m, "Seg", Vector3.new(seg, thickness, thickness), cf, color, M.Neon)
		p.CanCollide = false
	end
	m:SetAttribute("Speed", speed)
	CollectionService:AddTag(m, "PressSpin")
	m.Parent = parent
	return m
end

-- Build ----------------------------------------------------------------------

export type Built = { model: Model, ram: BasePart, bedTop: number, restBottom: number }

function PressBuilder.build(o: CFrame, tier: number): Built
	local press = Instance.new("Model")
	press.Name = "Press"
	local st, stage = styleFor(tier)
	local info = Config.Presses[tier]
	local accent = info.accent
	local def = Config.Objects[tier]

	local W = Config.pressWidth(tier)
	local s = W / 10 -- detail scale
	local clearance = def.height + math.max(2, W * 0.15)
	local pillarW = math.max(1.6, W * 0.13)
	local pillarH = BED_HEIGHT + clearance + W * 0.35 + 3
	local px = W / 2 + pillarW / 2 + 0.3
	local beamH = math.max(2, W * 0.18)
	local beamD = pillarW * 1.6
	local beamW = W + pillarW * 2 + 0.6
	local plateH = math.max(1, W * 0.1)
	local floorY = o.Position.Y
	local bedTop = floorY + BED_HEIGHT
	local restBottom = bedTop + clearance
	local beamTopLocal = pillarH + beamH
	local housingH = clearance + 1
	local housingD = W * 0.34
	local at = function(x: number, y: number, z: number): CFrame
		return o * CFrame.new(x, y, z)
	end

	-- A mesh frame for this stage (ServerStorage.PressMeshes.Stage<n>, saved in the
	-- place file) replaces the code-built pillars, beam and extras.
	local meshFolder = game:GetService("ServerStorage"):FindFirstChild("PressMeshes")
	local frameMesh = meshFolder and meshFolder:FindFirstChild("Stage" .. stage)
	if frameMesh and not frameMesh:IsA("Model") then
		frameMesh = nil
	end

	-- Base and bed
	local plinth = new(press, "Plinth", Vector3.new(beamW + 1.6, 0.6, math.max(W, beamD) + 1.6), at(0, 0.3, 0), st.trim, M.SmoothPlastic)
	Style.studs(plinth)
	local bed = new(press, "Bed", Vector3.new(W, BED_HEIGHT, W), at(0, BED_HEIGHT / 2, 0), st.bed, st.bedMat)
	bed:SetAttribute("Keep", true)
	if stage >= 2 then
		-- hazard edge along the front of the bed
		local n = math.max(3, math.floor(W / 1.2))
		for i = 0, n - 1 do
			local x = -W / 2 + (i + 0.5) * (W / n)
			new(press, "BedStripe", Vector3.new(W / n, 0.35, 0.5), at(x, BED_HEIGHT - 0.12, W / 2 - 0.2),
				if i % 2 == 0 then C(245, 190, 40) else BLACK, M.SmoothPlastic)
		end
	end
	if st.neon then
		-- underglow round the bed
		for _, z in { -1, 1 } do
			new(press, "Glow", Vector3.new(W + 0.1, 0.25, 0.25), at(0, 0.75, z * (W / 2 + 0.05)), st.neon, M.Neon)
			new(press, "Glow", Vector3.new(0.25, 0.25, W + 0.1), at(z * (W / 2 + 0.05), 0.75, 0), st.neon, M.Neon)
		end
	end

	if not frameMesh then
		-- Pillars
		for _, side in { -1, 1 } do
			local x = side * px
			local mid = at(x, pillarH / 2, 0)
			if stage == 3 then
				-- I-beam: web + two flanges
				new(press, "Pillar", Vector3.new(pillarW * 0.4, pillarH, pillarW), mid, st.frame, st.frameMat)
				for _, z in { -1, 1 } do
					new(press, "Flange", Vector3.new(pillarW * 1.15, pillarH, pillarW * 0.22), mid * CFrame.new(0, 0, z * pillarW * 0.45), st.frame, st.frameMat)
				end
				-- rivet rows
				for i = 1, math.floor(pillarH / 3) do
					for _, rx in { -0.35, 0.35 } do
						zcyl(press, "Rivet", 0.2, 0.35 * math.max(1, s * 0.6), mid * CFrame.new(rx * pillarW, -pillarH / 2 + i * 3, pillarW * 0.57), st.trim, M.Metal)
					end
				end
			else
				new(press, "Pillar", Vector3.new(pillarW, pillarH, pillarW), mid, st.frame, st.frameMat)
			end
			if stage == 2 then
				hazardBands(press, mid, pillarW, pillarH * 0.85, pillarW, BLACK)
			end
			if st.neon then
				for _, cx in { -1, 1 } do
					for _, cz in { -1, 1 } do
						new(press, "Edge", Vector3.new(0.22, pillarH * 0.92, 0.22), mid * CFrame.new(cx * pillarW / 2, 0, cz * pillarW / 2), st.neon, M.Neon)
					end
				end
			end
			-- foot and cap
			new(press, "Foot", Vector3.new(pillarW * 1.5, 1, pillarW * 1.5), at(x, 0.5, 0), st.trim, st.trimMat)
			new(press, "Cap", Vector3.new(pillarW * 1.25, 0.5, pillarW * 1.25), at(x, pillarH - 0.25, 0), st.trim, st.trimMat)
			if stage == 1 then
				for _, by in { 1.6, pillarH - 1.2 } do
					for _, bx in { -0.3, 0.3 } do
						zcyl(press, "Bolt", 0.25, 0.4, at(x + bx * pillarW, by, pillarW / 2 + 0.1), C(70, 65, 60), M.Metal)
					end
				end
			end
			if stage == 4 then
				-- energy cell at the foot
				local cell = at(x + side * (pillarW * 0.9 + 0.6 * s), 1 + 1.6 * s, pillarW * 0.3)
				vcyl(press, "CellGlass", 3.2 * s, 1.4 * s, cell, C(180, 230, 255), M.Glass).Transparency = 0.5
				local core = vcyl(press, "CellCore", 2.6 * s, 0.6 * s, cell, accent, M.Neon)
				light(core, accent, 8 * s)
				vcyl(press, "CellCap", 0.4 * s, 1.6 * s, cell * CFrame.new(0, 1.7 * s, 0), st.trim, M.Metal)
			end
		end

		-- Beam
		local beamCf = at(0, pillarH + beamH / 2, 0)
		local beam = new(press, "Beam", Vector3.new(beamW, beamH, beamD), beamCf, st.frame, st.frameMat)
		if stage >= 3 then
			for _, y in { -1, 1 } do
				new(press, "BeamTrim", Vector3.new(beamW + 0.3, 0.35 * math.max(1, s * 0.5), beamD + 0.3), beamCf * CFrame.new(0, y * beamH / 2, 0), st.trim, st.trimMat)
			end
		end
		if stage == 2 then
			hazardBands(press, beamCf * CFrame.Angles(0, 0, math.pi / 2), beamH, beamW * 0.9, beamD, BLACK)
		end
		if st.neon then
			new(press, "BeamGlow", Vector3.new(beamW * 0.95, 0.25, 0.25), beamCf * CFrame.new(0, -beamH / 2 + 0.2, beamD / 2 + 0.05), st.neon, M.Neon)
		end

		-- Name plate on the beam front
		local plateW = math.min(beamW * 0.62, 6 + W * 0.5)
		local plateHt = beamH * 0.5
		local plateCf = beamCf * CFrame.new(0, beamH * 0.08, beamD / 2 + 0.06)
		local namePlate = new(press, "NamePlate", Vector3.new(plateW, plateHt, 0.12), plateCf,
			if stage == 1 then C(150, 110, 70) elseif stage >= 4 then C(15, 15, 22) else BLACK, if stage == 1 then M.Wood else M.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = if stage >= 4 then 0 else 1
		gui.Parent = namePlate
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = string.upper(info.name)
		label.TextColor3 = if stage == 1 then C(60, 35, 20) elseif stage >= 4 then accent else C(250, 250, 250)
		label.Parent = gui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.15, 0)
		pad.PaddingBottom = UDim.new(0.15, 0)
		pad.PaddingLeft = UDim.new(0.05, 0)
		pad.PaddingRight = UDim.new(0.05, 0)
		pad.Parent = label

		-- Level lights: one per press tier, the ones you've reached lit.
		local lights = Config.MaxTier
		local spacing = math.min(1.1 * math.max(1, s * 0.7), (beamW * 0.9) / lights)
		local lightY = -beamH / 2 + beamH * 0.16
		for i = 1, lights do
			local x = (i - (lights + 1) / 2) * spacing
			local lit = i <= tier
			zcyl(press, "LevelLight", 0.15, spacing * 0.55, beamCf * CFrame.new(x, lightY, beamD / 2 + 0.06),
				if lit then accent else C(45, 45, 50), if lit then M.Neon else M.SmoothPlastic)
		end

		-- Main hydraulic cylinder on top of the beam
		local housingCf = at(0, beamTopLocal + housingH / 2, 0)
		if stage == 1 then
			vcyl(press, "Housing", housingH, housingD, housingCf, C(80, 80, 85), M.CorrodedMetal)
			-- hand wheel on the side
			local wheelCf = housingCf * CFrame.new(housingD / 2 + 0.4, housingH * 0.2, 0)
			xcyl(press, "Wheel", 0.3, housingD * 1.1, wheelCf, C(140, 40, 35), M.Metal)
			xcyl(press, "Hub", 0.7, housingD * 0.25, wheelCf, C(60, 55, 50), M.Metal)
		else
			vcyl(press, "Housing", housingH, housingD, housingCf, st.trim, M.Metal)
			local bands = math.max(2, math.floor(housingH / 3))
			for i = 1, bands do
				vcyl(press, "Band", 0.35 * math.max(1, s * 0.5), housingD * 1.08,
					housingCf * CFrame.new(0, -housingH / 2 + i * housingH / (bands + 1), 0), if st.neon then st.neon else st.frame, if st.neon then M.Neon else st.frameMat)
			end
			vcyl(press, "Top", 0.6 * math.max(1, s * 0.5), housingD * 1.15, housingCf * CFrame.new(0, housingH / 2, 0), st.trim, M.Metal)
		end

	end

	-- Mesh frame: stretched to the press size. Tall enough that the hanging
	-- cylinder (below) fits inside its top beam over the whole stroke.
	local ramTopRest = restBottom + plateH
	local sleeveTop = ramTopRest + clearance + 1.5
	if frameMesh then
		local frame = (frameMesh :: Model):Clone()
		frame.Name = "Frame"
		local cf, size = frame:GetBoundingBox()
		local yawDeg = (frameMesh:GetAttribute("Yaw") :: number?) or 0
		local turned = math.abs(yawDeg) % 180 == 90
		local srcW = if turned then size.Z else size.X
		local srcD = if turned then size.X else size.Z
		-- Uniform scale (no stretching): wide enough for the bed, tall enough that
		-- the cylinder/rod stays inside the frame over the whole stroke.
		local fitW = (W * 1.55) / srcW
		local fitH = (sleeveTop - floorY) / size.Y
		local k = math.max(fitW, fitH)
		local sx, sy, sz = k, k, k
		local _ = srcD
		local bottom = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
		local yaw = CFrame.Angles(0, math.rad(yawDeg), 0)
		local scaleV = if turned then Vector3.new(sz, sy, sx) else Vector3.new(sx, sy, sz)
		for _, d in frame:GetDescendants() do
			if d:IsA("BasePart") then
				local rel = bottom:ToObjectSpace(d.CFrame)
				local pos = rel.Position * scaleV
				local rot = rel - rel.Position
				-- scale the part along its own axes by the matching world scale
				local localScale = rot:VectorToObjectSpace(scaleV)
				d.Size = d.Size * Vector3.new(math.abs(localScale.X), math.abs(localScale.Y), math.abs(localScale.Z))
				d.CFrame = o * CFrame.new(0, 0.6, 0) * yaw * CFrame.new(pos) * rot
				d.Anchored = true
				d.CanCollide = true
			elseif d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		frame.Parent = press
		-- the cylinder hanging from the top beam (the rod slides inside it)
		local sleeveD = W * 0.3
		local sleeveLen = sleeveTop - (ramTopRest + 0.3)
		vcyl(press, "Sleeve", sleeveLen, sleeveD, CFrame.new(o.Position.X, ramTopRest + 0.3 + sleeveLen / 2, o.Position.Z) * (o - o.Position), st.trim, M.Metal)
		vcyl(press, "SleeveRing", 0.5 * math.max(1, s * 0.5), sleeveD * 1.12, CFrame.new(o.Position.X, ramTopRest + 0.55, o.Position.Z) * (o - o.Position), accent, if st.neon then M.Neon else M.Metal)
		-- accent glow round the plinth: every tier has its own colour
		for _, z in { -1, 1 } do
			new(press, "Glow", Vector3.new(beamW + 1.7, 0.3, 0.3), at(0, 0.45, z * ((math.max(W, beamD) + 1.6) / 2 + 0.05)), accent, M.Neon)
		end
		-- sign in front: press name + level lights
		local signW = math.clamp(W * 0.6, 5, 12)
		local signH = signW * 0.32
		local signCf = at(-(W / 2 + 1), 0, W / 2 + 2.2)
		for _, sx2 in { -0.4, 0.4 } do
			new(press, "SignPost", Vector3.new(0.3, 2.2, 0.3), signCf * CFrame.new(sx2 * signW, 1.1, 0), st.trim, M.Metal)
		end
		local board = new(press, "NamePlate", Vector3.new(signW, signH, 0.25), signCf * CFrame.new(0, 2.2 + signH / 2, 0), C(20, 20, 26), M.SmoothPlastic)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Back
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.Parent = board
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 0.62)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.Text = string.upper(info.name)
		title.TextColor3 = accent
		title.Parent = sg
		local lightsRow = Instance.new("Frame")
		lightsRow.Position = UDim2.fromScale(0.05, 0.66)
		lightsRow.Size = UDim2.fromScale(0.9, 0.24)
		lightsRow.BackgroundTransparency = 1
		lightsRow.Parent = sg
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0.012, 0)
		layout.Parent = lightsRow
		for i = 1, Config.MaxTier do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0.06, 0, 1, 0)
			dot.BackgroundColor3 = if i <= tier then accent else C(55, 55, 62)
			dot.BorderSizePixel = 0
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(1, 0)
			round.Parent = dot
			dot.Parent = lightsRow
		end
	end

	-- The ram (the plate the game moves) and everything welded to it
	local ramCf = CFrame.new(o.Position.X, restBottom + plateH / 2, o.Position.Z) * (o - o.Position)
	local ram = new(press, "Ram", Vector3.new(W * 0.92, plateH, W * 0.92), ramCf, st.ram, st.ramMat)
	local flange = new(press, "RamFlange", Vector3.new(W * 0.96, plateH * 0.35, W * 0.96), ramCf * CFrame.new(0, plateH * 0.5 + plateH * 0.17, 0), st.trim, st.trimMat)
	onRam(ram, flange)
	if stage >= 2 then
		local n = math.max(3, math.floor(W * 0.92 / 1.2))
		for i = 0, n - 1 do
			local x = -W * 0.46 + (i + 0.5) * (W * 0.92 / n)
			local stripe = new(press, "RamStripe", Vector3.new(W * 0.92 / n, plateH * 0.45, 0.12), ramCf * CFrame.new(x, 0, W * 0.46 + 0.06),
				if i % 2 == 0 then C(245, 190, 40) else BLACK, M.SmoothPlastic)
			onRam(ram, stripe)
		end
	end
	if st.neon then
		local glow = new(press, "RamGlow", Vector3.new(W * 0.93, 0.2, W * 0.93), ramCf * CFrame.new(0, -plateH / 2 + 0.1, 0), st.neon, M.Neon)
		onRam(ram, glow)
	end
	-- main rod: from the ram up into the housing, long enough to stay inside over the full stroke
	local rodD = W * 0.22
	local rodLen = if frameMesh then clearance + 1 else (floorY + beamTopLocal) - (restBottom + plateH) + housingH * 0.9
	local rod = vcyl(press, "Rod", rodLen, rodD, ramCf * CFrame.new(0, plateH / 2 + rodLen / 2, 0), st.rod, M.Metal)
	onRam(ram, rod)
	if st.neon then
		local ring = vcyl(press, "RodRing", 0.5 * math.max(1, s * 0.5), rodD * 1.25, ramCf * CFrame.new(0, plateH / 2 + 0.6 * math.max(1, s * 0.5), 0), st.neon, M.Neon)
		onRam(ram, ring)
	end

	if not frameMesh then
		-- Stage 2+: twin side cylinders
		if stage >= 2 then
			for _, side in { -1, 1 } do
				local x = side * W * 0.31
				local sleeveD = W * 0.13
				vcyl(press, "SideSleeve", housingH * 0.85, sleeveD, at(x, beamTopLocal + housingH * 0.85 / 2, 0), st.trim, M.Metal)
				vcyl(press, "SideCap", 0.4 * math.max(1, s * 0.5), sleeveD * 1.15, at(x, beamTopLocal + housingH * 0.85, 0), if st.neon then st.neon else st.frame, if st.neon then M.Neon else st.frameMat)
				local sideLen = (floorY + beamTopLocal) - (restBottom + plateH) + housingH * 0.75
				local sideRod = vcyl(press, "SideRod", sideLen, sleeveD * 0.55, ramCf * CFrame.new(x, plateH / 2 + sideLen / 2, 0), CHROME, M.Metal)
				onRam(ram, sideRod)
			end
			-- pressure gauge on the right pillar
			local gaugeCf = at(px, pillarH * 0.55, pillarW / 2 + 0.12 + (if stage == 3 then pillarW * 0.12 else 0))
			zcyl(press, "GaugeRim", 0.2, 1.8 * math.max(1, s * 0.6), gaugeCf, st.trim, M.Metal)
			zcyl(press, "GaugeFace", 0.24, 1.5 * math.max(1, s * 0.6), gaugeCf, C(245, 245, 240), M.SmoothPlastic)
			local needleLen = 0.6 * math.max(1, s * 0.6)
			new(press, "Needle", Vector3.new(0.12, needleLen, 0.05), gaugeCf * CFrame.new(0, 0, 0.14) * CFrame.Angles(0, 0, math.rad(-40 - tier * 8)) * CFrame.new(0, needleLen / 2, 0), C(220, 30, 30), M.Neon)
			-- control panel at the front left
			local panelCf = at(-(px + pillarW + 1.4), 0, W / 2 + 0.5)
			new(press, "PanelPost", Vector3.new(0.5, 3.2, 0.5), panelCf * CFrame.new(0, 1.6, 0), st.trim, M.Metal)
			local box = new(press, "PanelBox", Vector3.new(2.2, 1.4, 1.2), panelCf * CFrame.new(0, 3.6, 0) * CFrame.Angles(math.rad(-25), 0, 0), st.frame, st.frameMat)
			local button = ball(press, "Button", 0.75, box.CFrame * CFrame.new(-0.45, 0.62, 0), C(230, 30, 30), M.Neon)
			light(button, C(255, 60, 60), 6, 1)
			ball(press, "Lamp", 0.4, box.CFrame * CFrame.new(0.55, 0.65, 0), C(60, 230, 90), M.Neon)
		end

		-- Stage 3: beacons, steam vents, oil tank and pipes
		if stage == 3 then
			for _, side in { -1, 1 } do
				local bx = side * (beamW / 2 - 0.8 * math.max(1, s * 0.5))
				local baseCf = at(bx, beamTopLocal + 0.3, 0)
				vcyl(press, "BeaconBase", 0.6, 1.2 * math.max(1, s * 0.5), baseCf, st.trim, M.Metal)
				local bulb = ball(press, "Beacon", 1.1 * math.max(1, s * 0.5), baseCf * CFrame.new(0, 0.8 * math.max(1, s * 0.5), 0), C(255, 150, 30), M.Neon)
				light(bulb, C(255, 150, 40), 12 * s, 3)
				-- vent with steam
				local vent = new(press, "Vent", Vector3.new(1.2, 0.8, 1.2) * math.max(1, s * 0.5), at(side * W * 0.18, beamTopLocal + 0.4, -beamD * 0.25), st.trim, M.Metal)
				local steam = Instance.new("ParticleEmitter")
				steam.Color = ColorSequence.new(C(235, 235, 235))
				steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * s), NumberSequenceKeypoint.new(1, 2.5 * s) })
				steam.Transparency = NumberSequence.new(0.4, 1)
				steam.Lifetime = NumberRange.new(1.2, 2)
				steam.Speed = NumberRange.new(3 * s, 5 * s)
				steam.Rate = 4
				steam.SpreadAngle = Vector2.new(10, 10)
				steam.EmissionDirection = Enum.NormalId.Top
				steam.Parent = vent
			end
			-- oil tank behind the press, pipe up to the housing
			local tankL = W * 0.8
			local tankD = math.max(2.5, W * 0.28)
			local tankCf = at(0, tankD / 2 + 0.6, -(W / 2 + tankD / 2 + 1.2))
			xcyl(press, "Tank", tankL, tankD, tankCf, accent, M.Metal)
			for _, e in { -1, 1 } do
				xcyl(press, "TankEnd", 0.4, tankD * 1.05, tankCf * CFrame.new(e * tankL / 2, 0, 0), st.trim, M.Metal)
			end
			local pipeD = math.max(0.5, W * 0.05)
			local pipeTop = beamTopLocal + housingH * 0.6
			local pipeZ = -(W / 2 + tankD / 2 + 1.2)
			vcyl(press, "Pipe", pipeTop - tankD, pipeD, at(0, tankD + (pipeTop - tankD) / 2, pipeZ), C(40, 40, 44), M.Metal)
			new(press, "PipeTop", Vector3.new(pipeD, pipeD, math.abs(pipeZ)), at(0, pipeTop, pipeZ / 2), C(40, 40, 44), M.Metal)
		end

		-- Stage 4: screen + spinning ring around the housing
		if stage == 4 and st.neon then
			hoop(press, housingCf, housingD * 0.85, 0.35 * math.max(1, s * 0.6), st.neon, 1.5)
		end

		-- Stage 5: gold spikes, energy core with orbiting rings
		if stage == 5 and st.neon then
			local spikes = 5
			for i = 1, spikes do
				local x = (i - (spikes + 1) / 2) * (beamW / spikes)
				if math.abs(x) > housingD * 0.7 then
					local sh = beamH * 0.9
					new(press, "Spike", Vector3.new(beamD * 0.5, sh, beamD * 0.5), at(x, beamTopLocal + sh / 2, 0) * CFrame.Angles(0, math.rad(45), 0), GOLD, M.Metal)
					ball(press, "SpikeTip", beamD * 0.32, at(x, beamTopLocal + sh, 0), st.neon, M.Neon)
				end
			end
			for _, side in { -1, 1 } do
				new(press, "GoldCap", Vector3.new(pillarW * 1.35, 0.8, pillarW * 1.35), at(side * px, pillarH * 0.5, 0), GOLD, M.Metal)
			end
			local coreCf = at(0, beamTopLocal + housingH + housingD * 0.75, 0)
			local core = ball(press, "Core", housingD * 0.9, coreCf, st.neon, M.Neon)
			light(core, st.neon, 30, 4)
			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkle.Color = ColorSequence.new(st.neon)
			sparkle.LightEmission = 1
			sparkle.Size = NumberSequence.new(1.5 * s, 0)
			sparkle.Lifetime = NumberRange.new(0.8, 1.5)
			sparkle.Speed = NumberRange.new(2 * s, 5 * s)
			sparkle.SpreadAngle = Vector2.new(180, 180)
			sparkle.Rate = 12
			sparkle.Parent = core
			hoop(press, coreCf, housingD * 1.0, 0.4 * s, GOLD, 1.2, CFrame.Angles(math.rad(70), 0, 0))
			hoop(press, coreCf, housingD * 1.25, 0.35 * s, st.neon, -0.9, CFrame.Angles(math.rad(-60), math.rad(30), 0))
		end

	end

	-- Nothing on the press should trip up players walking past except the frame.
	for _, d in press:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Glow" or d.Name == "LevelLight" or d.Name == "Needle" or d.Name == "BedStripe") then
			d.CanCollide = false
		end
	end

	return { model = press, ram = ram, bedTop = bedTop, restBottom = restBottom }
end

return PressBuilder
