--!strict
-- Provisional balancing. Visual sector sizes never determine probabilities.
local S = {
	Cooldown = 24 * 60 * 60, Duration = 5, Revolutions = 6,
	RotorImage = "rbxassetid://105558594053157",
	FrameImage = "rbxassetid://71953431310313",
	PaidProductId = 0, -- No receipt handler: paid spins remain disabled.
	Rewards = {
		{id="cash_short", sector=0, kind="cash", seconds=60, weight=40, color=Color3.fromRGB(80,195,75)},
		{id="golden_small", sector=1, kind="golden", count=10, weight=20, color=Color3.fromRGB(250,145,35)},
		{id="cash_medium", sector=2, kind="cash", seconds=300, weight=18, color=Color3.fromRGB(65,165,245)},
		{id="crusher_uncommon", sector=3, kind="crusher", rarity="Uncommon", weight=10, color=Color3.fromRGB(35,190,175)},
		{id="cash_long", sector=4, kind="cash", seconds=1200, weight=7, color=Color3.fromRGB(250,210,45)},
		{id="golden_large", sector=5, kind="golden", count=30, weight=3, color=Color3.fromRGB(230,65,65)},
		{id="crusher_rare", sector=6, kind="crusher", rarity="Rare", weight=1.5, color=Color3.fromRGB(65,90,225)},
		{id="crusher_epic", sector=7, kind="crusher", rarity="Epic", weight=.5, color=Color3.fromRGB(175,75,235)},
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
