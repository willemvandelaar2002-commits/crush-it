--!strict
-- Pure, non-yielding profile transactions; shared by server, previews and tests.
local C = require(script.Parent.CrusherConfig)
local Rows = require(script.Parent.CrusherRows)
local Progression = require(script.Parent.FactoryProgression)
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
-- Duplicates that RECYCLE DUPES removes: every equipped copy stays, and so
-- does the strongest copy of each type (score, then level, then id), equipped
-- or not, so a better roll you haven't equipped yet is never thrown away.
-- score(item) gives a crusher's output; the server and client pass their own.
function R.duplicateExtras(owned,equipped,score)
	local busy={} for _,id in equipped do busy[id]=true end
	local best={}
	for _,item in owned do
		local keep=best[item.type]
		if not keep then best[item.type]=item else
			local a,b=score(item),score(keep)
			if a>b or (a==b and (item.level>keep.level or (item.level==keep.level and item.id<keep.id))) then best[item.type]=item end
		end
	end
	local extras={}
	for _,item in owned do if best[item.type]~=item and not busy[item.id] then table.insert(extras,item) end end
	return extras
end
-- Fusion check, shared by the server action and the fuser screen. inputs are
-- the ids of the copies that get used up. Returns main or nil, problem.
function R.fusionProblem(d,mainId,inputs)
	local s=d.crushers
	if (tonumber(s.plotLevel) or 0)<C.Fusion.PlotLevel then return nil,"Upgrade to Factory III to unlock fusion." end
	local main=R.find(d,mainId) if not main then return nil,"Choose one of your crushers first." end
	if main.fused then return nil,"This crusher is already fused." end
	if type(inputs)~="table" or #inputs~=C.Fusion.Copies then return nil,"Pick "..C.Fusion.Copies.." copies of the same crusher." end
	local busy={} for _,id in s.equipped do busy[id]=true end
	local seen={[main.id]=true}
	for _,id in inputs do
		local item=type(id)=="string" and R.find(d,id)
		if not item or seen[id] then return nil,"Pick "..C.Fusion.Copies.." different copies you own." end
		seen[id]=true
		if item.type~=main.type then return nil,"All four must be the same crusher." end
		if item.fused then return nil,"Fused crushers can't be used up." end
		if busy[id] then return nil,"Unequip the copies first. Equipped crushers are never used up." end
	end
	return main
