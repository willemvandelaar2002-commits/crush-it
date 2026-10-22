--!strict
-- Collectible crusher runtime. All mutations are non-yielding Rules transactions.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Http=game:GetService("HttpService")
local Config=require(RS.Shared.Config)
local C=Config.Crushers
local Rules=require(RS.Shared.CrusherRules)
local Net=require(RS.Shared.Net)
local Store=require(RS.Shared.Store)
local Format=require(RS.Shared.Format)
local Objects=require(RS.Shared.Objects)
local Data=require(script.Parent.Kit.DataService)
local Plots=require(script.Parent.Plots)
local PressBuilder=require(script.Parent.PressBuilder)
local Friend=require(script.Parent.FriendBoost)
local G={}
local sessions={}
local rng=Random.new()
local function guid() return Http:GenerateGUID(false) end
local function random() return rng:NextNumber() end
local function restoredCooldown(d)
	return os.clock()+math.clamp((d.crushers.rollReadyAt or 0)-workspace:GetServerTimeNow(),0,C.BaseRollSeconds)
end
local function perks(p)
	return {autoCrush=Store.hasPass(p,"AutoCrush"),lucky=Store.hasPass(p,"Lucky"),mult=(if Store.hasPass(p,"DoubleCash") then 2 else 1)*Friend.mult(p)}
end
local function cps(p,d)
	local total=0 for _,id in d.crushers.equipped do local item=Rules.find(d,id) if item then total+=Rules.stats(d,item,perks(p)).cps end end return total
end
local function send(p,message,result)
	local d=Data.get(p) local ctx=sessions[p] if not d or not ctx then return end
	local s=d.crushers
	if s.tutorial==5 and (s.upgrades.Damage+s.upgrades.Speed+s.upgrades.Yield)>0 then s.tutorial=6 end
	if s.tutorial==6 and (s.upgrades.Luck+s.upgrades.RollSpeed)>0 then s.tutorial=7 end
	if s.tutorial==7 then for _,v in s.owned do if v.level>1 then s.tutorial=8 break end end end
	p:SetAttribute("Cash",d.cash) p:SetAttribute("Scrap",d.scrap) p:SetAttribute("AvailableScrap",s.available)
	p:SetAttribute("Plot",ctx.plot.index) p:SetAttribute("Crushed",d.crushed) p:SetAttribute("Tier",d.tier)
	p:SetAttribute("AutoOn",true) p:SetAttribute("GoldenRush",d.goldenRush) p:SetAttribute("Rebirths",d.rebirths)
	local items={}
	for _,item in s.owned do
		local v=Rules.copy(item) v.stats=Rules.stats(d,item,perks(p)) v.cost=C.individualCost(item) table.insert(items,v)
	end
	Net.event("CrusherState"):FireClient(p,{cash=d.cash,carried=d.scrap,available=s.available,items=items,
		bays=s.equipped,unlocked=s.bays,upgrades=s.upgrades,tutorial=s.tutorial,rate=cps(p,d),
		rollSeconds=C.rollSeconds(s.upgrades.RollSpeed),rollReadyAt=workspace:GetServerTimeNow()+math.max(0,(ctx.nextRoll or 0)-os.clock()),
		message=message,result=result,lastRoll=ctx.lastRoll})
	ctx.plot.stations.Collect.label.Text="COLLECT SCRAP\n"..Format.cash(s.available).." ready"
	ctx.plot.stations.Collect.fill.Transparency=if s.available>0 then 0 else 1
	ctx.plot.stations.Sell.label.Text="SELL SCRAP\n"..Format.cash(d.scrap).." carried"
	for _,group in {"Production","Rolling"} do
		local lines={string.upper(group).." UPGRADES"}
		for _,id in C.UpgradeOrder do if C.Upgrades[id].group==group then
			local lv=s.upgrades[id] table.insert(lines,C.Upgrades[id].name.." Lv"..lv.."  "..(if lv>=C.MaxGlobal then "MAX" else Format.cash(C.globalCost(id,lv))))
		end end
		ctx.plot.stations[group].label.Text=table.concat(lines,"\n")
	end
	for i,bay in ctx.plot.bays do
		local item=Rules.find(d,s.equipped[tostring(i)])
		bay.label.Text=if item then C.typeById(item.type).name.." Lv"..item.level.."\n"..item.rarity.." / "..item.modifier.."\n"..Format.cash(Rules.stats(d,item,perks(p)).cps*60).." / min"
			else if i>s.bays then "BAY "..i.." LOCKED\nUnlock "..Format.cash(C.BayCosts[i]) else "BAY "..i.." EMPTY\nEquip an owned crusher" end
