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

type Gem = { part: BasePart, pos: Vector3, value: number, born: number, from: Vector3?, pulling: boolean, pull: number, pending: boolean }
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
local function paint()
	local m = machine()
	if not m then return end
	local awake = me:GetAttribute("GemAwake") == true
	if m:FindFirstChild("Frame") then
		-- Willem's textured model: an opal glow over it instead of recolouring
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
	local s = math.clamp(0.8 + 0.25 * (value - 1), 0.8, 1.6) * (if gemTemplate then 1.5 else 1)
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
