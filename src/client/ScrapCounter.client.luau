--!strict
-- 30 Oct (reference: the big number over the vault): a large floating cash
-- amount above YOUR collect bin that rolls up smoothly as scrap comes in and
-- drops to zero when you collect. Reads the player attribute AvailableScrap
-- (set by the server every second). Local only.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)

local player = Players.LocalPlayer
-- exact digits so it visibly ticks ("$651,940"); from a billion on, 3 decimals + suffix
local SUFFIX = { "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function money(n: number): string
	if n < 1e9 then
		local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		return "$" .. s
	end
	local i = 1 n /= 1e9
	while n >= 1000 and i < #SUFFIX do n /= 1000 i += 1 end
	return "$" .. string.format("%.3f", n) .. SUFFIX[i]
end
local GREEN = Color3.fromRGB(120, 255, 90)

local board: BillboardGui? = nil
local label: TextLabel? = nil
local scale: UIScale? = nil
local shown = 0

local function station(): BasePart?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(player:GetAttribute("Plot")))
	local m = plot and plot:FindFirstChild("CollectStation", true)
	local floor = m and m:FindFirstChild("HopperFloor")
	return if floor and floor:IsA("BasePart") then floor else nil
end

local function ensure()
	local floor = station()
	if not floor then
		if board then board:Destroy() board = nil end
		return
	end
	if board and board.Adornee == floor and board.Parent then return end
	if board then board:Destroy() end
	local b = Instance.new("BillboardGui")
	b.Name = "ScrapCounter" b.Adornee = floor b.Size = UDim2.fromOffset(320, 70)
	b.StudsOffsetWorldSpace = Vector3.new(0, 17, 0) b.LightInfluence = 0 b.MaxDistance = 260
	b.AlwaysOnTop = false b.ResetOnSpawn = false
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Text = ""
	t.Parent = b
	Style.text(t, 4)
	t.TextColor3 = GREEN
	local s = Instance.new("UIScale") s.Parent = t
	b.Parent = player:WaitForChild("PlayerGui")
	board, label, scale = b, t, s
end

local last = 0
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	if now - last > 1 then last = now ensure() end
	if not board or not label or not scale then return end
	local target = (player:GetAttribute("AvailableScrap") :: number?) or 0
	if target < shown then shown = target -- collected: snap down
	else shown += (target - shown) * math.min(1, dt * 4) end -- roll up smoothly
	if target - shown < 0.5 then shown = target end
	label.Text = if shown >= 1 then money(shown) else ""
	-- a little pulse while it climbs
	scale.Scale = 1 + math.min(.12, (target - shown) / math.max(1, target) * .6)
end)
