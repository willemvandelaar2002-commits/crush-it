--!strict
-- Collectible crusher runtime. All mutations are non-yielding Rules transactions.
local Players=game:GetService("Players")
local Analytics=require(script.Parent.Kit.Analytics)
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Http=game:GetService("HttpService")
local Config=require(RS.Shared.Config)
local C=Config.Crushers
local Rules=require(RS.Shared.CrusherRules)
local Gems=require(RS.Shared.GemConfig)
local Rows=require(RS.Shared.CrusherRows)
local RowVisuals=require(script.Parent.CrusherRowVisuals)
local Progression=require(RS.Shared.FactoryProgression)
local ProgressVisuals=require(script.Parent.FactoryProgressionVisuals)
local Finish=require(RS.Shared.CrusherFinish)
local Net=require(RS.Shared.Net)
local Store=require(RS.Shared.Store)
local Format=require(RS.Shared.Format)
local RollLook=require(RS.Shared.CrusherRollPresentation)
local UpgradeView=require(RS.Shared.CrusherUpgradeView)
local Objects=require(RS.Shared.Objects)
local Data=require(script.Parent.Kit.DataService)
local Plots=require(script.Parent.Plots)
local PressBuilder=require(script.Parent.PressBuilder)
local Workshop=require(script.Parent.Kit.CrusherWorkshop)
local Special=require(script.Parent.SpecialCrushers)
local GemMine=require(script.Parent.GemMine) -- 9 Nov
local Catalog=require(script.Parent.CatalogCrushers)
local Friend=require(script.Parent.FriendBoost)
local Tools=require(script.Parent.CrusherTools)
local Feel=require(script.Parent.CrusherFeedbackServer)
local Stash=require(script.Parent.PlotStash)
local MotionServer=require(script.Parent.CrusherMotionServer) -- 11 Nov: strikes play on the clients
local Motion=require(game:GetService("ReplicatedStorage").Shared.CrusherMotion)
local Goals=require(script.Parent.GoalsReward)
local IndexRewards=require(RS.Shared.IndexRewards)
local G={}
local sessions={}
local pedestalLook -- defined with the roll show helpers below
-- Teleport without falling through: with streaming on, the client may not have
-- the floor at the target yet. Load the area first, hold the character
-- anchored for a moment while it streams in, then release.
function G.safeTeleport(p,char,cf)
	local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
	root.Anchored=true
	char:PivotTo(cf)
	task.spawn(function()
		pcall(function() p:RequestStreamAroundAsync(cf.Position,4) end)
		task.wait(0.4)
		if root.Parent then root.AssemblyLinearVelocity=Vector3.zero root.Anchored=false end
	end)
end
local rng=Random.new()
local function guid() return Http:GenerateGUID(false) end
local function random() return rng:NextNumber() end
local function restoredCooldown(d)
	return os.clock()+math.clamp((d.crushers.rollReadyAt or 0)-workspace:GetServerTimeNow(),0,C.RollSeconds)
end
local Boost=require(RS.Shared.BoostConfig)
local Weekend=require(RS.Shared.WeekendConfig)
local ServerLuck=require(script.Parent.ServerLuck)
local Turbo=require(script.Parent.Turbo)
local Frenzy=require(script.Parent.Frenzy)
local function perks(p)
	local now=workspace:GetServerTimeNow() -- hub Boosts (server/Boosts) stack with the passes
	-- 2 Nov: the Lucky pass and the 2x Luck boost stack (x4 with both; before,
	-- a pass owner who bought the boost got nothing for it)
	return {speed=Frenzy.speed(p),autoCrush=Store.hasPass(p,"AutoCrush"),lucky=(if Store.hasPass(p,"Lucky") then 2 else 1)*(if Boost.active(p,"Luck",now) then 2 else 1)
			*Weekend.luck(os.time()) -- 4 Nov: LUCKY WEEKEND (Shared/WeekendConfig), everyone, Sat-Sun UTC
			*ServerLuck.mult() -- 4 Nov: someone bought Server Luck (x2 for the whole server)
			*(function() local d=Data.get(p) return C.rebirthLuck(d and d.crushers.rebirths or 0) end)()
			*(function() local d=Data.get(p) return if d then Gems.luckMult(d.crushers) else 1 end)(), -- 8 Nov: Gem Luck
		mult=Store.cashPassMult(p)*(if Store.hasPass(p,"VIP") then Store.Vip.Mult else 1)*(if Boost.active(p,"Cash",now) then 2 else 1)*Friend.mult(p)*(Turbo.active(p,now))
			*(function() local d=Data.get(p) return C.rebirthMult(d and d.crushers.rebirths or 0) end)() -- 2 Nov evening: rebirth bonus
			*(function() local d=Data.get(p) return if d then Gems.cashMult(d.crushers) else 1 end)(), -- 8 Nov: Gem Cash
		indexLuck=(function() local d=Data.get(p) return if d then IndexRewards.luck(d.crushers) else 0 end)(),
		limited=C.limitedOn()} -- 6 Nov: Limited (Lucky Weekend) crushers roll while the weekend is on
end
local function cps(p,d)
	local rows=Rows.snapshot(d) local buffs=perks(p)
	local total=0 for _,id in d.crushers.equipped do local item=Rules.find(d,id) if item then total+=Rules.stats(d,item,buffs,rows).cps end end return total
end
-- Frame look per bay state; only touched when the state changes.
local function bayLook(bay,state)
	if bay.shown==state then return end bay.shown=state
	bay.locked.Transparency=if state=="busy" then 1 else 0
	bay.locked.Color=if state=="open" then Color3.fromRGB(88,124,178) else Color3.fromRGB(150,176,212)
	bay.locked.WorkshopControls.Enabled=state=="next" or state=="open"
	for _,v in bay.padlock:GetDescendants() do if v:IsA("BasePart") then v.Transparency=if state=="locked" or state=="next" then 0 else 1 end end
	bay.strip.Transparency=if state=="locked" then .85 else 0
	bay.strip.Color=if state=="next" then Color3.fromRGB(80,235,110) elseif state=="busy" then Color3.fromRGB(255,244,214) else Color3.fromRGB(120,180,255)
end
-- Upper floors: hidden until the previous bays are full, then a see-through
-- ghost with a NEW FLOOR sign, then built (solid) once bought.
local function partsLook(model,mode)
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then
		if p:GetAttribute("BaseT")==nil then p:SetAttribute("BaseT",p.Transparency) p:SetAttribute("BaseC",p.CanCollide) end
		if p:GetAttribute("BaseQ")==nil then p:SetAttribute("BaseQ",p.CanQuery) end
		local baseT=p:GetAttribute("BaseT")
		p.Transparency=if mode=="built" then baseT elseif mode=="ghost" then math.max(baseT,.62) else 1
		p.CanCollide=mode=="built" and p:GetAttribute("BaseC")==true
		-- Invisible stairs/ghost floors must not intercept SurfaceGui mouse rays.
		-- Restore the authored query flag for both solid floors and clickable plaques.
		p.CanQuery=mode=="built" and p:GetAttribute("BaseQ")==true
		p.CastShadow=mode=="built"
	end end
	-- 11 Nov (audit 7): hidden floors, bays and signs leave the Workspace, so clients
	-- don't load them (server/PlotStash); built and ghost ones are in the Workspace
	Stash.set(model,mode~="hidden")
end
-- The floor model a bay belongs to: upper floor (tier 2) or Factory III top floor (tier 3).
local function floorFor(plot,i)
	local l=C.bayLayout(i)
	if l.rear then
		local first=C.rearStart(l.tier,l.wing)
		for _,f in plot.rearFloors or {} do if f.first==first then return f end end
		return nil
	end
	if l.tier==2 then return plot.floors and plot.floors[l.wing] end
	if l.tier==3 then return plot.topFloors and plot.topFloors[l.wing] end
	return nil
end
local function floorLook(plot,unlocked,cap)
	cap=cap or 0
	local all={}
	for _,list in {plot.floors,plot.topFloors,plot.rearFloors} do for _,f in list or {} do table.insert(all,f) end end
	for _,f in all do
		-- floors past the base plot come with the plot upgrade (built at once, their
		-- bays bought one by one): no ghost or BUILD sign, top floors rise in
		-- 2 Nov plot split: everything past the ground floor (StartBays) comes with a
		-- plot upgrade, so a floor is built when the plot includes it, never a ghost
		local mode=if unlocked>=f.first or (f.first>C.StartBays and f.first<=cap) then "built" elseif unlocked+1==f.first and not f.top and f.first<=C.StartBays then "ghost" else "hidden"
		if f.mode~=mode then
			-- (2 Nov: the upper floor also rises when Factory II is bought)
			local rise=(f.mode=="ghost" or (f.top==true and plot.riseTop==true) or (f.mode=="hidden" and not f.top and not f.rear)) and mode=="built"
			f.mode=mode
			partsLook(f.model,mode)
			if f.prompts then for _,prompt in f.prompts do prompt.Enabled=mode=="built" end end
			if rise then
				-- the new floor (and its bays) rises up out of the floor below's roof
				local models={f.model}
				for i,bay in plot.bays do if floorFor(plot,i)==f then table.insert(models,bay.model) end end
				local homes={} for k,m in models do homes[k]=m:GetPivot() m:PivotTo(homes[k]*CFrame.new(0,-C.Layout.TierHeight,0)) end
				task.spawn(function()
					local t0=os.clock()
					while true do
						local t=math.min(1,(os.clock()-t0)/0.9) local e=1-(1-t)^3
						for k,m in models do if m.Parent then m:PivotTo(homes[k]*CFrame.new(0,-C.Layout.TierHeight*(1-e),0)) end end
						if t>=1 then break end
						task.wait()
					end
				end)
			end
			if f.sign then
				partsLook(f.sign,if mode=="ghost" then "built" else "hidden")
				f.content.Visible=mode=="ghost"
			end
		end
		if f.buy then f.buy.Text="BUILD "..Format.cash(C.BayCosts[f.first]) end
	end
	plot.riseTop=nil
	-- the upper floor's parapet makes way for the top floor's deck
	for wing,f in plot.floors or {} do
		local top=plot.topFloors and plot.topFloors[wing]
		local mode=if top and top.mode=="built" then "hidden" else (f.mode or "hidden")
		if f.parapet and f.parapetMode~=mode then f.parapetMode=mode partsLook(f.parapet,mode) end
	end
end
-- Free time skip: SkipMinutes of the current production, paid as cash.
local function skipReward(p,d) return math.max(C.Goals.MinSkipReward,math.floor(cps(p,d)*C.Goals.SkipMinutes*60)) end
-- Group membership (IsInGroup is cached for the session; GetGroupsAsync is fresh).
local function checkGroup(p,fresh)
	local ok,inGroup=pcall(function()
		if not fresh then return p:IsInGroupAsync(C.Goals.GroupId) end
		for _,g in game:GetService("GroupService"):GetGroupsAsync(p.UserId) do if g.Id==C.Goals.GroupId then return true end end
		return false
	end)
	return ok and inGroup==true
