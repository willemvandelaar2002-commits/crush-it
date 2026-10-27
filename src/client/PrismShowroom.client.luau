--!strict
-- Prism Mech showroom pads (server/PrismShowroom): a name tag with a
-- GUARANTEED CRUSHER chip (OWNED once you bought it), a slow, soft rainbow on
-- the pad's ring and light, and the E prompt opening the offer in the shop
-- (ShopHud attribute "OpenOffer").
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local O = require(ReplicatedStorage.Shared.OfferConfig)

local me = Players.LocalPlayer
local rings: { [BasePart]: boolean } = {}
local chips: { [TextLabel]: Frame } = {}

local function owned(): boolean return me:GetAttribute("Offer_" .. O.Showroom.id) == true end
local function paintChips()
	for text, chip in chips do
		if not text.Parent then chips[text] = nil continue end
		text.Text = if owned() then "OWNED ✓" else O.Showroom.tag
		chip.BackgroundColor3 = if owned() then Color3.fromRGB(70, 200, 100) else Color3.fromRGB(34, 40, 78)
	end
end

local function setup(model: Instance)
	local anchor = model:WaitForChild("TagAnchor", 10) :: BasePart?
	local ring = model:WaitForChild("GlowRing", 10) :: BasePart?
	if ring then rings[ring] = true end
	if not anchor or anchor:FindFirstChild("ShowroomTag") then return end
	local tag = Instance.new("BillboardGui")
	tag.Name = "ShowroomTag"
	tag.Size = UDim2.fromOffset(240, 78)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 0.5, 0)
	tag.MaxDistance = 90
	tag.LightInfluence = 0
	tag.Parent = anchor
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Text = string.upper(O.Showroom.title)
	title.Parent = tag
	Style.text(title, 3)
	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Position = UDim2.new(0.5, 0, 0, 42)
	chip.Size = UDim2.fromOffset(200, 30)
	chip.Parent = tag
	Instance.new("UICorner", chip).CornerRadius = UDim.new(1, 0)
	local edge = Instance.new("UIStroke")
	edge.Thickness = 3
	edge.Color = Color3.new(1, 1, 1)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = chip
	local rainbow = Instance.new("UIGradient")
	rainbow.Parent = edge
	local keys = {}
	for i = 0, 5 do keys[i + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, 0.7, 1)) end
	rainbow.Color = ColorSequence.new(keys)
	local text = Instance.new("TextLabel")
	text.Position = UDim2.fromScale(0.06, 0.12)
	text.Size = UDim2.fromScale(0.88, 0.76)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Parent = chip
	Style.text(text, 2)
	chips[text] = chip
	paintChips()
	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function()
			local hud = me:FindFirstChild("PlayerGui") and me.PlayerGui:FindFirstChild("ShopHud")
			if hud then hud:SetAttribute("OpenOffer", O.Showroom.id) end
		end)
	end
end

for _, m in CollectionService:GetTagged("PrismShowroom") do task.spawn(setup, m) end
CollectionService:GetInstanceAddedSignal("PrismShowroom"):Connect(function(m) task.spawn(setup, m) end)
me:GetAttributeChangedSignal("Offer_" .. O.Showroom.id):Connect(paintChips)

-- slow, soft rainbow on the ring and its light (restrained: low saturation)
RunService.RenderStepped:Connect(function()
	local hue = (os.clock() * 0.06) % 1
	local c = Color3.fromHSV(hue, 0.45, 1)
	for ring in rings do
		if not ring.Parent then rings[ring] = nil continue end
		ring.Color = c
		local light = ring:FindFirstChildOfClass("PointLight")
		if light then light.Color = c end
	end
end)
