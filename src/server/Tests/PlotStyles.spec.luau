--!strict
-- 11 Nov: PLOT STYLES rules (Shared/PlotStyles, CrusherRules SetStyle/BuyStyle/earnStyles).
-- Run explicitly in Studio. Pure tables, no live profile.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local S=require(game.ReplicatedStorage.Shared.PlotStyles)
	local checks=0
	local function check(v,message) assert(v,message) checks+=1 end
	local n=0 local function id() n+=1 return "ps"..n end
	local function rnd() return .5 end
	local d=R.migrate({cash=0},id) local s=d.crushers
	check(s.styles.active=="Classic" and next(s.styles.owned)==nil,"new players show Classic and own no style")
	check(S.cashMult(s)==1,"no style, no cash bonus")
	-- a full row of six Legendaries (bays 1-6) at FACTORY II: doesn't count yet
	local leg=C.rarity("Legendary")
	s.plotLevel=1 s.bays=C.bayCapacity(1)
	for i=1,6 do local it={id=id(),type=leg.types[(i-1)%#leg.types+1],rarity="Legendary",modifier="Standard",level=1} table.insert(s.owned,it) s.equipped[tostring(i)]=it.id end
	check(#R.earnStyles(d)==0,"earning counts from FACTORY III")
	s.plotLevel=2
	local got=R.earnStyles(d)
	check(#got==1 and got[1]=="Legendary" and s.styles.owned.Legendary and s.styles.active=="Legendary","a Legendary row earns LEGENDARY and puts it on (Classic before)")
	check(#R.earnStyles(d)==0,"earned once")
	check(math.abs(S.cashMult(s)-1.02)<1e-9,"LEGENDARY: +2% cash")
	-- one Epic in the row: no Exotic, nothing new
	local ex=C.rarity("Exotic")
	for i=1,5 do local it={id=id(),type=ex.types[1],rarity="Exotic",modifier="Standard",level=1} table.insert(s.owned,it) s.equipped[tostring(i)]=it.id end
	check(#R.earnStyles(d)==0,"one Legendary left in the row: the row is Legendary, not Exotic")
	local it={id=id(),type=ex.types[2],rarity="Exotic",modifier="Standard",level=1} table.insert(s.owned,it) s.equipped["6"]=it.id
	got=R.earnStyles(d)
	check(#got==1 and got[1]=="Exotic" and s.styles.active=="Legendary","an Exotic row earns EXOTIC; the style you chose stays on")
	check(math.abs(S.cashMult(s)-1.05)<1e-9,"styles add up: +2% +3%")
	-- switching
	check(R.act(d,{},"SetStyle",{id="Exotic"},0,rnd,id,{}),"switch to an owned style")
	check(s.styles.active=="Exotic","Exotic on")
	check(not R.act(d,{},"SetStyle",{id="Eternal"},0,rnd,id,{}),"a style you don't own can't be put on")
	check(not R.act(d,{},"SetStyle",{id="Nope"},0,rnd,id,{}),"unknown style refused")
	check(R.act(d,{},"SetStyle",{id="Classic"},0,rnd,id,{}) and s.styles.active=="Classic","Classic is always yours")
	check(not R.act(d,{},"BuyStyle",{id="Legendary"},0,rnd,id,{}),"earned styles can't be bought")
	-- kept through rebirth and save cleaning
	s.plotLevel=3 d.cash=C.rebirthCost(0)
	check(R.act(d,{},"Rebirth",{},0,rnd,id,{}),"rebirth")
	local again=R.migrate(d,id).crushers
	check(again.styles.owned.Legendary and again.styles.owned.Exotic and S.cashBonus(again.styles)>0.049,"styles kept through rebirth")
	check(S.open(again),"after a rebirth the board stays (you own styles)")
	again.styles.owned.Fake=true again.styles.active="Fake"
	local clean=R.migrate(d,id).crushers.styles
	check(clean.owned.Fake==nil and clean.active=="Classic","junk styles dropped, active falls back to Classic")
	-- bigger styles pay more
	local last=0 for _,st in S.List do if st.kind=="earned" then check(st.cash>last,st.id.." pays more than the one before") last=st.cash end end
	return {passed=checks}
end
