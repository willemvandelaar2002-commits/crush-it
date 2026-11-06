--!strict
-- 6 Nov (Willem: phones; vault: Haptics, Feedback Timing - Sound Visual and Haptic Sync,
-- "dramatic events and UI feedback, not constant buzzing"): short vibrations on phones
-- and controllers for the big moments, using Roblox's HapticEffect (best effort: devices
-- without vibration simply do nothing). Off with the VIBRATION setting (Set_Vibration).
--   your roll           a light tick
--   Legendary+ for you  a notification buzz
--   your Secret/Divine  a big rumble, again on the reveal
--   plot upgrade        a big rumble
--   a purchase          a notification buzz
--   golden toy grabbed  a light tick
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer

-- only where something can vibrate: touch screens and gamepads
local function capable(): boolean
	return UIS.TouchEnabled or UIS.GamepadEnabled
end

local folder = Instance.new("Folder")
folder.Name = "Haptics"
folder.Parent = workspace -- (the docs' samples play them from Workspace)

local effects: { [string]: any } = {}
local function effect(name: string, kind: Enum.HapticEffectType): any
	local ok, e = pcall(function()
		local h = Instance.new("HapticEffect")
		h.Name = name
		h.Type = kind
		h.Parent = folder
		return h
	end)
	effects[name] = if ok then e else nil
	return effects[name]
end
effect("Tick", Enum.HapticEffectType.UIClick)
effect("Buzz", Enum.HapticEffectType.UINotification)
effect("Rumble", Enum.HapticEffectType.GameplayExplosion)

local lastAt: { [string]: number } = {}
local function play(name: string)
	if me:GetAttribute("Set_Vibration") == false or not capable() then return end
	local e = effects[name]
	if not e then return end
	-- never buzz constantly: at most one of each per 0.25 s
	if os.clock() - (lastAt[name] or 0) < 0.25 then return end
	lastAt[name] = os.clock()
	pcall(function() e:Play() end)
end

Net.event("CrusherState").OnClientEvent:Connect(function(v: any)
	if type(v) == "table" and v.rolled then play("Tick") end
end)
Net.event("RarePull").OnClientEvent:Connect(function(msg: any)
	if type(msg) == "table" and msg.userId == me.UserId and msg.rarity then play("Buzz") end
end)
Net.event("BigRoll").OnClientEvent:Connect(function(msg: any)
	if type(msg) ~= "table" or msg.userId ~= me.UserId then return end
	play("Rumble")
	-- and again when the crusher is revealed (the server holds the reveal this long)
	local hold = tonumber(msg.hold) or 4
	task.delay(math.max(1, hold - 0.6), function() lastAt.Rumble = 0 play("Rumble") end)
end)
Net.event("PlotUpgraded").OnClientEvent:Connect(function() play("Rumble") end)
Net.event("Purchased").OnClientEvent:Connect(function() play("Buzz") end)
Net.event("GoldenToy").OnClientEvent:Connect(function(r: any)
	if type(r) == "table" and not r.spawned then play("Tick") end -- grabbed, not just landed
end)
