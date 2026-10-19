--!strict
-- Crush It's game loop. Each player gets a plot with a press; holding CRUSH
-- (client) sends Crush, the server checks the Speed cooldown, slams the ram,
-- takes Power damage off the object and flattens it a bit. At 0 HP the
-- object pancakes, pays ObjectValue(tier) x Value, and the next one rolls in
-- on the conveyor. "Size" moves to the next tier: a bigger press and object.
--
-- Player attributes (read by the client HUD):
--   Cash, Tier, PowerLv, SpeedLv, ValueLv, Plot, ObjName, Hp, MaxHp

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.Kit.DataService)
local Plots = require(script.Parent.Plots)
local Objects = require(script.Parent.Objects)

local CrushRemote = Net.event("Crush")
local BuyRemote = Net.event("BuyUpgrade")
local CrushedRemote = Net.event("Crushed")
local HitRemote = Net.event("Hit")
local NoticeRemote = Net.event("Notice")
local UpgradedRemote = Net.event("Upgraded")

local RISE_SECONDS = 1.1 -- the new press rising out of the floor

local LEVEL_KEYS = { "Power", "Speed", "Value" }
local UPGRADE_BY_ID: { [string]: any } = {}
for _, u in Config.Upgrades do
	UPGRADE_BY_ID[u.id] = u
end

local TEMPLATE = {
	cash = Config.Economy.StartCash,
	tier = 1,
	levels = { Power = 0, Speed = 0, Value = 0 },
	rebirths = 0,
	crushed = 0,
}

local function sanitize(d: any): any
	d.cash = if typeof(d.cash) == "number" and d.cash == d.cash and d.cash >= 0 then d.cash else 0
	d.tier = math.clamp(math.floor(tonumber(d.tier) or 1), 1, Config.MaxTier)
	for _, k in LEVEL_KEYS do
		local u = UPGRADE_BY_ID[k]
		d.levels[k] = math.clamp(math.floor(tonumber(d.levels[k]) or 0), 0, u.max)
	end
	return d
end

DataService.start("CrushItPlayer_v1", TEMPLATE, sanitize)
Plots.create()

-- Per-plot object state ------------------------------------------------------

type Slot = {
	plot: Plots.Plot,
	object: Model?,
	hp: number,
	maxHp: number,
	tier: number,
	ready: boolean, -- an object is on the bed and can be pressed
	nextPress: number, -- os.clock() when the next press is allowed
}

local slots: { [Player]: Slot } = {}

local function level(data: any, id: string): number
	return data.levels[id] or 0
end

local function effect(data: any, id: string): number
	return UPGRADE_BY_ID[id].effect(level(data, id))
end

local function syncAttributes(player: Player, data: any)
	player:SetAttribute("Cash", data.cash)
	player:SetAttribute("Tier", data.tier)
	for _, k in LEVEL_KEYS do
		player:SetAttribute(k .. "Lv", data.levels[k])
	end
	local ls = player:FindFirstChild("leaderstats")
	local cashValue = ls and ls:FindFirstChild("Cash")
	if cashValue then
		(cashValue :: StringValue).Value = Format.cash(data.cash)
	end
end

local function syncHp(player: Player, slot: Slot)
	player:SetAttribute("Hp", math.max(0, slot.hp))
	player:SetAttribute("MaxHp", slot.maxHp)
	player:SetAttribute("ObjName", Config.Objects[slot.tier].name)
end

