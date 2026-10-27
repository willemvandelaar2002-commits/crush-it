--!strict
-- One local mix for the whole factory, with fixed sound/visual pools.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Tags=game:GetService("CollectionService")
local SoundService=game:GetService("SoundService")
local Content=game:GetService("ContentProvider")
local Config=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
if not Config.Crushers.Enabled then return end
local F=require(RS.Shared.CrusherFeedback)
local Net=require(RS.Shared.Net)
local C=Config.Crushers
local me=Players.LocalPlayer local rng=Random.new()
local folder=Instance.new("Folder") folder.Name="LocalCrusherFeedback"
local group=Instance.new("SoundGroup") group.Name="CrusherMachines" group.Volume=F.GroupVolume group.Parent=SoundService
-- The independent lifecycle watcher survives this script's destruction under
-- deferred signals, when our own Destroying callback may never run.
local run=tostring(os.clock())..":"..tostring(rng:NextNumber())
script:SetAttribute("FeedbackRun",run) folder:SetAttribute("FeedbackRun",run)
local owner=Instance.new("ObjectValue") owner.Name="FeedbackOwner" owner.Value=script owner.Parent=folder
local mixer=Instance.new("ObjectValue") mixer.Name="FeedbackMixer" mixer.Value=group mixer.Parent=folder
folder.Parent=workspace
local connections={} local stopped=false
local sources={} local audioFocus={} local visualFocus={} local nearest={}
local audioQueue={} local visuals={} local budget=F.newBudget()
local nextScan=0 local duckUntil=0 local statsAt=0 local starts={}

local function part(name)
	local p=Instance.new("Part") p.Name=name p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
	p.CastShadow=false p.Transparency=1 p.Size=Vector3.new(.1,.1,.1) p.Parent=folder return p
end
local preloads={}
local function channel(name,keys)
	local anchor=part(name.."Source") local attachment=Instance.new("Attachment") attachment.Parent=anchor
	local sounds={}
	for _,key in keys do
		local sound=Instance.new("Sound") sound.Name=name.."_"..key sound.RollOffMode=Enum.RollOffMode.LinearSquare
		sound.SoundId="rbxassetid://"..Config.Sounds[key]
		sound.RollOffMinDistance=22 sound.RollOffMaxDistance=F.AudioDistance sound.Volume=0 sound.SoundGroup=group sound.Parent=attachment
		sounds[key]=sound table.insert(preloads,sound)
	end
	return {anchor=anchor,sounds=sounds,sound=sounds[keys[1]],untilTime=0,volume=0}
end
local voices={} for i=1,F.ImpactVoices do voices[i]=channel("Impact"..i,{"Thud","MetalHit","SparkHit"}) end
local hiss=channel("HydraulicRelease",{"Hiss"})
local ambient=channel("FactoryPressure",{"Hiss"}) ambient.sound.Looped=true ambient.sound.PlaybackSpeed=.48
ambient.sound.RollOffMinDistance=30 ambient.sound.RollOffMaxDistance=145

-- Load a small palette in the background. An unloaded hit is skipped, not
-- queued until several seconds later. No yielding in event/render handlers.
task.spawn(function() pcall(function() Content:PreloadAsync(preloads) end) end)

local function register(model)
	if model:IsA("Model") then sources[model]=true end
end
for _,model in Tags:GetTagged(F.Tag) do register(model) end
table.insert(connections,Tags:GetInstanceAddedSignal(F.Tag):Connect(register))
table.insert(connections,Tags:GetInstanceRemovedSignal(F.Tag):Connect(function(model)
	sources[model]=nil audioFocus[model]=nil visualFocus[model]=nil
end))
local function listener()
	local camera=workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end
local function eventHidden(model)
	local node=model
	while node and node~=workspace do
		if node:GetAttribute("LocalEventHidden")==true then return true end
		node=node.Parent
	end
	return false
end
local function scan(now)
	nextScan=now+F.FocusInterval local at=listener()
	audioFocus={} visualFocus={} nearest={}
	if not at then return end
	local candidates={}
	for model in sources do if model:IsDescendantOf(workspace) and not eventHidden(model) then
		local position=model:GetAttribute("FeedbackPosition")
		if typeof(position)=="Vector3" then table.insert(candidates,{model=model,position=position,key=model:GetAttribute("InventoryId")}) end
	end end
	nearest=F.nearest(candidates,at,F.AudioMachines,F.AudioDistance)
	for _,v in nearest do audioFocus[v.model]=true end
	for _,v in F.nearest(candidates,at,F.VisualMachines,F.VisualDistance) do visualFocus[v.model]=true end
end

