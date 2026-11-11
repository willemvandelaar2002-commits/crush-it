--!strict
-- 11 Nov (audit 8, vault: Networking budget): crusher strikes play on each client.
-- Before, every strike tweened the moving parts on the server, so their positions
-- streamed to every player all the time (~90 kbps for one full factory). Now:
--   * at build the server tags each crusher model with how it moves (M.tagGroups,
--     M.tagRam, or "rig" for the crate crushers' keyframed rigs, rebuilt from the
--     shared metadata in SpecialCrusherAssets);
--   * per strike the server sends one small event (server/CrusherMotionServer) to
--     the players near that factory;
--   * the client (client/CrusherMotion) builds a view of the model once (M.view)
--     and plays the strike with local tweens (M.play), so contact lands on the
--     server's impact time like the sound and squash (CrusherFeel).
-- The server's own Catalog/Special .strike also use M.play (the specs and dev tools).
local TweenService = game:GetService("TweenService")
local Feedback = require(script.Parent.CrusherFeedback)
local Assets = require(script.Parent.SpecialCrusherAssets)

local M = {}
M.Remote = "CrusherMotion"
M.SendDistance = 320 -- server: players whose character is this close get a factory's strikes
M.PlayDistance = 300 -- client: strikes further from the camera are skipped
M.MaxLate = 0.45 -- client: a strike that arrives later than this after its start is skipped

-- Attributes (set on the server at build, replicated with the model):
--   model MotionKind  "groups" | "rig" | "ram"
--   model MotionGroups (groups) number of groups that take turns (Twin Titan: 2)
--   model MotionHit    share of the stroke time spent going down (.4, specials .38)
--   part  MotionGroup  which group the part moves with; MotionDown its CFrame at contact;
--         MotionSize   its Size at contact (telescoping rods)
--   part  MotionRam    (ram) the press ram; its contact height comes with each strike
--   model MotionLoop   seconds: the client strikes it on a loop by itself (showroom, dev preview)

