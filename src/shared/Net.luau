--!strict
-- RemoteEvents. The server creates them in ReplicatedStorage.Remotes; clients
-- wait for them. One place to see every client <-> server message.
--
--   Crush       client -> server : "press now" (server checks cooldown / owner)
--   BuyUpgrade  client -> server : upgradeId ("Power" | "Speed" | "Value" | "Size")
--   Crushed     server -> all    : { plot, position, tier, value, owner } — effects only
--   Hit         server -> all    : { plot, position, tier } — a press stroke landed (effects)
--   Notice      server -> client : { text } — short message (e.g. not enough cash)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = { "Crush", "BuyUpgrade", "Crushed", "Hit", "Notice" }

local Net = {}

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
