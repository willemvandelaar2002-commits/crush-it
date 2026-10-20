--!strict
-- Every uploaded icon (Willem's account, 512x512 PNGs, 20 Oct).
-- Swap an icon by changing its id here; nothing else needs to change.
-- These ids don't load as plain rbxassetid:// in an ImageLabel (likely decal
-- ids), but Roblox's thumbnail URL works for any asset type, so we use that.

local function id(n: string): string
	return "rbxthumb://type=Asset&id=" .. n .. "&w=420&h=420"
end

return {
	Book = id("139326189029321"),
	Shop = id("108694086790169"),
	Rewards = id("130608162750164"),
	Cash = id("105818491449765"),
	Power = id("133827925413773"),
	Speed = id("125971454243604"),
	Value = id("80257410856032"),
	Press = id("102684655405763"),
	Rebirth = id("118805133054994"), -- WarChest's rebirth icon: 119986205257706
	AutoCrush = id("105926085988328"),
	DoubleCash = id("124084693349196"),
	Offline = id("126844943827021"),
	Lucky = id("136809184380141"),
	Golden = id("77768517736981"),
	Trophy = id("139626264780814"),
}
