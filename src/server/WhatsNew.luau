--!strict
-- 2 Nov: sends the What's New panel (Shared/NewsConfig) once per version.
-- Players still in the tutorial (or brand new) are marked as having seen it,
-- so the panel never interrupts a first session.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Net = require(RS.Shared.Net)
local News = require(RS.Shared.NewsConfig)
local C = require(RS.Shared.Config).Crushers

local M = {}

function M.start(api: any)
	local event = Net.event("WhatsNew")
	local function check(p: Player)
		local d = api.whenLoaded(p)
		if not d or not p.Parent then return end
		if (d.newsSeen or 0) >= News.Version then return end
		if (d.crushers and d.crushers.tutorial or 1) <= #C.TutorialSteps then
			d.newsSeen = News.Version -- new players: nothing to catch up on
			return
		end
		task.wait(8) -- let the join settle (the client also waits for open menus)
		if p.Parent then event:FireClient(p, { version = News.Version, title = News.Title, lines = News.Lines }) end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(check, p) end)
	for _, p in Players:GetPlayers() do task.spawn(check, p) end
	Net.event("NewsSeen").OnServerEvent:Connect(function(p: Player, version: any)
		local d = api.getData(p)
		if d and version == News.Version then d.newsSeen = News.Version end
	end)
end

return M
