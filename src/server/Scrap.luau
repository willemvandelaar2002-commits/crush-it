--!strict
-- Scrap: what a crush pays now. Game.server calls Scrap.drop when an object is
-- flattened; the pieces fly out of the press and land on the plot. The owner
-- picks them up by walking over them (no limit; data.scrap) and sells them by
-- standing on the Deposit pad of their scrap shop (ScrapShop.luau); the smelter
-- turns it into cash over time, waiting on the Collect Cash pad.
-- Auto Collect pass: landed pieces fly to you, go into the smelter and the cash is collected for you.
-- Numbers in Config.Scrap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(ReplicatedStorage.Shared.Store)
local Net = require(ReplicatedStorage.Shared.Net)
local Format = require(ReplicatedStorage.Shared.Format)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local Pads = require(script.Parent.Pads)
local MarketplaceService = game:GetService("MarketplaceService")

export type Api = {
	getData: (Player) -> any,
	sync: (Player) -> (),
	plots: () -> { any }, -- Plots.all(): { model, origin, owner, shop, ... }
}

local Scrap = {}

local api: Api
local Picked = Net.event("ScrapPicked")
local Sold = Net.event("ScrapSold")
local Deposited = Net.event("ScrapDeposited")
local Notice = Net.event("Notice")

local C = Color3.fromRGB
local METAL_TINTS = { C(150, 155, 165), C(120, 125, 135), C(175, 150, 120) }

local function folderFor(plot: any): Folder
	local f = plot.model:FindFirstChild("Scrap") :: Folder?
	if not f then
		f = Instance.new("Folder")
		assert(f)
		f.Name = "Scrap"
		f.Parent = plot.model
	end
	return f :: Folder
end

