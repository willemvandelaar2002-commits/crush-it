--!strict
-- Cosmetic timings and roll-specific odds. Never chooses or grants an offer.
local C=require(script.Parent.CrusherConfig)
local P={Tag="CrusherOfferReveal",FreshSeconds=2.25,MaxSlots=5}
local profiles={
	Common={rank=0,duration=.32,lift=.35,pitch=1.15},
	Uncommon={rank=1,duration=.48,lift=.5,pitch=1.1},
	Rare={rank=2,duration=.7,lift=.7,pitch=1.05},
	Epic={rank=3,duration=1.0,lift=1.0,pitch=.98},
	Legendary={rank=4,duration=1.35,lift=1.3,pitch=.9},
	Mythic={rank=5,duration=1.6,lift=1.5,pitch=.85},
}
function P.profile(rarity) return profiles[rarity] or profiles.Common end
function P.owns(items,id)
	for _,item in items do if item.type==id then return true end end return false
end
function P.odds(id,luck,lucky,first)
	local wanted=C.rarityOf(id) if not wanted or wanted.weight<=0 then return 0 end
	if first then return if wanted.name=="Common" then #wanted.types else 0 end
	local total=0 local weight=0
	for _,r in C.Rarities do
		local w=r.weight*(1+C.LuckPerLevel*luck*r.rank)*(if lucky and r.rank>0 then 2 else 1)
		total+=w if r==wanted then weight=w end
	end
	return total/weight*#wanted.types
end
function P.oddsText(n)
	if n<=0 then return "" end
	local text=tostring(math.max(1,math.floor(n+.5)))
	text=text:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
	return "~1 in "..text.." · roll odds"
end
function P.lift(rarity,age)
	local p=P.profile(rarity) local t=math.clamp(age/p.duration,0,1)
	return math.sin(t*math.pi)*(1-t)*p.lift
end
function P.fresh(at,now) return type(at)=="number" and now-at>=-.25 and now-at<=P.FreshSeconds end
return P
