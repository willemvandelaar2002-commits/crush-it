--!strict
-- Builds a tier's object and squashes it.
-- If ReplicatedStorage.ObjectMeshes has a Model named like the object (an AI
-- or hand-made mesh, saved in the place file, not managed by Rojo), that is
-- used, scaled to fit the object's width/height. Otherwise the object is
-- built from the parts in Config.Objects.
-- Every part is a Block (spheres and cylinders use a SpecialMesh), so the
-- object can be flattened non-uniformly: setSquash(model, f) scales every
-- part's height and height position by f (1 = whole, 0.07 = pancake) and
-- spreads it a little sideways as it flattens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Objects = {}

type Original = { part: BasePart, size: Vector3, offset: CFrame }

local originals: { [Model]: { Original } } = {}

-- Config draws objects with their front at -Z; the player looks at the press
-- from the plot's +Z side, so turn every object around.
local FACING = CFrame.Angles(0, math.pi, 0)

local function addSparkle(part: BasePart, v: any, width: number)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkle"
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(v.text)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(math.clamp(width * 0.12, 0.3, 3), 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Rate = math.clamp(width * 2, 6, 40)
	sparkle.Speed = NumberRange.new(1, 3)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = part
end

local function meshTemplate(name: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("ObjectMeshes")
	local t = folder and folder:FindFirstChild(name)
	return if t and t:IsA("Model") then t else nil
end

-- From a mesh template: scale it to fit inside the object's width x height,
-- stand it on `base`, restyle for golden / diamond / silhouette.
local function buildFromMesh(template: Model, def: any, base: CFrame, v: any, silhouette: boolean?): Model
	local model = template:Clone()
	model.Name = def.name
	local cf, size = model:GetBoundingBox()
	local scale = math.min(def.height / size.Y, def.width / math.max(size.X, size.Z))
	local bottom = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	-- Template attribute "Yaw" (degrees) turns a mesh whose front isn't the default way round.
	local yaw = CFrame.Angles(0, math.rad((template:GetAttribute("Yaw") :: number?) or 0), 0)
	local list: { Original } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = bottom:ToObjectSpace(d.CFrame)
			local offset = yaw * FACING * (CFrame.new(rel.Position * scale) * (rel - rel.Position))
			local partSize = d.Size * scale
			d.Size = partSize
			d.CFrame = base * offset
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			if (v and v.tint) or silhouette then
				for _, c in d:GetChildren() do
					if c:IsA("SurfaceAppearance") or c:IsA("Decal") or c:IsA("Texture") then
						c:Destroy()
					end
				end
				if d:IsA("MeshPart") then
					d.TextureID = ""
				end
				if silhouette then
					d.Color = Color3.fromRGB(25, 25, 30)
					d.Material = Enum.Material.SmoothPlastic
				else
					d.Color = v.tint
					d.Material = v.material
					if v.id == "Diamond" then
						d.Transparency = 0.15
						d.Reflectance = 0.35
					end
				end
			end
			table.insert(list, { part = d, size = partSize, offset = offset })
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	originals[model] = list
	model.PrimaryPart = list[1].part
	model:SetAttribute("Variant", if v then v.id else "Normal")
	model:SetAttribute("Height", size.Y * scale) -- real height (the ram stops on it)
	if v and v.tint and not silhouette then
		addSparkle(list[1].part, v, def.width)
	end
	model.Destroying:Connect(function()
		originals[model] = nil
	end)
	return model
end

-- `base` = the CFrame of the object's base centre (on the press bed).
-- `variant` = "Normal" | "Golden" | "Diamond" (Config.Variants); `silhouette` paints it black (book).
function Objects.build(tier: number, base: CFrame, variant: string?, silhouette: boolean?): Model
	local def = Config.Objects[tier]
	local v = Config.VariantById[variant or "Normal"]
	local template = meshTemplate(def.name)
	if template then
		return buildFromMesh(template, def, base, v, silhouette)
	end
	local model = Instance.new("Model")
	model.Name = def.name
	local list: { Original } = {}
	for i, spec in def.parts do
		local part: BasePart
		if spec.shape == "wedge" then
			part = Instance.new("WedgePart")
		else
			part = Instance.new("Part")
			if spec.shape == "sphere" or spec.shape == "cylinder" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = if spec.shape == "sphere" then Enum.MeshType.Sphere else Enum.MeshType.Cylinder
				mesh.Parent = part
			end
		end
		part.Name = "P" .. i
		part.Color = spec.color
		part.Material = spec.material or Enum.Material.SmoothPlastic
		if v and v.tint then
			part.Color = spec.color:Lerp(v.tint, 0.75)
			part.Material = v.material
			if v.id == "Diamond" then
				part.Transparency = 0.15
				part.Reflectance = 0.35
			end
		end
		if silhouette then
			part.Color = Color3.fromRGB(25, 25, 30)
			part.Material = Enum.Material.SmoothPlastic
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CastShadow = true
		local rot = spec.rot or Vector3.zero
		local offset = FACING * CFrame.new(spec.pos) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
		local size = spec.size
		if spec.shape == "cylinder" then
			-- Config cylinders stand along Y; the Cylinder mesh runs along the part's X.
			offset *= CFrame.Angles(0, 0, math.pi / 2)
			size = Vector3.new(size.Y, size.X, size.Z)
		end
		part.Size = size
		part.CFrame = base * offset
		part.Parent = model
		table.insert(list, { part = part, size = size, offset = offset })
	end
	originals[model] = list
	model.PrimaryPart = list[1].part
	model:SetAttribute("Variant", if v then v.id else "Normal")
	if v and v.tint and not silhouette then
		addSparkle(list[1].part, v, def.width)
	end
	model.Destroying:Connect(function()
		originals[model] = nil
	end)
	return model
end

-- f in (0, 1]: fraction of the original height. Sideways spread grows as it flattens.
function Objects.setSquash(model: Model, base: CFrame, f: number)
	local list = originals[model]
	if not list then
		return
	end
	local spread = 1 + (1 - f) * 0.35
	for _, o in list do
		local p = o.offset.Position
		-- Height and vertical position shrink; footprint spreads. Rotation kept.
		local rotOnly = o.offset - p
		o.part.CFrame = base * CFrame.new(p.X * spread, p.Y * f, p.Z * spread) * rotOnly
		-- Scale along world Y: approximate by scaling the part's own axes by how
		-- much each points up (good for the axis-aligned/90° parts we use).
		local up = rotOnly:VectorToObjectSpace(Vector3.yAxis)
		local sx = 1 + (f - 1) * math.abs(up.X)
		local sy = 1 + (f - 1) * math.abs(up.Y)
		local sz = 1 + (f - 1) * math.abs(up.Z)
		local s = o.size
		o.part.Size = Vector3.new(math.max(0.05, s.X * sx * (if math.abs(up.X) < 0.5 then spread else 1)), math.max(0.05, s.Y * sy * (if math.abs(up.Y) < 0.5 then spread else 1)), math.max(0.05, s.Z * sz * (if math.abs(up.Z) < 0.5 then spread else 1)))
	end
end

return Objects
