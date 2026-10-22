--!strict
-- Carried scrap as a tower of toy blocks on each player's back (like the gold
-- stack in the reference games), with its value floating above it. For your
-- own player: collecting flies blocks from your scrap hopper onto your back,
-- selling flies them into your sell counter and bursts cash bundles that fly
-- into the cash counter (bottom-left). Visual only; reads the replicated
-- Scrap / Plot attributes the server already sets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.Config)
if not Config.Crushers.Enabled then return end
local Format = require(ReplicatedStorage.Shared.Format)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)

local me = Players.LocalPlayer
local COLORS = { Color3.fromRGB(248, 199, 53), Color3.fromRGB(53, 201, 79), Color3.fromRGB(35, 99, 210),
	Color3.fromRGB(230, 69, 77), Color3.fromRGB(255, 140, 40), Color3.fromRGB(156, 66, 221) }
local MAX_LAYERS = 24
local BLOCK = Vector3.new(2.2, 0.75, 1.5)

local function play(id: number?, volume: number?)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.5
	SoundService:PlayLocalSound(s)
	task.delay(3, function() s:Destroy() end)
end

-- How many layers a carried amount shows: grows with the number's size.
local function layersFor(amount: number): number
	if amount <= 0 then return 0 end
	return math.clamp(math.floor(2 + math.log10(amount + 1) * 2.2), 1, MAX_LAYERS)
end

type Stack = { player: Player, folder: Folder, blocks: { BasePart }, label: TextLabel?, gui: BillboardGui?, root: BasePart?, shown: number }
local stacks: { [Player]: Stack } = {}

local function block(i: number, root: BasePart, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = "CarriedScrap"
	p.Size = BLOCK
	p.Color = COLORS[(i - 1) % #COLORS + 1]
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.CastShadow = false, false, false, true, false
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = p
	-- behind the back (+Z of the root), each layer slightly twisted like a loose pile
	w.C0 = CFrame.new(0, -0.3 + (i - 1) * BLOCK.Y, 1.35) * CFrame.Angles(0, math.sin(i * 1.7) * 0.25, 0)
	w.Parent = p
	p.Parent = parent
	return p
end

local function rebuild(st: Stack, amount: number)
	local char = st.player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	if st.root ~= root then
		for _, b in st.blocks do b:Destroy() end
		table.clear(st.blocks)
		st.root = root
		st.folder.Parent = char
	end
	local want = layersFor(amount)
	while #st.blocks < want do table.insert(st.blocks, block(#st.blocks + 1, root, st.folder)) end
	while #st.blocks > want do (table.remove(st.blocks) :: BasePart):Destroy() end
	if not st.gui then
		local g = Instance.new("BillboardGui")
		g.Name = "ScrapValue"
		g.Size = UDim2.fromOffset(160, 40)
		g.StudsOffset = Vector3.new(0, 1.6, 0)
		g.AlwaysOnTop = true
		g.MaxDistance = 90
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.TextScaled = true
		t.Parent = g
		Style.text(t, 3)
		t.TextColor3 = Color3.fromRGB(150, 255, 110)
		st.gui = g
		st.label = t
	end
	local gui = st.gui :: BillboardGui
	gui.Adornee = st.blocks[#st.blocks]
	gui.Parent = if want > 0 then st.folder else nil
	if st.label then st.label.Text = Format.cash(amount) end
	st.shown = want
end

local function stationPart(name: string): BasePart?
	local index = me:GetAttribute("Plot")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = index and plots and plots:FindFirstChild("Plot" .. index)
	local station = plot and plot:FindFirstChild(name, true)
	if not station then return nil end
	if station:IsA("Model") then
		local cf = station:GetBoundingBox()
		local p = Instance.new("Part") -- a point to fly to/from
		p.CFrame = cf
		return p
	end
	return nil
end

-- One loose block flying in an arc between two world points.
local function fly(from: Vector3, to: Vector3, color: Color3, delay: number)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Size = BLOCK
	p.Color = color
	p.CFrame = CFrame.new(from)
	task.delay(delay, function()
		p.Parent = Workspace
		local t0 = os.clock()
		local spin = math.random() * 6
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = math.min(1, (os.clock() - t0) / 0.55)
			local pos = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
			p.CFrame = CFrame.new(pos) * CFrame.Angles(t * spin, t * spin * 1.3, 0)
			if t >= 1 then conn:Disconnect() p:Destroy() end
		end)
	end)
end

-- Cash bundles burst out around a screen point and fly into the cash icon.
local function cashBurst(worldAt: Vector3, amount: number)
	local gui = me.PlayerGui:FindFirstChild("CrushHud")
	local icon = gui and gui:FindFirstChild("CashIcon") :: GuiObject?
	local cam = Workspace.CurrentCamera
	if not gui or not cam then return end
	local sp, onScreen = cam:WorldToViewportPoint(worldAt)
	local inset = game:GetService("GuiService"):GetGuiInset()
	local start = Vector2.new(sp.X, sp.Y) - inset
	if not onScreen then start = cam.ViewportSize / 2 end
	local target = if icon then icon.AbsolutePosition + icon.AbsoluteSize / 2 else Vector2.new(60, cam.ViewportSize.Y - 80)
	local count = math.clamp(math.floor(6 + math.log10(amount + 1) * 2.5), 8, 26)
	for i = 1, count do
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = Icons.Cash
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Size = UDim2.fromOffset(44, 44)
		img.Position = UDim2.fromOffset(start.X, start.Y)
		img.Rotation = math.random(-30, 30)
		img.ZIndex = 50
		img.Parent = gui
		local a = math.random() * math.pi * 2
		local r = math.random(60, 170)
		local out = start + Vector2.new(math.cos(a) * r, math.sin(a) * r * 0.7)
		TweenService:Create(img, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(out.X, out.Y) }):Play()
		task.delay(0.35 + i * 0.03, function()
			local tw = TweenService:Create(img, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(26, 26) })
			tw:Play()
			tw.Completed:Wait()
			img:Destroy()
			if icon and i % 3 == 0 then
				local sc = icon:FindFirstChild("PopScale") :: UIScale? or Instance.new("UIScale")
				sc.Name = "PopScale"
				sc.Parent = icon
				sc.Scale = 1.25
				TweenService:Create(sc, TweenInfo.new(0.15), { Scale = 1 }):Play()
			end
		end)
	end
	play(Config.Sounds.Coin, 0.5)
