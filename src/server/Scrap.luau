--!strict
-- Scrap: what a crush pays now. Game.server calls Scrap.drop when an object is
-- flattened; the pieces fly out of the press and land on the plot. The owner
-- picks them up by walking over them (no limit; data.scrap) and sells them by
-- standing on the sell pad of their scrap shop (ScrapShop.luau) -> cash.
-- Auto Collect pass: landed pieces fly to you and are sold straight away.
-- Numbers in Config.Scrap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(ReplicatedStorage.Shared.Store)
local Net = require(ReplicatedStorage.Shared.Net)
local Build = require(script.Parent.Kit.Build)

export type Api = {
	getData: (Player) -> any,
	sync: (Player) -> (),
	plots: () -> { any }, -- Plots.all(): { model, origin, owner, shop, ... }
}

local Scrap = {}

local api: Api
local Picked = Net.event("ScrapPicked")
local Sold = Net.event("ScrapSold")

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

-- Where the pile goes for this press size: straight behind the press, between it
-- and the scrap shop. Also places the steel tray under it.
local function pileSpot(plot: any, tier: number): CFrame
	local F = Config.Plots.FloorSize
	local back = math.clamp(Config.pressWidth(tier) * 0.9 + 10, 14, F / 2 - 9)
	local spot = plot.origin * CFrame.new(0, 0, -back)
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
		return
	end
	local width = Config.pressWidth(tier)
	local spot = pileSpot(plot, tier)
	for i = 1, count do
		-- the pile grows wider and taller with every piece on it
		local n = #existing + i
		local radius = 2.2 + math.sqrt(n) * 0.75
		local height = 0.6 + math.sqrt(n) * 0.75
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
	local tray = plot.model:FindFirstChild("PileTray")
	if tray then
		tray:Destroy()
	end
end

local function sell(player: Player, data: any, plot: any, auto: boolean)
	local amount = data.scrap
	if amount <= 0 then
		return
	end
	data.scrap = 0
	data.cash += amount
	api.sync(player)
	local where = if plot.shop then plot.shop.hopper.Position else plot.origin.Position
	Sold:FireAllClients({ plot = plot.index, position = where, amount = amount, owner = player, auto = auto })
end

local function step()
	local S = Config.Scrap
	local now = os.clock()
	for _, plot in api.plots() do
		local owner: Player? = plot.owner
		if not owner then
			continue
		end
		local data = api.getData(owner)
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
			if auto then
				sell(owner, data, plot, true)
			else
				api.sync(owner)
				Picked:FireClient(owner, { value = picked, total = data.scrap })
			end
		end
		-- standing on the sell pad
		if data.scrap > 0 and plot.shop then
			local pad: BasePart = plot.shop.pad
			local d = Vector3.new(pad.Position.X - root.Position.X, 0, pad.Position.Z - root.Position.Z).Magnitude
			if d <= S.SellRadius and math.abs(pad.Position.Y - root.Position.Y) < 6 then
				sell(owner, data, plot, false)
			end
		end
	end
end

function Scrap.start(a: Api)
	api = a
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
