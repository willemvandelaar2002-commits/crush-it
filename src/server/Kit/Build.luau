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
--   Build.lighting(preset)                                    bright cartoon lighting

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

function Build.lighting(preset: string?)
	local _ = preset
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(90, 90, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 140)
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
	cc.Saturation = 0.08
	cc.Contrast = 0.06
	cc.Brightness = 0
	local bloom = effect("BloomEffect", "KitBloom")
	bloom.Intensity = 0.2
	bloom.Size = 24
	bloom.Threshold = 2
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.2
	atmo.Haze = 0.5
	atmo.Glare = 0.2
	atmo.Color = Color3.fromRGB(200, 230, 255)
	atmo.Decay = Color3.fromRGB(120, 170, 220)
	atmo.Parent = Lighting
end

return Build
