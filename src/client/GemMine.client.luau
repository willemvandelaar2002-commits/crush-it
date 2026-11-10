--!strict
-- 9 Nov: THE GEM MINE, your side (server/GemMine). Only you see your gems. One shared loop
-- spins and bobs them, pulls them in when you are within your magnet radius (attribute
-- GemMagnet) and sends the picked ones to the server in small batches; the server checks
-- them and adds the Gems (vault: Collectible Pickup FX - idle glint, magnet pull, collect pop;
-- one shared loop, no per-gem tweens, no server Touched).
-- 10 Nov: one Gem Crusher that everyone uses. Its strike plays here, for your crushes only
-- (your pace), and it turns opal on your screen once yours is awakened (attribute GemAwake).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local remote = Net.event("GemMine")
local folder = Instance.new("Folder")
folder.Name = "MyGems"
folder.Parent = workspace

type Gem = { part: BasePart, pos: Vector3, value: number, born: number, from: Vector3?, pulling: boolean, pull: number, pending: boolean, sent: boolean?, confirmed: boolean? }
local gems: { [number]: Gem } = {}
local queue: { number } = {}
local COLOR = Color3.fromRGB(255, 90, 230)

-- the shared crusher (streams in only near the mine)
local function machine(): Model?
	local mine = workspace:FindFirstChild("GemMine")
	return mine and mine:FindFirstChild("GemCrusher") :: Model?
end

-- the moving parts: the Ram (and on Willem's model both pistons) go down together by the
-- model's Strike attribute, along the machine's own up axis, then back to the captured pose
local rests: { [BasePart]: CFrame } = {}
local striking = false
local function strike()
	local m = machine()
	if not m or striking then return end
	local moving = {}
	for _, n in { "Ram", "Piston_L", "Piston_R" } do
		local part = m:FindFirstChild(n)
		if part and part:IsA("BasePart") then
			rests[part] = rests[part] or part.CFrame
			table.insert(moving, part)
		end
	end
	if #moving == 0 then return end
	local pivot = m:GetPivot()
	local offset = pivot.UpVector * -(tonumber(m:GetAttribute("Strike")) or 3.3)
	striking = true
	for _, part in moving do
		TweenService:Create(part, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = rests[part] + offset }):Play()
	end
	task.delay(0.26, function()
		for i, part in moving do
			local up = TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { CFrame = rests[part] })
			if i == 1 then up.Completed:Connect(function() striking = false end) end
			up:Play()
		end
	end)
end

local OPAL, CYAN, MAGENTA = Color3.fromRGB(240, 236, 255), Color3.fromRGB(140, 240, 255), Color3.fromRGB(225, 60, 210)
local stashed: { [Instance]: Instance? } = {}
local function paint()
	local m = machine()
	if not m then return end
	local awake = me:GetAttribute("GemAwake") == true
	local look = RS:FindFirstChild("GemMineMeshes") and RS.GemMineMeshes:FindFirstChild("AwakenedLook")
	if m:FindFirstChild("Frame") and look and look:IsA("SurfaceAppearance") then
		-- Willem's model: swap Frame's and Ram's SurfaceAppearance for the recoloured one (a
		-- SurfaceAppearance's maps can't be set by a script, but a whole one can be swapped)
		for _, n in { "Frame", "Ram" } do
			local part = m:FindFirstChild(n)
			if part then
				local normal = part:FindFirstChild("NormalLook") or part:FindFirstChildWhichIsA("SurfaceAppearance")
				if normal and normal.Name ~= "AwakenedLook" then normal.Name = "NormalLook" end
				local awakeSA = part:FindFirstChild("AwakenedLook")
				if awake and not awakeSA then
					if normal then normal.Parent = nil end
					look:Clone().Parent = part
					stashed[part] = normal
				elseif not awake and awakeSA then
					awakeSA:Destroy()
					local back = stashed[part]
					if back then back.Parent = part stashed[part] = nil end
				end
			end
		end
	elseif m:FindFirstChild("Frame") then
		-- no recoloured texture: an opal glow over it instead
		local h = m:FindFirstChild("AwakeGlow") :: Highlight?
		if awake and not h then
			local nh = Instance.new("Highlight")
			nh.Name = "AwakeGlow" nh.FillColor = OPAL nh.FillTransparency = 0.7
			nh.OutlineColor = CYAN nh.OutlineTransparency = 0.2
			nh.DepthMode = Enum.HighlightDepthMode.Occluded
			nh.Parent = m
		elseif not awake and h then
			h:Destroy()
		end
	else
		for _, c in m:GetChildren() do
			if c:IsA("BasePart") and (c.Name == "Inlay" or c.Name == "Core" or c.Name == "Anvil" or c.Name == "Ram") then
				c.Color = if not awake then MAGENTA elseif c.Name == "Core" or c.Name == "Inlay" then CYAN else OPAL
			end
		end
	end
	local base = m.PrimaryPart or m:FindFirstChild("Base")
	local text = base and base:FindFirstChild("Text", true) :: TextLabel?
	if text then text.Text = if awake then "YOUR AWAKENED GEM CRUSHER" else "GEM CRUSHER" end
