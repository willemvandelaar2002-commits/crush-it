--!strict
-- Run explicitly in Studio. Pure table fixtures never touch a live profile.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function random() return .1 end
	local function check(v,message) assert(v,message) checks+=1 end
	local function fresh() return R.migrate({cash=10000},id) end
	local function act(d,s,name,args,now) return R.act(d,s,name,args or {},now or 0,random,id,{}) end
	local d=fresh() local s={} local starter=d.crushers.owned[1]
	check(#d.crushers.owned==1 and d.crushers.equipped["1"]==starter.id,"starter must be equipped")
	local first=fresh() local _,_,cheap=R.act(first,{},"Roll",{},0,function() return .999 end,id,{})
	check(cheap[1].rarity=="Common" and cheap[1].modifier=="Standard" and first.crushers.rolls==1,"first roll is always a plain Common")
	local before=d.cash local ok,_,offers=act(d,s,"Roll")
	check(ok and d.cash==before and #offers==C.StartPedestals and #d.crushers.owned==1,"free roll fills the starting pedestals only")
	check(not act(d,s,"Buy",{slot=1},.1),"cannot buy before the reveal")
	before=d.cash local price=C.offerPrice(offers[1]) local bought,_,item=act(d,s,"Buy",{slot=1},C.RollSeconds)
	check(bought and d.cash==before-price and item.id~=starter.id,"buying an offer charges its price, unique instance")
	check(not act(d,s,"Buy",{slot=1},C.RollSeconds),"an offer can only be bought once")
	check(not act(d,s,"Roll",{},.1),"cooldown cannot roll again")
	check(act(d,s,"Roll",{},C.RollSeconds),"roll after interval")
	check(act(d,s,"Buy",{slot=1},2*C.RollSeconds),"buy second crusher")
	local sameType=d.crushers.owned[2] local otherLevel=starter.level
	check(act(d,s,"Level",{id=sameType.id}) and starter.level==otherLevel and sameType.level==2,"level correct duplicate")
	before=d.cash check(not act(d,s,"Level",{id="another-player-id"}) and before==d.cash,"foreign level ownership")
	check(not act(d,s,"Equip",{id="another-player-id",bay=1}),"foreign equipment ownership")
	check(not act(d,s,"Equip",{id=starter.id,bay=2}),"locked bay")
	check(act(d,s,"Unlock") and d.crushers.bays==2,"unlock cash bay")
	check(act(d,s,"Equip",{id=starter.id,bay=2}) and d.crushers.equipped["1"]==nil,"one instance cannot occupy two bays")
	check(act(d,s,"Equip",{id=sameType.id,bay=1}),"equip duplicate as separate machine")
	check(not act(d,s,"Equip",{id=d.crushers.owned[3].id}),"full bays reject auto equip")
	check(not act(d,s,"Equip",{id=starter.id,bay=0/0}),"NaN bay rejected")
	local st=R.stats(d,starter) act(d,s,"Upgrade",{id="Damage"}) local dmg=R.stats(d,starter)
	check(dmg.damage>st.damage and dmg.cycle==st.cycle and dmg.value==st.value,"damage is distinct")
	act(d,s,"Upgrade",{id="Speed"}) local speed=R.stats(d,starter)
	check(speed.cycle<dmg.cycle and speed.damage==dmg.damage and speed.value==dmg.value,"speed is distinct")
	act(d,s,"Upgrade",{id="Yield"}) local yield=R.stats(d,starter)
	check(yield.value>speed.value and yield.damage==speed.damage and yield.cycle==speed.cycle,"yield is distinct")
	local w0,w20=R.weights(0,false),R.weights(20,false) local sum0,sum20=0,0 for _,w in w0 do sum0+=w end for _,w in w20 do sum20+=w end
	check(w20[5]/sum20>w0[5]/sum0,"luck improves rare probability")
	local lucky=R.weights(0,true) check(lucky[1]==w0[1] and lucky[2]==w0[2]*2,"paid lucky weights")
	d=fresh() s={} act(d,s,"Upgrade",{id="Pedestals"}) local _,_,two=act(d,s,"Roll",{},10)
	check(#two==C.StartPedestals+1,"pedestal upgrade adds an offer per roll")
	check(not act(d,s,"Roll",{},s.nextRoll-.01),"animation cannot bypass interval")
	check(not act(d,s,"Buy",{slot=9},100) and not act(d,s,"Buy",{slot=0/0},100),"invalid pedestal slot rejected")
	d.cash=0 before=#d.crushers.owned check(not act(d,s,"Buy",{slot=1},100) and #d.crushers.owned==before,"unaffordable offer")
	d.cash=1e9 while #d.crushers.owned<C.MaxInventory do table.insert(d.crushers.owned,{id=id(),type="Bumper",rarity="Common",modifier="Standard",level=1}) end
	before=d.cash check(not act(d,s,"Buy",{slot=2},100) and d.cash==before,"full inventory never charges")
	d=fresh() d.cash=1e12 s={} for _=1,10 do act(d,s,"Upgrade",{id="Pedestals"}) end
	check(d.crushers.upgrades.Pedestals==C.upgradeMax("Pedestals") and C.pedestals(d.crushers.upgrades.Pedestals)==C.MaxPedestals,"pedestals stop at the max")
	d=R.migrate({cash=57,tier=7,levels={Power=6,Speed=4,Value=3},rebirths=2,helpers={2,4},scrap=8,smeltQueue=11,smeltReady=13,purchases={"paid"}},id)
	check(d.cash==57 and d.scrap==32 and #d.crushers.owned==3,"legacy balances and helpers migrate")
	check(d.purchases[1]=="paid" and d.legacyCrusherRecovery.helpers[2]==4 and d.smeltQueue==0 and #d.helpers==0,"perks/recovery and retirement")
	local ids=d.crushers.owned[1].id
	d=R.migrate(game.HttpService:JSONDecode(game.HttpService:JSONEncode(d)),id)
	check(d.scrap==32 and #d.crushers.owned==3 and d.crushers.owned[1].id==ids,"persisted migration is idempotent")
	d=R.migrate({cash=0/0,crushers={owned={}},crusherSchema=C.Schema},id)
	check(d.cash==C.StartCash and #d.crushers.owned==1,"repair invalid save without losing earning ability")
	-- Equip Best: top output fills the bays, kept crushers stay in place, no-op when already best
	local eb=fresh() eb.crushers.tutorial=#C.TutorialSteps+1 eb.crushers.bays=2
	local weak=eb.crushers.owned[1]
	local strong={id=id(),type="Quantum",rarity="Legendary",modifier="Standard",level=1}
	local mid={id=id(),type="Titan",rarity="Epic",modifier="Standard",level=1}
	table.insert(eb.crushers.owned,strong) table.insert(eb.crushers.owned,mid)
	eb.crushers.equipped={["1"]=mid.id}
	check(act(eb,{},"EquipBest") and eb.crushers.equipped["1"]==mid.id and eb.crushers.equipped["2"]==strong.id,"equip best keeps a kept crusher in its bay and fills the rest by output")
	check(not act(eb,{},"EquipBest"),"equip best twice is a no-op")
	check(weak and true,"fixture")
	-- tutorial: each step pays once, only for its own action, in order
	local t=fresh() local cash0=t.cash
	check(not R.tutorialAdvance(t,"Sell") and t.cash==cash0,"wrong tutorial action pays nothing")
	check(R.tutorialAdvance(t,"Collect") and t.crushers.tutorial==2 and t.cash==cash0+C.TutorialSteps[1].reward,"tutorial step pays its reward")
	check(not R.tutorialAdvance(t,"Collect") and t.crushers.tutorial==2,"a step cannot pay twice")
	for i=2,#C.TutorialSteps do R.tutorialAdvance(t,C.TutorialSteps[i].id) end
	local total=C.TutorialBonus for _,st in C.TutorialSteps do total+=st.reward end
	check(t.crushers.tutorial==#C.TutorialSteps+1 and t.cash==cash0+total,"finishing pays every step and the bonus once")
	local old=fresh() old.crushers.bays=3 old.crushers.rolls=4 table.insert(old.crushers.owned,{id=id(),type="Steel",rarity="Common",modifier="Standard",level=1})
	R.tutorialCatchUp(old) check(old.crushers.tutorial==6 and C.TutorialSteps[6].id=="Equip","catch-up skips steps already done, stops at the first open one")
	d=R.migrate({cash=0},id) s={} d.crushers.tutorial=#C.TutorialSteps+1 -- ledger checks below without tutorial rewards
	local events=R.step(d,s,0,{}) check(d.crushers.available==0 and events[1].kind=="Input","input spawn never awards scrap")
	for time=1,7 do R.step(d,s,time,{}) end
	check(d.crushers.available==8 and d.crushed==1,"scrap only on completed object")
	R.step(d,s,7.1,{}) check(d.crushers.available==8,"repeated tick never duplicates completion")
	R.step(d,s,9,{}) check(d.crushers.available==8,"next input never pays another reward")
	act(d,s,"Collect") check(d.scrap==8 and d.crushers.available==0,"collect moves ready ledger")
	act(d,s,"Sell") check(d.cash==8 and d.scrap==0,"sell moves carried ledger directly")
	act(d,s,"Sell") check(d.cash==8,"repeated sell cannot duplicate")
	local other=fresh() R.step(d,s,10,{}) check(other.crushers.available==0,"profile production isolation")
	local large=R.migrate({cash=1e20},id) check(large.cash==1e20,"large legacy cash is preserved")
	local ownedCount=#large.crushers.owned act(large,{},"Unequip",{id=large.crushers.owned[1].id})
	check(#large.crushers.owned==ownedCount,"unequipping never removes the permanent earning asset")
	large.crushers.bays=C.MaxBays before=large.cash
	check(not act(large,{},"Unlock") and large.cash==before,"max bays never charges")
	large.crushers.upgrades.Damage=C.MaxGlobal
	check(not act(large,{},"Upgrade",{id="Damage"}) and large.cash==before,"max upgrade never charges")
	local profiles,contexts={},{}
	for i=1,8 do profiles[i]=fresh() contexts[i]={} R.step(profiles[i],contexts[i],0,{}) end
	for time=1,7 do for i=1,8 do R.step(profiles[i],contexts[i],time,{}) end end
	for i=1,8 do check(profiles[i].crushers.available==8,"independent simultaneous factory production") end
	local boosted=R.migrate({cash=0,goldenRush=1},id) local boostedSession={}
	for time=0,7 do R.step(boosted,boostedSession,time,{mult=2}) end
	check(boosted.crushers.available==8*2*C.GoldenYield and boosted.goldenRush==0,"paid double/golden benefits apply once at completion")
	-- Expanded plot: old schema-2 IDs and slots remain unchanged, without a wipe.
	local old=fresh() old.crushers.bays=3 old.cash=1e12
	for i=2,3 do local v={id=id(),type="Steel",rarity="Common",modifier="Rusty",level=i+4} table.insert(old.crushers.owned,v) old.crushers.equipped[tostring(i)]=v.id end
	local oldId=old.crushers.equipped["3"]
	old=R.migrate(game.HttpService:JSONDecode(game.HttpService:JSONEncode(old)),id)
	check(old.crushers.bays==3 and old.crushers.equipped["3"]==oldId and R.find(old,oldId).level==7,"three-bay save retains equipment and instance level")
	for bay=4,C.MaxBays do
		check(act(old,{},"Unlock") and old.crushers.bays==bay,"sequential expanded bay unlock")
	end
	check(C.bayLayout(C.Layout.Wings*C.Layout.PerWing).tier==1 and C.bayLayout(C.Layout.Wings*C.Layout.PerWing+1).tier==2,"ground floor unlocks before upper tier")
	check(act(old,{},"Equip",{id=oldId,bay=C.MaxBays}) and old.crushers.equipped[tostring(C.MaxBays)]==oldId and old.crushers.equipped["3"]==nil,"existing instance equips beyond old capacity")
	local saved=R.migrate(game.HttpService:JSONDecode(game.HttpService:JSONEncode(old)),id)
	check(saved.crushers.equipped[tostring(C.MaxBays)]==oldId and saved.crushers.bays==C.MaxBays,"expanded equipment survives save roundtrip")
	local plotConfig=require(game.ReplicatedStorage.Shared.Config).Plots
	for bay=1,C.MaxBays do local layout=C.bayLayout(bay)
		check(math.abs(layout.x)+C.Layout.MachineWidth/2<plotConfig.FloorSize/2 and layout.tier<=2,"bay fits the configured two-tier plot")
	end
	check(plotConfig.FloorSize/2+3<plotConfig.Ring*math.tan(math.pi/plotConfig.Count),"radial plot footprints have a gap at the narrow entrance corners")
	local finalLegacy=R.migrate({cash=500,tier=13},id)
	check(finalLegacy.crushers.owned[1].type=="Quantum","new types cannot change legacy tier migration")
	local special={id=id(),type="TwinTitan",rarity="Epic",modifier="Rusty",level=8}
	table.insert(saved.crushers.owned,special)
	saved=R.migrate(game.HttpService:JSONDecode(game.HttpService:JSONEncode(saved)),id)
	check(R.find(saved,special.id).level==8 and R.find(saved,special.id).modifier=="Rusty","special collection instance survives reload")
	for _,v in {{"TwinTitan","Titan",.99,.9},{"RocketPress","Cobalt",.8,.9},{"Magnetron","Mega",.95,.9},{"GoldenKing","Quantum",.999,.4},{"Toyzilla","Quantum",.999,.9}} do
		local profile=fresh() local base=table.clone(profile.crushers.owned[1]) base.type=v[2]
		local instance=table.clone(base) instance.type=v[1]
		local a,b=R.stats(profile,base),R.stats(profile,instance)
		check(a.damage==b.damage and a.cycle==b.cycle and a.value==b.value and a.hp==b.hp,"special keeps its existing production band")
		local pool=C.rarityOf(v[1]).types
		profile.crushers.rolls=1 -- past the plain-Common first roll
		local draws={v[3],.1,(table.find(pool,v[1])-.5)/#pool} local index=0
		local result,_,rolled=R.act(profile,{},"Roll",{},0,function() index+=1 return draws[index] end,id,{})
		check(result and rolled[1].type==v[1],"special is reachable through authoritative collection rolls")
	end
	-- Forty real, reachable definitions; model additions must not silently
	-- change legacy IDs, saved instance stats or the existing rarity weights.
	check(#C.Types==40,"forty live crusher types")
	local seen={} local cumulative=0 local total=0 for _,r in C.Rarities do total+=r.weight end
	for _,r in C.Rarities do
		check(#r.types==8,"eight types per rarity")
		for position,typeId in r.types do
			check(not seen[typeId] and C.typeById(typeId)~=nil,"unique real type in each roll pool") seen[typeId]=true
			local profile=fresh() profile.crushers.rolls=1 local context={} local values={(cumulative+r.weight/2)/total,.1,(position-.5)/#r.types} local n=0
			local ok,_,result=R.act(profile,context,"Roll",{},0,function() n+=1 return values[n] end,id,{})
			check(ok and result[1].type==typeId and result[1].rarity==r.name,"every catalogue entry is rollable")
			profile.cash=1e9
			local bought,_,item=R.act(profile,context,"Buy",{slot=1},context.nextRoll,math.random,id,{})
			check(bought and item.type==typeId,"catalogue offer can be purchased")
			local stats=R.stats(profile,item)
			check(stats.cps>0 and stats.cycle>0 and stats.hp>0,"each type has usable production stats")
			item.level=7 local restored=R.migrate(R.copy(profile),id)
			check(R.find(restored,item.id).type==typeId and R.find(restored,item.id).level==7,"new types and levels survive migration")
		end
		cumulative+=r.weight
	end
	local recycle=fresh() local first=recycle.crushers.owned[1] local duplicate=table.clone(first)
	duplicate.id=id() duplicate.level=4 table.insert(recycle.crushers.owned,duplicate)
	local cash=recycle.cash
	check(not act(recycle,{},"Recycle",{id=first.id}),"cannot recycle an equipped instance")
	check(not act(recycle,{},"Recycle",{id="foreign-id"}),"cannot recycle another player's instance")
	check(act(recycle,{},"Recycle",{id=duplicate.id}) and #recycle.crushers.owned==1,"can free space by recycling exact duplicate")
	check(recycle.cash==cash and first.level==1,"recycling cannot mint cash or change other levels")
	act(recycle,{},"Unequip",{id=first.id})
	check(not act(recycle,{},"Recycle",{id=first.id}),"last copy of a type protects discovery")
	return {passed=checks}
end
