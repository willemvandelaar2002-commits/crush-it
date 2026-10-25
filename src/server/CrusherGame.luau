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
local RollLook=require(RS.Shared.CrusherRollPresentation)
local UpgradeView=require(RS.Shared.CrusherUpgradeView)
local Objects=require(RS.Shared.Objects)
local Data=require(script.Parent.Kit.DataService)
local Plots=require(script.Parent.Plots)
local PressBuilder=require(script.Parent.PressBuilder)
local Workshop=require(script.Parent.Kit.CrusherWorkshop)
local Special=require(script.Parent.SpecialCrushers)
local Catalog=require(script.Parent.CatalogCrushers)
local Friend=require(script.Parent.FriendBoost)
local Tools=require(script.Parent.CrusherTools)
local Feel=require(script.Parent.CrusherFeedbackServer)
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
local function perks(p)
	return {autoCrush=Store.hasPass(p,"AutoCrush"),lucky=Store.hasPass(p,"Lucky"),mult=(if Store.hasPass(p,"DoubleCash") then 2 else 1)*Friend.mult(p)}
end
local function cps(p,d)
	local total=0 for _,id in d.crushers.equipped do local item=Rules.find(d,id) if item then total+=Rules.stats(d,item,perks(p)).cps end end return total
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
		local baseT=p:GetAttribute("BaseT")
		p.Transparency=if mode=="built" then baseT elseif mode=="ghost" then math.max(baseT,.62) else 1
		p.CanCollide=mode=="built" and p:GetAttribute("BaseC")==true
		p.CastShadow=mode=="built"
	end end
end
local function floorOf(i) local l=C.bayLayout(i) return if l.tier>1 then l.wing else nil end
local function floorLook(plot,unlocked)
	for _,f in plot.floors or {} do
		local mode=if unlocked>=f.first then "built" elseif unlocked+1==f.first then "ghost" else "hidden"
		if f.mode~=mode then
			local rise=f.mode=="ghost" and mode=="built"
			f.mode=mode
			partsLook(f.model,mode)
			if rise then
				-- the new floor (and its bays) rises up out of the ground floor's roof
				local models={f.model}
				for i,bay in plot.bays do local l=C.bayLayout(i) if l.tier>1 and C.floorStart(l.tier,l.wing)==f.first then table.insert(models,bay.model) end end
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
			partsLook(f.sign,if mode=="ghost" then "built" else "hidden")
			f.content.Visible=mode=="ghost"
		end
		f.buy.Text="BUILD "..Format.cash(C.BayCosts[f.first])
	end
end
-- Free time skip: SkipMinutes of the current production, paid as cash.
local function skipReward(p,d) return math.max(C.Goals.MinSkipReward,math.floor(cps(p,d)*C.Goals.SkipMinutes*60)) end
-- Group membership (IsInGroup is cached for the session; GetGroupsAsync is fresh).
local function checkGroup(p,fresh)
	local ok,inGroup=pcall(function()
		if not fresh then return p:IsInGroup(C.Goals.GroupId) end
		for _,g in game:GetService("GroupService"):GetGroupsAsync(p.UserId) do if g.Id==C.Goals.GroupId then return true end end
		return false
	end)
	return ok and inGroup==true
