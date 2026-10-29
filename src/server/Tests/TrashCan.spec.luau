--!strict
-- Run explicitly in Studio. Pure tables, no live profile.
return function()
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local checks=0
	local function check(v,message) assert(v,message) checks+=1 end
	local n=0 local function id() n+=1 return "tc"..n end
	local d=R.migrate({cash=0},id) local s=d.crushers local starter=s.owned[1]
	for i=1,3 do table.insert(s.owned,{id="c"..i,type="Steel",rarity="Common",modifier="Standard",level=1}) end
	local function act(args) return R.act(d,{},"TrashMany",args,0,function() return .5 end,id,{}) end
	check(not act({ids={}}),"nothing picked")
	check(not act({ids={starter.id}}),"equipped crushers are kept")
	local ok,_,gone=act({ids={"c1","c2","c3",starter.id,"nope"}})
	check(ok and gone==3 and #s.owned==1 and s.owned[1].id==starter.id,"trash every picked unequipped crusher, even the last Steel")
	check(s.seen.Steel==true,"the Index still remembers Steel")
	s.equipped={} check(not act({ids={starter.id}}) and #s.owned==1,"never trash the very last crusher")
	return {passed=checks}
end
