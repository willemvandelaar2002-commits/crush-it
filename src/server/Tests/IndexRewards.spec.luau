--!strict
-- Run explicitly in Studio. Pure tables, no live profile.
return function()
	local C=require(game.ReplicatedStorage.Shared.CrusherConfig)
	local R=require(game.ReplicatedStorage.Shared.CrusherRules)
	local M=require(game.ReplicatedStorage.Shared.IndexRewards)
	local checks=0
	local function check(v,message) assert(v,message) checks+=1 end
	local n=0 local function id() n+=1 return "fx"..n end
	local d=R.migrate({cash=0},id) local s=d.crushers
	check(M.found(s)==1 and s.seen.Bumper==true,"the starter crusher counts as found")
	check(not M.ready(s,1),"5 needed for the first milestone")
	for i=1,9 do s.seen[C.Types[i+1].id]=true end
	check(M.found(s)==10 and M.ready(s,1) and M.ready(s,2) and not M.ready(s,3),"10 found: first two milestones ready")
	table.insert(s.indexClaimed,1) table.insert(s.indexClaimed,2)
	check(not M.ready(s,1) and M.next(s)==3,"claimed milestones can't be claimed again")
	check(math.abs(M.luck(s)-0.02)<1e-9,"milestone 2 gives +2% luck")
	-- recycling keeps found crushers; bad saved data is cleaned
	s.seen.NotAType=true table.insert(s.indexClaimed,2) table.insert(s.indexClaimed,"x")
	local again=R.migrate(d,id).crushers
	check(M.found(again)==10 and again.seen.NotAType==nil and #again.indexClaimed==2,"migrate keeps seen and claimed, drops junk")
	local plain,lucky=R.weights(0,false,0),R.weights(0,false,0.1)
	check(plain[1]==lucky[1] and math.abs(lucky[4]/plain[4]-1.1)<1e-9,"index luck boosts every rarity but Common")
	local total=0 for _,m in M.List do for _,r in m.rewards do if r.kind=="luck" then total+=r.percent end end end
	check(total==13 and M.List[#M.List].need<=#C.Types,"13% luck in total, every milestone reachable")
	return {passed=checks}
end
