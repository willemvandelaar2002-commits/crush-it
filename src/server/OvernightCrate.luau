--!strict
-- 8 Nov: the MYSTERY CRATE (Shared/CrateConfig). Saved as d.crate = { readyAt = os.time() }.
-- The crate model stands on the owner's plot (tag "MysteryCrate", attribute ReadyAt); the
-- client draws its countdown. Its prompt opens it once ReadyAt has passed: a free crusher
-- (CrateConfig.Rewards) + CashMinutes of earnings, then the next one starts.
-- Remote "Crate" server -> client: { arrived = true, readyAt } | { opened = { name, rarity, cash }, readyAt }
-- 8 Nov: model attributes for the client animation (everyone sees it): DropAt (server time
-- the crate starts falling), OpenedAt + OpenRarity (it bursts open).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tags = game:GetService("CollectionService")
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.CrusherConfig)
local K = require(RS.Shared.CrateConfig)
local Format = require(RS.Shared.Format)

local M = {}
local rng = Random.new()

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- 8 Nov: Willem's crate model (CrushIt-Mystery-Crate: MeshParts Body, Lid, Seal; the Seal is
-- on the front). Imported by Willem into ServerStorage.MysteryCrateModel (place file, not
-- in Git). Without it, the block placeholder below.
local function fromTemplate(m: Model, cf: CFrame): BasePart?
	local template = game:GetService("ServerStorage"):FindFirstChild("MysteryCrateModel")
	if not template then return nil end
	local copy = template:Clone()
	local body = copy:FindFirstChild("Body", true) :: BasePart?
	local seal = copy:FindFirstChild("Seal", true) :: BasePart?
	if not body or not body:IsA("BasePart") then copy:Destroy() return nil end
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true d.CanCollide = d == body d.CanTouch = false d.Parent = m end
	end
	copy:Destroy()
	-- front = the side with the Seal; turn it toward the walkway (plot x = 0)
	local box, size = m:GetBoundingBox()
	local front = if seal then (seal.Position - body.Position) * Vector3.new(1, 0, 1) else Vector3.new(0, 0, -1)
	if front.Magnitude < 0.01 then front = Vector3.new(0, 0, -1) end
	local want = (cf.Position - (cf * CFrame.new(1, 0, 0)).Position) -- plot local -x (toward the walkway)
	local turn = math.atan2(-want.Unit.X, -want.Unit.Z) - math.atan2(-front.Unit.X, -front.Unit.Z)
	-- scale to the crate's footprint (longest side across = K.ModelWidth), stand it on the base
	local scale = K.ModelWidth / math.max(size.X, size.Z, 0.1)
	local holder = Instance.new("Model")
	for _, d in m:GetChildren() do d.Parent = holder end
	holder.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	holder:ScaleTo(holder:GetScale() * scale)
	holder:PivotTo(CFrame.new(cf.Position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, turn, 0))
	for _, d in holder:GetChildren() do d.Parent = m end
	holder:Destroy()
	m:SetAttribute("Imported", true)
	return body
end

