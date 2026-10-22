--!strict
-- Pure, non-yielding profile transactions; shared by server, previews and tests.
local C = require(script.Parent.CrusherConfig)
local R = {}
local function copy(v)
	if type(v) ~= "table" then return v end
	local out = {} for k,x in v do out[k] = copy(x) end return out
end
local function number(v, default, max)
	return if type(v) == "number" and v == v and math.abs(v) < math.huge then math.clamp(v,0,max or C.MaxMoney) else default
end
local function integer(v, default, max) return math.floor(number(v,default,max)) end
function R.find(d,id)
	for _,item in d.crushers.owned do if item.id == id then return item end end
end
function R.migrate(d, guid)
	d.cash = C.money(number(d.cash,C.StartCash))
	d.scrap = C.money(number(d.scrap,0))
	if d.crusherSchema ~= C.Schema or type(d.crushers) ~= "table" then
		d.legacyCrusherRecovery = d.legacyCrusherRecovery or { cash=d.cash, tier=d.tier, levels=copy(d.levels), rebirths=d.rebirths,
			helpers=copy(d.helpers), collection=copy(d.collection), scrap=d.scrap, smeltQueue=d.smeltQueue, smeltReady=d.smeltReady, smeltLv=d.smeltLv }
		local levels = if type(d.levels)=="table" then d.levels else {}
		local oldTier=integer(d.tier,1,13)
		local t=C.typeById(C.LegacyTypes[math.clamp(math.ceil(oldTier/2),1,#C.LegacyTypes)])
		local item={id=guid(),type=t.id,rarity=C.Rarities[math.clamp(math.ceil(oldTier/2)-1,1,#C.Rarities)].name,modifier="Standard",
			level=math.clamp(1+math.floor((number(levels.Power,0,50)+number(levels.Value,0,50))/2),1,C.MaxLevel)}
		local owned={item}
		for _,lv in (if type(d.helpers)=="table" then d.helpers else {}) do
			if #owned < C.MaxInventory and type(lv)=="number" then table.insert(owned,{id=guid(),type="Steel",rarity="Common",modifier="Rusty",level=math.clamp(integer(lv,1,C.MaxLevel),1,C.MaxLevel)}) end
		end
		local equipped={ ["1"]=item.id }
		local bays=math.min(C.MaxBays,#owned)
		for i=2,bays do equipped[tostring(i)]=owned[i].id end
		d.crushers={ owned=owned, equipped=equipped, bays=bays, available=0, tutorial=1, upgrades={
			Damage=integer(number(levels.Power,0,50)/2,0,C.MaxGlobal), Speed=integer(levels.Speed,0,C.MaxGlobal),
			Yield=integer(number(levels.Value,0,50)+number(d.rebirths,0,100),0,C.MaxGlobal), Luck=integer(d.rebirths,0,C.MaxGlobal), RollSpeed=0 } }
		d.scrap=C.money(d.scrap+number(d.smeltQueue,0)+number(d.smeltReady,0))
		d.smeltQueue=0 d.smeltReady=0 d.smeltRate=0 d.helpers={}
		d.crusherSchema=C.Schema
	end
	local s=d.crushers
	s.upgrades=if type(s.upgrades)=="table" then s.upgrades else {}
	for _,id in C.UpgradeOrder do s.upgrades[id]=integer(s.upgrades[id],0,C.MaxGlobal) end
	s.bays=math.clamp(integer(s.bays,1,C.MaxBays),1,C.MaxBays)
	s.available=C.money(number(s.available,0)) s.tutorial=math.clamp(integer(s.tutorial,1,#C.Tutorial),1,#C.Tutorial)
	s.rollReadyAt=number(s.rollReadyAt,0,1e12)
	local owned,ids={},{}
	for _,v in (if type(s.owned)=="table" then s.owned else {}) do
		if type(v)=="table" and C.typeById(v.type) and C.rarity(v.rarity) and C.modifier(v.modifier) and #owned<C.MaxInventory then
			local id=if type(v.id)=="string" and #v.id<=64 and #v.id>0 and not ids[v.id] then v.id else guid()
			ids[id]=true table.insert(owned,{id=id,type=v.type,rarity=v.rarity,modifier=v.modifier,level=math.clamp(integer(v.level,1,C.MaxLevel),1,C.MaxLevel)})
		end
	end
	if #owned==0 then local id=guid() table.insert(owned,{id=id,type="Bumper",rarity="Common",modifier="Standard",level=1}) ids[id]=true end
	s.owned=owned
	local equipped,used={},{} local old=if type(s.equipped)=="table" then s.equipped else {}
	for i=1,s.bays do local id=old[tostring(i)] if ids[id] and not used[id] then equipped[tostring(i)]=id used[id]=true end end
	if next(equipped)==nil then equipped["1"]=owned[1].id end
	s.equipped=equipped
	d.purchases=if type(d.purchases)=="table" then d.purchases else {}
	d.daily=if type(d.daily)=="table" then d.daily else {day=0,streak=0}
	d.goldenRush=integer(d.goldenRush,0,100000) d.crushed=integer(d.crushed,0,C.MaxMoney)
	d.tier=integer(d.tier,1,13) d.rebirths=integer(d.rebirths,0,10000)
	return d
end
function R.stats(d,item,perks)
	perks=perks or {}
	local s=d.crushers local t=C.typeById(item.type)
	local damage=t.damage*C.LevelDamage^(item.level-1)*C.DamageFactor^s.upgrades.Damage*(if perks.autoCrush then C.AutoCrushDamage else 1)
	local cycle=t.cycle*C.SpeedFactor^s.upgrades.Speed
	local value=t.value*C.LevelYield^(item.level-1)*(1+C.YieldPerLevel*s.upgrades.Yield)*C.rarity(item.rarity).mult*C.modifier(item.modifier).mult*(perks.mult or 1)
	return {damage=damage,cycle=cycle,hp=t.hp,value=C.money(value),cps=value/(math.ceil(t.hp/damage)*cycle+C.InputDelay)}
end
function R.weights(luck,lucky)
	local out={} for i,v in C.Rarities do out[i]=v.weight*(1+C.LuckPerLevel*luck*v.rank)*(if lucky and v.rank>0 then 2 else 1) end return out
end
local function choose(weights, random)
	local total=0 for _,w in weights do total+=w end
	local target=random()*total local n=0 for i,w in weights do n+=w if target<n then return i end end return #weights
end
function R.act(d,session,action,args,now,random,guid,perks)
	local s=d.crushers args=if type(args)=="table" then args else {}
	local function pay(cost) if d.cash<cost then return false end d.cash=C.money(d.cash-cost) return true end
	if action=="Roll" then
		if now<(session.nextRoll or 0) then return false,"Roll is cooling down." end
		if #s.owned>=C.MaxInventory then return false,"Crusher inventory is full. No cash was charged." end
		if not pay(C.RollCost) then return false,"Need $"..C.RollCost..". Collect and sell scrap first." end
		local rarity=C.Rarities[choose(R.weights(s.upgrades.Luck,perks and perks.lucky),random)]
		local weights={} for i,v in C.Modifiers do weights[i]=v.weight end
		local mod=C.Modifiers[choose(weights,random)]
		local item={id=guid(),type=rarity.types[math.min(#rarity.types,math.floor(random()*#rarity.types)+1)],rarity=rarity.name,modifier=mod.name,level=1}
		table.insert(s.owned,item) session.lastRoll=item.id session.nextRoll=now+C.rollSeconds(s.upgrades.RollSpeed)
		if s.tutorial==3 then s.tutorial=4 end
		return true,"Rolled "..C.typeById(item.type).name,item
	elseif action=="Equip" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		local bay=args.bay
		if bay==nil then for i=1,s.bays do if not s.equipped[tostring(i)] then bay=i break end end end
		if type(bay)~="number" or bay~=bay or bay%1~=0 or bay<1 or bay>s.bays then return false,"No usable bay. Unequip a crusher or unlock another bay." end
		for key,id in s.equipped do if id==item.id then s.equipped[key]=nil end end
		s.equipped[tostring(bay)]=item.id
		if s.tutorial==4 then s.tutorial=5 end
	elseif action=="Unequip" then
		if not R.find(d,args.id) then return false,"You do not own that crusher." end
		for key,id in s.equipped do if id==args.id then s.equipped[key]=nil end end
	elseif action=="Level" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		if item.level>=C.MaxLevel then return false,"Crusher is at maximum level." end
		if not pay(C.individualCost(item)) then return false,"Not enough cash. Collect and sell scrap." end
		item.level+=1 if s.tutorial==7 then s.tutorial=8 end
	elseif action=="Upgrade" then
		local u=C.Upgrades[args.id] if not u then return false,"Unknown upgrade." end
		local lv=s.upgrades[args.id] if lv>=C.MaxGlobal then return false,"Upgrade is at maximum level." end
		if not pay(C.globalCost(args.id,lv)) then return false,"Not enough cash. Collect and sell scrap." end
		s.upgrades[args.id]+=1
		if s.tutorial==5 and u.group=="Production" then s.tutorial=6 elseif s.tutorial==6 and u.group=="Rolling" then s.tutorial=7 end
	elseif action=="Unlock" then
		if s.bays>=C.MaxBays then return false,"All bays are unlocked." end
		if not pay(C.BayCosts[s.bays+1]) then return false,"Not enough cash for another bay. Collect and sell." end s.bays+=1
	elseif action=="Collect" then
		if s.available<=0 then return false,"No finished scrap yet. Your crushers are working." end
		d.scrap=C.money(d.scrap+s.available) s.available=0 if s.tutorial==1 then s.tutorial=2 end
	elseif action=="Sell" then
		if d.scrap<=0 then return false,"Collect scrap from the blue bin first." end
		d.cash=C.money(d.cash+d.scrap) d.scrap=0 if s.tutorial==2 then s.tutorial=3 end
	else return false,"Unknown factory action." end
	return true,"Done!"
end
function R.step(d,session,now,perks)
	local events={} session.bays=session.bays or {}
	for i=1,C.MaxBays do
		local key=tostring(i) local id=d.crushers.equipped[key] local item=id and R.find(d,id)
		local r=session.bays[i]
		if not item then session.bays[i]=nil continue end
		local stats=R.stats(d,item,perks)
		if not r or r.id~=id then r={id=id,hp=stats.hp,nextStrike=now+C.InputDelay} session.bays[i]=r table.insert(events,{bay=i,kind="Input",hp=r.hp}) end
		if now>=r.nextStrike then
			if r.hp<=0 then r.hp=stats.hp r.nextStrike=now+C.InputDelay table.insert(events,{bay=i,kind="Input",hp=r.hp})
			else
				r.hp=math.max(0,r.hp-stats.damage) r.nextStrike=now+stats.cycle
				local completed=r.hp<=0
				if completed then
					local value=stats.value
					if d.goldenRush>0 then d.goldenRush-=1 value*=C.GoldenYield end
					d.crushers.available=C.money(d.crushers.available+value) d.crushed+=1
				end
				table.insert(events,{bay=i,kind="Strike",fraction=math.max(0.07,r.hp/stats.hp),completed=completed,cycle=stats.cycle})
			end
		end
	end
	return events
end
R.copy=copy
return R
