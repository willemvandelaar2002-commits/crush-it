--!strict
-- RemoteEvents. The server creates them in ReplicatedStorage.Remotes; clients
-- wait for them. One place to see every client <-> server message.
--
--   Crush       client -> server : "press now" (server checks cooldown / owner)
--   BuyUpgrade  client -> server : upgradeId ("Power" | "Speed" | "Value" | "Size")
--   Crushed     server -> all    : { plot, position, tier, value, owner } — effects only
--   Hit         server -> all    : { plot, position, tier } — a press stroke landed (effects)
--   Notice      server -> client : { text } — short message (e.g. not enough cash)
--   Upgraded    server -> all    : { plot, position, tier, owner } — bought a bigger press (effects)
--   Rebirthed   server -> all    : { plot, position, rebirths, owner, mult } — someone rebirthed (effects)
--   Collection  server -> client : collection table — on join and on every new book entry
--   SetAuto     client -> server : boolean — Auto Crush on/off (pass owners)
--   ShopNotice  server -> client : { kind = "offline", owned, seconds, cash } — offline earnings card
--   Purchased   server -> client : { id, text } — a Robux purchase went through (celebrate)
--   ShopOpened  client -> server : tab name — analytics only
--   Rewards     server -> client : { joined, claimed = {i,...}, cps, daily = { streak, canClaim, nextAt } }
--   ClaimReward client -> server : ("playtime", index) | ("daily")
--   ScrapPicked server -> client : { value, total } — you picked up scrap (sound/pop)
--   ScrapSold   server -> all    : { plot, position, amount, owner, auto } — cash collected from a smelter (effects)
--   ScrapDeposited server -> all : { plot, from, to, amount, owner } — scrap thrown into a smelter (effects)
--   (Hit / Crushed also carry `variant`: "Normal" | "Golden" | "Diamond"; BuyUpgrade also takes "Rebirth")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = { "Crush", "BuyUpgrade", "Crushed", "Hit", "Notice", "Upgraded", "Rebirthed", "Collection", "SetAuto", "ShopNotice", "Purchased", "ShopOpened", "Rewards", "ClaimReward", "ScrapPicked", "ScrapSold", "ScrapDeposited" }

local Net = {}

-- Collectible-crusher protocol; legacy names remain available for perks/rewards.
--   Travel      client -> server : "Hub" | "Plot" — top travel buttons (server teleports)
--   QuestState  server -> client : quest lists, tokens, shop; QuestAction client -> server : ("State") | ("Claim", period, id) | ("Buy", itemId)
--   OfflineAction client -> server : "Collect" — take the free offline cash (30 Oct)
--   PlotUpgraded server -> buyer : upgrade summary for the cutscene (only after a confirmed plot upgrade)
for _, name in { "CrusherAction", "CrusherState", "CrusherOpen", "Travel", "DailySpin", "QuestState", "QuestAction", "BoostAction", "PlotUpgraded", "OfferState", "OfferAction", "FactoryEventAction", "FactoryEventState", "ClaimIndexReward", "OfflineAction" } do table.insert(NAMES, name) end

local folder: Instance
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local e = Instance.new("RemoteEvent")
			e.Name = name
			e.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

function Net.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