-- The object's own main colour, mixed with metal, so scrap looks like bits of it.
local function pieceColor(tier: number, variant: string, i: number): (Color3, Enum.Material)
	local v = Config.VariantById[variant]
	if v and v.tint then
		return v.tint, if variant == "Diamond" then Enum.Material.Glass else Enum.Material.Foil
	end
	local def = Config.Objects[tier]
	local parts = def and def.parts
	local base = if parts and #parts > 0 then parts[((i - 1) % #parts) + 1].color else METAL_TINTS[1]
	return base:Lerp(METAL_TINTS[(i % #METAL_TINTS) + 1], 0.35), Enum.Material.Metal
end

-- Where the pile goes for this press size: straight in front of the press, between
-- it and the entrance with the scrap shop. Also places the steel tray under it.
local function pileSpot(plot: any, tier: number): CFrame
	local F = Config.Plots.FloorSize
	local _ = F
	local front = math.clamp(Config.pressWidth(tier) * 0.9 + 10, 14, 40) -- the biggest press reaches z = 33
	local spot = plot.origin * CFrame.new(0, 0, front)
	local tray = plot.model:FindFirstChild("PileTray")
	if tray and tray:GetAttribute("Tier") ~= tier then
		tray:Destroy()
		tray = nil
	end
	if not tray then
		local t = Build.inset(plot.model, "PileTray", spot, 11, 11, Color3.fromRGB(60, 62, 72), Color3.fromRGB(245, 190, 40))
		t:SetAttribute("Tier", tier)
	end
	return spot
end

-- Big floating "$X" over the pile (what's lying there), like the gold pile counter.
local function updateLabel(plot: any)
	local folder = plot.model:FindFirstChild("Scrap")
	local anchor = plot.model:FindFirstChild("PileAnchor") :: BasePart?
	local total, top = 0, 0
	if folder then
		for _, p in folder:GetChildren() do
			if p:IsA("BasePart") and not p:GetAttribute("Taken") then
				total += (p:GetAttribute("Value") :: number?) or 0
				top = math.max(top, p.Position.Y - plot.origin.Position.Y)
			end
		end
	end
	if total <= 0 then
		if anchor then
			anchor:Destroy()
		end
		return
	end
	if not anchor then
		local a = Instance.new("Part")
		a.Name = "PileAnchor"
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.CanTouch = false
		a.Transparency = 1
		a.Size = Vector3.one
		a.Parent = plot.model
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(14, 3.6)
		gui.LightInfluence = 0
		gui.MaxDistance = 160
		gui.Parent = a
		local label = Instance.new("TextLabel")
		label.Name = "Value"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Parent = gui
		Style.text(label, 5)
		label.TextColor3 = Color3.fromRGB(130, 255, 90)
		anchor = a
	end
	assert(anchor)
	local folderAttrX = folder and folder:GetAttribute("PileX") :: number?
	local folderAttrZ = folder and folder:GetAttribute("PileZ") :: number?
	if folderAttrX and folderAttrZ then
		anchor.CFrame = CFrame.new(folderAttrX, plot.origin.Position.Y + top + 4, folderAttrZ)
	end
	((anchor:FindFirstChildOfClass("BillboardGui") :: any).Value :: TextLabel).Text = Format.cash(total)
end
Scrap.updateLabel = updateLabel

-- Drops `value` worth of scrap from `from` (the bed) onto the pile behind the press.
function Scrap.drop(player: Player, plot: any, from: Vector3, value: number, tier: number, variant: string)
	local S = Config.Scrap
	local folder = folderFor(plot)
	local count = math.clamp(S.PiecesMin + math.floor(tier / 3), S.PiecesMin, S.PiecesMax)
	local existing = folder:GetChildren()
	if #existing + count > S.MaxOnFloor then
		-- too much lying around: the value joins pieces that are already there
		for i = 1, count do
			local p = existing[math.random(1, #existing)] :: BasePart
			p:SetAttribute("Value", ((p:GetAttribute("Value") :: number?) or 0) + value / count)
			p.Size = (p.Size * 1.04):Min(Vector3.new(3, 3, 3))
		end
		updateLabel(plot)
		return
	end
	local width = Config.pressWidth(tier)
	local spot = pileSpot(plot, tier)
	for i = 1, count do
		-- the pile grows wider and taller with every piece on it
		local n = #existing + i
		-- a tall stack, Destroy a Vault gold-pile style
		local radius = 2.4 + math.sqrt(n) * 0.45
		local height = 0.8 + math.sqrt(n) * 1.5
		folder:SetAttribute("PileX", spot.Position.X)
		folder:SetAttribute("PileZ", spot.Position.Z)
		folder:SetAttribute("PileR", radius)
		local size = 1.5 + math.random() * 0.8 + math.min(tier, 13) * 0.05
		local color, material = pieceColor(tier, variant, i)
		local p = Instance.new("Part")
		p.Name = "Scrap"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(size, size * (0.5 + math.random() * 0.4), size * (0.7 + math.random() * 0.4))
		p.Color = color
		p.Material = material
		p:SetAttribute("Value", value / count)
		-- a little glint so pieces stand out on the dark pad
		local glint = Instance.new("Sparkles")
		glint.SparkleColor = Color3.fromRGB(255, 240, 180)
		glint.Parent = p
		p:SetAttribute("Owner", player.UserId)
		-- land on the heap: closer to the middle = higher up
		local angle = math.random() * math.pi * 2
		local dist = (math.random() ^ 0.7) * radius
		local y = height * (1 - dist / radius) * (0.7 + math.random() * 0.3) + p.Size.Y * 0.4
		local land = spot * CFrame.new(math.cos(angle) * dist, y, math.sin(angle) * dist)
		local spin = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.CFrame = CFrame.new(from) * spin
		p.Parent = folder
		-- arc: up and out, then down with a little bounce
		local mid = from:Lerp(land.Position, 0.5) + Vector3.new(0, math.max(6, width * 1.5) + math.random() * 3, 0)
		local up = TweenService:Create(p, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(mid) * spin })
		up.Completed:Once(function()
			local down = TweenService:Create(p, TweenInfo.new(0.32, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{ CFrame = land * CFrame.Angles(0, math.random() * 6, 0) })
			down.Completed:Once(function()
				p:SetAttribute("LandedAt", os.clock())
				updateLabel(plot)
			end)
			down:Play()
		end)
		up:Play()
	end
end

-- Removes every piece on a plot (owner left, rebirth).
function Scrap.clear(plot: any)
	local f = plot.model:FindFirstChild("Scrap")
	if f then
		f:ClearAllChildren()
		f:SetAttribute("PileR", nil)
	end
	local anchor = plot.model:FindFirstChild("PileAnchor")
	if anchor then
		anchor:Destroy()
	end
	local tray = plot.model:FindFirstChild("PileTray")
	if tray then
		tray:Destroy()
	end
end

-- Smelter ----------------------------------------------------------------------
-- data.scrap (carried) -> Deposit pad -> data.smeltQueue, smelted at
-- data.smeltRate per second into data.smeltReady -> Collect Cash pad -> cash.

local smeltStart: { [Player]: number } = {} -- queue size when the current batch started (board bar)
local settled: { [Player]: boolean } = {} -- offline smelting paid into "ready" once per session
local padState: { [Player]: { id: string?, nextAt: number } } = {}
local lastAutoCollect: { [Player]: number } = {}

local GREEN = Color3.fromRGB(130, 255, 90)
local RED = Color3.fromRGB(255, 95, 85)

local function smeltSeconds(data: any): number
	return Config.Smelter.SmeltSeconds(data.smeltLv or 0)
end

local function deposit(player: Player, data: any, plot: any, from: Vector3?)
	local amount = data.scrap
	if amount <= 0 then
		return
	end
	data.scrap = 0
	data.smeltQueue += amount
	data.smeltRate = data.smeltQueue / smeltSeconds(data)
	smeltStart[player] = data.smeltQueue
	api.sync(player)
	if plot.shop then
		Deposited:FireAllClients({ plot = plot.index, from = from or plot.shop.pad.Position, to = plot.shop.hopper.Position, amount = amount, owner = player })
	end
end

-- Helpers (Mini Presses) put their output straight into the smelter.
function Scrap.feed(player: Player, data: any, plot: any, amount: number)
	if amount <= 0 then
		return
	end
	data.smeltQueue += amount
	data.smeltRate = math.max(data.smeltRate, data.smeltQueue / smeltSeconds(data))
	if not smeltStart[player] or data.smeltQueue > smeltStart[player] then
		smeltStart[player] = data.smeltQueue
	end
	local _ = plot
end

local function collect(player: Player, data: any, plot: any, auto: boolean)
	local amount = data.smeltReady
	if amount <= 0 then
		return
	end
	data.smeltReady = 0
	data.cash += amount
	api.sync(player)
	local where = if plot.shop then plot.shop.collect.Position else plot.origin.Position
	Sold:FireAllClients({ plot = plot.index, position = where, amount = amount, owner = player, auto = auto })
end

-- Finish Now (Robux product, Shop.luau): everything in the smelter is done at once.
function Scrap.finishSmelt(player: Player, data: any)
	data.smeltReady += data.smeltQueue
	data.smeltQueue = 0
	data.smeltRate = 0
	smeltStart[player] = nil
end

local function smeltTick(player: Player, data: any, dt: number)
	if not settled[player] then
		-- smelting carried on while you were away
		settled[player] = true
		data.smeltReady += data.smeltQueue
		data.smeltQueue = 0
		data.smeltRate = 0
	end
	if data.smeltQueue > 0 then
		if data.smeltRate <= 0 then
			data.smeltRate = data.smeltQueue / smeltSeconds(data)
			smeltStart[player] = data.smeltQueue
		end
		local move = math.min(data.smeltQueue, data.smeltRate * dt)
		data.smeltQueue -= move
		data.smeltReady += move
		if data.smeltQueue <= 1e-6 then
			data.smeltQueue = 0
			data.smeltRate = 0
			smeltStart[player] = nil
		end
	end
	player:SetAttribute("SmeltQueue", data.smeltQueue)
	player:SetAttribute("SmeltReady", data.smeltReady)
	player:SetAttribute("SmeltLv", data.smeltLv)
end

local function shopLabels(plot: any, owner: Player?, data: any)
	local shop = plot.shop
	if not shop then
		return
	end
	local board = shop.board :: any
	if not owner or not data then
		Pads.label(shop.pad, "Deposit Scrap", "")
		Pads.label(shop.collect, "Collect Cash", "")
		Pads.label(shop.speed, "+ Smelt Speed", "")
		Pads.label(shop.finish, "Finish Now", "")
		board.Amount.Text = ""
		board.Rate.Text = "Free plot"
		board.Bar.Fill.Size = UDim2.fromScale(0, 1)
		return
	end
	Pads.label(shop.pad, "Deposit Scrap", if data.scrap > 0 then Format.cash(data.scrap) else "", GREEN)
	Pads.label(shop.collect, "Collect Cash", Format.cash(data.smeltReady), GREEN)
	local lv = data.smeltLv or 0
	if lv >= Config.Smelter.SpeedMax then
		Pads.label(shop.speed, "Smelt Speed MAX", "", GREEN)
	else
		local cost = Config.Smelter.SpeedCost(lv)
		Pads.label(shop.speed, "+ Smelt Speed", Format.cash(cost), if data.cash >= cost then GREEN else RED)
	end
	local product = Store.productById("FinishSmelt")
	Pads.label(shop.finish, "Finish Now", if data.smeltQueue > 0 and product then "R$ " .. product.price else "", GREEN)
	if data.smeltQueue > 0 then
		board.Amount.Text = Format.cash(data.smeltQueue) .. " left"
		board.Rate.Text = Format.cash(data.smeltRate) .. " / sec"
		local start = smeltStart[owner] or data.smeltQueue
		board.Bar.Fill.Size = UDim2.fromScale(math.clamp(1 - data.smeltQueue / math.max(start, 1e-9), 0, 1), 1)
	else
		board.Amount.Text = if data.smeltReady > 0 then Format.cash(data.smeltReady) .. " ready!" else "$0"
		board.Rate.Text = string.format("Deposit scrap: done in %.1fs", smeltSeconds(data))
		board.Bar.Fill.Size = UDim2.fromScale(if data.smeltReady > 0 then 1 else 0, 1)
	end
end

local function shopPads(owner: Player, data: any, plot: any, root: BasePart, now: number)
	local shop = plot.shop
	if not shop then
		return
	end
	local state = padState[owner] or { id = nil, nextAt = 0 }
	padState[owner] = state
	local on: string? = nil
	local top: BasePart? = nil
	for _, p in { shop.pad, shop.collect, shop.speed, shop.finish } do
		if Pads.on(p, root) then
			on = p:GetAttribute("PadId") :: string
			top = p
		end
	end
	if on ~= state.id then
		state.id = on
		state.nextAt = now
	end
	if not on or not top or now < state.nextAt then
		return
	end
	if on == "Deposit" then
		if data.scrap > 0 then
			Pads.press(top)
			deposit(owner, data, plot, root.Position)
		end
		state.nextAt = now + 0.3
	elseif on == "Collect" then
		if data.smeltReady > 0 then
			Pads.press(top)
			collect(owner, data, plot, false)
		end
		state.nextAt = now + 0.6
	elseif on == "SmeltSpeed" then
		Pads.press(top)
		local lv = data.smeltLv or 0
		local cost = Config.Smelter.SpeedCost(lv)
		if lv >= Config.Smelter.SpeedMax then
			state.nextAt = math.huge
		elseif data.cash >= cost then
			data.cash -= cost
			data.smeltLv = lv + 1
			if data.smeltQueue > 0 then
				data.smeltRate = math.max(data.smeltRate, data.smeltQueue / smeltSeconds(data))
			end
			api.sync(owner)
			Notice:FireClient(owner, { text = string.format("Smelt Speed Lv %d!", data.smeltLv) })
			state.nextAt = now + 0.35
		else
			Notice:FireClient(owner, { text = "Not enough cash!" })
			state.nextAt = math.huge -- once per step
		end
	elseif on == "FinishSmelt" then
		state.nextAt = math.huge
		if data.smeltQueue > 0 then
			Pads.press(top)
			local product = Store.productById("FinishSmelt")
			if product and product.productId ~= 0 then
				MarketplaceService:PromptProductPurchase(owner, product.productId)
			else
				Notice:FireClient(owner, { text = "Finish Now: coming soon!" })
			end
		end
	end
end

local lastStep: { [Player]: number } = {}

local function step()
	local S = Config.Scrap
	local now = os.clock()
	for _, plot in api.plots() do
		local owner: Player? = plot.owner
		if not owner then
			shopLabels(plot, nil, nil)
			continue
		end
		local data = api.getData(owner)
		if data then
			smeltTick(owner, data, now - (lastStep[owner] or now))
			lastStep[owner] = now
			-- Auto Collect: smelted cash goes straight to you
			if data.smeltReady > 0 and Store.hasPass(owner, "AutoCollect") and now - (lastAutoCollect[owner] or 0) > 1 then
				lastAutoCollect[owner] = now
				collect(owner, data, plot, true)
			end
		end
		shopLabels(plot, owner, data)
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not data or not root then
			continue
		end
		local auto = Store.hasPass(owner, "AutoCollect")
		local picked = 0
		local folder = plot.model:FindFirstChild("Scrap")
		-- walking into the pile takes all of it
		local onPile = false
		if folder and folder:GetAttribute("PileR") then
			local px, pz = folder:GetAttribute("PileX") :: number, folder:GetAttribute("PileZ") :: number
			local d = Vector3.new(px - root.Position.X, 0, pz - root.Position.Z).Magnitude
			onPile = d <= (folder:GetAttribute("PileR") :: number) + 2.5
		end
		if folder then
			for _, p in folder:GetChildren() do
				if not p:IsA("BasePart") or p:GetAttribute("Taken") then
					continue
				end
				local landed = p:GetAttribute("LandedAt") :: number?
				if not landed then
					continue
				end
				local d = Vector3.new(p.Position.X - root.Position.X, 0, p.Position.Z - root.Position.Z).Magnitude
				local near = (onPile or d <= S.PickupRadius) and math.abs(p.Position.Y - root.Position.Y) < 10
				if near or (auto and now - landed >= S.AutoDelay) then
					p:SetAttribute("Taken", true)
					local value = (p:GetAttribute("Value") :: number?) or 0
					data.scrap += value
					picked += value
					-- fly into the player, then gone
					local t = TweenService:Create(p, TweenInfo.new(if near then 0.18 else 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ CFrame = root.CFrame, Size = p.Size * 0.3 })
					t.Completed:Once(function()
						p:Destroy()
					end)
					t:Play()
				end
			end
		end
		if picked > 0 then
			updateLabel(plot)
			if auto then
				-- Auto Collect: picked scrap goes straight into the smelter
				deposit(owner, data, plot, root.Position)
			else
				api.sync(owner)
				Picked:FireClient(owner, { value = picked, total = data.scrap })
			end
		end
		shopPads(owner, data, plot, root, now)
	end
end

function Scrap.start(a: Api)
	api = a
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		smeltStart[p] = nil
		settled[p] = nil
		padState[p] = nil
		lastAutoCollect[p] = nil
		lastStep[p] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			step()
		end
	end)
end

return Scrap
