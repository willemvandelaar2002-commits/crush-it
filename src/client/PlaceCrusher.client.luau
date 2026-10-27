--!strict
-- While you hold a crusher (backpack tool), every unlocked bay on your own
-- plot shows an E prompt: "Place" on an empty bay, "Swap" on a busy one (the
-- crusher in it goes back to your backpack). The prompts only exist while
-- holding, so they never cover the plaque buttons. The server checks the
-- Equip action (ownership, unlocked bay) as always.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C = require(RS.Shared.CrusherConfig)
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local actionRemote = Net.event("CrusherAction")
local state: any = nil
local prompts: { Instance } = {}
local heldTool: Tool? = nil

local function clear()
	for _, p in prompts do p:Destroy() end
	table.clear(prompts)
end
local function myPlot(): Instance?
	local plots = workspace:FindFirstChild("Plots")
	return plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
end
local function build()
	clear()
	local tool = heldTool
	if not tool or not tool.Parent or not state then return end
	local id = tool:GetAttribute("InventoryId")
	if type(id) ~= "string" then return end
	local plot = myPlot()
	if not plot then return end
	local typeDef = C.typeById(tostring(tool:GetAttribute("CrusherType")))
	local name = if typeDef then typeDef.name else tool.Name
	for i = 1, state.unlocked or 0 do
		local bay = plot:FindFirstChild("WorkingBay" .. i, true)
		local floor = bay and bay:FindFirstChild("BayPlatform")
		local panel = bay and bay:FindFirstChild("Panel")
		if floor and floor:IsA("BasePart") and floor.Transparency < 1 and panel and panel:IsA("BasePart") then
			local current = state.bays[tostring(i)]
			if current ~= id then
				local p = Instance.new("ProximityPrompt")
				p.Name = "PlaceCrusherPrompt"
				p.ActionText = if current then "Swap" else "Place"
				p.ObjectText = name
				p.KeyboardKeyCode = Enum.KeyCode.E
				p.HoldDuration = 0
				p.MaxActivationDistance = 10
				p.RequiresLineOfSight = false
				p.Triggered:Connect(function()
					actionRemote:FireServer("Equip", { id = id, bay = i })
				end)
				-- anchored above the plaque, between it and the machine (where you
				-- stand), high enough that it doesn't cover the plaque buttons
				local at = Instance.new("Attachment")
				at.Name = "PlacePromptAnchor"
				at.Parent = floor
				at.WorldPosition = floor.Position:Lerp(panel.Position, .55) + Vector3.new(0, 5, 0)
				p.Parent = at
				table.insert(prompts, at :: any)
			end
		end
	end
end

local function watchCharacter(char: Model)
	local function check()
		local tool = char:FindFirstChildOfClass("Tool")
		local t = if tool and tool:GetAttribute("InventoryId") ~= nil then tool else nil
		if t ~= heldTool then heldTool = t build() end
	end
	char.ChildAdded:Connect(check)
	char.ChildRemoved:Connect(check)
	check()
end
me.CharacterAdded:Connect(watchCharacter)
if me.Character then watchCharacter(me.Character) end
me.CharacterRemoving:Connect(function() heldTool = nil clear() end)

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" or type(v.bays) ~= "table" then return end
	state = v
	if heldTool then build() end
end)
