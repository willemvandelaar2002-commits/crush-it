--!strict
-- Leaderboards on the Top Crushers boards in the hub (HubPlaza.Boards):
--   RICHEST       cash
--   MOST CRUSHED  toys crushed
--   COLLECTION    different crusher types owned (out of all of them)
-- Each is an all-time top list in its own OrderedDataStore (Kit/Leaderboard);
-- without DataStore access (Studio) it shows this server's players instead.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local C = require(ReplicatedStorage.Shared.CrusherConfig)
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
		{ id = "Collection", store = "TopCollection_v1", score = function(p)
			local d = data(p) if not d then return 0 end
			local seen, n = {}, 0
			for _, item in d.crushers.owned do if not seen[item.type] then seen[item.type] = true n += 1 end end
			return n
		end, format = function(n) return math.floor(n + 0.5) .. " / " .. #C.Types end },
	}
	for _, b in boards do
		Leaderboard.start({ store = b.store, name = "Top" .. b.id, score = b.score, top = 8, every = 60,
			onUpdate = function(entries) show(b.id, entries, b.format) end })
	end
end

return TopBoards
