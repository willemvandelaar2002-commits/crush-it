--!strict
-- Toy scrap riding the plot conveyors into the scrap hoppers. Purely visual and
-- local: each belt (server part "ConveyorBelt" with ConveyorFrom/To attributes)
-- gets a few small toy blocks that loop along it. Only belts near the camera
-- animate, and the update runs at about 30 fps.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local COLORS = { Color3.fromRGB(248, 199, 53), Color3.fromRGB(53, 201, 79), Color3.fromRGB(35, 99, 210),
	Color3.fromRGB(230, 69, 77), Color3.fromRGB(255, 140, 40), Color3.fromRGB(156, 66, 221) }
local SPEED = 6 -- studs per second
local RANGE = 260
local PIECES = 7

type Belt = { from: Vector3, to: Vector3, length: number, cf: CFrame, pieces: { BasePart }, offset: number, folder: Folder }
local belts: { [BasePart]: Belt } = {}
local holder = Instance.new("Folder")
holder.Name = "ConveyorScrap"
holder.Parent = Workspace

local function add(part: Instance)
	if not part:IsA("BasePart") or part.Name ~= "ConveyorBelt" or belts[part] then return end
	local a, b = part:GetAttribute("ConveyorFrom"), part:GetAttribute("ConveyorTo")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return end
	local folder = Instance.new("Folder")
	folder.Parent = holder
	local rng = Random.new(math.floor(a.X * 7 + a.Z * 13))
	local pieces = {}
	for i = 1, PIECES do
		local p = Instance.new("Part")
		p.Name = "ToyScrap"
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.Size = Vector3.new(rng:NextNumber(1.3, 2), rng:NextNumber(1, 1.5), rng:NextNumber(1.3, 1.9))
		p.Color = COLORS[(i - 1) % #COLORS + 1]
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = folder
		pieces[i] = p
	end
	belts[part] = { from = a, to = b, length = (b - a).Magnitude, cf = CFrame.lookAt(a, b), pieces = pieces,
		offset = rng:NextNumber(0, 10), folder = folder }
	part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(Workspace) then
			folder:Destroy()
			belts[part] = nil
		end
	end)
end

for _, v in Workspace:GetDescendants() do add(v) end
Workspace.DescendantAdded:Connect(add)

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local eye = camera.CFrame.Position
	local now = os.clock()
	for _, belt in belts do
		local near = (belt.from:Lerp(belt.to, 0.5) - eye).Magnitude < RANGE
		belt.folder.Parent = if near then holder else nil
		if near then
			local gap = belt.length / #belt.pieces
			for i, p in belt.pieces do
				local d = ((now + belt.offset) * SPEED + i * gap) % belt.length
				local wobble = math.sin(d * 0.9 + i) * 0.5
				p.CFrame = belt.cf * CFrame.new(wobble, p.Size.Y / 2, -d) * CFrame.Angles(0, i * 0.8 + d * 0.05, 0)
			end
		end
	end
end)
