--!strict
-- Coating and fusion reveal effects (Willem's machine-effects pack, 28 Oct).
-- Plays only after the server confirmed the transaction for you: CrusherState
-- with result.coating (coating booth) or result.fused (fusion machine). The
-- pictures are copies of your real crushers: the "before" crusher and the
-- four fusion inputs are rebuilt from the previous state (the server has
-- already used up three copies by then), the result from the returned item.
-- Visual only: nothing here grants, charges or saves. The booth's own arm and
-- turntable motion stays in CoatingFx.client.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Net = require(RS.Shared.Net)
local Finish = require(RS.Shared.CrusherFinish)
local FX = require(script.Parent.Effects.MachineFX)

local me = Players.LocalPlayer
local COATING_SCALE = 1.15 -- spray starts line up with the booth's two nozzles
local FUSION_SCALE = 1.2 -- fills the fuser's glass chamber, on the output lift

local previous: { [string]: any } = {}
local handles: { any } = {}

local function myPlot(): Instance?
	local plots = workspace:FindFirstChild("Plots")
	return plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
end
local function near(pos: Vector3): boolean
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - pos).Magnitude < 160
end
-- A visual-only copy of a crusher with its coating/fused look.
local function snapshot(item: any, modifier: string?, fused: boolean?): Model?
	local folder = RS:FindFirstChild("CrusherPreviewModels")
	local source = folder and folder:FindFirstChild(item.type)
	if not source or not source:IsA("Model") then return nil end
	local copy = source:Clone()
	local mod = modifier or item.modifier
	if mod and mod ~= "Standard" then pcall(Finish.apply, copy, mod) end
	if fused then pcall(Finish.fused, copy) end
	local snap = FX.captureModel(copy)
	copy:Destroy()
	return snap
end
-- FXOrigin attachment when the machine has one, else the known platform.
local function originOf(machine: Instance, platform: string): CFrame?
	local marker = machine:FindFirstChild("FXOrigin", true)
	if marker and marker:IsA("Attachment") then return marker.WorldCFrame end
	local p = machine:FindFirstChild(platform, true)
	if not p then return nil end
	if p:IsA("Attachment") then return CFrame.new(p.WorldPosition) end
	if p:IsA("BasePart") then return CFrame.new(p.Position + Vector3.new(0, p.Size.Y / 2, 0)) end
	return nil
end
local function track(handle: any?)
	if handle then table.insert(handles, handle) end
	for i = #handles, 1, -1 do if not handles[i]:IsPlaying() then table.remove(handles, i) end end
end
local function cancelAll()
	for _, h in handles do h:Cancel() end
	table.clear(handles)
end

local function playCoating(result: any, items: { any })
	local plot = myPlot()
	local holder = plot and plot:FindFirstChild("CoatingBooth", true)
	local booth = holder and holder:FindFirstChildWhichIsA("Model")
	if not booth then return end
	local origin = originOf(booth, "CrusherDisplay")
	if not origin or not near(origin.Position) then return end
	local now
	for _, item in items do if item.id == result.id then now = item end end
	local before = previous[result.id]
	if not now then return end
	local recipe
	for _, r in C.Coatings do if r.name == result.coating then recipe = r end end
	local beforeSnap = if before then snapshot(before, before.modifier, before.fused) else nil
	local resultSnap = snapshot(now, result.coating, now.fused)
	local handle = FX.playCoating({ owner = booth, origin = origin, before = beforeSnap, result = resultSnap,
		color = if recipe then recipe.color else nil, scale = COATING_SCALE })
	if beforeSnap then beforeSnap:Destroy() end
	if resultSnap then resultSnap:Destroy() end
	track(handle)
end

local function playFusion(result: any, items: { any })
	local plot = myPlot()
	local fuser = plot and plot:FindFirstChild("Fuser", true)
	if not fuser then return end
	local origin = originOf(fuser, "OutputLift")
	if not origin or not near(origin.Position) then return end
	-- the four inputs: the kept main as it was, plus the three copies that are gone now
	local still: { [string]: boolean } = {}
	for _, item in items do still[item.id] = true end
	local inputs: { any } = {}
	local main = previous[result.id]
	if main then table.insert(inputs, main) end
	for id, item in previous do
		if #inputs >= 4 then break end
		if not still[id] and item.type == result.type then table.insert(inputs, item) end
	end
	-- the fused crusher is collected minutes after the copies went in: show four of its type
	while #inputs < 4 do table.insert(inputs, { type = result.type, modifier = if #inputs == 0 then result.modifier else "Standard" }) end
	local snaps: { Model } = {}
	for _, item in inputs do
		local s = snapshot(item, item.modifier, item.fused)
		if s then table.insert(snaps, s) end
	end
	local resultSnap = snapshot(result, result.modifier, true)
	local handle = FX.playFusion({ owner = fuser, origin = origin, inputs = snaps, result = resultSnap, scale = FUSION_SCALE })
	for _, s in snaps do s:Destroy() end
	if resultSnap then resultSnap:Destroy() end
	track(handle)
end

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.items) ~= "table" then return end
	local r = v.result
	if type(r) == "table" then
		local ok, err = pcall(function()
			if type(r.coating) == "string" and type(r.id) == "string" then playCoating(r, v.items)
			elseif r.fused == true and type(r.type) == "string" then playFusion(r, v.items) end
		end)
		if not ok then warn("[MachineEffects] " .. tostring(err)) end
	end
	table.clear(previous)
	for _, item in v.items do previous[item.id] = item end
end)
me.CharacterRemoving:Connect(cancelAll)
local function watchDeath(char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum and hum:IsA("Humanoid") then hum.Died:Connect(cancelAll) end
end
me.CharacterAdded:Connect(watchDeath)
if me.Character then task.spawn(watchDeath, me.Character) end
me:GetAttributeChangedSignal("Plot"):Connect(cancelAll)
-- Studio only: replay an effect with made-up data (visual only)
if game:GetService("RunService"):IsStudio() then
	local probe = Instance.new("BindableFunction")
	probe.Name = "MachineEffectsPreview"
	probe.OnInvoke = function(kind: string, result: any, before: { any }?, after: { any })
		table.clear(previous)
		for _, item in before or {} do previous[item.id] = item end
		if kind == "Coating" then playCoating(result, after) else playFusion(result, after) end
		return #handles
	end
	probe.Parent = script
end
