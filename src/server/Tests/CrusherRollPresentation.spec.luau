--!strict
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local P=require(game.ReplicatedStorage.Shared.CrusherRollPresentation)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local checks=0 local function check(v,msg) checks+=1 assert(v,msg) end
	for luck=0,C.MaxGlobal do for _,lucky in {false,true} do
		local weights=R.weights(luck,lucky) local total=0 for _,w in weights do total+=w end
		local sum=0
		for rank,rarity in C.Rarities do for _,id in rarity.types do
			local odds=P.odds(id,luck,lucky,false)
			check(math.abs(odds-total/weights[rank]*#rarity.types)<1e-8,"odds match authoritative weights")
			check(P.oddsText(odds):find("roll odds")~=nil,"odds label identifies the draw")
			sum+=1/odds
		end end
		check(math.abs(sum-1)<1e-9,"all type probabilities sum to one")
	end end
	for _,rarity in C.Rarities do
		for _,id in rarity.types do check(P.odds(id,20,true,true)==(if rarity.name=="Common" then 8 else 0),"first roll is Common only") end
		local p=P.profile(rarity.name)
		check(P.lift(rarity.name,0)==0 and math.abs(P.lift(rarity.name,p.duration))<1e-8,"reveal lift starts and finishes on pedestal")
		for i=0,40 do check(P.lift(rarity.name,p.duration*i/40)>=0,"lift never sinks into pedestal") end
	end
	check(P.profile("Legendary").duration>P.profile("Epic").duration and P.profile("Epic").duration>P.profile("Common").duration,"rarity escalates cosmetic presentation")
	check(P.fresh(100,100) and not P.fresh(100,103) and not P.fresh(100,99) and not P.fresh(0/0,100),"old/future/bad reveals rejected")
	check(P.owns({{type="Bumper"}},"Bumper") and not P.owns({{type="Bumper"}},"Steel"),"first discovery is based on owned types")
	check(P.oddsText(4000)=="~1 in 4,000 · roll odds","readable grouped odds")
	return {passed=checks}
end
