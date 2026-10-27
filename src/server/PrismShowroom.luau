--!strict
-- Prism Mech showroom: a low decorated pad on every plot (front yard, left of
-- the walkway between the Production board and the Sell station;
-- OfferConfig.Showroom.pad)
-- with the real imported Prism Mech on it. Cosmetic only: it is not a bay and
-- makes no scrap. Every few seconds its ram does one demo stroke.
-- The E prompt (tag "PrismShowroomPrompt") opens the offer in the shop; the
-- client (PrismShowroom.client) adds the name tag, OWNED state and the slow
-- rainbow light, so each viewer sees their own ownership.
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local O = require(RS.Shared.OfferConfig)
local Special = require(script.Parent.SpecialCrushers)
local Plots = require(script.Parent.Plots)

local Showroom = {}
local NAVY = Color3.fromRGB(29, 42, 65)
local GOLD = Color3.fromRGB(255, 216, 72)

local function disc(parent: Instance, name: string, height: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2) -- cylinder axis up
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function build(plot: any): any
	local cfg = O.Showroom.pad
	local base = plot.origin * CFrame.new(cfg.x, 0, cfg.z) * CFrame.Angles(0, cfg.yaw, 0)
	local folder = Instance.new("Model")
	folder.Name = "PrismShowroom"
	local s = cfg.size
	-- low pad: gold skirt, navy deck, a thin glowing ring, navy centre
	disc(folder, "Skirt", 0.35, s + 0.8, base * CFrame.new(0, 0.175, 0), GOLD)
	disc(folder, "Deck", 0.6, s, base * CFrame.new(0, 0.3, 0), NAVY)
	local ring = disc(folder, "GlowRing", 0.08, s - 1.2, base * CFrame.new(0, 0.64, 0), Color3.fromRGB(120, 220, 255), Enum.Material.Neon)
	ring.CanCollide = false
	ring.CanQuery = false
	disc(folder, "Centre", 0.1, s - 2.2, base * CFrame.new(0, 0.66, 0), Color3.fromRGB(44, 60, 92))
	-- four gold studs around the rim
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		disc(folder, "Bolt", 0.25, 0.9, base * CFrame.new(math.cos(a) * (s / 2 - 0.4), 0.72, math.sin(a) * (s / 2 - 0.4)), GOLD)
	end
	local light = Instance.new("PointLight")
	light.Name = "ShowroomLight"
	light.Range = 13
	light.Brightness = 1.1
	light.Shadows = false
	light.Color = ring.Color
	light.Parent = ring
	-- name tag anchor + prompt, above the machine
	local tag = Instance.new("Part")
	tag.Name = "TagAnchor"
	tag.Size = Vector3.new(1, 1, 1)
	tag.Transparency = 1
	tag.CanCollide = false
	tag.CanQuery = false
	tag.CanTouch = false
	tag.Anchored = true
	tag.CFrame = base * CFrame.new(0, 3, s / 2 - 1)
	tag.Parent = folder
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "View offer"
	prompt.ObjectText = O.Showroom.title
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = tag
	CollectionService:AddTag(prompt, "PrismShowroomPrompt")
	folder:SetAttribute("Offer", O.Showroom.id)
	folder:SetAttribute("PlotIndex", plot.index)
	-- the real model, the same fit as a bay (turned to face the walkway, pad.yaw)
	local v = Special.build(base * CFrame.new(0, 0.7, 0), O.Showroom.crusher)
	if v then
		v.model.Name = "ShowroomPrismMech"
		v.model.Parent = folder
		local _, size = v.model:GetBoundingBox()
		tag.CFrame = base * CFrame.new(0, 0.7 + size.Y + 2.2, 0)
	else
		warn("[PrismShowroom] Prism Mech template missing (ServerStorage.SpecialCrusherMeshes); pad only")
	end
	CollectionService:AddTag(folder, "PrismShowroom")
	folder.Parent = plot.model
	return v
end

function Showroom.start()
	local shown = {}
	for _, plot in Plots.all() do
		local ok, v = pcall(build, plot)
		if not ok then warn("[PrismShowroom] " .. tostring(v)) elseif v then table.insert(shown, v) end
	end
	-- demo strokes, staggered per plot so they don't all hit together
	for i, v in shown do
		task.spawn(function()
			task.wait(i * 0.6)
			while v.model.Parent do
				Special.strike(v, { cycle = 1.8, completed = true })
				task.wait(O.Showroom.demoEvery)
			end
		end)
	end
end

return Showroom
