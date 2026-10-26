--!strict
-- Plays the coating booth animation on your own plot after the server confirms
-- a coating (CrusherState result.coating). Visual only: the server already
-- charged and saved the coating before this runs. One controller per booth,
-- rebuilt if the booth is swapped (plot upgrade colour) or streams out.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local Net = require(RS.Shared.Net)
local Visuals = require(script.Parent.CoatingVisuals)

local me = Players.LocalPlayer
local controller: any = nil
local booth: Instance? = nil

local function findBooth(): Model?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	local holder = plot and plot:FindFirstChild("CoatingBooth", true)
	local model = holder and holder:FindFirstChildWhichIsA("Model")
	if model and model:FindFirstChild("Coat_Body") then return model end
	return nil
end

Net.event("CrusherState").OnClientEvent:Connect(function(v)
	local r = v and v.result
	if type(r) ~= "table" or type(r.coating) ~= "string" then return end
	local model = findBooth()
	if not model then return end
	-- only when you're close enough to see it
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - model:GetPivot().Position).Magnitude > 120 then return end
	if booth ~= model then
		if controller then controller:Destroy() end
		local ok, made = pcall(Visuals.new, model)
		controller = if ok then made else nil
		booth = model
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(workspace) and booth == model then
				if controller then controller:Destroy() end
				controller = nil booth = nil
			end
		end)
	end
	if controller then controller:Play(r.coating) end
end)
