--!strict
-- 9 Nov: THE GEM MINE (Willem: "teleporter to a new world with the Gem Crusher; it crushes
-- gems, you have to pick them up"). All Gems come from here (GemConfig.Mine).
--
--   * One shared area far outside the toy room (it only streams in when you are there).
--     Six pads on a ring, one per plot index; your pad holds your Gem Crusher.
--   * A teleporter on every plot (front left) opens at rebirth 1; a portal in the middle of
--     the mine takes you home. Server-side ProximityPrompts, server-side teleports.
--   * Every crush the server makes your gems: records only (position, value), at most
--     MaxDrops waiting. Your client draws them (only you see your gems) and picks them up
--     when you walk within the magnet radius; the server checks each pickup's distance
--     and a rate budget (vault: Collectible Pickup FX - server owns records, validates
--     batched requests; per-player pickups are never server instances).
--   * Rebirth 5 awakens the crusher (opal crystals, x1.5 gem value).
--   * Stand-in machine built from parts until Willem's Gem Crusher model is imported.
--
-- Remote "GemMine": server -> client {kind="sync"|"add"|"collected"|"openShop"|"crush"};
-- client -> server ("collect", {ids}).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
type Pad = { index: number, cf: CFrame, model: Model, ram: BasePart, ramRest: CFrame, crystals: { BasePart }, label: TextLabel, awake: boolean? }
local pads: { [number]: Pad } = {}
local root: Folder

local RGB = Color3.fromRGB
local NAVY, GOLD, MAGENTA, PINK = RGB(38, 34, 78), RGB(255, 196, 40), RGB(225, 60, 210), RGB(255, 140, 235)
local OPAL, CYAN = RGB(240, 236, 255), RGB(140, 240, 255)
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
-- crystal pressing block over an anvil). Front faces -Z of `cf`.
local function buildCrusher(parent: Instance, cf: CFrame): (Model, BasePart, { BasePart })
	local m = Instance.new("Model")
	m.Name = "GemCrusher"
	local crystals = {}
	local function part(name: string, size: Vector3, at: CFrame, color: Color3, mat: Enum.Material?): Part
		local p = Build.block(m, name, size, cf * at, color)
		p.Material = mat or Enum.Material.SmoothPlastic
		p.CanCollide = name == "Base" or name:find("Pillar") ~= nil
		return p
	end
	part("Base", Vector3.new(11, 1.2, 7), CFrame.new(0, 0.6, 0), NAVY)
	for _, x in { -4.2, 4.2 } do
		part("Pillar", Vector3.new(2.2, 9, 2.6), CFrame.new(x, 5.7, 0), NAVY)
		part("PillarGold", Vector3.new(2.4, 0.5, 2.8), CFrame.new(x, 3.4, 0), GOLD, Enum.Material.Metal)
		local inlay = part("Inlay", Vector3.new(0.4, 2, 1.1), CFrame.new(x, 5.6, -1.35), MAGENTA, Enum.Material.Neon)
		table.insert(crystals, inlay)
		part("Piston", Vector3.new(1.2, 3.2, 1.2), CFrame.new(x * 0.62, 8.3, -0.2), GOLD, Enum.Material.Metal)
	end
	part("Arch", Vector3.new(11, 2.2, 3), CFrame.new(0, 11.1, 0), NAVY)
	local core = part("Core", Vector3.new(2.8, 2.8, 2.8), CFrame.new(0, 11.4, -1.4) * CFrame.Angles(math.rad(45), math.rad(45), 0), MAGENTA, Enum.Material.Neon)
	table.insert(crystals, core)
	local anvil = part("Anvil", Vector3.new(6, 0.9, 4), CFrame.new(0, 2.3, -0.2), MAGENTA, Enum.Material.Glass)
	table.insert(crystals, anvil)
	local ram = part("Ram", Vector3.new(6.4, 1.6, 4.2), CFrame.new(0, 6.6, -0.2), MAGENTA, Enum.Material.Glass)
	table.insert(crystals, ram)
	m.PrimaryPart = m:FindFirstChild("Base") :: BasePart
	m.Parent = parent
	return m, ram, crystals
