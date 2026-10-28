--!strict
-- Two open, two-storey crusher banks around a clear plaza; coordinates are local.
local S=game:GetService("ReplicatedStorage").Shared
local Config=require(S.Config) local C=Config.Crushers local L=C.Layout
local Build=require(script.Parent.Kit.Build)
local W=require(script.Parent.Kit.CrusherWorkshop)
local Style=require(S.Kit.Style)
local Moat=require(script.Parent.Moat)
local P={} local V=Vector3.new
-- Blue bank walls and risers share the factory floor's imported stud finish.
local function bankPanel(parent,name,size,cf,color,solid)
 local panel=W.part(parent,name,size,cf,color,solid)
 Style.studs(panel)
 return panel
end
function P.prompt(part,action,title)
 local p=Instance.new("ProximityPrompt") p.Name="FactoryPrompt" p.ActionText=action p.ObjectText=title
 p.KeyboardKeyCode=Enum.KeyCode.E p.HoldDuration=0 p.MaxActivationDistance=12 p.RequiresLineOfSight=false p.Parent=part return p
end
-- Factory III: a third floor per wing, stepped back on top of the upper floor
-- the same way the upper floor sits on the ground bays. Its deck roofs the
-- upper bays; a lift pad on the upper walkway takes players up and down.
-- Hidden until plot level 2 (CrusherGame.floorLook raises it into place).
local function topFloor(parent,o,wing,side)
 local top=Instance.new("Model") top.Name="TopFloor"..wing top.Parent=parent
 local width=L.PerWing*L.Pitch+2 local T=L.TierHeight local x=side*L.WingX
 local back2=L.BayZ-L.UpperBack-L.BayDepth/2 -- back face of the upper bays
 local back3=back2-L.UpperBack -- back face of the top bays
 local walk3=L.WalkFront-L.UpperBack -- front edge of the top walkway
 local deckDepth=walk3-back3
 local inner=x-side*width/2 local outer=x+side*width/2
 -- under the top bays: a solid step from the upper floor up (its front is the
 -- upper floor's back wall), carried at the back by columns down to the ground
 local stepFront=back2-1.2
 bankPanel(top,"TopStep",V(width,T-.8,stepFront-back3),o*CFrame.new(x,T+(T-.8)/2,(stepFront+back3)/2),W.Blue,true)
 local deck=W.part(top,"TopDeck",V(width,.8,deckDepth),o*CFrame.new(x,2*T-.4,back3+deckDepth/2),Color3.fromRGB(125,159,199),true)
 Style.materialStuds(deck,true,{Enum.NormalId.Top},2)
 W.part(top,"TopFascia",V(width,1.4,.8),o*CFrame.new(x,2*T-.9,walk3+.2),W.Navy)
 W.part(top,"TopFasciaStripe",V(width,.3,.9),o*CFrame.new(x,2*T-.05,walk3+.2),W.Yellow)
 bankPanel(top,"TopBackWall",V(width,T+2,1.2),o*CFrame.new(x,2*T+(T+2)/2,back3-.6),W.Blue,true)
 W.part(top,"TopBackWallCap",V(width+.4,.6,1.6),o*CFrame.new(x,3*T+2.3,back3-.6),W.Yellow)
 for row=0,L.PerWing do
  local px=side*(L.WingX+(row-L.PerWing/2)*L.Pitch)
  W.part(top,"TopColumn",V(.9,T,.9),o*CFrame.new(px,2*T+T/2,L.BayZ-2*L.UpperBack+L.BayDepth/2-.2),W.Blue,true)
  -- rear supports down to the ground (kept off the central road)
  local rel=(C.wingFrame(side)*CFrame.new(px,0,back3+.8)).Position -- plot-local
  if math.abs(rel.X)>7 then
   W.part(top,"TopSupport",V(1.4,T+1,1.4),o*CFrame.new(px,(T-1)/2,back3+.8),W.Navy,true)
  end
 end
 -- safety rails along the front and both ends of the top walkway
 for _,h in {1.2,3} do
  W.part(top,"TopRail",V(width,.4,.4),o*CFrame.new(x,2*T+h,walk3-.4),W.Yellow,true)
  for _,ex in {inner,outer} do W.part(top,"TopEndRail",V(.4,.4,deckDepth),o*CFrame.new(ex,2*T+h,back3+deckDepth/2),W.Yellow,true) end
 end
 for i=0,math.floor(width/L.Pitch) do
  W.part(top,"TopRailPost",V(.5,3.2,.5),o*CFrame.new(inner+side*i*L.Pitch,2*T+1.6,walk3-.4),W.Yellow,true)
 end
 -- lift pads: one on the upper walkway, one straight above on the top walkway
 local liftX=side*(L.WingX+1.8*L.Pitch)
 local function pad(name,y,z,label,action)
  local cf=o*CFrame.new(liftX,y,z)
  local base=W.part(top,name.."Base",V(5.4,.4,5.4),cf*CFrame.new(0,.2,0),W.Navy,true)
  local glow=W.part(top,name.."Glow",V(.3,4.6,4.6),cf*CFrame.new(0,.45,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(80,235,110))
  glow.Shape=Enum.PartType.Cylinder glow.Material=Enum.Material.Neon glow.CastShadow=false
  -- floating label high over the pad: out of the walking path and clear of the bay plaques
  local board=W.part(top,name.."Sign",V(5.6,2.2,.3),cf*CFrame.new(0,8,0),Color3.fromRGB(53,170,80))
  board.CanQuery=false
  W.text(W.sign(board),"Label",label,UDim2.fromScale(.04,.06),UDim2.fromScale(.92,.88))
  local prompt=P.prompt(base,action,"Lift") prompt.MaxActivationDistance=8
  return base,prompt
 end
 local lowBase,lowPrompt=pad("LiftLower",T,L.WalkFront-4.5,"LIFT · FLOOR 3","Go up")
 local highBase,highPrompt=pad("LiftUpper",2*T,walk3-4.5,"LIFT · FLOOR 2","Go down")
 local function ride(prompt,target)
  prompt.Triggered:Connect(function(player)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if root then player.Character:PivotTo(CFrame.new(target.Position+Vector3.new(0,3.5,0))*root.CFrame.Rotation) end
  end)
 end
 ride(lowPrompt,highBase) ride(highPrompt,lowBase)
 lowPrompt.Enabled=false highPrompt.Enabled=false
 return {model=top,first=C.floorStart(3,wing),prompts={lowPrompt,highPrompt},top=true}
end
-- One bank: ground step, deck and columns (in ground), the upper floor's wall,
-- columns, rails and stairs (in up), and the upper wall's top (in parapet).
-- o is the bank's frame: a wing's turned frame, or the rear yard's offset frame.
local function bankWing(ground,up,parapet,o,side)
 local width=L.PerWing*L.Pitch+2 local T=L.TierHeight
 local back=L.BayZ-L.UpperBack-L.BayDepth/2 -- back face of the upper bays
 local riserFront=L.BayZ-L.BayDepth/2 -- back face of the ground bays
 local deckDepth=L.WalkFront-back
  local x=side*L.WingX local inner=x-side*width/2 local stairX=side*L.StairX
  -- Back wall: the ground part stays, the upper part belongs to the upper floor.
  -- Its top 2 studs and cap (the parapet) give way to the third floor's deck.
  bankPanel(ground,"BankBackWall",V(width,T,1.2),o*CFrame.new(x,T/2,back-.6),W.Blue,true)
  bankPanel(up,"BankBackWallUpper",V(width,T,1.2),o*CFrame.new(x,T+T/2,back-.6),W.Blue,true)
  bankPanel(parapet,"BackWallParapet",V(width,2,1.2),o*CFrame.new(x,2*T+1,back-.6),W.Blue,true)
  W.part(parapet,"BackWallCap",V(width+.4,.6,1.6),o*CFrame.new(x,2*T+2.3,back-.6),W.Yellow)
  -- The step: a solid block under the upper row; its front is the ground bays' back.
  bankPanel(ground,"BankStep",V(width,T-.8,riserFront-back),o*CFrame.new(x,(T-.8)/2,(riserFront+back)/2),W.Blue,true)
  -- The deck: roof of the ground bays (and floor of the upper floor once built).
  local deck=W.part(ground,"UpperDeck",V(width,.8,deckDepth),o*CFrame.new(x,T-.4,back+deckDepth/2),Color3.fromRGB(125,159,199),true)
  Style.materialStuds(deck,true,{Enum.NormalId.Top},2)
  W.part(ground,"DeckFascia",V(width,1.4,.8),o*CFrame.new(x,T-.9,L.WalkFront+.2),W.Navy)
  W.part(ground,"FasciaStripe",V(width,.3,.9),o*CFrame.new(x,T-.05,L.WalkFront+.2),W.Yellow)
  for row=0,L.PerWing do
   local px=side*(L.WingX+(row-L.PerWing/2)*L.Pitch)
   W.part(ground,"GroundColumn",V(.9,T-.8,.9),o*CFrame.new(px,(T-.8)/2,L.BayZ+L.BayDepth/2-.2),W.Blue,true)
   W.part(up,"UpperColumn",V(.9,T,.9),o*CFrame.new(px,T+T/2,L.BayZ-L.UpperBack+L.BayDepth/2-.2),W.Blue,true)
  end
  local railEnd=stairX-side*(L.StairWidth/2+.4)
  local railLen=math.abs(railEnd-inner) local railMid=(railEnd+inner)/2
  for _,h in {1.2,3} do W.part(up,"SafetyRail",V(railLen,.4,.4),o*CFrame.new(railMid,T+h,L.WalkFront-.4),W.Yellow,true) end
  for i=0,math.floor(railLen/L.Pitch) do
   W.part(up,"RailPost",V(.5,3.2,.5),o*CFrame.new(inner+side*i*L.Pitch,T+1.6,L.WalkFront-.4),W.Yellow,true)
  end
  W.part(up,"RailPost",V(.5,3.2,.5),o*CFrame.new(railEnd,T+1.6,L.WalkFront-.4),W.Yellow,true)
  for _,h in {1.2,3} do W.part(up,"EndRail",V(.4,.4,deckDepth),o*CFrame.new(inner,T+h,back+deckDepth/2),W.Yellow,true) end
  local count=math.ceil(T) local step=L.StairRun/count
  for i=1,count do
   local z=L.StairFront-(i-.5)*step local y=i*T/count
   W.part(up,"StairTread",V(L.StairWidth,1,step+.08),o*CFrame.new(stairX,y-.5,z),W.Navy,true)
   W.part(up,"StepNose",V(L.StairWidth,.12,.3),o*CFrame.new(stairX,y+.06,z+step/2-.15),W.Yellow)
  end
  for _,edge in {-1,1} do
   local ex=stairX+edge*(L.StairWidth/2-.3)
   local bottom=(o*CFrame.new(ex,3,L.StairFront)).Position
   local top=(o*CFrame.new(ex,T+3,L.WalkFront)).Position
   W.part(up,"StairRail",V(.5,.5,(top-bottom).Magnitude),CFrame.lookAt((top+bottom)/2,top),W.Yellow,true)
   for _,z in {L.StairFront,L.WalkFront} do
    W.part(up,"StairPost",V(.7,3,.7),o*CFrame.new(ex,(if z==L.StairFront then 0 else T)+1.5,z),W.Blue,true)
   end
  end
end
-- Ground banks plus, per wing, an "UpperFloor" model (back wall, columns, rails,
-- stairs) that only appears once that floor is bought (CrusherGame.floorLook).
local function banks(parent,o)
 local m=Instance.new("Model") m.Name="WorkshopBanks" m.Parent=parent
 local floors={} local tops={} local rears={}
 for wing,side in {-1,1} do
  local o=o*C.wingFrame(side) -- build the whole wing in its turned frame
  local up=Instance.new("Model") up.Name="UpperFloor"..wing up.Parent=m
  local parapet=Instance.new("Model") parapet.Name="UpperParapet"..wing parapet.Parent=m
  bankWing(m,up,parapet,o,side)
  local x=side*L.WingX local T=L.TierHeight
  -- "NEW FLOOR" sign standing on the roof, shown when this floor is next to buy.
  local sm=Instance.new("Model") sm.Name="FloorSign"..wing sm.Parent=m
  local cf=o*CFrame.new(x,T,L.BayZ-L.UpperBack+1)
  for _,dx in {-10,10} do W.part(sm,"SignPost",V(1.2,7,1.2),cf*CFrame.new(dx,3.5,0),W.Navy) end
  local face,gui=W.panel(sm,cf*CFrame.new(0,10.5,0),24,10,Color3.fromRGB(53,170,80))
  gui.MaxDistance=260
  local box=Instance.new("Frame") box.Name="Content" box.BackgroundTransparency=1 box.Size=UDim2.fromScale(1,1) box.Parent=gui
  W.text(box,"Title","NEW FLOOR!",UDim2.fromScale(.04,.03),UDim2.fromScale(.92,.32))
  local info=W.text(box,"Info","6 more crusher bays",UDim2.fromScale(.04,.34),UDim2.fromScale(.92,.18))
  info.TextColor3=Color3.fromRGB(255,240,170)
  local buy=W.button(box,"Buy","BUILD",UDim2.fromScale(.12,.56),UDim2.fromScale(.76,.38),"Bay",nil,C.floorStart(2,wing))
  floors[wing]={model=up,sign=sm,face=face,content=box,buy=buy,first=C.floorStart(2,wing),parapet=parapet}
  tops[wing]=topFloor(m,o,wing,side)
 end
 -- Factory IV and V: the same two banks again in the rear yard, behind the
 -- rear row and without the wing tilt. Ground banks come with Factory IV,
 -- their upper floors with Factory V (hidden until bought, see floorLook).
 for wing,side in {-1,1} do
  local ro=o*CFrame.new(0,0,L.RearShift)
  local ground=Instance.new("Model") ground.Name="RearGround"..wing ground.Parent=m
  local up=Instance.new("Model") up.Name="RearUpper"..wing up.Parent=m
  bankWing(ground,up,up,ro,side)
  table.insert(rears,{model=ground,first=C.rearStart(1,wing),top=true})
  table.insert(rears,{model=up,first=C.rearStart(2,wing),top=true})
 end
 return floors,tops,rears
end
-- One bay's frame: floor, beam with a status strip, back panel and padlock.
local function bayFrame(holder,cf)
 local T=L.TierHeight local d=L.BayDepth local w=L.BayWidth
 W.part(holder,"BayPlatform",V(w,.4,d),cf*CFrame.new(0,.2,0),W.Navy,true)
 W.part(holder,"HazardEdge",V(w,.12,.7),cf*CFrame.new(0,.45,d/2-.4),W.Yellow)
 W.part(holder,"TopBeam",V(w,.8,1),cf*CFrame.new(0,T-1.3,d/2-.5),W.Blue)
 local strip=W.part(holder,"StatusStrip",V(w-1,.3,.3),cf*CFrame.new(0,T-1.85,d/2-.5),Color3.fromRGB(255,244,214))
 -- Raised stage at the front of the bay so the whole press is in view.
 local P=L.Pedestal
 W.part(holder,"BayPedestal",V(w-1.2,P,L.MachineDepth+1),cf*CFrame.new(0,.4+P/2,L.MachineZ),W.Navy,true)
 W.part(holder,"PedestalEdge",V(w-1.2,.3,.4),cf*CFrame.new(0,.4+P-.15,L.MachineZ+(L.MachineDepth+1)/2-.1),W.Yellow)
 strip.Material=Enum.Material.Neon strip.CastShadow=false
 local panel=W.part(holder,"LockedInset",V(w-1.2,T-4.5,.4),cf*CFrame.new(0,(T-4.5)/2+.4,-d/2+.4),Color3.fromRGB(150,176,212))
 local lock=Instance.new("Model") lock.Name="Padlock" lock.Parent=holder
 local white=Color3.fromRGB(236,241,250)
 W.part(lock,"LockBody",V(3.4,2.8,.8),cf*CFrame.new(0,3.3,-d/2+.9),white)
 W.part(lock,"Keyhole",V(.5,1,.2),cf*CFrame.new(0,3.2,-d/2+1.35),W.Navy)
 for _,x in {-1.15,1.15} do W.part(lock,"Shackle",V(.55,1.9,.55),cf*CFrame.new(x,5.5,-d/2+.9),white) end
 W.part(lock,"Shackle",V(2.85,.55,.55),cf*CFrame.new(0,6.3,-d/2+.9),white)
 local gui=W.surface(panel) gui:SetAttribute("CrusherWorldControls",false)
 local label=W.text(gui,"Lock","",UDim2.fromScale(.06,.06),UDim2.fromScale(.88,.3))
 return panel,lock,strip,label
end
function P.create(root,Plots)
 require(script.Parent.Hub).create(root)
 local theme=Style.theme(Config.Look.Theme)
 for i=1,Config.Plots.Count do
  local o=Plots.originFor(i) local m=Instance.new("Model") m.Name="Plot"..i m:SetAttribute("Index",i) m:SetAttribute("Origin",o)
  -- The plot ends just behind the banks (no hidden strip of floor at the back).
  local front=Config.Plots.Front local rear=L.BayZ-L.UpperBack-L.BayDepth/2-4 local F=Config.Plots.FloorSize
  Build.platform(m,"Floor",o*CFrame.new(0,0,(front+rear)/2),F,front-rear,2,theme.platform,W.Blue,2)
  local decor=Instance.new("Model") decor.Name="Decor" decor.Parent=m
  W.border(decor,o,F,rear,front,14)
  local sign=W.entrance(decor,o*CFrame.new(0,0,front-4),14)
  W.walkway(m,o,12,rear+2,front)
  local floors,tops,rears=banks(m,o)
  local plot={index=i,origin=o,model=m,owner=nil,sign=sign,bays={},stations={},floors=floors,topFloors=tops,rearFloors=rears}
  for bay=1,C.MaxBays do
   local l=C.bayLayout(bay) local cf=o*C.bayFrame(l)*CFrame.new(l.x,l.y,l.z)*CFrame.Angles(0,l.yaw,0)
   local holder=Instance.new("Model") holder.Name="WorkingBay"..bay holder:SetAttribute("Bay",bay) holder.Parent=m
   local panel,lock,strip,lockLabel=bayFrame(holder,cf)
   -- Low desk-style plaque in front of the bay: readable from above, never covers the press.
   local face,text,buy,manage,max=W.plaque(holder,cf*CFrame.new(0,1.2,L.BayDepth/2+2.4)*CFrame.Angles(math.rad(-66),0,0),bay)
   plot.bays[bay]={model=holder,origin=cf*CFrame.new(0,.4+L.Pedestal,L.MachineZ),label=text,buy=buy,manage=manage,max=max,part=face,locked=panel,padlock=lock,strip=strip,lockLabel=lockLabel,
    prompt=P.prompt(face,"Manage",C.bayName(bay))}
  end
  require(script.Parent.CrusherRowVisuals).create(plot)
  require(script.Parent.FactoryProgressionVisuals).create(plot)
  -- Boards stand low and forward, turned toward the walkway, so the banks show over them.
  for _,spec in {{id="Production",x=-22,z=42,yaw=.3},{id="Rolling",x=22,z=42,yaw=-.3},{id="Collect",x=-60,z=60,yaw=math.pi/2},{id="Sell",x=-26,z=96,yaw=math.pi},{id="Roll",x=52,z=66,yaw=-math.pi/2},{id="Goals",x=52,z=102,yaw=math.pi}} do -- 28 Oct: Sell toward the plaza-side wall (z 80 -> 96), Goals in the front-right corner with its back to the plaza wall (was -44,24)
   local cf=o*CFrame.new(spec.x,0,spec.z)*CFrame.Angles(0,spec.yaw or 0,0)
   local station=if spec.id=="Production" or spec.id=="Rolling" then W.board(m,cf,spec.id) elseif spec.id=="Goals" then W.goals(m,cf) else W.station(m,cf,spec.id)
   if not station.rows then station.prompt=P.prompt(station.part,spec.id,spec.id.." station") end
   plot.stations[spec.id]=station
  end
  -- Conveyor from the outer end of the left bank, climbing into the scrap hopper.
  -- Runs along the plot edge outside the stairs and drops in over the hopper's end wall.
  local bend=(o*CFrame.new(-72.5,7,40)).Position
  W.conveyor(decor,(o*CFrame.new(-72.5,1.4,6)).Position,bend,4,o.Position.Y)
  W.conveyor(decor,bend,(o*CFrame.new(-63,10,51)).Position,4,o.Position.Y)
  -- Toy bricks round the plaza, clear of paths, stations and stairs.
  -- (the ones by the entrance follow the front edge: e = front-92)
  local red=Color3.fromRGB(230,69,77) local orange=Color3.fromRGB(255,140,40) local e=front-92
  for _,b in {{12,87+e,2,2,red,0},{15,89.5+e,2,1,W.Yellow,.4},{-12,87+e,2,2,W.Green,0},{-14,89.5+e,1,1,W.Blue,-.3},
   {-36,62,2,2,W.Yellow,.3},{36,60,2,2,W.Blue,-.4},{30,66,1,1,W.Green,.6},{-14,70,2,2,W.Blue,.2},
   {22,72,2,1,orange,0},{-70,88+e,2,2,red,-.1},{71,86+e,2,2,W.Green,.1},{68,89+e,1,1,W.Yellow,0}} do
   W.brick(decor,o*CFrame.new(b[1],0,b[2])*CFrame.Angles(0,b[6],0),b[3],b[4],b[5])
  end
  W.brick(decor,o*CFrame.new(12,1.6,87+e)*CFrame.Angles(0,.5,0),1,1,W.Blue)
  W.brick(decor,o*CFrame.new(-12,1.6,87+e)*CFrame.Angles(0,-.4,0),2,1,W.Yellow)
  m.Parent=root Moat.build(m,o,true,rear) table.insert(Plots.all(),plot)
  task.wait()
 end
end
return P
