--!strict
-- Pure profile operations. A persisted pending prize is an outbox: apply once
-- without yielding, then save reward and cleared pending together.
local S=require(script.Parent.DailySpinConfig)
local C=require(script.Parent.CrusherConfig)
local R={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function prize(raw)
	if type(raw)~="table" or type(raw.token)~="string" or #raw.token>64 then return nil end
	local def=S.reward(raw.id) if not def then return nil end
	local out={token=raw.token,id=def.id,sector=def.sector,kind=def.kind}
	if def.kind=="crusher" then
		local item=raw.item
		if type(item)~="table" or type(item.id)~="string" or #item.id>64 or not table.find(C.rarity(def.rarity).types,item.type) then return nil end
		out.item={id=item.id,type=item.type,rarity=def.rarity,modifier="Standard",level=1}
	elseif def.kind=="boost" then
		out.boost=def.boost out.amount=def.minutes
	else
		if not finite(raw.amount) or raw.amount<=0 then return nil end
		out.amount=math.min(C.MaxMoney,raw.amount)
	end
	return out
end
function R.migrate(raw)
	raw=if type(raw)=="table" then raw else {}
	return {nextAt=if finite(raw.nextAt) then math.clamp(raw.nextAt,0,1e12) else 0,
		claims=if finite(raw.claims) then math.clamp(math.floor(raw.claims),0,1e12) else 0,
		pending=prize(raw.pending),last=prize(raw.last)}
end
function R.choose(random)
	local total=0 for _,r in S.Rewards do total+=r.weight end
	local x=random()*total
	for _,r in S.Rewards do x-=r.weight if x<0 then return r end end
	return S.Rewards[#S.Rewards]
end
function R.reserve(d,now,cps,random,guid)
	local state=d.dailySpin
	if state.pending then return false,"Your selected prize is waiting to be delivered." end
	if now<state.nextAt then return false,"Your next free spin is not ready yet." end
	if #d.crushers.owned>=C.MaxInventory then return false,"Make one space in your crusher inventory before spinning." end
	local def=R.choose(random)
	local out={id=def.id,sector=def.sector,kind=def.kind,token=guid()}
	if def.kind=="crusher" then
		local pool=C.rarity(def.rarity).types
		out.item={id=guid(),type=pool[math.min(#pool,math.floor(random()*#pool)+1)],rarity=def.rarity,modifier="Standard",level=1}
	elseif def.kind=="boost" then out.boost=def.boost out.amount=def.minutes -- granted by the server (Boosts.add)
	else out.amount=if def.kind=="golden" then def.count else C.money(math.max(1,cps)*def.seconds) end
	state.nextAt=now+S.Cooldown state.pending=out
	return true,out
end
function R.deliver(d)
	local state=d.dailySpin local out=state.pending
	if not out then return false,"No pending reward." end
	if out.kind=="crusher" then
		-- A purchase can fill the last slot while the reservation save yields.
		if #d.crushers.owned>=C.MaxInventory then return false,"Your crusher prize is reserved. Make inventory space and reopen Daily Spin." end
		table.insert(d.crushers.owned,table.clone(out.item))
	elseif out.kind=="golden" then d.goldenRush=math.min(100000,(d.goldenRush or 0)+out.amount) -- older saved prizes
	elseif out.kind=="boost" then -- nothing here: the server adds the boost time after this
	else d.cash=C.money(d.cash+out.amount) end
	state.pending=nil state.last=out state.claims+=1
	return true,out
end
return R
