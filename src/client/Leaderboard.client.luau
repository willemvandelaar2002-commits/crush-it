--!strict
-- Leaderboard panel, top right (Destroy a Vault's "Here / Friends / Global"):
--   Here     everyone in this server, by cash (live)
--   Friends  you + your friends in this server
--   Global   all-time top 50 from the server's OrderedDataStore (Kit/Leaderboard),
--            refreshed every couple of minutes
-- Four rows show at once (scroll for more); if you're not among them your own
-- row is pinned underneath. X collapses it to a small 🏆 button.
-- Replaces Roblox's own player list (same corner).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Format = require(ReplicatedStorage.Shared.Format)
local Style = require(ReplicatedStorage.Shared.Kit.Style)

local player = Players.LocalPlayer

task.spawn(function()
	for _ = 1, 10 do
		if pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end) then
			return
		end
		task.wait(1)
	end
end)

local ROWS = 4
local ROW_H = 26
local WIDTH = 250
local BG = Color3.fromRGB(20, 24, 30)
local ME = Color3.fromRGB(110, 255, 90)

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = parent
	return i
end

local gui = make("ScreenGui", { Name = "LeaderboardHud", ResetOnSpawn = false, DisplayOrder = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

local panel = make("Frame", {
	Name = "Leaderboard", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(WIDTH, 226), BackgroundColor3 = BG,
}, gui)
Style.panel(panel, Color3.fromRGB(55, 104, 159), Color3.fromRGB(30, 47, 84))
-- Keep decorations outside the list layout so studs/borders cannot become rows.
local content = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, panel)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, content)
make("UIPadding", { PaddingBottom = UDim.new(0, 6) }, content)

-- Tabs + close -------------------------------------------------------------------
local tabBar = make("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1 }, content)
local TABS = { "Here", "Friends", "Global" }
local tabButtons: { [string]: TextButton } = {}
local current = "Here"
for i, name in TABS do
	local b = make("TextButton", {
		Name = name, Position = UDim2.new((i - 1) * 0.3, 4, 0, 4), Size = UDim2.new(0.3, -4, 1, -8), BackgroundColor3 = BG,
		BackgroundTransparency = 1, Text = name, TextScaled = true, AutoButtonColor = false,
	}, tabBar)
	Style.text(b, 1.5)
	Style.feedback(b)
	make("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, b)
	make("Frame", {
		Name = "Underline", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.new(0.8, 0, 0, 3),
		BackgroundColor3 = ME, BorderSizePixel = 0, Visible = false,
	}, b)
	tabButtons[name] = b
end
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1,
	Text = "X", TextScaled = true, TextColor3 = Color3.fromRGB(200, 200, 210), Font = Enum.Font.FredokaOne,
}, tabBar)
Style.button(closeButton, Color3.fromRGB(235, 77, 85))

local header = make("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 2 }, content)
local function headerText(text: string, x: number, align: Enum.TextXAlignment)
	make("TextLabel", {
		Position = UDim2.new(x, if x == 0 then 10 else -10, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(x, 0),
		BackgroundTransparency = 1, Text = text, TextScaled = true, Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(170, 175, 185), TextXAlignment = align,
	}, header)
end
headerText("Player", 0, Enum.TextXAlignment.Left)
headerText("Cash", 1, Enum.TextXAlignment.Right)

local list = make("ScrollingFrame", {
	Name = "Rows", Size = UDim2.new(1, 0, 0, ROWS * ROW_H), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 3,
	ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

local pinned = make("Frame", {
	Name = "You", Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, LayoutOrder = 4, Visible = false,
}, content)
local statusLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, LayoutOrder = 5, Visible = false, TextWrapped = true,
	Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(170, 175, 185), Position = UDim2.fromOffset(10, 0),
}, content)

-- Collapsed button.
local openButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = BG, BackgroundTransparency = 0.25, Text = "🏆", TextScaled = true, Visible = false,
}, gui)
Style.button(openButton, Color3.fromRGB(71, 145, 239))
local function fitLeaderboard()
	local compact = Style.compact()
	panel.Position = UDim2.new(1, -10, 0, if compact then 86 else 8)
	openButton.Position = UDim2.new(1, -12, 0, if compact then 146 else 8)
end
if Style.compact() then
	panel.Visible = false
	openButton.Visible = true
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitLeaderboard)
fitLeaderboard()
closeButton.Activated:Connect(function()
	panel.Visible = false
	openButton.Visible = true
end)
openButton.Activated:Connect(function()
	panel.Visible = true
	openButton.Visible = false
end)

