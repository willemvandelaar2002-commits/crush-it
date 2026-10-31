--!strict
-- Uploaded shop card artwork (31 Oct). IDs are the ones Roblox returned for
-- Willem's uploads (Crate Art Comparison pack, Candy Starter Card pack).
-- Presentation only: every card keeps a working fallback while these load.
local function id(n: string): string return "rbxassetid://" .. n end
return {
	FactoryCrate = {
		Chest = id("70891364292898"), -- FactoryCrate-512.png: the illustrated chest, transparent
		Backplate = id("77076356662252"), -- FactoryCrate-Backplate.png: blue/gold studded card, ~2.48:1
		ChestLarge = id("117905280807172"), -- FactoryCrate-Illustrated.png: same chest, high resolution (unused for now)
		Aspect = 2.48, -- backplate width / height
	},
	-- 31 Oct: Candy Starter Pack card (source PNG: assets/shop-card/CandyStarter-Background.png)
	CandyStarter = {
		Backplate = id("85230684065313"), -- CandyStarter-Background.png: pink/cream candy frame, ~2.48:1
		Aspect = 1974 / 797,
	},
}
