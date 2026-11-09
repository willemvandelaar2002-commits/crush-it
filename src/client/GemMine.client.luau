--!strict
-- 9 Nov: THE GEM MINE, your side (server/GemMine). Only you see your gems. One shared loop
-- spins and bobs them, pulls them in when you are within your magnet radius (attribute
-- GemMagnet) and sends the picked ones to the server in small batches; the server checks
-- them and adds the Gems (vault: Collectible Pickup FX - idle glint, magnet pull, collect pop;
-- one shared loop, no per-gem tweens, no server Touched).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local remote = Net.event("GemMine")
local folder = Instance.new("Folder")
folder.Name = "MyGems"
folder.Parent = workspace

type Gem = { part: BasePart, pos: Vector3, value: number, born: number, from: Vector3?, pulling: boolean, pull: number, pending: boolean }
local gems: { [number]: Gem } = {}
local queue: { number } = {}
local COLOR = Color3.fromRGB(255, 90, 230)

local function makePart(): BasePart
	local p = Instance.new("Part")
	p.Name = "Gem"
	p.Size = Vector3.new(1, 1, 1)
	p.Material = Enum.Material.Neon
	p.Color = COLOR
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Parent = folder
	return p
end

local function add(id: number, pos: Vector3, value: number, from: Vector3?)
	if gems[id] then return end
	local part = makePart()
	-- bigger gems for bigger values
	local s = math.clamp(0.8 + 0.25 * (value - 1), 0.8, 1.6)
	part.Size = Vector3.new(s, s, s)
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
	elseif msg.kind == "add" then
		for _, d in msg.drops or {} do add(d.id, d.pos, d.value, d.from) end
	elseif msg.kind == "collected" then
		for _, id in msg.ids or {} do remove(id) end
		for _, id in msg.refused or {} do
			local g = gems[id]
			if g then g.pending = false g.pulling = false g.pull = 0 g.part.Transparency = 0 end
		end
	elseif msg.kind == "openShop" then
		local hud = me.PlayerGui:FindFirstChild("GemShopHud")
		if hud then hud:SetAttribute("Open", true) end
	end
end)

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
		if g.from and age < 0.5 then
			-- flies out of the crusher in an arc
			local t = age / 0.5
			local p = g.from:Lerp(g.pos, t) + Vector3.new(0, math.sin(t * math.pi) * 4, 0)
			g.part.CFrame = CFrame.new(p) * spin
			continue
		end
		local rest = g.pos + Vector3.new(0, math.sin(now * 3 + id) * 0.25, 0)
		if root and not g.pulling and (root.Position - g.pos).Magnitude <= magnet then g.pulling = true end
		if g.pulling and root then
			g.pull = math.min(1, g.pull + dt * 3) -- accelerates: not a sticky constant lerp
			local cur = g.part.Position
			local target = root.Position
			local step = (target - cur) * math.min(1, g.pull * g.pull * 0.6 + dt * 6)
			g.part.CFrame = CFrame.new(cur + step) * spin
			if (target - g.part.Position).Magnitude < 1.6 then
				g.pending = true g.part.Transparency = 1
				table.insert(queue, id)
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

-- ask for our gems once everything is up (the server also syncs on teleport / rebirth)
task.delay(3, function() remote:FireServer("sync") end)
