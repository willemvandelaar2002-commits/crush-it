--!strict
-- Keep Roblox's native backpack, number keys, tooltips and equip behavior.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Images=require(RS.Shared.CrusherIcons)
local Icon=require(script.Parent.CrusherIcon)
local player=Players.LocalPlayer
local watched={} :: {[Tool]: ()->()}
local containers=setmetatable({}, {__mode="k"})
local function watch(tool: Instance)
	if not tool:IsA("Tool") or watched[tool] then return end
	local typeId=tool:GetAttribute("CrusherType") if typeof(typeId)~="string" then return end
	local alive=true
	local unsubscribe=Icon.ready(typeId,function(ready) if alive and ready then tool.TextureId=Images.image(typeId) or "" end end)
	watched[tool]=unsubscribe
	tool.Destroying:Once(function() alive=false unsubscribe() watched[tool]=nil end)
end
local function bind(root: Instance)
	if containers[root] then return end containers[root]=true
	root.ChildAdded:Connect(watch) for _,child in root:GetChildren() do watch(child) end
end
player.ChildAdded:Connect(function(child) if child:IsA("Backpack") then bind(child) end end)
bind(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(bind) if player.Character then bind(player.Character) end
