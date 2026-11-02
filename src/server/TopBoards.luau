--!strict
-- Leaderboards on the Top Crushers boards in the hub (HubPlaza.Boards):
--   RICHEST       cash
--   MOST CRUSHED  toys crushed
--   PLAYTIME      total time played (d.playSeconds; was COLLECTION until 2 Nov)
-- Each is an all-time top list in its own OrderedDataStore (Kit/Leaderboard);
-- without DataStore access (Studio) it shows this server's players instead.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local Players = game:GetService("Players")
local Leaderboard = require(script.Parent.Kit.Leaderboard)

local TopBoards = {}

local function screens(id: string): { BasePart }
	local out = {}
	for _, s in CollectionService:GetTagged("TopBoard") do
		if s:GetAttribute("BoardId") == id then table.insert(out, s :: BasePart) end
	end
	return out
end

local function show(id: string, entries: { any }, format: (number) -> string)
	for _, screen in screens(id) do
		local gui = screen:FindFirstChild("Board")
		if not gui then continue end
		for i = 1, 99 do
			local row = gui:FindFirstChild("Row" .. i)
			if not row then break end
			local e = entries[i]
			row.PlayerName.Text = if e then e.name else "-"
			row.Score.Text = if e then format(e.score) else ""
		end
	end
end

function TopBoards.start(api: any)
	local function data(p: Player) return api.getData(p) end
	local boards = {
		{ id = "Cash", store = "TopCash_v1", score = function(p) local d = data(p) return d and d.cash or 0 end,
			format = function(n) return Format.cash(n) end },
		{ id = "Crushed", store = "TopCrushed_v1", score = function(p) local d = data(p) return d and d.crushed or 0 end,
			format = function(n) return Format.cash(math.floor(n + 0.5)):gsub("%$", "") end },
		{ id = "Playtime", store = "TopPlaytime_v1", score = function(p) local d = data(p) return d and d.playSeconds or 0 end,
			format = function(n)
				local m = math.floor(n / 60)
				return if m >= 60 then string.format("%dh %02dm", m // 60, m % 60) else m .. "m"
			end },
	}
	-- count play time on the save (every TICK seconds for everyone in the game)
	local TICK = 15
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, p in Players:GetPlayers() do
				local d = data(p)
				if d then d.playSeconds = (d.playSeconds or 0) + TICK end
			end
		end
	end)
	for _, b in boards do
		Leaderboard.start({ store = b.store, name = "Top" .. b.id, score = b.score, top = 8, every = 60,
			onUpdate = function(entries) show(b.id, entries, b.format) end })
	end
end

return TopBoards
