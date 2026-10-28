--!strict
-- Pure timeline shared by the renderer and offline checks. No game/economy dependencies.
local Sequence = {}
Sequence.CoatingDuration = 4.4
Sequence.FusionDuration = 5.2

local function clamp(x: number): number
	return math.clamp(x, 0, 1)
end

local function smooth(x: number): number
	x = clamp(x)
	return x * x * (3 - 2 * x)
end

function Sequence.sample(kind: string, normalizedTime: number)
	local t = clamp(normalizedTime)
	local fusion = kind == "Fusion"
	local gather = smooth((t - 0.12) / 0.45)
	local reveal = smooth((t - 0.66) / 0.15)
	local finish = smooth((t - 0.87) / 0.13)
	local spray = smooth((t - 0.12) / 0.07) * (1 - smooth((t - 0.58) / 0.08))
	local charge = smooth((t - 0.08) / 0.46) * (1 - smooth((t - 0.65) / 0.10))
	local flash = math.max(0, 1 - math.abs(t - 0.66) / 0.065)
	local ring = smooth(t / 0.08) * (1 - finish)
	local burst = clamp((t - 0.66) / 0.26)
	local burstAlpha = t >= 0.66 and (1 - burst) * (1 - finish) or 0
	local phase
	if t < 0.12 then phase = "Prepare"
	elseif t < 0.60 then phase = fusion and "Combine" or "Coat"
	elseif t < 0.70 then phase = "Impact"
	elseif t < 0.87 then phase = "Reveal"
	else phase = "Settle" end
	return {
		phase = phase, t = t, gather = gather, reveal = reveal, finish = finish,
		spray = spray, charge = charge, flash = flash, ring = ring,
		burst = burst, burstAlpha = burstAlpha,
		inputAlpha = fusion and (1 - smooth((t - 0.50) / 0.12)) or 0,
		outputAlpha = fusion and reveal * (1 - finish) or (1 - finish),
		outputScale = fusion and (0.10 + 0.90 * reveal + math.sin(reveal * math.pi) * 0.12) or 1,
		inputRadius = 2.4 * (1 - gather) + 0.12,
		inputScale = 1 - gather * 0.82,
		angle = t * math.pi * (fusion and 5 or 2),
		scanHeight = 0.2 + 2.6 * smooth((t - 0.15) / 0.45),
	}
end

return Sequence
