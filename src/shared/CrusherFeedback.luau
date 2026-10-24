--!strict
-- Presentation budgets only. No production, prices, rewards or save data.
local F={
	Tag="ActiveCrusher",BatchInterval=.08,InterestDistance=170,MaxBatch=24,MaxServerQueue=256,
	FocusInterval=.2,AudioDistance=115,VisualDistance=95,AudioMachines=2,VisualMachines=4,
	ImpactGap=.25,MergeWindow=.055,LateTolerance=.25,MaxPending=16,
	ImpactVoices=2,ImpactLifetime=.38,HissGap=1.25,HissLifetime=.23,
	MaxBursts=4,ScrapPerBurst=4,MaxInputParts=24,ScrapLifetime=.48,
	SquashLead=.065,SquashTail=.055,GroupVolume=.65,DuckedVolume=.22,DuckSeconds=.8,
	AmbientVolume=.035,
}

function F.timing(cycle,special)
	local duration=math.min(.6,cycle*.7)
	return {duration=duration,hit=duration*(if special then .38 else .4),retract=duration*.48,up=duration*.52}
end

-- Stable tie-breaking stops equally distant machines swapping focus each scan.
function F.nearest(sources,position,count,distance)
	local ordered={}
	for _,source in sources do
		local delta=source.position-position local square=delta:Dot(delta)
		if square<=distance*distance then table.insert(ordered,{source=source,square=square,key=tostring(source.key or source.sequence or "")}) end
	end
	table.sort(ordered,function(a,b) return if a.square==b.square then a.key<b.key else a.square<b.square end)
	local out={} for i=1,math.min(count,#ordered) do table.insert(out,ordered[i].source) end return out
end

function F.newBudget() return {nextImpact=-math.huge,nextHiss=-math.huge} end
function F.takeImpact(budget,now)
	if now<budget.nextImpact then return false end
	budget.nextImpact=now+F.ImpactGap return true
end
function F.takeHiss(budget,now)
	if now<budget.nextHiss then return false end
	budget.nextHiss=now+F.HissGap return true
end
function F.fresh(impactAt,now) return impactAt>=now-F.LateTolerance and impactAt<=now+.65 end

-- Use one sample per impact; special voices replace, rather than layer over it.
local ENERGY={Thunder=true,Frost=true,Laser=true,Plasma=true,Quantum=true,Starforge=true,Magnetron=true}
local HEAVY={Titan=true,TwinTitan=true,Quake=true,Mecha=true,GoldenKing=true,Toyzilla=true,DragonJaw=true}
function F.voice(typeId)
	if ENERGY[typeId] then return "SparkHit",.22,1.05 end
	if HEAVY[typeId] then return "MetalHit",.28,.82 end
	return "Thud",.36,1
end

function F.spread(fraction) return 1+(1-fraction)*.35 end
function F.axisScale(fraction,up)
	up=math.abs(up)
	return (1+(fraction-1)*up)*(if up<.5 then F.spread(fraction) else 1)
end
return F
