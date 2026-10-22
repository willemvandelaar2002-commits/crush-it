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
	local before=d.cash local ok,_,rolled=act(d,s,"Roll")
	check(ok and d.cash==before-C.RollCost and rolled.id~=starter.id,"paid roll / unique duplicate instance")
	before=d.cash check(not act(d,s,"Roll",{},.1) and d.cash==before,"cooldown cannot charge or roll again")
	check(act(d,s,"Roll",{},C.BaseRollSeconds),"roll after interval")
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
	d=fresh() s={} act(d,s,"Upgrade",{id="RollSpeed"}) act(d,s,"Roll",{},10)
	check(math.abs(s.nextRoll-(10+C.rollSeconds(1)))<.0001,"server enforces improved roll interval")
	before=d.cash check(not act(d,s,"Roll",{},s.nextRoll-.01) and before==d.cash,"animation cannot bypass interval")
	d.cash=0 before=#d.crushers.owned check(not act(d,s,"Roll",{},100) and #d.crushers.owned==before,"unaffordable roll")
	d.cash=10000 while #d.crushers.owned<C.MaxInventory do table.insert(d.crushers.owned,{id=id(),type="Bumper",rarity="Common",modifier="Standard",level=1}) end
	before=d.cash check(not act(d,s,"Roll",{},100) and d.cash==before,"full inventory never charges")
	d=R.migrate({cash=57,tier=7,levels={Power=6,Speed=4,Value=3},rebirths=2,helpers={2,4},scrap=8,smeltQueue=11,smeltReady=13,purchases={"paid"}},id)
	check(d.cash==57 and d.scrap==32 and #d.crushers.owned==3,"legacy balances and helpers migrate")
	check(d.purchases[1]=="paid" and d.legacyCrusherRecovery.helpers[2]==4 and d.smeltQueue==0 and #d.helpers==0,"perks/recovery and retirement")
	local ids=d.crushers.owned[1].id
	d=R.migrate(game.HttpService:JSONDecode(game.HttpService:JSONEncode(d)),id)
	check(d.scrap==32 and #d.crushers.owned==3 and d.crushers.owned[1].id==ids,"persisted migration is idempotent")
	d=R.migrate({cash=0/0,crushers={owned={}},crusherSchema=C.Schema},id)
	check(d.cash==C.StartCash and #d.crushers.owned==1,"repair invalid save without losing earning ability")
	d=R.migrate({cash=0},id) s={}
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
	for lv=1,C.MaxGlobal do check(C.rollSeconds(lv)<C.rollSeconds(lv-1),"every rolling-speed level improves the server interval") end
	local boosted=R.migrate({cash=0,goldenRush=1},id) local boostedSession={}
	for time=0,7 do R.step(boosted,boostedSession,time,{mult=2}) end
	check(boosted.crushers.available==8*2*C.GoldenYield and boosted.goldenRush==0,"paid double/golden benefits apply once at completion")
	return {passed=checks}
end
