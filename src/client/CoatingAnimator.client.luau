--!nonstrict
-- One bounded cosmetic scheduler for persistent coating AND fusion looks.
-- Static decorations remain readable in every bay and ViewportFrame.
local Tags=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Motion=require(RS:WaitForChild("Shared"):WaitForChild("CrusherFinishMotion"))
local roots={} local connections={} local stopped=false local tick=0 local scan=0
-- Smooth coloured glow over the nearest coated/fused crushers (their own
-- colours stay; the coating is a soft layer on top). One Highlight each, pooled.
local GLOW={Polished=Color3.fromRGB(225,240,255),Frost=Color3.fromRGB(110,225,255),Fire=Color3.fromRGB(255,120,40),
	Charged=Color3.fromRGB(185,95,255),Fusion=Color3.fromRGB(120,255,140)}
local glowFolder=Instance.new("Folder") glowFolder.Name="LocalCoatingGlows" glowFolder.Parent=workspace
local glows={} -- pool: {hl=Highlight, owner=Model?, finish=string?}
for i=1,Motion.Glows do
	local hl=Instance.new("Highlight") hl.Name="CoatingGlow"..i hl.Enabled=false
	hl.DepthMode=Enum.HighlightDepthMode.Occluded hl.Parent=glowFolder
	glows[i]={hl=hl}
end
local function setGlow(slot,owner,finish)
	local g=glows[slot] if g.owner==owner and g.finish==finish then return end
	g.owner=owner g.finish=finish
	g.hl.Adornee=owner g.hl.Enabled=owner~=nil
	if owner then local c=GLOW[finish] or GLOW.Fusion g.hl.FillColor=c g.hl.OutlineColor=c:Lerp(Color3.new(1,1,1),.35) end
end
local function off(e)
	for _,p in e.emitters do if p.Parent then p.Enabled=false p.Rate=0 p:Clear() end end
	for _,b in e.arcs do if b.Parent then b.Enabled=false end end
	for _,l in e.lights do if l.Parent then l.Enabled=false end end
	for _,v in e.pulses do if v.part.Parent then v.part.Transparency=v.alpha end end
	e.level=0
end
local function add(root)
	if stopped or not root.Parent or roots[root] then return end
	local e={owner=root.Parent,finish=tostring(root:GetAttribute("Finish")),unit=root:GetAttribute("FinishUnit") or 1,emitters={},arcs={},lights={},pulses={},level=0,light=false,seed=0}
	for _,d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") then table.insert(e.emitters,d)
		elseif d:IsA("Beam") then table.insert(e.arcs,d)
		elseif d:IsA("PointLight") then table.insert(e.lights,d)
		elseif d:IsA("BasePart") then
			if not e.anchor then e.anchor=d end
			if d:GetAttribute("FinishPulse") or d.Name=="Gleam" then table.insert(e.pulses,{part=d,alpha=d.Transparency}) end
		end
	end
	local id=tostring(e.owner:GetAttribute("InventoryId") or e.owner.Name)
	for i=1,#id do e.seed=(e.seed+string.byte(id,i)*i)%997 end
	e.seed=e.seed/79
	off(e) roots[root]=e
end
for _,r in Tags:GetTagged("CoatingFx") do add(r) end
connections[#connections+1]=Tags:GetInstanceAddedSignal("CoatingFx"):Connect(function(r) task.defer(add,r) end)
connections[#connections+1]=Tags:GetInstanceRemovedSignal("CoatingFx"):Connect(function(r)
	local e=roots[r] if e then off(e) end roots[r]=nil
end)
-- the event marks the whole plot (FactoryEventVisuals), so check the parents too
local function hidden(owner)
	local node=owner
	while node and node~=workspace do
		if node:GetAttribute("LocalEventHidden")==true then return true end
		node=node.Parent
	end
	return false
end
local function focus()
	local camera=workspace.CurrentCamera local groups={}
	for root,e in roots do
		if not root.Parent then off(e) roots[root]=nil
		else
			e.light=false
			local valid=camera and root:IsDescendantOf(workspace) and e.anchor and e.anchor.Parent and not hidden(e.owner)
			if not valid then if e.level~=0 then off(e) end continue end
			local distance=(e.anchor.Position-camera.CFrame.Position).Magnitude
			local g=groups[e.owner]
			if not g then
				g={entries={},distance=distance,key=tostring(e.owner:GetAttribute("InventoryId") or e.owner:GetFullName())}
				groups[e.owner]=g
			end
			g.distance=math.min(g.distance,distance) table.insert(g.entries,e)
		end
	end
	local ordered={} for _,g in groups do table.insert(ordered,g) end
	local function clearGlows(from) for i=from,Motion.Glows do setGlow(i,nil,nil) end end
	table.sort(ordered,function(a,b) return if a.distance==b.distance then a.key<b.key else a.distance<b.distance end)
	local lightCount=0
	local glowSlot=0
	for rank,g in ordered do
		if glowSlot<Motion.Glows and g.distance<=Motion.Far then
			-- the coating colour wins; fused-only crushers glow green
			local finish="Fusion" for _,e in g.entries do if e.finish~="Fusion" then finish=e.finish end end
			glowSlot+=1 setGlow(glowSlot,g.entries[1].owner,finish)
		end
		local level=Motion.level(g.distance,rank)
		for _,e in g.entries do
			if level==0 and e.level~=0 then off(e) end
			e.level=level
			if level==2 and #e.lights>0 and lightCount<Motion.Lights then e.light=true lightCount+=1 end
		end
	end
	clearGlows(glowSlot+1)
end
local function update(e,now)
	local s=Motion.sample(e.finish,now,e.seed)
	for _,emitter in e.emitters do if emitter.Parent then
		local enabled=e.level==2
		emitter.Enabled=enabled emitter.Rate=if enabled then (emitter:GetAttribute("FinishRate") or 0) else 0
	end end
	for _,beam in e.arcs do if beam.Parent then
		beam.Enabled=e.level==2 and s.arc
		beam.CurveSize0=s.curve*e.unit*.025 beam.CurveSize1=-beam.CurveSize0
	end end
	for _,light in e.lights do if light.Parent then light.Enabled=e.light and e.level==2 light.Brightness=s.brightness end end
	for _,v in e.pulses do if v.part.Parent then
		local amount=if e.level==0 then 0 elseif v.part.Name=="Gleam" then .58*(1-s.glint) else .18*(1-s.pulse)
		v.part.Transparency=v.alpha+(1-v.alpha)*amount
	end end
end
connections[#connections+1]=Run.Heartbeat:Connect(function(dt)
	if stopped then return end
	tick+=dt scan+=dt
	if scan>=Motion.Scan then scan=0 focus() end
	if tick<Motion.Tick then return end tick=0
	local now=os.clock()
	for i,g in glows do if g.owner then
		if not g.owner.Parent or hidden(g.owner) then setGlow(i,nil,nil)
		else
			local w=.5+.5*math.sin(now*2.2+i)
			g.hl.FillTransparency=.68+.14*w g.hl.OutlineTransparency=.35+.3*w
		end
	end end
	for root,e in roots do
		if not root.Parent then off(e) roots[root]=nil
		elseif e.level>0 then
			-- Event-hidden owners are silenced immediately, before the next focus scan.
			if hidden(e.owner) then off(e) else update(e,now) end
		end
	end
end)
local function stop()
	if stopped then return end stopped=true
	for _,c in connections do c:Disconnect() end
	for _,e in roots do off(e) end table.clear(roots)
	glowFolder:Destroy()
end
connections[#connections+1]=script.Destroying:Connect(stop)
