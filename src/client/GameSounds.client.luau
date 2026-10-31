--!strict
-- 31 Oct: game-feel sounds for the core loop (Willem: more sounds, also for
-- rolling). Local only, read from CrusherState changes:
--   roll -> dice + one click per pedestal; the best rarity in the roll plays
--   its own sting (RollReveal); collect -> coins; sell -> ka-ching (+ coins
--   for big sales); a new crusher / a bay change -> clunk.
-- UI clicks live in Style.feedback; the bin counter tick in ScrapCounter.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Config = require(RS.Shared.Config)
local Net = require(RS.Shared.Net)
local S = Config.Sounds

local me = Players.LocalPlayer
local cache: { [number]: Sound } = {}
local function play(id: number?, volume: number, pitch: number?)
	if not id then return end
	local base = cache[id]
	if not base then
		base = Instance.new("Sound") base.SoundId = "rbxassetid://" .. id base.Parent = SoundService
		cache[id] = base
	end
	local s = base:Clone() s.Volume = volume s.PlaybackSpeed = pitch or 1 s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	game:GetService("Debris"):AddItem(s, 8)
end
-- preload so the first roll/sell isn't silent
task.spawn(function()
	local list = {}
	for _, key in { "Sell", "Collect", "Roll", "RevealTick", "Equip" } do
		local id = (S :: any)[key] if id then local s = Instance.new("Sound") s.SoundId = "rbxassetid://" .. id s.Parent = SoundService cache[id] = s table.insert(list, s) end
	end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
end)

local function nearBin(): boolean
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(me:GetAttribute("Plot")))
	local bin = plot and plot:FindFirstChild("CollectStation")
	local char = me.Character local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (bin and bin:IsA("Model") and root) then return false end
	return (bin:GetPivot().Position - root.Position).Magnitude < 30
end
local last: any = nil
local function bayCount(bays: any): number
	local n = 0 for _ in (if type(bays) == "table" then bays else {}) do n += 1 end return n
end
Net.event("CrusherState").OnClientEvent:Connect(function(v)
	if type(v) ~= "table" then return end
	local prev = last
	last = { cash = v.cash or 0, carried = v.carried or 0, available = v.available or 0,
		items = if type(v.items) == "table" then #v.items else 0, bays = bayCount(v.bays) }
	if not prev then return end
	if v.rolled then
		play(S.Roll, 0.5, 1.1)
		for i = 1, math.clamp(tonumber(v.pedestals) or 1, 1, 8) do
			task.delay(0.35 + i * 0.12, function() play(S.RevealTick, 0.35, 1 + i * 0.06) end)
		end
		return
	end
	-- collecting the bin pays cash straight away (or fills your carried scrap)
	-- (Auto Collect empties the bin every couple of seconds: only a real,
	-- bigger collect next to your bin makes the sound)
	local drop = prev.available - last.available
	local rate = tonumber(v.rate) or 0
	if drop > 0 and drop > rate * 4 and nearBin() and (last.carried > prev.carried or last.cash > prev.cash) then
		-- (31 Oct: no coin sound on collect, Willem found it annoying)
		if last.cash > prev.cash then task.delay(0.1, function() play(S.Sell, 0.55) end) end
	end
	if last.carried < prev.carried and last.cash > prev.cash then
		play(S.Sell, 0.6)
	end
	if last.items > prev.items or last.bays ~= prev.bays then
		play(S.Equip, 0.3, 1.15)
	end
end)
