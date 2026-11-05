--!strict
-- 5 Nov (vault V2: Game Passes "a status pass: visible signals advertise the pass to
-- everyone"; Text Chat Customization: chat PrefixText stops working under Roblox's
-- platform-integrated chat, default Feb 2027): a small tag above the head of VIP pass
-- owners (gold "VIP") and Roblox Plus members (blue "PLUS"). VIP wins when both.
-- Built on the server so every player sees it; rebuilt on respawn and when the pass
-- or the subscription changes. Also mirrors Plus to the player attribute PlusMember
-- (the client chat tag reads it; HasRobloxSubscription is only reliable on the server).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Store = require(RS.Shared.Store)

local M = {}

local LOOKS = {
	VIP = { text = "VIP", top = Color3.fromRGB(255, 226, 90), bottom = Color3.fromRGB(240, 150, 20), stroke = Color3.fromRGB(110, 60, 0) },
	PLUS = { text = "PLUS", top = Color3.fromRGB(120, 200, 255), bottom = Color3.fromRGB(40, 110, 245), stroke = Color3.fromRGB(10, 40, 110) },
}

local function isPlus(p: Player): boolean
	local ok, v = pcall(function() return (p :: any).HasRobloxSubscription end)
	return ok and v == true
end

local function which(p: Player): string?
	if Store.hasPass(p, "VIP") then return "VIP" end
	if isPlus(p) then return "PLUS" end
	return nil
end

local function build(kind: string, head: BasePart): BillboardGui
	local look = LOOKS[kind]
	local gui = Instance.new("BillboardGui")
	gui.Name = "StatusTag"
	gui.Size = UDim2.fromOffset(84, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0) -- above Roblox's own name
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Adornee = head
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pill
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(look.top, look.bottom)
	grad.Parent = pill
	local edge = Instance.new("UIStroke")
	edge.Color = look.stroke
	edge.Thickness = 2.5
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = pill
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(6, 3)
	label.Size = UDim2.new(1, -12, 1, -6)
	label.Font = Enum.Font.FredokaOne
	label.Text = look.text
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = look.stroke
	stroke.Thickness = 2
	stroke.Parent = label
	return gui
end

local function refresh(p: Player)
	p:SetAttribute("PlusMember", isPlus(p))
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not head or not head:IsA("BasePart") then return end
	local old = head:FindFirstChild("StatusTag")
	local kind = which(p)
	if old and old:GetAttribute("Kind") == kind then return end
	if old then old:Destroy() end
	if kind then
		local gui = build(kind, head)
		gui:SetAttribute("Kind", kind)
		gui.Parent = head
	end
end

function M.start()
	local function join(p: Player)
		p.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 10)
			refresh(p)
		end)
		p:GetAttributeChangedSignal(Store.passAttr("VIP")):Connect(function() refresh(p) end)
		pcall(function()
			p:GetPropertyChangedSignal("HasRobloxSubscription" :: any):Connect(function() refresh(p) end)
		end)
		if p.Character then refresh(p) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end
end

return M
