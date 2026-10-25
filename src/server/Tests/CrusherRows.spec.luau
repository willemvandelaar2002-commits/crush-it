--!strict
-- Non-yielding economy fixtures. Never edits live data or place templates.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local Rows=require(game.ReplicatedStorage.Shared.CrusherRows)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local checks=0 local serial=0
	local function check(v,msg) checks+=1 assert(v,msg) end
	local function close(a,b,msg) check(math.abs(a-b)<math.max(.00001,math.abs(b)*1e-10),msg) end
	local function guid() serial+=1 return "row-fixture-"..serial end
	local function fresh()
		local d=R.migrate({cash=1e9},guid)
		d.crushers.owned={} d.crushers.equipped={} d.crushers.bays=C.MaxBays
		d.crushers.tutorial=#C.TutorialSteps+1
		return d
	end
	local function fill(d,row,rarity)
		local pool=C.rarity(rarity).types local items={}
		for n=1,C.Layout.PerWing do
			local item={id=guid(),type=pool[(n-1)%#pool+1],rarity=rarity,modifier=if n%2==0 then "Polished" else "Standard",level=n}
			table.insert(d.crushers.owned,item) table.insert(items,item)
			d.crushers.equipped[tostring((row-1)*C.Layout.PerWing+n)]=item.id
		end
		return items
	end
	check(Rows.count()==4 and C.Layout.PerWing==6,"four physical six-bay rows")
	for bay=1,C.MaxBays do local l=C.bayLayout(bay)
		check(Rows.index(bay)==(l.tier-1)*C.Layout.Wings+l.wing,"row matches wing/floor layout")
	end
	for _,rarity in C.Rarities do for row=1,Rows.count() do
		local d=fresh() local items=fill(d,row,rarity.name)
		local snapshot=Rows.snapshot(d) local result=snapshot.rows[row]
		check(result.active and result.matches==6 and result.rarity==rarity.name,"different types/levels/modifiers complete a rarity set")
		close(result.bonus,C.RowBonuses[rarity.name],"configured rarity bonus")
		for _,item in items do
			local base=R.stats(d,item,{mult=2},false) local boosted=R.stats(d,item,{mult=2})
			local rawValue=base.cps*(math.ceil(base.hp/base.damage)*base.cycle+C.InputDelay)
			close(boosted.value,C.money(rawValue*(1+result.bonus)),"resource boost multiplies once before currency rounding")
			close(boosted.cps,base.cps*(1+result.bonus),"display rate includes row")
			check(boosted.damage==base.damage and boosted.cycle==base.cycle and boosted.hp==base.hp,"row changes only yield")
		end
		for i,other in snapshot.rows do if i~=row then check(not other.active,"other rows get no bonus") end end
		local saved=R.copy(d) local oldId=items[1].id local oldLevel=items[1].level
		saved=R.migrate(saved,guid)
		check(Rows.snapshot(saved).rows[row].active and R.find(saved,oldId).level==oldLevel,"rejoin derives bonus without a saved upgrade flag")
		d.crushers.bays=result.last-1
		check(not Rows.snapshot(d).rows[row].active,"locked sixth bay does not qualify")
		d.crushers.bays=C.MaxBays
		d.crushers.equipped[tostring(result.last)]=nil
		check(not Rows.snapshot(d).rows[row].active,"missing member removes bonus immediately")
		d.crushers.equipped[tostring(result.last)]=items[6].id
		items[6].rarity=if rarity.name=="Common" then "Epic" else "Common"
		check(not Rows.snapshot(d).rows[row].active,"a mismatched saved rarity cannot fake a set")
	end end
	local d=fresh() local groups={}
	for row,rarity in {"Common","Rare","Epic","Legendary"} do groups[row]=fill(d,row,rarity) end
	local snapshot=Rows.snapshot(d)
	for row,items in groups do for _,item in items do
		close(R.stats(d,item).rowBonus,snapshot.rows[row].bonus,"four complete rows do not stack on each other")
	end end
	local loose={id=guid(),type="Titan",rarity="Epic",modifier="Standard",level=1}
	table.insert(d.crushers.owned,loose)
	check(R.stats(d,loose).rowBonus==0,"unequipped inventory gets no active-row multiplier")
	local first=groups[1][1]
	d.crushers.equipped["7"]=first.id
	check(not Rows.snapshot(d).rows[1].active and not Rows.snapshot(d).rows[2].active,"duplicate equipped IDs cannot activate either row")
	d.crushers.equipped["7"]="foreign-id"
	check(not Rows.snapshot(d).rows[2].active,"unknown ownership does not qualify")
	-- Completion ledger: no grant on activation; one boost per finished input.
	d=fresh() local machines=fill(d,1,"Epic") d.crushers.bays=6
	d.crushers.available=123.45 d.scrap=20 d.goldenRush=1
	d.crushers.upgrades.Damage=C.MaxGlobal
	for _,item in machines do item.level=C.MaxLevel end
	local expected=123.45
	for i,item in machines do local value=R.stats(d,item).value
		expected=C.money(expected+value*(if i==1 then C.GoldenYield else 1))
	end
	local session={} R.step(d,session,0,{})
	close(d.crushers.available,123.45,"activating a row does not award scrap")
	local events=R.step(d,session,C.InputDelay+.01,{}) local finished=0
	for _,event in events do if event.completed then finished+=1 end end
	check(finished==6 and d.goldenRush==0,"one completion per machine; Golden Rush consumed normally")
	close(d.crushers.available,expected,"actual ledger includes row and golden boost exactly once")
	R.step(d,session,C.InputDelay+.02,{}) close(d.crushers.available,expected,"repeated tick cannot duplicate earnings")
	R.act(d,session,"Unequip",{id=machines[6].id},2,math.random,guid,{})
	check(not Rows.snapshot(d).rows[1].active,"unequip transaction breaks set")
	close(d.crushers.available,expected,"breaking a set never recalculates banked resources")
	local cash=d.cash local total=C.money(expected+20)
	check(R.act(d,session,"Collect",{},3,math.random,guid,{}),"collect still works")
	close(d.scrap,total,"collection transfers boosted ledger without boosting it again")
	check(R.act(d,session,"Sell",{},3,math.random,guid,{}),"sell still works")
	close(d.cash,C.money(cash+total),"sale transfers scrap without a second row multiplier")
	-- A naive raw-output selection can break a valuable high-level row.
	d=fresh() machines=fill(d,1,"Epic") d.crushers.bays=6
	for i,item in machines do item.level=if i<=5 then C.MaxLevel else 1 end
	local outsider={id=guid(),type="Quantum",rarity="Legendary",modifier="Standard",level=1}
	table.insert(d.crushers.owned,outsider)
	local before=R.copy(d.crushers.equipped)
	local ok,message=R.act(d,{},"EquipBest",{},0,math.random,guid,{})
	check(not ok and message:find("row bonuses")~=nil,"Equip Best protects a better matching setup")
	for key,id in before do check(d.crushers.equipped[key]==id,"rejected selection is non-mutating") end
	check(not R.act(d,{},"ActivateRow",{row=1,rarity="Legendary"},0,math.random,guid,{}),"clients cannot claim a row perk")
	return {passed=checks}
end
