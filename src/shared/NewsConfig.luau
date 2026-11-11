--!strict
-- 2 Nov (vault: Patch Notes and Player Communication): the in-game "What's New"
-- panel. Shown once per Version to returning players (never to brand-new players
-- or during the tutorial), never over another menu. Bump Version and rewrite
-- the lines with every update; numbers stated plainly.
local M = {}

M.Version = 6 -- 11 Nov: the big patch (Gem Mine, Exotic + Eternal, Auto Roll, Mystery Crate, plot styles)
M.Title = "BIG UPDATE!"
M.Lines = {
	"THE GEM MINE: a whole new world! Collect Gems, buy upgrades and open the GEM CHEST with keys. Opens at Rebirth 1 + Factory IV.",
	"2 NEW RARITIES: Exotic and ETERNAL. 12 new crushers to find!",
	"AUTO ROLL: press AUTO at the roll machine, pick your targets and let it roll.",
	"MYSTERY CRATE: a free crusher every day, up to SECRET!",
	"LUCKY WEEKEND crushers: 3 limited crushers, only on Saturday and Sunday.",
	"PLOT STYLES from Factory III: new looks for your factory with a cash bonus.",
	"Factory III and IV are cheaper, new Mythic models, SETTINGS menu, and lots of fixes.",
}

return M
