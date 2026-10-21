--!strict
-- Drives the toy train (server/Hub.luau, tag "ToyTrain") round the loop: every
-- car (attribute Offset = studs behind the engine) is placed on the rails each
-- frame from the server clock, so everyone sees the train in the same spot.
-- Cars are moved part by part relative to their "Chassis" (a model's pivot is
-- not reliable on the client with streaming on).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type Rig = { chassis: BasePart, lift: number, parts: { BasePart }, offsets: { CFrame }, count: number }
local rigs: { [Model]: Rig } = {}

local function rig(car: Model): Rig?
	local chassis = car:FindFirstChild("Chassis") :: BasePart?
	if not chassis then
		return nil
	end
	local count = #car:GetDescendants()
	local r = rigs[car]
	if r and r.count == count and r.chassis == chassis then
		return r
	end
	local parts, offsets = {}, {}
	for _, p in car:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			table.insert(offsets, chassis.CFrame:ToObjectSpace(p.CFrame))
		end
	end
	r = { chassis = chassis, lift = (car:GetAttribute("ChassisY") :: number?) or 2.2, parts = parts, offsets = offsets, count = count }
	rigs[car] = r
	return r
end

RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	local moveParts: { BasePart } = {}
	local moveTo: { CFrame } = {}
	for _, train in CollectionService:GetTagged("ToyTrain") do
		local r = (train:GetAttribute("Radius") :: number?) or 185
		local lap = (train:GetAttribute("Lap") :: number?) or 60
		local y = (train:GetAttribute("FloorY") :: number?) or 1.6
		local head = (now % lap) / lap * math.pi * 2
		for _, car in train:GetChildren() do
			if car:IsA("Model") then
				local rg = rig(car)
				if rg then
					local a = head - ((car:GetAttribute("Offset") :: number?) or 0) / r
					local pos = Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
					-- moving toward increasing angle: forward = d/da (sin a, cos a)
					local chassisCf = CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), 0, -math.sin(a))) * CFrame.new(0, rg.lift, 0)
					for i, p in rg.parts do
						table.insert(moveParts, p)
						table.insert(moveTo, chassisCf * rg.offsets[i])
					end
				end
			end
		end
	end
	if #moveParts > 0 then
		Workspace:BulkMoveTo(moveParts, moveTo, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