-- Rows ---------------------------------------------------------------------------
type Entry = { id: number, name: string, score: number }

local function fillRow(row: Frame, rank: number?, e: Entry)
	row:ClearAllChildren()
	local mine = e.id == player.UserId
	if mine then
		make("Frame", { Size = UDim2.new(1, -8, 1, -2), Position = UDim2.fromOffset(4, 1), BackgroundColor3 = ME, BackgroundTransparency = 0.82 }, row)
	end
	local rankColor = if rank == 1 then Color3.fromRGB(255, 210, 60)
		elseif rank == 2 then Color3.fromRGB(210, 215, 225)
		elseif rank == 3 then Color3.fromRGB(230, 150, 90)
		else Color3.fromRGB(170, 175, 185)
	make("TextLabel", {
		Position = UDim2.fromOffset(8, 3), Size = UDim2.fromOffset(26, ROW_H - 6), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne,
		Text = if rank then "#" .. rank else "", TextScaled = true, TextColor3 = rankColor, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	make("TextLabel", {
		Position = UDim2.fromOffset(38, 3), Size = UDim2.new(0.55, -38, 1, -6), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		Text = e.name, TextScaled = true, TextColor3 = if mine then ME else Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 3), Size = UDim2.new(0.45, -10, 1, -6), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, Text = Format.cash(e.score), TextScaled = true, TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
end

local function localEntry(p: Player): Entry
	return { id = p.UserId, name = p.DisplayName, score = (p:GetAttribute("Cash") :: number?) or 0 }
end

local friendCache: { [number]: boolean } = {}
local function isFriend(p: Player): boolean
	if p == player then
		return true
	end
	if friendCache[p.UserId] == nil then
		friendCache[p.UserId] = false
		task.spawn(function()
			local ok, yes = pcall(function()
				return player:IsFriendsWith(p.UserId)
			end)
			friendCache[p.UserId] = ok and yes
		end)
	end
	return friendCache[p.UserId]
end

local function globalEntries(): ({ Entry }, string)
	local store = ReplicatedStorage:FindFirstChild("KitLeaderboard") :: StringValue?
	if not store then
		return {}, "Loading..."
	end
	local status = store:GetAttribute("Status")
	if status == "unavailable" then
		return {}, "Global board shows up in the live game."
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(store.Value)
	end)
	if not ok or #data.entries == 0 then
		return {}, if status == "ok" then "No scores yet. Be the first!" else "Loading..."
	end
	return data.entries, ""
end

local function render()
	local entries: { Entry } = {}
	local status = ""
	if current == "Global" then
		entries, status = globalEntries()
	else
		for _, p in Players:GetPlayers() do
			if current == "Here" or isFriend(p) then
				table.insert(entries, localEntry(p))
			end
		end
		table.sort(entries, function(a, b)
			return a.score > b.score
		end)
		if current == "Friends" and #entries <= 1 then
			status = "Invite friends to see them here!"
		end
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local meShown = false
	for i, e in entries do
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, LayoutOrder = i }, list)
		fillRow(row, i, e)
		if e.id == player.UserId and i <= ROWS then
			meShown = true
		end
	end
	-- pin your own row under the list when it's off screen
	pinned.Visible = not meShown
	if not meShown then
		local rank: number? = nil
		for i, e in entries do
			if e.id == player.UserId then
				rank = i
			end
		end
		fillRow(pinned, rank, localEntry(player))
	end
	statusLabel.Text = status
	statusLabel.Visible = status ~= ""
	for name, b in tabButtons do
		local on = name == current
		b.TextColor3 = if on then Color3.new(1, 1, 1) else Color3.fromRGB(150, 155, 165);
		(b:FindFirstChild("Underline") :: Frame).Visible = on
	end
end

for name, b in tabButtons do
	b.Activated:Connect(function()
		current = name
		list.CanvasPosition = Vector2.zero
		render()
	end)
end

-- Live updates: cash changes, joins/leaves, new global top.
local function watch(p: Player)
	p:GetAttributeChangedSignal("Cash"):Connect(function()
		if current ~= "Global" then
			render()
		end
	end)
end
for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerAdded:Connect(function(p)
	watch(p)
	render()
end)
Players.PlayerRemoving:Connect(function()
	task.defer(render)
end)
task.spawn(function()
	local store = ReplicatedStorage:WaitForChild("KitLeaderboard", 30) :: StringValue?
	if store then
		store.Changed:Connect(render)
		store:GetAttributeChangedSignal("Status"):Connect(render)
	end
end)
-- friend lookups finish asynchronously
task.delay(3, render)
render()
