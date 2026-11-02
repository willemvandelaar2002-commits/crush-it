--!strict
-- 2 Nov: the What's New panel (Shared/NewsConfig, sent by server/WhatsNew once
-- per version). Waits until no other menu is open and no factory event runs
-- (the pop-up gate), then shows the update's lines; closing it tells the server.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local INK = Style.Colors.Ink

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local node = Instance.new(class)
	for k, v in props do (node :: any)[k] = v end
	node.Parent = parent
	return node
end

local gui = make("ScreenGui", { Name = "WhatsNewHud", ResetOnSpawn = false, DisplayOrder = 7, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local W, H = 560, 420
local panel = make("Frame", { Name = "WhatsNewPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(W, H), BackgroundColor3 = Color3.fromRGB(40, 48, 84), Visible = false, ZIndex = 5 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, panel)
make("UIStroke", { Thickness = 5, Color = INK }, panel)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(80, 96, 160), Color3.fromRGB(36, 42, 74)) }, panel)
Style.studsImage(panel, 26, 0.9).ZIndex = 5
Style.modal(panel)
panel:SetAttribute("FitWidth", W + 40)
panel:SetAttribute("FitHeight", H + 40)

local title = make("TextLabel", { Name = "Title", Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 56), BackgroundTransparency = 1,
	TextScaled = true, Text = "What's New", ZIndex = 7 }, panel)
Style.bold(title, 3)
title.TextColor3 = Color3.fromRGB(255, 220, 90)
local list = make("Frame", { Name = "Lines", Position = UDim2.fromOffset(28, 80), Size = UDim2.new(1, -56, 1, -160), BackgroundTransparency = 1, ZIndex = 6 }, panel)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local ok = make("TextButton", { Name = "Ok", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(220, 58),
	Text = "LET'S GO!", TextScaled = true, ZIndex = 7 }, panel)
Style.button(ok, Style.GREEN)

local current: number? = nil
ok.Activated:Connect(function()
	panel.Visible = false
	if current then Net.event("NewsSeen"):FireServer(current) current = nil end
end)

Net.event("WhatsNew").OnClientEvent:Connect(function(news: any)
	if type(news) ~= "table" or type(news.lines) ~= "table" then return end
	-- the pop-up gate: never over another menu, an event, or straight after a reveal
	local waited = 0
	while (Style.hasModal() or me:GetAttribute("FactoryEventRunning") == true) and waited < 300 do
		task.wait(1) waited += 1
	end
	if Style.hasModal() then return end -- still busy after 5 min: next join
	for _, c in list:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
	title.Text = news.title or "What's New"
	for i, line in news.lines do
		local l = make("TextLabel", { Name = "Line" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
			TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "• " .. tostring(line), ZIndex = 7 }, list)
		Style.text(l, 2)
	end
	current = news.version
	panel.Visible = true
end)
