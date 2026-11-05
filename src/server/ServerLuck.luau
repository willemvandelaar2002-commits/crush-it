--!strict
-- 4 Nov (monetization round 2; vault: Genre Playbook RNG "a server-wide luck boost:
-- everyone in the server gets 2x luck, the buyer is announced - social visibility
-- sells"): the Server Luck product. Everyone in THIS server gets x2 luck on rolls;
-- buying again adds time (capped). Kept in workspace attributes so every script and
-- every client can read it: ServerLuckEnds (server time) and ServerLuckBy (name).
-- CrusherGame's perks() multiplies luck by ServerLuck.mult().
local RS = game:GetService("ReplicatedStorage")
local Store = require(RS.Shared.Store)
local Net = require(RS.Shared.Net)

local M = {}

local function now(): number return workspace:GetServerTimeNow() end

function M.mult(): number
	local ends = (workspace:GetAttribute("ServerLuckEnds") :: number?) or 0
	local after = (workspace:GetAttribute("AftershockEnds") :: number?) or 0
	return (if ends > now() then Store.ServerLuck.Mult else 1) * (if after > now() then ((workspace:GetAttribute("AftershockLuck") :: number?) or 1) else 1)
end

-- 5 Nov: someone rolled a Divine: everyone here gets extra luck for a short while
-- (C.BigRoll.Divine). Rolling another one restarts the timer; it does not stack.
function M.aftershock(roller: Player, mult: number, seconds: number)
	workspace:SetAttribute("AftershockLuck", mult)
	workspace:SetAttribute("AftershockEnds", now() + seconds)
	workspace:SetAttribute("AftershockBy", roller.DisplayName)
end

function M.add(buyer: Player)
	local t = now()
	local start = math.max(t, (workspace:GetAttribute("ServerLuckEnds") :: number?) or 0)
	workspace:SetAttribute("ServerLuckEnds", math.min(start + Store.ServerLuck.Minutes * 60, t + Store.ServerLuck.MaxMinutes * 60))
	workspace:SetAttribute("ServerLuckBy", buyer.DisplayName)
	Net.event("RarePull"):FireAllClients({ text = buyer.DisplayName .. " bought SERVER LUCK: 2x luck for EVERYONE for " .. Store.ServerLuck.Minutes .. " minutes!",
		userId = buyer.UserId, color = Color3.fromRGB(90, 230, 100) })
end

return M
