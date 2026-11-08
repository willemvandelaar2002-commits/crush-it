--!strict
-- 7 Nov (Willem: "lets add autoroll now as well for the event"; free for everyone,
-- stops on the rarities the player ticks, auto buy is paid).
-- AUTO ROLL runs here on the server, so it keeps going wherever you walk on your plot:
--   roll -> wait for the reveal (and a big-roll cinematic) -> look at the pedestals:
--   * none of the ticked rarities: roll again
--   * a ticked rarity: STOP (a notice says what), so you can buy it yourself
--   * with the AUTO BUY pass (Store "AutoBuy"): buy the best one and keep rolling;
--     if it can't (cash, full inventory) it stops and says why
-- Picks are rarity names (any crusher of it) and crusher ids (just that one, 7 Nov: Willem
-- "make the crushers individually clickable").
-- Only after the tutorial. State: attributes AutoRoll / AutoRollPicks ("Legendary,Titan")
-- / AutoBuy for the window (client/AutoRoll). Remote "AutoRoll"(on, picks, buy).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Net = require(RS.Shared.Net)
local C = require(RS.Shared.CrusherConfig)
local Store = require(RS.Shared.Store)

local M = {}
type State = { on: boolean, picks: { [string]: boolean }, buy: boolean, skip: boolean, token: number }

function M.start(api: any)
	-- api.action(p, name, args) -> ok, message; api.session(p) -> ctx; api.getData(p) -> d
	local states: { [Player]: State } = {}
	-- crushers you can target: the ones of the rarities in the window
	local pickable: { [string]: boolean } = {}
	for _, name in C.AutoRoll.Rarities do
		local r = C.rarity(name)
		for _, id in (if r then r.types else {}) do pickable[id] = true end
	end
	local remote = Net.event("AutoRoll")
	local notice = Net.event("Notice")

	local function mirror(p: Player, s: State)
		p:SetAttribute("AutoRoll", s.on)
		local list = {}
		for _, name in C.AutoRoll.Rarities do
			if s.picks[name] then table.insert(list, name) end
			local r = C.rarity(name)
			for _, id in (if r then r.types else {}) do if s.picks[id] then table.insert(list, id) end end
		end
		p:SetAttribute("AutoRollPicks", table.concat(list, ","))
		p:SetAttribute("AutoBuy", s.buy)
		p:SetAttribute("AutoRollSkip", s.skip)
	end
	local function stop(p: Player, s: State, text: string?)
		s.on = false s.token += 1
		mirror(p, s)
		if text then notice:FireClient(p, { text = text }) end
	end
	local function rankOf(name: string): number
		local r = C.rarity(name)
		return if r then r.rank else -1
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
			-- 8 Nov: SKIP ANIMATION makes this roll's reveal short (CrusherGame reads ctx.fastRoll)
			local rctx = api.session(p)
			if rctx then rctx.fastRoll = s.skip end
			local ok, message = api.action(p, "Roll", {})
			if rctx then rctx.fastRoll = nil end
			if not ok then
				if message == "Roll is cooling down." then task.wait(0.3) continue end
				stop(p, s, "Auto Roll stopped: " .. tostring(message)) break
			end
			if not waitReveal() then break end
			local ctx = api.session(p)
			if not ctx or not ctx.offers then continue end
			-- the rarest offer of a ticked rarity on the pedestals
			local bestSlot, bestRank, best = nil, -1, nil
			for slot, offer in ctx.offers do
				if offer and (s.picks[offer.rarity] or s.picks[offer.type]) then local rank = rankOf(offer.rarity) if rank > bestRank then bestSlot, bestRank, best = slot, rank, offer end end
			end
			if best then
				local def = C.typeById(best.type)
				local name = (if def then def.name else best.type) :: string
				if s.buy and Store.hasPass(p, "AutoBuy") then
					local bought, why = api.action(p, "Buy", { slot = bestSlot })
					if not bought then stop(p, s, "Auto Roll stopped: " .. best.rarity .. " " .. name .. " is waiting. " .. tostring(why)) break end
					notice:FireClient(p, { text = "Auto Buy: " .. best.rarity .. " " .. name .. "!" })
				else
					local article = if string.find(best.rarity, "^[AEIOU]") then "an " else "a "
					stop(p, s, "Auto Roll stopped: " .. article .. best.rarity .. " " .. name .. " is on your pedestal!") break
				end
			end
		end
	end

	remote.OnServerEvent:Connect(function(p: Player, on: any, picks: any, buy: any, skip: any)
		local s = states[p]
		if not s then return end
		if type(picks) == "table" then
			local set = {}
			local count = 0
			for _, name in picks do
				count += 1
				if count > 100 then break end
				if type(name) ~= "string" then continue end
				if table.find(C.AutoRoll.Rarities, name) or (C.typeById(name) and pickable[name]) then set[name] = true end
			end
			s.picks = set
		end
		s.buy = buy == true and Store.hasPass(p, "AutoBuy")
		if type(skip) == "boolean" then s.skip = skip end
		if on == true and not s.on then
			local d = api.getData(p)
			if not d or (d.crushers.tutorial or 1) <= #C.TutorialSteps then
				notice:FireClient(p, { text = "Finish the tutorial first." }) mirror(p, s) return
			end
			if next(s.picks) == nil then notice:FireClient(p, { text = "Tick a rarity or tap a crusher to stop on." }) mirror(p, s) return end
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
		local picks = {} for _, name in C.AutoRoll.Default do picks[name] = true end
		local s: State = { on = false, picks = picks, buy = false, skip = false, token = 0 }
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