end
me:GetAttributeChangedSignal("GemAwake"):Connect(paint)
workspace.DescendantAdded:Connect(function(d) if d.Name == "GemCrusher" and d:IsA("Model") then task.defer(paint) end end)

-- Willem's pickup gem (ReplicatedStorage.GemMineMeshes.GemPickup, 46 triangles) or a neon cube
local meshes = RS:FindFirstChild("GemMineMeshes")
local gemTemplate = meshes and meshes:FindFirstChild("GemPickup") :: BasePart?
local function makePart(): BasePart
	local p: BasePart
	if gemTemplate then
		p = gemTemplate:Clone()
	else
		p = Instance.new("Part")
		p.Material = Enum.Material.Neon
		p.Color = COLOR
	end
	p.Name = "Gem"
	p.Size = Vector3.new(1, 1, 1)
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Parent = folder
	return p
end

local function add(id: number, pos: Vector3, value: number, from: Vector3?)
	if gems[id] then return end
	local part = makePart()
	-- bigger gems for bigger values
	local s = math.clamp(0.8 + 0.25 * (value - 1), 0.8, 1.6) * (if gemTemplate then 2.2 else 1.3) -- 10 Nov: bigger (Willem)
	part.Size = if gemTemplate then gemTemplate.Size.Unit * s * math.sqrt(3) else Vector3.new(s, s, s)
	gems[id] = { part = part, pos = pos, value = value, born = os.clock(), from = from, pulling = false, pull = 0, pending = false }
end

local function remove(id: number)
	local g = gems[id]
	if g then g.part:Destroy() gems[id] = nil end
end

remote.OnClientEvent:Connect(function(msg)
	if type(msg) ~= "table" then return end
	if msg.kind == "sync" then
		for id in gems do remove(id) end
		for _, d in msg.drops or {} do add(d.id, d.pos, d.value, nil) end
		paint()
	elseif msg.kind == "add" then
		strike()
		for _, d in msg.drops or {} do add(d.id, d.pos, d.value, d.from) end
	elseif msg.kind == "collected" then
		-- the server's answer can come while the gem is still flying in: it goes when it arrives
		for _, id in msg.ids or {} do
			local g = gems[id]
			if g and g.pending then remove(id) elseif g then g.confirmed = true end
		end
		for _, id in msg.refused or {} do
			local g = gems[id]
			if g then g.pending = false g.sent = false g.pulling = false g.pull = 0 g.part.Transparency = 0 end
		end
	elseif msg.kind == "openShop" then
		local hud = me.PlayerGui:FindFirstChild("GemShopHud")
		if hud then hud:SetAttribute("Open", true) end
	end
end)

-- 10 Nov (Willem: "we need sounds for the gems picking up"): a crystal ding per gem you pick up.
-- Quick pickups in a row climb in pitch (a streak, like coins in a platformer); a gem worth more
-- rings a little lower and louder. At most one ding per 0.05 s (a magnet sweep stays a tune, not noise).
local Config = require(RS.Shared.Config)
local SoundService = game:GetService("SoundService")
local streak, lastDing, lastPick = 0, 0, 0
-- 10 Nov evening (Willem: "a little too loud and have a delay"): a new Sound per ding had to
-- load first (0.3 s) and the file swells in (its peak is ~0.13 s in). Now a few copies are made
-- and preloaded up front and used in turn, each ding starts 0.07 s in (where it is already loud),
-- and it is quieter.
local DING_START, DING_VOLUME = 0.07, 0.22
local dings: { Sound } = {}
for i = 1, 6 do
	local snd = Instance.new("Sound")
	snd.Name = "GemDing" snd.SoundId = "rbxassetid://" .. tostring(Config.Sounds.GemPickup)
	snd.Volume = DING_VOLUME
	snd.Parent = SoundService
	dings[i] = snd