end

local function awaken(pad: Pad, awake: boolean)
	if pad.awake == awake then return end
	pad.awake = awake
	for _, c in pad.crystals do c.Color = if awake then (if c.Name == "Core" or c.Name == "Inlay" then CYAN else OPAL) else MAGENTA end
end

local function buildWorld()
	root = Instance.new("Folder")
	root.Name = "GemMine"
	local o = Mine.Origin
	-- floor: a crystal cave platform with a rim of rocks and crystal clusters
	local floor = Build.block(root, "MineFloor", Vector3.new(Mine.Radius * 2, 4, Mine.Radius * 2), o * CFrame.new(0, -2, 0), RGB(54, 40, 92))
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(4, Mine.Radius * 2, Mine.Radius * 2)
	floor.CFrame = o * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90))
	local rng = Random.new(9)
	for i = 1, 26 do
		local a = i / 26 * math.pi * 2
		local at = o * CFrame.new(math.cos(a) * (Mine.Radius - 4), 0, math.sin(a) * (Mine.Radius - 4))
		Build.rock(root, at, 2.2 + rng:NextNumber() * 1.6, { rock = ROCK }, rng)
		if i % 2 == 0 then
			local h = 6 + rng:NextNumber() * 8
			local c = Build.block(root, "Crystal", Vector3.new(2.2, h, 2.2), at * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), a, math.rad(rng:NextNumber(-20, 20))), if i % 4 == 0 then CYAN else PINK)
			c.Material = Enum.Material.Neon c.CanCollide = false
		end
	end
	-- the way home: a portal in the middle
	local portal = Build.block(root, "HomePortal", Vector3.new(1, 12, 12), o * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD)
	portal.Shape = Enum.PartType.Cylinder portal.Material = Enum.Material.Metal
	local ring = Build.block(root, "HomeRing", Vector3.new(1.2, 9, 9), o * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
	ring.Shape = Enum.PartType.Cylinder ring.Material = Enum.Material.Neon
	label(portal, "BACK TO YOUR FACTORY", RGB(255, 236, 120), 6, Vector2.new(18, 3))
	prompt(portal, "Go home", "Gem Mine").Triggered:Connect(function(p) api.home(p) end)
	-- the six pads
	for i = 1, 6 do
		local a = (i - 1) / 6 * math.pi * 2
		local pos = (o * CFrame.new(math.cos(a) * Mine.PadRing, 0, math.sin(a) * Mine.PadRing)).Position
		-- the crusher's back faces outward, its front (-Z) towards the middle
		local cf = CFrame.lookAt(pos, o.Position) -- LookVector points to the middle (= -Z)
		local padPart = Build.block(root, "Pad" .. i, Vector3.new(16, 1, 14), cf * CFrame.new(0, 0.5, 2), NAVY)
		local m, ram, crystals = buildCrusher(root, cf * CFrame.new(0, 1, 3))
		m.Name = "GemCrusher" .. i
		local shop = Build.block(root, "UpgradeSign" .. i, Vector3.new(4, 5, 0.6), cf * CFrame.new(9.5, 3.5, -2) * CFrame.Angles(0, math.rad(-25), 0), GOLD)
		label(shop, "GEM UPGRADES", RGB(255, 236, 120), 4, Vector2.new(10, 2.2))
		prompt(shop, "Upgrades", "Gem Shop").Triggered:Connect(function(p)
			Net.event("GemMine"):FireClient(p, { kind = "openShop" })
		end)
		local pad: Pad = { index = i, cf = cf, model = m, ram = ram, ramRest = ram.CFrame, crystals = crystals,
			label = label(padPart, "", RGB(255, 200, 250), 14, Vector2.new(20, 3)) }
		pads[i] = pad
	end
	root.Parent = workspace
end

-- the teleporter on every plot (front left, inside the entrance)
local function buildTeleporters()
	for _, plot in api.plots() do
		local at = plot.origin * CFrame.new(Mine.Teleporter.x, 0, Mine.Teleporter.z)
		local m = Instance.new("Model")
		m.Name = "GemMineTeleporter"
		local base = Build.block(m, "Base", Vector3.new(1, 9, 9), at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), NAVY)
		base.Shape = Enum.PartType.Cylinder
		local ring = Build.block(m, "Ring", Vector3.new(1.1, 7, 7), at * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), MAGENTA)
		ring.Shape = Enum.PartType.Cylinder ring.Material = Enum.Material.Neon
		for _, x in { -4, 4 } do Build.block(m, "Post", Vector3.new(0.8, 7, 0.8), at * CFrame.new(x, 4, 0), GOLD).Material = Enum.Material.Metal end
		local top = Build.block(m, "Top", Vector3.new(9, 0.8, 1), at * CFrame.new(0, 7.8, 0), GOLD)
		top.Material = Enum.Material.Metal
		local text = label(top, "GEM MINE", RGB(255, 170, 245), 3.5, Vector2.new(14, 3))
		local pr = prompt(base, "Teleport", "Gem Mine")
		pr.Triggered:Connect(function(p) M.enter(p) end)
		m:SetAttribute("PlotIndex", plot.index)
		m.Parent = plot.model
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
	local d = api.data(p) local plot = api.plot(p)
	if not d or not plot then return end
	if not unlocked(d) then
		Net.event("Notice"):FireClient(p, { text = "The GEM MINE opens at REBIRTH " .. Gems.UnlockRebirths .. "." })
		return
	end
	local pad = pads[plot.index] if not pad then return end
	-- stand in front of your crusher, facing it
	local spot = pad.cf * CFrame.new(0, 3, -12)
	api.teleport(p, CFrame.lookAt(spot.Position, pad.cf.Position + Vector3.new(0, 3, 0)))
	M.refresh(p)
