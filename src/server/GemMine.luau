--!strict
-- 9 Nov: THE GEM MINE (Willem: "teleporter to a new world with the Gem Crusher; it crushes
-- gems, you have to pick them up"). All Gems come from here (GemConfig.Mine).
--
--   * One shared area far outside the toy room (it only streams in when you are there).
--   * 10 Nov (Willem: "just 1 crusher that everyone uses"): ONE big Gem Crusher in the middle,
--     a glowing pickup zone around it where the gems land, a rim of rocks and crystals, one
--     portal (you arrive on it and press E on it to go home) and a GEM UPGRADES sign.
--   * A teleporter on every plot (front left) opens at rebirth 1. Server-side
--     ProximityPrompts, server-side teleports.
--   * Everyone's gems are private: the server keeps each player's records (position, value;
--     at most MaxDrops) on that player's own crush timer (their upgrades). Your client draws
--     your gems and plays the crusher's strike for your crushes only, so the one crusher
--     strikes at your pace on your screen. Pickups: the server checks each one's distance
--     and a rate budget (vault: Collectible Pickup FX - server owns records, validates
--     batched requests; per-player pickups are never server instances).
--   * Rebirth 5 awakens your crusher: x1.5 gem value, and on your screen it turns opal.
--   * 10 Nov: Willem's models (ChatGPT + Blender: GemCoreColossus crusher with a moving Ram and
--     two pistons, teleporter pad, pickup gem, crystal clusters, cave rocks) live in the place
--     file under ReplicatedStorage.GemMineMeshes (not in Git; pre-sized, upright, front -Z).
--     Anything missing there falls back to the part-built stand-ins below.
--
-- Remote "GemMine": server -> client {kind="sync"|"add"|"collected"|"openShop"};
-- client -> server ("collect", {ids}) / ("sync").
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local Gems = require(RS.Shared.GemConfig)
local Store = require(RS.Shared.Store)
local MarketplaceService = game:GetService("MarketplaceService")
local Net = require(RS.Shared.Net)
local Build = require(script.Parent.Kit.Build)
local Analytics = require(script.Parent.Kit.Analytics)

local M = {}
local Mine = Gems.Mine

type Api = {
	data: (Player) -> any, -- the player's save (d) or nil
	plot: (Player) -> any, -- the player's plot (index, origin, model) or nil
	plots: () -> { any },
	teleport: (Player, CFrame) -> (),
	home: (Player) -> (),
	refreshState: (Player) -> (), -- push CrusherState (gem count etc.)
	act: (Player, string, any) -> (boolean, string?, any), -- 11 Nov: run a crusher action (the Gem Chest opens with "GemCrate")
}
local api: Api
type Drop = { pos: Vector3, value: number }
type State = { nextCrush: number, drops: { [number]: Drop }, count: number, nextId: number, budget: number, budgetAt: number }
local states: { [Player]: State } = {}
type Crusher = { model: Model, center: Vector3, -- center: the platform's top middle
	 ramRest: CFrame, arrive: CFrame }
local crusher: Crusher
local root: Folder
local walkToggle: ((Player) -> ())? = nil -- the AUTO WALK board's action (also the client's button)
local chest: { model: Model, lid: BasePart, hinge: CFrame, lidRest: CFrame, front: BasePart, busy: boolean }? = nil

local RGB = Color3.fromRGB
local NAVY, GOLD, MAGENTA, PINK = RGB(38, 34, 78), RGB(255, 196, 40), RGB(225, 60, 210), RGB(255, 140, 235)
local CYAN = RGB(140, 240, 255)
local ROCK = RGB(70, 52, 112)

local function label(adornee: BasePart, text: string, color: Color3, y: number, size: Vector2): TextLabel
	local gui = Build.label(adornee, text, color, y, size)
	return gui:FindFirstChild("Text") :: TextLabel
end

