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
local Workshop=require(script.Parent.Kit.CrusherWorkshop)
local Special=require(script.Parent.SpecialCrushers)
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
	st.Roll.label.Text=if rolling then "Rolling..." else "Random rarity  ·  "..Format.cash(C.RollCost)
	st.Roll.button.Text=if rolling then "ROLLING..." else "ROLL "..Format.cash(C.RollCost)
	for _,group in {"Production","Rolling"} do
		for _,id in C.UpgradeOrder do if C.Upgrades[id].group==group then
			local lv=s.upgrades[id] local row=ctx.plot.stations[group].rows[id]
			row.label.Text=if lv>=C.MaxGlobal then "Lv "..lv.."  MAX LEVEL" else "Lv "..lv.." > "..(lv+1).."   "..C.shortBenefit(id,lv)
			row.button.Text=if lv>=C.MaxGlobal then "MAX" else Format.cash(C.globalCost(id,lv))
		end end
	end
	floorLook(ctx.plot,s.bays)
	for i,bay in ctx.plot.bays do
		-- bays on an upper floor that isn't built yet are invisible
		local wing=floorOf(i) local f=wing and ctx.plot.floors and ctx.plot.floors[wing]
		local hidden=f~=nil and f.mode~="built"
		if bay.hidden~=hidden then bay.hidden=hidden bay.shown=nil partsLook(bay.model,if hidden then "hidden" else "built") end
		if hidden then
			bay.label.name.Text="" bay.label.rarity.Text="" bay.label.stats.Text="" bay.buy.Visible=false bay.manage.Visible=false bay.lockLabel.Text=""
			continue
		end
		local item=Rules.find(d,s.equipped[tostring(i)])
		local state=if item then "busy" elseif i<=s.bays then "open" elseif i==s.bays+1 then "next" else "locked"
		local card=bay.label
		if item then
			local r=C.rarity(item.rarity)
			card.name.Text=C.typeById(item.type).name
			card.rarity.Text=item.rarity..(if item.modifier~="Standard" then "  ·  "..item.modifier.." x"..C.modifier(item.modifier).mult else "")
			card.rarity.TextColor3=r.color:Lerp(Color3.new(1,1,1),.25)
			card.stats.Text="Level "..item.level.."  ·  "..Format.cash(Rules.stats(d,item,perks(p)).cps*60).."/min"
		else
			card.name.Text=if state=="open" then "EMPTY BAY" elseif state=="next" then "NEXT BAY" else "LOCKED"
			card.rarity.Text=if state=="open" then "Equip a crusher here" elseif state=="next" then "Unlock for more output" else ""
			card.rarity.TextColor3=Color3.new(1,1,1)
			card.stats.Text=""
		end
		bay.buy.Text=if item then (if item.level>=C.MaxLevel then "MAX" else "LEVEL UP\n"..Format.cash(C.individualCost(item)))
			elseif state=="next" then "UNLOCK\n"..Format.cash(C.BayCosts[i]) else "EQUIP"
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
	local special=if t.template then Special.build(o,t.template) else nil
	if special then
		special.id=item.id special.tier=t.input special.model.Name="EquippedCrusher"
		special.model:SetAttribute("InventoryId",item.id) special.model:SetAttribute("Rarity",item.rarity) special.model:SetAttribute("Modifier",item.modifier)
		special.model.Parent=bay.model ctx.visuals[i]=special return
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
	local special=t.template and Special.build(at,t.template)
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
local function card(st,name,rarity,odds,value,color)
	st.card.name.Text=name st.card.name.TextColor3=color or Color3.new(1,1,1)
	st.card.rarity.Text=rarity st.card.rarity.TextColor3=color or Color3.new(1,1,1)
	st.card.odds.Text=odds st.card.value.Text=value
