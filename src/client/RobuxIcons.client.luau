--!strict
-- 5 Nov (Willem: "use the Robux icon everywhere you can buy something with Robux"):
-- every text on screen or on a sign that shows a price as "R$ 99" gets Willem's Robux
-- coin (Icons.Robux) instead of the letters, via Style.robux. Watches the HUD
-- (PlayerGui) and the signs in the world (SurfaceGuis / BillboardGuis); a label whose
-- price arrives later ("..." -> "R$ 69") is caught when its text changes.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Icons = require(RS.Shared.Icons)

local me = Players.LocalPlayer
local watched: { [Instance]: RBXScriptConnection } = {}

local function consider(obj: Instance)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	-- Style.bold draws the text in two child copies ("Drop", "Face"): only the label itself
	if (obj.Name == "Drop" or obj.Name == "Face") and obj.Parent and obj.Parent:IsA("TextLabel") then return end
	if obj:GetAttribute("RobuxIcon") or watched[obj] then return end
	-- a button whose text is drawn by a caption child (Style.buttonStuds): the caption gets the icon
	if (obj :: any).TextTransparency >= 1 then return end
	local label = obj :: TextLabel
	local function check(): boolean
		if label.Text:find("R%$") then
			Style.robux(label, Icons.Robux)
			return true
		end
		return false
	end
	if check() then return end
	watched[obj] = label:GetPropertyChangedSignal("Text"):Connect(function()
		if check() and watched[obj] then watched[obj]:Disconnect() watched[obj] = nil end
	end)
	obj.Destroying:Connect(function() if watched[obj] then watched[obj]:Disconnect() watched[obj] = nil end end)
end

local function inWorldGui(obj: Instance): boolean
	return obj:FindFirstAncestorWhichIsA("SurfaceGui") ~= nil or obj:FindFirstAncestorWhichIsA("BillboardGui") ~= nil
end

local pg = me:WaitForChild("PlayerGui")
for _, d in pg:GetDescendants() do consider(d) end
pg.DescendantAdded:Connect(function(d) task.defer(consider, d) end)
for _, d in workspace:GetDescendants() do if inWorldGui(d) then consider(d) end end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("TextLabel") or d:IsA("TextButton") then task.defer(function() if inWorldGui(d) then consider(d) end end) end
end)
