--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 1
M.Title = "What's New"
M.Lines = {
	"16 GOALS after the tutorial, with prizes up to a free Legendary crusher!",
	"Bays 3 to 6 now cost $50 / $80 / $120 / $180.",
	"Factory III is much cheaper: about $452M (was $2.21B).",
	"The Lucky pass and the 2x Luck boost now stack (4x luck with both).",
	"The Index shows YOUR odds, with all your luck included.",
	"New: CODES in the Rewards menu. Try CRUSHIT!",
}

return M