end
local function buildBay(p,i,item)
	local ctx=sessions[p] local bay=ctx.plot.bays[i] local old=ctx.visuals[i]
	if old then old.model:Destroy() ctx.visuals[i]=nil end
	if not item then return end
	local t=C.typeById(item.type) local o=bay.origin
	local built=PressBuilder.build(o,t.tier) built.model.WorldPivot=o
	local _,size=built.model:GetBoundingBox() local scale=math.min(1,24/size.X,24/size.Z,30/size.Y)
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
	built.model.Parent=bay.model
	local bed=(built.model:FindFirstChild("Bed") :: BasePart)
	ctx.visuals[i]={id=item.id,model=built.model,ram=built.ram,rest=built.ram.CFrame,
		base=CFrame.new(o.Position.X,bed.Position.Y+bed.Size.Y/2,o.Position.Z)*(o-o.Position),input=nil,tier=t.input}
end
local function reconcile(p)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return end
	for i=1,C.MaxBays do local item=Rules.find(d,d.crushers.equipped[tostring(i)]) local visual=ctx.visuals[i]
		if (item and item.id or nil)~=(visual and visual.id or nil) then buildBay(p,i,item) end
	end
end
local function action(p,name,args)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return false,"Profile is loading." end
	local ok,message,result=Rules.act(d,ctx,name,args,os.clock(),random,guid,perks(p))
	if ok and name=="Roll" then d.crushers.rollReadyAt=workspace:GetServerTimeNow()+math.max(0,ctx.nextRoll-os.clock()) end
	if ok then reconcile(p) end
	send(p,message,result) return ok,message,result
end
local function visualEvent(p,event)
	local v=sessions[p].visuals[event.bay] if not v then return end
	if event.kind=="Input" then
		if v.input then v.input:Destroy() end
		v.input=Objects.build(v.tier,v.base,"Normal") v.input.Name="ProductionInput" v.input.Parent=v.model
	else
		if v.input then Objects.setSquash(v.input,v.base,event.fraction) end
		local height=Config.Objects[v.tier].height*event.fraction
		local down=CFrame.new(v.rest.Position.X,v.base.Position.Y+height+v.ram.Size.Y/2,v.rest.Position.Z)*(v.rest-v.rest.Position)
		local duration=math.min(.45,event.cycle*.6)
		local model=v.model
		Tween:Create(v.ram,TweenInfo.new(duration*.4),{CFrame=down}):Play()
		task.delay(duration*.4,function() if model.Parent and v.ram.Parent then Tween:Create(v.ram,TweenInfo.new(duration*.6),{CFrame=v.rest}):Play() end end)
	end
