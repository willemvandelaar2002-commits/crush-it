--!strict
return function()
	local Shared=game.ReplicatedStorage.Shared
	local S=require(Shared.DailySpinConfig) local R=require(Shared.DailySpinRules)
	local C=require(Shared.CrusherConfig) local Profiles=require(Shared.CrusherRules)
	local count=0 local serial=0
	local function guid() serial+=1 return "spin-test-"..serial end
	local function check(ok,msg) count+=1 assert(ok,msg) end
	local function fresh() return Profiles.migrate({cash=100},guid) end
	local cumulative=0 local total=0 local seen={}
	for _,def in S.Rewards do total+=def.weight end
	for index,def in S.Rewards do
		check(def.sector==index-1 and not seen[def.sector],"explicit unique clockwise sectors") seen[def.sector]=true
		local randomValue=(cumulative+def.weight/2)/total cumulative+=def.weight
		check(R.choose(function() return randomValue end).id==def.id,"weighted server outcome")
		check(math.abs(S.odds(def.id)-def.weight/total*100)<1e-8,"odds from weights")
		for _,angle in {-1080,-.5,0,45,359.9,360,9999.25} do
			local target=S.target(angle,def.sector)
			check(target-angle>=360*S.Revolutions,"forward full revolutions")
			check(math.abs((target+45*def.sector)%360)<.001,"sector centre under pointer")
			local again=S.target(target%360,def.sector)
			check(again>=target%360+360*S.Revolutions,"repeated spins")
		end
		local d=fresh() local cash=d.cash local golden=d.goldenRush local owned=#d.crushers.owned
		local ok,out=R.reserve(d,1000,2,function() return randomValue end,guid)
		check(ok and out.id==def.id and d.cash==cash and #d.crushers.owned==owned,"reservation never grants")
		check(d.dailySpin.nextAt==1000+86400,"24 hours from accepted spin")
		check(not R.reserve(d,1000,2,math.random,guid),"parallel/repeated reservation rejected")
		-- Crash after reservation save: reload the same selected prize, not a reroll.
		d=Profiles.migrate(Profiles.copy(d),guid)
		check(d.dailySpin.pending.id==def.id,"pending survives rejoin")
		local granted,prize=R.deliver(d)
		check(granted and prize.token==out.token and d.dailySpin.claims==1,"exactly one delivery")
		check(not R.deliver(d),"duplicate delivery rejected")
		if def.kind=="cash" then check(d.cash==cash+2*def.seconds,"existing cash balance")
		elseif def.kind=="golden" then check(d.goldenRush==golden+def.count,"existing Golden Rush balance")
		else check(#d.crushers.owned==owned+1 and d.crushers.owned[#d.crushers.owned].rarity==def.rarity,"existing inventory reward") end
		-- Crash after delivery save: pending is cleared atomically with the reward.
		d=Profiles.migrate(Profiles.copy(d),guid)
		check(not d.dailySpin.pending and not R.deliver(d),"saved delivery cannot replay")
		check(not R.reserve(d,1000+86399,2,math.random,guid),"persisted cooldown prevents early rejoin spin")
		check(R.reserve(d,1000+86400,2,function() return randomValue end,guid),"exact cooldown boundary eligible")
	end
	local full=fresh() for i=2,C.MaxInventory do local item=table.clone(full.crushers.owned[1]) item.id=guid() table.insert(full.crushers.owned,item) end
	check(not R.reserve(full,1000,1,math.random,guid) and full.dailySpin.nextAt==0,"full inventory never consumes a spin")
	local d=fresh() local n=0
	R.reserve(d,1000,1,function() n+=1 return if n==1 then .83 else .1 end,guid)
	check(d.dailySpin.pending.kind=="crusher","capacity-race fixture")
	for i=2,C.MaxInventory do local item=table.clone(d.crushers.owned[1]) item.id=guid() table.insert(d.crushers.owned,item) end
	local token=d.dailySpin.pending.token
	check(not R.deliver(d) and d.dailySpin.pending.token==token,"late full inventory reserves selected crusher")
	table.remove(d.crushers.owned)
	check(R.deliver(d) and #d.crushers.owned==C.MaxInventory,"reserved crusher delivered after freeing space")
	check(S.PaidProductId==0,"paid spins unconfigured")
	for _,size in {Vector2.new(1920,1080),Vector2.new(1280,720),Vector2.new(1024,640),Vector2.new(900,600)} do
		local factor=S.desktopScale(size.X,size.Y)
		check(920*factor<=size.X-40+.01 and 640*factor<=size.Y-65+.01,"desktop panel stays within viewport margins")
		check(factor>0 and factor<=1,"desktop never scales artwork above its design size")
	end
	return {passed=count}
end
