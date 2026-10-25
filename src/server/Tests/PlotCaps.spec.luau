--!strict
-- Run explicitly in Studio. Factory II (plot level 1) raises the upgrade caps.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local V=require(game.ReplicatedStorage.Shared.CrusherUpgradeView)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,name,args) return R.act(d,{},name,args or {},0,function() return .1 end,id,{}) end
	local caps=C.PlotUpgrade.Caps[1]
	check(C.levelCap(0)==C.MaxLevel and C.levelCap(1)==caps.level and caps.level>C.MaxLevel,"crusher level cap rises with the plot")
	check(C.upgradeMax("Damage",0)==C.MaxGlobal and C.upgradeMax("Damage",1)==caps.global,"factory cap rises with the plot")
	check(C.upgradeMax("Pedestals",0)==C.upgradeMax("Pedestals",1),"pedestals keep their own max")

	-- before the plot upgrade: stuck at the base caps, with a hint
	local d=R.migrate({cash=1e30},id) d.cash=1e30
	local s=d.crushers local item=s.owned[1]
	item.level=C.MaxLevel s.upgrades.Damage=C.MaxGlobal
	local ok,message=act(d,"Level",{id=item.id})
	check(not ok and message:find("UPGRADE PLOT"),"base crusher cap points at the plot upgrade")
	check(not act(d,"LevelMax",{id=item.id}),"MAX respects the base cap")
	ok,message=act(d,"Upgrade",{id="Damage"})
	check(not ok and message:find("UPGRADE PLOT"),"base factory cap points at the plot upgrade")
	check(V.crusher(d,item,{}).state=="Max" and V.board(d,"Damage",{}).state=="Max","views show MAX before the plot upgrade")

	-- after: the same crusher and upgrade can go higher, up to the new caps
	s.plotLevel=1
	check(V.crusher(d,item,{}).state=="Ready" and V.board(d,"Damage",{}).state=="Ready","views open up after the plot upgrade")
	check(act(d,"Level",{id=item.id}) and item.level==C.MaxLevel+1,"crusher levels past the old cap")
	check(act(d,"LevelMax",{id=item.id}) and item.level==caps.level,"MAX stops at the new cap")
	ok,message=act(d,"Level",{id=item.id})
	check(not ok and message:find("UPGRADE PLOT"),"Factory II cap points at Factory III")
	s.plotLevel=2
	check(act(d,"LevelMax",{id=item.id}) and item.level==C.levelCap(2),"Factory III raises the cap again")
	ok,message=act(d,"Level",{id=item.id})
	check(not ok and message=="Maximum level reached.","final cap message")
	s.plotLevel=1
	for _=1,caps.global do act(d,"Upgrade",{id="Damage"}) end
	check(s.upgrades.Damage==caps.global,"factory upgrade stops at the new cap")

	-- saves above the base caps survive a reload
	item.level=caps.level
	local saved=R.migrate(d,id)
	check(saved.crushers.owned[1].level==caps.level and saved.crushers.upgrades.Damage==caps.global,"raised levels are kept on load")
	return {passed=checks}
end
