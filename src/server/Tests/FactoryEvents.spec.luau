--!strict
return function()
	local Shared=game.ReplicatedStorage.Shared
	local E=require(Shared.FactoryEventConfig)
	local R=require(Shared.FactoryEventRules)
	local Motion=require(Shared.FactoryEventMotion)
	local C=require(Shared.CrusherConfig)
	local Crushers=require(Shared.CrusherRules)
	local checks=0 local sequence=0
	local function check(ok,message) assert(ok,message) checks+=1 end
	local function close(a,b,message) check(math.abs(a-b)<1e-7*math.max(1,math.abs(b)),message) end
	local function id() sequence+=1 return "event-test-"..sequence end
	local function fresh() return Crushers.migrate({cash=0},id) end
	local function snapshot(d)
		return R.snapshot(d,C.bayCapacity(d.crushers.plotLevel),C.rarityOf,function(item) return Crushers.stats(d,item,{},false) end)
	end
	local d=fresh() local s=d.crushers s.bays=24 s.owned={} s.equipped={}
	local commonType=C.rarity("Common").types[1]
	for bay=1,10 do local item={id=id(),type=commonType,rarity="Common",modifier="Standard",level=1}
		table.insert(s.owned,item) s.equipped[tostring(bay)]=item.id end
	local ten=snapshot(d)
	check(ten.count==10 and ten.points==10,"ten placed Commons make ten points")
	local spare={id=id(),type="GoldenKing",rarity="Legendary",modifier="Standard",level=1}
	table.insert(s.owned,spare)
	check(snapshot(d).points==10,"backpack crushers do not contribute")
	s.equipped["11"]=spare.id
	check(snapshot(d).points==15 and snapshot(d).dominant=="Legendary","Legendary adds five and sets accent")
	s.equipped["12"]=spare.id
	check(snapshot(d).points==15,"corrupt duplicate ID is counted once")
	s.equipped["12"]=nil
	spare.rarity="Mythic"
	check(snapshot(d).points==10,"mismatched claimed rarity cannot inflate score")
	spare.rarity="Legendary"
	s.bays=10
	check(snapshot(d).points==10,"locked bays do not contribute")
	s.bays=24
	local before=snapshot(d) local saved=Crushers.copy(d)
	local upgraded=s.owned[1] upgraded.level=20 upgraded.modifier="Charged" upgraded.fused=true
	local after=snapshot(d)
	check(after.points==before.points and after.cps>before.cps and after.power>before.power,"level/coating/fusion strengthen damage, not rarity points")
	check(saved.crushers.owned[1].level==1 and not saved.crushers.owned[1].fused,"snapshots are plain values, not live inventory references")
	for rarity,points in E.Points do
		local typeId=C.rarity(rarity).types[1]
		local one=fresh() one.crushers.owned={{id="only",type=typeId,rarity=rarity,modifier="Standard",level=1}}
		one.crushers.equipped={["1"]="only"}
		check(snapshot(one).points==points,rarity.." uses its configured points")
	end
	local cap=R.snapshot(d,24,C.rarityOf,function() return {cps=1e290} end)
	check(cap.power==E.MaxPower,"huge factories have a finite event power cap")
	local invalid=R.snapshot(d,24,C.rarityOf,function() return {cps=0/0} end)
	check(invalid.count==0 and invalid.power==0,"nonfinite stats cannot damage the boss")
	for i,g in E.Grades do check(R.grade(g.points)==i,"grade boundary "..i) end
	check(R.inside(Vector3.new(0,5,0)) and not R.inside(Vector3.new(81,5,0)),"own-plot width checked")
	check(not R.inside(Vector3.new(0,5,-126)) and not R.inside(Vector3.new(0,70,0)),"rear and height checked")
	check(R.onBeat(10.2,10) and not R.onBeat(11.2,10),"server beat window")
	close(R.damage(4,true),R.damage(4,false)*E.PulseMultiplier,"overdrive multiplier")
	local hp,m=R.resize(40,100,50)
	close(hp,20,"leaving preserves completion ratio") close(m,50,"leaving resizes max")
	check(R.reward(0)==E.MinReward and R.reward(1e290)==E.MaxReward,"reward min/cap")
	local record={active=E.MinimumActive,hits=E.MinimumHits,cps=10}
	check(R.eligible(record),"both participation thresholds qualify")
	check(not R.eligible({active=29,hits=100}),"hits alone cannot qualify")
	check(not R.eligible({active=100,hits=9}),"time alone cannot qualify")
	-- reward reels: fixed rolls, fake grant hooks
	local given,boosted={}, {}
	local function hooks(rolls,full)
		local i=0
		return {random=function() i+=1 return rolls[i] or 0 end,
			giveCrusher=function(rarity) if full then return nil end table.insert(given,rarity) return rarity.." Thing" end,
			addBoost=function(b,m) table.insert(boosted,b) return true end}
	end
	local cashOnly={0,0,0}
	local profile=fresh() local original=Crushers.copy(profile.crushers)
	record.rank=1
	local ok,result=R.grant(profile,"round-1",record,C.money,hooks(cashOnly))
	check(ok and #result.prizes==E.Reels.ByRank[1] and profile.factoryEvents.wins==1,"rank 1 spins its configured reels")
	check(result.cash==R.cashPrize(R.prize("Cash"),10)*#result.prizes and profile.cash==result.cash,"cash tiles pay cps x seconds")
	local paid=profile.cash
	check(not R.grant(profile,"round-1",record,C.money,hooks(cashOnly)) and profile.cash==paid,"repeated finale cannot pay twice")
	local rejoined=Crushers.migrate(Crushers.copy(profile),id)
	check(not R.grant(rejoined,"round-1",record,C.money,hooks(cashOnly)),"reward ledger survives profile migration/rejoin")
	check(profile.crushers.owned[1].id==original.owned[1].id and profile.crushers.equipped["1"]==original.equipped["1"],"reward never consumes or moves crushers")
	check(not R.grant(profile,"unqualified",{active=0,hits=0,cps=100},C.money,hooks(cashOnly)),"unqualified victory cannot pay")
	check(R.reelCount(nil)==E.Reels.Others and R.reelCount(99)==E.Reels.Others,"unranked/low ranks get the base reels")
	check(R.pick(.999999)==E.Reels.Prizes[#E.Reels.Prizes].id and R.pick(0)==E.Reels.Prizes[1].id,"pick covers both ends")
	local total=0 for _,v in R.odds() do total+=v end
	check(math.abs(total-100)<.5,"displayed odds add up to 100%")
	local mythicAt=0 local w=0 local sum=0 for _,p in E.Reels.Prizes do sum+=p.weight end
	for _,p in E.Reels.Prizes do if p.id=="Mythic" then mythicAt=(w+p.weight/2)/sum end w+=p.weight end
	record.rank=50
	local ok2,r2=R.grant(profile,"round-crusher",record,C.money,hooks({mythicAt}))
	check(ok2 and #r2.prizes==1 and r2.prizes[1].kind=="crusher" and given[#given]=="Mythic","crusher tile grants that rarity")
	local before=profile.cash
	local ok3,r3=R.grant(profile,"round-full",record,C.money,hooks({mythicAt},true))
	check(ok3 and r3.prizes[1].fallback and r3.prizes[1].id=="Mythic" and profile.cash>before,"full inventory turns a crusher tile into cash")
	record.rank=1
	for i=2,30 do R.grant(profile,"round-"..i,record,C.money,hooks(cashOnly)) end
	check(#profile.factoryEvents.claimed==E.LedgerSize,"reward ledger bounded")
	profile.factoryEvents={wins=0/0,claimed={"a","a",false,"b"}}
	R.migrate(profile)
	check(profile.factoryEvents.wins==0 and #profile.factoryEvents.claimed==2,"malformed event state sanitizes")
	for _,phase in {"Assemble","Active","Finale","Victory","Recover"} do check(Motion.controls(phase),phase.." has one event ram owner") end
	check(not Motion.controls("Idle") and not Motion.controls("Announce"),"normal scenery driver outside event")
	local f,hit=Motion.ram("Finale",2.85)
	check(f==1 and hit,"final blow lands at 2.85 seconds")
	f,hit=Motion.ram("Finale",6.5)
	check(f==0 and not hit,"final blow retracts before recovery")
	for tick=0,720 do
		local age=tick/120
		local fraction=Motion.plotStroke(age)
		check(fraction>=0 and fraction<=1,"plot stroke stays within bounds")
	end
	return {passed=checks}
end
