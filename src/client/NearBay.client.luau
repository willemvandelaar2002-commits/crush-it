--!strict
-- 3 Nov (vault: HUD Design "tap pads", World-Space UI "verified on a phone"; Willem:
-- phone sessions are shorter). The LEVEL UP / MAX buttons live on small plaques in
-- the world, which are hard to hit with a thumb. On touch screens, standing next to
-- one of your bays with a crusher shows a big screen button for that bay:
--   [ BAY 3 · LEVEL UP $35 ]  [ MAX ]
-- It sends the same actions as the plaque (Level / LevelMax with the bay and id),
-- so the server checks reach, cash and caps exactly as before.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = require(RS.Shared.Config)
local Net = require(RS.Shared.Net)
local Style = require(RS.Shared.Kit.Style)
local Format = require(RS.Shared.Format)
local C = Config.Crushers
if not C.Enabled then return end
if not UserInputService.TouchEnabled then return end

local me = Players.LocalPlayer
local RANGE = 11 -- studs from the bay (the server allows up to C.Layout.InteractionDistance)

local gui = Instance.new("ScreenGui")
gui.Name = "NearBayHud" gui.ResetOnSpawn = false gui.DisplayOrder = 4 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = me:WaitForChild("PlayerGui")
local bar = Instance.new("Frame")
bar.Name = "Bar" bar.AnchorPoint = Vector2.new(0.5, 1) bar.Position = UDim2.new(0.5, 0, 1, -96)
bar.Size = UDim2.fromOffset(330, 58) bar.BackgroundTransparency = 1 bar.Visible = false bar.Parent = gui
Style.phoneFit(bar, { scale = 0.9 })

local function button(name: string, x: number, w: number, color: Color3): (TextButton, TextLabel)
	local b = Instance.new("TextButton")
	b.Name = name b.Text = "" b.Position = UDim2.fromOffset(x, 0) b.Size = UDim2.fromOffset(w, 58) b.Parent = bar
	Style.button(b, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1 t.TextScaled = true t.Text = "" t.ZIndex = 3
	t.Position = UDim2.fromOffset(8, 6) t.Size = UDim2.new(1, -16, 1, -12) t.Parent = b
	Style.text(t, 2.5)
	return b, t
end
local level, levelText = button("NearLevel", 0, 240, Color3.fromRGB(53, 201, 79))
local max, maxText = button("NearMax", 250, 80, Color3.fromRGB(40, 150, 230))
maxText.Text = "MAX"

local lastColor: Color3? = nil
local function paint(c: Color3) if lastColor ~= c then lastColor = c Style.setButtonColor(level, c) end end
local state: any = nil
local current: { bay: number, id: string }? = nil
Net.event("CrusherState").OnClientEvent:Connect(function(v: any) if type(v) == "table" then state = v end end)

local function plotModel(): Model?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	return if plot and plot:IsA("Model") then plot else nil
end
local function itemById(id: string): any
	for _, item in (state and state.items) or {} do if item.id == id then return item end end
	return nil
end

level.Activated:Connect(function()
	if current then Net.event("CrusherAction"):FireServer("Level", { id = current.id, bay = current.bay }) end
end)
max.Activated:Connect(function()
	if current then Net.event("CrusherAction"):FireServer("LevelMax", { id = current.id, bay = current.bay }) end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local plot = plotModel()
		local found: { bay: number, id: string }? = nil
		-- hidden during the tutorial and cutscenes (the tutorial points at the plaque)
		local busy = me:GetAttribute("CutscenePlaying") == true or not state or (state.tutorial or 0) <= #C.TutorialSteps
		if root and plot and state and state.bays and not busy then
			local best = RANGE
			for key, id in state.bays do
				local i = tonumber(key)
				local model = i and plot:FindFirstChild("WorkingBay" .. key, true)
				if model and model:IsA("Model") then
					local d = (model:GetPivot().Position - root.Position) * Vector3.new(1, 0, 1)
					local dy = math.abs(model:GetPivot().Position.Y - root.Position.Y)
					if d.Magnitude < best and dy < 8 then best = d.Magnitude found = { bay = i :: number, id = id } end
				end
			end
		end
		current = found
		bar.Visible = found ~= nil
		if found then
			local item = itemById(found.id)
			local cap = C.levelCap(state.plotLevel or 0)
			if item and item.level >= cap then
				levelText.Text = "BAY " .. found.bay .. " · MAX LEVEL"
				paint(Color3.fromRGB(120, 124, 134))
			elseif item then
				local cost = item.cost or C.individualCost(item)
				levelText.Text = "BAY " .. found.bay .. " · LEVEL UP " .. Format.cash(cost)
				paint(if (state.cash or 0) >= cost then Color3.fromRGB(53, 201, 79) else Color3.fromRGB(120, 124, 134))
			end
		end
	end
end)
