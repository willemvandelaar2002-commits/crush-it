--!strict
-- Uploaded shop card artwork (31 Oct). IDs are the ones Roblox returned for
-- Willem's uploads (Crate Art Comparison, Candy Starter Card, Prism Mech Card and Cash Pack Icons packs).
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
	-- 31 Oct: Prism Mech showroom card (source PNG: assets/shop-card/PrismMech-Background.png)
	PrismMech = {
		Backplate = id("102747752191257"), -- PrismMech-Background.png: violet + gold frame, corner crystals, ~2.48:1
		Aspect = 1974 / 797,
	},
	-- 31 Oct: one icon per cash pack, by Store product id (sources: assets/shop-card/cash/).
	-- Only the cash-pack cards use these; Icons.Cash stays everywhere else.
	CashPacks = {
		CashSmall = id("91590888539709"), -- CashPile.png: low pile
		CashMedium = id("140435524782279"), -- CashStack.png: tall pyramid of bundles
		CashLarge = id("72188129858951"), -- CashVault.png: open gold/emerald vault
	},
}