-- Rolls a fresh object for the slot's tier along the conveyor onto the bed.
local function spawnObject(player: Player, slot: Slot)
	if slot.object then
		slot.object:Destroy()
		slot.object = nil
	end
	slot.ready = false
	local tier = slot.tier
	local bed = Plots.bedBase(slot.plot)
	local beltPos = Plots.beltStart(slot.plot).Position
	local start = CFrame.new(beltPos.X, bed.Position.Y, beltPos.Z) * (bed - bed.Position)
	local model = Objects.build(tier, start)
	model.Parent = slot.plot.model
	slot.object = model
	slot.maxHp = Config.Economy.ObjectHp(tier)
	slot.hp = slot.maxHp
	syncHp(player, slot)
	local t0 = os.clock()
	local dur = Config.Economy.BeltSeconds
	while os.clock() - t0 < dur do
		RunService.Heartbeat:Wait()
		if slot.object ~= model or not model.Parent then
			return
		end
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		a = 1 - (1 - a) ^ 3
		Objects.setSquash(model, start:Lerp(bed, a), 1)
	end
	Objects.setSquash(model, bed, 1)
	slot.ready = true
end

local function moveRam(slot: Slot, bottomY: number, duration: number)
	local ram = slot.plot.ram
	if not ram then
		return
	end
	local plateH = ram.Size.Y
	local o = slot.plot.origin
	local rot = o - o.Position
	local down = CFrame.new(o.Position.X, bottomY + plateH / 2, o.Position.Z) * rot
	local up = CFrame.new(o.Position.X, slot.plot.ramRestY + plateH / 2, o.Position.Z) * rot
	local half = duration / 2
	local t1 = TweenService:Create(ram, TweenInfo.new(half * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = down })
	t1:Play()
	t1.Completed:Wait()
	local t2 = TweenService:Create(ram, TweenInfo.new(half * 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = up })
	t2:Play()
end

local function onCrush(player: Player)
	local slot = slots[player]
	local data = DataService.get(player)
	if not slot or not data or not slot.ready or not slot.object then
		return
	end
	local now = os.clock()
	if now < slot.nextPress then
		return
	end
	local cd = effect(data, "Speed")
	slot.nextPress = now + cd
	slot.ready = false -- no double press during the stroke
	local model = slot.object
	local tier = slot.tier
	local height = Config.Objects[tier].height
	local bed = Plots.bedBase(slot.plot)

	slot.hp -= effect(data, "Power")
	local dead = slot.hp <= 0
	local f = if dead then 0.07 else 0.35 + 0.65 * (slot.hp / slot.maxHp)
	syncHp(player, slot)

	-- Ram travels down to the object's new top, squash lands on impact.
	local stroke = math.min(cd * 0.8, 0.5)
	task.spawn(moveRam, slot, slot.plot.bedTop + height * f, stroke)
	task.wait(stroke / 2 * 0.6)
	if slot.object ~= model then
		return
	end
	Objects.setSquash(model, bed, f)
	local pos = bed.Position + Vector3.new(0, height * f, 0)
	HitRemote:FireAllClients({ plot = slot.plot.index, position = pos, tier = tier, owner = player })

	if not dead then
		slot.ready = true
		return
	end

	local value = Config.Economy.ObjectValue(tier) * effect(data, "Value")
	data.cash += value
	data.crushed += 1
	syncAttributes(player, data)
	CrushedRemote:FireAllClients({ plot = slot.plot.index, position = pos, tier = tier, value = value, owner = player })
	task.wait(0.4)
	if slot.object == model and slots[player] == slot then
		spawnObject(player, slot)
	end
end

-- A bigger press can grow under the player: step them back to the plot's spawn.
local function moveOffPress(player: Player, plot: Plots.Plot)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end
	local bed = Plots.bedBase(plot).Position
	local offset = root.Position - bed
	local half = Config.pressWidth(plot.tier) / 2 + 3
	if math.abs(offset.X) < half and math.abs(offset.Z) < half then
		local spawnCf = Plots.spawnFor(plot)
		character:PivotTo(CFrame.lookAt(spawnCf.Position, Vector3.new(bed.X, spawnCf.Position.Y, bed.Z)))
	end
end

local function notice(player: Player, text: string)
	NoticeRemote:FireClient(player, { text = text })
end

