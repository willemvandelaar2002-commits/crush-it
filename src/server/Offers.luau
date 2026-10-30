--!strict
-- Shop offers on the server: Starter Pack, Factory Crate and the Prism Mech
-- (Shared/OfferConfig, Shared/OfferRules).
--
-- Buying: the client asks (OfferAction "Prompt", productKey); the server checks
-- the product is configured, a one-time offer isn't owned yet, crates are
-- allowed for this player (PolicyService ArePaidRandomItemsRestricted) and no
-- other offer prompt is open, then prompts the purchase itself.
-- Granting happens ONLY in Shop's receipt handler (the one ProcessReceipt),
-- which calls Offers.grant and saves before answering PurchaseGranted.
--
-- Crates: the server picks the crusher when the receipt arrives, grants it at
-- once and stores a reveal. The client's opening animation only shows that
-- saved result; "Seen" deletes the reveal. Closing, skipping or leaving early
-- just means the same result is shown again next time: nothing rerolls.
--
--   OfferState  server -> client : { owned = {id=true}, reveals = {...}, crates = "allowed"|"restricted"|"checking" }
--   OfferAction client -> server : ("Prompt", productKey) | ("Seen", revealId) | ("State")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local MarketplaceService = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")

local Net = require(RS.Shared.Net)
local Store = require(RS.Shared.Store)
local O = require(RS.Shared.OfferConfig)
local R = require(RS.Shared.OfferRules)

local Offers = {}
local api: any = nil
local crateAccess: { [Player]: string } = {} -- "allowed" | "restricted" (nil while checking)
local prompting: { [Player]: number } = {} -- os.clock() of the open prompt
local PROMPT_LOCK = 30 -- seconds an unanswered prompt blocks another one
local rng = Random.new()

local state = Net.event("OfferState")
local notice = Net.event("Notice")

function Offers.handles(product: string): boolean
	return O.byProduct(product) ~= nil
end

local function mirror(p: Player, d: any)
	R.migrate(d)
	for _, offer in { O.StarterPack, O.Showroom } do
		p:SetAttribute("Offer_" .. offer.id, if R.owns(d, offer.id) then true else nil)
	end
end

function Offers.send(p: Player)
	local d = api and api.getData(p)
	if not d or not p.Parent then return end
	local offers = R.migrate(d)
	state:FireClient(p, { owned = table.clone(offers.owned), reveals = table.clone(offers.reveals), crates = crateAccess[p] or "checking" })
end

-- Called by Shop's receipt handler (never yields). Returns the celebration text.
function Offers.grant(p: Player, d: any, product: string, purchaseId: string): string
	local ok, result = R.fulfil(d, product, purchaseId, {
		giveCrusher = function(rarity: string, typeId: string) return api.giveCrusher(p, rarity, typeId, true) end,
		addCash = function(n: number) api.addCash(p, n) end,
		cashFor = function(seconds: number) return Store.cashFor(api.cashPerSecond(p), seconds) end,
		addBoost = function(id: string, minutes: number) require(script.Parent.Boosts).add(p, id, minutes) end,
		random = function() return rng:NextNumber() end,
	})
	if not ok then error("offer grant refused: " .. tostring(result)) end
	if result.repeatOnce then warn(`[Offers] {p.UserId} paid again for one-time {product}; contents granted again`) end
	mirror(p, d)
	prompting[p] = nil
	task.defer(Offers.send, p) -- after the grant is complete
	return result.text
end

local function checkPolicy(p: Player)
	for attempt = 1, 3 do
		local ok, info = pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(p) end)
		if not p.Parent then return end
		if ok and type(info) == "table" then
			if crateAccess[p] then return end -- already decided (Studio override)
			crateAccess[p] = if info.ArePaidRandomItemsRestricted == false then "allowed" else "restricted"
			p:SetAttribute("PaidRandomItems", crateAccess[p])
			Offers.send(p)
			return
		end
		task.wait(5 * attempt)
	end
	-- unknown: treat as restricted (crates stay blocked; guaranteed offers still work)
	crateAccess[p] = "restricted"
	p:SetAttribute("PaidRandomItems", "restricted")
	Offers.send(p)
end

local function prompt(p: Player, key: any)
	local d = api.getData(p)
	local entry = type(key) == "string" and O.byProduct(key)
	local product = type(key) == "string" and Store.productById(key)
	if not d or not entry or not product then return end
	if product.productId == 0 then notice:FireClient(p, { text = "Coming soon!" }) return end
	if entry.offer.once and R.owns(d, entry.offer.id) then notice:FireClient(p, { text = "You already own the " .. entry.offer.title .. "." }) return end
	if entry.kind == "crate" and crateAccess[p] ~= "allowed" then
		notice:FireClient(p, { text = "Crates aren't available for your account. Guaranteed offers still are." })
		return
	end
	if prompting[p] and os.clock() - prompting[p] < PROMPT_LOCK then return end
	prompting[p] = os.clock()
	MarketplaceService:PromptProductPurchase(p, product.productId)
end

function Offers.start(gameApi: any)
	api = gameApi
	Net.event("OfferAction").OnServerEvent:Connect(function(p: Player, action: any, arg: any)
		local d = api.getData(p)
		if not d then return end
		if action == "Prompt" then prompt(p, arg)
		elseif action == "Seen" then if R.seen(d, arg) then Offers.send(p) end
		elseif action == "State" then Offers.send(p) end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number)
		local p = Players:GetPlayerByUserId(userId)
		if p then prompting[p] = nil end
	end)
	local function join(p: Player)
		task.spawn(checkPolicy, p)
		local d = api.whenLoaded(p)
		if d and p.Parent then mirror(p, d) Offers.send(p) end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do task.spawn(join, p) end
	Players.PlayerRemoving:Connect(function(p) crateAccess[p] = nil prompting[p] = nil end)
	require(script.Parent.PrismShowroom).start()
	-- Studio only: ServerStorage.DevCrateAccess:Invoke(player, "allowed" | "restricted")
	-- overrides the PolicyService answer, to test both crate paths.
	if game:GetService("RunService"):IsStudio() then
		local dev = Instance.new("BindableFunction")
		dev.Name = "DevCrateAccess"
		dev.OnInvoke = function(p: Player, access: string)
			crateAccess[p] = if access == "allowed" then "allowed" else "restricted"
			p:SetAttribute("PaidRandomItems", crateAccess[p])
			Offers.send(p)
			return crateAccess[p]
		end
		dev.Parent = game:GetService("ServerStorage")
	end
end

return Offers
