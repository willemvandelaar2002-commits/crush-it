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
	check(C.BaseMaxBays==24 and C.MaxBays==60 and C.bayCapacity(1)==36 and C.bayCapacity(2)==48 and C.bayCapacity(3)==54 and C.bayCapacity(4)==60,"five stages: 24, 36, 48, 54, 60 bays")
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
	check(P.expand(d) and d.cash==0 and d.crushers.plotLevel==1 and d.crushers.bays==24,"Factory II charges once; its twelve bays are bought separately")
	check(not P.expand(d) and d.cash==0,"repeated expansion cannot grant or charge again")
	for i,item in original do check(d.crushers.owned[i].id==item.id and d.crushers.owned[i].level==item.level,"expansion retains crushers") end
	local saved=R.migrate(R.copy(d),id)
	check(saved.crushers.plotLevel==1 and saved.crushers.bays==24,"expansion survives migration")
	d.cash=1e15
	for bay=25,36 do check(R.act(d,{},"Unlock",{},0,math.random,id,{}) and d.crushers.bays==bay,"new row bays unlock one by one") end
	check(not R.act(d,{},"Unlock",{},0,math.random,id,{}),"no bays past the plot level")
	saved=R.migrate(R.copy(d),id)
	check(saved.crushers.bays==36,"bought row bays survive migration")
	local old=full();old.crushers.bays=36;old.crushers.plotLevel=nil
	old=R.migrate(old,id)
	check(old.crushers.plotLevel==0 and old.crushers.bays==24,"old saves do not get free expansion from capacity alone")
	check(not R.act(old,{},"Unlock",{},0,math.random,id,{}),"ordinary Unlock cannot bypass plot upgrade")
	check(Rows.snapshot(old).rows[5].unlocked==0,"unbought third floor has no row perk")
	-- Factory III to V: fill every bay, upgrade
	local function fill(p,a,b)
		for i=a,b do
			local item={id=id(),type="Bumper",rarity="Common",modifier="Standard",level=1}
			table.insert(p.crushers.owned,item) p.crushers.equipped[tostring(i)]=item.id
		end
	end
	local f=full() f.cash=C.plotCost(1) check(P.expand(f),"Factory II")
	local ok,message=P.expand(f)
	check(not ok and message=="Fill all 36 bays before upgrading your plot.","Factory III needs all 36 bays filled")
	f.crushers.bays=36 fill(f,25,36) f.cash=C.plotCost(2)-1 before=f.cash
	check(P.full(f) and not P.expand(f) and f.cash==before,"Factory III unaffordable leaves profile unchanged")
	f.cash=C.plotCost(2)
	check(P.expand(f) and f.cash==0 and f.crushers.plotLevel==2 and f.crushers.bays==36,"Factory III opens the rear yard ground row")
	f.crushers.bays=48 fill(f,37,48) f.cash=C.plotCost(3)
	check(P.expand(f) and f.crushers.plotLevel==3 and f.crushers.bays==48,"Factory IV opens rear upper left")
	f.crushers.bays=54 fill(f,49,54) f.cash=C.plotCost(4)
	check(P.expand(f) and f.crushers.plotLevel==4 and f.crushers.bays==54,"Factory V opens rear upper right")
	f.crushers.bays=60
	ok,message=P.expand(f)
	check(not ok and message=="Your plot is fully expanded.","no plot upgrade after Factory V")
	check(R.migrate(R.copy(f),id).crushers.bays==60,"Factory V survives migration")
	check(C.plotCost(1)<C.plotCost(2) and C.plotCost(2)<C.plotCost(3) and C.plotCost(3)<C.plotCost(4),"each plot upgrade costs more")
	for bay=C.RearFirst,C.MaxBays do local layout=C.bayLayout(bay)
		check(layout.rear and layout.tier<=2 and layout.z==C.Layout.BayZ+C.Layout.RearShift-(layout.tier-1)*C.Layout.UpperBack,"rear yard banks: max two floors")
		check(math.abs(layout.x)-C.Layout.BayWidth/2>C.Layout.RoadHalf and math.abs(layout.x)+C.Layout.BayWidth/2<78,"rear yard bays clear the road and fit the plot width")
		check(C.bayFrame(layout)==CFrame.new(),"rear yard is not tilted")
	end
	check(C.rearStart(1,1)==37 and C.rearStart(1,2)==43 and C.rearStart(2,1)==49 and C.rearStart(2,2)==55,"rear yard numbering")
	check(C.bayName(37)=="Rear left 1" and C.bayName(55)=="Rear upper right 1","rear yard names")
	local rows=Rows.snapshot(f).rows
	check(rows[7].name=="REAR LEFT" and rows[10].name=="REAR UPPER RIGHT","rear yard rows")
	for bay=C.TopFirst,C.RearFirst-1 do local layout=C.bayLayout(bay)
		check(layout.tier==3 and layout.top and layout.y==2*C.Layout.TierHeight and layout.z==C.Layout.BayZ-2*C.Layout.UpperBack,"third floor steps back on top of the upper floor")
		local under=C.bayLayout(bay-C.floorStart(3,layout.wing)+C.floorStart(2,layout.wing))
		check(under.tier==2 and under.wing==layout.wing and under.x==layout.x,"each top bay sits above an upper bay")
	end
	check(C.floorStart(3,1)==25 and C.floorStart(3,2)==31 and C.bayName(25)=="Top left 1","top floor numbering")
	check(rows[5].name=="TOP LEFT" and rows[6].name=="TOP RIGHT","top floor rows")
	-- Layout v1 saves (middle rear row at 25-30) convert without losing crushers
	local function v1(level,equip)
		local p=fresh() p.crushers.layout=nil p.crushers.plotLevel=level p.crushers.owned={} p.crushers.equipped={}
		for _,i in equip do local item={id="v1-"..i,type="Bumper",rarity="Common",modifier="Standard",level=1}
			table.insert(p.crushers.owned,item) p.crushers.equipped[tostring(i)]=item.id end
		return R.migrate(p,id)
	end
	local m1=v1(1,{1,24,25,30})
	check(m1.crushers.layout==C.LayoutVersion and m1.crushers.plotLevel==1 and m1.crushers.bays==36,"v1 Factory II keeps its level, now 36 bays")
	check(m1.crushers.equipped["1"]=="v1-1" and m1.crushers.equipped["24"]=="v1-24","base bays unchanged")
	local placed={} for _,v in m1.crushers.equipped do placed[v]=true end
	check(placed["v1-25"] and placed["v1-30"],"rear row crushers stay equipped in free bays")
	local m2=v1(2,{25,26,27,28,29,30,31,36,37,42})
	check(m2.crushers.equipped["25"]=="v1-31" and m2.crushers.equipped["30"]=="v1-36" and m2.crushers.equipped["31"]=="v1-37" and m2.crushers.equipped["36"]=="v1-42","v1 third floor bays move to 25-36")
	placed={} for k,v in m2.crushers.equipped do placed[v]=tonumber(k) end
	for i=25,30 do check(placed["v1-"..i] and placed["v1-"..i]<=C.bayCapacity(2),"v1 rear row crushers land in a bay of the new level") end
	local m4=v1(4,{25,43,66})
	check(m4.crushers.equipped["37"]=="v1-43" and m4.crushers.equipped["60"]=="v1-66","v1 rear yard bays shift down by six")
	check(#m4.crushers.owned==3,"conversion never removes crushers")
	check(R.migrate(R.copy(m4),id).crushers.equipped["37"]=="v1-43","conversion runs once")
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
