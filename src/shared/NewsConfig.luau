--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 5
M.Title = "What's New"
M.Lines = {
	"LUCKY WEEKEND: every Saturday and Sunday, 2x luck on rolls for everyone!",
	"Daily rewards: see tomorrow's prize right after you claim today's.",
	"After Factory II, small goals guide you all the way to your first REBIRTH.",
	"NEW CODES in Rewards > CODES: CRUSHIT, LUCKYROLL, REBIRTH, FREECRUSHER and PHONEUPDATE!",
	"REBIRTH from Factory IV: keep all your crushers, x1.5 cash and +25% luck each time.",
	"Bad luck? After 200 rolls without one, a Legendary is guaranteed.",
}

return M