local bursts={}
for i=1,F.MaxBursts do
	local ring=part("ImpactRing") ring.Shape=Enum.PartType.Cylinder ring.Material=Enum.Material.Neon
	local bits={} for j=1,F.ScrapPerBurst do bits[j]=part("ToyScrap") end
	bursts[i]={ring=ring,bits=bits,untilTime=0}
end
local function burst(event,now)
	local slot for _,b in bursts do if b.untilTime<=now then slot=b break end end
	if not slot then return end
	local def=C.typeById(event.typeId) local rarity=def and C.rarityOf(event.typeId)
	local color=(def and def.accent) or (rarity and rarity.color) or Color3.fromRGB(255,204,70)
	slot.start=now slot.untilTime=now+F.ScrapLifetime slot.position=event.position+Vector3.new(0,.22,0)
	slot.ring.Color=color slot.ring.Transparency=.3 slot.motion={}
	for i,p in slot.bits do
		p.Color=if i%2==0 then color else Color3.fromRGB(255,220,95)
		local size=rng:NextNumber(.18,.34) p.Size=Vector3.new(size,size*.65,size)
		local angle=rng:NextNumber(0,math.pi*2) local speed=rng:NextNumber(3,6)
		slot.motion[i]={velocity=Vector3.new(math.cos(angle)*speed,rng:NextNumber(4,7),math.sin(angle)*speed),spin=rng:NextNumber(-7,7)}
		p.Transparency=if event.completed then 0 else 1 -- scraps only on completed inputs
	end
end

local function capture(event,now)
	local input=event.input
	if now>=event.impactAt or not input or not input:IsA("Model") or not input.Parent then return nil end
	if math.abs((input:GetAttribute("SquashFraction") or 1)-event.before)>.001 then return nil end
	local parts={}
	for _,p in input:GetDescendants() do if p:IsA("BasePart") then
		if #parts>=F.MaxInputParts then return nil end
		local offset=event.base:ToObjectSpace(p.CFrame) local rotation=offset-offset.Position
		table.insert(parts,{part=p,size=p.Size,offset=offset,up=rotation:VectorToObjectSpace(Vector3.yAxis)})
	end end
	return {event=event,parts=parts}
end
local function squash(job,fraction)
	local e=job.event local from=e.before local spread=F.spread(fraction)/F.spread(from)
	for _,v in job.parts do if v.part.Parent then
		local p=v.offset.Position local rotation=v.offset-p
		v.part.CFrame=e.base*CFrame.new(p.X*spread,p.Y*fraction/from,p.Z*spread)*rotation
		v.part.Size=Vector3.new(
			math.max(.05,v.size.X*F.axisScale(fraction,v.up.X)/F.axisScale(from,v.up.X)),
			math.max(.05,v.size.Y*F.axisScale(fraction,v.up.Y)/F.axisScale(from,v.up.Y)),
			math.max(.05,v.size.Z*F.axisScale(fraction,v.up.Z)/F.axisScale(from,v.up.Z)))
	end end
end
local function live(event,now)
	return event.model and sources[event.model] and event.model:IsDescendantOf(workspace) and not eventHidden(event.model) and F.fresh(event.impactAt,now)
end
table.insert(connections,Net.event("Hit").OnClientEvent:Connect(function(msg)
	if type(msg)~="table" or not msg.crusherFeedback or type(msg.events)~="table" then return end
	local now=workspace:GetServerTimeNow() if now>=nextScan then scan(now) end
	for i,e in msg.events do
		if i>F.MaxBatch then break end
		if not live(e,now) then continue end
		if audioFocus[e.model] and #audioQueue<F.MaxPending then table.insert(audioQueue,e) end
		if visualFocus[e.model] and #visuals<F.VisualMachines then
			local job=capture(e,now) or {event=e}
			table.insert(visuals,job)
		end
	end
end))

local function startSound(slot,key,position,volume,pitch,now,lifetime)
	local sound=slot.sounds[key] if not sound then return false end
	if not sound.IsLoaded then return false end
	slot.sound=sound
	slot.anchor.CFrame=CFrame.new(position) slot.volume=volume slot.untilTime=now+lifetime
	sound.Volume=volume sound.PlaybackSpeed=pitch sound.TimePosition=0 sound:Play() return true
end
local function updateChannel(slot,now)
	if slot.untilTime<=now then
		if slot.sound.IsPlaying then slot.sound:Stop() end
		slot.sound.Volume=0
	else slot.sound.Volume=slot.volume*math.clamp((slot.untilTime-now)/.07,0,1) end
