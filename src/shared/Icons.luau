--!strict
-- Every uploaded icon (Willem's account, 512x512 PNGs, 20 Oct).
-- These are the Image ids behind the uploaded decals, so they load for every
-- player. Don't go back to decal ids through rbxthumb://: a private decal's
-- thumbnail only shows to its owner, so other players saw blank icons.
-- To swap an icon: upload the PNG, open the decal in Studio (InsertService:
-- LoadAsset(decalId)) and copy its Decal.Texture id here.

local function id(n: string): string
	return "rbxassetid://" .. n
end

return {
	Book = id("81331205840113"), -- decal 139326189029321
	Shop = id("85820261067278"), -- decal 108694086790169
	Rewards = id("129215110267001"), -- decal 130608162750164
	Cash = id("98244872810376"), -- decal 105818491449765
	Power = id("138851581750358"), -- decal 133827925413773
	Speed = id("103295262884876"), -- decal 125971454243604
	Value = id("129681169460956"), -- decal 80257410856032
	Press = id("123814414980756"), -- decal 102684655405763
	Rebirth = id("90818789034514"), -- decal 118805133054994
	AutoCrush = id("79330874809591"), -- decal 105926085988328
	DoubleCash = id("97833325663750"), -- decal 124084693349196
	Offline = id("104060508227706"), -- decal 126844943827021
	Lucky = id("138780104233345"), -- decal 136809184380141
	Golden = id("85828350065088"), -- decal 77768517736981
	Trophy = id("101098329602259"), -- decal 139626264780814
	-- Coating Lab / Fusion Machine art (Willem's PNGs in docs/art/icons, 27 Oct).
	-- An empty id makes the screen show an emoji stand-in.
	FactoryCrate = id("134946124538197"), -- the Factory Crate in the shop (29 Oct)
	CoatingLab = id("89003452709321"), -- spray can (Brasslight Studio image)
	FusionMachine = id("95171948221071"), -- fusion canister (Brasslight Studio image)
	FinishPolished = id("90505902880419"), -- silver droplet (Brasslight Studio image)
	FinishFrost = id("132410562417007"), -- ice crystal (Brasslight Studio image)
	FinishFire = id("107601696310568"), -- flame (Brasslight Studio image)
	FinishCharged = id("133963983524832"), -- lightning bolt (Brasslight Studio image)
}
