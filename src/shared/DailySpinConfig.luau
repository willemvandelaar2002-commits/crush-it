--!strict
-- Provisional balancing. Visual sector sizes never determine probabilities.
local S = {
	Cooldown = 24 * 60 * 60, Duration = 5, Revolutions = 6,
	RotorImage = "rbxassetid://105558594053157",
	FrameImage = "rbxassetid://71953431310313",
	PaidProductId = 0, -- No receipt handler: paid spins remain disabled.
	Rewards = {
		{id="cash_short", sector=0, kind="cash", seconds=60, weight=40, color=Color3.fromRGB(70,215,70)},
		-- 29 Oct: the two Golden prizes (10x scrap for the next N toys, invisible in
		-- play) became timed hub boosts (server/Boosts)
		{id="boost_luck", sector=1, kind="boost", boost="Luck", minutes=10, weight=20, color=Color3.fromRGB(255,150,30)},
		{id="cash_medium", sector=2, kind="cash", seconds=300, weight=18, color=Color3.fromRGB(50,165,255)},
		{id="crusher_uncommon", sector=3, kind="crusher", rarity="Uncommon", weight=10, color=Color3.fromRGB(30,210,190)},
		{id="cash_long", sector=4, kind="cash", seconds=1200, weight=7, color=Color3.fromRGB(255,205,30)},
		{id="boost_cash", sector=5, kind="boost", boost="Cash", minutes=30, weight=3, color=Color3.fromRGB(245,60,70)},
		{id="crusher_rare", sector=6, kind="crusher", rarity="Rare", weight=1.5, color=Color3.fromRGB(70,100,255)},
		{id="crusher_epic", sector=7, kind="crusher", rarity="Epic", weight=.5, color=Color3.fromRGB(185,80,255)},
		-- jackpot: lands on the Epic sector (the wheel art has 8 sectors) but gives a Mythic
		{id="crusher_mythic", sector=7, jackpot=true, kind="crusher", rarity="Mythic", weight=.1, color=Color3.fromRGB(255,70,190)},
	},
}
function S.reward(id)
	for _,r in S.Rewards do if r.id==id then return r end end
end
function S.odds(id)
	local total=0 for _,r in S.Rewards do total+=r.weight end
	local r=S.reward(id) return if r then r.weight/total*100 else 0
end
function S.target(current,sector,revolutions)
	local landing=(-45*sector)%360
	return current+360*(revolutions or S.Revolutions)+(landing-current%360)%360
end
function S.desktopScale(width,height)
	return math.max(.1,math.min(1,(width-40)/920,(height-65)/640))
end
return S
