--!strict
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local P=require(game.ReplicatedStorage.Shared.CrusherRollPresentation)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local checks=0 local function check(v,msg) checks+=1 assert(v,msg) end
	for luck=0,C.MaxGlobal do for _,lucky in {false,true,4 :: any} do for _,bonus in {0,0.13} do
		-- (8 Nov: during a Lucky Weekend the live roll includes Limited, so this does too)
		local weekend=C.limitedOn()
		local weights=R.weights(luck,lucky,bonus,weekend) local total=0 for _,w in weights do total+=w end
		local sum=0
		for rank,rarity in C.Rarities do for _,id in rarity.types do
			if rarity.event and not weekend then continue end -- (Limited: only during its event, checked below)
			if rarity.weight<=0 and not rarity.event then check(P.odds(id,luck,lucky,false,bonus)==0,"exclusive types have no roll odds") continue end
			-- 11 Nov: a big luck multiplier can push a common rarity to 0% (all rolls better)
			if weights[rank]<=0 then check(P.odds(id,luck,lucky,false,bonus)==0,"a rarity at 0% shows no odds") continue end
			local odds=P.odds(id,luck,lucky,false,bonus)
			-- 2 Nov: the Index shows the same odds, rounded
			check(C.effectiveOdds(id,luck,lucky,bonus,weekend)==math.max(1,math.floor(odds+.5)),"Index odds match the roll")
			check(math.abs(odds-total/weights[rank]*#rarity.types)<1e-8,"odds match authoritative weights")
			check(P.oddsText(odds):find("roll odds")~=nil,"odds label identifies the draw")
			sum+=1/odds
		end end
		check(math.abs(sum-1)<1e-9,"all type probabilities sum to one")
	end end end
	-- 6 Nov: Limited (Lucky Weekend) odds use the weights with the event on
	local lim=C.rarity("Limited")
	for _,luck in {0,10,40} do
		local w=R.weights(luck,2,0,true) local total=0 local at=0 for i,x in w do total+=x if C.Rarities[i]==lim then at=x end end
		for _,id in lim.types do
			check(math.abs(P.odds(id,luck,2,false,0)-total/at*#lim.types)<1e-6,"Limited roll odds = weekend weights")
			check(C.effectiveOdds(id,luck,2,0,true)==math.max(1,math.floor(total/at*#lim.types+.5)),"Index weekend odds match")
		end
	end
	-- Lucky pass and 2x Luck boost stack: 4x the chance of each rarity-or-better (11 Nov)
	check(math.abs(C.chanceAtLeast(4,20,4)-4*C.chanceAtLeast(4,20,1))<1e-9,"pass + boost = 4x Legendary-or-better")
	for _,rarity in C.Rarities do
		for _,id in rarity.types do check((P.odds(id,20,true,true)>0)==(rarity.name==C.FirstRoll.Rarity),"first roll is the C.FirstRoll rarity only") end
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
