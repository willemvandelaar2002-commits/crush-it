--!strict
-- Walk-on buy pads (the Yuzu game's "Buy 5 Yuzu" pads) and the stats board
-- (its "Selling Yuzu 9.98K, 1 Yuzu/Sec" sign).
--
-- Just inside the entrance gate on the right, opposite the scrap shop, so the
-- whole loop (pile -> deposit -> collect -> buy) is a few steps: front row Power,
-- Speed, Value, Bigger Press, Rebirth; behind it Auto Collect and Auto Crush (Robux).
-- Stand on a pad to buy once; keep standing to keep buying (after a short
-- pause). Only the plot owner can use them. Big floating labels show the name,
-- level and price (green = affordable, red = not yet).
-- Game.server calls Pads.start({ buy = onBuy, plots = Plots.all }).

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(ReplicatedStorage.Shared.Store)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Build = require(script.Parent.Kit.Build)

local Pads = {}

local C = Color3.fromRGB
local BLACK = C(28, 28, 34)
local GREEN = C(120, 255, 90)
local RED = C(255, 95, 85)
local SIZE = 7.5

export type PadDef = { id: string, kind: "upgrade" | "robux", x: number, z: number?, color: Color3 }

Pads.Defs = {
	{ id = "Power", kind = "upgrade", x = 16, color = C(255, 95, 80) },
	{ id = "Speed", kind = "upgrade", x = 25.5, color = C(70, 190, 255) },
	{ id = "Value", kind = "upgrade", x = 35, color = C(255, 210, 60) },
	{ id = "Size", kind = "upgrade", x = 44.5, color = C(190, 90, 255) },
	{ id = "Rebirth", kind = "upgrade", x = 54, color = C(255, 150, 50) },
	{ id = "AutoCollect", kind = "robux", x = 35, z = 14, color = C(255, 185, 70) },
	{ id = "AutoCrush", kind = "robux", x = 44.5, z = 14, color = C(255, 110, 90) },
} :: { PadDef }

local NAMES = { Size = "Bigger Press", AutoCollect = "Auto Collect", AutoCrush = "Auto Crush" }

Pads.ROW_Z = 58 -- local Z of the first pad row (z = 0 is the press, the entrance at Config.Plots.Front)
local PAD_Z = Pads.ROW_Z

local function billboard(adornee: BasePart): (TextLabel, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PadLabel"
	gui.Size = UDim2.fromScale(8.6, 3.6) -- narrower than the 9.5-stud pad spacing, so labels never overlap
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 140
	gui.Adornee = adornee
	gui.Parent = adornee
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.55)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Parent = gui
	Style.text(title, 3)
	local price = Instance.new("TextLabel")
	price.Name = "Price"
	price.Position = UDim2.fromScale(0, 0.52)
	price.Size = UDim2.fromScale(1, 0.48)
	price.BackgroundTransparency = 1
	price.TextScaled = true
	price.Parent = gui
	Style.text(price, 3)
	return title, price
end

-- One walk-on pad: dark frame, coloured studded top ("Pad_<id>", attribute
-- Rest = its resting CFrame for the press-down bounce), a glossy shine and a
-- floating two-line label (PadLabel.Title / PadLabel.Price). cf = ground centre.
function Pads.make(parent: Instance, cf: CFrame, id: string, color: Color3, titleText: string, size: number?): BasePart
	local s = size or SIZE
	Build.block(parent, "PadFrame", Vector3.new(s + 1, 0.3, s + 1), cf * CFrame.new(0, 0.15, 0), BLACK, {})
	local top = Build.block(parent, "Pad_" .. id, Vector3.new(s, 0.5, s), cf * CFrame.new(0, 0.25, 0), color)
	top:SetAttribute("PadId", id)
	top:SetAttribute("Rest", top.CFrame)
	local shine = Build.block(parent, "PadShine", Vector3.new(s - 2, 0.06, s - 2), cf * CFrame.new(0, 0.53, 0), Style.lighten(color, 0.35), {})
	shine.Material = Enum.Material.Neon
	shine.Transparency = 0.55
	local title, price = billboard(top)
	title.Text = titleText
	price.Text = ""
	return top
end

-- Is `root` standing on pad `top`?
function Pads.on(top: BasePart, root: BasePart): boolean
	local rel = top.CFrame:PointToObjectSpace(root.Position)
	local half = top.Size.X / 2 + 0.5
	return math.abs(rel.X) <= half and math.abs(rel.Z) <= half and rel.Y > 0 and rel.Y < 6
end

-- Sets a pad's label (only writes when it changed).
function Pads.label(top: BasePart, title: string, price: string, color: Color3?)
	local gui = top:FindFirstChild("PadLabel") :: any
	if not gui then
		return
	end
	if gui.Title.Text ~= title then
		gui.Title.Text = title
	end
	if gui.Price.Text ~= price then
		gui.Price.Text = price
	end
	if color then
		gui.Price.TextColor3 = color
	end
end

Pads.press = function(top: BasePart)
	local rest = top:GetAttribute("Rest") :: CFrame
	top.CFrame = rest * CFrame.new(0, -0.22, 0)
	TweenService:Create(top, TweenInfo.new(0.25, Enum.EasingStyle.Back), { CFrame = rest }):Play()
end

-- Builds the pads + stats board into plotModel ("Pads" model).
function Pads.build(plotModel: Model, origin: CFrame)
	local m = Instance.new("Model")
	m.Name = "Pads"
	for i, def in Pads.Defs do
		local top = Pads.make(m, origin * CFrame.new(def.x, 0, PAD_Z + (def.z or 0)), def.id, def.color, NAMES[def.id] or def.id)
		-- every other label a bit higher, so neighbours never cover each other
		local gui = top:FindFirstChild("PadLabel") :: BillboardGui?
		if gui and i % 2 == 0 then
			gui.StudsOffsetWorldSpace = Vector3.new(0, 6.8, 0)
		end
	end
	-- stats board (between the pile and the pads, facing the entrance)
	local boardCf = origin * CFrame.new(30, 0, 44) * CFrame.Angles(0, math.rad(-10), 0)
	local board, face = Build.signFrame(m, boardCf, 16, 10, C(40, 42, 50))
	board.Name = "StatsBoard"
	face.Name = "StatsFace"
	face.Color = C(250, 236, 190)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Stats"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = face
	local function line(name: string, y: number, h: number, color: Color3, stroke: number)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Position = UDim2.fromScale(0.05, y)
		l.Size = UDim2.fromScale(0.9, h)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Text = ""
		l.Parent = gui
		Style.text(l, stroke)
		l.TextColor3 = color
	end
	line("Head", 0.05, 0.2, C(255, 214, 80), 4)
	line("Object", 0.25, 0.22, Color3.new(1, 1, 1), 4)
	line("Value", 0.5, 0.25, GREEN, 5)
	line("Count", 0.78, 0.16, C(255, 245, 220), 3)
	m.Parent = plotModel
end

type Api = { buy: (Player, string) -> (), plots: () -> { any } }

local function attr(p: Player, name: string): number
	return (p:GetAttribute(name) :: number?) or 0
end

-- (title, price text, affordable?)
local function describe(player: Player, def: PadDef): (string, string, boolean)
	local cash = attr(player, "Cash")
	if def.kind == "robux" then
		local pass = Store.passByPerk(def.id)
		if not pass then
			return def.id, "", false
		end
		if Store.hasPass(player, def.id) then
			return pass.title, "OWNED", true
		end
		return pass.title, "R$ " .. pass.price, true
	end
	if def.id == "Size" then
		local tier = math.max(1, attr(player, "Tier"))
		if tier >= Config.MaxTier then
			return "Bigger Press", "MAX", false
		end
		local cost = Config.SizeCost(tier)
		return "Bigger Press", Format.cash(cost), cash >= cost
	end
	if def.id == "Rebirth" then
		local r = attr(player, "Rebirths")
		local need = Config.Rebirth.RequiredTier(r)
		if attr(player, "Tier") >= need then
			return "Rebirth", string.format("x%.1f cash!", Config.rebirthMult(r + 1)), true
		end
		return "Rebirth", "Reach " .. Config.Objects[need].name, false
	end
	for _, u in Config.Upgrades do
		if u.id == def.id then
			local lv = attr(player, def.id .. "Lv")
			if lv >= u.max then
				return u.title .. " MAX", "", false
			end
			local cost = u.cost(lv)
			return u.title .. " Lv " .. (lv + 1), Format.cash(cost), cash >= cost
		end
	end
	return def.id, "", false
end

local function press(top: BasePart)
	local rest = top:GetAttribute("Rest") :: CFrame
	top.CFrame = rest * CFrame.new(0, -0.22, 0)
	TweenService:Create(top, TweenInfo.new(0.25, Enum.EasingStyle.Back), { CFrame = rest }):Play()
end

function Pads.start(api: Api)
	local Notice = Net.event("Notice")
	-- per player: which pad they stand on and when it fires next
	local standing: { [Player]: { id: string?, nextAt: number, fired: boolean } } = {}
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local now = os.clock()
		for _, plot in api.plots() do
			local pads = plot.model:FindFirstChild("Pads")
			local owner: Player? = plot.owner
			if not pads then
				continue
			end
			-- labels
			for _, def in Pads.Defs do
				local top = pads:FindFirstChild("Pad_" .. def.id) :: BasePart?
				local gui = top and top:FindFirstChild("PadLabel")
				if not gui then
					continue
				end
				local title, price = (gui :: any).Title :: TextLabel, (gui :: any).Price :: TextLabel
				if owner then
					local t, p, ok = describe(owner, def)
					if title.Text ~= t then
						title.Text = t
					end
					if price.Text ~= p then
						price.Text = p
					end
					price.TextColor3 = if def.kind == "robux" then GREEN elseif ok then GREEN else RED
				elseif title.Text ~= (NAMES[def.id] or def.id) then
					title.Text = NAMES[def.id] or def.id
					price.Text = ""
				end
			end
			-- stats board
			local face = pads:FindFirstChild("StatsFace", true)
			local stats = face and face:FindFirstChild("Stats")
			if stats then
				local s = stats :: any
				if owner then
					s.Head.Text = "Now Crushing"
					s.Object.Text = tostring(owner:GetAttribute("ObjName") or "")
					s.Value.Text = Format.cash(attr(owner, "CrushValue")) .. " / crush"
					s.Count.Text = "Crushed: " .. Format.compact(attr(owner, "Crushed"))
				else
					s.Head.Text = "Free plot"
					s.Object.Text = ""
					s.Value.Text = ""
					s.Count.Text = ""
				end
			end
			-- stepping
			if not owner then
				continue
			end
			local character = owner.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				continue
			end
			local state = standing[owner] or { id = nil, nextAt = 0, fired = false }
			standing[owner] = state
			local on: string? = nil
			local onTop: BasePart? = nil
			for _, def in Pads.Defs do
				local top = pads:FindFirstChild("Pad_" .. def.id) :: BasePart?
				if top then
					local rel = top.CFrame:PointToObjectSpace(root.Position)
					if math.abs(rel.X) <= SIZE / 2 + 0.5 and math.abs(rel.Z) <= SIZE / 2 + 0.5 and rel.Y > 0 and rel.Y < 6 then
						on = def.id
						onTop = top
					end
				end
			end
			if on ~= state.id then
				state.id = on
				state.fired = false
				state.nextAt = now -- fire straight away on stepping on
				if on == "Rebirth" then
					local _, _, ok = describe(owner, Pads.Defs[5])
					if ok then
						-- no accidental rebirths: stand still for 2 seconds
						state.nextAt = now + 2
						Notice:FireClient(owner, { text = "Stay on the pad to REBIRTH..." })
					end
				end
			end
			if on and onTop and now >= state.nextAt then
				local def: PadDef? = nil
				for _, d in Pads.Defs do
					if d.id == on then
						def = d
					end
				end
				assert(def)
				press(onTop)
				if def.kind == "robux" then
					state.nextAt = math.huge -- once per step
					local pass = Store.passByPerk(on)
					if pass and not Store.hasPass(owner, on) then
						if pass.gamePassId == 0 then
							Notice:FireClient(owner, { text = pass.title .. ": coming soon!" })
						else
							MarketplaceService:PromptGamePassPurchase(owner, pass.gamePassId)
						end
					end
				elseif on == "Rebirth" then
					state.nextAt = math.huge
					api.buy(owner, on)
				else
					-- buy now, then keep buying while standing on it (no "not enough cash" spam)
					local _, _, ok = describe(owner, def)
					if ok or not state.fired then
						api.buy(owner, on)
					end
					state.nextAt = now + (if state.fired then 0.3 else 0.7)
					state.fired = true
				end
			end
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		standing[p] = nil
	end)
end

return Pads