end
task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({ dings[1] }) end) end)
local nextDing = 1
local function ding(value: number)
	local now = os.clock()
	streak = if now - lastPick < 0.7 then math.min(streak + 1, 12) else 0
	lastPick = now
	if now - lastDing < 0.05 then return end
	lastDing = now
	local snd = dings[nextDing]
	nextDing = nextDing % #dings + 1
	snd.Volume = if value > 1 then DING_VOLUME * 1.3 else DING_VOLUME
	snd.PlaybackSpeed = (1 + streak * 0.04) * (if value > 1 then 0.92 else 1) * (0.98 + math.random() * 0.04)
	snd.TimePosition = DING_START
	snd:Play()
	snd.TimePosition = DING_START
end

local lastSend = 0
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local char = me.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local magnet = tonumber(me:GetAttribute("GemMagnet")) or 5
	for id, g in gems do
		if g.pending then continue end
		local age = now - g.born
		local spin = CFrame.Angles(math.rad(45), now * 2 + id, math.rad(35))
		if g.from and age < 0.7 then
			-- flies out of the crusher in an arc (11 Nov: higher and longer for the bigger platform)
			local t = age / 0.7
			local arc = 4 + (g.pos - g.from).Magnitude * 0.12
			local p = g.from:Lerp(g.pos, t) + Vector3.new(0, math.sin(t * math.pi) * arc, 0)
			g.part.CFrame = CFrame.new(p) * spin
			continue
		end
		local rest = g.pos + Vector3.new(0, math.sin(now * 3 + id) * 0.25, 0)
		if root and not g.pulling and (root.Position - g.pos).Magnitude <= magnet then
			g.pulling = true
			-- vault audit 11 Nov (Collectible Pickup FX): ask the server when the pull STARTS, while
			-- you are surely in range, not on arrival (laggy players would be refused)
			if not g.sent then g.sent = true table.insert(queue, id) end
		end
		if g.pulling and root then
			g.pull = math.min(1, g.pull + dt * 3) -- accelerates: not a sticky constant lerp
			local cur = g.part.Position
			local target = root.Position
			local step = (target - cur) * math.min(1, g.pull * g.pull * 0.6 + dt * 6)
			g.part.CFrame = CFrame.new(cur + step) * spin
			if (target - g.part.Position).Magnitude < 1.6 then
				g.pending = true g.part.Transparency = 1
				ding(g.value)
				if g.confirmed then remove(id) end
			end
		else
			g.part.CFrame = CFrame.new(rest) * spin
		end
	end
	if #queue > 0 and now - lastSend > 0.12 then
		lastSend = now
		remote:FireServer("collect", queue)
		queue = {}
	end
end)