end
local function mix(now)
	local earliest=math.huge
	for i=#audioQueue,1,-1 do local e=audioQueue[i]
		if not live(e,now) or not audioFocus[e.model] then table.remove(audioQueue,i)
		else earliest=math.min(earliest,e.impactAt) end
	end
	if earliest==math.huge or now<earliest+F.MergeWindow then return end
	local due={}
	for i=#audioQueue,1,-1 do local e=audioQueue[i]
		if e.impactAt<=earliest+F.MergeWindow then table.insert(due,e) table.remove(audioQueue,i) end
	end
	local at=listener() if not at then return end
	local ranked=F.nearest(due,at,1,F.AudioDistance) local event=ranked[1]
	if not event then return end
	local slot for _,voice in voices do if voice.untilTime<=now then slot=voice break end end
	if not slot or not F.takeImpact(budget,now) then return end
	local key,volume,pitch=F.voice(event.typeId)
	local played=startSound(slot,key,event.position,volume*(if #due>1 then 1.12 else 1),pitch*rng:NextNumber(.96,1.04),now,F.ImpactLifetime)
	if played then
		table.insert(starts,now)
		if F.takeHiss(budget,now) then startSound(hiss,"Hiss",event.position,.075,rng:NextNumber(.94,1.04),now,F.HissLifetime) end
	end
end

local lastScrap=me:GetAttribute("Scrap") or 0
table.insert(connections,me:GetAttributeChangedSignal("Scrap"):Connect(function()
	local value=me:GetAttribute("Scrap") or 0
	if value~=lastScrap then duckUntil=workspace:GetServerTimeNow()+F.DuckSeconds end lastScrap=value
end))
table.insert(connections,Run.RenderStepped:Connect(function(dt)
	if stopped then return end
	local now=workspace:GetServerTimeNow() if now>=nextScan then scan(now) end
	for _,voice in voices do updateChannel(voice,now) end updateChannel(hiss,now)
	mix(now)
	for i=#visuals,1,-1 do local job=visuals[i] local e=job.event
		if not e.model or not e.model.Parent or not visualFocus[e.model] or eventHidden(e.model) then
			if job.parts and e.input and e.input.Parent then squash(job,e.fraction) end
			table.remove(visuals,i)
		else
			if job.parts and e.input and e.input.Parent then
				local t=math.clamp((now-e.impactAt+F.SquashLead)/(F.SquashLead+F.SquashTail),0,1)
				squash(job,e.before+(e.fraction-e.before)*(1-(1-t)^2))
			end
			if now>=e.impactAt and not job.burst then burst(e,now) job.burst=true end
			if now>=e.impactAt+F.SquashTail then table.remove(visuals,i) end
		end
	end
	local activeParts=0
	for _,b in bursts do if b.untilTime>now then
		local age=now-b.start local t=age/F.ScrapLifetime
		b.ring.Size=Vector3.new(.045,.6+t*3,.6+t*3)
		b.ring.CFrame=CFrame.new(b.position)*CFrame.Angles(0,0,math.pi/2) b.ring.Transparency=.3+t*.7
		for i,p in b.bits do if p.Transparency<1 then
			local m=b.motion[i] p.CFrame=CFrame.new(b.position+m.velocity*age+Vector3.new(0,-12*age*age,0))*CFrame.Angles(age*m.spin,age*m.spin*.7,age*m.spin*.3)
			p.Transparency=math.max(0,(t-.5)*2) activeParts+=1
		end end
	else b.ring.Transparency=1 for _,p in b.bits do p.Transparency=1 end end end
	local alpha=1-math.exp(-dt*8)
	local target=if now<duckUntil then F.DuckedVolume else F.GroupVolume
	-- Keep one very quiet pressure bed; no motor loop per crusher.
	group.Volume+=(target-group.Volume)*alpha
	local ambientTarget=if #nearest>0 then F.AmbientVolume else 0
	ambient.sound.Volume+=(ambientTarget-ambient.sound.Volume)*alpha
	if #nearest>0 then
		local center=Vector3.zero for _,v in nearest do center+=v.position end center/=#nearest
		ambient.anchor.CFrame=CFrame.new(center)
		if ambient.sound.IsLoaded and not ambient.sound.IsPlaying then ambient.sound:Play() end
	elseif ambient.sound.Volume<.001 and ambient.sound.IsPlaying then ambient.sound:Stop() end
	if now>=statsAt then
		statsAt=now+.1 local active=0 for _,v in voices do if v.untilTime>now and v.sound.IsPlaying then active+=1 end end
		for i=#starts,1,-1 do if now-starts[i]>=1 then table.remove(starts,i) end end
		folder:SetAttribute("ActiveImpactVoices",active) folder:SetAttribute("ImpactsLastSecond",#starts)
		folder:SetAttribute("PendingEvents",#audioQueue+#visuals) folder:SetAttribute("ActiveScrapParts",activeParts)
	end
end))

script.Destroying:Connect(function()
	stopped=true for _,connection in connections do connection:Disconnect() end
	for _,job in visuals do if job.parts and job.event.input and job.event.input.Parent then squash(job,job.event.fraction) end end
	folder:Destroy() group:Destroy()
end)
