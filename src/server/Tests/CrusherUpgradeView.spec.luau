--!strict
-- Pure profile fixtures; never reads or writes a live player save.
return function()
	local S=game.ReplicatedStorage.Shared
	local C=require(S.CrusherConfig) local R=require(S.CrusherRules)
	local V=require(S.CrusherUpgradeView) local Format=require(S.Format)
	local checks=0 local serial=0
	local function check(ok,message) assert(ok,message) checks+=1 end
	local function guid() serial+=1 return "upgrade-view-"..serial end
	local function fresh() return R.migrate({cash=1e20},guid) end
	local function act(d,name,args) return R.act(d,{},name,args,10,function() return .5 end,guid,{}) end
	check(V.Boards.Production.scope=="ALL YOUR CRUSHERS" and V.Boards.Rolling.scope=="FUTURE ROLLS","board scopes")
	for _,t in C.Types do
		for _,level in {1,C.MaxLevel-1} do
			local d=fresh() local item=d.crushers.owned[1]
			item.type=t.id item.rarity=C.rarityOf(t.id).name item.level=level
			local duplicate=table.clone(item) duplicate.id=guid() table.insert(d.crushers.owned,duplicate)
			local cash=d.cash local old=R.stats(d,item) local other=R.stats(d,duplicate)
			local view=V.crusher(d,item,{})
			check(d.cash==cash and item.level==level and duplicate.level==level,"preview is read-only")
			check(act(d,"Level",{id=item.id}),"real level purchase succeeds")
			local after=R.stats(d,item)
			check(view.effect=="LV "..level.." > "..item.level.."\n"..Format.cash(old.cps*60).." > "..Format.cash(after.cps*60).."/min","preview matches purchased output")
			check(duplicate.level==level and R.stats(d,duplicate).cps==other.cps,"only selected instance levels")
		end
	end
	local d=fresh() local item=d.crushers.owned[1]
	item.level=C.MaxLevel local view=V.crusher(d,item,{})
	check(view.state=="Max" and view.button=="MAX\nLEVEL" and not view.effect:find(">"),"no fictional level past max")
	item.level=1 local cost=C.individualCost(item) d.cash=cost-.01
	check(V.crusher(d,item,{}).state=="Short","individual affordability below exact price")
	d.cash=cost check(V.crusher(d,item,{}).state=="Ready","individual affordability at exact price")
	for _,id in C.UpgradeOrder do
		d=fresh() local max=C.upgradeMax(id)
		for _,lv in {0,max-1,max} do
			d.crushers.upgrades[id]=lv local price=C.globalCost(id,lv) d.cash=price
			local before=R.copy(d.crushers.upgrades) local b=V.board(d,id,{})
			check(b.state==(if lv==max then "Max" else "Ready"),"board cap / exact affordability")
			for key,value in before do check(d.crushers.upgrades[key]==value,"board preview never mutates upgrades") end
			if lv<max then
				d.cash=price-.01 check(V.board(d,id,{}).state=="Short","board short of cash")
			else check(not b.effect:find(">"),"max displays current effect only") end
		end
	end
	d=fresh()
	check(V.board(d,"Speed",{}).effect=="Cycle 100% > 94%","speed shows duration rather than incorrect rate")
	check(V.board(d,"Pedestals",{}).effect=="1 > 2 choices / roll","pedestals describe offers, not free ownership")
	for _,lucky in {false,true} do
		for _,lv in {0,7,C.MaxGlobal-1} do
			d.crushers.upgrades.Luck=lv
			local function chance(level)
				local weights=R.weights(level,lucky) local all,common=0,weights[1]
				for _,w in weights do all+=w end return (all-common)/all*100
			end
			check(V.board(d,"Luck",{lucky=lucky}).effect==string.format("Uncommon+ %.1f%% > %.1f%%",chance(lv),chance(lv+1)),"luck uses normalised probabilities and pass")
		end
	end
	-- Production upgrades cover owned crushers even when not equipped.
	d=fresh() local first=d.crushers.owned[1] local second=table.clone(first) second.id=guid() table.insert(d.crushers.owned,second)
	local a,b=R.stats(d,first).damage,R.stats(d,second).damage
	check(act(d,"Upgrade",{id="Damage"}) and R.stats(d,first).damage>a and R.stats(d,second).damage>b,"factory scope includes unequipped instances")
	check(act(d,"Unequip",{id=first.id}),"fixture unequip")
	check(act(d,"Level",{id=first.id}),"fixture level")
	local level=first.level check(act(d,"Equip",{id=first.id,bay=1}) and first.level==level,"level remains attached after swapping")
	return checks
end
