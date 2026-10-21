--!strict
-- Drives the toy train (server/Hub.luau, tag "ToyTrain") round the loop: every
-- car (attribute Offset = studs behind the engine) is placed on the rails each
-- frame from the server clock, so everyone sees the train in the same spot.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for _, train in CollectionService:GetTagged("ToyTrain") do
		local r = (train:GetAttribute("Radius") :: number?) or 185
		local lap = (train:GetAttribute("Lap") :: number?) or 60
		local y = (train:GetAttribute("FloorY") :: number?) or 1.6
		local head = (now % lap) / lap * math.pi * 2
		for _, car in train:GetChildren() do
			if car:IsA("Model") then
				local a = head - ((car:GetAttribute("Offset") :: number?) or 0) / r
				local pos = Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
				-- moving toward increasing angle: forward = d/da (sin a, cos a)
				car:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), 0, -math.sin(a))))
			end
		end
	end
end)
