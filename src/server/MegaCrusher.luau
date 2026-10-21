--!strict
-- The Mega Crusher: the landmark in the middle of the station hub (Hub.luau). A
-- big Mega-stage press (PressBuilder, tier 9) over a stack of giant toy blocks.
-- The client (client/Mega.client.luau, tag "MegaCrusher") slams the ram down every
-- Period seconds: the toys squash, sparks fly, a "CRUSH!" pops up and the screen
-- shakes for players close by; then the ram rises and the toys pop back up.
-- Scenery only: it pays nothing.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Kit.Build)
local PressBuilder = require(script.Parent.PressBuilder)

local MegaCrusher = {}

local C = Color3.fromRGB
local TIER = 9
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

function MegaCrusher.build(parent: Instance, cf: CFrame): Model
	local built = PressBuilder.build(cf, TIER)
	local press = built.model
	press.Name = "MegaCrusher"
	local ram = built.ram
	local plateH = ram.Size.Y

	-- giant toy blocks on the bed: three stacked studded cubes
	local toy = Instance.new("Model")
	toy.Name = "Toy"
	local y = built.bedTop
	local blocks = {
		{ size = 12, h = 6, color = C(232, 86, 74), turn = 0.15 },
		{ size = 10, h = 5, color = C(244, 190, 46), turn = -0.25 },
		{ size = 8, h = 4.5, color = C(62, 143, 230), turn = 0.4 },
	}
	for i, b in blocks do
		local block = Build.block(toy, "ToyBlock" .. i, Vector3.new(b.size, b.h, b.size),
			CFrame.new(cf.Position.X, y + b.h / 2, cf.Position.Z) * CFrame.Angles(0, b.turn, 0), b.color, ALL)
		block.CanCollide = false
		y += b.h
	end
	local toyTop = y
	toy.Parent = press

	press:SetAttribute("BedTop", built.bedTop)
	press:SetAttribute("RestY", ram.Position.Y)
	-- at the hit, the ram's plate squashes the stack to 30 % of its height
	press:SetAttribute("HitY", built.bedTop + (toyTop - built.bedTop) * 0.3 + plateH / 2)
	press:SetAttribute("Period", 6)
	local bed = press:FindFirstChild("Bed") :: BasePart?
	if bed then
		local _, size = press:GetBoundingBox()
		Build.label(bed, "MEGA CRUSHER", C(255, 214, 80), size.Y + 4, Vector2.new(34, 6))
	end
	CollectionService:AddTag(press, "MegaCrusher")
	press.Parent = parent
	local _ = ReplicatedStorage
	return press
end

return MegaCrusher
