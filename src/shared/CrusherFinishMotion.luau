--!strict
-- Cosmetic-only deterministic motion and distance budgets. No production logic.
local M = { Detailed = 12, Quiet = 24, Near = 85, Far = 140, Lights = 3, Scan = 0.3, Tick = 1 / 12, Glows = 10 }
function M.sample(finish: string, now: number, seed: number)
	local t = now + seed
	local wave = math.sin(t * 2.1)
	local flash = math.max(0, math.sin(t * 9.3)) ^ 12
	return {
		pulse = 0.5 + wave * 0.5,
		glint = math.max(0, math.sin(t * 1.8)) ^ 5,
		arc = finish == "Charged" and (math.sin(t * 11) + math.sin(t * 17.3)) > -1.1, -- mostly on, flickering
		curve = math.sin(t * 24) * 0.18,
		brightness = finish == "Fire" and 0.6 + 0.25 * wave + 0.15 * flash or 0.5 + 0.2 * wave,
		spin = t * 0.45,
	}
end
function M.level(distance: number, rank: number): number
	if distance > M.Far or rank > M.Quiet then return 0 end
	if distance <= M.Near and rank <= M.Detailed then return 2 end
	return 1
end
return M