end
-- Copies fusion would use for this main: unequipped, unfused, same type,
-- weakest first (lowest level, uncoated first), so the best ones stay.
function R.fusionCopies(d,main)
	local busy={} for _,id in d.crushers.equipped do busy[id]=true end
	local list={}
	for _,item in d.crushers.owned do
		if item.id~=main.id and item.type==main.type and not item.fused and not busy[item.id] then table.insert(list,item) end
	end
	table.sort(list,function(a,b)
		local ma,mb=C.modifier(a.modifier).mult,C.modifier(b.modifier).mult
		if a.level~=b.level then return a.level<b.level end
		if ma~=mb then return ma<mb end
		return a.id<b.id
	end)
	local out={} for i=1,math.min(C.Fusion.Copies,#list) do out[i]=list[i] end
	return out,#list
end
-- Message at a cap: points at the plot upgrade while it can still raise caps.
function R.capMessage(plotLevel)
	if (plotLevel or 0)<C.PlotUpgrade.MaxLevel then return "Maximum level for now. UPGRADE PLOT raises the cap." end
	return "Maximum level reached."
end
-- How many levels this crusher can buy in a row with this much cash, and
-- what they cost together. Stops at cap (the plot's level cap). Used by MAX on the plaque.
function R.maxLevels(cash,item,cap)
	cap=cap or C.MaxLevel
	local n,total,level=0,0,item.level
	while level<cap do
		local cost=C.individualCost({level=level,rarity=item.rarity})
		if total+cost>cash then break end
		total+=cost level+=1 n+=1
	end
	return n,total
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
		local item={id=guid(),type=t.id,rarity=C.Rarities[math.clamp(math.ceil(oldTier/2)-1,1,#C.Rarities-1)].name,modifier="Standard",
			level=math.clamp(1+math.floor((number(levels.Power,0,50)+number(levels.Value,0,50))/2),1,C.topLevelCap())}
		local owned={item}
		for _,lv in (if type(d.helpers)=="table" then d.helpers else {}) do
			if #owned < C.MaxInventory and type(lv)=="number" then table.insert(owned,{id=guid(),type="Steel",rarity="Common",modifier="Rusty",level=math.clamp(integer(lv,1,C.topLevelCap()),1,C.topLevelCap())}) end
		end
		local equipped={ ["1"]=item.id }
		local bays=math.min(C.MaxBays,#owned)
		for i=2,bays do equipped[tostring(i)]=owned[i].id end
		d.crushers={ owned=owned, equipped=equipped, bays=bays, available=0, tutorial=1, upgrades={
			Damage=integer(number(levels.Power,0,50)/2,0,C.MaxGlobal), Speed=integer(levels.Speed,0,C.MaxGlobal),
			Yield=integer(number(levels.Value,0,50)+number(d.rebirths,0,100),0,C.MaxGlobal), Luck=integer(d.rebirths,0,C.MaxGlobal), Pedestals=0 } }
		d.scrap=C.money(d.scrap+number(d.smeltQueue,0)+number(d.smeltReady,0))
		d.smeltQueue=0 d.smeltReady=0 d.smeltRate=0 d.helpers={}
		d.crusherSchema=C.Schema
	end
	local s=d.crushers
	-- Bay layout v2 (25 Oct): the middle rear row is gone. v1 numbering: 25-30
	-- rear row, 31-42 third floor, 43-66 rear yard; v2: 25-36 third floor, 37-60
	-- rear yard. Equipped crushers move with their bay; rear-row crushers go to
	-- the first free bay of the new plot level, otherwise back to the inventory.
	-- Plot levels keep their number (v1 30/42/54/66 bays -> v2 36/48/54/60).
	if (tonumber(s.layout) or 1)<2 and type(s.equipped)=="table" then
		local moved,rowItems={},{}
		for key,id in s.equipped do local i=tonumber(key)
			if i and i==math.floor(i) then
				if i>=1 and i<=C.BaseMaxBays then moved[tostring(i)]=id
				elseif i>C.BaseMaxBays and i<=C.BaseMaxBays+6 then table.insert(rowItems,{i=i,id=id})
				elseif i>C.BaseMaxBays+6 and i<=C.MaxBays+6 then moved[tostring(i-6)]=id end
			end
		end
		table.sort(rowItems,function(a,b) return a.i<b.i end)
		local cap=C.bayCapacity(integer(s.plotLevel,0,C.PlotUpgrade.MaxLevel))
		for _,r in rowItems do for b=1,cap do if moved[tostring(b)]==nil then moved[tostring(b)]=r.id break end end end
		s.equipped=moved
	end
	s.layout=C.LayoutVersion
	s.upgrades=if type(s.upgrades)=="table" then s.upgrades else {}
	s.upgrades.RollSpeed=nil -- retired upgrade (rolling speed became pedestals)
	for _,id in C.UpgradeOrder do s.upgrades[id]=integer(s.upgrades[id],0,C.topUpgradeMax(id)) end
	s.plotLevel=integer(s.plotLevel,0,C.PlotUpgrade.MaxLevel)
	s.bays=math.clamp(integer(s.bays,1,C.MaxBays),1,C.bayCapacity(s.plotLevel))
	if s.plotLevel>=1 then s.bays=C.bayCapacity(s.plotLevel) end -- the paid expansion includes its whole row
	s.available=C.money(number(s.available,0)) s.tutorial=math.clamp(integer(s.tutorial,1,#C.TutorialSteps+1),1,#C.TutorialSteps+1) -- #steps+1 = finished
	s.rollReadyAt=number(s.rollReadyAt,0,1e12)
	s.rolls=integer(s.rolls,0,1e9) -- rolls made (the first one is always cheap)
	local owned,ids={},{}
	for _,v in (if type(s.owned)=="table" then s.owned else {}) do
		if type(v)=="table" and C.typeById(v.type) and C.rarity(v.rarity) and C.modifier(v.modifier) and (#owned<C.MaxInventory or C.rarity(v.rarity).exclusive) then
			local id=if type(v.id)=="string" and #v.id<=64 and #v.id>0 and not ids[v.id] then v.id else guid()
			ids[id]=true table.insert(owned,{id=id,type=v.type,rarity=v.rarity,modifier=v.modifier,level=math.clamp(integer(v.level,1,C.topLevelCap()),1,C.topLevelCap()),
				fused=if v.fused==true then true else nil})
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
	d.dailySpin=require(script.Parent.DailySpinRules).migrate(d.dailySpin)
	require(script.Parent.QuestRules).migrate(d) -- quest tokens, quest lists, stat counters
	d.timeSkipAt=number(d.timeSkipAt,0,1e12) -- next free time skip (server time)
	d.goldenRush=integer(d.goldenRush,0,100000) d.crushed=integer(d.crushed,0,C.MaxMoney)
	d.tier=integer(d.tier,1,13) d.rebirths=integer(d.rebirths,0,10000)
	return d
end
function R.stats(d,item,perks,rows)
	perks=perks or {}
	local s=d.crushers local t=C.typeById(item.type)
	local damage=t.damage*C.LevelDamage^(item.level-1)*C.DamageFactor^s.upgrades.Damage*(if perks.autoCrush then C.AutoCrushDamage else 1)
	local cycle=t.cycle*C.SpeedFactor^s.upgrades.Speed
	local value=t.value*C.LevelYield^(item.level-1)*(1+C.YieldPerLevel*s.upgrades.Yield)*C.rarity(item.rarity).mult*C.modifier(item.modifier).mult*(perks.mult or 1)*(if item.fused then C.Fusion.Mult else 1)
	local multiplier=if rows==false then 1 else Rows.multiplier(rows or Rows.snapshot(d),item.id)
	value*=multiplier
	return {damage=damage,cycle=cycle,hp=t.hp,value=C.money(value),cps=value/(math.ceil(t.hp/damage)*cycle+C.InputDelay),rowBonus=multiplier-1}
end
function R.weights(luck,lucky)
	local out={} for i,v in C.Rarities do out[i]=v.weight*(1+C.LuckPerLevel*luck*v.rank)*(if lucky and v.rank>0 then 2 else 1) end return out
end
local function choose(weights, random)
	local total=0 for _,w in weights do total+=w end
	local target=random()*total local n=0 for i,w in weights do n+=w if target<n then return i end end
	-- rounding fallback: the last entry that can actually be chosen (never a weight-0 Mythic)
	for i=#weights,1,-1 do if weights[i]>0 then return i end end
	return 1
end
local function act(d,session,action,args,now,random,guid,perks)
	local s=d.crushers args=if type(args)=="table" then args else {}
	local function pay(cost) if d.cash<cost then return false end d.cash=C.money(d.cash-cost) return true end
	if action=="Roll" then
		-- Free roll: fills every unlocked pedestal with an offer (not owned yet).
		if now<(session.nextRoll or 0) then return false,"Roll is cooling down." end
		local weights={} for i,v in C.Modifiers do weights[i]=v.weight end
		local offers={}
		-- the very first roll only offers plain Commons, so it is cheap to buy
		local first=s.rolls==0
		for i=1,C.pedestals(s.upgrades.Pedestals) do
			local rarity=if first then C.Rarities[1] else C.Rarities[choose(R.weights(s.upgrades.Luck,perks and perks.lucky),random)]
			local mod=if first then C.Modifiers[1] else C.Modifiers[choose(weights,random)]
			offers[i]={type=rarity.types[math.min(#rarity.types,math.floor(random()*#rarity.types)+1)],rarity=rarity.name,modifier=mod.name,level=1}
		end
		session.offers=offers session.nextRoll=now+C.rollSeconds() s.rolls+=1
		return true,"Rolling...",offers
	elseif action=="Buy" then
		local slot=args.slot
		local offer=type(slot)=="number" and session.offers and session.offers[slot]
		if not offer then return false,"That pedestal is empty. Roll first." end
		if now<(session.nextRoll or 0) then return false,"Wait for the reveal." end
		if #s.owned>=C.MaxInventory then return false,"Inventory full. Recycle duplicates in the Index (RECYCLE DUPES). No cash was charged." end
		local price=C.offerPrice(offer)
		if not pay(price) then return false,"Need $"..price..". Collect and sell scrap first." end
		local item={id=guid(),type=offer.type,rarity=offer.rarity,modifier=offer.modifier,level=1}
		table.insert(s.owned,item) session.offers[slot]=false session.lastRoll=item.id
		return true,"Bought "..C.typeById(item.type).name.."!",item
	elseif action=="Equip" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		local bay=args.bay
		if bay==nil then for i=1,s.bays do if not s.equipped[tostring(i)] then bay=i break end end end
		if type(bay)~="number" or bay~=bay or bay%1~=0 or bay<1 or bay>s.bays then return false,"No usable bay. Unequip a crusher or unlock another bay." end
		for key,id in s.equipped do if id==item.id then s.equipped[key]=nil end end
		s.equipped[tostring(bay)]=item.id
	elseif action=="EquipBest" then
		-- fill the unlocked bays with the highest-output crushers; ones that
		-- are already in a bay and still make the cut stay where they are
		local list=table.clone(s.owned)
		-- Compare raw outputs fairly; current row membership must not bias the
		-- ranking. Before committing, protect a stronger hand-arranged row set.
		local out={} for _,item in list do out[item.id]=R.stats(d,item,perks,false).cps end
		table.sort(list,function(a,b) if out[a.id]==out[b.id] then return a.id<b.id end return out[a.id]>out[b.id] end)
		local best={} for i=1,math.min(s.bays,#list) do best[list[i].id]=true end
		local equipped,placed={},{}
		for key,id in s.equipped do if best[id] and tonumber(key) and tonumber(key)<=s.bays then equipped[key]=id placed[id]=true end end
		local nextBest=1
		for i=1,s.bays do
			local key=tostring(i)
			if not equipped[key] then
				while list[nextBest] and (placed[list[nextBest].id] or not best[list[nextBest].id]) do nextBest+=1 end
				local item=list[nextBest] if not item then break end
				equipped[key]=item.id placed[item.id]=true
			end
		end
		local same=true
		for key,id in equipped do if s.equipped[key]~=id then same=false end end
		for key,id in s.equipped do if equipped[key]~=id then same=false end end
		if same then return false,"You're already using your best crushers!" end
		local proposed={crushers={owned=s.owned,equipped=equipped,bays=s.bays}}
		local currentRows,newRows=Rows.snapshot(d),Rows.snapshot(proposed)
		local before,after=0,0
		for _,id in s.equipped do before+=(out[id] or 0)*Rows.multiplier(currentRows,id) end
		for _,id in equipped do after+=(out[id] or 0)*Rows.multiplier(newRows,id) end
		if after+1e-8<before then return false,"Kept your row bonuses: this setup produces more. Arrange matching rarities manually." end
		s.equipped=equipped
		return true,"Equipped your best crushers!"
	elseif action=="Unequip" then
		if not R.find(d,args.id) then return false,"You do not own that crusher." end
		for key,id in s.equipped do if id==args.id then s.equipped[key]=nil end end
	elseif action=="Recycle" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		for _,id in s.equipped do if id==item.id then return false,"Unequip this crusher before recycling it." end end
		local copies=0 for _,other in s.owned do if other.type==item.type then copies+=1 end end
		if copies<2 then return false,"Keep your last crusher of each type for the Index." end
		for i,other in s.owned do if other.id==item.id then table.remove(s.owned,i) break end end
		return true,"Duplicate recycled. Inventory space freed."
	elseif action=="RecycleDuplicates" then
		local extras=R.duplicateExtras(s.owned,s.equipped,function(item) return R.stats(d,item,perks or {}).cps end)
		if #extras==0 then return false,"No duplicates to recycle. Equipped crushers and your best copy of each type are kept." end
		local gone={} for _,item in extras do gone[item.id]=true end
		for i=#s.owned,1,-1 do if gone[s.owned[i].id] then table.remove(s.owned,i) end end
		return true,"Recycled "..#extras.." duplicate"..(if #extras==1 then "" else "s")..". Inventory space freed.",#extras
	elseif action=="Level" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		if item.level>=C.levelCap(s.plotLevel) then return false,R.capMessage(s.plotLevel) end
		if not pay(C.individualCost(item)) then return false,"Not enough cash. Collect and sell scrap." end
		item.level+=1
	elseif action=="LevelMax" then
		local item=R.find(d,args.id) if not item then return false,"You do not own that crusher." end
		if item.level>=C.levelCap(s.plotLevel) then return false,R.capMessage(s.plotLevel) end
		local n=R.maxLevels(d.cash,item,C.levelCap(s.plotLevel))
		if n<1 then return false,"Not enough cash. Collect and sell scrap." end
		for _=1,n do pay(C.individualCost(item)) item.level+=1 end
		return true,"Done!",n
	elseif action=="Fuse" then
		local main,problem=R.fusionProblem(d,args.main,args.inputs)
		if not main then return false,problem end
		local gone={} for _,id in args.inputs do gone[id]=true end
		for i=#s.owned,1,-1 do if gone[s.owned[i].id] then table.remove(s.owned,i) end end
		main.fused=true
		return true,"Done!",main
	elseif action=="Upgrade" then
		local u=C.Upgrades[args.id] if not u then return false,"Unknown upgrade." end
		local lv=s.upgrades[args.id] if lv>=C.upgradeMax(args.id,s.plotLevel) then return false,if u.max then "Upgrade is at maximum level." else R.capMessage(s.plotLevel) end
		if not pay(C.globalCost(args.id,lv)) then return false,"Not enough cash. Collect and sell scrap." end
		s.upgrades[args.id]+=1
	elseif action=="Unlock" then
		if s.bays>=C.bayCapacity(s.plotLevel) then return false,"Fill the original rows and use UPGRADE PLOT for more bays." end
		if not pay(C.BayCosts[s.bays+1]) then return false,"Not enough cash for another bay. Collect and sell." end s.bays+=1
	elseif action=="UpgradePlot" then return Progression.expand(d)
	elseif action=="Collect" then
		if s.available<=0 then return false,"No finished scrap yet. Your crushers are working." end
		d.scrap=C.money(d.scrap+s.available) s.available=0
	elseif action=="Sell" then
		if d.scrap<=0 then return false,"Collect scrap from the blue bin first." end
		d.cash=C.money(d.cash+d.scrap) d.scrap=0
	else return false,"Unknown factory action." end
	return true,"Done!"
end
-- Tutorial: finishing the current step's action moves on and pays its reward.
function R.tutorialAdvance(d,id)
	local s=d.crushers local step=C.TutorialSteps[s.tutorial]
	if not step or step.id~=id then return false end
	s.tutorial+=1 d.cash=C.money(d.cash+step.reward)
	if s.tutorial>#C.TutorialSteps then d.cash=C.money(d.cash+C.TutorialBonus) end
	return true
end
-- Skip steps the profile has already done (older saves, steps done out of order).
function R.tutorialCatchUp(d)
	local s=d.crushers
	local function doneStep(id)
		local inBays=0 for _ in s.equipped do inBays+=1 end
		if id=="Collect" or id=="Sell" or id=="Roll" then return s.rolls>0 or #s.owned>1 end
		if id=="Buy" then return #s.owned>1 end
		if id=="Unlock" then return s.bays>=2 end
		if id=="Equip" then return inBays>=2 end
		if id=="Upgrade" then return s.upgrades.Damage+s.upgrades.Speed+s.upgrades.Yield>0 end
		if id=="Level" then for _,v in s.owned do if v.level>1 then return true end end end
		return false
	end
	while C.TutorialSteps[s.tutorial] and doneStep(C.TutorialSteps[s.tutorial].id) do R.tutorialAdvance(d,C.TutorialSteps[s.tutorial].id) end
end
function R.act(d,session,action,args,now,random,guid,perks)
	local ok,message,result=act(d,session,action,args,now,random,guid,perks)
	if ok then
		-- counters for quests (QuestRules.stat)
		local counted=({Sell="sells",Buy="buys",Level="levels",LevelMax="levels",Upgrade="upgrades"})[action]
		-- LevelMax counts every level it bought, as if LEVEL UP was pressed that often
		if counted then d.stats=d.stats or {} d.stats[counted]=(d.stats[counted] or 0)+(if action=="LevelMax" then result else 1) end
		local id=if action=="EquipBest" then "Equip" elseif action=="LevelMax" then "Level" else action
		if action=="Upgrade" then local u=C.Upgrades[(type(args)=="table" and args.id) or ""] id=if u and u.group=="Production" then "Upgrade" else "" end
		R.tutorialAdvance(d,id)
	end
	return ok,message,result
end
function R.step(d,session,now,perks)
	local events={} session.bays=session.bays or {}
	local rows=Rows.snapshot(d)
	for i=1,math.min(d.crushers.bays,C.bayCapacity(d.crushers.plotLevel)) do
		local key=tostring(i) local id=d.crushers.equipped[key] local item=id and R.find(d,id)
		local r=session.bays[i]
		if not item then session.bays[i]=nil continue end
		local stats=R.stats(d,item,perks,rows)
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