local function onBuy(player: Player, id: unknown)
	local data = DataService.get(player)
	local slot = slots[player]
	if not data or not slot or typeof(id) ~= "string" then
		return
	end
	if id == "Size" then
		if data.tier >= Config.MaxTier then
			notice(player, "Biggest press already!")
			return
		end
		local cost = Config.SizeCost(data.tier)
		if data.cash < cost then
			notice(player, "Not enough cash")
			return
		end
		data.cash -= cost
		data.tier += 1
		syncAttributes(player, data)
		slot.tier = data.tier
		if slot.object then
			slot.object:Destroy()
			slot.object = nil
		end
		slot.ready = false
		Plots.buildPress(slot.plot, data.tier)
		Plots.riseIn(slot.plot, RISE_SECONDS)
		moveOffPress(player, slot.plot)
		UpgradedRemote:FireAllClients({ plot = slot.plot.index, position = Plots.bedBase(slot.plot).Position, tier = data.tier, owner = player })
		local tierAtBuy = data.tier
		task.delay(RISE_SECONDS, function()
			-- Skip if they bought again (or left) meanwhile; the newer buy spawns it.
			if slots[player] == slot and slot.tier == tierAtBuy and not slot.object then
				spawnObject(player, slot)
			end
		end)
		return
	end
	local u = UPGRADE_BY_ID[id]
	if not u then
		return
	end
	local lv = level(data, id)
	if lv >= u.max then
		notice(player, "Maxed out!")
		return
	end
	local cost = u.cost(lv)
	if data.cash < cost then
		notice(player, "Not enough cash")
		return
	end
	data.cash -= cost
	data.levels[id] = lv + 1
	syncAttributes(player, data)
end

-- Studio only: ServerStorage.DevGiveCash:Invoke(player, amount) for testing.
if RunService:IsStudio() then
	local give = Instance.new("BindableFunction")
	give.Name = "DevGiveCash"
	give.OnInvoke = function(player: Player, amount: number)
		local data = DataService.get(player)
		if data then
			data.cash += amount
			syncAttributes(player, data)
		end
		return data and data.cash
	end
	give.Parent = game:GetService("ServerStorage")
end

CrushRemote.OnServerEvent:Connect(function(player)
	onCrush(player)
end)
BuyRemote.OnServerEvent:Connect(onBuy)

-- Joining / leaving ---------------------------------------------------------

local function freePlot(): Plots.Plot?
	for _, plot in Plots.all() do
		if not plot.owner then
			return plot
		end
	end
	return nil
end

local function placeCharacter(player: Player, plot: Plots.Plot)
	local character = player.Character
	if not character then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and slots[player] then
		local spawnCf = Plots.spawnFor(plot)
		local look = Plots.bedBase(plot).Position
		character:PivotTo(CFrame.lookAt(spawnCf.Position, Vector3.new(look.X, spawnCf.Position.Y, look.Z)))
	end
end

local function onPlayer(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "$0"
	cash.Parent = ls
	ls.Parent = player

	local data = DataService.whenLoaded(player)
	if not data then
		return
	end
	local plot = freePlot()
	if not plot then
		player:Kick("This server is full, please join another one.")
		return
	end
	plot.owner = player
	plot.sign.Text = player.DisplayName .. "'s Press"
	player:SetAttribute("Plot", plot.index)
	local slot: Slot = { plot = plot, object = nil, hp = 1, maxHp = 1, tier = data.tier, ready = false, nextPress = 0 }
	slots[player] = slot
	syncAttributes(player, data)
	Plots.buildPress(plot, data.tier)
	task.spawn(spawnObject, player, slot)

	player.CharacterAdded:Connect(function()
		task.defer(placeCharacter, player, plot)
	end)
	if player.Character then
		task.spawn(placeCharacter, player, plot)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	local slot = slots[player]
	slots[player] = nil
	if slot then
		if slot.object then
			slot.object:Destroy()
		end
		slot.plot.owner = nil
		slot.plot.sign.Text = "Free plot"
		Plots.buildPress(slot.plot, 1)
	end
end)
