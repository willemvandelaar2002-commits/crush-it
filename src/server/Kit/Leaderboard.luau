--!strict
-- Kit: global leaderboard (top N of all time) in an OrderedDataStore.
-- Reusable: the game passes a store name and how to read a player's score.
--
--   Leaderboard.start({ store = "CashBoard_v1", score = function(player) -> number, top = 50, every = 120 })
--
-- * Every `every` seconds (and when a player leaves) each player's score is
--   written if it changed. Scores can be huge, so they're stored as
--   log10(score + 1) * 1e6 (an integer); clients decode with Leaderboard.decode.
-- * Every `every` seconds the top N is read and published as JSON in
--   ReplicatedStorage.KitLeaderboard (a StringValue):
--     { updated = os.time(), entries = { { id, name, score }, ... } }
--   Its "Status" attribute is "ok" or "unavailable" (e.g. Studio without API access).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leaderboard = {}

local SCALE = 1e6

function Leaderboard.encode(score: number): number
	return math.floor(math.log10(math.max(score, 0) + 1) * SCALE)
end

function Leaderboard.decode(value: number): number
	return 10 ^ (value / SCALE) - 1
end

-- name: the StringValue it publishes to (default "KitLeaderboard"); onUpdate gets
-- the entries after every read. Without DataStore access (Studio) it falls back
-- to the players in this server so the boards still show something.
export type Options = { store: string, score: (Player) -> number, top: number?, every: number?, name: string?,
	onUpdate: ((entries: { any }, live: boolean) -> ())? }

function Leaderboard.start(opts: Options)
	local top = opts.top or 50
	local every = opts.every or 120
	local name = opts.name or "KitLeaderboard"
	local out = ReplicatedStorage:FindFirstChild(name) :: StringValue? or Instance.new("StringValue")
	assert(out)
	out.Name = name
	out.Value = HttpService:JSONEncode({ updated = 0, entries = {} })
	out:SetAttribute("Status", "loading")
	out.Parent = ReplicatedStorage

	-- this server's players, best first (used when the DataStore can't be read)
	local function localEntries()
		local entries = {}
		for _, p in Players:GetPlayers() do
			table.insert(entries, { id = p.UserId, name = p.DisplayName, score = opts.score(p) })
		end
		table.sort(entries, function(a, b) return a.score > b.score end)
		while #entries > top do table.remove(entries) end
		return entries
	end
	local function fallback()
		out:SetAttribute("Status", "unavailable")
		if opts.onUpdate then opts.onUpdate(localEntries(), false) end
	end

	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(opts.store)
	end)
	if not ok then
		task.spawn(function()
			while true do fallback() task.wait(math.min(every, 30)) end
		end)
		return
	end

	local written: { [number]: number } = {}
	local names: { [number]: string } = {}

	local function write(player: Player)
		local value = Leaderboard.encode(opts.score(player))
		if value <= 0 or written[player.UserId] == value then
			return
		end
		local success = pcall(function()
			store:SetAsync(tostring(player.UserId), value)
		end)
		if success then
			written[player.UserId] = value
		end
	end

	local function nameOf(id: number): string
		if names[id] then
			return names[id]
		end
		local p = Players:GetPlayerByUserId(id)
		if p then
			names[id] = p.DisplayName
			return p.DisplayName
		end
		local okName, name = pcall(function()
			return Players:GetNameFromUserIdAsync(id)
		end)
		names[id] = if okName then name else "Player"
		return names[id]
	end

	local function read()
		local success, pages = pcall(function()
			return store:GetSortedAsync(false, top)
		end)
		if not success then
			fallback()
			return
		end
		local entries = {}
		for _, item in pages:GetCurrentPage() do
			local id = tonumber(item.key)
			if id then
				table.insert(entries, { id = id, name = nameOf(id), score = Leaderboard.decode(item.value) })
			end
		end
		out.Value = HttpService:JSONEncode({ updated = os.time(), entries = entries })
		out:SetAttribute("Status", "ok")
		if opts.onUpdate then opts.onUpdate(entries, true) end
	end

	Players.PlayerRemoving:Connect(function(player)
		write(player)
		written[player.UserId] = nil
	end)

	task.spawn(function()
		task.wait(10) -- let saves load first
		while true do
			for _, player in Players:GetPlayers() do
				write(player)
			end
			read()
			task.wait(every)
		end
	end)
end

return Leaderboard
