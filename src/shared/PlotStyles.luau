--!strict
-- 11 Nov: PLOT STYLES (docs/Systems/Plot styles.md). A style changes how your whole factory
-- looks (floor, trim, rim, lamps; Willem's kits per style later) and every style you own adds
-- a little cash forever (the rarer or dearer, the more). Kept through rebirths.
--   Earned: a full row (6 bays) of that rarity or better, equipped at the same time, once.
--           Counts from FACTORY III (where the STYLE board stands).
--   Gem:    bought with Gems at the STYLE board (Willem's special themes; none listed yet).
-- Palette colours recolour the Classic look until Willem's kit for that style is in.
local C = require(script.Parent.CrusherConfig)

local S = {}
-- Keep the board as a coming-soon preview until the styles screen is ready.
S.UiEnabled = false
local RGB = Color3.fromRGB

export type Style = {
	id: string, name: string, kind: string, -- "base" | "earned" | "gem"
	rarity: string?, price: number?, cash: number, -- cash: +share of income while owned
	palette: { floor: Color3, trim: Color3, rim: Color3, lamp: Color3, accent: Color3 }?,
}

S.List = {
	{ id = "Classic", name = "CLASSIC", kind = "base", cash = 0 },
	{ id = "Legendary", name = "LEGENDARY", kind = "earned", rarity = "Legendary", cash = 0.02,
		palette = { floor = RGB(40, 46, 96), trim = RGB(255, 200, 55), rim = RGB(255, 186, 40), lamp = RGB(255, 222, 120), accent = RGB(255, 236, 160) } },
	{ id = "Exotic", name = "EXOTIC", kind = "earned", rarity = "Exotic", cash = 0.03,
		palette = { floor = RGB(64, 38, 34), trim = RGB(255, 112, 55), rim = RGB(230, 80, 40), lamp = RGB(255, 150, 60), accent = RGB(255, 196, 80) } },
	{ id = "Secret", name = "SECRET", kind = "earned", rarity = "Secret", cash = 0.04,
		palette = { floor = RGB(38, 38, 52), trim = RGB(150, 150, 178), rim = RGB(90, 90, 112), lamp = RGB(176, 120, 255), accent = RGB(160, 100, 255) } },
	{ id = "Divine", name = "DIVINE", kind = "earned", rarity = "Divine", cash = 0.06,
		palette = { floor = RGB(222, 238, 250), trim = RGB(110, 225, 255), rim = RGB(245, 250, 255), lamp = RGB(190, 240, 255), accent = RGB(255, 226, 120) } },
	{ id = "Eternal", name = "ETERNAL", kind = "earned", rarity = "Eternal", cash = 0.08,
		palette = { floor = RGB(30, 22, 62), trim = RGB(205, 185, 255), rim = RGB(150, 120, 230), lamp = RGB(200, 170, 255), accent = RGB(120, 220, 255) } },
	-- Gem styles go here when Willem's designs are in, e.g.
	-- { id = "Candy", name = "CANDY", kind = "gem", price = 15000, cash = 0.02, palette = {...} },
	-- (proposed prices 15,000 / 30,000 / 60,000 Gems with +2% / +3% / +5% cash)
} :: { Style }
S.ById = {} :: { [string]: Style }
for _, st in S.List do S.ById[st.id] = st end
S.Default = "Classic"
S.BoardPlot = 2 -- the STYLE board stands (and earning counts) from FACTORY III

-- the save's styles, cleaned: owned ids (not Classic) and the active one
function S.clean(v: any): { owned: { [string]: boolean }, active: string }
	local owned = {}
	if type(v) == "table" and type(v.owned) == "table" then
		for id, on in v.owned do
			if on == true and type(id) == "string" and S.ById[id] and id ~= S.Default then owned[id] = true end
		end
	end
	local active = if type(v) == "table" and type(v.active) == "string" and (owned[v.active] or v.active == S.Default) then v.active else S.Default
	return { owned = owned, active = active }
end

function S.owns(styles: any, id: string): boolean
	return id == S.Default or (styles ~= nil and styles.owned ~= nil and styles.owned[id] == true)
end

-- +cash from every style you own (they add up)
function S.cashBonus(styles: any): number
	local b = 0
	for id in (styles and styles.owned or {}) do local st = S.ById[id] if st then b += st.cash end end
	return b
end
function S.cashMult(s: any): number return 1 + S.cashBonus(s and s.styles) end

-- does the factory count for earning (the board is there, or you already have a style)?
function S.open(s: any): boolean
	return (s.plotLevel or 0) >= S.BoardPlot or next((s.styles and s.styles.owned) or {}) ~= nil
end

-- the best rarity a full row reaches: every bay of the row equipped (once each), the row's
-- lowest rarity rank. rows: CrusherRows.snapshot(d)
function S.bestRowRank(d: any, rows: any): number
	local s = d.crushers
	local items = {} for _, it in s.owned do items[it.id] = it end
	local low: { [number]: number } = {} local count: { [number]: number } = {}
	for id, row in rows.byItem do
		local it = items[id] local r = it and C.rarity(it.rarity)
		if r then
			low[row.index] = math.min(low[row.index] or math.huge, r.rank)
			count[row.index] = (count[row.index] or 0) + 1
		end
	end
	local best = -1
	for i, n in count do
		local row = rows.rows[i]
		if row and n == row.capacity and row.unlocked == row.capacity then best = math.max(best, low[i]) end
	end
	return best
end

-- earned styles you qualify for now but don't own yet
function S.newlyEarned(d: any, rows: any): { string }
	local s = d.crushers
	if not S.open(s) then return {} end
	local best = S.bestRowRank(d, rows)
	local out = {}
	if best < 0 then return out end
	for _, st in S.List do
		local r = st.kind == "earned" and st.rarity and C.rarity(st.rarity)
		if r and best >= r.rank and not S.owns(s.styles, st.id) then table.insert(out, st.id) end
	end
	return out
end

return S
