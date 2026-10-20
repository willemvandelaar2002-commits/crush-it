--!strict
-- Helpers: Mini Presses round the big press (after the Yuzu game's
-- capybaras and Destroy a Vault's tanks). data.helpers = { level, ... } (one per
-- slot, max Config.Helpers.Slots). Every Tick seconds each one "crushes" and its
-- value goes into the owner's smelter (Scrap.feed). Two yards of 4 on the front
-- half of the plot, either side of the conveyor; pads next to them:
--   Buy Mini Press  -> a level 1 helper in the next free slot (cash)
--   Merge           -> 3 helpers of the same level become 1 of the next level
-- Models are rebuilt whenever the list changes; the client animates the rams
-- (tag "HelperRam", Helpers.client.luau).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)
local Pads = require(script.Parent.Pads)

export type Api = {
	getData: (Player) -> any,
	sync: (Player) -> (),
	plots: () -> { any },
	feed: (Player, any, any, number) -> (), -- Scrap.feed(player, data, plot, amount)
	mult: (Player, any) -> number, -- cash multipliers (rebirth, collection, 2x, friends)
}

local Helpers = {}

local C = Color3.fromRGB
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local SLOT = 11
local GREEN = C(130, 255, 90)
local RED = C(255, 95, 85)

local api: Api = nil :: any

-- Slot ground positions in plot-local space: front half of the plot, clear of
-- the biggest press (its bed reaches z = 30.5), the conveyor (x = 0) and the
-- path from the hub bridge (x = 16). Inner row first, so new ones sit by the press.
local YARDS = { { x = { -30, -44 } }, { x = { 34, 48 } } }
local ROWS = { 39, 52 }
function Helpers.slotOffsets(): { Vector3 }
	local out = {}
	for _, yard in YARDS do
		for _, z in ROWS do
			for _, x in yard.x do
				table.insert(out, Vector3.new(x, 0, z))
			end
		end
	end
	return out
end

local function padOffsets(): (Vector3, Vector3)
	return Vector3.new(-15, 0, 45.5), Vector3.new(23.5, 0, 45.5)
end

