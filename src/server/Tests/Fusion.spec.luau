--!strict
-- Run explicitly in Studio. Fusion: main + three unequipped copies -> one fused crusher.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local n=0 local checks=0
	local function id() n+=1 return "fuse-"..n end
	local function check(v,message) assert(v,message) checks+=1 end
	local function act(d,args) return R.act(d,{},"Fuse",args,0,function() return .1 end,id,{}) end
	local function setup()
		local d=R.migrate({cash=0},id) local s=d.crushers
		s.plotLevel=C.Fusion.PlotLevel s.bays=C.bayCapacity(s.plotLevel)
		s.owned={} s.equipped={}
		local function add(type,level,modifier)
			local item={id=id(),type=type,rarity=C.rarityOf(type).name,modifier=modifier or "Standard",level=level or 1}
			table.insert(s.owned,item) return item
		end
		return d,s,add
	end
	-- happy path
	local d,s,add=setup()
	local main=add("Bumper",30,"Frost") s.equipped["1"]=main.id
	local a,b,c=add("Bumper",1),add("Bumper",2),add("Bumper",3)
	local spare=add("Bumper",9,"Polished")
	local other=add("Steel",1)
	local before=R.stats(d,main,{},false).value
	local copies,total=R.fusionCopies(d,main)
	check(total==4 and #copies==3 and copies[1]==a and copies[2]==b and copies[3]==c,"suggested copies: weakest unequipped first, best spare kept")
	local ok,_,result=act(d,{main=main.id,inputs={a.id,b.id,c.id}})
	check(ok and result==main and main.fused,"fuse succeeds and marks the main")
	check(main.level==30 and main.modifier=="Frost" and s.equipped["1"]==main.id,"main keeps level, coating and its bay")
	check(not R.find(d,a.id) and not R.find(d,b.id) and not R.find(d,c.id) and R.find(d,spare.id) and R.find(d,other.id),"exactly the three copies are used up")
	check(math.abs(R.stats(d,main,{},false).value-before*C.Fusion.Mult)<1e-6*before+0.02,"fused crusher makes 2x")
	local saved=R.migrate(R.copy(d),id)
	check(R.find(saved,main.id).fused==true and R.find(saved,spare.id).fused==nil,"fused flag is saved")
	check(not act(d,{main=main.id,inputs={spare.id}}),"a fused crusher can't fuse again")
	-- refusals change nothing
	local function refused(label,dd,args)
		local count=#dd.crushers.owned local okk=act(dd,args)
		check(not okk and #dd.crushers.owned==count,label)
	end
	d,s,add=setup() main=add("Bumper") a,b,c=add("Bumper"),add("Bumper"),add("Bumper")
	s.plotLevel=C.Fusion.PlotLevel-1
	refused("locked before Factory III",d,{main=main.id,inputs={a.id,b.id,c.id}})
	s.plotLevel=C.Fusion.PlotLevel
	s.equipped["2"]=a.id
	refused("equipped copies are never used up",d,{main=main.id,inputs={a.id,b.id,c.id}})
	s.equipped["2"]=nil
	local steel=add("Steel")
	refused("all four must be the same type",d,{main=main.id,inputs={a.id,b.id,steel.id}})
	refused("no duplicate ids",d,{main=main.id,inputs={a.id,a.id,b.id}})
	refused("main can't be its own input",d,{main=main.id,inputs={main.id,a.id,b.id}})
	refused("exactly three copies",d,{main=main.id,inputs={a.id,b.id}})
	refused("foreign ids",d,{main=main.id,inputs={a.id,b.id,"someone-else"}})
	refused("foreign main",d,{main="someone-else",inputs={a.id,b.id,c.id}})
	check(act(d,{main=main.id,inputs={a.id,b.id,c.id}}),"then a valid fuse still works")
	return {passed=checks}
end