-- 10 Nov (Willem: "you can still see the normal plots from a distance... maybe a dark sky above
-- the gem island"): while you are in the mine your sky turns into a starry purple night with a
-- dense haze, so the far-away factories fade out. Local only; restored when you leave. If a
-- factory event's night is already on (BearEventSky), that night stays and nothing is swapped.
local Lighting = game:GetService("Lighting")
local GemConfig = require(RS.Shared.GemConfig)
local MINE_NIGHT = { ClockTime = 0, Brightness = 2, Ambient = Color3.fromRGB(110, 80, 150),
	OutdoorAmbient = Color3.fromRGB(130, 95, 180), ExposureCompensation = 0.1 }
local mineSky: Sky? = nil
local mineAtmo: Atmosphere? = nil
local saved: { props: { [string]: any }, kids: { Instance } }? = nil
local function inMine(): boolean
	local char = me.Character
	local r = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r then return false end
	local o = GemConfig.Mine.Origin.Position
	return (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(o.X, 0, o.Z)).Magnitude < GemConfig.Mine.Radius + 40
end
local function mineLookOn()
	if saved or Lighting:FindFirstChild("BearEventSky") then return end
	local sv = { props = {}, kids = {} }
	for k in MINE_NIGHT do sv.props[k] = (Lighting :: any)[k] end
	for _, c in Lighting:GetChildren() do
		if c:IsA("Sky") or c:IsA("Atmosphere") then table.insert(sv.kids, c) c.Parent = nil end
	end
	local sky = Instance.new("Sky") sky.Name = "GemMineSky"
	sky.StarCount = 5000 sky.SunAngularSize = 0 sky.MoonAngularSize = 14 sky.Parent = Lighting
	local atmo = Instance.new("Atmosphere") atmo.Name = "GemMineAtmosphere"
	atmo.Density = 0.42 atmo.Offset = 0.1 atmo.Color = Color3.fromRGB(70, 40, 110) atmo.Decay = Color3.fromRGB(25, 12, 45)
	atmo.Glare = 0 atmo.Haze = 2.2 atmo.Parent = Lighting
	mineSky, mineAtmo = sky, atmo
	saved = sv
	TweenService:Create(Lighting, TweenInfo.new(0.5), MINE_NIGHT):Play()
end
local function mineLookOff()
	local sv = saved
	if mineSky then mineSky.Parent = nil end
	if mineAtmo then mineAtmo.Parent = nil end
	if not sv then return end
	saved = nil
	for _, c in sv.kids do if c.Parent == nil then pcall(function() c.Parent = Lighting end) end end
	TweenService:Create(Lighting, TweenInfo.new(0.8), sv.props):Play()
end
-- the mine's own song (GemConfig.Mine.Music): fades in while you are in the mine; the normal
-- (and an event's) music pauses meanwhile and carries on where it was when you leave
local SoundService = game:GetService("SoundService")
local mineSong: Sound? = nil
if (GemConfig.Mine.Music or 0) ~= 0 then
	local snd = Instance.new("Sound")
	snd.Name = "MineMusic" snd.SoundId = "rbxassetid://" .. tostring(GemConfig.Mine.Music)
	snd.Looped = true snd.Volume = 0 snd.Parent = SoundService
	mineSong = snd
end
local paused: { Sound } = {}
local songOn = false
local function mineMusic(on: boolean)
	local snd = mineSong
	if not snd or on == songOn then return end
	songOn = on
	if on then
		for _, n in { "BackgroundMusic", "EventMusic" } do
			local other = SoundService:FindFirstChild(n)
			if other and other:IsA("Sound") and other.IsPlaying then other:Pause() table.insert(paused, other) end
		end
		if not snd.IsPlaying then snd:Play() end
		TweenService:Create(snd, TweenInfo.new(1.2), { Volume = GemConfig.Mine.MusicVolume or 0.3 }):Play()
	else
		TweenService:Create(snd, TweenInfo.new(0.8), { Volume = 0 }):Play()
		task.delay(0.8, function() if not songOn then snd:Pause() end end)
		for _, other in paused do other:Resume() end
		paused = {}
	end
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local here = inMine()
		if here then mineLookOn() elseif saved or (mineSky and mineSky.Parent) then mineLookOff() end
		mineMusic(here)
	end
end)

-- the floating gems around the mine: a slow spin and bob (one loop, only while you are there)
local floatRest: { [BasePart]: CFrame } = {}
RunService.Heartbeat:Connect(function()
	if not saved then return end -- (saved = the mine sky is on = you are in the mine)
	local mine = workspace:FindFirstChild("GemMine")
	local f = mine and mine:FindFirstChild("FloatGems")
	if not f then return end
	local now = os.clock()
	for i, g in f:GetChildren() do
		if g:IsA("BasePart") then
			local rest = floatRest[g] or g.CFrame
			floatRest[g] = rest
			g.CFrame = CFrame.new(rest.Position + Vector3.new(0, math.sin(now * 0.8 + i) * 1.2, 0)) * CFrame.Angles(0, now * 0.6 + i, 0)
		end
	end
end)

-- ask for our gems once everything is up (the server also syncs on teleport / rebirth)
task.delay(3, function() remote:FireServer("sync") end)
