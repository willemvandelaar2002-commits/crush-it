--!strict
-- Pure event arithmetic / profile transactions, independent of Roblox services.
local E = require(script.Parent.FactoryEventConfig)
local R = {}
local function finite(n)
	return type(n)=="number" and n==n and math.abs(n)<math.huge
end
function R.grade(points)
	local grade=1
	for i,g in E.Grades do if points>=g.points then grade=i end end
	return grade
end
function R.snapshot(d, maxBays, rarityOf, stats)
	local owned={} local used={} local slots={} local points,output,count=0,0,0
	local dominant,rank="Common",0
	for _,item in d.crushers.owned do owned[item.id]=item end
	for bay=1,math.min(maxBays,d.crushers.bays) do
		local id=d.crushers.equipped[tostring(bay)] local item=owned[id]
		local rarity=item and rarityOf(item.type)
		if item and not used[id] and rarity and rarity.name==item.rarity and E.Points[rarity.name] then
			used[id]=true
			local s=stats(item) local rate=s and s.cps
			if finite(rate) and rate>=0 then
				count+=1 points+=E.Points[rarity.name]
				table.insert(slots,bay)
				output=math.min(1e290,output+math.min(rate,1e290))
				if E.Points[rarity.name]>rank then rank=E.Points[rarity.name] dominant=rarity.name end
			end
		end
	end
	return {count=count,points=points,grade=R.grade(points),dominant=dominant,cps=output,slots=slots,
		power=if count>0 then math.min(E.MaxPower,1+math.log10(1+output)) else 0}
end
function R.inside(localPosition)
	return math.abs(localPosition.X)<=E.PlotHalfWidth and localPosition.Z>=E.PlotRear
		and localPosition.Z<=E.PlotFront and localPosition.Y>=-8 and localPosition.Y<=E.PlotHeight
end
function R.onBeat(now,started)
	local t=(now-started)%E.Strike
	return t<=E.PulseWindow or t>=E.Strike-.15
end
function R.damage(power,pulsed)
	return power*E.Strike*(if pulsed then E.PulseMultiplier else 1)
end
function R.reward(cps)
	return math.floor(math.clamp((if finite(cps) then cps else 0)*E.RewardSeconds,E.MinReward,E.MaxReward))
end
function R.eligible(record)
	return record.hits>=E.MinimumHits and record.active>=E.MinimumActive
end
function R.migrate(d)
	local old=if type(d.factoryEvents)=="table" then d.factoryEvents else {}
	local ledger={} local seen={}
	for _,id in (if type(old.claimed)=="table" then old.claimed else {}) do
		if type(id)=="string" and #id<=96 and not seen[id] then
			seen[id]=true table.insert(ledger,id)
			if #ledger>=E.LedgerSize then break end
		end
	end
	d.factoryEvents={wins=if finite(old.wins) then math.clamp(math.floor(old.wins),0,1e9) else 0,claimed=ledger}
	return d.factoryEvents
end
function R.grant(d,roundId,record,money)
	-- No yields between checking the ledger, recording the ID and crediting cash.
	-- Reward and ledger are in the same player profile / DataService save.
	local s=R.migrate(d)
	if not R.eligible(record) or table.find(s.claimed,roundId) then return false,0 end
	local amount=R.reward(record.cps)
	table.insert(s.claimed,1,roundId)
	while #s.claimed>E.LedgerSize do table.remove(s.claimed) end
	s.wins+=1 d.cash=money(d.cash+amount)
	return true,amount
end
-- Preserve completion ratio when players leave. No healing or free damage.
function R.resize(hp,maxHp,newMax)
	if maxHp<=0 then return newMax,newMax end
	return math.clamp(hp/maxHp,0,1)*newMax,newMax
end
return R
