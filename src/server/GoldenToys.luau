--!strict
-- 2 Nov: golden toys (CrusherConfig.GoldenToys; the doc's "golden toys" + Grow a
-- Garden's surprise layer). For each player on their own plot, every Min-Max
-- seconds a glowing golden toy lands in front of one of their bays for Life
-- seconds. Grabbing it (walk into it or press E) pays Seconds of income, or
-- sometimes a short boost. Only the owner can grab their toy; the server decides.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local Format = require(RS.Shared.Format)
local C = require(RS.Shared.Config).Crushers
local Analytics = require(script.Parent.Kit.Analytics)

local M = {}
local G = C.GoldenToys
local rng = Random.new()

local function makeToy(at: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "GoldenToy" p.Size = Vector3.new(3, 2.2, 3) p.Anchored = true p.CanCollide = false p.CanQuery = true p.CanTouch = true
	p.Color = Color3.fromRGB(255, 205, 50) p.Material = Enum.Material.Neon p.CastShadow = false
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local stud = Instance.new("Part")
	stud.Name = "Stud" stud.Shape = Enum.PartType.Cylinder stud.Size = Vector3.new(0.6, 1.1, 1.1) stud.Anchored = true stud.CanCollide = false
	stud.CanQuery = false stud.CanTouch = false stud.Color = p.Color stud.Material = Enum.Material.Neon
	stud.CFrame = p.CFrame * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)) stud.Parent = p
	local light = Instance.new("PointLight") light.Color = p.Color light.Range = 14 light.Brightness = 2 light.Parent = p
	local sparkle = Instance.new("ParticleEmitter") sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds" sparkle.Rate = 12
	sparkle.Lifetime = NumberRange.new(0.6, 1) sparkle.Speed = NumberRange.new(2, 4) sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150)) sparkle.LightEmission = 1 sparkle.Parent = p
	local board = Instance.new("BillboardGui") board.Size = UDim2.fromOffset(120, 40) board.StudsOffset = Vector3.new(0, 3.2, 0)
	board.AlwaysOnTop = true board.LightInfluence = 0 board.MaxDistance = 90 board.Parent = p
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.Font = Enum.Font.FredokaOne t.Text = "GRAB!" t.TextColor3 = Color3.fromRGB(255, 225, 80) t.Parent = board
	local s = Instance.new("UIStroke") s.Thickness = 3 s.Color = Color3.fromRGB(19, 23, 38) s.Parent = t
	return p
end

function M.start(api: any)
	local event = Net.event("GoldenToy")
	local live: { [Player]: BasePart } = {}
	local function grab(p: Player, toy: BasePart)
		if live[p] ~= toy or not toy.Parent then return end
		live[p] = nil
		toy:Destroy()
		local d = api.getData(p)
		if not d then return end
		local result
		if rng:NextNumber() < G.BoostChance then
			local id = if rng:NextNumber() < 0.5 then "Cash" else "Luck"
			require(script.Parent.Boosts).add(p, id, G.BoostMinutes)
			result = { text = "2x " .. string.upper(id) .. " " .. G.BoostMinutes .. " MIN!" }
		else
			local secs = rng:NextInteger(G.Seconds[1], G.Seconds[2])
			local amount = math.max(G.MinCash, math.floor(api.cashPerSecond(p) * secs))
			api.addCash(p, amount, "GoldenToy", "Gameplay")
			result = { amount = amount, text = "+" .. Format.cash(amount) }
		end
		d.stats = d.stats or {}
		d.stats.goldenToys = (d.stats.goldenToys or 0) + 1
		Analytics.custom(p, "GoldenToy", 1)
		event:FireClient(p, result)
	end
	local function spawnFor(p: Player)
		local d = api.getData(p)
		local plot = api.eventPlot(p)
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not d or not plot or not root or live[p] then return end
		if (d.crushers.tutorial or 1) < 3 then return end -- after the first collect and sell
		if p:GetAttribute("FactoryEventRunning") == true then return end
		-- only while you are on your own plot
		if (root.Position - plot.origin.Position).Magnitude > 140 then return end
		local count = math.max(1, math.min(d.crushers.bays, #plot.bays))
		local bay = plot.bays[rng:NextInteger(1, count)]
		if not bay or not bay.part then return end
		local toy = makeToy(bay.part.Position + Vector3.new(0, 3.2, 0))
		toy.Parent = plot.model
		live[p] = toy
		local prompt = Instance.new("ProximityPrompt") prompt.ActionText = "Grab" prompt.ObjectText = "Golden toy"
		prompt.HoldDuration = 0 prompt.MaxActivationDistance = 12 prompt.RequiresLineOfSight = false prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = toy
		prompt.Triggered:Connect(function(who) if who == p then grab(p, toy) end end)
		toy.Touched:Connect(function(hit)
			local who = Players:GetPlayerFromCharacter(hit.Parent)
			if who == p then grab(p, toy) end
		end)
		event:FireClient(p, { spawned = toy })
		task.delay(G.Life, function()
			if live[p] == toy then live[p] = nil end
			if toy.Parent then toy:Destroy() end
		end)
	end
	local nextAt: { [Player]: number } = {}
	Players.PlayerAdded:Connect(function(p) nextAt[p] = os.clock() + G.FirstDelay end)
	for _, p in Players:GetPlayers() do nextAt[p] = os.clock() + G.FirstDelay end
	Players.PlayerRemoving:Connect(function(p)
		nextAt[p] = nil
		if live[p] then live[p]:Destroy() live[p] = nil end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for p, at in nextAt do
				if now >= at then
					nextAt[p] = now + rng:NextNumber(G.Min, G.Max)
					task.spawn(spawnFor, p)
				end
			end
		end
	end)
end

return M
