--!strict
-- Deterministic presentation checks. No live profile or audio asset required.
return function()
	local F=require(game.ReplicatedStorage.Shared.CrusherFeedback)
	local Config=require(game.ReplicatedStorage.Shared.Config)
	local checks=0
	local function check(ok,message) assert(ok,message) checks+=1 end
	local sources={} for i=1,20 do table.insert(sources,{key=string.format("%02d",i),position=Vector3.new(i*3,0,0)}) end
	local nearest=F.nearest(sources,Vector3.zero,F.AudioMachines,F.AudioDistance)
	check(#nearest==2 and nearest[1].key=="01" and nearest[2].key=="02","only the nearest two of twenty have audio focus")
	check(#F.nearest(sources,Vector3.zero,F.VisualMachines,F.VisualDistance)==4,"four nearby visual sources")
	check(#F.nearest(sources,Vector3.new(1000,0,0),2,F.AudioDistance)==0,"distant factories silent")
	local tie={{key="b",position=Vector3.new(-3,0,0)},{key="a",position=Vector3.new(3,0,0)}}
	check(F.nearest(tie,Vector3.zero,1,100)[1].key=="a","stable focus for equal distances")
	local capped=F.nearest(sources,Vector3.zero,7,100)
	check(#capped==7,"bounded network batches")
	local budget=F.newBudget() local accepted={}
	for i=0,10000 do local now=i*.001 if F.takeImpact(budget,now) then table.insert(accepted,now) end end
	for i,time in accepted do
		if i>1 then check(time-accepted[i-1]>=F.ImpactGap-1e-10,"hard minimum interval") end
		local count=0 for _,other in accepted do if other>=time and other<time+1-1e-10 then count+=1 end end
		check(count<=4,"no more than four impact starts in a rolling second")
	end
	budget=F.newBudget() local last=-math.huge
	for i=0,100 do local now=i*.1 if F.takeHiss(budget,now) then check(now-last>=F.HissGap,"occasional hisses only") last=now end end
	check(F.fresh(10,10.2) and not F.fresh(10,10.3) and not F.fresh(11,10),"drop stale and implausibly future pulses")
	for _,cycle in {.3,.4,1.4,1.8} do for _,special in {false,true} do
		local t=F.timing(cycle,special)
		check(t.hit>0 and t.hit<t.retract and t.retract<t.duration,"contact precedes hold and release")
		check(math.abs(t.retract+t.up-t.duration)<1e-8 and t.duration<cycle,"ram returns before its next strike")
	end end
	for _,before in {1,.75,.25,.07} do for _,after in {.75,.25,.07} do for _,up in {0,1,.70710678} do
		local ratio=F.axisScale(after,up)/F.axisScale(before,up)
		check(ratio>0 and ratio==ratio,"finite local squash transform")
		check(math.abs(F.axisScale(before,up)*ratio-F.axisScale(after,up))<1e-8,"snapshot scaling matches authoritative object formula")
	end end end
	for _,id in {"Bumper","Steel","Quantum","Toyzilla","Magnetron","Thunder","GoldenKing"} do
		local key,volume,pitch=F.voice(id)
		check(Config.Sounds[key]~=nil and volume<=.36 and pitch>0,"existing restrained sample palette")
		check(key~="BoomHit" and key~="BoomCrush","no repeating explosion samples")
	end
	check(F.MaxBursts*F.ScrapPerBurst==16 and F.ImpactVoices==2,"fixed voice and scrap pools")
	return checks
end
