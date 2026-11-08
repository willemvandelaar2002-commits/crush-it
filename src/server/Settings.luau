--!strict
-- 6 Nov: player settings (Shared/SettingsConfig) saved in the profile as d.settings and
-- mirrored to attributes "Set_<key>" for the client. Only known keys and allowed values
-- are accepted; anything else is ignored.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local S = require(RS.Shared.SettingsConfig)

local M = {}

local function valid(key: string, value: any): boolean
	local default = S.Defaults[key]
	if default == nil then return false end
	if key == "Music" or key == "Sounds" then return table.find(S.Levels, value) ~= nil end
	if key == "Effects" then return table.find(S.Effects, value) ~= nil end
	return type(value) == type(default)
end

local function settings(d: any): { [string]: any }
	if type(d.settings) ~= "table" then d.settings = {} end
	for k, v in d.settings do
		if not valid(k, v) then d.settings[k] = nil end
	end
	return d.settings
end

local function mirror(p: Player, d: any)
	local s = settings(d)
	for key, default in S.Defaults do
		local v = s[key]
		if v == nil then v = default end
		p:SetAttribute("Set_" .. key, v)
	end
end

function M.start(api: any)
	local last: { [Player]: number } = {}
	Net.event("Settings").OnServerEvent:Connect(function(p: Player, key: any, value: any)
		if type(key) ~= "string" or not valid(key, value) then return end
		local d = api.getData(p)
		if not d then return end
		-- (a tap per row is plenty; this only stops a flood)
		if os.clock() - (last[p] or 0) < 0.1 then return end
		last[p] = os.clock()
		settings(d)[key] = if value == S.Defaults[key] then nil else value
		p:SetAttribute("Set_" .. key, value)
	end)
	local function join(p: Player)
		local d = api.whenLoaded(p)
		if d and p.Parent then mirror(p, d) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

return M
