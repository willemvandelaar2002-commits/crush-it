--!strict
-- 8 Nov (Willem: "a command so I can skip to plots, or a dev panel"): a small DEV button
-- (bottom left, Studio only) opens a panel of test shortcuts. Everything goes to the server
-- through the remote "Dev", which only exists in Studio (server/CrusherGame); live servers
-- never answer it. Chat: /plot 1-5 does the same as the plot buttons.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
local Net = require(RS.Shared.Net)

local me = Players.LocalPlayer
local rgb = Color3.fromRGB
local remote = Net.event("Dev")

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local n = Instance.new(class)
	for k, v in props do (n :: any)[k] = v end
	n.Parent = parent
	return n
end

local gui = make("ScreenGui", { Name = "DevPanelHud", ResetOnSpawn = false, DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, me:WaitForChild("PlayerGui"))
local open = make("TextButton", { Name = "DevButton", Text = "DEV", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -90), Size = UDim2.fromOffset(56, 30),
	BackgroundColor3 = rgb(30, 30, 40), TextColor3 = rgb(255, 220, 80), Font = Enum.Font.GothamBold, TextSize = 14 }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, open)

local panel = make("Frame", { Name = "DevPanel", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -126), Size = UDim2.fromOffset(250, 10),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = rgb(25, 25, 35), BackgroundTransparency = 0.05, Visible = false }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, panel)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
local status = make("TextLabel", { Text = "DEV (Studio only)", Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, TextColor3 = rgb(255, 220, 80),
	Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 }, panel)

local order = 0
local function row(title: string, buttons: { { any } })
	order += 1
	make("TextLabel", { Text = title, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, TextColor3 = rgb(180, 185, 210), Font = Enum.Font.Gotham,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, panel)
	order += 1
	local line = make("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = order }, panel)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, line)
	for _, b in buttons do
		local btn = make("TextButton", { Text = b[1], Size = UDim2.new(1 / #buttons, -4, 1, 0), BackgroundColor3 = rgb(60, 70, 110), TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 13 }, line)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
		btn.Activated:Connect(function()
			b[2]()
			status.Text = "sent: " .. title .. " " .. b[1]
		end)
	end
end
local function send(what: string, arg: any): () -> ()
	return function() remote:FireServer(what, arg) end
end

row("Plot level (skips tutorial + goals, unlocks its bays)", { { "1", send("Plot", 1) }, { "2", send("Plot", 2) }, { "3", send("Plot", 3) }, { "4", send("Plot", 4) }, { "5", send("Plot", 5) }, { "6", send("Plot", 6) } })
row("Skip", { { "Tutorial", send("Skip", "") }, { "+ Goals", send("Skip", "goals") } })
row("Cash", { { "+1M", send("Cash", 1e6) }, { "+1B", send("Cash", 1e9) }, { "+1T", send("Cash", 1e12) } })
row("Big roll", { { "Secret", send("BigRoll", "Secret") }, { "Divine", send("BigRoll", "Divine") }, { "Limited", send("BigRoll", "Limited") } })
-- 9 Nov: Gems / rebirth tests
row("Gems", { { "+25", send("Gems", 25) }, { "+100", send("Gems", 100) }, { "+1000", send("Gems", 1000) } })
row("Rebirths (sets the count; 5+: Gem Crusher)", { { "0", send("Rebirths", 0) }, { "1", send("Rebirths", 1) }, { "3", send("Rebirths", 3) }, { "5", send("Rebirths", 5) }, { "10", send("Rebirths", 10) } })
row("Rebirth (test Head Start / Nest Egg)", { { "Make ready", send("RebirthReady") }, { "Rebirth now", send("RebirthNow") } })
row("Gem upgrades", { { "All max", send("GemUps", "max") }, { "All 0", send("GemUps", "reset") } })
row("Other", { { "Crate ready", send("CrateReady") }, { "Weekend on/off", send("Weekend") } })

open.Activated:Connect(function() panel.Visible = not panel.Visible end)