end

local function track(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "ScrapStack"
	local st: Stack = { player = player, folder = folder, blocks = {}, root = nil, shown = 0 }
	stacks[player] = st
	local last = (player:GetAttribute("Scrap") :: number?) or 0
	local function update()
		local amount = (player:GetAttribute("Scrap") :: number?) or 0
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if player == me and root then
			if amount > last then
				-- collected: blocks fly from the hopper onto the back
				local hopper = stationPart("CollectStation")
				if hopper then
					for i = 1, math.min(8, layersFor(amount) - layersFor(last) + 3) do
						fly(hopper.Position + Vector3.new(0, 3, 0), root.Position + Vector3.new(0, 1, 0), COLORS[i % #COLORS + 1], i * 0.05)
					end
				end
			elseif amount < last and amount <= 0 then
				-- sold: the stack flies into the counter, then cash bursts out
				local seller = stationPart("SellStation")
				local to = if seller then seller.Position + Vector3.new(0, 2, 0) else root.Position + Vector3.new(0, 2, 0)
				for i, b in st.blocks do fly(b.Position, to, b.Color, i * 0.025) end
				local sold = last
				task.delay(0.5, function() cashBurst(root.Position + Vector3.new(0, 3, 0), sold) end)
			end
		end
		last = amount
		rebuild(st, amount)
	end
	player:GetAttributeChangedSignal("Scrap"):Connect(update)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		st.root = nil
		rebuild(st, (player:GetAttribute("Scrap") :: number?) or 0)
	end)
	if player.Character then task.spawn(rebuild, st, last) end
end

for _, p in Players:GetPlayers() do track(p) end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(p) stacks[p] = nil end)
