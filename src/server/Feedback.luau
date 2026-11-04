--!strict
-- 5 Nov: the one-tap survey (Shared/FeedbackConfig). Only fixed answers are accepted
-- (no typed text: nothing to filter or moderate); each is logged once per session as
-- a custom analytics event. d.feedbackAsked = the survey popped up once for this save.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local F = require(RS.Shared.FeedbackConfig)
local Analytics = require(script.Parent.Kit.Analytics)

local M = {}

function M.start(api: any)
	local done: { [Player]: { [string]: boolean } } = {}
	Net.event("Feedback").OnServerEvent:Connect(function(p: Player, kind: any, value: any)
		local d = api.getData(p)
		if not d then return end
		local seen = done[p] or {}
		done[p] = seen
		if kind == "Shown" then
			d.feedbackAsked = true
			p:SetAttribute("FeedbackAsked", true)
		elseif kind == "Rating" and not seen.rating then
			for _, r in F.Ratings do
				if r.value == value then
					seen.rating = true
					Analytics.custom(p, "FeedbackRating", r.value, r.label)
				end
			end
		elseif kind == "Wish" and type(value) == "string" and not seen[value] then
			for _, w in F.Wishes do
				if w.key == value then
					seen[value] = true
					Analytics.custom(p, "FeedbackWish", 1, w.key)
				end
			end
		end
	end)
	local function join(p: Player)
		local d = api.whenLoaded(p)
		if d and p.Parent then p:SetAttribute("FeedbackAsked", d.feedbackAsked == true) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end
	Players.PlayerRemoving:Connect(function(p) done[p] = nil end)
end

return M
