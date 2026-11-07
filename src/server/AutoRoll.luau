--!strict
-- 7 Nov (Willem: "lets add autoroll now as well for the event"; free for everyone,
-- stops on a rarity the player picks, auto buy is paid).
-- AUTO ROLL runs here on the server, so it keeps going wherever you walk on your plot:
--   roll -> wait for the reveal (and a big-roll cinematic) -> look at the pedestals:
--   * nothing at or above the chosen rarity: roll again
--   * something that rare: STOP (a notice says what), so you can buy it yourself
--   * with the AUTO BUY pass (Store "AutoBuy"): buy the best one and keep rolling;
--     if it can't (cash, full inventory) it stops and says why
-- Only after the tutorial. State: attributes AutoRoll / AutoRollMin / AutoBuy for the HUD
-- (client/AutoRoll). Remote "AutoRoll"(on, min, buy).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.CrusherConfig)
local Store = require(RS.Shared.Store)

local M = {}
type State = { on: boolean, min: string, buy: boolean, token: number }

function M.start(api: any)
	-- api.action(p, name, args) -> ok, message; api.session(p) -> ctx; api.getData(p) -> d
	local states: { [Player]: State } = {}
	local remote = Net.event("AutoRoll")
	local notice = Net.event("Notice")

	local function mirror(p: Player, s: State)
		p:SetAttribute("AutoRoll", s.on)
		p:SetAttribute("AutoRollMin", s.min)
		p:SetAttribute("AutoBuy", s.buy)
	end
	local function stop(p: Player, s: State, text: string?)
		s.on = false s.token += 1
		mirror(p, s)
		if text then notice:FireClient(p, { text = text }) end
	end
	local function rankOf(name: string): number
		local r = C.rarity(name)
		return if r then r.rank else math.huge
	end

	local function run(p: Player, s: State, token: number)
		local function alive(): boolean return s.on and s.token == token and p.Parent ~= nil end
		local function waitReveal(): boolean
			while alive() do
				local ctx = api.session(p)
				if not ctx then return false end
				if os.clock() >= (ctx.nextRoll or 0) + 0.15 then return true end
				task.wait(0.1)
			end
			return false
		end
		while alive() do
			if not waitReveal() then break end
			local ok, message = api.action(p, "Roll", {})
			if not ok then
				if message == "Roll is cooling down." then task.wait(0.3) continue end
				stop(p, s, "Auto Roll stopped: " .. tostring(message)) break
			end
			if not waitReveal() then break end
			local ctx = api.session(p)
			if not ctx or not ctx.offers then continue end
			-- the best offer on the pedestals
			local bestSlot, bestRank, best = nil, -1, nil
			for slot, offer in ctx.offers do
				if offer then local rank = rankOf(offer.rarity) if rank > bestRank then bestSlot, bestRank, best = slot, rank, offer end end
			end
			if best and bestRank >= rankOf(s.min) then
				local def = C.typeById(best.type)
				local name = (if def then def.name else best.type) :: string
				if s.buy and Store.hasPass(p, "AutoBuy") then
					local bought, why = api.action(p, "Buy", { slot = bestSlot })
					if not bought then stop(p, s, "Auto Roll stopped: " .. best.rarity .. " " .. name .. " is waiting. " .. tostring(why)) break end
					notice:FireClient(p, { text = "Auto Buy: " .. best.rarity .. " " .. name .. "!" })
				else
					stop(p, s, "Auto Roll stopped: a " .. best.rarity .. " " .. name .. " is on your pedestal!") break
				end
			end
		end
	end

	remote.OnServerEvent:Connect(function(p: Player, on: any, min: any, buy: any)
		local s = states[p]
		if not s then return end
		if type(min) == "string" and table.find(C.AutoRoll.Choices, min) then s.min = min end
		s.buy = buy == true and Store.hasPass(p, "AutoBuy")
		if on == true and not s.on then
			local d = api.getData(p)
			if not d or (d.crushers.tutorial or 1) <= #C.TutorialSteps then
				notice:FireClient(p, { text = "Finish the tutorial first." }) mirror(p, s) return
			end
			s.on = true s.token += 1
			mirror(p, s)
			task.spawn(run, p, s, s.token)
		elseif on == false and s.on then
			stop(p, s, nil)
		else
			mirror(p, s)
		end
	end)
	local function join(p: Player)
		local s: State = { on = false, min = C.AutoRoll.Default, buy = false, token = 0 }
		states[p] = s
		mirror(p, s)
		-- losing the pass (refund) turns auto buy off
		p:GetAttributeChangedSignal(Store.passAttr("AutoBuy")):Connect(function()
			if not Store.hasPass(p, "AutoBuy") and s.buy then s.buy = false mirror(p, s) end
		end)
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do join(p) end
	Players.PlayerRemoving:Connect(function(p) local s = states[p] if s then s.on = false s.token += 1 end states[p] = nil end)
end

return M
