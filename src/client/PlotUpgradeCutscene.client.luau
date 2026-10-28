--!strict
-- Plot upgrade cutscene (~4 s), only for the buyer, only after the server sent
-- PlotUpgraded (a confirmed purchase; never on join or refresh). Purely local:
-- the real new section is already built and solid on the server; here it is
-- hidden with LocalTransparencyModifier and rebuilt by local copies that rise
-- into place, then the copies go and the real parts show again. Skip, death,
-- respawn or a second upgrade end it at once and restore camera, controls and
-- HUD. Spending, capacity and saving never depend on it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)

local me = Players.LocalPlayer
local INK = Style.Colors.Ink
local WHITE = Color3.new(1, 1, 1)

-- What each plot level adds (models in the plot) and its feature to spotlight.
local SECTIONS = {
	{ banks = { "TopFloor1", "TopFloor2" }, feature = "CoatingBooth" },
	{ banks = { "RearGround1", "RearGround2" }, extra = { "RearYard", "FusionWing" }, feature = "Fuser" },
	{ banks = { "RearUpper1" } },
	{ banks = { "RearUpper2" }, feature = "ArchBeam" },
}
-- island blocks stay put (they reach down into the floor below the plot)
local KEEP = { Dirt = true, Stone = true, Rock = true }
local function groupOf(part: BasePart, inBay: boolean): number
	if inBay then return 3 end
	local n = part.Name
	if n:find("Deck") or n:find("Floor") or n:find("Step") or n:find("Walk") or n:find("Edge") or n == "Top" or n:find("Rim") then return 1 end
	if n:find("Column") or n:find("Support") or n:find("Wall") or n:find("Post") or n:find("Pillar") or n:find("Fascia") or n:find("Stripe") or n:find("Panel") then return 2 end
	return 4
end
local GROUP_START = { 0.35, 0.8, 1.15, 1.5 }
local RISE = 0.45

local playing: any = nil
local freezeAt: number? = nil -- Studio test only: hold the timeline at this moment for screenshots

-- Never waits: this place has no default PlayerModule, so the character is
-- also held still through its Humanoid (old values put back afterwards).
local function controls(): any?
	local module = me:FindFirstChild("PlayerScripts") and me.PlayerScripts:FindFirstChild("PlayerModule")
	if not module then return nil end
	local ok, ctl = pcall(function() return (require(module :: any) :: any):GetControls() end)
	return if ok then ctl else nil
end
local function hold(s: any)
	local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	s.held = { hum = hum, walk = hum.WalkSpeed, jump = hum.JumpPower, height = hum.JumpHeight }
	hum.WalkSpeed = 0 hum.JumpPower = 0 hum.JumpHeight = 0
	local ctl = controls() if ctl then ctl:Disable() end
end
local function release(s: any)
	local h = s.held
	if h and h.hum.Parent then
		-- only put back what nothing else changed meanwhile
		if h.hum.WalkSpeed == 0 then h.hum.WalkSpeed = h.walk end
		if h.hum.JumpPower == 0 then h.hum.JumpPower = h.jump end
		if h.hum.JumpHeight == 0 then h.hum.JumpHeight = h.height end
	end
	local ctl = controls() if ctl then ctl:Enable() end
end

local function finish()
	local s = playing
	if not s then return end
	playing = nil
	for _, c in s.connections do c:Disconnect() end
	for _, t in s.tweens do t:Cancel() end
	if s.folder then s.folder:Destroy() end
	for _, p in s.hidden do if p.Parent then p.LocalTransparencyModifier = 0 end end
	for gui, was in s.guis do if gui.Parent then gui.Enabled = was end end
	if s.gui then s.gui:Destroy() end
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		me:SetAttribute("CutscenePlaying", nil)
		local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
		cam.CameraSubject = hum or s.subject
		cam.FieldOfView = s.fov
	end
	release(s)
end