end

-- name, awake look, teleporter text, magnet, and the client's copy of your gems
function M.refresh(p: Player)
	local d = api.data(p) local plot = api.plot(p)
	if not d or not plot then return end
	local s = d.crushers
	local pad = pads[plot.index]
	if pad then
		pad.label.Text = p.DisplayName .. "'s " .. (if Gems.mineAwake(s) then "AWAKENED " else "") .. "GEM CRUSHER"
		awaken(pad, Gems.mineAwake(s))
	end
	local tp = plot.gemTeleporter
	if tp then
		local open = unlocked(d)
		tp.text.Text = if open then "GEM MINE" else "GEM MINE\nREBIRTH " .. Gems.UnlockRebirths .. " TO UNLOCK"
	end
	p:SetAttribute("GemMagnet", Gems.mineMagnet(s))
	p:SetAttribute("GemsPerMinute", math.floor(Gems.minePerMinute(s) + 0.5))
	local st = stateOf(p)
	local list = {}
	for id, drop in st.drops do table.insert(list, { id = id, pos = drop.pos, value = drop.value }) end
	Net.event("GemMine"):FireClient(p, { kind = "sync", drops = list, pad = if pad then pad.cf.Position else nil })
end

local function crush(p: Player, d: any, st: State, now: number)
	local s = d.crushers
	st.nextCrush = now + Gems.mineCrushSeconds(s)
	local plot = api.plot(p) local pad = plot and pads[plot.index]
	if not pad then return end
	-- the ram comes down (everyone sees it)
	local down = pad.ramRest * CFrame.new(0, -3.3, 0)
	TweenService:Create(pad.ram, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = down }):Play()
	task.delay(0.3, function() TweenService:Create(pad.ram, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { CFrame = pad.ramRest }):Play() end)
	if st.count >= Mine.MaxDrops then return end
	local add = {}
	local value = Gems.mineValue(s)
	for _ = 1, math.min(Gems.mineDrops(s), Mine.MaxDrops - st.count) do
		st.nextId += 1
		local a = (math.random() - 0.5) * math.rad(110)
		local r = 4 + math.random() * Mine.Scatter
		local pos = (pad.cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 1.2, -r)).Position
		st.drops[st.nextId] = { pos = pos, value = value }
		st.count += 1
		table.insert(add, { id = st.nextId, pos = pos, value = value, from = pad.ramRest.Position })
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

M.pads = pads
M.states = states
return M