local function build(plot: any, owner: Player): Model
	local m = Instance.new("Model")
	m.Name = "MysteryCrate"
	local cf = plot.origin * CFrame.new(K.Spot.x, 0, K.Spot.z) * CFrame.Angles(0, K.Spot.yaw, 0)
	part(m, "Base", Vector3.new(7.5, 0.6, 7.5), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(30, 34, 80))
	local imported = fromTemplate(m, cf)
	local body = imported or part(m, "Body", Vector3.new(6, 5, 6), cf * CFrame.new(0, 3.1, 0), Color3.fromRGB(150, 70, 230))
	if not imported then
	-- gold bands and lid
	part(m, "BandA", Vector3.new(6.3, 5.2, 0.8), cf * CFrame.new(0, 3.1, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Neon).Transparency = 0.15
	part(m, "BandB", Vector3.new(0.8, 5.2, 6.3), cf * CFrame.new(0, 3.1, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Neon).Transparency = 0.15
	part(m, "Lid", Vector3.new(6.6, 0.8, 6.6), cf * CFrame.new(0, 5.9, 0), Color3.fromRGB(110, 40, 190))
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local g = Instance.new("SurfaceGui")
		g.Face = face g.CanvasSize = Vector2.new(200, 170) g.LightInfluence = 0 g.Parent = body
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Text = "?" t.TextScaled = true
		t.Font = Enum.Font.FredokaOne t.TextColor3 = Color3.new(1, 1, 1) t.TextStrokeTransparency = 0 t.Parent = g
	end
	end
	-- the countdown sign (text filled in by the client)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign" bb.Size = UDim2.fromOffset(220, 80) bb.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y / 2 + 2.3, 0)
	bb.MaxDistance = 90 bb.AlwaysOnTop = false bb.LightInfluence = 0 bb.Parent = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenPrompt" prompt.ActionText = "Open" prompt.ObjectText = "Mystery Crate"
	prompt.HoldDuration = 0.3 prompt.MaxActivationDistance = 12 prompt.RequiresLineOfSight = false
	prompt.Parent = body
	m:SetAttribute("Owner", owner.UserId)
	m:SetAttribute("OwnerName", owner.DisplayName)
	m.PrimaryPart = body
	Tags:AddTag(m, "MysteryCrate")
	m.Parent = plot.model
	return m
end

local function pick(): string
	local total = 0
	for _, r in K.Rewards do total += r.weight end
	local roll = rng:NextNumber() * total
	for _, r in K.Rewards do
		roll -= r.weight
		if roll <= 0 then return r.rarity end
	end
	return K.Rewards[1].rarity
end

function M.start(api: any)
	local remote = Net.event("Crate")
	local notice = Net.event("Notice")
	local models: { [Player]: Model } = {}
	local busy: { [Player]: boolean } = {}

	local function crate(d: any): { readyAt: number? }
		if type(d.crate) ~= "table" then d.crate = {} end
		return d.crate
	end
	local function mirror(p: Player, d: any)
		local at = crate(d).readyAt
		p:SetAttribute("CrateReadyAt", at)
		local m = models[p]
		if m then m:SetAttribute("ReadyAt", at) end
	end

	local function open(p: Player, m: Model)
		if busy[p] then return end
		local d = api.getData(p)
		if not d or m:GetAttribute("Owner") ~= p.UserId then
			notice:FireClient(p, { text = "This is " .. tostring(m:GetAttribute("OwnerName")) .. "'s crate." })
			return
		end
		local c = crate(d)
		local now = os.time()
		if not c.readyAt then return end
		if now < c.readyAt then
			local left = c.readyAt - now
			notice:FireClient(p, { text = string.format("Your Mystery Crate opens in %dh %dm. Come back then!", left // 3600, (left % 3600) // 60) })
			return
		end
		busy[p] = true
		local rarity = pick()
		local name = api.giveCrusher(p, rarity, nil, true) or rarity
		local cash = C.money(math.max(1, api.cashPerSecond(p)) * K.CashMinutes * 60)
		api.addCash(p, cash, "MysteryCrate", "TimedReward")
		c.readyAt = now + K.Hours * 3600
		local t = workspace:GetServerTimeNow()
		m:SetAttribute("OpenRarity", rarity)
		m:SetAttribute("OpenedAt", t)
		m:SetAttribute("DropAt", t + K.NextDropAfter) -- the next crate falls in
		d.stats = d.stats or {}
		d.stats.crates = (d.stats.crates or 0) + 1
		api.save(p)
		mirror(p, d)
		remote:FireClient(p, { opened = { name = name, rarity = rarity, cash = Format.cash(cash) }, readyAt = c.readyAt })
		require(script.Parent.Kit.Analytics).custom(p, "MysteryCrateOpened", d.stats.crates, rarity)
		busy[p] = nil
	end

	local function tick(p: Player)
		local d = api.getData(p)
		if not d or not d.crushers then return end
		local c = crate(d)
		-- the first crate lands once the tutorial is done
		local fresh = false
		if not c.readyAt then
			fresh = true
			if (d.crushers.tutorial or 0) <= #C.TutorialSteps then return end
			-- (8 Nov: not right after the tutorial; goal 0/nil = older saves past the goals)
			local goal = d.crushers.goal or 0
			if goal ~= 0 and goal < K.AfterGoal then return end
			c.readyAt = os.time() + K.FirstHours * 3600
			remote:FireClient(p, { arrived = true, readyAt = c.readyAt })
		end
		if not models[p] then
			local plot = api.eventPlot(p)
			if plot then
				local m = build(plot, p)
				models[p] = m
				if fresh then m:SetAttribute("DropAt", workspace:GetServerTimeNow() + 1.5) end
				local prompt = (m.PrimaryPart :: BasePart):FindFirstChild("OpenPrompt") :: ProximityPrompt
				prompt.Triggered:Connect(function(who: Player) open(who, m) end)
			end
		end
		mirror(p, d)
	end

	Players.PlayerRemoving:Connect(function(p)
		local m = models[p]
		if m then m:Destroy() end
		models[p] = nil busy[p] = nil
	end)
	task.spawn(function()
		while true do
			for _, p in Players:GetPlayers() do task.spawn(tick, p) end
			task.wait(3)
		end
	end)
end

return M
