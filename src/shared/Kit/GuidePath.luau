--!strict
-- Kit (client only): a trail of glowing chevrons on the ground that scroll
-- toward a target, plus a bobbing arrow over the target (the forge-game
-- "follow the arrows" path). Reusable: the game decides where to point.
--
--   local path = GuidePath.new({ color?, spacing?, speed?, stopDistance?, label? })
--   path:update(fromPosition, targetPosition?, label?)  -- call every frame; nil target hides it
--   path:destroy()
--
-- Chevrons sit on whatever is under them (a downward ray), so the trail
-- follows floors, platforms and steps. It is drawn only for the local player.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GuidePath = {}
GuidePath.__index = GuidePath

export type Options = { color: Color3?, spacing: number?, speed: number?, stopDistance: number?, maxLength: number? }

local MAX = 40 -- chevrons at most (maxLength / spacing)

local function arm(parent: Instance, color: Color3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.2
	p.Size = Vector3.new(0.45, 0.08, 2.1)
	p.Parent = parent
	return p
end

function GuidePath.new(opts: Options?)
	local o = opts or {}
	local self = setmetatable({}, GuidePath)
	self.color = o.color or Color3.new(1, 1, 1)
	self.spacing = o.spacing or 4
	self.speed = o.speed or 6 -- studs per second the chevrons move
	self.stopDistance = o.stopDistance or 8
	self.maxLength = o.maxLength or 160
	self.folder = Instance.new("Folder")
	self.folder.Name = "GuidePath"
	self.folder.Parent = Workspace
	self.chevrons = {}
	for i = 1, MAX do
		local m = Instance.new("Model")
		m.Name = "Chevron" .. i
		local left, right = arm(m, self.color), arm(m, self.color)
		m.Parent = self.folder
		self.chevrons[i] = { model = m, left = left, right = right }
	end
	-- arrow over the target
	local anchor = Instance.new("Part")
	anchor.Name = "TargetAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = self.folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 110)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local text = Instance.new("TextLabel")
	text.Name = "Label"
	text.Size = UDim2.fromScale(1, 0.4)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = ""
	text.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(19, 23, 38)
	stroke.Parent = text
	local arrow = text:Clone()
	arrow.Name = "Arrow"
	arrow.Position = UDim2.fromScale(0, 0.38)
	arrow.Size = UDim2.fromScale(1, 0.62)
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromRGB(255, 225, 70)
	arrow.Parent = gui
	self.anchor = anchor
	self.billboard = gui
	self.labelText = text
	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self:_hide()
	return self
end

function GuidePath:_hide()
	for _, c in self.chevrons do
		c.left.Transparency = 1
		c.right.Transparency = 1
	end
	self.billboard.Enabled = false
end

-- Height of the ground under (x, z), ignoring characters and this path.
function GuidePath:_ground(x: number, z: number, fallback: number): number
	local ignore: { Instance } = { self.folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	self.rayParams.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(Vector3.new(x, fallback + 40, z), Vector3.new(0, -120, 0), self.rayParams)
	return if hit then hit.Position.Y else fallback
end

function GuidePath:update(from: Vector3, target: Vector3?, label: string?)
	if not target then
		self:_hide()
		return
	end
	local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
	local dist = flat.Magnitude
	if dist < self.stopDistance then
		self:_hide()
		return
	end
	local dir = flat.Unit
	local length = math.min(dist - self.stopDistance * 0.5, self.maxLength)
	local shift = (os.clock() * self.speed) % self.spacing
	local yaw = math.atan2(-dir.X, -dir.Z) -- CFrame looking along dir
	for i, c in self.chevrons do
		local d = 3 + (i - 1) * self.spacing + shift
		if d > length then
			c.left.Transparency = 1
			c.right.Transparency = 1
			continue
		end
		local x, z = from.X + dir.X * d, from.Z + dir.Z * d
		local y = self:_ground(x, z, from.Y) + 0.06
		local base = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
		-- ">" shape pointing forward (-Z of base): two arms meeting at the tip
		c.left.CFrame = base * CFrame.new(-0.62, 0, 0.2) * CFrame.Angles(0, math.rad(-40), 0)
		c.right.CFrame = base * CFrame.new(0.62, 0, 0.2) * CFrame.Angles(0, math.rad(40), 0)
		-- fade in at the start and out near the end
		local fade = math.clamp(math.min(d - 3, length - d) / 4, 0, 1)
		c.left.Transparency = 1 - 0.8 * fade
		c.right.Transparency = c.left.Transparency
	end
	self.anchor.CFrame = CFrame.new(target + Vector3.new(0, 3 + math.sin(os.clock() * 4) * 0.6, 0))
	self.labelText.Text = label or ""
	self.billboard.Enabled = true
end

function GuidePath:destroy()
	self.folder:Destroy()
end

return GuidePath
