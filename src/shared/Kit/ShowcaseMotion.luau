--!strict
-- Client-only art motion. One shared 30 Hz connection, with ancestor/clip checks.
-- Owns only the properties/decorations it creates; no sounds or game state.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Motion = {}
type Entry = { gui: GuiObject, step: (number, number) -> (), reset: () -> (), gate: GuiObject?, enabled: (() -> boolean)?, phase: number, awake: boolean, alive: boolean, destroyed: RBXScriptConnection? }
local entries: { Entry } = {}
local connection: RBXScriptConnection? = nil
local elapsed = 0

local function intersects(a: Vector2, size: Vector2, b: Vector2, other: Vector2): boolean
	return a.X + size.X > b.X and a.Y + size.Y > b.Y and a.X < b.X + other.X and a.Y < b.Y + other.Y
end
function Motion.onScreen(gui: GuiObject, gate: GuiObject?): boolean
	if not gui.Parent or (gate and not gate.Visible) then return false end
	local size, position = gui.AbsoluteSize, gui.AbsolutePosition
	if size.X <= 0 or size.Y <= 0 then return false end
	local camera = Workspace.CurrentCamera
	if camera and not intersects(position, size, Vector2.zero, camera.ViewportSize) then return false end
	local node: Instance? = gui
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible then return false end
			if node ~= gui and node.ClipsDescendants and not intersects(position, size, node.AbsolutePosition, node.AbsoluteSize) then return false end
		elseif node:IsA("ScreenGui") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end
local function bind(gui: GuiObject, props: any, step: (number, number) -> (), reset: () -> ()): () -> ()
	if not RunService:IsClient() then return function() end end
	local item: Entry = { gui = gui, step = step, reset = reset, gate = props.gate, enabled = props.enabled,
		phase = props.phase or 0, awake = false, alive = true, destroyed = nil }
	table.insert(entries, item)
	local function stop()
		if not item.alive then return end
		item.alive = false
		if item.destroyed then item.destroyed:Disconnect() end
		reset()
	end
	item.destroyed = gui.Destroying:Connect(stop)
	if not connection and RunService:IsClient() then
		elapsed = 0
		connection = RunService.RenderStepped:Connect(function(dt)
			elapsed += dt
			if elapsed < 1 / 30 then return end
			local delta = math.min(elapsed, 0.1)
			elapsed = 0
			for i = #entries, 1, -1 do
				local entry = entries[i]
				if not entry.alive or not entry.gui.Parent then
					if entry.destroyed then entry.destroyed:Disconnect() end
					table.remove(entries, i)
				else
					local awake = Motion.onScreen(entry.gui, entry.gate) and (not entry.enabled or entry.enabled())
					if awake then entry.phase += delta entry.step(entry.phase, delta)
					elseif entry.awake then entry.reset() end
					entry.awake = awake
				end
			end
			if #entries == 0 and connection then connection:Disconnect() connection = nil end
		end)
	end
	return stop
end
function Motion.floatArt(gui: GuiObject, options: any?): () -> ()
	local o = options or {}
	local position, rotation = gui.Position, gui.Rotation
	return bind(gui, o, function(t)
		local wave = t * math.pi * 2 / math.max(0.2, o.period or 3.4)
		gui.Position = position + UDim2.fromOffset(0, math.sin(wave) * (o.bob or 3))
		gui.Rotation = rotation + math.sin(wave + 0.55) * (o.tilt or 2)
	end, function() if gui.Parent then gui.Position = position gui.Rotation = rotation end end)
end
function Motion.spinArt(gui: GuiObject, options: any?): () -> ()
	local o = options or {}
	local rotation = gui.Rotation
	return bind(gui, o, function(t) gui.Rotation = rotation + (t * (o.speed or 14)) % 360 end,
		function() if gui.Parent then gui.Rotation = rotation end end)
end
function Motion.glint(parent: GuiObject, options: any?): () -> ()
	local o = options or {}
	local star = Instance.new("Frame")
	star.Name = "ShowcaseGlint"
	star.BackgroundTransparency = 1
	star.BorderSizePixel = 0
	star.AnchorPoint = Vector2.new(0.5, 0.5)
	star.Position = o.position or UDim2.fromScale(0.75, 0.27)
	star.Size = UDim2.fromOffset(0, 0)
	star.Visible = false
	star.ZIndex = o.zIndex or parent.ZIndex + 2
	star.Parent = parent
	local lines = {}
	for _, dimensions in { Vector2.new(1, 0.1), Vector2.new(0.1, 1) } do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = UDim2.fromScale(dimensions.X, dimensions.Y)
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BorderSizePixel = 0
		line.ZIndex = star.ZIndex
		line.Parent = star
		local round = Instance.new("UICorner") round.CornerRadius = UDim.new(0.5, 0) round.Parent = line
		table.insert(lines, line)
	end
	local stop = bind(parent, o, function(t)
		local phase = t % (o.interval or 5.2)
		local duration = o.duration or 0.7
		star.Visible = phase < duration
		if not star.Visible then return end
		local a = phase / duration
		local strength = math.sin(a * math.pi)
		local size = (o.size or 26) * strength
		star.Size = UDim2.fromOffset(size, size)
		star.Rotation = 15 + a * 75
		for _, line in lines do line.BackgroundTransparency = 1 - strength * 0.9 end
	end, function() if star.Parent then star.Visible = false end end)
	return function() stop() star:Destroy() end
end
-- Separate client-local effect owned by this panel. Lighting survives camera
-- replacement/destruction; existing post-processing effects are preserved.
function Motion.focusBlur(panel: Frame, size: number?): () -> ()
	if not RunService:IsClient() then return function() end end
	local effect = Instance.new("BlurEffect")
	effect.Name = panel.Name .. "FocusBlur"
	effect.Size = 0
	effect.Enabled = false
	effect.Parent = Lighting
	local tween: Tween? = nil
	local alive = true
	local function update()
		if not alive then return end
		if tween then tween:Cancel() end
		if panel.Visible then
			effect.Enabled = true
			tween = TweenService:Create(effect, TweenInfo.new(0.2), { Size = size or 12 })
			tween:Play()
		else
			effect.Enabled = false
			effect.Size = 0
		end
	end
	local visible = panel:GetPropertyChangedSignal("Visible"):Connect(update)
	local destroyed: RBXScriptConnection? = nil
	local function stop()
		if not alive then return end
		alive = false
		if tween then tween:Cancel() end
		visible:Disconnect()
		if destroyed then destroyed:Disconnect() end
		effect:Destroy()
	end
	destroyed = panel.Destroying:Connect(stop)
	update()
	return stop
end
return Motion