function M.tagGroups(model: Model, hit: number, groups: { { { part: BasePart, down: CFrame, size: Vector3? } } })
	model:SetAttribute("MotionKind", "groups")
	model:SetAttribute("MotionGroups", #groups)
	model:SetAttribute("MotionHit", hit)
	for i, list in groups do
		for _, e in list do
			e.part:SetAttribute("MotionGroup", i)
			e.part:SetAttribute("MotionDown", e.down)
			if e.size then e.part:SetAttribute("MotionSize", e.size) end
		end
	end
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- every moving part arrives together
end
function M.tagRam(model: Model, ram: BasePart)
	model:SetAttribute("MotionKind", "ram")
	model:SetAttribute("MotionHit", .4)
	ram:SetAttribute("MotionRam", true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
end
function M.tagRig(model: Model)
	model:SetAttribute("MotionKind", "rig")
	model:SetAttribute("MotionHit", .38)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
end

---------------------------------------------------------------------------------------
-- kit="motion" rigs (crate crushers). Everything is worked out once: the pose of every
-- moving part at each key time of the Blender demo curves. A strike then only tweens
-- from key to key. (Moved here from server/SpecialCrushers on 11 Nov.)
local function parts(node: Instance): { BasePart }
	local out = {} if node:IsA("BasePart") then table.insert(out, node) end
	for _, v in node:GetDescendants() do if v:IsA("BasePart") then table.insert(out, v) end end
	return out
end
M.parts = parts
local function component(root: Instance, name: string): Instance?
	-- the named component through any importer-introduced Model wrappers
	if root.Name == name and #parts(root) > 0 then return root end
	for _, v in root:GetChildren() do local found = component(v, name) if found then return found end end
	return nil
end
M.component = component
local CURVES = { -- (frame-1)/71 -> amount, from the pack's build.py
	press = { { 0, 0 }, { 15 / 71, 0 }, { 26 / 71, .25 }, { 33 / 71, 1 }, { 39 / 71, 1 }, { 56 / 71, 0 }, { 1, 0 } },
	wind = { { 0, 0 }, { 11 / 71, .18 }, { 24 / 71, .76 }, { 33 / 71, 1 }, { 43 / 71, 1 }, { 62 / 71, 0 }, { 1, 0 } },
	spin = { { 0, 0 }, { 1, 1 } }, -- 5 Nov: rollers / rings turn one full circle per strike
}
-- 6 Nov: a motion can carry its own keys ({t, amount} on the same 0..1 timeline, contact at 33/71)
local function amount(curve: any, t: number): number
	local keys = if type(curve) == "table" then curve else CURVES[curve] or CURVES.press
	for i = 2, #keys do local a, b = keys[i - 1], keys[i]
		if t <= b[1] then return a[2] + (b[2] - a[2]) * (t - a[1]) / math.max(1e-6, b[1] - a[1]) end
	end
	return keys[#keys][2]
end
function M.rig(model: Model, metadata: any): any
	local Pm = metadata.parts
	local frame = component(model, "Frame") :: BasePart
	-- FBX -> world: anchor on the Frame, scale from its size, and the turn about Y
	-- from the part that sits furthest from the Frame horizontally.
	local scale = frame.Size.Magnitude / Pm.Frame.size.Magnitude
	local best, far = nil, -1
	for name, info in Pm do if name ~= "Frame" then
		local d = info.center - Pm.Frame.center local h = Vector2.new(d.X, d.Z).Magnitude
		if h > far then best, far = name, h end
	end end
	local yaw = 0
	if best and far > 1e-3 then
		local fd = Pm[best].center - Pm.Frame.center
		local wd = (component(model, best) :: BasePart).Position - frame.Position
		yaw = math.atan2(wd.X, wd.Z) - math.atan2(fd.X, fd.Z)
	end
	local turn = CFrame.Angles(0, yaw, 0)
	local function point(p: Vector3) return frame.Position + turn:VectorToWorldSpace((p - Pm.Frame.center) * scale) end
	local function vector(v: Vector3) return turn:VectorToWorldSpace(v * scale) end
	local motions = {} for _, m in metadata.motion do motions[m.name] = motions[m.name] or {} table.insert(motions[m.name], m) end
	local moving = {}
	for name, info in Pm do if motions[name] or (info.parent and motions[info.parent]) then moving[name] = true end end
	local rest = {} for name in moving do local p = component(model, name) :: BasePart rest[name] = { part = p, cf = p.CFrame, size = p.Size } end
	for name in moving do if Pm[name].parent and not rest[Pm[name].parent] then local q = component(model, Pm[name].parent) :: BasePart rest[Pm[name].parent] = { part = q, cf = q.CFrame, size = q.Size } end end
	local times, seen = {}, {}
	for _, keys in CURVES do for _, k in keys do if not seen[k[1]] then seen[k[1]] = true table.insert(times, k[1]) end end end
	for _, m in metadata.motion do for _, k in m.keys or {} do if not seen[k[1]] then seen[k[1]] = true table.insert(times, k[1]) end end end
	table.sort(times)
	local function pose(name: string, t: number): any
		local r = rest[name] local cf, size = r.cf, r.size
		local o = point(Pm[name].origin)
		for _, m in motions[name] or {} do
			local a = amount(m.keys or m.curve, t)
			if m.kind == "move" then
				local d = vector(m.vector) * a cf = cf + d o += d
			elseif m.kind == "rotate" then
				cf = CFrame.new(o) * CFrame.fromAxisAngle(turn:VectorToWorldSpace(m.axis), m.angle * a) * CFrame.new(-o) * cf
			elseif m.kind == "extend" then
				local k = 1 + (m.ratio - 1) * a
				local want = turn:VectorToWorldSpace(if m.axis == "X" then Vector3.xAxis elseif m.axis == "Z" then Vector3.zAxis else Vector3.yAxis)
				local axis, dot = Vector3.yAxis, -1
				for _, c in { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis } do local d = math.abs(cf:VectorToWorldSpace(c):Dot(want)) if d > dot then axis, dot = c, d end end
				local rel = cf:PointToObjectSpace(o):Dot(axis)
				cf = cf * CFrame.new(axis * rel * (1 - k)) size = size + axis * size:Dot(axis) * (k - 1)
			end
		end
		local parent = Pm[name].parent
		if parent and rest[parent] then local pc = pose(parent, t) cf = (pc.cf * rest[parent].cf:Inverse()) * cf end
		return { cf = cf, size = size }
	end
	local poses = {} for name in moving do poses[name] = {} for i, t in times do poses[name][i] = pose(name, t) end end
	return { times = times, poses = poses, rest = rest, busy = false }
end

---------------------------------------------------------------------------------------
-- A view: what moves and where it rests, read once from the tagged model.
local views: { [Instance]: any } = setmetatable({}, { __mode = "k" }) :: any
function M.view(model: Model): any
	local v = views[model]
	if v then return v end
	local kind = model:GetAttribute("MotionKind")
	if kind == "groups" then
		local groups = {}
		for i = 1, (model:GetAttribute("MotionGroups") :: number?) or 1 do groups[i] = {} end
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				local g = p:GetAttribute("MotionGroup")
				local down = p:GetAttribute("MotionDown")
				if type(g) == "number" and groups[g] and typeof(down) == "CFrame" then
					local size = p:GetAttribute("MotionSize")
					table.insert(groups[g], { part = p, rest = p.CFrame, size = p.Size, down = down, downSize = if typeof(size) == "Vector3" then size else nil })
				end
			end
		end
		v = { kind = kind, groups = groups, strikes = 0 }
	elseif kind == "ram" then
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("MotionRam") then v = { kind = kind, ram = p, rest = p.CFrame } break end
		end
	elseif kind == "rig" then
		local meta = Assets[model:GetAttribute("SpecialTemplate") :: any]
		local ok, rig = pcall(M.rig, model, meta)
		if ok and rig then v = { kind = kind, rig = rig } end
	end
	if not v then return nil end
	v.model = model
	v.hit = (model:GetAttribute("MotionHit") :: number?) or .4
	views[model] = v
	return v
end
-- seconds from the start of a strike to contact
function M.hitTime(v: any, cycle: number): number
	if v.kind == "rig" then return Feedback.timing(cycle, true).hit end
	return math.min(.6, cycle * .7) * v.hit
end

local function tween(p: BasePart, t: number, props: { [string]: any }, dir: Enum.EasingDirection?)
	TweenService:Create(p, TweenInfo.new(math.max(t, .01), Enum.EasingStyle.Quad, dir or Enum.EasingDirection.In), props):Play()
end

local function playRig(v: any, cycle: number, late: number)
	local rig = v.rig if rig.busy then return end rig.busy = true
	-- contact (key 33/71) lands when the shared feedback expects the hit; the return
	-- stroke takes the rest of the time. A late start squeezes the way down.
	local hit = Feedback.timing(cycle, true).hit
	local down = math.max(hit - late, hit * .25)
	local back = math.clamp(cycle * .55, .45, 1)
	local CONTACT = 33 / 71
	task.spawn(function()
		for i = 2, #rig.times do
			local t0, t1 = rig.times[i - 1], rig.times[i]
			local dt = if t1 <= CONTACT then (t1 - t0) / CONTACT * down else (t1 - t0) / (1 - CONTACT) * back
			for name, list in rig.poses do
				local part = rig.rest[name].part local a, b = list[i - 1], list[i]
				if part.Parent and (a.cf ~= b.cf or a.size ~= b.size) then
					TweenService:Create(part, TweenInfo.new(dt, Enum.EasingStyle.Linear), { CFrame = b.cf, Size = b.size }):Play()
				end
			end
			task.wait(dt)
			if not v.model.Parent then break end
		end
		for _, r in rig.rest do if r.part.Parent then r.part.CFrame = r.cf r.part.Size = r.size end end
		rig.busy = false
	end)
end

-- Play one strike. event: { cycle, completed, y = the ram's contact height (ram kind) };
-- late: seconds since the strike should have started (the client catching up).
function M.play(v: any, event: any, late: number?)
	local lateBy = late or 0
	local cycle = event.cycle or 1.8
	if v.kind == "rig" then playRig(v, cycle, lateBy) return end
	local duration = math.min(.6, cycle * .7)
	local hit = duration * v.hit
	local down = math.max(hit - lateBy, hit * .25)
	local retract = math.max(down, duration * .48 - lateBy)
	local up = duration * .52
	local model = v.model
	if v.kind == "ram" then
		local p, rest = v.ram, v.rest
		local y = tonumber(event.y) or rest.Position.Y
		tween(p, down, { CFrame = CFrame.new(rest.Position.X, y, rest.Position.Z) * rest.Rotation })
		task.delay(retract, function() if model.Parent and p.Parent then tween(p, up, { CFrame = rest }, Enum.EasingDirection.Out) end end)
		return
	end
	v.strikes += 1
	for i, group in v.groups do
		-- Twin Titan alternates, with a simultaneous finishing stroke (visual only)
		if #v.groups > 1 and not event.completed and i ~= ((v.strikes - 1) % #v.groups + 1) then continue end
		for _, e in group do
			local p = e.part
			if not p.Parent then continue end
			tween(p, down, if e.downSize then { CFrame = e.down, Size = e.downSize } else { CFrame = e.down })
			task.delay(retract, function()
				if model.Parent and p.Parent then tween(p, up, if e.downSize then { CFrame = e.rest, Size = e.size } else { CFrame = e.rest }, Enum.EasingDirection.Out) end
			end)
		end
	end
end

return M