end
local function send(p,message,result)
	local d=Data.get(p) local ctx=sessions[p] if not d or not ctx then return end
	local s=d.crushers
	-- A first purchase (or spin prize) can make another visible offer of the
	-- same type known. Keep its badge honest without rebuilding the model.
	for slot,model in ctx.plot.offerModels or {} do
		if model.Parent and model:GetAttribute("RevealUnowned") and RollLook.owns(s.owned,model:GetAttribute("RevealType")) then
			model:SetAttribute("RevealUnowned",false)
			local card=ctx.plot.stations.Roll.pedestals[slot].card
			card.rarity.Text=card.rarity.Text:gsub(" · UNOWNED","")
		end
	end
	Rules.tutorialCatchUp(d)
	Tools.sync(p,d) -- unequipped crushers live in the Roblox backpack
	p:SetAttribute("Cash",d.cash) p:SetAttribute("Scrap",d.scrap) p:SetAttribute("AvailableScrap",s.available)
	p:SetAttribute("Plot",ctx.plot.index) p:SetAttribute("Crushed",d.crushed) p:SetAttribute("Tier",d.tier)
	p:SetAttribute("AutoOn",true) p:SetAttribute("GoldenRush",d.goldenRush) p:SetAttribute("Rebirths",d.rebirths)
	local items={}
	for _,item in s.owned do
		local v=Rules.copy(item) v.stats=Rules.stats(d,item,perks(p)) v.cost=C.individualCost(item) table.insert(items,v)
	end
	Net.event("CrusherState"):FireClient(p,{cash=d.cash,carried=d.scrap,available=s.available,items=items,
		bays=s.equipped,unlocked=s.bays,upgrades=s.upgrades,tutorial=s.tutorial,rate=cps(p,d),
		rollSeconds=C.rollSeconds(),rolled=ctx.justRolled,pedestals=C.pedestals(s.upgrades.Pedestals),rollReadyAt=workspace:GetServerTimeNow()+math.max(0,(ctx.nextRoll or 0)-os.clock()),
		message=message,result=result,lastRoll=ctx.lastRoll,discovery=ctx.justDiscovered})
	local st=ctx.plot.stations
	st.Collect.label.Text=Format.cash(s.available).." ready"
	-- The pile grows with ready scrap (about one minute of output fills it).
	local pieces=st.Collect.fill:GetChildren()
	local shown=if s.available<=0 then 0 else math.clamp(math.ceil(#pieces*s.available/math.max(1,cps(p,d)*60)),3,#pieces)
	if st.Collect.shown~=shown then st.Collect.shown=shown
		for i,v in pieces do v.Transparency=if i<=shown then 0 else 1 end
	end
	st.Sell.label.Text=Format.cash(d.scrap).." carried"
	local rolling=os.clock()<(ctx.nextRoll or 0)
	st.Roll.label.Text=if rolling then "Rolling..." else "Free  ·  "..C.pedestals(s.upgrades.Pedestals).." pedestal"..(if C.pedestals(s.upgrades.Pedestals)>1 then "s" else "")
	st.Roll.button.Text=if rolling then "ROLLING..." else "ROLL"
	pedestalLook(ctx.plot,C.pedestals(s.upgrades.Pedestals))
	local displayPerks=perks(p)
	for _,group in {"Production","Rolling"} do
		for _,id in C.UpgradeOrder do if C.Upgrades[id].group==group then
			local row=ctx.plot.stations[group].rows[id] local view=UpgradeView.board(d,id,displayPerks)
			row.label.Text=view.effect Workshop.purchase(row.button,view)
		end end
	end
	-- goals board: group row and the free time skip
	local goals=st.Goals and st.Goals.rows
	if goals then
		goals.Group.button.Text=if ctx.inGroup then "✓ JOINED" else "JOIN"
		goals.Group.label.Text=if ctx.inGroup then "Thanks for joining!" else "Unlocks the free time skip"
		local left=(d.timeSkipAt or 0)-workspace:GetServerTimeNow()
		goals.Skip.button.Text=if not ctx.inGroup then "JOIN FIRST" elseif left>0 then string.format("%02d:%02d:%02d",left//3600,left%3600//60,left%60) else "CLAIM"
		goals.Skip.label.Text="Get "..Format.cash(skipReward(p,d)).." instantly"
	end
	floorLook(ctx.plot,s.bays)
	for i,bay in ctx.plot.bays do
		-- bays on an upper floor that isn't built yet are invisible
		local wing=floorOf(i) local f=wing and ctx.plot.floors and ctx.plot.floors[wing]
		local hidden=f~=nil and f.mode~="built"
		if bay.hidden~=hidden then bay.hidden=hidden bay.shown=nil partsLook(bay.model,if hidden then "hidden" else "built") end
		if hidden then
			bay.label.name.Text="" bay.label.rarity.Text="" bay.label.stats.Text="" bay.label.scope.Text="" bay.buy.Visible=false bay.manage.Visible=false bay.lockLabel.Text=""
			continue
		end
		local item=Rules.find(d,s.equipped[tostring(i)])
		local state=if item then "busy" elseif i<=s.bays then "open" elseif i==s.bays+1 then "next" else "locked"
		local card=bay.label
		if item then
			card.scope.Text="THIS CRUSHER"
			local r=C.rarity(item.rarity)
			card.name.Text=C.typeById(item.type).name
			card.rarity.Text=item.rarity..(if item.modifier~="Standard" then "  ·  "..item.modifier.." x"..C.modifier(item.modifier).mult else "")
			card.rarity.TextColor3=r.color:Lerp(Color3.new(1,1,1),.25)
			local view=UpgradeView.crusher(d,item,displayPerks)
			card.stats.Text=view.effect Workshop.purchase(bay.buy,view)
		else
			card.scope.Text="BAY "..i
			card.name.Text=if state=="open" then "EMPTY BAY" elseif state=="next" then "NEXT BAY" else "LOCKED"
			card.rarity.Text=if state=="open" then "Equip a crusher here" elseif state=="next" then "Unlock for more output" else ""
			card.rarity.TextColor3=Color3.new(1,1,1)
			card.stats.Text=""
			if state=="next" then
				local view=UpgradeView.purchase(d.cash,C.BayCosts[i],false,"Adds a working bay; does not level a crusher.","BAY UNLOCKED!")
				view.button="UNLOCK\n"..Format.cash(C.BayCosts[i]) Workshop.purchase(bay.buy,view)
			else Workshop.clearPurchase(bay.buy) bay.buy.Text="EQUIP" end
		end
		local plate=if item then C.rarity(item.rarity).color:Lerp(Workshop.Navy,.2) else Workshop.Blue
		if bay.part.Color~=plate then bay.part.Color=plate end
		bay.buy.Visible=state~="locked"
		bay.manage.Visible=state=="busy"
		-- The direct plaque buttons replace the default prompt overlay, which can
		-- cover the small level button and intercept its mouse click.
		bay.prompt.Enabled=false
		bay.lockLabel.Text=if state=="next" then Format.cash(C.BayCosts[i]) elseif state=="open" then "EMPTY" else ""
		bayLook(bay,state)
	end
end
local function buildBay(p,i,item)
	local ctx=sessions[p] local bay=ctx.plot.bays[i] local old=ctx.visuals[i]
	if old then old.model:Destroy() ctx.visuals[i]=nil end
	if not item then return end
	local t=C.typeById(item.type) local o=bay.origin
	local special=Catalog.build(o,t.id) or (if t.template then Special.build(o,t.template) else nil)
	if special then
		special.id=item.id special.tier=t.input special.model.Name="EquippedCrusher"
		special.model:SetAttribute("InventoryId",item.id) special.model:SetAttribute("Rarity",item.rarity) special.model:SetAttribute("Modifier",item.modifier)
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
	built.model.Parent=bay.model
	local colors={Bumper=Color3.fromRGB(235,69,67),Steel=Color3.fromRGB(35,126,235),Cobalt=Color3.fromRGB(52,193,87),Mega=Color3.fromRGB(171,68,228),Titan=Color3.fromRGB(248,194,40),Quantum=Color3.fromRGB(50,208,220)}
	-- Coloured cap on top of the press (the light strip on the bay beam replaces the old beacon).
	local header=Workshop.part(built.model,"ToyHeader",Vector3.new(8.4,1,2),o*CFrame.new(0,l.MachineHeight-.5,1),colors[item.type] or Config.Presses[t.tier].accent)
	for _,x in {-3.3,3.3} do Workshop.part(built.model,"HeaderBolt",Vector3.new(.5,.5,.4),header.CFrame*CFrame.new(x,0,1.1),Color3.fromRGB(222,233,245)) end
	local bed=(built.model:FindFirstChild("Bed") :: BasePart)
	ctx.visuals[i]={id=item.id,model=built.model,ram=built.ram,rest=built.ram.CFrame,
		base=CFrame.new(o.Position.X,bed.Position.Y+bed.Size.Y/2,o.Position.Z)*(o-o.Position),input=nil,tier=t.input,
		clearance=built.ram.Position.Y-built.ram.Size.Y/2-(bed.Position.Y+bed.Size.Y/2),bedWidth=math.min(bed.Size.X,bed.Size.Z)}
	Feel.track(ctx.visuals[i],t.id)
end
local function reconcile(p)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return end
	for i=1,C.MaxBays do local item=Rules.find(d,d.crushers.equipped[tostring(i)]) local visual=ctx.visuals[i]
		if (item and item.id or nil)~=(visual and visual.id or nil) then buildBay(p,i,item) end
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
local function oddsText(typeId) return "[1 in "..Format.cash(C.oddsFor(typeId)):gsub("%$","").."]" end
-- Unlocked pedestals are yellow and empty until a roll; locked ones are grey
-- with a hint, so the ROLLING board upgrade is visible on the plot.
function pedestalLook(plot,count)
	if plot.pedestalCount==count then return end plot.pedestalCount=count
	for i,ped in plot.stations.Roll.pedestals do
		local open=i<=count
		ped.part.Color=if open then Workshop.Yellow else Color3.fromRGB(120,128,140)
		ped.part.Material=if open then Enum.Material.SmoothPlastic else Enum.Material.Slate
		if not open then card(ped,"LOCKED","More pedestals at","ROLL UPGRADES","","",Color3.fromRGB(200,205,215)) ped.prompt.Enabled=false
		elseif ped.card.name.Text=="LOCKED" then card(ped,"","","","","") end
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
	local seconds=math.max(1.2,(ctx.nextRoll or 0)-os.clock()) local token={} ctx.rollToken=token
	local rollId=guid() local rollData=Data.get(p) local rollPerks=perks(p)
	local rollLuck=rollData.crushers.upgrades.Luck local first=rollData.crushers.rolls==1
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
	-- turn a model slowly about its pedestal centre, from its stored base pose
	local function turn(m,centre,a,lift)
		local basePivot=m:GetAttribute("BasePivot")
		if typeof(basePivot)~="CFrame" then basePivot=m:GetPivot() m:SetAttribute("BasePivot",basePivot) end
		m:PivotTo(CFrame.new(0,lift or 0,0)*CFrame.new(centre)*CFrame.Angles(0,a,0)*CFrame.new(-centre)*basePivot)
	end
	local shown={} local nextFlick={}
	local function flick(slot,id)
		if shown[slot] then showModel(shown[slot],false) end
		local m=silhouetteFor(slot,id) shown[slot]=m showModel(m,true)
		local hl=plot.outlines[slot]
		if not hl then
			hl=Instance.new("Highlight") hl.Name="SilhouetteOutline" hl.FillColor=Color3.fromRGB(8,8,12) hl.FillTransparency=0 hl.OutlineTransparency=0
			hl.OutlineColor=Color3.new(1,1,1) hl.DepthMode=Enum.HighlightDepthMode.Occluded plot.outlines[slot]=hl
		end
		hl.Parent=m hl.Enabled=true
		card(st.pedestals[slot],"???","???","Rolling...","???","")
	end
	local function stop()
		for slot,m in shown do showModel(m,false) if plot.outlines[slot] then plot.outlines[slot].Enabled=false end end
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
				task.delay((slot-1)*.12,function()
					if ctx.rollToken~=token or sessions[p]~=ctx or not item then return end
					if not ctx.offers or ctx.offers[slot]~=item then return end -- already bought/replaced during the stagger
					local ped=st.pedestals[slot] local r=C.rarity(item.rarity)
					local odds=RollLook.odds(item.type,rollLuck,rollPerks.lucky,first)
					local unowned=d and not RollLook.owns(d.crushers.owned,item.type)
					local model=displayModel(item.type,ped.top,item) model.Name="OfferCrusher"
					model:SetAttribute("RevealOwner",p.UserId) model:SetAttribute("RevealRoll",rollId)
					model:SetAttribute("RevealSlot",slot) model:SetAttribute("RevealAt",workspace:GetServerTimeNow())
					model:SetAttribute("RevealRarity",item.rarity) model:SetAttribute("RevealType",item.type)
					model:SetAttribute("RevealUnowned",unowned==true) model:SetAttribute("RevealOdds",odds)
					model.Parent=plot.model game:GetService("CollectionService"):AddTag(model,RollLook.Tag)
					plot.offerModels[slot]=model
					task.spawn(function()
						local t0=os.clock() local centre=ped.top.Position
						while model.Parent and os.clock()-t0<30 do
							local age=os.clock()-t0 turn(model,centre,age*.8,RollLook.lift(item.rarity,age)) task.wait(1/20)
						end
					end)
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
				flick(slot,if last then item.type else pick())
				nextFlick[slot]=t+.12+.35*(t/seconds)^2
			end
			if shown[slot] then turn(shown[slot],st.pedestals[slot].top.Position,t*1.1) end
		end
		local spin=t*14*(1-t/seconds*.6)
		st.die:PivotTo(base*CFrame.new(0,math.abs(math.sin(t*9))*1.2,0)*CFrame.Angles(spin,spin*.7,spin*.4))
		for r,cf in rollers do r.CFrame=cf*CFrame.Angles(t*20,0,0) end
	end)
end
local function action(p,name,args)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return false,"Profile is loading." end
	local offer=if name=="Buy" and type(args)=="table" and type(args.slot)=="number" then ctx.offers and ctx.offers[args.slot] else nil
	local newType=offer and not RollLook.owns(d.crushers.owned,offer.type)
	local ok,message,result=Rules.act(d,ctx,name,args,os.clock(),random,guid,perks(p))
	if ok and name=="Roll" then d.crushers.rollReadyAt=workspace:GetServerTimeNow()+math.max(0,ctx.nextRoll-os.clock()) rollShow(p,result) end
	if ok and name=="Buy" then
		if newType then ctx.justDiscovered={id=result.id,type=result.type,rarity=result.rarity} end
		local ped=ctx.plot.stations.Roll.pedestals[args.slot]
		flash(ctx.plot,ped.top,Color3.fromRGB(120,255,140)) clearOffer(ctx.plot,args.slot)
		card(ped,"BOUGHT!","","","","",Color3.fromRGB(120,255,140))
		task.delay(1.5,function() if ped.card.name.Text=="BOUGHT!" then card(ped,"","","","","") end end)
	end
	if ok then reconcile(p) end
	ctx.justRolled=ok and name=="Roll" or nil
	send(p,if ok and name=="Roll" then nil else message,if name=="Buy" then result else nil) ctx.justRolled=nil ctx.justDiscovered=nil
	return ok,message,result
end
local function visualEvent(p,event)
	local v=sessions[p].visuals[event.bay] if not v then return end
	if event.kind=="Input" then
		if v.input then v.input:Destroy() end
		v.input=Objects.build(v.tier,v.base,"Normal") v.input.Name="ProductionInput" v.input.Parent=v.model
		local _,size=v.input:GetBoundingBox()
		local scale=math.min(1,v.clearance*.85/size.Y,v.bedWidth/(math.max(size.X,size.Z)*1.35))
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
		if v.catalog then Catalog.strike(v,event) return end
		if v.special then Special.strike(v,event) return end
		local height=(if v.input then v.input:GetAttribute("Height") else Config.Objects[v.tier].height)*event.fraction
		local down=CFrame.new(v.rest.Position.X,v.base.Position.Y+height+v.ram.Size.Y/2,v.rest.Position.Z)*(v.rest-v.rest.Position)
		local model=v.model
		Tween:Create(v.ram,TweenInfo.new(timing.hit,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=down}):Play()
		task.delay(timing.retract,function() if model.Parent and v.ram.Parent then Tween:Create(v.ram,TweenInfo.new(timing.up,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=v.rest}):Play() end end)
	end
end
function G.start()
	Data.start("CrushItPlayer_v1",{cash=C.StartCash,scrap=0,purchases={},daily={day=0,streak=0},goldenRush=0,lastSeen=0},function(d) return Rules.migrate(d,guid) end)
	Plots.create() require(script.Parent.World).create() Friend.start()
	require(script.Parent.CrusherPreviews).start()
	for _,plot in Plots.all() do for _,bay in plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false end end
	for _,plot in Plots.all() do pedestalLook(plot,C.StartPedestals) end
	for _,plot in Plots.all() do floorLook(plot,0) for i,bay in plot.bays do if floorOf(i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end end
	require(script.Parent.Moat).start(function(p) local ctx=sessions[p] return if ctx then Plots.spawnFor(ctx.plot) else CFrame.new(0,5,14) end, G.safeTeleport)
	require(script.Parent.Kit.Leaderboard).start({store="CashBoard_v1",score=function(p) return p:GetAttribute("Cash") or 0 end})
	local function spawnCharacter(p,char)
		local h=char:WaitForChild("Humanoid",10) local root=char:WaitForChild("HumanoidRootPart",10)
		if h then h.WalkSpeed=Config.PlayerWalkSpeed end
		local ctx=sessions[p] if root and ctx then G.safeTeleport(p,char,Plots.spawnFor(ctx.plot)) end
	end
	local function join(p)
		local d=Data.whenLoaded(p) if not d then return end
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
	end
	for _,plot in Plots.all() do
		for name,station in plot.stations do if station.prompt then station.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then Net.event("Notice"):FireClient(p,{text="Use your own factory."}) return end
			if name=="Production" or name=="Rolling" then Net.event("CrusherOpen"):FireClient(p,name) else action(p,name) end
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
		local ctx=sessions[p] if ctx then for _,v in ctx.visuals do v.model:Destroy() end ctx.plot.owner=nil ctx.plot.sign.Text="Free factory" ctx.rollToken=nil
			for i in ctx.plot.stations.Roll.pedestals do clearOffer(ctx.plot,i) end ctx.plot.pedestalCount=nil pedestalLook(ctx.plot,C.StartPedestals)
			for i,bay in ctx.plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.label.scope.Text="BAY "..i Workshop.clearPurchase(bay.buy) bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false end end
			floorLook(ctx.plot,0) for i,bay in ctx.plot.bays do if floorOf(i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end
		sessions[p]=nil
	end)
	Net.event("CrusherAction").OnServerEvent:Connect(function(p,name,args)
		local ctx=sessions[p] local d=Data.get(p) if not ctx or not d or type(name)~="string" then return end
		local now=os.clock() if now-ctx.lastRequest<C.RequestInterval then return end ctx.lastRequest=now
		if name=="Sync" then send(p) return end
		if name=="GroupCheck" then ctx.inGroup=checkGroup(p,true) send(p) return end
		args=if type(args)=="table" then args else {}
		-- World purchases require the owner's own station and a nearby character.
		local target local reach=C.Layout.InteractionDistance
		if name=="Upgrade" then local u=C.Upgrades[args.id] if u then target=ctx.plot.stations[u.group].part end
		elseif name=="Level" or name=="Unlock" then
			local bay=if type(args.bay)=="number" then ctx.plot.bays[args.bay] else nil
			if bay and (name=="Unlock" and args.bay==d.crushers.bays+1 or name=="Level" and d.crushers.equipped[tostring(args.bay)]==args.id) then target=bay.part end
			local wing=type(args.bay)=="number" and floorOf(args.bay)
			local f=wing and ctx.plot.floors and ctx.plot.floors[wing]
			if name=="Unlock" and f and f.first==args.bay and args.bay==d.crushers.bays+1 then target=f.face reach=45 end
		elseif name=="TimeSkip" then target=ctx.plot.stations.Goals and ctx.plot.stations.Goals.part
		elseif name=="Buy" then local ped=type(args.slot)=="number" and ctx.plot.stations.Roll.pedestals[args.slot] if ped then target=ped.part end
		elseif ctx.plot.stations[name] then target=ctx.plot.stations[name].part end
		if name~="Equip" and name~="Unequip" and name~="Recycle" and name~="EquipBest" then
			local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not target or not root or (root.Position-target.Position).Magnitude>reach then send(p,"Walk closer to your station or bay control.") return end
		end
		if name=="TimeSkip" then
			if not ctx.inGroup then ctx.inGroup=checkGroup(p,true) end
			if not ctx.inGroup then send(p,"Join the group first to unlock the free time skip.") return end
			local now=workspace:GetServerTimeNow()
			if now<(d.timeSkipAt or 0) then send(p,"Your next free time skip isn't ready yet.") return end
			local reward=skipReward(p,d)
			d.cash=C.money(d.cash+reward) d.timeSkipAt=now+C.Goals.SkipCooldownHours*3600
			send(p,"Done!") return
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
				if d.scrap>0 then Rules.act(d,ctx,"Sell",{},now,random,guid,perks(p)) end
			end
			if now-lastSend>=1 then send(p) end
		end end
		Feel.flush(now)
		if now-lastSend>=1 then lastSend=now end if now-lastAuto>=C.AutoCollectInterval then lastAuto=now end
	end)
	local api={getData=Data.get,whenLoaded=Data.whenLoaded,save=Data.saveNow,sync=function(p) send(p) end,
		-- reward crusher: random type of that rarity, Standard, level 1; nil when full
		giveCrusher=function(p,rarityName)
			local d=Data.get(p) local r=C.rarity(rarityName)
			if not d or not r or #d.crushers.owned>=C.MaxInventory then return nil end
			local item={id=guid(),type=r.types[rng:NextInteger(1,#r.types)],rarity=r.name,modifier="Standard",level=1}
			table.insert(d.crushers.owned,item) send(p)
			return C.typeById(item.type).name
		end,
		addCash=function(p,n) local d=Data.get(p) if d then d.cash=C.money(d.cash+n) send(p) end end,
		cashPerSecond=function(p) local d=Data.get(p) return if d then cps(p,d) else 0 end,
		finishLegacyProduct=function(p) local d=Data.get(p) if d then d.scrap=C.money(d.scrap+d.crushers.available) d.crushers.available=0 action(p,"Sell") end end}
	require(script.Parent.Shop).start(api) require(script.Parent.Rewards).start(api)
	require(script.Parent.DailySpin).start(api)
	require(script.Parent.Quests).start(api)
	require(script.Parent.TopBoards).start(api)
	-- /credits <amount> (or /cash): test cash, e.g. "/credits 5m". Studio, or the
	-- place owner in live servers. No amount gives 1M.
	local SUFFIX={k=1e3,m=1e6,b=1e9,t=1e12,qa=1e15}
	local function isAdmin(p) return RunService:IsStudio() or (game.CreatorType==Enum.CreatorType.User and p.UserId==game.CreatorId) end
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
