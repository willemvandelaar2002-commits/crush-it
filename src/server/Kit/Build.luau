--!strict
-- Reusable world pieces in the studded block style (pairs with shared/Kit/Style).
--
--   Build.block(parent, name, size, cf, color, studFaces?)    a studded part
--   Build.platform(parent, name, topCf, w, d, h, color, edgeColor, edge?)
--        a slab whose TOP surface is at topCf, with a raised darker rim
--   Build.inset(parent, name, topCf, w, d, color, edgeColor)  a framed patch lying on a surface
--   Build.signFrame(parent, baseCf, w, h, frameColor) -> (Model, facePart)
--        chunky studded sign on two posts; draw on facePart's Back face (+Z)
--   Build.label(adornee, text, color, offsetY, sizeStuds?) -> BillboardGui
--        big floating outlined label ("Smelt" style)
--   Build.lighting(preset)                                    cartoon lighting: Day, Sunset, GoldenHour, Dusk, Smog
--
-- Props (blocky + studded; `palette` is Style.theme(...), `rng` a Random for variety):
--   Build.tree(parent, baseCf, scale, palette, rng?)    trunk + stacked leaf cubes
--   Build.bush(parent, baseCf, scale, palette, rng?)    two or three leaf cubes on the ground
--   Build.rock(parent, baseCf, scale, palette, rng?)    a cluster of tilted grey blocks
--   Build.fence(parent, fromPos, toPos, color, opts?)   posts + two long rails between two ground points
--   Build.lamp(parent, baseCf, palette, height?)        post with a glowing head (Neon + PointLight)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local Build = {}

function Build.block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, studFaces: { Enum.NormalId }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.CFrame = cf
	p.Color = color
	Style.studs(p, studFaces or { Enum.NormalId.Top })
	p.Parent = parent
	return p
end

function Build.platform(parent: Instance, name: string, topCf: CFrame, w: number, d: number, h: number, color: Color3, edgeColor: Color3, edge: number?): Model
	local m = Instance.new("Model")
	m.Name = name
	local e = edge or 1.5
	local lip = 0.35
	Build.block(m, "Top", Vector3.new(w - e * 2, h, d - e * 2), topCf * CFrame.new(0, -h / 2, 0), color)
	local sides = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	Build.block(m, "Edge", Vector3.new(w, h + lip, e), topCf * CFrame.new(0, (lip - h) / 2, d / 2 - e / 2), edgeColor, sides)
	Build.block(m, "Edge", Vector3.new(w, h + lip, e), topCf * CFrame.new(0, (lip - h) / 2, -d / 2 + e / 2), edgeColor, sides)
	Build.block(m, "Edge", Vector3.new(e, h + lip, d - e * 2), topCf * CFrame.new(w / 2 - e / 2, (lip - h) / 2, 0), edgeColor, sides)
	Build.block(m, "Edge", Vector3.new(e, h + lip, d - e * 2), topCf * CFrame.new(-w / 2 + e / 2, (lip - h) / 2, 0), edgeColor, sides)
	m.Parent = parent
	return m
end

