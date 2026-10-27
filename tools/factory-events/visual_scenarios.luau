
local renderer=require(shared.FactoryEventVisuals).new()
local geometryChecks=0
local function check(ok,message) assert(ok,message) geometryChecks+=1 end
-- Realistic original plot/production nodes, deliberately nonzero local alpha.
local plot=Instance.new('Model') plot.Name='Plot1' plot.Parent=workspace
local original=Instance.new('Model') original.Name='EquippedCrusher' original.Parent=plot
local painted=Instance.new('Part') painted.LocalTransparencyModifier=.2 painted.Parent=original
local emitter=Instance.new('ParticleEmitter') emitter.Enabled=true emitter.Parent=original
local mega=Instance.new('Model') mega.Name='MegaCrusher' mega.Parent=workspace
mega:SetAttribute('BedTop',3) mega:SetAttribute('RestY',32)
local ram=Instance.new('Part') ram.Name='Ram' ram.Size=Vector3.new(20,5,14) ram.CFrame=CFrame.new(0,32,0) ram.Parent=mega
local toy=Instance.new('Model') toy.Name='Toy' toy.Parent=mega
local toyPart=Instance.new('Part') toyPart.LocalTransparencyModifier=.35 toyPart.Parent=toy
services.CollectionService:AddTag(mega,'MegaCrusher')
local bear=Instance.new('Model') bear.Name='FactoryTeddy' bear.Parent=workspace
local head=Instance.new('Part') head.Name='Head' head.Size=Vector3.new(10,10,8) head.CFrame=CFrame.new(100,30,100) head.Parent=bear
local eye=Instance.new('Part') eye.Name='Eye' eye.CFrame=CFrame.new(100,31,95.8) eye.Parent=bear
for grade=1,5 do
	local packet={roundId='visual-'..grade,phase='Active',started=clock,ends=clock+180,hp=60,maxHp=100,
		participants={{userId=1,plotIndex=1,origin=CFrame.new(),points=E.Grades[grade].points,grade=grade,
			dominant=({'Common','Uncommon','Rare','Epic','Legendary'})[grade],count=10,present=true,pulseUntil=0}}}
	renderer:update(packet)
	check(painted.LocalTransparencyModifier==1 and not emitter.Enabled,'original visuals hidden')
	check(plot:GetAttribute('LocalEventHidden')==true,'normal feedback suppressed locally')
	check(renderer.central and renderer.bear,'central transformation and bear aura built')
	check(toyPart.LocalTransparencyModifier==1,'original central toys hidden')
	local rig=renderer.rigs[1]
	check(rig and #renderer.folder:GetDescendants()<160,'bounded geometry for grade '..grade)
	local low=math.huge local high=-math.huge
	for tick=0,240 do
		renderer:step(clock+tick/120)
		for _,p in rig.model:GetDescendants() do if p:IsA('BasePart') then
			check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,'noninteractive cosmetic')
			check(p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0,'positive animated size')
			check(p.CFrame.Position.Magnitude<100,'bounded cosmetic position')
		end end
		low=math.min(low,rig.moving[1].part.Position.Y) high=math.max(high,rig.moving[1].part.Position.Y)
	end
	check(high-low>7,'working hydraulic stroke')
	renderer:step(clock+1.5)
	print('GEOMETRY|MODEL|SuperCrusher-Grade'..grade)
	for _,p in rig.model:GetDescendants() do if p:IsA('BasePart') then
		local pos=p.Position local size=p.Size local c=p.Color
		print('GEOMETRY|PART|'..p.Name..'|'..p.ClassName..'|'..tostring(p.Shape)..'|'..table.concat({pos.X,pos.Y,pos.Z},',')..'|'..table.concat({size.X,size.Y,size.Z},',')..'|'..table.concat(p.CFrame.R,',')..'|'..table.concat({c.R,c.G,c.B},',')..'|'..tostring(p.Material))
	end end
	local previous=renderer.central.panels[1].part.Position
	packet.hp=10 renderer:update(packet) renderer:step(clock+1.5)
	check((renderer.central.panels[1].part.Position-previous).Magnitude>0,'Mega Crusher unfolds with shared progress')
	packet.phase='Finale' packet.started=clock renderer:update(packet) renderer:step(clock+2.9)
	check(renderer.central.shield.Transparency==1 and renderer.central.burst,'final blow exposes core and creates shockwave')
	packet.phase='Victory' renderer:update(packet) renderer:step(clock+3)
	check(renderer.bear.eyes[1].Transparency==1,'bear corruption ends on victory')
	packet.phase='Recover' renderer:update(packet) renderer:step(clock+1)
	renderer:update({roundId=packet.roundId,phase='Idle',participants={}})
	check(painted.LocalTransparencyModifier==.2 and emitter.Enabled,'original alpha/emitter restored exactly')
	check(plot:GetAttribute('LocalEventHidden')==nil,'feedback restored')
	check(toyPart.LocalTransparencyModifier==.35,'central toys restore their authored alpha')
	check(#renderer.folder:GetChildren()==0,'all temporary plot geometry removed')
end
-- Whole-mesh imported bear fallback and central streaming/replacement.
eye:Destroy()
local p={roundId='streaming',phase='Assemble',started=clock,ends=clock+6,hp=0,maxHp=0,
	participants={{userId=1,plotIndex=1,origin=CFrame.new(),points=20,grade=2,dominant='Rare',count=10,
		present=true,pulseUntil=0,slots={1,6,13,24}}}}
renderer:update(p) renderer:step(clock+1)
check(#renderer.bear.eyes==2,'combined imported bear receives two temporary red eyes')
check(#renderer.rigs[1].sparks==4,'assembly energy comes from equipped bay positions')
local late=Instance.new('Part') late.Parent=original
renderer:update(p)
check(late.LocalTransparencyModifier==1,'late production inputs/streamed parts are hidden on update')
mega.Parent=nil renderer:update(p) renderer:step(clock+1.5)
check(renderer.central==nil,'streamed-out central rig discarded without errors')
mega.Parent=workspace renderer:update(p) renderer:step(clock+2)
check(renderer.central~=nil,'central rig recreated after streaming returns')
local leave={roundId='streaming',phase='Active',started=clock,ends=clock+180,hp=100,maxHp=100,participants={}}
renderer:update(leave)
check(renderer.rigs[1]==nil and painted.LocalTransparencyModifier==.2,'leaving restores plot without waiting for entire event')
renderer:destroy()
check(renderer.folder.Parent==nil,'renderer root destroyed')
print('PASS|Actual visual builder/animation/lifecycle|'..geometryChecks)
