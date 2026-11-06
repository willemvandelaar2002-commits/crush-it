--!strict
-- 6 Nov (Willem: phones; vault audit round 7 gap): the SETTINGS menu. A gear button at
-- the end of the top-left row opens a panel with one row per setting (Shared/
-- SettingsConfig): tap a choice, the server saves it (server/Settings) and mirrors it to
-- the attribute "Set_<key>", which every script reads.
--   Music / Sounds  SoundGroups "Music" and "Sounds" under SoundService: every sound in
--                   the game is put in one of them (music by name), the group's Volume is
--                   the setting, so no other script has to know about it.
--   Shake           Style.shakeOn() (the camera-shake code checks it)
--   Effects         Style.lite() reads it; Low applies at once (client/PhoneLite), going
--                   back to High needs a rejoin (said on the row)
--   Vibration       client/Haptics; only shown on phones and controllers
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)
local S = require(RS.Shared.SettingsConfig)

local me = Players.LocalPlayer
local C = Color3.fromRGB
local INK = Style.Colors.Ink
local remote = Net.event("Settings")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end
local function get(key: string): any
	local v = me:GetAttribute("Set_" .. key)
	if v == nil then return S.Defaults[key] end
	return v
end

-- sound groups ----------------------------------------------------------------------
local MUSIC_NAMES = { BackgroundMusic = true, EventMusic = true }
local musicGroup = make("SoundGroup", { Name = "Music", Volume = 1 }, SoundService)
local sfxGroup = make("SoundGroup", { Name = "Sounds", Volume = 1 }, SoundService)
local function sort(d: Instance)
	if d:IsA("Sound") and d.SoundGroup == nil then
		d.SoundGroup = if MUSIC_NAMES[d.Name] then musicGroup else sfxGroup
	end
end
for _, root in { SoundService, Workspace, me:WaitForChild("PlayerGui") } do
	for _, d in root:GetDescendants() do sort(d) end
	root.DescendantAdded:Connect(sort)
end
local function applyVolumes()
	musicGroup.Volume = tonumber(get("Music")) or 1
	sfxGroup.Volume = tonumber(get("Sounds")) or 1
end
me:GetAttributeChangedSignal("Set_Music"):Connect(applyVolumes)
me:GetAttributeChangedSignal("Set_Sounds"):Connect(applyVolumes)
applyVolumes()

-- the panel -------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "SettingsHud", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local button = Style.iconButton(gui, { name = "SettingsButton", icon = "⚙️", label = "SETTINGS", a = C(110, 170, 255), b = C(40, 80, 200) })
local function place() Style.placeAfterHudRow(button) end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
task.spawn(function() while true do place() task.wait(2) end end) -- the row changes as buttons come and go
-- (the HUD appears step by step in the tutorial: show the gear with the Shop button)
local function followShop()
	local shop = me.PlayerGui:FindFirstChild("ShopButton", true)
	local sg = shop and shop:FindFirstAncestorOfClass("ScreenGui")
	gui.Enabled = sg == nil or sg.Enabled
end
task.spawn(function() while true do followShop() task.wait(1) end end)

local touchy = UIS.TouchEnabled or UIS.GamepadEnabled
local rows = {}
for _, r in S.Rows do
	if not r.touchOnly or touchy then table.insert(rows, r) end
end
local W, ROW = 560, 66
local H = 96 + #rows * ROW + 20
local panel = make("Frame", { Name = "SettingsPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = C(52, 44, 140), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 20) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(80, 68, 190), C(42, 34, 120)) }, panel)
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 20) panel:SetAttribute("FitHeight", H + 20)
local title = make("TextLabel", { Text = "SETTINGS", Position = UDim2.fromOffset(28, 16), Size = UDim2.new(1, -120, 0, 52), BackgroundTransparency = 1,
	TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, panel)
Style.text(title, 4)
local close = make("TextButton", { Text = "", Position = UDim2.new(1, -78, 0, 12), Size = UDim2.fromOffset(64, 64), ZIndex = 7 }, panel)
Style.button(close, C(228, 36, 44))
local x = make("TextLabel", { Text = "X", Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 1, -16), BackgroundTransparency = 1, TextScaled = true, ZIndex = 9 }, close)
Style.text(x, 3)

local GREEN, GREY = C(60, 200, 80), C(110, 116, 140)
local refreshers: { () -> () } = {}
for i, r in rows do
	local y = 90 + (i - 1) * ROW
	local name = make("TextLabel", { Text = r.title, Position = UDim2.fromOffset(28, y + 8), Size = UDim2.fromOffset(200, ROW - 22), BackgroundTransparency = 1,
		TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, panel)
	Style.text(name, 3)
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 30 }, name)
	local choices: { { label: string, value: any } } = {}
	if r.kind == "level" then
		for _, lv in S.Levels do table.insert(choices, { label = S.LevelNames[lv], value = lv }) end
	elseif r.kind == "toggle" then
		choices = { { label = "ON", value = true }, { label = "OFF", value = false } }
	else
		for _, e in S.Effects do table.insert(choices, { label = string.upper(e), value = e }) end
	end
	local bw = math.floor((W - 260 - 20) / 3)
	local buttons = {}
	for j, ch in choices do
		local b = make("TextButton", { Text = "", Position = UDim2.fromOffset(240 + (j - 1) * (bw + 8), y + 4), Size = UDim2.fromOffset(bw, ROW - 14), ZIndex = 7 }, panel)
		Style.button(b, GREY)
		local t = make("TextLabel", { Text = ch.label, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, TextScaled = true, ZIndex = 9 }, b)
		Style.text(t, 3)
		make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 26 }, t)
		b.Activated:Connect(function()
			if get(r.key) == ch.value then return end
			me:SetAttribute("Set_" .. r.key, ch.value) -- at once here; the server saves and confirms
			remote:FireServer(r.key, ch.value)
		end)
		buttons[j] = b
	end
	local function refresh()
		for j, ch in choices do Style.setButtonColor(buttons[j], if get(r.key) == ch.value then GREEN else GREY) end
	end
	me:GetAttributeChangedSignal("Set_" .. r.key):Connect(refresh)
	table.insert(refreshers, refresh)
	refresh()
end

button.Activated:Connect(function()
	if panel.Visible then Style.setOpen(panel, false) return end
	for _, f in refreshers do f() end
	Style.setOpen(panel, true)
end)
close.Activated:Connect(function() Style.setOpen(panel, false) end)
