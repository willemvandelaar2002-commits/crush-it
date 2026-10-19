--!strict
-- Builds a tier's object from Config.Objects and squashes it.
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

-- `base` = the CFrame of the object's base centre (on the press bed).
function Objects.build(tier: number, base: CFrame): Model
	local def = Config.Objects[tier]
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
