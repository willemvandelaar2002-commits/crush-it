--!strict
-- Disposable pure profiles, no live saves or place assets.
return function()
	local S=game.ReplicatedStorage.Shared
	local C=require(S.CrusherConfig) local R=require(S.CrusherRules)
	local P=require(S.FactoryProgression) local Rows=require(S.CrusherRows)
	local checks=0 local n=0
	local function check(v,message) checks+=1 assert(v,message) end
	local function id() n+=1 return "factory-fixture-"..n end
	local function fresh() local d=R.migrate({cash=1e12},id) d.crushers.tutorial=#C.TutorialSteps+1 return d end
	local function full()
		local d=fresh() d.crushers.bays=C.BaseMaxBays
		d.crushers.owned={} d.crushers.equipped={}
		for i=1,C.BaseMaxBays do
			local rarity=C.Rarities[(i-1)%#C.Rarities+1]
			local item={id=id(),type=rarity.types[1],rarity=rarity.name,modifier="Standard",level=1}
			table.insert(d.crushers.owned,item) d.crushers.equipped[tostring(i)]=item.id
		end
		return d
	end
	local d=fresh() local before=d.cash
	check(C.BaseMaxBays==24 and C.MaxBays==30,"one extra six-bay row")
	check(not P.expand(d) and d.cash==before,"incomplete plot cannot expand or charge")
	d=full() check(P.full(d),"mixed rarities qualify when all original rows are occupied")
	d.crushers.equipped["24"]=nil
	check(not P.full(d) and not P.expand(d),"one empty original bay blocks upgrade")
	d=full() d.crushers.equipped["24"]=d.crushers.equipped["23"]
	check(not P.full(d),"duplicate equipment cannot fake full rows")
	d=full() d.cash=C.PlotUpgrade.Cost-1 before=d.cash
	check(not P.expand(d) and d.cash==before and d.crushers.plotLevel==0,"unaffordable plot upgrade leaves profile unchanged")
	d.cash=C.PlotUpgrade.Cost
	local original=R.copy(d.crushers.owned)
	check(P.expand(d) and d.cash==0 and d.crushers.plotLevel==1 and d.crushers.bays==30,"upgrade charges once and grants six bays")
	check(not P.expand(d) and d.cash==0,"repeated expansion cannot grant or charge again")
	for i,item in original do check(d.crushers.owned[i].id==item.id and d.crushers.owned[i].level==item.level,"expansion retains crushers") end
	local saved=R.migrate(R.copy(d),id)
	check(saved.crushers.plotLevel==1 and saved.crushers.bays==30,"expansion survives migration")
	saved.crushers.bays=24 saved=R.migrate(saved,id)
	check(saved.crushers.bays==30,"paid row entitlement repairs partial capacity")
	local old=full();old.crushers.bays=30;old.crushers.plotLevel=nil
	old=R.migrate(old,id)
	check(old.crushers.plotLevel==0 and old.crushers.bays==24,"old saves do not get free expansion from capacity alone")
	check(not R.act(old,{},"Unlock",{},0,math.random,id,{}),"ordinary Unlock cannot bypass plot upgrade")
	check(Rows.snapshot(old).rows[5].unlocked==0,"unbought expansion has no row perk")
	for bay=25,30 do local layout=C.bayLayout(bay)
		check(layout.expansion and layout.y==0 and layout.side==0 and layout.z==-43,"rear expansion stays low and centered")
		check(math.abs(layout.x)+C.Layout.BayWidth/2<35,"row bays fit expansion width")
	end
	-- Coatings apply to owned, held, unequipped instances with one-use previews.
	d=full() local item={id=id(),type="Titan",rarity="Epic",modifier="Standard",level=7}
	table.insert(d.crushers.owned,item)
	check(not P.quote(d,item.id,"Polished",0,"q"),"lab is locked until plot upgrade")
	d.cash=1e12 check(P.expand(d),"coating fixture expanded")
	for _,recipe in C.Coatings do
		item.modifier="Standard" local before=d.cash local serial=item.id
		local quote=P.quote(d,item.id,recipe.name,100,"quote-"..recipe.name)
		check(quote and d.cash==before and item.modifier=="Standard","preview never charges or changes finish")
		check(not P.apply(d,quote,"wrong",item.id,101) and d.cash==before,"wrong confirmation token rejected")
		check(not P.apply(d,quote,quote.token,"foreign-id",101) and d.cash==before,"switched held crusher rejected")
		check(not P.apply(d,quote,quote.token,item.id,quote.expires) and d.cash==before,"expired preview rejected")
		local ok=P.apply(d,quote,quote.token,item.id,101)
		check(ok and item.modifier==recipe.name and d.cash==before-quote.cost,"confirmation applies exactly the selected coating/cost")
		check(item.id==serial and item.type=="Titan" and item.rarity=="Epic" and item.level==7,"coating preserves identity/rarity/level")
		local cash=d.cash check(not P.apply(d,quote,quote.token,item.id,102) and d.cash==cash,"replayed confirmation cannot charge twice")
		check(not P.quote(d,item.id,recipe.name,103,"duplicate"),"same finish cannot be purchased again")
		local restored=R.migrate(R.copy(d),id) local restoredItem=R.find(restored,item.id)
		check(restoredItem.modifier==recipe.name,"each applied finish survives saves")
		local uncoated=table.clone(item);uncoated.modifier="Standard"
		local a,b=R.stats(d,item),R.stats(d,uncoated)
		check(math.abs(a.cps/b.cps-C.modifier(recipe.name).mult)<1e-8 and a.damage==b.damage and a.cycle==b.cycle,"finish boosts yield, not damage or speed")
	end
	item.modifier="Charged"
	check(not P.quote(d,item.id,"Polished",0,"downgrade") and not P.quote(d,item.id,"Fire",0,"downgrade"),"no accidental downgrade")
	item.modifier="Standard"
	local quote=P.quote(d,item.id,"Frost",0,"stale") item.level+=1
	before=d.cash check(not P.apply(d,quote,quote.token,item.id,1) and d.cash==before,"changed level invalidates cost preview")
	item.level=7 quote=P.quote(d,item.id,"Fire",0,"cash") d.cash=quote.cost-1 before=d.cash
	check(not P.apply(d,quote,quote.token,item.id,1) and d.cash==before and item.modifier=="Standard","insufficient cash never mutates finish")
	d.crushers.equipped["25"]=item.id
	check(not P.quote(d,item.id,"Charged",0,"equipped"),"equipped machine must be unequipped at the lab")
	check(not P.quote(d,"someone-else","Charged",0,"foreign"),"foreign ownership rejected")
	check(not P.quote(d,item.id,"Imaginary",0,"unknown"),"unknown finish rejected")
	local total=0 for _,modifier in C.Modifiers do total+=modifier.weight check(modifier.name~="Frost" and modifier.name~="Fire","craft-only finishes stay out of rolls") end
	check(total==100,"original modifier roll weights preserved")
	return {passed=checks}
end