local function plotModel(): Model?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	return if plot and plot:IsA("Model") then plot else nil
end

local function ui(s: any, info: any)
	local gui = Instance.new("ScreenGui") gui.Name = "UpgradeCutscene" gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true gui.DisplayOrder = 50 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local bars = {}
	for i, y in { 0, 1 } do
		local bar = Instance.new("Frame") bar.Name = "Bar" .. i bar.BorderSizePixel = 0 bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.AnchorPoint = Vector2.new(0, y) bar.Position = UDim2.fromScale(0, y) bar.Size = UDim2.fromScale(1, 0) bar.Parent = gui
		bars[i] = bar
	end
	local skip = Instance.new("TextButton") skip.Name = "Skip" skip.Text = "Skip" skip.TextSize = 34
	skip.AnchorPoint = Vector2.new(1, 1) skip.Position = UDim2.new(1, -28, 1, -26) skip.Size = UDim2.fromOffset(170, 66) skip.ZIndex = 5
	Style.button(skip, Color3.fromRGB(255, 222, 24))
	skip.Parent = gui
	skip.Activated:Connect(finish)
	local title = Instance.new("TextLabel") title.Name = "Title" title.Text = "FACTORY UPGRADED!" title.Font = Enum.Font.FredokaOne
	title.TextScaled = true title.BackgroundTransparency = 1 title.TextColor3 = info.accent or Color3.fromRGB(255, 222, 24)
	title.AnchorPoint = Vector2.new(.5, .5) title.Position = UDim2.fromScale(.5, .2) title.Size = UDim2.fromScale(.62, .11) title.ZIndex = 4
	title.TextTransparency = 1 title.Parent = gui
	local stroke = Instance.new("UIStroke") stroke.Thickness = 5 stroke.Color = INK stroke.Transparency = 1 stroke.Parent = title
	local scale = Instance.new("UIScale") scale.Scale = .4 scale.Parent = title
	local sub = Instance.new("TextLabel") sub.Name = "Details" sub.Font = Enum.Font.FredokaOne sub.TextScaled = true
	sub.BackgroundTransparency = 1 sub.TextColor3 = WHITE sub.AnchorPoint = Vector2.new(.5, 0)
	sub.Position = UDim2.fromScale(.5, .27) sub.Size = UDim2.fromScale(.6, .09) sub.ZIndex = 4 sub.TextTransparency = 1 sub.Parent = gui
	local s2 = Instance.new("UIStroke") s2.Thickness = 3 s2.Color = INK s2.Transparency = 1 s2.Parent = sub
	-- the real upgrade data from the server
	local lines = { info.name .. " · " .. info.added .. " NEW BAYS TO UNLOCK" }
	local what = { info.section }
	if info.unlock then table.insert(what, info.unlock .. " UNLOCKED") end
	table.insert(lines, table.concat(what, " · "))
	if info.caps then table.insert(lines, "UPGRADE CAP " .. info.caps.global[1] .. " → " .. info.caps.global[2] .. " · CRUSHER LV " .. info.caps.level[1] .. " → " .. info.caps.level[2]) end
	sub.Text = table.concat(lines, "\n")
	sub.Size = UDim2.fromScale(.46, .04 * #lines)
	gui.Parent = me:WaitForChild("PlayerGui")
	s.gui = gui
	local function tw(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
		local tween = Tween:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		table.insert(s.tweens, tween) tween:Play()
	end
	for _, bar in bars do tw(bar, .35, { Size = UDim2.fromScale(1, .11) }) end
	s.showTitle = function()
		tw(title, .3, { TextTransparency = 0 }) tw(stroke, .3, { Transparency = 0 })
		tw(scale, .45, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(.2, function() if playing == s then tw(sub, .3, { TextTransparency = 0 }) tw(s2, .3, { Transparency = 0 }) end end)
	end
	s.closeBars = function() for _, bar in bars do tw(bar, .3, { Size = UDim2.fromScale(1, 0) }) end end
end

local function neon(folder: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, t: number?): Part
	local p = Instance.new("Part") p.Name = name p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false
	p.CastShadow = false p.Material = Enum.Material.Neon p.Color = color p.Size = size p.CFrame = cf p.Transparency = t or .2 p.Parent = folder
	return p
end

local function play(info: any)
	if playing then finish() end -- a new upgrade replaces a running cutscene
	local plot = plotModel()
	local def = SECTIONS[info.level]
	local cam = workspace.CurrentCamera
	if not plot or not def or not cam then return end
	local origin = plot:GetAttribute("Origin") :: CFrame
	local s: any = { connections = {}, tweens = {}, hidden = {}, guis = {}, subject = cam.CameraSubject, fov = cam.FieldOfView }
	playing = s
	-- 1. collect the new section: banks, extra models and the new bays
	local roots: { Instance } = {}
	local banks = plot:FindFirstChild("WorkshopBanks")
	for _, n in def.banks do local m = banks and banks:FindFirstChild(n) if m then table.insert(roots, m) end end
	for _, n in def.extra or {} do local m = plot:FindFirstChild(n, true) if m then table.insert(roots, m) end end
	for i = info.first, info.last do local m = plot:FindFirstChild("WorkingBay" .. i, true) if m then table.insert(roots, m) end end
	local walls = plot:FindFirstChild("StageWalls" .. (info.level + 1), true) if walls then table.insert(roots, walls) end
	local folder = Instance.new("Folder") folder.Name = "UpgradeCutsceneFx" folder.Parent = workspace
	s.folder = folder
	local copies = {}
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, root in roots do
		local inBay = root.Name:match("^WorkingBay") ~= nil
		-- the camera and the sweep frame the new floor itself, not the walls or yard around the plot
		local main = inBay or table.find(def.banks, root.Name) ~= nil
		for _, p in root:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 and not KEEP[p.Name] then
				local rel = origin:PointToObjectSpace(p.Position)
				if main then lo = lo:Min(rel) hi = hi:Max(rel) end
				local copy = p:Clone()
				for _, c in copy:GetChildren() do if not (c:IsA("Decal") or c:IsA("Texture") or c:IsA("SpecialMesh")) then c:Destroy() end end
				copy.Anchored = true copy.CanCollide = false copy.CanQuery = false copy.CanTouch = false
				copy.LocalTransparencyModifier = 1 copy.Parent = folder
				p.LocalTransparencyModifier = 1 table.insert(s.hidden, p)
				table.insert(copies, { part = copy, target = p.CFrame, group = groupOf(p, inBay), rel = rel })
			elseif p:IsA("SurfaceGui") and p.Enabled then s.guis[p] = true p.Enabled = false end
		end
	end
	-- owner copies of bay plaques live in PlayerGui
	for _, g in me.PlayerGui:GetDescendants() do
		if g:IsA("SurfaceGui") and g.Enabled and g.Adornee then
			for _, root in roots do if g.Adornee:IsDescendantOf(root) then s.guis[g] = true g.Enabled = false break end end
		end
	end
	if #copies == 0 or lo.X == math.huge then finish() return end
	local centre = (lo + hi) / 2 local size = hi - lo
	-- the sweep runs along the section's long side; copies rise in that order too
	local alongX = size.X >= size.Z
	for _, c in copies do
		local k = math.clamp(if alongX then (c.rel.X - lo.X) / math.max(size.X, 1) else (c.rel.Z - lo.Z) / math.max(size.Z, 1), 0, 1)
		c.start = GROUP_START[c.group] + k * .35
		c.drop = if c.group == 1 then 6 else 9
	end
	-- feature to spotlight
	local feature: Instance? = if def.feature then plot:FindFirstChild(def.feature, true) else nil
	local featureAt: Vector3?
	if feature then
		if feature:IsA("BasePart") then featureAt = feature.Position
		elseif feature:IsA("Model") then featureAt = (feature:GetBoundingBox()).Position end
	end
	-- 2. camera: elevated view from the side the section opens to (rear sections from behind)
	local fromBack = centre.Z < -40
	local span = math.max(size.X, size.Z, 30)
	local function viewOf(c: Vector3, sp: number, back: boolean): CFrame
		local dir = if back then -1 else 1
		local eye = origin * Vector3.new(c.X + sp * .1, c.Y + sp * .42 + 14, c.Z + dir * (sp * .5 + 22))
		return CFrame.lookAt(eye, origin * c)
	end
	local mainView = viewOf(centre, span, fromBack)
	local featureView = if featureAt then (function()
		local rel = origin:PointToObjectSpace(featureAt)
		return viewOf(rel, 34, false)
	end)() else nil
	cam.CameraType = Enum.CameraType.Scriptable
	me:SetAttribute("CutscenePlaying", true) -- other cutscenes leave the camera alone
	hold(s)
	-- hide the HUD (restored on finish)
	for _, g in me.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "UpgradeCutscene" then s.guis[g] = true g.Enabled = false end
	end
	ui(s, info)
	local startCam = cam.CFrame
	local accent: Color3 = info.accent or Color3.fromRGB(255, 222, 24)
	-- 3. light sweep and 4. feature reveal parts
	local sweepH = size.Y + 8
	local sweep = neon(folder, "Sweep", if alongX then Vector3.new(.6, sweepH, size.Z + 4) else Vector3.new(size.X + 4, sweepH, .6), origin, accent, 1)
	local ring, beams, burst
	if featureAt then
		local base = CFrame.new(featureAt.X, origin.Position.Y + .3, featureAt.Z)
		ring = neon(folder, "Ring", Vector3.new(.25, 2, 2), base * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 235, 255), 1)
		ring.Shape = Enum.PartType.Cylinder
		beams = {}
		for i = 1, 4 do
			local a = i * math.pi / 2 + math.pi / 4
			beams[i] = neon(folder, "Beam", Vector3.new(.5, .1, .5), base * CFrame.new(math.cos(a) * 9, 0, math.sin(a) * 9), Color3.fromRGB(220, 250, 255), 1)
		end
		local host = neon(folder, "BurstHost", Vector3.new(.2, .2, .2), base * CFrame.new(0, 2, 0), WHITE, 1)
		burst = Instance.new("ParticleEmitter") burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Rate = 0 burst.Lifetime = NumberRange.new(.6, 1) burst.Speed = NumberRange.new(8, 14) burst.SpreadAngle = Vector2.new(70, 70)
		burst.Color = ColorSequence.new(accent:Lerp(WHITE, .4), accent) burst.LightEmission = 1
		burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .5), NumberSequenceKeypoint.new(1, 0) })
		burst.Parent = host
	end
	local sound = Instance.new("Sound") sound.SoundId = "rbxassetid://" .. Config.Sounds.LevelUp sound.Volume = .6 sound.Parent = folder
	local t0 = os.clock()
	local feat0 = if featureAt then 2.2 else math.huge
	local done = if featureAt then 4.3 else 3.6
	local titled, burstDone, sounded = false, false, false
	local function ease(x: number) x = math.clamp(x, 0, 1) return 1 - (1 - x) ^ 3 end
	local function back(x: number) x = math.clamp(x, 0, 1) local c1 = 1.4 return 1 + (c1 + 1) * (x - 1) ^ 3 + c1 * (x - 1) ^ 2 end
	table.insert(s.connections, Run.RenderStepped:Connect(function()
		if playing ~= s then return end
		local t = os.clock() - t0
		if freezeAt then t = math.min(t, freezeAt) end
		-- camera: in, (feature), back to the player
		if t < .7 then cam.CFrame = startCam:Lerp(mainView, ease(t / .7))
		elseif featureView and t >= feat0 - .3 and t < feat0 + .2 then cam.CFrame = mainView:Lerp(featureView, ease((t - feat0 + .3) / .5))
		elseif featureView and t >= feat0 + .2 then cam.CFrame = featureView
		else cam.CFrame = mainView end
		-- section copies rise (overshoot slightly, then settle)
		for _, c in copies do
			local k = (t - c.start) / RISE
			if k <= 0 then c.part.LocalTransparencyModifier = 1
			elseif k < 1 then
				c.part.LocalTransparencyModifier = 1 - ease(k * 1.6)
				c.part.CFrame = c.target * CFrame.new(0, -c.drop * (1 - back(k)), 0)
			elseif not c.settled then c.settled = true c.part.LocalTransparencyModifier = 0 c.part.CFrame = c.target end
		end
		-- 3. coloured light sweep along the new section
		local sk = (t - 1.55) / .8
		if sk > 0 and sk < 1 then
			local x = if alongX then lo.X + (size.X + 4) * sk - 2 else centre.X
			local z = if alongX then centre.Z else lo.Z + (size.Z + 4) * sk - 2
			sweep.CFrame = origin * CFrame.new(x, centre.Y, z)
			sweep.Transparency = .25 + .7 * math.abs(sk - .5) * 2 * .6
		else sweep.Transparency = 1 end
		if not sounded and t > 1.5 then sounded = true sound:Play() end
		-- 5. title once the section stands
		if not titled and t > 1.9 then titled = true s.showTitle() end
		-- 4. feature: ring, beams, burst
		if ring and t > feat0 then
			local k = (t - feat0) / .9
			local d = 2 + 22 * ease(k)
			ring.Size = Vector3.new(.25, d, d) ring.Transparency = .1 + .9 * math.clamp(k, 0, 1)
			for _, b in beams do
				local h = 26 * ease(k * 1.4)
				b.Size = Vector3.new(.5, math.max(h, .1), .5)
				b.CFrame = CFrame.new(b.Position.X, origin.Position.Y + h / 2, b.Position.Z)
				b.Transparency = .15 + .85 * math.clamp((k - .4) / .6, 0, 1)
			end
			if not burstDone then burstDone = true burst:Emit(26) end
		end
		-- 6. hold, then hand the camera back
		if t > done - .6 and not s.barsClosed then s.barsClosed = true s.closeBars() end
		if t > done - .5 and t < done then
			local hum = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum then
				local home = CFrame.lookAt(hum.Position + Vector3.new(0, 14, 0) - (cam.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 22, hum.Position)
				cam.CFrame = cam.CFrame:Lerp(home, ease((t - done + .5) / .5))
			end
		end
		if t >= done then finish() end
	end))
	-- interruptions: death, respawn, leaving the plot
	local function bindCharacter(char: Model?)
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then table.insert(s.connections, hum.Died:Connect(finish)) end
	end
	bindCharacter(me.Character)
	table.insert(s.connections, me.CharacterRemoving:Connect(finish))
	table.insert(s.connections, me.CharacterAdded:Connect(finish))
	table.insert(s.connections, me:GetAttributeChangedSignal("Plot"):Connect(finish))
end

Net.event("PlotUpgraded").OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or type(info.level) ~= "number" then return end
	task.wait(.15) -- let the new section's parts replicate first
	local ok, err = pcall(play, info)
	if not ok then warn("[PlotUpgradeCutscene] " .. tostring(err)) finish() end
end)
-- Studio check: is a cutscene running? (used by the Studio test)
if Run:IsStudio() then
	local probe = Instance.new("BindableFunction") probe.Name = "CutsceneState"
	probe.OnInvoke = function(cmd, value)
		if cmd == "Skip" then finish() end
		if cmd == "FreezeAt" then freezeAt = value end
		return playing ~= nil
	end
	probe.Parent = script
end
