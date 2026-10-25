--!strict
-- Run explicitly in Studio. RECYCLE DUPES in the Owned view.
return function()
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local n=0 local checks=0
	local function id() n+=1 return "fixture-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,name,args) return R.act(d,{},name,args or {},0,function() return .1 end,id,{}) end
	local d=R.migrate({cash=0},id)
	local s=d.crushers local starter=s.owned[1]
	local function add(type,rarity,level,modifier)
		local item={id=id(),type=type,rarity=rarity,modifier=modifier or "Standard",level=level}
		table.insert(s.owned,item) return item
	end
	-- three more copies of the starter type; one stronger, unequipped
	local strong=add(starter.type,starter.rarity,9)
	local weak1=add(starter.type,starter.rarity,1)
	local weak2=add(starter.type,starter.rarity,2)
	-- a different type with two copies, none equipped: the stronger stays
	local other=s.owned[1].type=="Steel" and "Bumper" or "Steel"
	local keepOther=add(other,"Common",5)
	local dropOther=add(other,"Common",3)
	-- a single copy of a third type stays
	local only=add("Cobalt","Uncommon",1)

	local extras=R.duplicateExtras(s.owned,s.equipped,function(item) return R.stats(d,item,{}).cps end)
	local set={} for _,item in extras do set[item.id]=true end
	check(#extras==3,"three extras")
	check(not set[starter.id],"equipped copy is kept")
	check(not set[strong.id],"the strongest copy is kept even when not equipped")
	check(set[weak1.id] and set[weak2.id],"weaker unequipped copies go")
	check(not set[keepOther.id] and set[dropOther.id],"no copy equipped: strongest stays")
	check(not set[only.id],"single copies stay")

	local before=#s.owned
	local ok,_,count=act(d,"RecycleDuplicates")
	check(ok and count==3 and #s.owned==before-3,"recycles all three in one go")
	check(R.find(d,starter.id) and R.find(d,strong.id) and R.find(d,keepOther.id) and R.find(d,only.id),"kept crushers still owned")
	check(s.equipped["1"]==starter.id,"equipment unchanged")
	check(not act(d,"RecycleDuplicates"),"nothing left to recycle")
	return {passed=checks}
end
