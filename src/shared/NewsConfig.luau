--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 1
M.Title = "What's New"
M.Lines = {
	"SMASH! Tap the red button (or F) to fill the meter: FRENZY makes all your crushers 2x fast.",
	"Golden toys land at your bays: grab them for cash or a boost!",
	"New TURBO pump on your plot: multiply ALL your cash for a while.",
	"Your factory grows in 6 steps now, and the big price jumps are gone.",
	"Higher upgrade and level caps: there's always something to buy.",
	"New: CODES in the Rewards menu. Try CRUSHIT!",
}

return M