end
function G.start()
	Data.start("CrushItPlayer_v1",{cash=C.StartCash,scrap=0,purchases={},daily={day=0,streak=0},goldenRush=0,lastSeen=0},function(d) return Rules.migrate(d,guid) end)
	Plots.create() require(script.Parent.World).create() Friend.start()
	require(script.Parent.Moat).start(function(p) local ctx=sessions[p] return if ctx then Plots.spawnFor(ctx.plot) else CFrame.new(0,5,14) end)
	require(script.Parent.Kit.Leaderboard).start({store="CashBoard_v1",score=function(p) return p:GetAttribute("Cash") or 0 end})
	local function spawnCharacter(p,char)
		local h=char:WaitForChild("Humanoid",10) local root=char:WaitForChild("HumanoidRootPart",10)
		if h then h.WalkSpeed=Config.PlayerWalkSpeed end
		local ctx=sessions[p] if root and ctx then char:PivotTo(Plots.spawnFor(ctx.plot)) end
	end
	local function join(p)
		local d=Data.whenLoaded(p) if not d then return end
		local plot for _,v in Plots.all() do if not v.owner then plot=v break end end
		if not plot then p:Kick("All factory plots are occupied. Please join another server.") return end
		plot.owner=p plot.sign.Text=p.DisplayName.."'s Factory"
		sessions[p]={plot=plot,visuals={},bays={},nextRoll=restoredCooldown(d),lastRequest=0}
		local ls=Instance.new("Folder") ls.Name="leaderstats" ls.Parent=p local cash=Instance.new("StringValue") cash.Name="Cash" cash.Parent=ls
		p:GetAttributeChangedSignal("Cash"):Connect(function() cash.Value=Format.cash(p:GetAttribute("Cash") or 0) end)
		p.CharacterAdded:Connect(function(char) spawnCharacter(p,char) end)
		if p.Character then task.spawn(spawnCharacter,p,p.Character) end
		reconcile(p) send(p)
	end
	for _,plot in Plots.all() do
		for name,station in plot.stations do station.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then Net.event("Notice"):FireClient(p,{text="Use your own factory."}) return end
			if name=="Production" or name=="Rolling" then Net.event("CrusherOpen"):FireClient(p,name) else action(p,name) end
		end) end
		for i,bay in plot.bays do bay.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then return end Net.event("CrusherOpen"):FireClient(p,"Inventory",i)
		end) end
	end
	Players.PlayerAdded:Connect(join) for _,p in Players:GetPlayers() do task.spawn(join,p) end
	Players.PlayerRemoving:Connect(function(p)
		local ctx=sessions[p] if ctx then for _,v in ctx.visuals do v.model:Destroy() end ctx.plot.owner=nil ctx.plot.sign.Text="Free factory" end sessions[p]=nil
	end)
	Net.event("CrusherAction").OnServerEvent:Connect(function(p,name,args)
		local ctx=sessions[p] if not ctx or type(name)~="string" then return end
		local now=os.clock() if now-ctx.lastRequest<C.RequestInterval then return end ctx.lastRequest=now
		if name=="Sync" then send(p) else action(p,name,args) end
	end)
	local elapsed,lastSend,lastAuto=0,0,0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt if elapsed<C.Tick then return end elapsed=0 local now=os.clock()
		for p,ctx in sessions do local d=Data.get(p) if d then
			for _,event in Rules.step(d,ctx,now,perks(p)) do visualEvent(p,event) end
			if now-lastAuto>=C.AutoCollectInterval and Store.hasPass(p,"AutoCollect") then
				if d.crushers.available>0 then Rules.act(d,ctx,"Collect",{},now,random,guid,perks(p)) end
				if d.scrap>0 then Rules.act(d,ctx,"Sell",{},now,random,guid,perks(p)) end
			end
			if now-lastSend>=1 then send(p) end
		end end
		if now-lastSend>=1 then lastSend=now end if now-lastAuto>=C.AutoCollectInterval then lastAuto=now end
	end)
	local api={getData=Data.get,whenLoaded=Data.whenLoaded,save=Data.saveNow,sync=function(p) send(p) end,
		addCash=function(p,n) local d=Data.get(p) if d then d.cash=C.money(d.cash+n) send(p) end end,
		cashPerSecond=function(p) local d=Data.get(p) return if d then cps(p,d) else 0 end,
		finishLegacyProduct=function(p) local d=Data.get(p) if d then d.scrap=C.money(d.scrap+d.crushers.available) d.crushers.available=0 action(p,"Sell") end end}
	require(script.Parent.Shop).start(api) require(script.Parent.Rewards).start(api)
	if RunService:IsStudio() then
		local dev=Instance.new("BindableFunction") dev.Name="DevCrusher"
		dev.OnInvoke=function(p,cmd,args)
			if cmd=="Get" then return Rules.copy(Data.get(p)) end
			if cmd=="Cash" then api.addCash(p,args) return true end
			if cmd=="Action" then return action(p,args.name,args.args) end
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
