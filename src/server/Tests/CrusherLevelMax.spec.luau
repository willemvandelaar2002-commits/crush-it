--!strict
-- Run explicitly in Studio. MAX on a bay plaque: as many levels as the cash covers.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local V=require(game.ReplicatedStorage.Shared.CrusherUpgradeView)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,name,args) return R.act(d,{},name,args,0,function() return .1 end,id,{}) end
	local function fresh(cash) local d=R.migrate({cash=cash},id) d.cash=cash return d,d.crushers.owned[1] end

	-- cash for exactly three levels, plus a bit less than the fourth
	local d,item=fresh(0)
	local three=0 for lv=1,3 do three+=C.individualCost({level=lv,rarity=item.rarity}) end
	d.cash=three+C.individualCost({level=4,rarity=item.rarity})-1
	local levels,total=R.maxLevels(d.cash,item)
	check(levels==3 and total==three,"maxLevels counts what the cash covers")
	local view=V.crusherMax(d,item)
	check(view.state=="Ready" and view.button=="MAX\n+3" and view.success=="CRUSHER +3!","view shows +3")
	local before=d.cash
	local ok,_,bought=act(d,"LevelMax",{id=item.id})
	check(ok and bought==3 and item.level==4 and d.cash==before-three,"LevelMax buys three levels and charges their sum")
	check(d.stats.levels==3,"quest counter counts every level")

	-- the same result as pressing LEVEL UP three times
	local e,other=fresh(before)
	for _=1,3 do act(e,"Level",{id=other.id}) end
	check(other.level==item.level and e.cash==d.cash,"same as three single LEVEL UPs")

	-- not enough for one level
	local short=V.crusherMax(d,item)
	check(short.state=="Short" and short.button=="MAX\n+0","short cash shows grey +0")
	before=d.cash
	check(not act(d,"LevelMax",{id=item.id}) and d.cash==before and item.level==4,"short cash buys nothing")

	-- stops at the level cap, never past it
	local rich,top=fresh(1e30)
	ok=act(rich,"LevelMax",{id=top.id})
	check(ok and top.level==C.MaxLevel,"stops at MaxLevel")
	check(V.crusherMax(rich,top).state=="Max" and not act(rich,"LevelMax",{id=top.id}),"maxed crusher refuses MAX")

	-- someone else's crusher
	before=rich.cash
	check(not act(rich,"LevelMax",{id="another-player-id"}) and rich.cash==before,"foreign crusher refused")
	return {passed=checks}
end
