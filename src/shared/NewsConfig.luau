--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 4
M.Title = "What's New"
M.Lines = {
	"NEW CODES in Rewards > CODES: CRUSHIT, LUCKYROLL, REBIRTH, FREECRUSHER and PHONEUPDATE!",
	"REBIRTH from Factory IV: keep all your crushers, x1.5 cash and +25% luck each time.",
	"FILL ROW: tap the board at a row's sign to fill it with one rarity (row bonus!).",
	"x10 buttons on the factory upgrades, and REBUILD after a rebirth.",
	"Bad luck? After 200 rolls without one, a Legendary is guaranteed.",
	"Better on phones: bigger buttons and a LEVEL UP button at your bay.",
}

return M
