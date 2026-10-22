--!strict
if require(game:GetService("ReplicatedStorage").Shared.Config).Crushers.Enabled then return end
-- Zone label at the top of the screen (Destroy a Vault's "Base" / "Market"):
-- "Your Plot", "<Name>'s Plot", "Free Plot", "Scrap Shop" or "Hub",
-- in a cobalt workshop plate that pops when it changes. Plots carry their
-- floor-centre CFrame as the attribute "Origin" (server/Plots.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local pill = Instance.new("Frame")
pill.Name = "Zone"
pill.AnchorPoint = Vector2.new(0.5, 0)
-- desktop: above the goal bar; phones: the goal bar is in the top-right corner, so under it
pill.Position = if touch then UDim2.new(1, -110, 0, 44) else UDim2.new(0.5, 0, 0, 4)
pill.Size = UDim2.fromOffset(if touch then 150 else 200, if touch then 28 else 34)
pill.Parent = gui
Style.panel(pill, Style.Colors.Cobalt, Style.Colors.CobaltDark)
local function fitZone()
	local viewport = Workspace.CurrentCamera.ViewportSize
	local compact = Style.compact()
	local portrait = compact and viewport.X < viewport.Y
	pill.AnchorPoint = if compact and not portrait then Vector2.new(1, 0) else Vector2.new(0.5, 0)
	pill.Position = if portrait then UDim2.new(0.5, 0, 0, 86)
		else if compact then UDim2.new(1, -14, 0, 44) else UDim2.new(0.5, 0, 0, 4)
	pill.Size = UDim2.fromOffset(if compact then 150 else 200, if compact then 24 else 34)
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitZone)
fitZone()
local scale = Instance.new("UIScale")
scale.Parent = pill
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.ZIndex = 2
label.Parent = pill
Style.text(label, 2.5)
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.Parent = label

local function zone(pos: Vector3): string
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return "Hub"
	end
	local P = Config.Plots
	local half = P.FloorSize / 2
	local shop = Config.ScrapShop
	for _, plot in plots:GetChildren() do
		local origin = plot:GetAttribute("Origin") :: CFrame?
		if not origin then
			continue
		end
		local p = origin:PointToObjectSpace(pos)
		local mine = plot:GetAttribute("Index") == player:GetAttribute("Plot")
		if math.abs(p.X) <= half and p.Z <= P.Front and p.Z >= -P.Back then
			-- the scrap shop: just inside the gate on the left (Plots.luau)
			if p.X <= P.ShopX and p.X >= P.ShopX - shop.Depth and math.abs(p.Z - P.ShopZ) <= shop.Width / 2 then
				return if mine then "Your Scrap Shop" else "Scrap Shop"
			end
			if mine then
				return "Your Plot"
			end
			local sign = plot:FindFirstChild("OwnerName", true) :: TextLabel?
			local name = sign and sign.Text or ""
			return if name ~= "" and name ~= "Free plot" then name else "Free Plot"
		end
	end
	return "Hub"
end

local current = ""
task.spawn(function()
	while true do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local z = if root then zone(root.Position) else "Hub"
		if z ~= current then
			current = z
			label.Text = z
			scale.Scale = 0.75
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		task.wait(0.25)
	end
end)
