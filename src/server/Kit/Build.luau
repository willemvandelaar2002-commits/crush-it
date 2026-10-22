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
--   Build.path(parent, a, b, width, color?)                   concrete service lane with kerbs and painted markings
--   Build.island(parent, topCf, w, d, seaY, palette, opts?)   island body under a floor: dirt, stone sides, rocks, curb
--   Build.patch(parent, cf, w, d, color, rng?, name?)         stepped-outline asphalt patch on a floor
--   Build.bridge(parent, a, b, width, palette, seaY?)        chunky concrete bridge with block posts
--   Build.lava(parent, surfaceCf, length, width, opts?)       lava strip (crust, glowing rims, drifting blobs, embers) -> (Model, floor)
--   Build.bank(parent, cf, length, height, thickness?)        basalt curb along a lava strip
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
local CollectionService = game:GetService("CollectionService")
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
--   "FactoryDay" sunny skylit interior, clear colour and soft ambient fill
--   "YardDay"    warm clear daylight, soft shadows, restrained bloom and haze
--   "Day"        bright noon, blue sky
--   "Sunset"     low warm sun, pink/orange haze, sun rays
--   "GoldenHour" earlier and brighter than Sunset: everything golden
--   "Dusk"       sun just down: purple-blue sky, warm horizon, stars, lamps glow
--   "Smog"       hazy orange industrial sky, thick atmosphere
local PRESETS = {
	FactoryDay = {
		clock = 13.5, lat = 25, brightness = 2.4, exposure = 0, ambient = Color3.fromRGB(121, 129, 145), outdoor = Color3.fromRGB(174, 171, 163),
		sat = 0.02, contrast = 0.05, tint = Color3.fromRGB(255, 252, 245), bloom = 0.04, threshold = 2.6, rays = false,
		density = 0.08, offset = 0, haze = 0.12, glare = 0, color = Color3.fromRGB(222, 238, 250), decay = Color3.fromRGB(185, 207, 226), stars = 0, sun = 12,
	},
	YardDay = {
		clock = 14, lat = 35, brightness = 2, exposure = -0.12, ambient = Color3.fromRGB(110, 104, 94), outdoor = Color3.fromRGB(145, 142, 130),
		sat = 0.04, contrast = 0.03, tint = Color3.fromRGB(255, 252, 246), bloom = 0.08, threshold = 2.4, rays = false,
		density = 0.14, offset = 0, haze = 0.25, glare = 0.03, color = Color3.fromRGB(225, 234, 240), decay = Color3.fromRGB(174, 187, 198), stars = 0, sun = 12,
	},
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
	-- The place also contains older Bloom/SunRays effects. FactoryDay owns
	-- those effects through KitBloom/KitSunRays, so avoid stacking them.
	-- Retain their original state for callers that switch to another preset.
	for _, e in Lighting:GetChildren() do
		if (e:IsA("BloomEffect") and e.Name ~= "KitBloom") or (e:IsA("SunRaysEffect") and e.Name ~= "KitSunRays") then
			local enabled = e:GetAttribute("FactoryPreviousEnabled")
			if preset == "FactoryDay" then
				if enabled == nil then e:SetAttribute("FactoryPreviousEnabled", e.Enabled) end
				e.Enabled = false
			elseif typeof(enabled) == "boolean" then
				e.Enabled = enabled
				e:SetAttribute("FactoryPreviousEnabled", nil)
			end
		end
	end
	Lighting.ClockTime = p.clock
	Lighting.GeographicLatitude = p.lat
	Lighting.Brightness = p.brightness
	Lighting.ExposureCompensation = p.exposure
	Lighting.Ambient = p.ambient
	Lighting.OutdoorAmbient = p.outdoor
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ShadowSoftness = if preset == "YardDay" or preset == "FactoryDay" then 0.65 else 0.3
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
	if preset == "YardDay" or preset == "FactoryDay" then
		-- Engine-bundled cloudy blue sky: proper cube faces instead of the
		-- place's repeated flat side image, with no new uploaded asset dependency.
		sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
		sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
		sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
		sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
		sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
		sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	end
	sky.SunAngularSize = p.sun
	sky.MoonAngularSize = 11
	sky.CelestialBodiesShown = true
	sky.StarCount = p.stars
	sky.Parent = Lighting
end

-- Concrete service lane. Existing widths, elevations and corner overlaps
-- are retained; painted details cannot collide or participate in queries.
function Build.path(parent: Instance, a: Vector3, b: Vector3, width: number, color: Color3?): Model
	local m = Instance.new("Model")
	m.Name = "Path"
	local c = color or Color3.fromRGB(77, 83, 88)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude + width -- overlap the corners
	local mid = CFrame.lookAt(a:Lerp(b, 0.5), a:Lerp(b, 0.5) + flat)
	local top = Build.block(m, "PathTop", Vector3.new(width, 0.12, len), mid * CFrame.new(0, 0.06, 0), c, {})
	top.Material = Enum.Material.Concrete
	top.CanCollide = false
	for _, side in { -1, 1 } do
		local edge = Build.block(m, "PathEdge", Vector3.new(0.6, 0.16, len), mid * CFrame.new(side * (width / 2 + 0.3), 0.08, 0), Color3.fromRGB(184, 188, 182), {})
		edge.CanCollide = false
	end
	local function paint(name: string, size: Vector3, cf: CFrame, tint: Color3)
		local p = Build.block(m, name, size, cf, tint, {})
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
	end
	local white = Color3.fromRGB(234, 236, 224)
	if width >= 8 and len < 100 then
		for z = -2, 2, 2 do
			paint("Crossing", Vector3.new(width * 0.8, 0.025, 0.8), mid * CFrame.new(0, 0.135, z), white)
		end
	elseif len > 50 then
		paint("ArrowShaft", Vector3.new(0.5, 0.025, 3), mid * CFrame.new(0, 0.135, 0), white)
		for _, side in { -1, 1 } do
			paint("ArrowHead", Vector3.new(0.5, 0.025, 2), mid * CFrame.new(side * 0.6, 0.135, -0.9) * CFrame.Angles(0, side * math.pi / 4, 0), white)
		end
	end
	for _, side in { -1, 1 } do
		paint("SafetyEdge", Vector3.new(0.25, 0.025, 4), mid * CFrame.new(side * (width / 2 - 0.4), 0.135, 0), Color3.fromRGB(239, 200, 78))
	end
	m.Parent = parent
	return m
end

-- Islands ----------------------------------------------------------------------
-- Build.island(parent, topCf, w, d, seaY, palette, opts?) -> Model
-- The body UNDER a floor whose top is at topCf: a dirt band, chunky studded stone
-- sides going down past the sea surface (seaY), random rocks at the waterline and a
-- low stone curb along the top edge (gaps where opts.gaps say). Does not build the
-- floor itself. opts = { gaps = { { side = "front"|"back"|"left"|"right", at = number, width = number } }, rng = Random?, curb = boolean? }
function Build.island(parent: Instance, top: CFrame, w: number, d: number, seaY: number, palette: { [string]: Color3 }, opts: { [string]: any }?): Model
	local o = opts or {}
	local rng: Random = o.rng or Random.new(3)
	local m = Instance.new("Model")
	m.Name = "IslandBody"
	local ALL4 = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	local topY = top.Position.Y
	local function level(y: number): CFrame
		return top * CFrame.new(0, y - topY, 0)
	end
	-- dirt band just under the floor, stone body down into the lava
	local dirtTop = topY - 0.4
	local dirtH = 3
	Build.block(m, "Dirt", Vector3.new(w + 0.8, dirtH, d + 0.8), level(dirtTop - dirtH / 2), palette.dirt or Color3.fromRGB(138, 96, 60), ALL4)
	local stoneTop = dirtTop - dirtH
	local stoneBottom = seaY - 6
	local stoneH = stoneTop - stoneBottom
	Build.block(m, "Stone", Vector3.new(w + 2, stoneH, d + 2), level(stoneBottom + stoneH / 2), palette.stone or Color3.fromRGB(132, 130, 140), ALL4)
	-- chunky blocks sticking out of the sides at random heights (breaks the straight wall)
	local stoneDark = palette.stoneDark or Color3.fromRGB(102, 100, 110)
	local function sideBlocks(len: number, place: (number) -> CFrame)
		local t = -len / 2 + rng:NextNumber(2, 6)
		while t < len / 2 - 4 do
			local bw = rng:NextNumber(4, 10)
			local bh = rng:NextNumber(2, stoneH * 0.6)
			local by = stoneBottom + rng:NextNumber(0, stoneH - bh)
			local color = if rng:NextNumber() < 0.5 then stoneDark else (palette.stone or Color3.fromRGB(132, 130, 140))
			Build.block(m, "Rock", Vector3.new(bw, bh, 1.6), place(t + bw / 2) * CFrame.new(0, by + bh / 2 - topY, 0), color, ALL4)
			t += bw + rng:NextNumber(3, 12)
		end
	end
	sideBlocks(w, function(x) return top * CFrame.new(x, 0, d / 2 + 1.4) end)
	sideBlocks(w, function(x) return top * CFrame.new(x, 0, -d / 2 - 1.4) * CFrame.Angles(0, math.pi, 0) end)
	sideBlocks(d, function(z) return top * CFrame.new(w / 2 + 1.4, 0, z) * CFrame.Angles(0, math.pi / 2, 0) end)
	sideBlocks(d, function(z) return top * CFrame.new(-w / 2 - 1.4, 0, z) * CFrame.Angles(0, -math.pi / 2, 0) end)
	-- boulders at the waterline
	for _ = 1, math.floor((w + d) / 14) do
		local side = rng:NextInteger(1, 4)
		local along = rng:NextNumber(-0.5, 0.5)
		local local_: Vector3
		if side == 1 then
			local_ = Vector3.new(along * w, 0, d / 2 + rng:NextNumber(1.5, 3))
		elseif side == 2 then
			local_ = Vector3.new(along * w, 0, -d / 2 - rng:NextNumber(1.5, 3))
		elseif side == 3 then
			local_ = Vector3.new(w / 2 + rng:NextNumber(1.5, 3), 0, along * d)
		else
			local_ = Vector3.new(-w / 2 - rng:NextNumber(1.5, 3), 0, along * d)
		end
		local sz = rng:NextNumber(2.5, 5)
		Build.block(m, "Boulder", Vector3.new(sz, sz * 0.8, sz), top * CFrame.new(local_.X, seaY - topY + sz * 0.15, local_.Z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber() * 6, rng:NextNumber(-0.2, 0.2)), stoneDark, ALL4)
	end
	-- low stone curb along the edge, chunky blocks of random length/height, with gaps
	if o.curb ~= false then
		local gaps = o.gaps or {}
		local function blocked(side: string, t: number): boolean
			for _, g in gaps do
				if g.side == side and math.abs(t - g.at) < g.width / 2 + 0.5 then
					return true
				end
			end
			return false
		end
		local function curb(side: string, len: number, place: (number) -> CFrame)
			local t = -len / 2
			while t < len / 2 do
				local bw = math.min(rng:NextNumber(4, 9), len / 2 - t)
				local mid = t + bw / 2
				if bw > 0.5 and not blocked(side, mid) and not blocked(side, t + 0.2) and not blocked(side, t + bw - 0.2) then
					local bh = rng:NextNumber(1.3, 2.2)
					Build.block(m, "Curb", Vector3.new(bw, bh, 1.8), place(mid) * CFrame.new(0, bh / 2, 0),
						if rng:NextNumber() < 0.3 then stoneDark else (palette.stone or Color3.fromRGB(132, 130, 140)), ALL4)
				end
				t += bw
			end
		end
		curb("front", w, function(x) return top * CFrame.new(x, 0, d / 2 - 0.9) end)
		curb("back", w, function(x) return top * CFrame.new(x, 0, -d / 2 + 0.9) end)
		curb("right", d - 3.6, function(z) return top * CFrame.new(w / 2 - 0.9, 0, z) * CFrame.Angles(0, math.pi / 2, 0) end)
		curb("left", d - 3.6, function(z) return top * CFrame.new(-w / 2 + 0.9, 0, z) * CFrame.Angles(0, math.pi / 2, 0) end)
	end
	m.Parent = parent
	return m
end

-- A stepped-outline patch lying on a floor (Destroy a Vault's dark asphalt zones):
-- a main rectangle plus a few smaller rectangles sticking out of its edges.
function Build.patch(parent: Instance, cf: CFrame, w: number, d: number, color: Color3, rng: Random?, name: string?): Model
	local r = rng or Random.new(5)
	local m = Instance.new("Model")
	m.Name = name or "Patch"
	local function rect(x: number, z: number, rw: number, rd: number)
		local p = Build.block(m, "PatchPart", Vector3.new(rw, 0.1, rd), cf * CFrame.new(x, 0.05, z), color)
		p.CanCollide = false
	end
	rect(0, 0, w, d)
	for _ = 1, r:NextInteger(3, 6) do
		local side = r:NextInteger(1, 4)
		local rw = r:NextNumber(0.2, 0.45) * (if side <= 2 then w else d)
		local depth = r:NextNumber(2.5, 6)
		local t = r:NextNumber(-0.5, 0.5) * ((if side <= 2 then w else d) - rw)
		if side == 1 then
			rect(t, d / 2 + depth / 2, rw, depth)
		elseif side == 2 then
			rect(t, -d / 2 - depth / 2, rw, depth)
		elseif side == 3 then
			rect(w / 2 + depth / 2, t, depth, rw)
		else
			rect(-w / 2 - depth / 2, t, depth, rw)
		end
	end
	m.Parent = parent
	return m
end

-- Concrete service bridge on the existing deck segments and collision shapes.
function Build.bridge(parent: Instance, a: Vector3, b: Vector3, width: number, palette: { [string]: Color3 }, seaY: number?): Model
	local m = Instance.new("Model")
	m.Name = "Bridge"
	local wood = Color3.fromRGB(82, 88, 93)
	local woodDark = palette.woodDark or Color3.fromRGB(48, 67, 94)
	local ALL4 = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local base = CFrame.lookAt(a, a + flat) -- -Z runs from a to b
	local n = math.max(2, math.floor(len / 2.5))
	for i = 0, n - 1 do
		local z = -(i + 0.5) * len / n
		local deck = Build.block(m, "Plank", Vector3.new(width, 0.7, len / n - 0.15), base * CFrame.new(0, -0.35, z), if i % 2 == 0 then wood else Style.lighten(wood, 0.04), { Enum.NormalId.Top })
		deck.Material = Enum.Material.Concrete
	end
	for _, x in { -1, 1 } do
		Build.block(m, "Beam", Vector3.new(0.9, 1, len), base * CFrame.new(x * (width / 2 + 0.2), -0.6, -len / 2), woodDark, ALL4)
		for _, z in { -0.6, -len + 0.6 } do
			Build.block(m, "Post", Vector3.new(2.2, 2.6, 2.2), base * CFrame.new(x * (width / 2 + 0.3), 1.3, z), Color3.fromRGB(184, 188, 182), ALL4)
		end
		Build.block(m, "Rail", Vector3.new(0.6, 0.6, len - 2.4), base * CFrame.new(x * (width / 2 + 0.3), 1.6, -len / 2), woodDark, ALL4)
	end
	if seaY then
		local legs = math.max(0, math.floor(len / 14))
		for i = 1, legs do
			local z = -len * i / (legs + 1)
			local h = a.Y - seaY + 4
			for _, x in { -1, 1 } do
				Build.block(m, "Leg", Vector3.new(1.6, h, 1.6), base * CFrame.new(x * (width / 2 - 0.6), -h / 2 - 0.8, z), woodDark, ALL4)
			end
		end
	end
	m.Parent = parent
	return m
end

-- Lava -------------------------------------------------------------------------
-- Build.lava(parent, surfaceCf, length, width, opts?) -> (Model, floor: Part)
-- A strip of stylised lava whose top surface is at surfaceCf (its X axis runs
-- along the strip): dark cracked crust, glowing edges where it meets the banks,
-- drifting bright blobs and crust plates (tag "LavaDrift"; the client moves
-- them, see Scrap.client.luau), rising embers and orange light. `floor` is an
-- invisible solid part just under the surface: hook its Touched to bounce players.
-- opts = { lights?: boolean (default true), drift?: number speed studs/s (default 1.6) }
local LAVA_CRUST = Color3.fromRGB(110, 28, 10)
local LAVA_GLOW = Color3.fromRGB(255, 120, 20)
local LAVA_HOT = Color3.fromRGB(255, 200, 70)
local BASALT = Color3.fromRGB(48, 44, 46)

function Build.lava(parent: Instance, surface: CFrame, length: number, width: number, opts: { [string]: any }?): (Model, Part)
	local o = opts or {}
	local m = Instance.new("Model")
	m.Name = "Lava"
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		p.Parent = m
		return p
	end
	-- molten glow underneath, crust on top (CrackedLava draws its own glowing cracks)
	part("Molten", Vector3.new(length, 0.3, width), surface * CFrame.new(0, -0.35, 0), LAVA_GLOW, Enum.Material.Neon)
	part("Crust", Vector3.new(length, 0.4, width), surface * CFrame.new(0, -0.2, 0), LAVA_CRUST, Enum.Material.CrackedLava)
	-- white-hot rims along both banks
	for _, side in { -1, 1 } do
		part("Rim", Vector3.new(length, 0.12, 0.45), surface * CFrame.new(0, 0.02, side * (width / 2 - 0.22)), LAVA_HOT, Enum.Material.Neon)
		part("RimGlow", Vector3.new(length, 0.1, 1.1), surface * CFrame.new(0, 0.01, side * (width / 2 - 0.9)), LAVA_GLOW, Enum.Material.Neon).Transparency = 0.45
	end
	-- drifting blobs (bright) and crust plates (dark): the client slides them along X
	local speed = o.drift or 1.6
	local function drifter(name: string, size: Vector3, z: number, y: number, color: Color3, material: Enum.Material, start: number, v: number)
		local p = part(name, size, surface * CFrame.new(-length / 2 + start, y, z) * CFrame.Angles(0, math.random() * 6, 0), color, material)
		p:SetAttribute("Len", length)
		p:SetAttribute("Start", start)
		p:SetAttribute("Speed", v)
		p:SetAttribute("Origin", (surface * CFrame.new(-length / 2, y, z)).Position)
		p:SetAttribute("Axis", surface.XVector)
		CollectionService:AddTag(p, "LavaDrift")
	end
	local n = math.max(1, math.floor(length / 20))
	for i = 1, n do
		local z = (math.random() - 0.5) * (width - 3)
		local d = 0.9 + math.random() * 1.1
		drifter("Blob", Vector3.new(d * 2.2, 0.12, d), z, 0.02, if math.random() < 0.25 then LAVA_HOT else LAVA_GLOW, Enum.Material.Neon,
			(i - math.random()) * length / n, speed * (0.8 + math.random() * 0.4))
	end
	for i = 1, math.max(1, math.floor(length / 13)) do
		local z = (math.random() - 0.5) * (width - 2.6)
		local d = 1.4 + math.random() * 1.8
		drifter("Plate", Vector3.new(d * 1.3, 0.25, d), z, 0.1, Color3.fromRGB(70, 34, 24), Enum.Material.Basalt,
			math.random() * length, speed * (0.6 + math.random() * 0.3))
	end
	-- embers rising, and some orange light
	local emitterPart = part("Embers", Vector3.new(length, 0.1, width), surface, LAVA_GLOW, Enum.Material.SmoothPlastic)
	emitterPart.Transparency = 1
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Rate = math.clamp(length / 4, 3, 30)
	embers.Lifetime = NumberRange.new(1.2, 2.4)
	embers.Speed = NumberRange.new(2.5, 5)
	embers.SpreadAngle = Vector2.new(20, 20)
	embers.Acceleration = Vector3.new(0, 1, 0)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	embers.Color = ColorSequence.new(LAVA_HOT, LAVA_GLOW)
	embers.LightEmission = 1
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Parent = emitterPart
	if o.lights ~= false then
		for i = 0, math.floor(length / 36) do
			local a = Instance.new("Attachment")
			a.Position = Vector3.new(-length / 2 + 18 + i * 36, 0.6, 0)
			a.Parent = emitterPart
			local light = Instance.new("PointLight")
			light.Color = LAVA_GLOW
			light.Range = 14
			light.Brightness = 1.4
			light.Shadows = false
			light.Parent = a
		end
	end
	-- solid floor just under the surface (for Touched)
	local floor = Instance.new("Part")
	floor.Name = "LavaFloor"
	floor.Anchored = true
	floor.Transparency = 1
	floor.CanQuery = false
	floor.Size = Vector3.new(length, 1, width)
	floor.CFrame = surface * CFrame.new(0, -0.6, 0)
	floor.Parent = m
	m.Parent = parent
	return m, floor
end

-- Basalt bank: a low dark rock curb (top at `height` above surfaceCf), studded.
function Build.bank(parent: Instance, cf: CFrame, length: number, height: number, thickness: number?): Part
	local t = thickness or 1.4
	local p = Build.block(parent, "Bank", Vector3.new(length, height, t), cf * CFrame.new(0, height / 2, 0), BASALT, { Enum.NormalId.Top })
	p.Material = Enum.Material.Basalt
	return p
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