-- The yards: slot bases with white corner brackets, and the Buy / Merge pads.
function Helpers.build(plotModel: Model, origin: CFrame)
	local m = Instance.new("Model")
	m.Name = "HelperYard"
	local pal = Style.theme(Config.Look.Theme)
	-- dark asphalt under each yard (Destroy a Vault's unit zones)
	for _, x in { -37, 41 } do
		Build.block(m, "YardZone", Vector3.new(27, 0.1, 26), origin * CFrame.new(x, 0.05, 45.5), pal.pad or C(52, 54, 62)).CanCollide = false
	end
	for i, off in Helpers.slotOffsets() do
		local cf = origin * CFrame.new(off)
		local base = Build.block(m, "Slot" .. i, Vector3.new(SLOT, 0.16, SLOT), cf * CFrame.new(0, 0.08, 0), C(46, 48, 56))
		base:SetAttribute("Slot", i)
		-- white L brackets in the corners
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = cf * CFrame.new(sx * (SLOT / 2 - 0.9), 0.2, sz * (SLOT / 2 - 0.9))
				Build.block(m, "Bracket", Vector3.new(2.4, 0.1, 0.45), corner * CFrame.new(-sx * 0.75, 0, sz * 0.0), C(245, 245, 250), {})
				Build.block(m, "Bracket", Vector3.new(0.45, 0.1, 2.4), corner * CFrame.new(0, 0, -sz * 0.75), C(245, 245, 250), {})
			end
		end
	end
	local buyOff, mergeOff = padOffsets()
	Pads.make(m, origin * CFrame.new(buyOff), "BuyHelper", C(255, 140, 50), "Buy Mini Press")
	Pads.make(m, origin * CFrame.new(mergeOff), "MergeHelpers", C(120, 120, 135), "Merge!")
	local _ = pal
	m.Parent = plotModel
end

local function helperModel(parent: Instance, cf: CFrame, level: number, owner: Player, value: number)
	local H = Config.Helpers
	local color = H.Colors[math.min(level, #H.Colors)]
	local dark = Style.darken(color, 0.45)
	local m = Instance.new("Model")
	m.Name = "Helper"
	Build.block(m, "Base", Vector3.new(7, 0.8, 7), cf * CFrame.new(0, 0.6, 0), dark, ALL)
	local bed = Build.block(m, "Bed", Vector3.new(4.2, 0.6, 4.2), cf * CFrame.new(0, 1.3, 0), C(60, 62, 72), ALL)
	for _, x in { -1, 1 } do
		Build.block(m, "Pillar", Vector3.new(1.3, 7.5, 1.3), cf * CFrame.new(x * 2.9, 1 + 3.75, 0), color, ALL)
	end
	Build.block(m, "Beam", Vector3.new(7.4, 1.5, 2.2), cf * CFrame.new(0, 9.2, 0), color, ALL)
	Build.block(m, "Cylinder", Vector3.new(1.8, 2, 1.8), cf * CFrame.new(0, 7.6, 0), dark, ALL)
	-- ram (the client moves it between RestY and HitY)
	local ram = Build.block(m, "Ram", Vector3.new(3.6, 0.9, 3.6), cf * CFrame.new(0, 6, 0), Style.lighten(color, 0.2), ALL)
	ram.CanCollide = false
	ram:SetAttribute("RestY", ram.Position.Y)
	ram:SetAttribute("HitY", bed.Position.Y + 0.3 + 1.5 + 0.45)
	ram:SetAttribute("Period", H.Tick)
	ram:SetAttribute("Value", value)
	ram:SetAttribute("Owner", owner.UserId)
	CollectionService:AddTag(ram, "HelperRam")
	-- the thing being crushed
	local obj = Build.block(m, "Object", Vector3.new(2.4, 1.5, 2.4), cf * CFrame.new(0, 1.6 + 0.75, 0), C(255, 120, 90), ALL)
	obj.CanCollide = false
	ram:SetAttribute("ObjectName", obj.Name)
	-- label
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(8, 2.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 11.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Parent = bed
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.55)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Text = H.Names[math.min(level, #H.Names)] .. (if level > #H.Names then " +" .. (level - #H.Names) else "")
	title.Parent = gui
	Style.text(title, 3)
	title.TextColor3 = Style.lighten(color, 0.25)
	local rate = Instance.new("TextLabel")
	rate.Name = "Rate"
	rate.Position = UDim2.fromScale(0, 0.55)
	rate.Size = UDim2.fromScale(1, 0.45)
	rate.BackgroundTransparency = 1
	rate.TextScaled = true
	rate.Text = Format.cash(value) .. " / " .. H.Tick .. "s"
	rate.Parent = gui
	Style.text(rate, 2.5)
	rate.TextColor3 = GREEN
	m.Parent = parent
end

local function value(player: Player, data: any, level: number): number
	return Config.Helpers.Value(level, data.tier) * api.mult(player, data)
end

-- Rebuilds the helper models on a plot.
function Helpers.refresh(plot: any)
	local old = plot.model:FindFirstChild("Helpers")
	if old then
		old:Destroy()
	end
	if not api then
		return -- Helpers.start refreshes every plot once it runs
	end
	local owner: Player? = plot.owner
	local data = owner and api.getData(owner)
	if not owner or not data then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "Helpers"
	for i, level in data.helpers do
		local off = Helpers.slotOffsets()[i]
		if off then
			helperModel(folder, plot.origin * CFrame.new(off), level, owner, value(owner, data, level))
		end
	end
	folder.Parent = plot.model
end

-- Which level can merge (lowest level with 3+), or nil.
local function mergeable(list: { number }): number?
	local counts: { [number]: number } = {}
	for _, l in list do
		counts[l] = (counts[l] or 0) + 1
	end
	local best: number? = nil
	for l, n in counts do
		if n >= 3 and (best == nil or l < best) then
			best = l
		end
	end
	return best
end

local function labels(plot: any, owner: Player?, data: any)
	local yard = plot.model:FindFirstChild("HelperYard")
	if not yard then
		return
	end
	local buy = yard:FindFirstChild("Pad_BuyHelper") :: BasePart?
	local merge = yard:FindFirstChild("Pad_MergeHelpers") :: BasePart?
	if not buy or not merge then
		return
	end
	if not owner or not data then
		Pads.label(buy, "Buy Mini Press", "")
		Pads.label(merge, "Merge!", "")
		return
	end
	local n = #data.helpers
	if n >= Config.Helpers.Slots then
		Pads.label(buy, "Slots Full", "Merge them!", RED)
	else
		local cost = Config.Helpers.Cost(n, data.tier)
		Pads.label(buy, "Buy Mini Press", Format.cash(cost), if data.cash >= cost then GREEN else RED)
	end
	local lv = mergeable(data.helpers)
	if lv then
		Pads.label(merge, "Merge!", "3x Lv " .. lv .. " > Lv " .. (lv + 1), GREEN)
	else
		Pads.label(merge, "Merge!", "Need 3 the same", RED)
	end
end

function Helpers.start(a: Api)
	api = a
	for _, plot in a.plots() do
		if plot.owner then
			Helpers.refresh(plot)
		end
	end
	local Notice = Net.event("Notice")
	local Purchased = Net.event("Purchased")
	local standing: { [Player]: { id: string?, nextAt: number } } = {}
	local tickAt = os.clock() + Config.Helpers.Tick
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local now = os.clock()
		local doTick = now >= tickAt
		if doTick then
			tickAt = now + Config.Helpers.Tick
		end
		for _, plot in api.plots() do
			local owner: Player? = plot.owner
			local data = owner and api.getData(owner)
			labels(plot, owner, data)
			if not owner or not data then
				continue
			end
			-- production
			if doTick and #data.helpers > 0 then
				local total = 0
				for _, level in data.helpers do
					total += value(owner, data, level)
				end
				api.feed(owner, data, plot, total)
			end
			-- pads
			local root = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local yard = plot.model:FindFirstChild("HelperYard")
			if not root or not yard then
				continue
			end
			local state = standing[owner] or { id = nil, nextAt = 0 }
			standing[owner] = state
			local on: string? = nil
			local top: BasePart? = nil
			for _, id in { "BuyHelper", "MergeHelpers" } do
				local p = yard:FindFirstChild("Pad_" .. id) :: BasePart?
				if p and Pads.on(p, root) then
					on = id
					top = p
				end
			end
			if on ~= state.id then
				state.id = on
				state.nextAt = now
			end
			if not on or not top or now < state.nextAt then
				continue
			end
			Pads.press(top)
			if on == "BuyHelper" then
				local n = #data.helpers
				local cost = Config.Helpers.Cost(n, data.tier)
				if n >= Config.Helpers.Slots then
					Notice:FireClient(owner, { text = "All slots full: merge 3 the same!" })
					state.nextAt = math.huge
				elseif data.cash < cost then
					Notice:FireClient(owner, { text = "Not enough cash!" })
					state.nextAt = math.huge
				else
					data.cash -= cost
					table.insert(data.helpers, 1)
					api.sync(owner)
					Helpers.refresh(plot)
					Purchased:FireClient(owner, { id = "Helper", text = "New Mini Press!" })
					state.nextAt = now + 0.6
				end
			else
				local lv = mergeable(data.helpers)
				if lv then
					local removed = 0
					local keep = {}
					for _, l in data.helpers do
						if l == lv and removed < 3 then
							removed += 1
						else
							table.insert(keep, l)
						end
					end
					table.insert(keep, lv + 1)
					table.sort(keep, function(x, y)
						return x > y
					end)
					data.helpers = keep
					api.sync(owner)
					Helpers.refresh(plot)
					Purchased:FireClient(owner, { id = "Helper", text = "MERGED! " .. Config.Helpers.Names[math.min(lv + 1, #Config.Helpers.Names)] })
					state.nextAt = now + 0.8
				else
					Notice:FireClient(owner, { text = "You need 3 Mini Presses of the same level" })
					state.nextAt = math.huge
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		standing[p] = nil
	end)
end

return Helpers