end
-- 2 Nov: goals after the tutorial (C.Goals2). Checked from the save on every
-- state send; each pays its reward once. Saves that had finished the tutorial
-- before goals existed skip the goals they already passed WITHOUT rewards.
-- progress on a goal: (have, need); the client shows it as "3 / 5"
local function goalCount(d,g)
	local s=d.crushers
	if g.check=="bays" then return s.bays,g.n end
	if g.check=="fill" then local n=0 for _ in s.equipped do n+=1 end return n,g.n end
	if g.check=="level" then local best=0 for _,v in s.owned do best=math.max(best,v.level) end return math.min(best,g.n),g.n end
	if g.check=="upgrades" then return s.upgrades.Damage+s.upgrades.Speed+s.upgrades.Yield,g.n end
	if g.check=="rolls" then return s.rolls or 0,g.n end
	if g.check=="gift" then return math.min(1,(d.stats and d.stats.gifts) or 0),1 end
	if g.check=="index" then return math.min(1,#(s.indexClaimed or {})),1 end
	if g.check=="row" then for _,row in Rows.snapshot(d).rows do if row.active then return 1,1 end end return 0,1 end
	if g.check=="plot" then return s.plotLevel or 0,g.n end
	-- 4 Nov (quiet goals): a coated crusher (any finish a roll can't give), a fused one, a rebirth
	if g.check=="coat" then for _,v in s.owned do if v.modifier~="Standard" and v.modifier~="Rusty" then return 1,1 end end return 0,1 end
	if g.check=="fuse" then for _,v in s.owned do if v.fused then return 1,1 end end return if s.fusion then 1 else 0,1 end
	if g.check=="rebirth" then return math.min(1,s.rebirths or 0),1 end
	local stats=d.stats or {}
	if g.check=="frenzy" then return math.min(1,stats.frenzies or 0),1 end
	if g.check=="golden" then return math.min(1,stats.goldenToys or 0),1 end
	if g.check=="turbo" then return math.min(1,stats.turbos or 0),1 end
	return 0,1
end
local function goalDone(d,g) local have,need=goalCount(d,g) return have>=need end
local function goalReward(p,d,g)
	local r=g.reward
	if r.cash then d.cash=C.money(d.cash+math.max(r.min or 0,math.floor(cps(p,d)*r.cash)))
	elseif r.crusher then
		local rarity=C.rarity(r.crusher)
		if rarity and #rarity.types>0 then
			-- a goal prize always arrives (even with a full inventory)
			table.insert(d.crushers.owned,{id=guid(),type=rarity.types[rng:NextInteger(1,#rarity.types)],rarity=rarity.name,modifier="Standard",level=1})
		end
	elseif r.boost then
		-- Boosts.add syncs the state itself; don't nest it inside this send
		task.defer(function() require(script.Parent.Boosts).add(p,r.boost,r.minutes) end)
	end
end
local function goalTick(p,d)
	local s=d.crushers
	if (s.tutorial or 1)<=#C.TutorialSteps then return end
	-- an older goal list (goalsV 1/2) -> the same goal id in this list (a goal
	-- that no longer exists restarts at 1); this once, goals already done are
	-- skipped without rewards (the plot split can complete several at once)
	local silent=false
	if s.goal~=nil and s.goalsV~=C.Goals2Version then
		local ids=C.Goals2History[s.goalsV or 1] or C.Goals2History[1]
		silent=true
		-- 4 Nov: a save that finished the old list goes on after its last goal
		-- (the quiet goals were added behind it); done ones are skipped silently
		if s.goal>#ids then
			local last=nil for i,g in C.Goals2 do if g.id==ids[#ids] then last=i end end
			s.goal=if last then last+1 else #C.Goals2+1
		else
			-- a removed goal (e.g. Merge) moves on to the next old goal that still exists
			local found=nil
			for k=s.goal,#ids do
				for i,g in C.Goals2 do if g.id==ids[k] then found=i break end end
				if found then break end
			end
			s.goal=found or #C.Goals2+1
		end
	end
	s.goalsV=C.Goals2Version
	if s.goal==nil then s.goal=1 silent=(s.bays or 0)>2 or (s.plotLevel or 0)>0 end -- older saves
	-- older saves also skip the one-off habit goals (gift, index, row, rolls)
	-- they would otherwise be stuck on, but stop at the first real progress goal
	local habit={gift=true,index=true,row=true,rolls=true,frenzy=true,golden=true,turbo=true}
	-- 4 Nov: someone who has rebirthed jumps from any quiet goal straight to the REBIRTH
	-- goal (after a rebirth "Fill 36 bays" or "Buy Factory IV" would point backwards)
	if (s.rebirths or 0)>=1 and C.Goals2[s.goal] and C.Goals2[s.goal].quiet then
		for i,g in C.Goals2 do if g.check=="rebirth" and i>s.goal then s.goal=i end end
	end
	local done=0
	while C.Goals2[s.goal] and (goalDone(d,C.Goals2[s.goal]) or (silent and habit[C.Goals2[s.goal].check])) and done<#C.Goals2 do
		if not silent then goalReward(p,d,C.Goals2[s.goal]) end
		s.goal+=1 done+=1
	end
end
-- 5 Nov (Willem): UNOWNED / NEW DISCOVERY mean "not in your Index yet" (every type
-- the save ever had, crushers.seen), not "not in your inventory right now"
local function inIndex(s,typeId)
	return (type(s.seen)=="table" and s.seen[typeId]==true) or RollLook.owns(s.owned,typeId)
end
local function send(p,message,result)
	local d=Data.get(p) local ctx=sessions[p] if not d or not ctx then return end
	local s=d.crushers
	local rowState=Rows.snapshot(d)
	-- A first purchase (or spin prize) can make another visible offer of the
	-- same type known. Keep its badge honest without rebuilding the model.
	for slot,model in ctx.plot.offerModels or {} do
		if model.Parent and model:GetAttribute("RevealUnowned") and inIndex(s,model:GetAttribute("RevealType")) then
			model:SetAttribute("RevealUnowned",false)
			local card=ctx.plot.stations.Roll.pedestals[slot].card
			card.rarity.Text=card.rarity.Text:gsub(" · UNOWNED","")
		end
	end
	Rules.tutorialCatchUp(d)
	local goalCash=d.cash
	goalTick(p,d)
	if d.cash~=goalCash then Analytics.cash(p,"GoalReward","Onboarding",goalCash,d.cash) end
	-- onboarding funnel (new saves only): steps 2..9 = tutorial steps done, in order
	if d.onboarding and d.onboarding.funnel then
		for k=1,math.min(#C.TutorialSteps,(s.tutorial or 1)-1) do Analytics.funnelStep(p,d.onboarding,k+1,C.FunnelNames[k+1]) end
		-- 2 Nov: goals done (steps 10..), only once the tutorial is done so steps stay in order
		if (s.tutorial or 1)>#C.TutorialSteps and s.goal then
			for k=1,math.min(C.MainGoals,s.goal-1) do local step=#C.TutorialSteps+1+k Analytics.funnelStep(p,d.onboarding,step,C.FunnelNames[step]) end
		end
	end
	Rules.markSeen(s) -- Index: remember every type this save has owned
	Tools.sync(p,d) -- unequipped crushers live in the Roblox backpack
	p:SetAttribute("Cash",d.cash) p:SetAttribute("Scrap",d.scrap) p:SetAttribute("AvailableScrap",s.available)
	p:SetAttribute("Plot",ctx.plot.index) p:SetAttribute("Crushed",d.crushed) p:SetAttribute("Tier",d.tier)
	p:SetAttribute("CashRate",cps(p,d)) p:SetAttribute("AutoOn",true) p:SetAttribute("GoldenRush",d.goldenRush) p:SetAttribute("Rebirths",s.rebirths or 0)
	-- 11 Nov: your roll luck, for the odds panel and the luck texts in the shop (C.luckPreviewFor)
	do local pk=perks(p) p:SetAttribute("RollLuck",s.upgrades.Luck or 0) p:SetAttribute("RollLuckMult",pk.lucky) p:SetAttribute("RollLuckBonus",pk.indexLuck or 0) end
	p:SetAttribute("Gems",math.floor(s.gems or 0)) p:SetAttribute("GemRate",if (s.rebirths or 0)>=Gems.UnlockRebirths then Gems.minePerMinute(s) else 0) -- 9 Nov: the Gem Mine's rate
	local goalHave,goalNeed=nil,nil
	if s.goal and C.Goals2[s.goal] then goalHave,goalNeed=goalCount(d,C.Goals2[s.goal]) end
	local items={}
	for _,item in s.owned do
		local v=Rules.copy(item) v.stats=Rules.stats(d,item,perks(p),rowState) v.cost=C.individualCost(item) table.insert(items,v)
	end
	Net.event("CrusherState"):FireClient(p,{cash=d.cash,carried=d.scrap,available=s.available,items=items,
		bays=s.equipped,unlocked=s.bays,upgrades=s.upgrades,plotLevel=s.plotLevel,
		goal=s.goal,goalHave=goalHave,goalNeed=goalNeed,rollLucky=perks(p).lucky,fusion=if s.fusion then {item=Rules.copy(s.fusion.item),readyAt=s.fusion.readyAt,now=os.time()} else nil,tutorial=s.tutorial,rate=cps(p,d),rows=rowState.rows,
		equipBetter=(function() -- 3 Nov: the red "!" on Equip Best, from the real rule (rechecked every 3 s)
			if not ctx.equipCheckAt or os.clock()-ctx.equipCheckAt>3 or message then ctx.equipCheckAt=os.clock() ctx.equipBetter=Rules.equipBestHelps(d,perks(p)) end
			return ctx.equipBetter end)(),
		gems=math.floor(s.gems or 0),gemUps=s.gemUps,gemRate=if (s.rebirths or 0)>=Gems.UnlockRebirths then Gems.minePerMinute(s) else 0,
		rollSeconds=math.max(1,C.rollSeconds()-Gems.rollCut(s)),rebirths=s.rebirths or 0,rebirthCost=C.rebirthCost(s.rebirths or 0),rolled=ctx.justRolled,pedestals=Rules.pedestalCount(s),rollReadyAt=workspace:GetServerTimeNow()+math.max(0,(ctx.nextRoll or 0)-os.clock()),
		message=message,result=result,lastRoll=ctx.lastRoll,discovery=ctx.justDiscovered,coating=ctx.coatingQuote,
		goals=Goals.view(ctx,d,workspace:GetServerTimeNow()),
		index={seen=(function() local list={} for id in s.seen do table.insert(list,id) end return list end)(),claimed=s.indexClaimed,luck=IndexRewards.luck(s)}})
	local st=ctx.plot.stations
	st.Collect.label.Text=Format.cash(s.available).." ready"
	-- The pile grows with ready scrap: fast at first, then slower, full at about
	-- 15 minutes of output (30 Oct; was full after 1 minute). Pieces are bottom-up.
	local pieces=st.Collect.sorted
	if not pieces then
		pieces=st.Collect.fill:GetChildren() table.sort(pieces,function(a,b) return a.Position.Y<b.Position.Y end) st.Collect.sorted=pieces
	end
	local minutes=s.available/math.max(1e-6,cps(p,d)*60)
	local shown=if s.available<=0 then 0 else math.clamp(math.ceil(#pieces*math.log(1+minutes)/math.log(16)),3,#pieces)
	if st.Collect.shown~=shown then st.Collect.shown=shown
		for i,v in pieces do v.Transparency=if i<=shown then 0 else 1 end
	end
	st.Sell.label.Text=Format.cash(d.scrap).." carried"
	if st.Turbo then
		local tm,left=Turbo.active(p,workspace:GetServerTimeNow())
		st.Turbo.label.Text=if tm>1 then string.format("x%d cash · %d:%02d left",tm,left//60,left%60) else "Boost your crushers!"
	end
	local rolling=os.clock()<(ctx.nextRoll or 0)
	-- 3 Nov: the pity counter is shown on the roll machine (vault: pity must be visible)
	local pityLeft=math.max(0,C.Pity.Rolls-(s.pity or 0))
	local pityText=if pityLeft<=0 then "LEGENDARY GUARANTEED!" else "Legendary in "..pityLeft.." rolls"
	local pedCount=Rules.pedestalCount(s)
	st.Roll.label.Text=if rolling then "Rolling..." else "Free  ·  "..pedCount.." pedestal"..(if pedCount>1 then "s" else "").."\n"..pityText
	st.Roll.button.Text=if rolling then "ROLLING..." else "ROLL"
	pedestalLook(ctx.plot,pedCount,(s.rebirths or 0)>=Gems.UnlockRebirths)
	local displayPerks=perks(p)
	for _,group in {"Production","Rolling"} do
		for _,id in C.UpgradeOrder do if C.Upgrades[id].group==group then
			local row=ctx.plot.stations[group].rows[id] local view=UpgradeView.board(d,id,displayPerks)
			row.label.Text=view.effect Workshop.purchase(row.button,view)
			if row.many then
				-- x10: price of up to 10 levels (as many as the cap allows); ready when one level is affordable
				local lv=s.upgrades[id] local max=C.upgradeMax(id,s.plotLevel) local n=math.min(C.UpgradeMany,max-lv)
				local cost=0 for k=0,n-1 do cost+=C.globalCost(id,lv+k) end
				local many=UpgradeView.purchase(d.cash,if n>0 then C.globalCost(id,lv) else 0,n<=0,"","")
				many.button="x"..C.UpgradeMany many.hint=if n<=0 then Rules.capMessage(s.plotLevel) else "Buys up to "..C.UpgradeMany.." levels ("..Format.cash(cost).." for all "..n..")."
				Workshop.purchase(row.many,many)
			end
		end end
	end
	-- Favorite is best-effort client confirmation; group and cooldown are server gates.
	local goals=st.Goals and st.Goals.rows
	if goals then
		local view=Goals.view(ctx,d,workspace:GetServerTimeNow())
		goals.Like.button.Text=if view.favorite then "✓ FAVORITED" else "★ FAVORITE"
		goals.Like.label.Text=if view.favorite then "Favorite goal complete!" else "Confirm the Roblox favorite prompt"
		goals.Group.button.Text=if ctx.inGroup then "✓ JOINED" else "JOIN"
		goals.Group.label.Text=if ctx.inGroup then "Group goal complete!" else "Complete both goals for the free skip"
		local left=view.left
		Workshop.purchase(goals.Skip.button,{state=if view.canClaim then "Ready" else "Short",cost=0,
			button=if not view.favorite then "FAVORITE" elseif not view.inGroup then "JOIN FIRST" elseif left>0 then string.format("%02d:%02d:%02d",left//3600,left%3600//60,left%60) else "CLAIM",
			hint=view.reason,success="+"..C.Goals.SkipMinutes.." MIN!"})
		goals.Skip.label.Text=if not view.favorite or not view.inGroup then "Complete BOTH goals above" else "Get "..Format.cash(skipReward(p,d)).." instantly"
	end
	local cap=C.bayCapacity(s.plotLevel)
	floorLook(ctx.plot,s.bays,cap)
	for i,bay in ctx.plot.bays do
		-- bays on an upper floor that isn't built yet are invisible
		local f=floorFor(ctx.plot,i)
		local hidden=(f~=nil and f.mode~="built")
		if bay.hidden~=hidden then bay.hidden=hidden bay.shown=nil partsLook(bay.model,if hidden then "hidden" else "built") end
		if hidden then
			bay.label.name.Text="" bay.label.rarity.Text="" bay.label.stats.Text="" bay.label.line.Text="" bay.label.scope.Text="" bay.buy.Visible=false bay.manage.Visible=false bay.max.Visible=false bay.lockLabel.Text=""
			continue
		end
		local item=Rules.find(d,s.equipped[tostring(i)])
		local state=if item then "busy" elseif i<=s.bays then "open" elseif i==s.bays+1 and i<=cap then "next" else "locked"
		local card=bay.label
		if item then
			card.scope.Text="THIS CRUSHER"
			local r=C.rarity(item.rarity)
			card.name.Text=(if (item.stars or 0)>0 then string.rep("★",item.stars).." " else "")..C.typeById(item.type).name
			card.rarity.Text=(if item.fused then "FUSED · " else "")..item.rarity..(if item.modifier~="Standard" then "  ·  "..item.modifier.." x"..C.modifier(item.modifier).mult else "")
			card.rarity.TextColor3=r.color:Lerp(Color3.new(1,1,1),.25)
			local view=UpgradeView.crusher(d,item,displayPerks)
			card.stats.Text=view.effect card.line.Text=view.short Workshop.purchase(bay.buy,view)
			Workshop.purchase(bay.max,UpgradeView.crusherMax(d,item))
		else
			card.scope.Text="BAY "..i
			card.name.Text=if state=="open" then "EMPTY BAY" elseif state=="next" then "NEXT BAY" else "LOCKED"
			card.rarity.Text=if state=="open" then "Equip a crusher here" elseif state=="next" then "Unlock for more output" else ""
			card.rarity.TextColor3=Color3.new(1,1,1)
			card.stats.Text=""
			card.line.Text=if state=="open" then "Equip a crusher" elseif state=="next" then "More output" else ""
			if state=="next" then
				local view=UpgradeView.purchase(d.cash,C.BayCosts[i],false,"Adds a working bay; does not level a crusher.","BAY UNLOCKED!")
				view.button="UNLOCK\n"..Format.cash(C.BayCosts[i]) Workshop.purchase(bay.buy,view)
			else Workshop.clearPurchase(bay.buy) bay.buy.Text="EQUIP" end
		end
		local plate=if item then C.rarity(item.rarity).color:Lerp(Workshop.Navy,.2) else Workshop.Blue
		if bay.part.Color~=plate then bay.part.Color=plate end
		bay.buy.Visible=state~="locked"
		bay.manage.Visible=state=="busy"
		bay.max.Visible=state=="busy"
		-- The direct plaque buttons replace the default prompt overlay, which can
		-- cover the small level button and intercept its mouse click.
		bay.prompt.Enabled=false
		bay.lockLabel.Text=if state=="next" then Format.cash(C.BayCosts[i]) elseif state=="open" then "EMPTY" else ""
		bayLook(bay,state)
	end
	RowVisuals.sync(ctx.plot,rowState)
	local quote=ctx.coatingQuote local preview=""
	if quote then local item=Rules.find(d,quote.id)
		if item then local upgraded=table.clone(item) upgraded.modifier=quote.target
			preview=C.typeById(item.type).name.." · "..item.modifier.." > "..quote.target.."\n"..Format.cash(Rules.stats(d,item,displayPerks).cps*60).." > "..Format.cash(Rules.stats(d,upgraded,displayPerks).cps*60).."/min (before row bonus)"
		end
	end
	ProgressVisuals.sync(ctx.plot,d,quote,os.clock(),preview)
end
-- Fused crushers get a glowing gold frame round their pedestal (inside the
-- machine's own model, so it goes when the machine is rebuilt or swapped).
-- Fused crushers: green glow plate, corner lights and sparkles (CrusherFinish.fused).
local function fusedMark(model,o) Finish.fused(model,o) end
local function buildBay(p,i,item)
	local ctx=sessions[p] local bay=ctx.plot.bays[i] local old=ctx.visuals[i]
	if old then old.model:Destroy() ctx.visuals[i]=nil end
	if not item then return end
	local t=C.typeById(item.type) local o=bay.origin
	local special=Catalog.build(o,t.id) or (if t.template then Special.build(o,t.template) else nil)
	if special then
		special.id=item.id special.tier=t.input special.rarity=item.rarity special.model.Name="EquippedCrusher"
		special.model:SetAttribute("InventoryId",item.id) special.model:SetAttribute("Rarity",item.rarity) special.model:SetAttribute("Modifier",item.modifier)
		Finish.apply(special.model,item.modifier,o)
		if item.fused then fusedMark(special.model,o) end
		special.model.Parent=bay.model ctx.visuals[i]=special Feel.track(special,t.id) return
	end
	local built=PressBuilder.build(o,t.tier) built.model.WorldPivot=o
	local _,size=built.model:GetBoundingBox() local l=C.Layout
	local scale=math.min(1,l.MachineWidth/size.X,l.MachineDepth/size.Z,l.MachineHeight/size.Y)
	built.model:ScaleTo(scale) built.model.Name="EquippedCrusher"
	built.model:SetAttribute("InventoryId",item.id) built.model:SetAttribute("Rarity",item.rarity) built.model:SetAttribute("Modifier",item.modifier)
	local emitters=0
	for _,part in built.model:GetDescendants() do if part:IsA("BasePart") then
		part.CanCollide=false part.CanTouch=false part.CanQuery=false
		if part.Name=="Plinth" or part.Name=="Housing" then part.Color=C.rarity(item.rarity).color end
		if item.modifier=="Polished" and part.Name=="Housing" then part.Material=Enum.Material.Metal end
		if item.modifier=="Rusty" and part.Name=="Bed" then part.Material=Enum.Material.CorrodedMetal end
		if item.modifier=="Polished" and part.Name=="Bed" then part.Material=Enum.Material.Metal part.Color=Color3.fromRGB(211,224,238) end
		if item.modifier=="Charged" and part.Name=="Plinth" then part.Material=Enum.Material.Neon end
	elseif part:IsA("Light") then part.Enabled=false
	elseif part:IsA("ParticleEmitter") then emitters+=1 part.Enabled=emitters<=C.MaxPressEmitters part.Rate=math.min(part.Rate,C.PressParticleRate)
	end end
	Finish.apply(built.model,item.modifier,o)
	if item.fused then fusedMark(built.model,o) end
	built.model.Parent=bay.model
	local colors={Bumper=Color3.fromRGB(235,69,67),Steel=Color3.fromRGB(35,126,235),Cobalt=Color3.fromRGB(52,193,87),Mega=Color3.fromRGB(171,68,228),Titan=Color3.fromRGB(248,194,40),Quantum=Color3.fromRGB(50,208,220)}
	-- Coloured cap on top of the press (the light strip on the bay beam replaces the old beacon).
	local header=Workshop.part(built.model,"ToyHeader",Vector3.new(8.4,1,2),o*CFrame.new(0,l.MachineHeight-.5,1),colors[item.type] or Config.Presses[t.tier].accent)
	for _,x in {-3.3,3.3} do Workshop.part(built.model,"HeaderBolt",Vector3.new(.5,.5,.4),header.CFrame*CFrame.new(x,0,1.1),Color3.fromRGB(222,233,245)) end
	local bed=(built.model:FindFirstChild("Bed") :: BasePart)
	ctx.visuals[i]={id=item.id,model=built.model,ram=built.ram,rest=built.ram.CFrame,
		base=CFrame.new(o.Position.X,bed.Position.Y+bed.Size.Y/2,o.Position.Z)*(o-o.Position),input=nil,tier=t.input,rarity=item.rarity,
		clearance=built.ram.Position.Y-built.ram.Size.Y/2-(bed.Position.Y+bed.Size.Y/2),bedWidth=math.min(bed.Size.X,bed.Size.Z)}
	Motion.tagRam(built.model,built.ram)
	Feel.track(ctx.visuals[i],t.id)
end
local function reconcile(p)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return end
	for i=1,C.MaxBays do local item=Rules.find(d,d.crushers.equipped[tostring(i)]) local visual=ctx.visuals[i]
		-- a fused crusher keeps its id, so the fused flag is part of the key
		local want=item and (item.id..(if item.fused then "#fused" else "")) or nil
		local have=visual and (visual.key or visual.id) or nil
		if want~=have then buildBay(p,i,item) if ctx.visuals[i] then ctx.visuals[i].key=want end end
	end
end
-- Fit a press model into a box and paint it in the crusher's rarity/modifier.
local function dress(model,item,fit)
	if fit then
		local _,size=model:GetBoundingBox()
		model:ScaleTo(math.min(1,fit.X/size.X,fit.Z/size.Z,fit.Y/size.Y))
	end
	for _,part in model:GetDescendants() do if part:IsA("BasePart") then
		part.CanCollide=false part.CanTouch=false part.CanQuery=false
		if part.Name=="Plinth" or part.Name=="Housing" then part.Color=C.rarity(item.rarity).color end
		if item.modifier=="Polished" and part.Name=="Housing" then part.Material=Enum.Material.Metal end
		if item.modifier=="Rusty" and part.Name=="Bed" then part.Material=Enum.Material.CorrodedMetal end
		if item.modifier=="Polished" and part.Name=="Bed" then part.Material=Enum.Material.Metal part.Color=Color3.fromRGB(211,224,238) end
		if item.modifier=="Charged" and part.Name=="Plinth" then part.Material=Enum.Material.Neon end
	elseif part:IsA("Light") then part.Enabled=false
	elseif part:IsA("ParticleEmitter") then part.Enabled=false end end
end
-- A display copy of a crusher type for the reveal plinth (imported special
-- meshes when the type has a template, else the procedural press).
local REVEAL_FIT=Vector3.new(5.4,7.4,5.4)
local function displayModel(typeId,at,item)
	local t=C.typeById(typeId)
	local model
	local special=Catalog.build(at,t.id) or (if t.template then Special.build(at,t.template) else nil)
	if special then model=special.model
	else local built=PressBuilder.build(at,t.tier) model=built.model end
	local _,size=model:GetBoundingBox()
	model:ScaleTo(model:GetScale()*math.min(1,REVEAL_FIT.X/size.X,REVEAL_FIT.Z/size.Z,REVEAL_FIT.Y/size.Y))
	-- sit the bounding box on the plinth
	local cf,sz=model:GetBoundingBox()
	model:PivotTo(model:GetPivot()+(at.Position+Vector3.new(0,sz.Y/2,0)-cf.Position))
	if item then dress(model,item,nil) else
		for _,part in model:GetDescendants() do if part:IsA("BasePart") then part.CanCollide=false part.CanTouch=false part.CanQuery=false
		elseif part:IsA("Light") or part:IsA("ParticleEmitter") then part.Enabled=false end end
	end
	if item then Finish.apply(model,item.modifier,at) end
	return model
end
-- Black silhouette with a white outline (one Highlight per plot follows it).
local function silhouette(model)
	for _,part in model:GetDescendants() do
		if part:IsA("BasePart") then part.Color=Color3.fromRGB(12,12,16) part.Material=Enum.Material.SmoothPlastic part.CastShadow=false
			if part:IsA("MeshPart") then part.TextureID="" end
		elseif part:IsA("SurfaceAppearance") or part:IsA("Decal") or part:IsA("Texture") or part:IsA("SurfaceGui") or part:IsA("BillboardGui") then part:Destroy() end
	end
end
local function showModel(model,visible)
	for _,part in model:GetDescendants() do if part:IsA("BasePart") then
		if part:GetAttribute("ShowT")==nil then part:SetAttribute("ShowT",part.Transparency) end
		part.Transparency=if visible then part:GetAttribute("ShowT") else 1
	end end
end
local function card(ped,name,rarity,odds,value,price,color)
	local c=ped.card
	c.name.Text=name c.name.TextColor3=color or Color3.new(1,1,1)
	c.rarity.Text=rarity c.rarity.TextColor3=color or Color3.new(1,1,1)
	c.odds.Text=odds c.value.Text=value c.price.Text=price
end
local function oddsText(typeId)
	local r=C.rarityOf(typeId) if (r and r.exclusive) or C.isCrateOnly(typeId) then return "[EXCLUSIVE]" end
	return "[1 in "..Format.cash(C.oddsFor(typeId)):gsub("%$","").."]"
end
-- Unlocked pedestals are yellow and empty until a roll; locked ones are grey
-- with a hint, so the ROLLING board upgrade is visible on the plot.
function pedestalLook(plot,count,gemShop)
	local key=count..":"..tostring(gemShop==true)
	if plot.pedestalCount==key then return end plot.pedestalCount=key
	for i,ped in plot.stations.Roll.pedestals do
		local open=i<=count
		-- 8 Nov: the Gem Pedestal (past the board's max) is purple, and only there after a rebirth
		local gem=i>C.MaxPedestals
		if gem then for _,part in ped.parts or {} do
			if part:GetAttribute("BaseT")==nil then part:SetAttribute("BaseT",part.Transparency) end
			part.Transparency=if gemShop then part:GetAttribute("BaseT") else 1 part.CanCollide=gemShop==true part.CanQuery=gemShop==true
		end end
		ped.part.Color=if open then (if gem then Color3.fromRGB(205,80,240) else Workshop.Yellow) else Color3.fromRGB(120,128,140)
		ped.part.Material=if open then Enum.Material.SmoothPlastic else Enum.Material.Slate
		if gem and not gemShop then card(ped,"","","","","") ped.prompt.Enabled=false
		elseif not open then card(ped,"LOCKED","More pedestals at",if gem then "GEM SHOP" else "ROLL UPGRADES","","",Color3.fromRGB(200,205,215)) ped.prompt.Enabled=false
		elseif ped.card.name.Text=="LOCKED" then card(ped,"","","","","") end
		-- 30 Oct (less busy plot): the LOCKED hint only shows up close; offers stay readable from afar
		local gui=ped.card.name.Parent
		if gui and gui:IsA("BillboardGui") then gui.MaxDistance=if open then 110 else C.QuietLabelDistance end
	end
end
-- Remove the offer models and cards (a new roll, a purchase, or leaving).
local function clearOffer(plot,slot)
	local ped=plot.stations.Roll.pedestals[slot]
	if plot.offerModels and plot.offerModels[slot] then plot.offerModels[slot]:Destroy() plot.offerModels[slot]=nil end
	ped.prompt.Enabled=false
	if ped.card.name.Text~="LOCKED" then card(ped,"","","","","") end
end
local function flash(plot,at,color)
	local f=Workshop.part(plot.model,"RevealFlash",Vector3.new(2,2,2),at*CFrame.new(0,3,0),color or Color3.fromRGB(255,240,180))
	f.Shape=Enum.PartType.Ball f.Material=Enum.Material.Neon f.CastShadow=false
	Tween:Create(f,TweenInfo.new(.35,Enum.EasingStyle.Quad),{Size=Vector3.new(10,10,10),Transparency=1}):Play()
	task.delay(.4,function() f:Destroy() end)
end
-- Roll show (like the reference): every unlocked pedestal flickers black
-- silhouettes of possible crushers with "???" and their odds, slowing down;
-- then each pops in turn (flash) into the real offer with name, rarity, odds,
-- output and price. Buying is done with the pedestal's prompt.
local function rollShow(p,offers)
	local ctx=sessions[p] local plot=ctx.plot local st=plot.stations.Roll
	-- 8 Nov (Willem: "the skip still shows it"): SKIP ANIMATION = no flicker, no die spin,
	-- all pedestals at once, no reveal highlight / sting (RevealFast)
	local fast=ctx.fastRoll==true
	local seconds=if fast then 0 else math.max(1.2,(ctx.nextRoll or 0)-os.clock()) local token={} ctx.rollToken=token
	local rollId=guid() local rollData=Data.get(p) local rollPerks=perks(p)
	local rollLuck=rollData.crushers.upgrades.Luck local first=rollData.crushers.rolls==1
	-- 2 Nov: a Legendary or better roll is announced to the whole server once revealed
	local best=nil local bestSlot=nil
	for slot,item in offers do local r=item and C.rarity(item.rarity) if r and r.rank>=4 and (not best or r.rank>best.rank) then best=table.clone(r) best.item=item bestSlot=slot end end
	-- 5 Nov: Secret and up get the big cinematic (BigRoll.client): that pedestal is
	-- held back for C.BigRoll[rarity].Hold seconds so the impact lands on the reveal;
	-- the next roll and buying wait as long (no rolling a Secret away by accident)
	local function bigFor(r) return if r and (r.rank>=C.BigRoll.MinRank or r.name=="Limited") then C.BigRoll[r.name] else nil end
	-- 11 Nov (Willem: "remove the cinematic roll for crushers you already own"): the cinematic
	-- only plays for a type this save has never owned (crushers.seen); the best NEW one gets it
	local seenSet=if type(rollData.crushers.seen)=="table" then rollData.crushers.seen else {}
	local show=nil local showSlot=nil
	for slot,item in offers do local r=item and C.rarity(item.rarity)
		if bigFor(r) and not seenSet[item.type] and (not show or r.rank>show.rank) then show=table.clone(r) show.item=item showSlot=slot end
	end
	local big=bigFor(show)
	-- 8 Nov: the tutorial's first roll (one Rare, C.FirstRoll) gets the big cinematic too,
	-- only for this player (no server-wide announcement for a Rare)
	local firstShow=false
	if first and not best then
		for slot,item in offers do local r=item and C.rarity(item.rarity) if r and r.name==C.FirstRoll.Rarity then best=table.clone(r) best.item=item bestSlot=slot end end
		if best then big={Hold=C.FirstRoll.Hold} firstShow=true show=best showSlot=bestSlot end
	end
	local hold=if big then big.Hold else 0
	if big then
		ctx.nextRoll=(ctx.nextRoll or 0)+hold
		rollData.crushers.rollReadyAt=workspace:GetServerTimeNow()+math.max(0,ctx.nextRoll-os.clock())
		local def=C.typeById(show.item.type) local ped=st.pedestals[showSlot]
		-- 5 Nov (Willem): the cinematic counts up to the BASE odds of that crusher (no luck,
		-- passes or boosts), so a Secret / Divine always shows how rare it really is
		local odds=RollLook.odds(show.item.type,0,nil,false,0)
		task.delay(seconds,function()
			if ctx.rollToken~=token or sessions[p]~=ctx then return end
			-- 5 Nov (Willem): skippable once you have watched this rarity's cinematic before (saved)
			local cs=rollData.crushers if type(cs.bigSeen)~="table" then cs.bigSeen={} end
			local canSkip=cs.bigSeen[show.name]==true cs.bigSeen[show.name]=true
			local fire=if firstShow then function(t) Net.event("BigRoll"):FireClient(p,t) end else function(t) Net.event("BigRoll"):FireAllClients(t) end
			fire({canSkip=canSkip,userId=p.UserId,player=p.DisplayName,rarity=show.name,rank=show.rank,color=show.color,
				name=def and def.name or show.item.type,type=show.item.type,odds=odds,slot=showSlot,at=ped.top,machine=st.die:GetPivot().Position,hold=hold,
				revealAt=workspace:GetServerTimeNow()+hold,aftershock=big.AftershockLuck,aftershockSeconds=big.AftershockSeconds})
		end)
	end
	if best and not firstShow then
		local def=C.typeById(best.item.type)
		task.delay(seconds+hold+0.4,function()
			if ctx.rollToken~=token then return end
			Net.event("RarePull"):FireAllClients({player=p.DisplayName,rarity=best.name,name=def and def.name or best.item.type,color=best.color,userId=p.UserId})
			-- (the Divine / Eternal aftershock stays, also when the cinematic is skipped for an owned type)
			local after=bigFor(best)
			if after and after.AftershockLuck then
				ServerLuck.aftershock(p,after.AftershockLuck,after.AftershockSeconds)
				Net.event("RarePull"):FireAllClients({text=string.upper(best.name).." AFTERSHOCK: +"..math.floor((after.AftershockLuck-1)*100+.5).."% luck for EVERYONE for "..after.AftershockSeconds.." seconds!",
					userId=p.UserId,color=best.color})
			end
		end)
	end
	for i in st.pedestals do clearOffer(plot,i) end
	plot.offerModels={}
	-- silhouettes are built lazily per pedestal and type, then reused
	plot.silhouettes=plot.silhouettes or {}
	local folder=plot.model:FindFirstChild("RollSilhouettes")
	if not folder then folder=Instance.new("Model") folder.Name="RollSilhouettes" folder.Parent=plot.model end
	local function silhouetteFor(slot,id)
		plot.silhouettes[slot]=plot.silhouettes[slot] or {}
		local m=plot.silhouettes[slot][id]
		if not m then
			local count=0 local oldest local oldestTime=math.huge
			for key,cached in plot.silhouettes[slot] do
				count+=1 local used=cached:GetAttribute("LastShown") or 0
				if used<oldestTime then oldest=key oldestTime=used end
			end
			if count>=6 and oldest then
				if plot.outlines[slot] then plot.outlines[slot].Parent=folder end
				plot.silhouettes[slot][oldest]:Destroy() plot.silhouettes[slot][oldest]=nil
			end
			m=displayModel(id,st.pedestals[slot].top) silhouette(m) showModel(m,false) m.Parent=folder
			m:SetAttribute("BasePivot",m:GetPivot()) plot.silhouettes[slot][id]=m
		end
		m:SetAttribute("LastShown",os.clock())
		return m
	end
	plot.outlines=plot.outlines or {}
	local pool={} for _,r in C.Rarities do for _,id in r.types do table.insert(pool,{id=id,w=r.weight^.45}) end end
	local function pick()
		local total=0 for _,e in pool do total+=e.w end local x=rng:NextNumber()*total
		for _,e in pool do x-=e.w if x<=0 then return e.id end end return pool[#pool].id
	end
	-- Spinning is done by each client (RollSpin.client) from these attributes:
	-- the server never moves the parts, so nothing is replicated per frame.
	local function spin(m,centre,speed,lift)
		if typeof(m:GetAttribute("BasePivot"))~="CFrame" then m:SetAttribute("BasePivot",m:GetPivot()) end
		m:SetAttribute("SpinCentre",centre) m:SetAttribute("SpinSpeed",speed)
		m:SetAttribute("SpinStart",workspace:GetServerTimeNow()) m:SetAttribute("SpinLift",lift)
		game:GetService("CollectionService"):AddTag(m,"RollSpin")
	end
	-- each pedestal flickers between a few types per roll, mostly ones it
	-- already built, so a roll builds at most a couple of new models
	local candidates={}
	for slot in offers do
		local list={} local cached={}
		for id in (plot.silhouettes[slot] or {}) do table.insert(cached,id) end
		for _=1,3 do if #cached>0 then table.insert(list,table.remove(cached,rng:NextInteger(1,#cached))) end end
		while #list<4 do table.insert(list,pick()) end
		candidates[slot]=list
	end
	local shown={} local nextFlick={}
	local function flick(slot,id)
		if shown[slot] then showModel(shown[slot],false) game:GetService("CollectionService"):RemoveTag(shown[slot],"RollSpin") end
		local m=silhouetteFor(slot,id) shown[slot]=m showModel(m,true)
		local hl=plot.outlines[slot]
		if not hl then
			hl=Instance.new("Highlight") hl.Name="SilhouetteOutline" hl.FillColor=Color3.fromRGB(8,8,12) hl.FillTransparency=0 hl.OutlineTransparency=0
			hl.OutlineColor=Color3.new(1,1,1) hl.DepthMode=Enum.HighlightDepthMode.Occluded plot.outlines[slot]=hl
		end
		hl.Parent=m hl.Enabled=true
		spin(m,st.pedestals[slot].top.Position,1.1,nil)
		card(st.pedestals[slot],"???","???","Rolling...","???","")
	end
	local function stop()
		for slot,m in shown do showModel(m,false) game:GetService("CollectionService"):RemoveTag(m,"RollSpin") if plot.outlines[slot] then plot.outlines[slot].Enabled=false end end
		shown={}
	end
	local start=os.clock() local base=st.die:GetPivot() local rollers={}
	for _,r in st.rollers do rollers[r]=r.CFrame end
	for i in offers do nextFlick[i]=(i-1)*.04 end
	local conn conn=RunService.Heartbeat:Connect(function()
		local t=os.clock()-start
		if t>=seconds or ctx.rollToken~=token or not st.die.Parent then
			conn:Disconnect() st.die:PivotTo(base) for r,cf in rollers do r.CFrame=cf end
			stop()
			if ctx.rollToken~=token or sessions[p]~=ctx then return end
			local d=Data.get(p)
			for slot,item in offers do
				-- reveal the pedestals one after another, centre first
				task.delay((if fast then 0 else (slot-1)*.12)+(if slot==showSlot then hold else 0),function()
					if ctx.rollToken~=token or sessions[p]~=ctx or not item then return end
					if not ctx.offers or ctx.offers[slot]~=item then return end -- already bought/replaced during the stagger
					local ped=st.pedestals[slot] local r=C.rarity(item.rarity)
					local odds=RollLook.odds(item.type,rollLuck,rollPerks.lucky,first,rollPerks.indexLuck)
					local unowned=d and not inIndex(d.crushers,item.type)
					local model=displayModel(item.type,ped.top,item) model.Name="OfferCrusher"
					model:SetAttribute("RevealOwner",p.UserId) model:SetAttribute("RevealRoll",rollId)
					model:SetAttribute("RevealSlot",slot) model:SetAttribute("RevealAt",workspace:GetServerTimeNow())
					model:SetAttribute("RevealRarity",item.rarity) model:SetAttribute("RevealType",item.type)
					model:SetAttribute("RevealUnowned",unowned==true) model:SetAttribute("RevealOdds",odds)
					if fast then model:SetAttribute("RevealFast",true) end
					model.Parent=plot.model game:GetService("CollectionService"):AddTag(model,RollLook.Tag)
					plot.offerModels[slot]=model
					spin(model,ped.top.Position,.8,item.rarity)
					local perMin=d and Rules.stats(d,{type=item.type,rarity=item.rarity,modifier=item.modifier,level=1},perks(p)).cps*60 or 0
					local name=C.typeById(item.type).name
					card(ped,name,item.rarity..(if item.modifier~="Standard" then " · "..item.modifier else "")..(if unowned then " · UNOWNED" else ""),RollLook.oddsText(odds),
						Format.cash(perMin).."/min",Format.cash(C.offerPrice(item)),r.color:Lerp(Color3.new(1,1,1),.15))
					ped.prompt.ActionText="Buy "..Format.cash(C.offerPrice(item)) ped.prompt.ObjectText=name ped.prompt.Enabled=true
				end)
			end
			return
		end
		-- flicker: fast at first, slowing down towards the reveal
		for slot,item in offers do
			if t>=nextFlick[slot] then
				local last=seconds-t<.45
				local list=candidates[slot]
				flick(slot,if last then item.type else list[rng:NextInteger(1,#list)])
				nextFlick[slot]=t+.18+.35*(t/seconds)^2
			end
		end
		local spin=t*14*(1-t/seconds*.6)
		st.die:PivotTo(base*CFrame.new(0,math.abs(math.sin(t*9))*1.2,0)*CFrame.Angles(spin,spin*.7,spin*.4))
		for r,cf in rollers do r.CFrame=cf*CFrame.Angles(t*20,0,0) end
	end)
end
-- What a plot upgrade from levelBefore to level added, for the buyer's cutscene.
local function upgradeSummary(levelBefore,level)
	local U=C.PlotUpgrade local baysBefore=C.bayCapacity(levelBefore)
	local before=U.Caps[levelBefore] local after=U.Caps[level]
	return {level=level,name=U.Names[level],title=U.Titles[level],section=U.Sections[level],
		unlock=U.Unlocks[level],accent=U.Accents[level],added=C.bayCapacity(level)-baysBefore,bays=C.bayCapacity(level),
		first=baysBefore+1,last=C.bayCapacity(level),
		caps={global={if before then before.global else C.MaxGlobal,after.global},level={if before then before.level else C.MaxLevel,after.level}}}
end
-- 2 Nov: what each action's cash change is called in the economy dashboard
local ACTION_SKU={UpgradeMany="FactoryUpgrade",Rebuild="UnlockBay",Sell="SellScrap",Buy="BuyCrusher",Unlock="UnlockBay",Upgrade="FactoryUpgrade",Level="LevelUp",LevelMax="LevelUp",
	UpgradePlot="PlotUpgrade",ApplyCoating="Coating",Fuse="Fusion",RollUpgrade="RollUpgrade"}
local function action(p,name,args)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return false,"Profile is loading." end
	local cashBefore=d.cash
	local offer=if name=="Buy" and type(args)=="table" and type(args.slot)=="number" then ctx.offers and ctx.offers[args.slot] else nil
	local newType=offer and not inIndex(d.crushers,offer.type)
	local ok,message,result
	local levelBefore=Progression.level(d) local baysBefore=C.bayCapacity(levelBefore)
	-- coating: the crusher chosen on the coating screen (args.item), or the held one (old board)
	local chosen=if (name=="QuoteCoating" or name=="ApplyCoating") and type(args)=="table" and type(args.item)=="string" then args.item else Tools.held(p)
	if name=="QuoteCoating" then
		local quote,problem=Progression.quote(d,chosen,args.id,os.clock(),guid())
		ctx.coatingQuote=quote ok=quote~=nil message=problem or "Review the coating preview, then confirm."
	elseif name=="ApplyCoating" then
		local quote=ctx.coatingQuote
		ok,message=Progression.apply(d,quote,args.token,chosen,os.clock())
		if ok and quote then result={coating=quote.target,id=quote.id} end
		ctx.coatingQuote=nil
	else
		-- fusion timing uses real unix time (it runs while you're offline); never trust a client time
		if name=="Fuse" or name=="CollectFusion" then args.serverTime=os.time() end
		ok,message,result=Rules.act(d,ctx,name,args,os.clock(),random,guid,perks(p))
	end
	-- Studio only (DevCrusher "ForceRoll"): the first pedestal of the next roll gets this rarity
	if ok and name=="Roll" and ctx.forceRarity and RunService:IsStudio() then
		local r=C.rarity(ctx.forceRarity) ctx.forceRarity=nil
		if r and #r.types>0 then result[1]={type=r.types[1],rarity=r.name,modifier="Standard",level=1} ctx.offers=result end
	end
	-- 8 Nov: Auto Roll with SKIP ANIMATION (server/AutoRoll sets ctx.fastRoll)
	if ok and name=="Roll" and ctx.fastRoll then ctx.nextRoll=os.clock()+C.AutoRoll.SkipSeconds end
	if ok and name=="Roll" then d.crushers.rollReadyAt=workspace:GetServerTimeNow()+math.max(0,ctx.nextRoll-os.clock()) rollShow(p,result) end
	if ok and name=="Buy" then
		if newType then ctx.justDiscovered={id=result.id,type=result.type,rarity=result.rarity} end
		local ped=ctx.plot.stations.Roll.pedestals[args.slot]
		flash(ctx.plot,ped.top,Color3.fromRGB(120,255,140)) clearOffer(ctx.plot,args.slot)
		card(ped,"BOUGHT!","","","","",Color3.fromRGB(120,255,140))
		task.delay(1.5,function() if ped.card.name.Text=="BOUGHT!" then card(ped,"","","","","") end end)
	end
	if ok then reconcile(p) end
	if d.cash~=cashBefore then Analytics.cash(p,ACTION_SKU[name] or name,if name=="Buy" then "Shop" else "Gameplay",cashBefore,d.cash) end
	-- onboarding funnel: the first plot upgrade comes after the tutorial steps
	if ok and d.onboarding and name=="UpgradePlot" and Progression.level(d)>levelBefore then
		-- one step per plot upgrade from Factory III on (Factory II is the last goal), in order
		for lv=math.max(2,levelBefore+1),Progression.level(d) do
			local step=#C.TutorialSteps+C.MainGoals+lv-1 Analytics.funnelStep(p,d.onboarding,step,C.FunnelNames[step])
		end
	end
	-- 3 Nov (vault audit: "time per step logged"): minutes played when each factory
	-- level and each rebirth is reached, to see how long the long loop really takes
	-- (vault target: first rebirth in 1-3 h). Value = minutes played (playSeconds).
	if ok and name=="UpgradePlot" and Progression.level(d)>levelBefore then
		Analytics.custom(p,if (d.crushers.rebirths or 0)==0 then "ReachedFactory" else "ReachedFactoryAfterRebirth",
			math.floor((d.playSeconds or 0)/60),C.PlotUpgrade.Names[Progression.level(d)])
		if d.fullClock==true and (d.crushers.rebirths or 0)==0 then
			Analytics.custom(p,"ReachedFactoryNew",math.floor((d.playSeconds or 0)/60),C.PlotUpgrade.Names[Progression.level(d)])
		end
	end
	if ok and name=="Rebirth" then
		Analytics.custom(p,"RebirthMinutes",math.floor((d.playSeconds or 0)/60),"Rebirth "..d.crushers.rebirths)
		if d.fullClock==true then Analytics.custom(p,"RebirthMinutesNew",math.floor((d.playSeconds or 0)/60),"Rebirth "..d.crushers.rebirths) end
	end
	-- plot upgrade cutscene: only the buyer, only after the server confirmed it
	if ok and name=="Rebirth" then
		-- everyone sees it; the factory goes back to the ground floor (bay models rebuilt)
		Turbo.resetPeak(p)
		Analytics.custom(p,"CrusherRebirth",d.crushers.rebirths)
		Net.event("RarePull"):FireAllClients({text=p.DisplayName.." REBIRTHED! (x"..C.rebirthMult(d.crushers.rebirths).." income, x"..C.rebirthLuck(d.crushers.rebirths).." luck)",userId=p.UserId,color=Color3.fromRGB(255,170,60)})
		Net.event("RebirthDone"):FireClient(p,{rebirths=d.crushers.rebirths,mult=C.rebirthMult(d.crushers.rebirths),luck=C.rebirthLuck(d.crushers.rebirths)})
		-- 9 Nov: the Gem Mine opens at rebirth 1, its Gem Crusher awakens at rebirth 5 (announced)
		if d.crushers.rebirths==Gems.Mine.AwakenRebirths then
			Net.event("RarePull"):FireAllClients({text=p.DisplayName.." AWAKENED THE GEM CRUSHER!",userId=p.UserId,color=Color3.fromRGB(235,80,210)})
		end
		GemMine.refresh(p)
	end
	-- 8 Nov: Gem Shop analytics; a Gem Crate Exotic or better is announced to the server
	if ok and name=="GemUpgrade" and type(result)=="table" then
		Analytics.custom(p,"GemUpgrade",result.level,result.id)
		Analytics.gems(p,"GemUpgrade:"..tostring(result.id),"Shop",-(result.cost or 0),d.crushers.gems)
		GemMine.refresh(p) -- 10 Nov: a mine upgrade (speed, magnet...) applies at once
	end
	if ok and name=="GemCrate" and type(result)=="table" then
		Analytics.custom(p,"GemCrate",1,result.rarity)
		Analytics.gems(p,"GemCrate","Shop",-Gems.Crate.Cost,d.crushers.gems)
		local r=C.rarity(result.rarity)
		if r and r.rank>=4.25 then Net.event("RarePull"):FireAllClients({text=p.DisplayName.." opened a "..string.upper(result.rarity).." "..C.typeById(result.type).name.." from the Gem Crate!",userId=p.UserId,color=r.color}) end
	end
	if ok and name=="UpgradePlot" and Progression.level(d)>levelBefore then
		Net.event("PlotUpgraded"):FireClient(p,upgradeSummary(levelBefore,Progression.level(d)))
		-- 11 Nov: the Gem Mine needs FACTORY IV (and rebirth 1): its portal appears in the rear yard
		GemMine.refresh(p)
		if Gems.mineOpen(d.crushers) and levelBefore<Gems.UnlockPlot then
			Net.event("Notice"):FireClient(p,{text="The GEM MINE is open! Its portal is in your rear yard."})
		end
	end
	ctx.justRolled=ok and name=="Roll" or nil
	send(p,if ok and name=="Roll" then nil else message,if name=="Buy" or name=="Fuse" or name=="CollectFusion" or name=="ApplyCoating" then result else nil) ctx.justRolled=nil ctx.justDiscovered=nil
	return ok,message,result
end
-- the toy a crusher of this rarity crushes (C.RarityObjects), as a Config.Objects index
local objectIndex={} for i,def in Config.Objects do objectIndex[def.name]=i end
local function objectFor(rarity)
	local list=C.RarityObjects[rarity] or C.RarityObjects.Common
	return objectIndex[list[rng:NextInteger(1,#list)]] or 1
end
local function visualEvent(p,event)
	local v=sessions[p].visuals[event.bay] if not v then return end
	if event.kind=="Input" then
		-- 31 Oct: the flattened toy stays on the bed a moment under the new one
		-- (fast crushers swapped them in ~0.1 s and it read as flickering)
		if v.input then
			local old=v.input old.Name="CrushedInput"
			if (old:GetAttribute("SquashFraction") or 1)<1 then task.delay(C.CrushedLinger,function() if old.Parent then old:Destroy() end end) else old:Destroy() end
		end
		v.objectIndex=objectFor(v.rarity)
		v.input=Objects.build(v.objectIndex,v.base,"Normal") v.input.Name="ProductionInput" v.input.Parent=v.model
		local _,size=v.input:GetBoundingBox()
		local scale=math.min(1,v.clearance*.9/size.Y,v.bedWidth/(math.max(size.X,size.Z)*1.1)) -- big toys (rarer crushers) fill more of the bed
		Objects.scale(v.input,v.base,scale) v.input:SetAttribute("Height",size.Y*scale)
		v.input:SetAttribute("SquashFraction",1) v.inputFraction=1
	else
		local before=v.inputFraction or 1 v.inputFraction=event.fraction
		local timing=Feel.strike(v,event,before) local input=v.input
		-- The authoritative display catches up at contact, never before the ram.
		task.delay(timing.hit,function()
			if v.model.Parent and input and input.Parent and v.input==input then
				Objects.setSquash(input,v.base,event.fraction) input:SetAttribute("SquashFraction",event.fraction)
			end
		end)
		-- 11 Nov (audit 8): the motion plays on the clients near this factory (CrusherMotion)
		local impactAt=workspace:GetServerTimeNow()+timing.hit
		if v.catalog or v.special then MotionServer.strike(v,event,impactAt) return end
		local height=(if v.input then v.input:GetAttribute("Height") else Config.Objects[v.objectIndex or v.tier].height)*event.fraction
		MotionServer.strike(v,event,impactAt,v.base.Position.Y+height+v.ram.Size.Y/2)
	end
end
function G.start()
	Data.start("CrushItPlayer_v1",{cash=C.StartCash,scrap=0,purchases={},daily={day=0,streak=0},goldenRush=0,lastSeen=0},function(d) return Rules.migrate(d,guid) end)
	Plots.create() require(script.Parent.World).create() Friend.start()
	require(script.Parent.RobuxSigns).start(Plots.all) -- 31 Oct: clickable Robux signs on the plots
	require(script.Parent.CrusherPreviews).start()
	for _,plot in Plots.all() do for _,bay in plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.label.line.Text="" bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false bay.max.Visible=false end end
	for _,plot in Plots.all() do pedestalLook(plot,C.StartPedestals,false) end
	for _,plot in Plots.all() do floorLook(plot,0) ProgressVisuals.sync(plot,nil,nil,0,"") for i,bay in plot.bays do if floorFor(plot,i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end end
	require(script.Parent.Moat).start(function(p) local ctx=sessions[p] return if ctx then Plots.spawnFor(ctx.plot) else CFrame.new(0,5,14) end, G.safeTeleport)
	require(script.Parent.Kit.Leaderboard).start({store="CashBoard_v1",score=function(p) return p:GetAttribute("Cash") or 0 end})
	local function spawnCharacter(p,char)
		local h=char:WaitForChild("Humanoid",10) local root=char:WaitForChild("HumanoidRootPart",10)
		if h then h.WalkSpeed=Config.PlayerWalkSpeed end
		local ctx=sessions[p] if root and ctx then G.safeTeleport(p,char,Plots.spawnFor(ctx.plot)) end
	end
	local function join(p)
		local d=Data.whenLoaded(p) if not d then return end
		-- onboarding funnel: only saves that start here fresh (tutorial step 1); step 1 = Joined
		if d.onboarding==nil then d.onboarding={funnel=d.crushers.tutorial==1,funnelStep=0} end
		-- 4 Nov: a brand-new save counts its playtime from the very first second
		-- (playSeconds only exists since 2 Nov, so older saves undercount). Timing
		-- events from these saves also go out as *New (clean numbers for pacing).
		if d.fullClock==nil and d.crushers.tutorial==1 and (d.playSeconds or 0)<=5 and (d.crushers.rolls or 0)==0 then d.fullClock=true end
		Analytics.funnelStep(p,d.onboarding,1,C.FunnelNames[1])
		local plot for _,v in Plots.all() do if not v.owner then plot=v break end end
		if not plot then p:Kick("All factory plots are occupied. Please join another server.") return end
		plot.owner=p plot.sign.Text=p.DisplayName.."'s Factory"
		p.CameraMaxZoomDistance=C.CameraMaxZoom
		sessions[p]={plot=plot,visuals={},bays={},nextRoll=restoredCooldown(d),lastRequest=0}
		task.spawn(function() local ctx=sessions[p] if ctx then ctx.inGroup=checkGroup(p,false) end end)
		local ls=Instance.new("Folder") ls.Name="leaderstats" ls.Parent=p local cash=Instance.new("StringValue") cash.Name="Cash" cash.Parent=ls
		p:GetAttributeChangedSignal("Cash"):Connect(function() cash.Value=Format.cash(p:GetAttribute("Cash") or 0) end)
		p.CharacterAdded:Connect(function(char) spawnCharacter(p,char) end)
		if p.Character then task.spawn(spawnCharacter,p,p.Character) end
		reconcile(p) send(p)
		task.defer(GemMine.refresh,p) -- 9 Nov: your pad, teleporter text, gems
	end
	-- 9 Nov: THE GEM MINE (server/GemMine)
	GemMine.start({
		data=function(p) return Data.get(p) end,
		plot=function(p) local ctx=sessions[p] return ctx and ctx.plot end,
		plots=function() return Plots.all() end,
		teleport=function(p,cf) local char=p.Character if char then G.safeTeleport(p,char,cf) end end,
		home=function(p) local ctx=sessions[p] local char=p.Character if ctx and char then G.safeTeleport(p,char,Plots.spawnFor(ctx.plot)) end end,
		refreshState=function(p) send(p) end,
	})
	for _,plot in Plots.all() do
		for name,station in plot.stations do if station.prompt then station.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then Net.event("Notice"):FireClient(p,{text="Use your own factory."}) return end
			if name=="Production" or name=="Rolling" or name=="Trash" or name=="Turbo" then Net.event("CrusherOpen"):FireClient(p,name) else action(p,name) end
		end) end end
		for slot,ped in plot.stations.Roll.pedestals do ped.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then Net.event("Notice"):FireClient(p,{text="Use your own factory."}) return end
			action(p,"Buy",{slot=slot})
		end) end
		for i,bay in plot.bays do bay.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then return end
			-- holding a crusher from the backpack: place it in this bay
			local held=Tools.held(p) if held then action(p,"Equip",{id=held,bay=i}) return end
			Net.event("CrusherOpen"):FireClient(p,"Inventory",i)
		end) end
	end
	-- Top travel buttons: to the Mega Crusher (hub) or back to your factory.
	local lastTravel={}
	Net.event("Travel").OnServerEvent:Connect(function(p,where)
		local ctx=sessions[p] local char=p.Character
		if not ctx or not char or (where~="Hub" and where~="Plot") then return end
		if os.clock()-(lastTravel[p] or 0)<C.TravelCooldown then return end lastTravel[p]=os.clock()
		if where=="Plot" then G.safeTeleport(p,char,Plots.spawnFor(ctx.plot)) return end
		local spawn=workspace:FindFirstChild("HubSpawn",true)
		local y=(if spawn then spawn.Position.Y else 0)+3
		G.safeTeleport(p,char,CFrame.lookAt(Vector3.new(0,y,C.HubTravelZ),Vector3.new(0,y,0)))
	end)
	Players.PlayerRemoving:Connect(function(p) lastTravel[p]=nil end)
	Players.PlayerAdded:Connect(join) for _,p in Players:GetPlayers() do task.spawn(join,p) end
	Players.PlayerRemoving:Connect(function(p)
		local ctx=sessions[p] if ctx then for _,v in ctx.visuals do v.model:Destroy() end ctx.plot.owner=nil ctx.plot.sign.Text="Free factory"
			if ctx.plot.progression and ctx.plot.progression.levelText then ctx.plot.progression.levelText.Text="" end ctx.rollToken=nil
			for i in ctx.plot.stations.Roll.pedestals do clearOffer(ctx.plot,i) end ctx.plot.pedestalCount=nil pedestalLook(ctx.plot,C.StartPedestals,false)
			for i,bay in ctx.plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.label.line.Text="" bay.label.scope.Text="BAY "..i Workshop.clearPurchase(bay.buy) bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false bay.max.Visible=false end end
			floorLook(ctx.plot,0) RowVisuals.sync(ctx.plot,nil) ProgressVisuals.sync(ctx.plot,nil,nil,0,"") for i,bay in ctx.plot.bays do if floorFor(ctx.plot,i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end
		sessions[p]=nil
	end)
	Net.event("CrusherAction").OnServerEvent:Connect(function(p,name,args)
		local ctx=sessions[p] local d=Data.get(p) if not ctx or not d or type(name)~="string" then return end
		args=if type(args)=="table" then args else {}
		local favoriteAck=name=="FavoriteConfirmed"
		-- A fast already-favorited read can finish before RequestInterval. The
		-- one-use challenge gates its acknowledgement instead of dropping it.
		if favoriteAck and not Goals.validFavorite(ctx,args.token,workspace:GetServerTimeNow()) then return end
		local now=os.clock() if not favoriteAck and now-ctx.lastRequest<C.RequestInterval then return end ctx.lastRequest=now
		if name=="Sync" then send(p) return end
		if name=="GroupCheck" then ctx.inGroup=checkGroup(p,true) send(p) return end
		-- World purchases require the owner's own station and a nearby character.
		local target local reach=C.Layout.InteractionDistance
		if name=="Upgrade" or name=="UpgradeMany" then local u=C.Upgrades[args.id] if u then target=ctx.plot.stations[u.group].part end
		elseif name=="Level" or name=="LevelMax" or name=="Unlock" then
			local bay=if type(args.bay)=="number" then ctx.plot.bays[args.bay] else nil
			if bay and (name=="Unlock" and args.bay==d.crushers.bays+1 or name~="Unlock" and d.crushers.equipped[tostring(args.bay)]==args.id) then target=bay.part end
			local f=type(args.bay)=="number" and floorFor(ctx.plot,args.bay)
			if name=="Unlock" and f and f.face and f.first==args.bay and args.bay==d.crushers.bays+1 then target=f.face reach=45 end
		elseif name=="TimeSkip" or name=="FavoriteStart" or name=="FavoriteConfirmed" then target=ctx.plot.stations.Goals and ctx.plot.stations.Goals.part
		elseif name=="Buy" then local ped=type(args.slot)=="number" and ctx.plot.stations.Roll.pedestals[args.slot] if ped then target=ped.part end
		elseif name=="UpgradePlot" then target=ctx.plot.progression.upgrade.part
		elseif name=="Fuse" or name=="CollectFusion" then target=ctx.plot.stages and ctx.plot.stages.fuserPart reach=26
		elseif name=="QuoteCoating" or name=="ApplyCoating" then target=ctx.plot.progression.lab.part
		elseif name=="TrashMany" then target=ctx.plot.stations.Trash and ctx.plot.stations.Trash.part reach=40
		elseif ctx.plot.stations[name] then target=ctx.plot.stations[name].part end
		if name~="Equip" and name~="Unequip" and name~="Recycle" and name~="RecycleDuplicates" and name~="EquipBest" and name~="Rebirth" and name~="Rebuild" and name~="FillRow" and name~="SkipTutorial" and name~="GemUpgrade" and name~="GemCrate" then
			local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not target or not root or (root.Position-target.Position).Magnitude>reach then send(p,"Walk closer to your station or bay control.") return end
		end
		if name=="SkipTutorial" then -- 5 Nov: tutorial SKIP button (after a confirm on the client)
			local before=d.cash local from=Rules.tutorialSkip(d)
			if not from then send(p) return end
			Analytics.cash(p,"TutorialSkip","Onboarding",before,d.cash)
			Analytics.custom(p,"TutorialSkipped",from,C.TutorialSteps[from].id)
			send(p,"Tutorial skipped: +"..Format.cash(d.cash-before).."!") task.spawn(Data.saveNow,p) return
		end
		if name=="Trash" then Net.event("CrusherOpen"):FireClient(p,"Trash") return end -- the trash can's own button opens the picker
		if name=="Turbo" then Net.event("CrusherOpen"):FireClient(p,"Turbo") return end -- the pump's button opens the Turbo menu
		if name=="FavoriteStart" then
			Goals.beginFavorite(ctx,guid(),workspace:GetServerTimeNow()) send(p) return
		elseif name=="FavoriteConfirmed" then
			if Goals.confirmFavorite(ctx,args.token,workspace:GetServerTimeNow()) then send(p) end return
		elseif name=="TimeSkip" then
			if not ctx.favoriteConfirmed then send(p,"Favorite the game first, then join the group.") return end
			if workspace:GetServerTimeNow()<(d.timeSkipAt or 0) then send(p,"Your next free time skip isn't ready yet.") return end
			if ctx.goalClaimBusy then return end ctx.goalClaimBusy=true
			local ok,err=pcall(function()
				-- Refresh even a previously true membership, then revalidate after
				-- the yielding API call. No overlapping request can grant twice.
				local member=checkGroup(p,true)
				if sessions[p]~=ctx or Data.get(p)~=d then return end
				ctx.inGroup=member
				local skipCash=d.cash
				local granted,reason=Goals.claim(ctx,d,workspace:GetServerTimeNow(),skipReward(p,d),C.Goals.SkipCooldownHours*3600,C.money)
				if d.cash~=skipCash then Analytics.cash(p,"TimeSkip","TimedReward",skipCash,d.cash) end
				send(p,if granted then "Done!" else reason)
			end)
			ctx.goalClaimBusy=false
			if not ok then warn("[Goals] Claim failed: "..tostring(err)) send(p,"Couldn't check your goals. Please try again.") end
			return
		end
		action(p,name,args)
	end)
	local elapsed,lastSend,lastAuto=0,0,0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt if elapsed<C.Tick then return end elapsed=0 local now=os.clock()
		for p,ctx in sessions do local d=Data.get(p) if d then
			for _,event in Rules.step(d,ctx,now,perks(p)) do visualEvent(p,event) end
			if now-lastAuto>=C.AutoCollectInterval and Store.hasPass(p,"AutoCollect") then
				if d.crushers.available>0 then Rules.act(d,ctx,"Collect",{},now,random,guid,perks(p)) end
				if d.scrap>0 then local before=d.cash Rules.act(d,ctx,"Sell",{},now,random,guid,perks(p)) Analytics.cash(p,"AutoSell","Gameplay",before,d.cash) end
			end
			if now-lastSend>=1 then send(p) Analytics.cashBalance(p,d.cash) end
		end end
		Feel.flush(now) MotionServer.flush(now)
		if now-lastSend>=1 then lastSend=now end if now-lastAuto>=C.AutoCollectInterval then lastAuto=now end
	end)
	local api={getData=Data.get,whenLoaded=Data.whenLoaded,save=Data.saveNow,canSave=Data.canSave,sync=function(p) send(p) end,
		-- reward crusher: random type of that rarity, Standard, level 1; nil when full
		-- typeId: a specific type of that rarity (shop Mythics); force: ignore the
		-- inventory limit (paid items must always arrive)
		giveCrusher=function(p,rarityName,typeId,force)
			local d=Data.get(p) local r=C.rarity(rarityName)
			if not d or not r or #r.types==0 or (#d.crushers.owned>=C.MaxInventory and not force) then return nil end
			-- a specific type must belong to that rarity (crate-only types via C.rarityOf)
			if typeId and C.rarityOf(typeId)~=r then return nil end
			local item={id=guid(),type=typeId or r.types[rng:NextInteger(1,#r.types)],rarity=r.name,modifier="Standard",level=1}
			table.insert(d.crushers.owned,item) send(p)
			return C.typeById(item.type).name
		end,
		-- sku / tx: the reason for the economy dashboard (Kit/Analytics.cash)
		addCash=function(p,n,sku,tx) local d=Data.get(p) if d then local before=d.cash d.cash=C.money(d.cash+n) if sku then Analytics.cash(p,sku,tx or "Gameplay",before,d.cash) end send(p) end end,
		cashPerSecond=function(p) local d=Data.get(p) return if d then cps(p,d) else 0 end,
		-- the short-lived part of the cash multiplier (2x Cash boost), for Turbo prices
		shortBoost=function(p) return if Boost.active(p,"Cash",workspace:GetServerTimeNow()) then 2 else 1 end,
		eventPlot=function(p) local ctx=sessions[p] return if ctx then ctx.plot else nil end,
		eventFleet=function(p)
			local d=Data.get(p) if not d then return nil end
			local rows=Rows.snapshot(d) local buffs=perks(p)
			return require(RS.Shared.FactoryEventRules).snapshot(d,C.bayCapacity(d.crushers.plotLevel),C.rarityOf,
				function(item) return Rules.stats(d,item,buffs,rows) end)
		end,
		finishLegacyProduct=function(p) local d=Data.get(p) if d then d.scrap=C.money(d.scrap+d.crushers.available) d.crushers.available=0 action(p,"Sell") end end}
	require(script.Parent.Shop).start(api) require(script.Parent.Rewards).start(api)
	require(script.Parent.DailySpin).start(api)
	require(script.Parent.OvernightCrate).start(api) -- 8 Nov: the Mystery Crate
	require(script.Parent.Quests).start(api)
	require(script.Parent.TopBoards).start(api)
	require(script.Parent.Boosts).start(api)
	require(script.Parent.FactoryEvents).start(api)
	require(script.Parent.IndexRewards).start(api)
	require(script.Parent.Codes).start(api)
	Turbo.start(api)
	Frenzy.start(api)
	require(script.Parent.GoldenToys).start(api)
	require(script.Parent.WhatsNew).start(api)
	require(script.Parent.Referral).start(api) -- 4 Nov: invite a friend -> both get a Legendary
	require(script.Parent.Feedback).start(api) -- 5 Nov: the one-tap survey
	require(script.Parent.Settings).start(api) -- 6 Nov: the SETTINGS menu (music, sounds, shake, effects, vibration)
	require(script.Parent.AutoRoll).start({action=action,session=function(p) return sessions[p] end,getData=Data.get}) -- 7 Nov: AUTO ROLL (free) + AUTO BUY (pass)
	require(script.Parent.NameTags).start() -- 5 Nov: VIP / PLUS tag above the head
	-- /credits <amount> (or /cash): test cash, e.g. "/credits 5m". No amount gives 1M.
	-- 11 Nov (Willem: "we have the dev panel now"): Studio only, never in live servers
	-- (it put test cash into the leaderboard and the economy analytics).
	local SUFFIX={k=1e3,m=1e6,b=1e9,t=1e12,qa=1e15}
	local function isAdmin(_p) return RunService:IsStudio() end
	local function credits(p,text)
		if not isAdmin(p) then return end
		local arg=string.split(text," ")[2]
		local amount=1e6
		if arg and arg~="" then
			local num,suffix=string.match(string.lower(arg),"^([%d%.]+)(%a*)$")
			local n=tonumber(num)
			if not n or (suffix~="" and not SUFFIX[suffix]) then Net.event("Notice"):FireClient(p,{text="Use: /credits 5m"}) return end
			amount=math.floor(n*(SUFFIX[suffix] or 1))
		end
		if amount<=0 or amount~=amount or amount==math.huge then return end
		api.addCash(p,amount)
		Net.event("Notice"):FireClient(p,{text="+"..Format.cash(amount).." (dev)"})
	end
	local TCS=game:GetService("TextChatService")
	local command=Instance.new("TextChatCommand") command.Name="CreditsCommand"
	command.PrimaryAlias="/credits" command.SecondaryAlias="/cash"
	command.Triggered:Connect(function(source,text) local p=Players:GetPlayerByUserId(source.UserId) if p then credits(p,text) end end)
	command.Parent=TCS
	local function hook(p) p.Chatted:Connect(function(m) local c=string.lower(string.split(m," ")[1] or "") if c=="/credits" or c=="/cash" then credits(p,m) end end) end
	if TCS.ChatVersion~=Enum.ChatVersion.TextChatService then Players.PlayerAdded:Connect(hook) for _,p in Players:GetPlayers() do hook(p) end end
	-- /event [start|win|cancel|halloween|bear]: test the factory event (Studio only)
	if RunService:IsStudio() then
		local eventCommand=Instance.new("TextChatCommand") eventCommand.Name="EventCommand" eventCommand.PrimaryAlias="/event"
		eventCommand.Triggered:Connect(function(source,text)
			local p=Players:GetPlayerByUserId(source.UserId)
			local dev=game.ServerStorage:FindFirstChild("DevFactoryEvent")
			if not p or not dev then return end
			local arg=string.lower(string.split(text," ")[2] or "start")
			local name=if arg=="win" then "Win" elseif arg=="cancel" then "Cancel" else "Start"
			-- /event halloween or /event bear picks the version (default: the scheduled one)
			local which=if arg=="halloween" then "Halloween" elseif arg=="bear" then "Bear" else nil
			local ok=dev:Invoke(name,which)
			Net.event("Notice"):FireClient(p,{text="Event "..string.lower(name)..(if ok then "" else ": not possible right now")})
		end)
		eventCommand.Parent=TCS
		-- 5 Nov (Willem): /skip finishes the tutorial at once (its rewards are paid, like the
		-- SKIP button); /skip goals also jumps past the main goals to the quiet ones (no goal
		-- rewards). Studio only.
		local skipCommand=Instance.new("TextChatCommand") skipCommand.Name="SkipCommand" skipCommand.PrimaryAlias="/skip"
		skipCommand.Triggered:Connect(function(source,text)
			local p=Players:GetPlayerByUserId(source.UserId) local d=p and Data.get(p)
			if not p or not d then return end
			local s=d.crushers
			while C.TutorialSteps[s.tutorial] do Rules.tutorialAdvance(d,C.TutorialSteps[s.tutorial].id) end
			local goals=string.lower(string.split(text," ")[2] or "")=="goals"
			if goals then s.goal=math.max(s.goal or 1,C.MainGoals+1) end
			send(p,if goals then "Tutorial and main goals skipped (dev)" else "Tutorial skipped (dev)")
		end)
		skipCommand.Parent=TCS
		-- 5 Nov (Willem): /bigroll [secret|divine|limited] rolls at once with that rarity on the first
		-- pedestal, to test the big roll cinematic (default: secret). Studio only.
		local bigCommand=Instance.new("TextChatCommand") bigCommand.Name="BigRollCommand" bigCommand.PrimaryAlias="/bigroll"
		bigCommand.Triggered:Connect(function(source,text)
			local p=Players:GetPlayerByUserId(source.UserId) local ctx=p and sessions[p]
			if not p or not ctx then return end
			local arg=string.lower(string.split(text," ")[2] or "secret")
			local rarity=if arg=="divine" then "Divine" elseif arg=="limited" then "Limited" elseif arg=="eternal" then "Eternal" else "Secret"
			ctx.forceRarity=rarity
			local ok,message=action(p,"Roll",{})
			if not ok then ctx.forceRarity=nil end
			Net.event("Notice"):FireClient(p,{text=if ok then "Big roll test: "..rarity.." (dev)" else "Big roll test: "..tostring(message)})
		end)
		bigCommand.Parent=TCS
		-- 8 Nov (Willem: "a command so I can skip to plots, or a dev panel"): /plot <1-5> jumps to
		-- that plot level with every bay of it unlocked; the DEV panel (client/DevPanel, Studio
		-- only) sends the same through the remote "Dev".
		local function devDo(p: Player, what: string, arg: any): string?
			local d=Data.get(p) local ctx=sessions[p]
			if not d or not ctx then return nil end
			local s=d.crushers
			if what=="Plot" then
				local level=math.clamp(math.floor(tonumber(arg) or 1),1,C.PlotUpgrade.MaxLevel)
				while C.TutorialSteps[s.tutorial] do Rules.tutorialAdvance(d,C.TutorialSteps[s.tutorial].id) end
				s.goal=math.max(s.goal or 1,C.MainGoals+1)
				s.plotLevel=level s.bays=math.max(s.bays,C.bayCapacity(level))
				GemMine.refresh(p) -- (11 Nov: the Gem Mine portal shows from Factory IV)
				ctx.bays={} reconcile(p) send(p,"Plot level "..level.." (dev)") return "ok"
			elseif what=="Skip" then
				while C.TutorialSteps[s.tutorial] do Rules.tutorialAdvance(d,C.TutorialSteps[s.tutorial].id) end
				if arg=="goals" then s.goal=math.max(s.goal or 1,C.MainGoals+1) end
				send(p,"Skipped (dev)") return "ok"
			elseif what=="Cash" then
				api.addCash(p,math.clamp(tonumber(arg) or 0,0,1e15)) send(p,"+cash (dev)") return "ok"
			elseif what=="BigRoll" then
				ctx.forceRarity=if arg=="Divine" or arg=="Limited" or arg=="Eternal" then arg else "Secret"
				local ok,message=action(p,"Roll",{}) if not ok then ctx.forceRarity=nil end
				return tostring(message)
			elseif what=="CrateReady" then
				if type(d.crate)=="table" and d.crate.readyAt then d.crate.readyAt=os.time()-1 end
				return "ok"
			-- 9 Nov: Gems tests (Willem: "make it so I can test it in the dev panel")
			elseif what=="Gems" then
				s.gems+=math.clamp(math.floor(tonumber(arg) or 0),0,1e6) p:SetAttribute("Gems",s.gems) send(p,"+Gems (dev)") return "ok"
			elseif what=="Rebirths" then
				s.rebirths=math.clamp(math.floor(tonumber(arg) or 0),0,100)
				GemMine.refresh(p)
				ctx.bays={} reconcile(p) send(p,"Rebirths = "..s.rebirths.." (dev)") return "ok"
			elseif what=="RebirthReady" then
				while C.TutorialSteps[s.tutorial] do Rules.tutorialAdvance(d,C.TutorialSteps[s.tutorial].id) end
				s.goal=math.max(s.goal or 1,C.MainGoals+1)
				s.plotLevel=math.max(s.plotLevel or 0,C.Rebirth.MinPlot) s.bays=math.max(s.bays,C.bayCapacity(s.plotLevel))
				d.cash=math.max(d.cash,C.rebirthCost(s.rebirths or 0))
				ctx.bays={} reconcile(p) send(p,"Rebirth ready (dev)") return "ok"
			elseif what=="RebirthNow" then
				local ok,message=action(p,"Rebirth",{}) return tostring(ok)..tostring(message)
			elseif what=="GemUps" then
				for _,u in Gems.Upgrades do s.gemUps[u.id]=if arg=="max" then u.max else 0 end
				ctx.bays={} reconcile(p) send(p,"Gem upgrades "..tostring(arg).." (dev)") return "ok"
			-- 9 Nov: preview an Eternal model (not a crusher type yet) in bay 1, biting every 2 s.
			-- "Clear" puts the bay's real crusher back.
			elseif what=="EternalPreview" then
				local bay=ctx.plot.bays[1] if not bay then return "no bay" end
				local equipped=s.equipped["1"] local item=equipped and Rules.find(d,equipped)
				if arg=="clear" then buildBay(p,1,item) return "ok" end
				local v=Special.build(bay.origin,tostring(arg))
				if not v then return "template or metadata missing: "..tostring(arg) end
				local old=ctx.visuals[1] if old then old.model:Destroy() end
				v.model.Name="EquippedCrusher" v.model:SetAttribute("Preview",true) v.model:SetAttribute("MotionLoop",2) v.model.Parent=bay.model
				local t=item and C.typeById(item.type)
				v.id=item and item.id or "preview" v.tier=t and t.input or 1 v.rarity="Preview"
				ctx.visuals[1]=v
				send(p,"Preview: "..tostring(arg).." in bay 1 (dev)") return "ok"
			-- 9 Nov: fill every open bay (Willem: "fill all rows"). "rows": one rarity per row,
			-- so the row bonuses switch on; "specials": the heaviest models everywhere (lag test);
			-- "empty": take everything out except bay 1. Dev crushers are added to the inventory.
			elseif what=="FillRows" then
				if arg=="empty" then
					local keep=s.equipped["1"] s.equipped={} if keep then s.equipped["1"]=keep end
				else
					local heavy={}
					for _,r in C.Rarities do if r.name=="Exotic" or r.name=="Secret" or r.name=="Divine" or r.name=="Eternal" then for _,t in r.types do table.insert(heavy,{t,r.name}) end end end
					for i=1,s.bays do if not s.equipped[tostring(i)] then
						local typeId,rarity
						if arg=="specials" and #heavy>0 then local h=heavy[(i-1)%#heavy+1] typeId,rarity=h[1],h[2]
						else local r=C.Rarities[(Rows.index(i)-1)%#C.Rarities+1] typeId,rarity=r.types[(i-1)%#r.types+1],r.name end
						local item={id=guid(),type=typeId,rarity=rarity,modifier=C.Modifiers[1].name,level=1}
						table.insert(s.owned,item) s.equipped[tostring(i)]=item.id
					end end
					Rules.markSeen(s)
				end
				ctx.bays={} reconcile(p) send(p,"Bays "..tostring(arg).." (dev)") return "ok"
			elseif what=="Weekend" then
				workspace:SetAttribute("WeekendTest",if workspace:GetAttribute("WeekendTest")=="active" then nil else "active")
				return tostring(workspace:GetAttribute("WeekendTest"))
			end
			return nil
		end
		Net.event("Dev").OnServerEvent:Connect(function(p,what,arg)
			if type(what)=="string" then devDo(p,what,arg) end
		end)
		local plotCommand=Instance.new("TextChatCommand") plotCommand.Name="PlotCommand" plotCommand.PrimaryAlias="/plot"
		plotCommand.Triggered:Connect(function(source,text)
			local p=Players:GetPlayerByUserId(source.UserId)
			if p then devDo(p,"Plot",string.split(text," ")[2]) end
		end)
		plotCommand.Parent=TCS
	end
	if RunService:IsStudio() then
		local dev=Instance.new("BindableFunction") dev.Name="DevCrusher"
		dev.OnInvoke=function(p,cmd,args)
			if cmd=="Get" then return Rules.copy(Data.get(p)) end
			if cmd=="Cash" then api.addCash(p,args) return true end
			-- Studio only: replay the cutscene for a plot level the player already owns (no data change)
			if cmd=="PreviewUpgrade" then
				local d=Data.get(p) local level=math.clamp(tonumber(args) or 1,1,C.PlotUpgrade.MaxLevel)
				assert(d and Progression.level(d)>=level,"Preview only levels the plot already has")
				Net.event("PlotUpgraded"):FireClient(p,upgradeSummary(level-1,level)) return true
			end
			if cmd=="Action" then return action(p,args.name,args.args) end
			if cmd=="ForceRoll" then sessions[p].forceRarity=args return true end -- 5 Nov: test the big roll cinematic
			if cmd=="Reload" then
				assert(Data.isMock(),"Mock store only") assert(Data.saveNow(p)) Data.reloadForTest(p)
				local ctx=sessions[p] ctx.bays={} ctx.nextRoll=restoredCooldown(Data.get(p)) reconcile(p) send(p) return true
			end
			if cmd=="Profile" then
				assert(Data.isMock(),"Profile injection requires Studio's in-memory store")
				Data.replaceForTest(p,args) local ctx=sessions[p] ctx.bays={} ctx.nextRoll=restoredCooldown(Data.get(p)) reconcile(p) send(p) return true
			end
		end dev.Parent=game.ServerStorage
	end
end
return G
