--!strict
-- Run explicitly in Studio. 2 Nov evening: REBIRTH rules (and old merge stars).
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,name,args) return R.act(d,{},name,args or {},0,function() return .1 end,id,{}) end
	local function copyOf(item) return {id=id(),type=item.type,rarity=item.rarity,modifier=item.modifier,level=1} end

	-- MERGE was removed again; stars made while it was live still count and survive saves
	local d=R.migrate({cash=1e9},id) d.crushers.available=0
	local base=d.crushers.owned[1]
	local before=R.stats(d,base).value
	check(not act(d,"Merge",{id=base.id}),"merge is gone")
	base.stars=1
	check(math.abs(R.stats(d,base).value-before*C.Merge.Mult)<1e-6,"an old star still multiplies the value")
	check(R.migrate(R.copy(d),id).crushers.owned[1].stars==1,"stars survive migrate")

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
	check(C.rebirthMult(1)==C.Rebirth.Mult and C.rebirthMult(2)==C.Rebirth.Mult^2 and C.rebirthCost(1)>C.rebirthCost(0),"bonus rises, next rebirth costs more")
	local again=R.migrate(R.copy(r),id)
	check(again.crushers.rebirths==1,"rebirths survive migrate")
	-- REBUILD (after the first rebirth): buys every bay it can afford, then equips the best
	local b=R.migrate({cash=10},id) b.crushers.available=0
	check(not act(b,"Rebuild"),"rebuild needs a rebirth")
	b.crushers.rebirths=1 b.crushers.plotLevel=0 b.crushers.bays=1
	for i=1,5 do table.insert(b.crushers.owned,copyOf(b.crushers.owned[1])) end
	b.cash=C.BayCosts[2]+C.BayCosts[3]+C.BayCosts[4]+1
	local built,_,bought=act(b,"Rebuild")
	local filled=0 for _ in b.crushers.equipped do filled+=1 end
	check(built and bought==3 and b.crushers.bays==4 and filled==4 and b.cash<C.BayCosts[5],"rebuild buys bays cheapest first and fills them")
	-- EQUIP BY RARITY: the chosen rarity goes first, filling bays from bay 1
	local e=R.migrate({cash=10},id) e.crushers.available=0
	local es=e.crushers es.bays=3
	local rare={id=id(),type=C.rarity("Rare").types[1],rarity="Rare",modifier="Standard",level=1}
	local epic={id=id(),type=C.rarity("Epic").types[1],rarity="Epic",modifier="Standard",level=1}
	table.insert(es.owned,rare) table.insert(es.owned,epic)
	check(act(e,"EquipBest",{rarity="Rare"}) and es.equipped["1"]==rare.id,"equip by rarity puts that rarity in bay 1")
	check(not act(e,"EquipBest",{rarity="Mythic"}),"equip by rarity needs one of that rarity")
	-- FILL ROW: row 1 gets the best crushers of the chosen rarity, moved from other bays
	local f=R.migrate({cash=10},id) f.crushers.available=0
	local fs=f.crushers fs.bays=8
	local epics={} for i=1,7 do local e2={id=id(),type=C.rarity("Epic").types[1],rarity="Epic",modifier="Standard",level=i} table.insert(fs.owned,e2) table.insert(epics,e2) end
	fs.equipped["8"]=epics[7].id
	check(act(f,"FillRow",{row=1,rarity="Epic"}),"fill row works")
	local ok6=true for bay=1,6 do local it=R.find(f,fs.equipped[tostring(bay)]) if not it or it.rarity~="Epic" then ok6=false end end
	check(ok6 and fs.equipped["1"]==epics[7].id and fs.equipped["8"]==nil,"row 1 holds the six best Epics; the best moved from bay 8")
	check(not act(f,"FillRow",{row=1,rarity="Mythic"}) and not act(f,"FillRow",{row=99,rarity="Epic"}),"fill row checks rarity and row")
	-- EQUIP BEST past Factory I: fills bays beyond 12 (bug 3 Nov: it judged only bays 1-12)
	local q=R.migrate({cash=10},id) q.crushers.available=0
	local qs=q.crushers qs.plotLevel=1 qs.bays=C.bayCapacity(1) qs.equipped={}
	local legs={}
	for i=1,qs.bays do local l={id=id(),type=C.rarity("Legendary").types[1],rarity="Legendary",modifier="Standard",level=1} table.insert(qs.owned,l) table.insert(legs,l) end
	for i=1,12 do qs.equipped[tostring(i)]=legs[i].id end
	check(R.equipBestHelps(q,{}),"equip best sees empty bays past 12")
	check(act(q,"EquipBest"),"equip best fills them")
	local full=0 for _ in qs.equipped do full+=1 end
	check(full==qs.bays,"every bay filled: "..full.."/"..qs.bays)
	check(not R.equipBestHelps(q,{}) and not act(q,"EquipBest"),"then nothing left to improve")
	-- x10 factory upgrades: up to 10 levels, as many as the cash covers
	local u=R.migrate({cash=10},id) u.crushers.available=0
	local cost10=0 for k=0,9 do cost10+=C.globalCost("Damage",k) end
	u.cash=cost10
	local okU,_,nU=act(u,"UpgradeMany",{id="Damage"})
	check(okU and nU==10 and u.crushers.upgrades.Damage==10 and u.cash<1,"x10 buys ten levels")
	u.cash=C.globalCost("Damage",10)+C.globalCost("Damage",11)
	local _,_,n2=act(u,"UpgradeMany",{id="Damage"})
	check(n2==2 and u.crushers.upgrades.Damage==12,"x10 buys what the cash covers")
	check(not act(u,"UpgradeMany",{id="Damage"}) and not act(u,"UpgradeMany",{id="Luck"}),"x10 needs cash and only works on factory upgrades")
	print("RebirthMerge.spec: "..checks.." checks passed")
end