end
-- Roll show (like the reference): the die and rollers spin while black
-- silhouettes of possible crushers flicker on the plinth with "???" and their
-- odds; then a flash and the real crusher appears with name, rarity, odds and
-- its output per minute.
local function rollShow(p,item)
	local ctx=sessions[p] local st=ctx.plot.stations.Roll
	local seconds=math.max(1.2,(ctx.nextRoll or 0)-os.clock()) local token={} ctx.rollToken=token
	st.reveal.Text="ROLLING..."
	if ctx.revealModel then ctx.revealModel:Destroy() ctx.revealModel=nil end
	-- silhouettes are built once per plot and reused
	local plot=ctx.plot
	if not plot.silhouettes then
		plot.silhouettes={}
		local folder=Instance.new("Model") folder.Name="RollSilhouettes" folder.Parent=plot.model
		for _,t in C.Types do
			local m=displayModel(t.id,st.pedestal) silhouette(m) showModel(m,false) m.Parent=folder plot.silhouettes[t.id]=m
			m:SetAttribute("BasePivot",m:GetPivot())
		end
		local hl=Instance.new("Highlight") hl.Name="SilhouetteOutline" hl.FillColor=Color3.fromRGB(8,8,12) hl.FillTransparency=0 hl.OutlineTransparency=0 hl.OutlineColor=Color3.new(1,1,1)
		hl.DepthMode=Enum.HighlightDepthMode.Occluded hl.Enabled=false hl.Parent=folder plot.silhouetteOutline=hl
	end
	local pool={} for _,r in C.Rarities do for _,id in r.types do table.insert(pool,{id=id,w=r.weight^.45}) end end
	local function pick()
		local total=0 for _,e in pool do total+=e.w end local x=rng:NextNumber()*total
		for _,e in pool do x-=e.w if x<=0 then return e.id end end return pool[#pool].id
	end
	-- turn a model slowly about the plinth centre, from its stored base pose
	local centre=st.pedestal.Position
	local function turn(m,a)
		local basePivot=m:GetAttribute("BasePivot")
		if typeof(basePivot)~="CFrame" then basePivot=m:GetPivot() m:SetAttribute("BasePivot",basePivot) end
		m:PivotTo(CFrame.new(centre)*CFrame.Angles(0,a,0)*CFrame.new(-centre)*basePivot)
	end
	local shown
	local function flick(id)
		if shown then showModel(plot.silhouettes[shown],false) end
		shown=id showModel(plot.silhouettes[id],true)
		plot.silhouetteOutline.Parent=plot.silhouettes[id] plot.silhouetteOutline.Enabled=true
		card(st,"???","???","[1 in "..Format.cash(C.oddsFor(id)):gsub("%$","").."]","???")
	end
	local start=os.clock() local base=st.die:GetPivot() local rollers={} local nextFlick=0
	for _,r in st.rollers do rollers[r]=r.CFrame end
	local conn conn=RunService.Heartbeat:Connect(function()
		local t=os.clock()-start
		if t>=seconds or ctx.rollToken~=token or not st.die.Parent then
			conn:Disconnect() st.die:PivotTo(base) for r,cf in rollers do r.CFrame=cf end
			if shown then showModel(plot.silhouettes[shown],false) end plot.silhouetteOutline.Enabled=false
			if ctx.rollToken~=token or sessions[p]~=ctx then return end
			-- flash, then the real crusher
			local flash=Workshop.part(plot.model,"RevealFlash",Vector3.new(2,2,2),st.pedestal*CFrame.new(0,3,0),Color3.fromRGB(255,240,180))
			flash.Shape=Enum.PartType.Ball flash.Material=Enum.Material.Neon flash.CastShadow=false
			Tween:Create(flash,TweenInfo.new(.35,Enum.EasingStyle.Quad),{Size=Vector3.new(11,11,11),Transparency=1}):Play()
			task.delay(.4,function() flash:Destroy() end)
			local model=displayModel(item.type,st.pedestal,item)
			model.Name="RolledCrusher" model.Parent=plot.model ctx.revealModel=model
			-- the result turns slowly on the plinth for a while
			task.spawn(function()
				local t0=os.clock()
				while model.Parent and os.clock()-t0<12 do turn(model,(os.clock()-t0)*0.8) task.wait(1/30) end
			end)
			local r=C.rarity(item.rarity) local d=Data.get(p)
			local perMin=d and Rules.stats(d,item,perks(p)).cps*60 or 0
			-- (the server toast would spoil the reveal; the card says it)
			card(st,C.typeById(item.type).name,item.rarity..(if item.modifier~="Standard" then " · "..item.modifier else ""),
				"[1 in "..Format.cash(C.oddsFor(item.type)):gsub("%$","").."]",Format.cash(perMin).."/min",r.color:Lerp(Color3.new(1,1,1),.15))
			st.reveal.Text=string.upper(item.rarity).."\n"..C.typeById(item.type).name
			st.reveal.TextColor3=r.color:Lerp(Color3.new(1,1,1),.2)
			return
		end
		-- flicker: fast at first, slowing down towards the reveal
		if t>=nextFlick then
			local last=seconds-t<.45
			flick(if last then item.type else pick())
			nextFlick=t+.12+.35*(t/seconds)^2
		end
		if shown then turn(plot.silhouettes[shown],t*1.1) end
		local spin=t*14*(1-t/seconds*.6)
		st.die:PivotTo(base*CFrame.new(0,math.abs(math.sin(t*9))*1.2,0)*CFrame.Angles(spin,spin*.7,spin*.4))
		for r,cf in rollers do r.CFrame=cf*CFrame.Angles(t*20,0,0) end
	end)
end
local function action(p,name,args)
	local ctx=sessions[p] local d=Data.get(p) if not ctx or not d then return false,"Profile is loading." end
	local ok,message,result=Rules.act(d,ctx,name,args,os.clock(),random,guid,perks(p))
	if ok and name=="Roll" then d.crushers.rollReadyAt=workspace:GetServerTimeNow()+math.max(0,ctx.nextRoll-os.clock()) rollShow(p,result) end
	if ok then reconcile(p) end
	send(p,message,result) return ok,message,result
end
local function visualEvent(p,event)
	local v=sessions[p].visuals[event.bay] if not v then return end
	if event.kind=="Input" then
		if v.input then v.input:Destroy() end
		v.input=Objects.build(v.tier,v.base,"Normal") v.input.Name="ProductionInput" v.input.Parent=v.model
		local _,size=v.input:GetBoundingBox()
		local scale=math.min(1,v.clearance*.85/size.Y,v.bedWidth/(math.max(size.X,size.Z)*1.35))
		Objects.scale(v.input,v.base,scale) v.input:SetAttribute("Height",size.Y*scale)
	else
		if v.input then Objects.setSquash(v.input,v.base,event.fraction) end
		if v.special then Special.strike(v,event) return end
		local height=(if v.input then v.input:GetAttribute("Height") else Config.Objects[v.tier].height)*event.fraction
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
	for _,plot in Plots.all() do for _,bay in plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false end end
	for _,plot in Plots.all() do floorLook(plot,0) for i,bay in plot.bays do if floorOf(i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end end
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
		for name,station in plot.stations do if station.prompt then station.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then Net.event("Notice"):FireClient(p,{text="Use your own factory."}) return end
			if name=="Production" or name=="Rolling" then Net.event("CrusherOpen"):FireClient(p,name) else action(p,name) end
		end) end end
		for i,bay in plot.bays do bay.prompt.Triggered:Connect(function(p)
			if plot.owner~=p then return end Net.event("CrusherOpen"):FireClient(p,"Inventory",i)
		end) end
	end
	Players.PlayerAdded:Connect(join) for _,p in Players:GetPlayers() do task.spawn(join,p) end
	Players.PlayerRemoving:Connect(function(p)
		local ctx=sessions[p] if ctx then for _,v in ctx.visuals do v.model:Destroy() end ctx.plot.owner=nil ctx.plot.sign.Text="Free factory" ctx.rollToken=nil
			if ctx.revealModel then ctx.revealModel:Destroy() end ctx.plot.stations.Roll.reveal.Text="LAST ROLL" card(ctx.plot.stations.Roll,"","","","")
			for _,bay in ctx.plot.bays do bayLook(bay,"locked") bay.label.name.Text="LOCKED" bay.label.rarity.Text="" bay.label.stats.Text="" bay.part.Color=Workshop.Blue bay.buy.Visible=false bay.manage.Visible=false end end
			floorLook(ctx.plot,0) for i,bay in ctx.plot.bays do if floorOf(i) then bay.hidden=true bay.shown=nil partsLook(bay.model,"hidden") end end
		sessions[p]=nil
	end)
	Net.event("CrusherAction").OnServerEvent:Connect(function(p,name,args)
		local ctx=sessions[p] local d=Data.get(p) if not ctx or not d or type(name)~="string" then return end
		local now=os.clock() if now-ctx.lastRequest<C.RequestInterval then return end ctx.lastRequest=now
		if name=="Sync" then send(p) return end
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
		elseif ctx.plot.stations[name] then target=ctx.plot.stations[name].part end
		if name~="Equip" and name~="Unequip" then
			local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not target or not root or (root.Position-target.Position).Magnitude>reach then send(p,"Walk closer to your station or bay control.") return end
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
		if now-lastSend>=1 then lastSend=now end if now-lastAuto>=C.AutoCollectInterval then lastAuto=now end
	end)
	local api={getData=Data.get,whenLoaded=Data.whenLoaded,save=Data.saveNow,sync=function(p) send(p) end,
		addCash=function(p,n) local d=Data.get(p) if d then d.cash=C.money(d.cash+n) send(p) end end,
		cashPerSecond=function(p) local d=Data.get(p) return if d then cps(p,d) else 0 end,
		finishLegacyProduct=function(p) local d=Data.get(p) if d then d.scrap=C.money(d.scrap+d.crushers.available) d.crushers.available=0 action(p,"Sell") end end}
	require(script.Parent.Shop).start(api) require(script.Parent.Rewards).start(api)
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
