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
}
local api: Api
type Drop = { pos: Vector3, value: number }
type State = { nextCrush: number, drops: { [number]: Drop }, count: number, nextId: number, budget: number, budgetAt: number }
local states: { [Player]: State } = {}
type Crusher = { model: Model, center: Vector3, -- center: the platform's top middle
	 ramRest: CFrame, arrive: CFrame }
local crusher: Crusher
local root: Folder

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

-- the portal (the same look on your plot and in the mine): navy base, neon ring, gold frame
local function buildPortal(parent: Instance, at: CFrame, title: string, action: string): (Model, TextLabel, ProximityPrompt)
	local m = Instance.new("Model")
	local padT = tpl("TeleporterPad")
	if padT and padT:IsA("BasePart") then
		-- Willem's pad (one mesh for both ends); an invisible anchor above the deck holds the
		-- prompt and the sign
		local pad = padT:Clone()
		pad.Name = "Pad" pad.Anchored = true
		pad:PivotTo(at * CFrame.new(0, pad.Size.Y / 2, 0))
		pad.Parent = m
		local anchor = Build.block(m, "Base", Vector3.new(6, 0.4, 6), at * CFrame.new(0, pad.Size.Y + 0.3, 0), MAGENTA)
		anchor.Transparency = 1 anchor.CanCollide = false anchor.CanQuery = false
		local text = label(anchor, title, RGB(255, 170, 245), 6.5, Vector2.new(14, 3))
		local pr = prompt(anchor, action, "Gem Mine")
		m.PrimaryPart = anchor
		m.Parent = parent
		return m, text, pr
	end
	local base = Build.block(m, "Base", Vector3.new(1, 9, 9), at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), NAVY)
	base.Shape = Enum.PartType.Cylinder
	local ring = Build.block(m, "Ring", Vector3.new(1.1, 7, 7), at * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
	ring.Shape = Enum.PartType.Cylinder ring.Material = Enum.Material.Neon
	for _, x in { -4, 4 } do Build.block(m, "Post", Vector3.new(0.8, 7, 0.8), at * CFrame.new(x, 4, 0), GOLD).Material = Enum.Material.Metal end
	local top = Build.block(m, "Top", Vector3.new(9, 0.8, 1), at * CFrame.new(0, 7.8, 0), GOLD)
	top.Material = Enum.Material.Metal
	local text = label(top, title, RGB(255, 170, 245), 3.5, Vector2.new(14, 3))
	local pr = prompt(base, action, "Gem Mine")
	m.PrimaryPart = base
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
	local floor = Build.block(root, "MineFloor", Vector3.new(4, Mine.Radius * 2, Mine.Radius * 2), o * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), RGB(58, 40, 96))
	floor.Shape = Enum.PartType.Cylinder floor.Material = Enum.Material.Slate
	local edge = Build.block(root, "MineEdge", Vector3.new(3.6, Mine.Radius * 2 + 3, Mine.Radius * 2 + 3), o * CFrame.new(0, -2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
	edge.Shape = Enum.PartType.Cylinder edge.Material = Enum.Material.Neon deco(edge)
	-- glowing veins from the platform out to the rim
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local r0 = Mine.Zone.radius + 3
		local len = rng:NextNumber(18, Mine.Radius - r0 - 8)
		local mid = Mine.Zone.center * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.03, -(r0 + len / 2))
		local v = Build.block(root, "Vein", Vector3.new(rng:NextNumber(0.35, 0.7), 0.1, len), o * mid, if i % 3 == 0 then CYAN else PINK)
		v.Material = Enum.Material.Neon v.Transparency = 0.25 deco(v)
	end
	-- the rim: cave rocks with crystal clusters in front of them, and big crystal spires
	for i = 1, 22 do
		local a = i / 22 * math.pi * 2
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
	local trim = Build.block(root, "ZoneTrim", Vector3.new(Mine.Zone.height, zr * 2 + 2, zr * 2 + 2), zc * CFrame.new(0, Mine.Zone.height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD)
	trim.Shape = Enum.PartType.Cylinder trim.Material = Enum.Material.Metal
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
	for i = 1, 10 do
		local a = math.rad(-120 + (i - 1) * 26)
		local at = zc * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -(zr + 2.2))
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
	light(top, 8, 36, RGB(255, 150, 240), 1.8)

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
	for _, x in { -2.6, 2.6 } do Build.block(root, "SignPost", Vector3.new(0.6, 6, 0.6), signAt * CFrame.new(x, 3, 0), GOLD).Material = Enum.Material.Metal end
	local frame = Build.block(root, "SignFrame", Vector3.new(6, 4, 0.5), signAt * CFrame.new(0, 5, 0), GOLD)
	frame.Material = Enum.Material.Metal
	local shop = Build.block(root, "UpgradeSign", Vector3.new(5.2, 3.2, 0.6), signAt * CFrame.new(0, 5, 0), NAVY)
	local signGem = tpl("GemPickup")
	if signGem and signGem:IsA("BasePart") then
		local g = signGem:Clone() g.Anchored = true g.Size *= 2.2 deco(g)
		g.CFrame = signAt * CFrame.new(0, 8.2, 0) g.Parent = root
	end
	local signText = label(shop, "GEM UPGRADES", RGB(255, 236, 120), 0, Vector2.new(5, 2.2))
	local signGui = signText.Parent :: BillboardGui
	signGui.AlwaysOnTop = true signGui.MaxDistance = 90 -- on the board, not hidden by it
	prompt(shop, "Upgrades", "Gem Shop").Triggered:Connect(function(p)
		Net.event("GemMine"):FireClient(p, { kind = "openShop" })
	end)
	crusher = { model = m, center = zc.Position + Vector3.new(0, Mine.Zone.height, 0), ramRest = ram.CFrame,
		arrive = CFrame.lookAt((portalAt * CFrame.new(0, 3, -6)).Position, zc.Position + Vector3.new(0, 3, 0)) }
	root.Parent = workspace
end

-- the teleporter on every plot (front left, inside the entrance)
local function buildTeleporters()
	for _, plot in api.plots() do
		local at = plot.origin * CFrame.new(Mine.Teleporter.x, 0, Mine.Teleporter.z)
		local m, text, pr = buildPortal(plot.model, at, "GEM MINE", "Teleport")
		m.Name = "GemMineTeleporter"
		m:SetAttribute("PlotIndex", plot.index)
		pr.Triggered:Connect(function(p) M.enter(p) end)
		plot.gemTeleporter = { text = text, prompt = pr }
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

local function unlocked(d: any): boolean return d ~= nil and (d.crushers.rebirths or 0) >= Gems.UnlockRebirths end

function M.enter(p: Player)
	local d = api.data(p)
	if not d then return end
	if not unlocked(d) then
		Net.event("Notice"):FireClient(p, { text = "The GEM MINE opens at REBIRTH " .. Gems.UnlockRebirths .. "." })
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
		tp.text.Text = if unlocked(d) then "GEM MINE" else "GEM MINE\nREBIRTH " .. Gems.UnlockRebirths .. " TO UNLOCK"
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
	for _ = 1, math.min(Gems.mineDrops(s), Mine.MaxDrops - st.count) do
		st.nextId += 1
		-- anywhere on the platform in front of the crusher (uniform over the disc)
		local a = math.random() * math.pi * 2
		local r = math.sqrt(math.random()) * (Mine.Zone.radius - 1.5)
		local pos = crusher.center + Vector3.new(math.cos(a) * r, 1.2, math.sin(a) * r)
		st.drops[st.nextId] = { pos = pos, value = value }
		st.count += 1
		table.insert(add, { id = st.nextId, pos = pos, value = value, from = crusher.ramRest.Position })
	end
	Net.event("GemMine"):FireClient(p, { kind = "add", drops = add })
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
		if kind == "collect" then collect(p, arg) elseif kind == "sync" then M.refresh(p) end
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
