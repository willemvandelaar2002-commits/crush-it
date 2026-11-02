--!strict
-- Run explicitly in Studio. 2 Nov evening: MERGE (stars) and REBIRTH rules.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,name,args) return R.act(d,{},name,args or {},0,function() return .1 end,id,{}) end
	local function copyOf(item) return {id=id(),type=item.type,rarity=item.rarity,modifier=item.modifier,level=1} end

	-- MERGE: needs Copies spare copies of the same type and stars
	local d=R.migrate({cash=1e9},id) d.crushers.available=0
	local s=d.crushers local base=s.owned[1]
	check(not act(d,"Merge",{id=base.id}),"no spare copies: no merge")
	local a=copyOf(base) local b=copyOf(base) table.insert(s.owned,a) table.insert(s.owned,b)
	local before=R.stats(d,base).value
	local ok=act(d,"Merge",{id=base.id})
	check(ok and base.stars==1 and #s.owned==1,"merge uses the two spare copies and adds a star")
	check(math.abs(R.stats(d,base).value-before*C.Merge.Mult)<1e-6,"a star multiplies the value")
	local saved=R.migrate(R.copy(d),id)
	check(saved.crushers.owned[1].stars==1,"stars survive migrate")
	-- a starless copy can't feed a 1-star merge
	table.insert(s.owned,copyOf(base)) table.insert(s.owned,copyOf(base))
	check(not act(d,"Merge",{id=base.id}),"copies must have the same stars")
	check(#s.owned==3,"failed merge keeps the copies")

	-- REBIRTH
	local r=R.migrate({cash=10},id) r.crushers.available=0
	local rs=r.crushers
	check(not act(r,"Rebirth"),"rebirth needs the factory level")
	rs.plotLevel=C.Rebirth.MinPlot rs.bays=C.bayCapacity(rs.plotLevel)
	check(not act(r,"Rebirth"),"rebirth needs the cash")
	r.cash=C.rebirthCost(0) r.scrap=500 rs.available=40
	rs.upgrades.Damage=10 rs.upgrades.Luck=7 rs.upgrades.Pedestals=2
	local item=rs.owned[1] item.level=30 item.stars=2
	local extra=copyOf(item) extra.modifier="Golden" table.insert(rs.owned,extra)
	rs.equipped["2"]=extra.id
	local done,msg,count=act(r,"Rebirth")
	check(done and count==1 and rs.rebirths==1,"rebirth counts: "..tostring(msg))
	check(r.cash==C.Rebirth.StartCash and r.scrap==0 and rs.available==0,"cash and scrap reset")
	check(rs.plotLevel==0 and rs.bays==1 and rs.equipped["1"]==item.id and rs.equipped["2"]==nil,"factory back to bay 1")
	check(rs.upgrades.Damage==0 and rs.upgrades.Luck==7 and rs.upgrades.Pedestals==2,"factory upgrades reset, Luck and pedestals kept")
	check(#rs.owned==2 and item.level==1 and item.stars==2 and extra.modifier=="Golden","crushers kept (stars, coating), levels reset")
	check(C.rebirthMult(1)==1+C.Rebirth.MultPer and C.rebirthCost(1)>C.rebirthCost(0),"bonus rises, next rebirth costs more")
	local again=R.migrate(R.copy(r),id)
	check(again.crushers.rebirths==1,"rebirths survive migrate")
	print("RebirthMerge.spec: "..checks.." checks passed")
end
