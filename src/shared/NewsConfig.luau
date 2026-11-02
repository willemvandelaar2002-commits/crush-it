--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 3
M.Title = "What's New"
M.Lines = {
	"REBIRTH from Factory IV: start over with all your crushers and earn +50% income forever.",
	"The Coating Lab now opens with Factory II.",
	"SMASH! Tap the red button (or F): FRENZY makes all your crushers 2x fast.",
	"Golden toys land at your bays, and the TURBO pump multiplies ALL your cash.",
	"Higher caps, smaller price jumps, and CODES in the Rewards menu. Try CRUSHIT!",
}

return M