local function prompt(parent: BasePart, action: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

-- the stand-in Gem Crusher (Willem's concept: navy arch, gold pistons, magenta core and
-- crystal pressing block over an anvil), k times the bay size. Front faces -Z of `cf`.
-- The crystal parts (Inlay, Core, Anvil, Ram) are what the client recolours when awake.
local Meshes = RS:FindFirstChild("GemMineMeshes")
local function tpl(name: string): Instance?
	return Meshes and Meshes:FindFirstChild(name)
end

local function buildCrusher(parent: Instance, cf: CFrame, k: number): (Model, BasePart)
	local t = tpl("GemCrusher")
	if t and t:IsA("Model") and t:FindFirstChild("Frame") and t:FindFirstChild("Ram") then
		-- Willem's model: Frame stays, Ram + Piston_L + Piston_R move (the client plays it)
		local m = t:Clone()
		m.Name = "GemCrusher"
		for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
		m.PrimaryPart = m:FindFirstChild("Frame") :: BasePart
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- streams in whole (the client's strike/awake look)
		-- 11 Nov: bigger (Mine.ModelScale); the strike and height grow with it
		local k2 = Mine.ModelScale or 1
		if k2 ~= 1 then
			m:ScaleTo(m:GetScale() * k2)
			for _, a in { "Strike", "Height" } do
				local v = tonumber(m:GetAttribute(a))
				if v then m:SetAttribute(a, v * k2) end
			end
		end
		m:PivotTo(cf)
		m.Parent = parent
		return m, m:FindFirstChild("Ram") :: BasePart
	end
	local m = Instance.new("Model")
	m.Name = "GemCrusher"
	local function part(name: string, size: Vector3, at: CFrame, color: Color3, mat: Enum.Material?): Part
		local p = Build.block(m, name, size * k, cf * CFrame.new(at.Position * k) * at.Rotation, color)
		p.Material = mat or Enum.Material.SmoothPlastic
		p.CanCollide = name == "Base" or name:find("Pillar") ~= nil
		return p
	end
	part("Base", Vector3.new(11, 1.2, 7), CFrame.new(0, 0.6, 0), NAVY)
	for _, x in { -4.2, 4.2 } do
		part("Pillar", Vector3.new(2.2, 9, 2.6), CFrame.new(x, 5.7, 0), NAVY)
		part("PillarGold", Vector3.new(2.4, 0.5, 2.8), CFrame.new(x, 3.4, 0), GOLD, Enum.Material.Metal)
		part("Inlay", Vector3.new(0.4, 2, 1.1), CFrame.new(x, 5.6, -1.35), MAGENTA, Enum.Material.Neon)
		part("Piston", Vector3.new(1.2, 3.2, 1.2), CFrame.new(x * 0.62, 8.3, -0.2), GOLD, Enum.Material.Metal)
	end
	part("Arch", Vector3.new(11, 2.2, 3), CFrame.new(0, 11.1, 0), NAVY)
	part("Core", Vector3.new(2.8, 2.8, 2.8), CFrame.new(0, 11.4, -1.4) * CFrame.Angles(math.rad(45), math.rad(45), 0), MAGENTA, Enum.Material.Neon)
	part("Anvil", Vector3.new(6, 0.9, 4), CFrame.new(0, 2.3, -0.2), MAGENTA, Enum.Material.Glass)
	local ram = part("Ram", Vector3.new(6.4, 1.6, 4.2), CFrame.new(0, 6.6, -0.2), MAGENTA, Enum.Material.Glass)
	m.PrimaryPart = m:FindFirstChild("Base") :: BasePart
	m:SetAttribute("Strike", 3.3 * k) -- how far the ram comes down (the client plays it)
	m:SetAttribute("Height", 12.2 * k)
	m.Parent = parent
	return m, ram
end

-- the portal (the same look on your plot and in the mine). 11 Nov (Willem: "probably a portal is
-- better for it instead of a pad on the ground"): a standing ring portal. Willem's pad (or a navy
-- disc) is its base; on it an upright gold ring with a pink rim and a glowing swirl inside, facing
-- along the CFrame's Z. E on the swirl uses it.
local PORTAL_R = 5 -- the ring's radius (studs, to the middle of the gold band)
local function buildPortal(parent: Instance, at: CFrame, title: string, action: string, turn: boolean?): (Model, TextLabel, ProximityPrompt)
	local m = Instance.new("Model")
	local baseTop = 1
	local padT = tpl("TeleporterPad")
	-- 11 Nov: Willem's GemPortalRing (ReplicatedStorage.GemMineMeshes: ground-centre pivot, front -Z,
	-- own base 0.9 high, opening 8 across centred 5.85 up). Its meshes don't collide (a box round
	-- the ring would close the hole); an invisible flat pad under the base carries you.
	local ringT = tpl("GemPortalRing")
	local hasRing = ringT ~= nil and ringT:IsA("Model")
	local centre = at * CFrame.new(0, 5.85, -0.3)
	local radius = 3.95 + 0.8 -- (the swirl below is radius * 2 - 1.6 = 7.9 across)
	if hasRing then
		local ring = (ringT :: Model):Clone()
		ring.Name = "Ring"
		for _, d in ring:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false end end
		ring:PivotTo(if turn then at * CFrame.Angles(0, math.pi, 0) else at) -- (its gold front toward where you come from)
		ring.Parent = m
		local pad = Build.block(m, "Pad", Vector3.new(10.8, 0.9, 3.5), at * CFrame.new(0, 0.45, 0), NAVY)
		pad.Transparency = 1 pad.CanQuery = false
	elseif padT and padT:IsA("BasePart") then
		local pad = padT:Clone()
		pad.Name = "Pad" pad.Anchored = true
		pad:PivotTo(at * CFrame.new(0, pad.Size.Y / 2, 0))
		pad.Parent = m
		baseTop = pad.Size.Y
	else
		local base = Build.block(m, "Pad", Vector3.new(1, 11, 11), at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), NAVY)
		base.Shape = Enum.PartType.Cylinder
		local rim = Build.block(m, "PadRim", Vector3.new(1.05, 9, 9), at * CFrame.new(0, 0.52, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
		rim.Shape = Enum.PartType.Cylinder rim.Material = Enum.Material.Neon
	end
	if not hasRing then centre = at * CFrame.new(0, baseTop + PORTAL_R + 0.6, 0) radius = PORTAL_R end
	-- (stand-in without Willem's ring) 24 gold blocks round a circle, a pink neon band just inside
	local n = if hasRing then 0 else 24
	local len = 2 * math.pi * PORTAL_R / 24 * 1.12
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local seg = centre * CFrame.Angles(0, 0, a) * CFrame.new(0, PORTAL_R, 0)
		local g = Build.block(m, "Ring", Vector3.new(len, 1.1, 1.4), seg, GOLD)
		g.Material = Enum.Material.Metal
		local inner = Build.block(m, "RingGlow", Vector3.new(len * 0.86, 0.35, 1.5), centre * CFrame.Angles(0, 0, a) * CFrame.new(0, PORTAL_R - 0.7, 0), MAGENTA)
		inner.Material = Enum.Material.Neon inner.CanCollide = false
	end
	-- gems on the ring: one at the top, two at the sides
	for _, ang in (if hasRing then {} else { 0, 90, -90 }) do
		local gem = Build.block(m, "RingGem", Vector3.new(1.3, 1.3, 1.3), centre * CFrame.Angles(0, 0, math.rad(ang)) * CFrame.new(0, PORTAL_R + 0.4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), CYAN)
		gem.Material = Enum.Material.Neon gem.CanCollide = false
	end
	-- the swirl (a thin disc facing along Z) with sparkles drawn into it
	local swirl = Build.block(m, "Swirl", Vector3.new(0.3, radius * 2 - 1.6, radius * 2 - 1.6), centre * CFrame.Angles(0, math.rad(90), 0), PINK)
	swirl.Shape = Enum.PartType.Cylinder swirl.Material = Enum.Material.ForceField swirl.Transparency = 0.05
	swirl.CanCollide = false swirl.CastShadow = false
	local core = Build.block(m, "SwirlCore", Vector3.new(0.2, radius * 2 - 1.7, radius * 2 - 1.7), centre * CFrame.Angles(0, math.rad(90), 0), RGB(120, 40, 170))
	core.Shape = Enum.PartType.Cylinder core.Material = Enum.Material.Neon core.Transparency = 0.35
	core.CanCollide = false core.CastShadow = false
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 14 pe.Lifetime = NumberRange.new(0.8, 1.4) pe.Speed = NumberRange.new(-3, -2)
	pe.Shape = Enum.ParticleEmitterShape.Disc pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(RGB(255, 170, 245), CYAN) pe.LightEmission = 1
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds" pe.Rotation = NumberRange.new(0, 360) pe.RotSpeed = NumberRange.new(-180, 180)
	pe.Parent = core
	local light = Instance.new("PointLight") light.Range = 18 light.Brightness = 1.6 light.Color = RGB(255, 150, 240) light.Shadows = false light.Parent = core
	local text = label(swirl, title, RGB(255, 170, 245), if hasRing then 8.2 else PORTAL_R + 2.6, Vector2.new(14, 3))
	local pr = prompt(swirl, action, "Gem Mine")
	m.PrimaryPart = swirl
	m.Parent = parent
	return m, text, pr
end

local function buildWorld()
	root = Instance.new("Folder")
	root.Name = "GemMine"
	local o = Mine.Origin
	local rng = Random.new(9)
	local function light(at: BasePart, height: number, range: number, color: Color3, brightness: number?)
		local att = Instance.new("Attachment") att.Parent = at att.WorldPosition = at.Position + Vector3.new(0, height, 0)
		local l = Instance.new("PointLight") l.Range = range l.Brightness = brightness or 2.2 l.Color = color l.Shadows = false l.Parent = att
	end
	local function deco(p: BasePart) p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false end
	local function clone(name: string, size: number, at: CFrame, collide: boolean): BasePart?
		local t = tpl(name)
		if not (t and t:IsA("BasePart")) then return nil end
		local c = t:Clone() c.Anchored = true
		c.Size *= size
		c:PivotTo(at * CFrame.new(0, c.Size.Y / 2 - 0.2, 0))
		if not collide then deco(c) end
		c.Parent = root
		return c
	end

	-- 10 Nov (Willem: "more gem like ... it looks kinda plain"): a dark crystal-cave floor
	-- with glowing crystal veins, big crystal spires and floating gems around the rim
	-- 10 Nov (Willem: the studs "looks kinda unfinished"): a polished amethyst tile floor. A
	-- dark violet base glows faintly through the joints; diamond-set tiles in two tones on top
	-- (one part per tile, ~200 in all; none under the gem platform).
	local floor = Build.block(root, "MineFloor", Vector3.new(4, Mine.Radius * 2, Mine.Radius * 2), o * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), RGB(66, 26, 118))
	floor.Shape = Enum.PartType.Cylinder floor.Material = Enum.Material.Neon
	local edge = Build.block(root, "MineEdge", Vector3.new(3.6, Mine.Radius * 2 + 3, Mine.Radius * 2 + 3), o * CFrame.new(0, -2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
	edge.Shape = Enum.PartType.Cylinder edge.Material = Enum.Material.Neon deco(edge)
	local tileFolder = Instance.new("Folder") tileFolder.Name = "FloorTiles" tileFolder.Parent = root
	local STEP, TILE = 10, 9.2 -- 0.8-stud glowing joints (11 Nov: bigger tiles for the bigger floor)
	local platformAt = (o * Mine.Zone.center).Position
	local n = math.ceil(Mine.Radius / STEP) + 1
	for gx = -n, n do
		for gz = -n, n do
			-- a diamond grid: the square grid turned 45 degrees
			local lx, lz = (gx - gz) * STEP / math.sqrt(2), (gx + gz) * STEP / math.sqrt(2)
			local at = o * CFrame.new(lx, 0, lz)
			local flat = Vector3.new(lx, 0, lz)
			local fromPlatform = Vector3.new(at.Position.X - platformAt.X, 0, at.Position.Z - platformAt.Z).Magnitude
			if flat.Magnitude < Mine.Radius - 4 and fromPlatform > Mine.Zone.radius - 2 then
				local dark = (gx + gz) % 2 == 0
				local t = Build.block(tileFolder, "Tile", Vector3.new(TILE, 0.4, TILE), at * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, math.rad(45), 0),
					if dark then RGB(70, 44, 126) else RGB(98, 62, 166))
				t.Material = Enum.Material.Glass t.Reflectance = 0.12 t.MaterialVariant = ""
				t.CanTouch = false t.CastShadow = false
			end
		end
	end
	-- the rim: cave rocks with crystal clusters in front of them, and big crystal spires
	for i = 1, 30 do -- (11 Nov: 22 -> 30 for the bigger rim)
		local a = i / 30 * math.pi * 2
		local at = o * CFrame.new(math.cos(a) * (Mine.Radius - 4), 0, math.sin(a) * (Mine.Radius - 4))
		local turn = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		if not clone(({ "CaveRockSmall", "CaveRockWide", "CaveRockTall" })[i % 3 + 1], 1.8 + rng:NextNumber() * 1.6, at * turn, true) then
			Build.rock(root, at, 2.2 + rng:NextNumber() * 1.6, { rock = ROCK }, rng)
		end
		local inward = o * CFrame.new(math.cos(a) * (Mine.Radius - 11), 0, math.sin(a) * (Mine.Radius - 11))
		if i % 2 == 0 then
			clone(if i % 4 == 0 then "CrystalClusterLarge" else "CrystalClusterSmall", 2 + rng:NextNumber() * 1.5, inward * turn, false)
		end
		local front = math.sin(a) > 0.6 -- the side with the portal: keep the view open
		if i % 4 == 1 and not front then
			-- a big spire with a glow
			local spire = clone("CrystalClusterLarge", 3.5 + rng:NextNumber() * 1.5, at * turn, false)
			if spire and i % 8 == 1 then light(spire, 6, 34, if i % 16 == 1 then CYAN else PINK, 1.6) end
		end
	end
	-- floating gems around the mine (the client spins and bobs them)
	local float = Instance.new("Folder") float.Name = "FloatGems" float.Parent = root
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2 + 0.2
		-- only on the left and right: not over the crusher (back) or the portal (front)
		if math.abs(math.sin(a)) > 0.55 then continue end
		local r = Mine.Radius - 18 + rng:NextNumber(-4, 4)
		local t = tpl("GemPickup")
		local g: BasePart
		if t and t:IsA("BasePart") then g = t:Clone() :: BasePart g.Size *= rng:NextNumber(3.5, 6)
		else g = Build.block(float, "Gem", Vector3.new(3, 3, 3), CFrame.new(), PINK) g.Material = Enum.Material.Neon end
		g.Name = "FloatGem" g.Anchored = true deco(g)
		g.CFrame = o * CFrame.new(math.cos(a) * r, rng:NextNumber(14, 24), math.sin(a) * r)
		g.Parent = float
	end

	-- THE PLATFORM in front of the crusher (Willem: "gem crusher a bit further back and then the
	-- platform in the front"): your gems land on it. Raised, gold trim, a glowing ring.
	local zc = o * Mine.Zone.center
	local zr = Mine.Zone.radius
	-- 11 Nov: Willem's rim, twelve 30-degree arcs (GemPlatformEdgeSegment, plain ones facing the
	-- portal), pivot at the platform's ground centre, made for radius 38; else a gold cylinder
	local segT, plainT = tpl("GemPlatformEdgeSegment"), tpl("GemPlatformEdgePlain")
	local hasRim = segT ~= nil and segT:IsA("Model")
	if hasRim then
		local rim = Instance.new("Model") rim.Name = "ZoneEdge"
		local k = zr / 38 -- (uniform, if the platform radius ever changes)
		for i = 0, 11 do
			local t = if (i == 0 or i == 11) and plainT and plainT:IsA("Model") then plainT else segT
			local s = (t :: Model):Clone()
			for _, d in s:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false end end
			if k ~= 1 then s:ScaleTo(s:GetScale() * k) end
			s:PivotTo(zc * CFrame.Angles(0, (i + 0.5) * math.pi / 6, 0))
			s.Parent = rim
		end
		rim.Parent = root
	else
		local trim = Build.block(root, "ZoneTrim", Vector3.new(Mine.Zone.height, zr * 2 + 2, zr * 2 + 2), zc * CFrame.new(0, Mine.Zone.height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD)
		trim.Shape = Enum.PartType.Cylinder trim.Material = Enum.Material.Metal
	end
	local ring = Build.block(root, "ZoneRim", Vector3.new(Mine.Zone.height + 0.1, zr * 2 + 0.8, zr * 2 + 0.8), zc * CFrame.new(0, Mine.Zone.height / 2 + 0.03, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
	ring.Shape = Enum.PartType.Cylinder ring.Material = Enum.Material.Neon deco(ring)
	local top = Build.block(root, "Zone", Vector3.new(Mine.Zone.height + 0.2, zr * 2, zr * 2), zc * CFrame.new(0, Mine.Zone.height / 2 + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), RGB(78, 46, 132))
	top.Shape = Enum.PartType.Cylinder top.Material = Enum.Material.Glass top.Reflectance = 0.1
	-- facet tiles: a star of thin gold lines on the platform
	for i = 1, 8 do
		local line = Build.block(root, "Facet", Vector3.new(0.25, 0.06, zr * 2 - 2), zc * CFrame.new(0, Mine.Zone.height + 0.2, 0) * CFrame.Angles(0, i / 8 * math.pi, 0), GOLD)
		line.Material = Enum.Material.Neon line.Transparency = 0.7 deco(line)
	end
	-- small crystals around the platform edge, leaving the front (to the portal) open
	for i = 1, 14 do
		local a = math.rad(-120 + (i - 1) * 18.5)
		local at = zc * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -(zr + (if hasRim then 3.4 else 2.2))) -- (outside the rim)
		clone(if i % 3 == 0 then "CrystalClusterLarge" else "CrystalClusterSmall", 1.1 + rng:NextNumber() * 0.5, at * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), false)
	end
	-- sparkles over the platform (one emitter)
	local sparkHost = Build.block(root, "Sparkles", Vector3.new(zr * 1.6, 0.2, zr * 1.6), zc * CFrame.new(0, Mine.Zone.height + 6, 0), PINK)
	sparkHost.Transparency = 1 deco(sparkHost)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 8 pe.Lifetime = NumberRange.new(1.5, 2.5) pe.Speed = NumberRange.new(0.5, 1.5)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(RGB(255, 170, 245), CYAN) pe.LightEmission = 1 pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.SpreadAngle = Vector2.new(180, 180) pe.Parent = sparkHost
	light(top, 10, 60, RGB(255, 150, 240), 1.8) -- (PointLight range tops out at 60)

	-- the one Gem Crusher at the back of the platform, its front towards the portal (+Z)
	local m, ram = buildCrusher(root, o * CFrame.new(0, 0, Mine.CrusherZ) * CFrame.Angles(0, math.rad(180), 0), Mine.CrusherScale)
	local height = tonumber(m:GetAttribute("Height")) or 22
	local base = m.PrimaryPart :: BasePart
	local above = height - (base.Position.Y - o.Position.Y) -- from the part's centre to the top
	light(base, above + 4, 60, RGB(230, 200, 255))
	label(base, "GEM CRUSHER", RGB(255, 200, 250), above + 3, Vector2.new(22, 3.4))
	-- the portal: you arrive on it and press E on it to go home
	local portalAt = o * CFrame.new(0, 0, Mine.PortalZ)
	local portal, _, pr = buildPortal(root, portalAt, "BACK TO YOUR FACTORY", "Go home")
	portal.Name = "Portal"
	pr.Triggered:Connect(function(p) api.home(p) end)
	light(portal.PrimaryPart :: BasePart, 10, 30, RGB(255, 170, 240))
	-- the Gem Shop sign beside the portal: a navy board with a gold frame and a gem on top
	local signAt = portalAt * CFrame.new(11, 0, -2) * CFrame.Angles(0, math.rad(20), 0)
	-- 11 Nov: Willem's GemSignBoard for both boards (blank Panel 5.16 x 3.12, front -Z; the frame
	-- covers the panel's back, so the back text sits on an invisible board on the frame's back)
	local boardT = tpl("GemSignBoard")
	local hasBoard = boardT ~= nil and boardT:IsA("Model") and boardT:FindFirstChild("Panel") ~= nil
	local function board(at: CFrame, name: string, frameName: string, postName: string): (BasePart, BasePart?)
		if hasBoard then
			local s = (boardT :: Model):Clone()
			s.Name = name .. "Board"
			for _, d in s:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false end end
			s:PivotTo(at)
			s.Parent = root
			local panel = s:FindFirstChild("Panel") :: BasePart
			panel.Name = name panel.CanQuery = true -- (prompt and click)
			local rel = at:ToObjectSpace(panel.CFrame)
			local back = Build.block(s, name .. "Back", Vector3.new(panel.Size.X, panel.Size.Y, 0.05), at * CFrame.new(rel.X, rel.Y, 0.7), NAVY)
			back.Transparency = 1 deco(back)
			return panel, back
		end
		for _, x in { -2.6, 2.6 } do Build.block(root, postName, Vector3.new(0.6, 6, 0.6), at * CFrame.new(x, 3, 0), GOLD).Material = Enum.Material.Metal end
		local frame = Build.block(root, frameName, Vector3.new(6, 4, 0.5), at * CFrame.new(0, 5, 0), GOLD)
		frame.Material = Enum.Material.Metal
		return Build.block(root, name, Vector3.new(5.2, 3.2, 0.6), at * CFrame.new(0, 5, 0), NAVY), nil
	end
	local shop, shopBack = board(signAt, "UpgradeSign", "SignFrame", "SignPost")
	local signGem = tpl("GemPickup")
	if signGem and signGem:IsA("BasePart") and not hasBoard then
		local g = signGem:Clone() g.Anchored = true g.Size *= 2.2 deco(g)
		g.CFrame = signAt * CFrame.new(0, 8.2, 0) g.Parent = root
	end
	-- the words printed on both faces of the board (a floating label hid behind it)
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 60
		sg.LightInfluence = 0 sg.MaxDistance = 120
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(0.92, 0.8) t.Position = UDim2.fromScale(0.04, 0.1) t.BackgroundTransparency = 1
		t.Text = "GEM\nUPGRADES" t.TextScaled = true t.Font = Enum.Font.FredokaOne t.TextColor3 = RGB(255, 236, 120)
		local st = Instance.new("UIStroke") st.Thickness = 5 st.Color = RGB(40, 20, 60) st.Parent = t
		t.Parent = sg
		if face == Enum.NormalId.Back and shopBack then sg.Adornee = shopBack end
		sg.Parent = shop
	end
	prompt(shop, "Upgrades", "Gem Shop").Triggered:Connect(function(p)
		Net.event("GemMine"):FireClient(p, { kind = "openShop" })
	end)
	-- 11 Nov (Willem): the AUTO WALK board on the other side of the portal (the same look as the
	-- upgrades sign). Not owned: E / click opens the pass purchase. Owned: it switches Auto Walk
	-- on and off (attribute AutoWalkOn). Each player's own text (price / ON / OFF) is set on
	-- their screen (client/GemMine), the board says what it does.
	local walkAt = portalAt * CFrame.new(-11, 0, -2) * CFrame.Angles(0, math.rad(-20), 0)
	local walk, walkBack = board(walkAt, "AutoWalkSign", "WalkFrame", "WalkPost")
	if not hasBoard then
		local shoe = Build.block(root, "WalkGem", Vector3.new(1.4, 1.4, 1.4), walkAt * CFrame.new(0, 7.8, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), MAGENTA)
		shoe.Material = Enum.Material.Neon deco(shoe)
	end
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local sg = Instance.new("SurfaceGui")
		sg.Name = "AutoWalkGui" sg.Face = face sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 60
		sg.LightInfluence = 0 sg.MaxDistance = 120
		local t = Instance.new("TextLabel")
		t.Name = "Title" t.Size = UDim2.fromScale(0.92, 0.5) t.Position = UDim2.fromScale(0.04, 0.06) t.BackgroundTransparency = 1
		t.Text = "AUTO WALK" t.TextScaled = true t.Font = Enum.Font.FredokaOne t.TextColor3 = RGB(255, 170, 245)
		local st = Instance.new("UIStroke") st.Thickness = 5 st.Color = RGB(40, 20, 60) st.Parent = t
		t.Parent = sg
		local sub = Instance.new("TextLabel")
		sub.Name = "Status" sub.Size = UDim2.fromScale(0.92, 0.36) sub.Position = UDim2.fromScale(0.04, 0.58) sub.BackgroundTransparency = 1
		sub.Text = "walks to your gems" sub.TextScaled = true sub.Font = Enum.Font.FredokaOne sub.TextColor3 = RGB(255, 236, 120)
		local st2 = Instance.new("UIStroke") st2.Thickness = 4 st2.Color = RGB(40, 20, 60) st2.Parent = sub
		sub.Parent = sg
		if face == Enum.NormalId.Back and walkBack then sg.Adornee = walkBack end
		sg.Parent = walk
	end
	local function onWalkBoard(p: Player)
		if Store.hasPass(p, "AutoWalk") then
			p:SetAttribute("AutoWalkOn", p:GetAttribute("AutoWalkOn") == false)
			return
		end
		local pass = Store.passByPerk("AutoWalk")
		if pass and pass.gamePassId ~= 0 then
			Analytics.custom(p, "SignClicked", nil, "AutoWalk")
			MarketplaceService:PromptGamePassPurchase(p, pass.gamePassId)
		end
	end
	walkToggle = onWalkBoard
	local walkPrompt = prompt(walk, "Auto Walk", "Gem Mine")
	walkPrompt.Name = "AutoWalkPrompt"
	walkPrompt.Triggered:Connect(onWalkBoard)
	local click = Instance.new("ClickDetector") click.MaxActivationDistance = 40 click.Parent = walk
	click.MouseClick:Connect(onWalkBoard)
	-- 11 Nov (Willem: "put the chest physically in the cave. then you buy 1 key, and open it with the
	-- key"): the GEM CHEST beside the GEM UPGRADES board, facing the platform. E with a key opens it
	-- (rule GemCrate takes the key); keys are bought at GEM UPGRADES (rule GemKey).
	do
		local at = portalAt * CFrame.new(21, 0, -9) * CFrame.Angles(0, math.rad(35), 0)
		local cm = Instance.new("Model") cm.Name = "GemChest"
		local function cpart(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
			local p = Build.block(cm, name, size, cf, color)
			p.Material = mat or Enum.Material.SmoothPlastic
			return p
		end
		local W, D, Hb = 8.4, 5.4, 3.8 -- (a big chest: it is the prize of the mine)
		-- 11 Nov: Willem's chest model (ReplicatedStorage.GemMineMeshes.GemChest: MeshParts ChestBody,
		-- ChestGlow (still), ChestLid + LidGlow (turn about the rear hinge, attribute Hinge relative
		-- to the ground-centre pivot), front -Z). The meshes don't collide; an invisible ChestHitbox
		-- carries the prompt, the label and the reach check. Without it, the block chest below.
		local template = Meshes and Meshes:FindFirstChild("GemChest")
		local hingeLocal = template and template:GetAttribute("Hinge")
		local body: BasePart
		local lid: BasePart
		local hinge: CFrame
		local lock: BasePart? = nil
		if template and typeof(hingeLocal) == "CFrame" then
			local copy = template:Clone()
			copy:PivotTo(at)
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false d.CastShadow = d.Name == "ChestBody" or d.Name == "ChestLid"
					d.Parent = cm
				end
			end
			copy:Destroy()
			lid = cm:FindFirstChild("ChestLid") :: BasePart
			hinge = at * hingeLocal
			body = cpart("ChestHitbox", Vector3.new(W, 4.6, D), at * CFrame.new(0, 2.3, 0), NAVY)
			body.Transparency = 1
			body.CanCollide = true body.CanQuery = true
			label(body, "GEM CHEST", RGB(255, 170, 245), 6.6, Vector2.new(12, 2.8))
		else
		body = cpart("ChestBody", Vector3.new(W, Hb, D), at * CFrame.new(0, Hb / 2 + 0.4, 0), NAVY)
		cpart("ChestFoot", Vector3.new(W + 0.6, 0.4, D + 0.6), at * CFrame.new(0, 0.2, 0), GOLD, Enum.Material.Metal)
		for _, x in { -W / 2 + 0.6, W / 2 - 0.6 } do
			cpart("ChestBand", Vector3.new(0.5, Hb + 0.05, D + 0.1), at * CFrame.new(x, Hb / 2 + 0.4, 0), GOLD, Enum.Material.Metal)
		end
		-- the lid turns about its back edge (hinge)
		hinge = at * CFrame.new(0, Hb + 0.4, D / 2)
		lid = cpart("ChestLid", Vector3.new(W, 1.8, D), hinge * CFrame.new(0, 0.9, -D / 2), RGB(60, 50, 120))
		local lidBands = {}
		for _, x in { -W / 2 + 0.6, W / 2 - 0.6 } do
			table.insert(lidBands, cpart("ChestLidBand", Vector3.new(0.6, 1.85, D + 0.1), hinge * CFrame.new(x, 0.9, -D / 2), GOLD, Enum.Material.Metal))
		end
		lock = cpart("ChestLock", Vector3.new(1.4, 1.4, 0.5), at * CFrame.new(0, Hb + 0.1, -D / 2 - 0.2) * CFrame.Angles(0, 0, math.rad(45)), MAGENTA, Enum.Material.Neon)
		local glow = cpart("ChestGlow", Vector3.new(W - 1, 0.2, D - 1), at * CFrame.new(0, Hb + 0.35, 0), PINK, Enum.Material.Neon)
		glow.Transparency = 0.4
		for _, p in cm:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = p.Name == "ChestBody" or p.Name == "ChestFoot" end end
		label(body, "GEM CHEST", RGB(255, 170, 245), 5.6, Vector2.new(12, 2.8))
		end
		local pr = prompt(body, "Open", "Gem Chest")
		pr.Name = "GemChestPrompt" pr.MaxActivationDistance = 12
		cm.PrimaryPart = body
		cm.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- (the lid arrives with the box)
		cm.Parent = root
		chest = { model = cm, lid = lid, hinge = hinge, lidRest = lid.CFrame, front = body, busy = false }
		-- the hinge for the clients' lid animation (client/GemMine plays the opening and the reveal)
		cm:SetAttribute("Hinge", hinge)
		pr.Triggered:Connect(function(p)
			local ok, _, item = api.act(p, "GemCrate", {})
			if not ok or type(item) ~= "table" then return end
			-- 11 Nov (Willem: "make the chest reveal more special"): everyone near sees the lid fly
			-- open and a beam in the prize's colour; the opener gets the full reveal on screen
			Net.event("GemMine"):FireAllClients({ kind = "chestOpen", rarity = item.rarity, by = p.UserId })
			Net.event("GemMine"):FireClient(p, { kind = "chestReveal", type = item.type, rarity = item.rarity })
		end)
		if lock then lock.CanQuery = false end
	end
	crusher = { model = m, center = zc.Position + Vector3.new(0, Mine.Zone.height, 0), ramRest = ram.CFrame,
		arrive = CFrame.lookAt((portalAt * CFrame.new(0, 3, -6)).Position, zc.Position + Vector3.new(0, 3, 0)) }
	root.Parent = workspace
end

-- the Gem Chest's front part (the server's reach check for "GemCrate")
function M.chestPart(): BasePart? return chest and chest.front or nil end

-- the teleporter on every plot (front left, inside the entrance)
local function buildTeleporters()
	for _, plot in api.plots() do
		local at = plot.origin * CFrame.new(Mine.Teleporter.x, 0, Mine.Teleporter.z) -- (the ring faces along Z: down the road)
		local m, text, pr = buildPortal(plot.model, at, "GEM MINE", "Teleport", true)
		m.Name = "GemMineTeleporter"
		m:SetAttribute("PlotIndex", plot.index)
		pr.Triggered:Connect(function(p) M.enter(p) end)
		-- 11 Nov: it stands in the rear yard, so it only shows once the owner has FACTORY IV
		m.Parent = nil
		plot.gemTeleporter = { text = text, prompt = pr, model = m, home = plot.model }
	end
end

local function stateOf(p: Player): State
	local st = states[p]
	if not st then
		st = { nextCrush = os.clock() + 2, drops = {}, count = 0, nextId = 0, budget = Mine.CollectPerSecond, budgetAt = os.clock() }
		states[p] = st
	end
	return st
end

local function unlocked(d: any): boolean return d ~= nil and Gems.mineOpen(d.crushers) end

function M.enter(p: Player)
	local d = api.data(p)
	if not d then return end
	if not unlocked(d) then
		Net.event("Notice"):FireClient(p, { text = "The GEM MINE opens at " .. Gems.UnlockText .. "." })
		return
	end
	api.teleport(p, crusher.arrive) -- on the portal, facing the crusher
	M.refresh(p)
end

-- teleporter text, magnet, awake look and the client's copy of your gems
function M.refresh(p: Player)
	local d = api.data(p) local plot = api.plot(p)
	if not d then return end
	local s = d.crushers
	local tp = plot and plot.gemTeleporter
	if tp then
		local yard = (s.plotLevel or 0) >= Gems.UnlockPlot
		tp.model.Parent = if yard then tp.home else nil
		tp.text.Text = if unlocked(d) then "GEM MINE" else "GEM MINE\n" .. Gems.UnlockText .. " TO UNLOCK"
	end
	p:SetAttribute("GemMagnet", Gems.mineMagnet(s))
	p:SetAttribute("GemsPerMinute", math.floor(Gems.minePerMinute(s) + 0.5))
	p:SetAttribute("GemAwake", Gems.mineAwake(s))
	local st = stateOf(p)
	local list = {}
	for id, drop in st.drops do table.insert(list, { id = id, pos = drop.pos, value = drop.value }) end
	Net.event("GemMine"):FireClient(p, { kind = "sync", drops = list })
end

local function crush(p: Player, d: any, st: State, now: number)
	local s = d.crushers
	st.nextCrush = now + Gems.mineCrushSeconds(s)
	-- the strike plays on your screen only (your pace); gems only while there is room
	local add = {}
	local value = Gems.mineValue(s)
	for _ = 1, math.min(Gems.dropsNow(s, math.random()), Mine.MaxDrops - st.count) do -- (11 Nov: 0.2-gem levels, the fraction is a chance)
		st.nextId += 1
		-- anywhere on the platform in front of the crusher (uniform over the disc)
		local a = math.random() * math.pi * 2
		local r = math.sqrt(math.random()) * (Mine.Zone.radius - 1.5)
		local pos = crusher.center + Vector3.new(math.cos(a) * r, 1.2, math.sin(a) * r)
		st.drops[st.nextId] = { pos = pos, value = value }
		st.count += 1
		table.insert(add, { id = st.nextId, pos = pos, value = value, from = crusher.ramRest.Position })
	end
	-- (vault audit 11 Nov: nothing sent while your mine is full)
	if #add > 0 then Net.event("GemMine"):FireClient(p, { kind = "add", drops = add }) end
end

local function collect(p: Player, ids: any)
	if type(ids) ~= "table" then return end
	local d = api.data(p) local st = states[p]
	local char = p.Character local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not d or not st or not hrp then return end
	local now = os.clock()
	st.budget = math.min(Mine.CollectPerSecond, st.budget + (now - st.budgetAt) * Mine.CollectPerSecond)
	st.budgetAt = now
	local reach = Gems.mineMagnet(d.crushers) + Mine.CollectSlack
	local got, taken, refused = 0, {}, {}
	for i, id in ids do
		if i > 40 then break end
		local drop = type(id) == "number" and st.drops[id]
		if drop then
			if st.budget >= 1 and (drop.pos - hrp.Position).Magnitude <= reach then
				st.budget -= 1
				got += drop.value
				st.drops[id] = nil st.count -= 1
				table.insert(taken, id)
			else
				table.insert(refused, id)
			end
		end
	end
	if got > 0 then
		local s = d.crushers
		local dust = (s.gemDust or 0) + got
		local whole = math.floor(dust)
		s.gems += whole s.gemDust = dust - whole
		p:SetAttribute("Gems", s.gems)
		if whole > 0 then Analytics.gems(p, "Mine", "Gameplay", whole, s.gems) end
		-- (the Gem Shop and HUD read the Gems attribute; no full state push per pickup)
	end
	Net.event("GemMine"):FireClient(p, { kind = "collected", ids = taken, refused = refused })
end

function M.start(a: Api)
	api = a
	buildWorld()
	buildTeleporters()
	Net.event("GemMine").OnServerEvent:Connect(function(p, kind, arg)
		if kind == "collect" then collect(p, arg) elseif kind == "sync" then M.refresh(p)
		elseif kind == "autoWalk" and walkToggle then walkToggle(p) end -- (11 Nov: the on-screen button)
	end)
	Players.PlayerRemoving:Connect(function(p) states[p] = nil end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt if acc < 0.25 then return end acc = 0
		local now = os.clock()
		for _, p in Players:GetPlayers() do
			local d = api.data(p)
			if unlocked(d) then
				local st = stateOf(p)
				if now >= st.nextCrush then crush(p, d, st, now) end
			end
		end
	end)
end

M.crusher = function() return crusher end
M.states = states
return M
