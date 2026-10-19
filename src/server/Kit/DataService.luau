--!strict
-- Kit: player save data. Reusable across games — the game passes in its own
-- default data and DataStore name; nothing here knows about Crush It.
--
-- Same patterns as WarChest's PlayerDataService, kept small:
--   * Session lock: the save holds { jobId, lockedAt }. Another server that
--     loads a locked profile waits (up to LOCK_WAIT seconds) for the owner's
--     final save, then takes over a stale lock. No two servers ever write
--     the same profile at once, so no duplication or rollback.
--   * Retries with backoff on every DataStore call.
--   * Autosave every AUTOSAVE seconds (also refreshes the lock), save on
--     leave, and save everyone on shutdown (BindToClose).
--   * Studio without API access: an in-memory mock store, so Play just works.
--
-- API:
--   DataService.start(storeName, defaults, sanitize?)
--   DataService.get(player) -> data table (nil until loaded)
--   DataService.whenLoaded(player) -> data (yields)
--   DataService.Loaded (BindableEvent.Event: player, data)
--   DataService.saveNow(player) -> boolean

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

local AUTOSAVE = 60
local LOCK_STALE = 150 -- a lock not refreshed for this long belongs to a dead server
local LOCK_WAIT = 30
local RETRIES = 4

type Store = { UpdateAsync: (any, string, (any) -> any) -> any, GetAsync: (any, string) -> any }

local store: Store
local defaults: { [string]: any } = {}
local sanitizeFn: ((any) -> any)? = nil
local profiles: { [Player]: { data: any, loaded: boolean, canSave: boolean } } = {}
local loadedEvent = Instance.new("BindableEvent")
DataService.Loaded = loadedEvent.Event

local function deepCopy(t: any): any
	if typeof(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = deepCopy(v)
	end
	return out
end

-- Fills in any key missing from `data` with the default (new fields added to
-- the game later just appear on old saves).
local function reconcile(data: any, template: any)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif typeof(v) == "table" and typeof(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

local function mockStore(): Store
	local mem: { [string]: any } = {}
	return {
		UpdateAsync = function(_, key, fn)
			local nextValue = fn(deepCopy(mem[key]))
			if nextValue ~= nil then
				mem[key] = deepCopy(nextValue)
			end
			return nextValue
		end,
		GetAsync = function(_, key)
			return deepCopy(mem[key])
		end,
	} :: any
end

local function resolveStore(name: string): Store
	local real
	local ok = pcall(function()
		real = DataStoreService:GetDataStore(name)
		if RunService:IsStudio() then
			real:GetAsync("__access_check")
		end
	end)
	if not ok then
		if RunService:IsStudio() then
			warn("[DataService] No DataStore access in Studio (Game Settings > Security > Enable Studio Access to API Services). Using an in-memory store; nothing is saved.")
			return mockStore()
		end
		error("[DataService] DataStore unavailable")
	end
	return real :: any
end

local function retry<T>(fn: () -> T): (boolean, T?)
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`[DataService] attempt {attempt} failed: {result}`)
		task.wait(1.5 * attempt)
	end
	return false, nil
end

local function key(player: Player): string
	return "player_" .. player.UserId
end

local function load(player: Player)
	local profile = { data = nil :: any, loaded = false, canSave = false }
	profiles[player] = profile
	local deadline = os.clock() + LOCK_WAIT
	local loadedData = nil
	while player.Parent do
		local blocked = false
		local ok = retry(function()
			return store:UpdateAsync(key(player), function(old)
				old = old or {}
				local lock = old._lock
				if lock and lock.jobId ~= game.JobId and os.time() - (lock.lockedAt or 0) < LOCK_STALE and os.clock() < deadline then
					blocked = true
					return nil -- another live server still owns it: don't write, wait and retry
				end
				blocked = false
				old._lock = { jobId = game.JobId, lockedAt = os.time() }
				loadedData = old
				return old
			end)
		end)
		if not ok then
			-- Store down: play on defaults but never save over the real profile.
			warn(`[DataService] could not load {player.Name}; this session will not save`)
			loadedData = nil
			break
		end
		if not blocked then
			profile.canSave = true
			break
		end
		task.wait(5)
	end
	if not player.Parent then
		profiles[player] = nil
		return
	end
	local data = loadedData or {}
	data._lock = nil
	reconcile(data, defaults)
	if sanitizeFn then
		data = (sanitizeFn :: any)(data)
	end
	profile.data = data
	profile.loaded = true
	loadedEvent:Fire(player, data)
end

local function save(player: Player, release: boolean): boolean
	local profile = profiles[player]
	if not profile or not profile.loaded or not profile.canSave then
		return false
	end
	local snapshot = deepCopy(profile.data)
	local stolen = false
	local ok = retry(function()
		return store:UpdateAsync(key(player), function(old)
			old = old or {}
			local lock = old._lock
			if lock and lock.jobId ~= game.JobId then
				stolen = true
				return nil -- another server took over: never overwrite its data
			end
			snapshot._lock = if release then nil else { jobId = game.JobId, lockedAt = os.time() }
			return snapshot
		end)
	end)
	if stolen then
		profile.canSave = false
		warn(`[DataService] {player.Name}'s profile is owned by another server; stopped saving here`)
	end
	return ok and not stolen
end

function DataService.get(player: Player): any
	local p = profiles[player]
	return if p and p.loaded then p.data else nil
end

function DataService.whenLoaded(player: Player): any
	while player.Parent do
		local data = DataService.get(player)
		if data then
			return data
		end
		task.wait(0.1)
	end
	return nil
end

function DataService.saveNow(player: Player): boolean
	return save(player, false)
end

function DataService.start(storeName: string, template: { [string]: any }, sanitize: ((any) -> any)?)
	defaults = template
	sanitizeFn = sanitize
	store = resolveStore(storeName)
	Players.PlayerAdded:Connect(load)
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		profiles[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for player in profiles do
				task.spawn(save, player, false)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