function Build.inset(parent: Instance, name: string, topCf: CFrame, w: number, d: number, color: Color3, edgeColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = name
	local e = 1
	Build.block(m, "Fill", Vector3.new(w, 0.1, d), topCf * CFrame.new(0, 0.05, 0), color)
	for _, z in { -1, 1 } do
		Build.block(m, "Frame", Vector3.new(w + e * 2, 0.25, e), topCf * CFrame.new(0, 0.125, z * (d / 2 + e / 2)), edgeColor)
	end
	for _, x in { -1, 1 } do
		Build.block(m, "Frame", Vector3.new(e, 0.25, d), topCf * CFrame.new(x * (w / 2 + e / 2), 0.125, 0), edgeColor)
	end
	m.Parent = parent
	return m
end

function Build.signFrame(parent: Instance, baseCf: CFrame, w: number, h: number, frameColor: Color3): (Model, Part)
	local m = Instance.new("Model")
	m.Name = "Sign"
	local postH = 3.5
	local all = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	for _, side in { -1, 1 } do
		Build.block(m, "Post", Vector3.new(1.8, postH + 1, 1.8), baseCf * CFrame.new(side * (w / 2 - 0.6), (postH + 1) / 2, 0), frameColor, all)
	end
	local border = 1
	Build.block(m, "Frame", Vector3.new(w + border * 2, h + border * 2, 1.4), baseCf * CFrame.new(0, postH + border + h / 2, 0), frameColor, all)
	local face = Build.block(m, "Face", Vector3.new(w, h, 0.4), baseCf * CFrame.new(0, postH + border + h / 2, 0.55), Style.darken(frameColor, 0.45), {})
	m.WorldPivot = baseCf
	m.Parent = parent
	return m, face
end

function Build.label(adornee: BasePart, text: string, color: Color3, offsetY: number, sizeStuds: Vector2?): BillboardGui
	local size = sizeStuds or Vector2.new(16, 4)
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatLabel"
	gui.Size = UDim2.fromScale(size.X, size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	Style.text(label, 4)
	label.TextColor3 = color
	gui.Parent = adornee
	return gui
end

-- Presets (all cartoon-bright, they only change mood):
--   "Day"        bright noon, blue sky
--   "Sunset"     low warm sun, pink/orange haze, sun rays
--   "GoldenHour" earlier and brighter than Sunset: everything golden
--   "Dusk"       sun just down: purple-blue sky, warm horizon, stars, lamps glow
--   "Smog"       hazy orange industrial sky, thick atmosphere
local PRESETS = {
	Day = {
		clock = 13.5, lat = 41.7, brightness = 2.2, exposure = 0, ambient = Color3.fromRGB(90, 90, 105), outdoor = Color3.fromRGB(128, 128, 140),
		sat = 0.08, contrast = 0.06, tint = Color3.new(1, 1, 1), bloom = 0.2, threshold = 2, rays = false,
		density = 0.2, offset = 0, haze = 0.5, glare = 0.2, color = Color3.fromRGB(200, 230, 255), decay = Color3.fromRGB(120, 170, 220), stars = 3000, sun = 21,
	},
	Sunset = {
		clock = 17.25, lat = 30, brightness = 3.2, exposure = 0.25, ambient = Color3.fromRGB(130, 112, 118), outdoor = Color3.fromRGB(200, 170, 160),
		sat = 0.15, contrast = 0.08, tint = Color3.fromRGB(255, 236, 218), bloom = 0.35, threshold = 1.6, rays = true,
		density = 0.26, offset = 0.15, haze = 1.6, glare = 0.8, color = Color3.fromRGB(255, 190, 150), decay = Color3.fromRGB(190, 95, 110), stars = 600, sun = 18,
	},
	GoldenHour = {
		clock = 16.4, lat = 35, brightness = 3, exposure = 0.15, ambient = Color3.fromRGB(125, 110, 95), outdoor = Color3.fromRGB(190, 165, 130),
		sat = 0.18, contrast = 0.08, tint = Color3.fromRGB(255, 240, 215), bloom = 0.3, threshold = 1.7, rays = true,
		density = 0.22, offset = 0.1, haze = 1.1, glare = 0.6, color = Color3.fromRGB(255, 215, 160), decay = Color3.fromRGB(230, 150, 90), stars = 0, sun = 20,
	},
	Dusk = {
		clock = 18.35, lat = 28, brightness = 2.4, exposure = 0.45, ambient = Color3.fromRGB(120, 105, 140), outdoor = Color3.fromRGB(150, 130, 175),
		sat = 0.2, contrast = 0.1, tint = Color3.fromRGB(240, 230, 255), bloom = 0.5, threshold = 1.3, rays = false,
		density = 0.3, offset = 0.2, haze = 2, glare = 0.4, color = Color3.fromRGB(255, 160, 140), decay = Color3.fromRGB(110, 80, 160), stars = 3000, sun = 14,
	},
	Smog = {
		clock = 15.6, lat = 30, brightness = 2.7, exposure = 0.2, ambient = Color3.fromRGB(125, 105, 90), outdoor = Color3.fromRGB(180, 150, 120),
		sat = 0.05, contrast = 0.1, tint = Color3.fromRGB(255, 228, 195), bloom = 0.25, threshold = 1.8, rays = true,
		density = 0.4, offset = 0.05, haze = 2.6, glare = 0.3, color = Color3.fromRGB(230, 170, 110), decay = Color3.fromRGB(150, 100, 70), stars = 0, sun = 24,
	},
}
Build.SkyPresets = PRESETS

function Build.lighting(preset: string?)
	local p = PRESETS[preset or "Day"] or PRESETS.Day
	Lighting.ClockTime = p.clock
	Lighting.GeographicLatitude = p.lat
	Lighting.Brightness = p.brightness
	Lighting.ExposureCompensation = p.exposure
	Lighting.Ambient = p.ambient
	Lighting.OutdoorAmbient = p.outdoor
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ShadowSoftness = 0.3
	local function effect(class: string, name: string): any
		local e = Lighting:FindFirstChild(name) or Instance.new(class)
		e.Name = name
		e.Parent = Lighting
		return e
	end
	local cc = effect("ColorCorrectionEffect", "KitColor")
	cc.Saturation = p.sat
	cc.Contrast = p.contrast
	cc.Brightness = 0
	cc.TintColor = p.tint
	local bloom = effect("BloomEffect", "KitBloom")
	bloom.Intensity = p.bloom
	bloom.Size = 24
	bloom.Threshold = p.threshold
	local rays = effect("SunRaysEffect", "KitSunRays")
	rays.Enabled = p.rays
	rays.Intensity = 0.06
	rays.Spread = 0.6
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = p.density
	atmo.Offset = p.offset
	atmo.Haze = p.haze
	atmo.Glare = p.glare
	atmo.Color = p.color
	atmo.Decay = p.decay
	atmo.Parent = Lighting
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.SunAngularSize = p.sun
	sky.MoonAngularSize = 11
	sky.CelestialBodiesShown = true
	sky.StarCount = p.stars
	sky.Parent = Lighting
end

-- Props --------------------------------------------------------------------------

local ALL_SIDES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local function vary(c: Color3, rng: Random?, amount: number): Color3
	if not rng then
		return c
	end
	local f = (rng:NextNumber() - 0.5) * 2 * amount
	return if f > 0 then Style.lighten(c, f) else Style.darken(c, -f)
end

local function prop(parent: Instance, name: string, baseCf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = name
	m.WorldPivot = baseCf
	m.Parent = parent
	return m
end

-- A blocky tree: square trunk with a darker foot and two or three leaf cubes stacked
-- and twisted on top. Roughly 5 x 12 x 5 studs at scale 1. baseCf sits on the ground.
function Build.tree(parent: Instance, baseCf: CFrame, scale: number, palette: { [string]: Color3 }, rng: Random?): Model
	local m = prop(parent, "Tree", baseCf)
	local s = scale
	local trunkH = 5 * s
	local trunk = vary(palette.trunk, rng, 0.08)
	Build.block(m, "Trunk", Vector3.new(1.6 * s, trunkH, 1.6 * s), baseCf * CFrame.new(0, trunkH / 2, 0), trunk, ALL_SIDES)
	Build.block(m, "Root", Vector3.new(2.4 * s, 0.8 * s, 2.4 * s), baseCf * CFrame.new(0, 0.4 * s, 0), Style.darken(trunk, 0.15), ALL_SIDES)
	local leaf = vary(palette.leaf, rng, 0.12)
	local twist = if rng then rng:NextNumber() * math.pi else 0
	local big = 6 * s
	local y = trunkH + big / 2 - 0.6 * s
	Build.block(m, "Leaves", Vector3.new(big, big * 0.85, big), baseCf * CFrame.new(0, y, 0) * CFrame.Angles(0, twist, 0), leaf, ALL_SIDES)
	local mid = 4.2 * s
	y += big * 0.85 / 2 + mid * 0.35
	Build.block(m, "Leaves", Vector3.new(mid, mid * 0.8, mid), baseCf * CFrame.new(0, y, 0) * CFrame.Angles(0, twist + math.rad(45), 0), Style.lighten(leaf, 0.1), ALL_SIDES)
	if not rng or rng:NextNumber() < 0.6 then
		local top = 2.4 * s
		y += mid * 0.8 / 2 + top * 0.3
		Build.block(m, "Leaves", Vector3.new(top, top * 0.8, top), baseCf * CFrame.new(0, y, 0) * CFrame.Angles(0, twist, 0), Style.lighten(leaf, 0.2), ALL_SIDES)
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Leaves" then
			p.CanCollide = false
		end
	end
	return m
end

-- Low leaf cubes sitting on the ground.
function Build.bush(parent: Instance, baseCf: CFrame, scale: number, palette: { [string]: Color3 }, rng: Random?): Model
	local m = prop(parent, "Bush", baseCf)
	local leaf = vary(Style.darken(palette.leaf, 0.08), rng, 0.1)
	local n = if rng then rng:NextInteger(2, 3) else 2
	for i = 1, n do
		local size = (if i == 1 then 3.4 else 2.4) * scale
		local a = if rng then rng:NextNumber() * math.pi * 2 else i * 2
		local off = if i == 1 then Vector3.zero else Vector3.new(math.cos(a), 0, math.sin(a)) * 1.8 * scale
		local p = Build.block(m, "Leaves", Vector3.new(size, size * 0.75, size), baseCf * CFrame.new(off.X, size * 0.75 / 2, off.Z) * CFrame.Angles(0, a, 0), Style.lighten(leaf, (i - 1) * 0.08), ALL_SIDES)
		p.CanCollide = false
	end
	return m
end

-- One big tilted block with one or two smaller ones leaning against it, partly sunk.
function Build.rock(parent: Instance, baseCf: CFrame, scale: number, palette: { [string]: Color3 }, rng: Random?): Model
	local m = prop(parent, "Rock", baseCf)
	local r = rng or Random.new(1)
	local n = r:NextInteger(2, 3)
	for i = 1, n do
		local size = (if i == 1 then 4 else 2.2 + r:NextNumber()) * scale
		local sz = Vector3.new(size, size * (0.6 + r:NextNumber() * 0.3), size * (0.8 + r:NextNumber() * 0.3))
		local a = r:NextNumber() * math.pi * 2
		local off = if i == 1 then Vector3.zero else Vector3.new(math.cos(a), 0, math.sin(a)) * 2.6 * scale
		local cf = baseCf * CFrame.new(off.X, sz.Y * 0.35, off.Z)
			* CFrame.Angles(math.rad(r:NextNumber(-12, 12)), a, math.rad(r:NextNumber(-12, 12)))
		Build.block(m, "Stone", sz, cf, vary(palette.rock, r, 0.1), ALL_SIDES)
	end
	return m
end

-- Fence from one ground point to another: posts every `spacing` studs (default 10)
-- with a cap, and two long rails. opts = { height?, spacing? }.
function Build.fence(parent: Instance, from: Vector3, to: Vector3, color: Color3, opts: { height: number?, spacing: number? }?): Model
	local o = opts or {}
	local h = o.height or 4
	local spacing = o.spacing or 10
	local m = Instance.new("Model")
	m.Name = "Fence"
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local len = flat.Magnitude
	local dir = CFrame.lookAt(from, from + flat)
	local count = math.max(1, math.round(len / spacing))
	local postColor = Style.darken(color, 0.12)
	for i = 0, count do
		local cf = dir * CFrame.new(0, h / 2, -len * i / count)
		Build.block(m, "Post", Vector3.new(1.2, h, 1.2), cf, postColor, ALL_SIDES)
		Build.block(m, "Cap", Vector3.new(1.6, 0.5, 1.6), cf * CFrame.new(0, h / 2 + 0.25, 0), color, ALL_SIDES)
	end
	for _, y in { h * 0.4, h * 0.8 } do
		Build.block(m, "Rail", Vector3.new(0.5, 0.7, len), dir * CFrame.new(0, y, -len / 2), color, ALL_SIDES)
	end
	m.WorldPivot = dir
	m.Parent = parent
	return m
end

-- Street lamp: studded base, thin post and a glowing head block with a cap.
function Build.lamp(parent: Instance, baseCf: CFrame, palette: { [string]: Color3 }, height: number?): Model
	local m = prop(parent, "Lamp", baseCf)
	local h = height or 10
	local dark = palette.dark
	Build.block(m, "Base", Vector3.new(2.4, 1, 2.4), baseCf * CFrame.new(0, 0.5, 0), dark, ALL_SIDES)
	Build.block(m, "Post", Vector3.new(0.8, h, 0.8), baseCf * CFrame.new(0, h / 2 + 1, 0), dark, {})
	local head = Build.block(m, "Light", Vector3.new(2, 2, 2), baseCf * CFrame.new(0, h + 2, 0), palette.lamp, {})
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	Build.block(m, "Cap", Vector3.new(2.8, 0.6, 2.8), baseCf * CFrame.new(0, h + 3.3, 0), dark, ALL_SIDES)
	local light = Instance.new("PointLight")
	light.Color = palette.lamp
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = head
	return m
end

return Build
