--!strict
-- Two open, two-storey crusher banks around a clear plaza; coordinates are local.
local S=game:GetService("ReplicatedStorage").Shared
local Config=require(S.Config) local C=Config.Crushers local L=C.Layout
local Build=require(script.Parent.Kit.Build)
local W=require(script.Parent.Kit.CrusherWorkshop)
local Style=require(S.Kit.Style)
local Moat=require(script.Parent.Moat)
local P={} local V=Vector3.new
function P.prompt(part,action,title)
 local p=Instance.new("ProximityPrompt") p.Name="FactoryPrompt" p.ActionText=action p.ObjectText=title
 p.KeyboardKeyCode=Enum.KeyCode.E p.HoldDuration=0 p.MaxActivationDistance=12 p.RequiresLineOfSight=false p.Parent=part return p
end
local function banks(parent,o)
 local m=Instance.new("Model") m.Name="WorkshopBanks" m.Parent=parent
 local width=L.PerWing*L.Pitch+2 local T=L.TierHeight
 local back=L.BayZ-L.UpperBack-L.BayDepth/2 -- back face of the upper bays
 local riserFront=L.BayZ-L.BayDepth/2 -- back face of the ground bays
 local deckDepth=L.WalkFront-back
 for _,side in {-1,1} do
  local o=o*C.wingFrame(side) -- build the whole wing in its turned frame
  local x=side*L.WingX local inner=x-side*width/2 local stairX=side*L.StairX
  -- Back wall behind the upper row, capped with a yellow trim line.
  W.part(m,"BankBackWall",V(width,2*T+2,1.2),o*CFrame.new(x,T+1,back-.6),W.Blue,true)
  W.part(m,"BackWallCap",V(width+.4,.6,1.6),o*CFrame.new(x,2*T+2.3,back-.6),W.Yellow)
  -- The step: a solid block under the upper row; its front is the ground bays' back.
  W.part(m,"BankStep",V(width,T-.8,riserFront-back),o*CFrame.new(x,(T-.8)/2,(riserFront+back)/2),W.Blue,true)
  -- One deck: upper bay floor + walkway over the ground bays.
  local deck=W.part(m,"UpperDeck",V(width,.8,deckDepth),o*CFrame.new(x,T-.4,back+deckDepth/2),Color3.fromRGB(125,159,199),true)
  Style.materialStuds(deck,true,{Enum.NormalId.Top},2)
  W.part(m,"DeckFascia",V(width,1.4,.8),o*CFrame.new(x,T-.9,L.WalkFront+.2),W.Navy)
  W.part(m,"FasciaStripe",V(width,.3,.9),o*CFrame.new(x,T-.05,L.WalkFront+.2),W.Yellow)
  -- Columns between bays on both rows.
  for row=0,L.PerWing do
   local px=side*(L.WingX+(row-L.PerWing/2)*L.Pitch)
   W.part(m,"GroundColumn",V(.9,T-.8,.9),o*CFrame.new(px,(T-.8)/2,L.BayZ+L.BayDepth/2-.2),W.Blue,true)
   W.part(m,"UpperColumn",V(.9,T,.9),o*CFrame.new(px,T+T/2,L.BayZ-L.UpperBack+L.BayDepth/2-.2),W.Blue,true)
  end
  -- Front safety rail with a gap where the stairs land, and a short end rail.
  local railEnd=stairX-side*(L.StairWidth/2+.4)
  local railLen=math.abs(railEnd-inner) local railMid=(railEnd+inner)/2
  for _,h in {1.2,3} do W.part(m,"SafetyRail",V(railLen,.4,.4),o*CFrame.new(railMid,T+h,L.WalkFront-.4),W.Yellow,true) end
  for i=0,math.floor(railLen/L.Pitch) do
   W.part(m,"RailPost",V(.5,3.2,.5),o*CFrame.new(inner+side*i*L.Pitch,T+1.6,L.WalkFront-.4),W.Yellow,true)
  end
  W.part(m,"RailPost",V(.5,3.2,.5),o*CFrame.new(railEnd,T+1.6,L.WalkFront-.4),W.Yellow,true)
  for _,h in {1.2,3} do W.part(m,"EndRail",V(.4,.4,deckDepth),o*CFrame.new(inner,T+h,back+deckDepth/2),W.Yellow,true) end
  -- Stairs at the outer end, climbing from the plaza onto the walkway.
  local count=math.ceil(T) local step=L.StairRun/count
  for i=1,count do
   local z=L.StairFront-(i-.5)*step local y=i*T/count
   W.part(m,"StairTread",V(L.StairWidth,1,step+.08),o*CFrame.new(stairX,y-.5,z),W.Navy,true)
   W.part(m,"StepNose",V(L.StairWidth,.12,.3),o*CFrame.new(stairX,y+.06,z+step/2-.15),W.Yellow)
  end
  for _,edge in {-1,1} do
   local ex=stairX+edge*(L.StairWidth/2-.3)
   local bottom=(o*CFrame.new(ex,3,L.StairFront)).Position
   local top=(o*CFrame.new(ex,T+3,L.WalkFront)).Position
   W.part(m,"StairRail",V(.5,.5,(top-bottom).Magnitude),CFrame.lookAt((top+bottom)/2,top),W.Yellow,true)
   for _,z in {L.StairFront,L.WalkFront} do
    W.part(m,"StairPost",V(.7,3,.7),o*CFrame.new(ex,(if z==L.StairFront then 0 else T)+1.5,z),W.Blue,true)
   end
  end
 end
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
  banks(m,o)
  local plot={index=i,origin=o,model=m,owner=nil,sign=sign,bays={},stations={}}
  for bay=1,C.MaxBays do
   local l=C.bayLayout(bay) local cf=o*C.wingFrame(l.side)*CFrame.new(l.x,l.y,l.z)*CFrame.Angles(0,l.yaw,0)
   local holder=Instance.new("Model") holder.Name="WorkingBay"..bay holder:SetAttribute("Bay",bay) holder.Parent=m
   local panel,lock,strip,lockLabel=bayFrame(holder,cf)
   -- Low desk-style plaque in front of the bay: readable from above, never covers the press.
   local face,text,buy,manage=W.plaque(holder,cf*CFrame.new(0,1.2,L.BayDepth/2+2.4)*CFrame.Angles(math.rad(-66),0,0),bay)
   plot.bays[bay]={model=holder,origin=cf*CFrame.new(0,.4+L.Pedestal,L.MachineZ),label=text,buy=buy,manage=manage,part=face,locked=panel,padlock=lock,strip=strip,lockLabel=lockLabel,
    prompt=P.prompt(face,"Manage",C.bayName(bay))}
  end
  -- Boards stand low and forward, turned toward the walkway, so the banks show over them.
  for _,spec in {{id="Production",x=-22,z=42,yaw=.3},{id="Rolling",x=22,z=42,yaw=-.3},{id="Collect",x=-60,z=60,yaw=math.pi/2},{id="Sell",x=-26,z=80,yaw=math.pi},{id="Roll",x=46,z=72,yaw=math.pi}} do
   local cf=o*CFrame.new(spec.x,0,spec.z)*CFrame.Angles(0,spec.yaw or 0,0)
   local station=if spec.id=="Production" or spec.id=="Rolling" then W.board(m,cf,spec.id) else W.station(m,cf,spec.id)
   if not station.rows then station.prompt=P.prompt(station.part,spec.id,spec.id.." station") end
   plot.stations[spec.id]=station
  end
  -- Conveyor from the outer end of the left bank, climbing into the scrap hopper.
  -- Runs along the plot edge outside the stairs and drops in over the hopper's end wall.
  local bend=(o*CFrame.new(-72.5,7,40)).Position
  W.conveyor(decor,(o*CFrame.new(-72.5,1.4,6)).Position,bend,4,o.Position.Y)
  W.conveyor(decor,bend,(o*CFrame.new(-63,10,51)).Position,4,o.Position.Y)
  -- Toy bricks round the plaza, clear of paths, stations and stairs.
  local red=Color3.fromRGB(230,69,77) local orange=Color3.fromRGB(255,140,40)
  for _,b in {{12,87,2,2,red,0},{15,89.5,2,1,W.Yellow,.4},{-12,87,2,2,W.Green,0},{-14,89.5,1,1,W.Blue,-.3},
   {-36,62,2,2,W.Yellow,.3},{36,60,2,2,W.Blue,-.4},{30,66,1,1,W.Green,.6},{-14,70,2,2,W.Blue,.2},
   {22,72,2,1,orange,0},{-64,88,2,2,red,-.1},{71,86,2,2,W.Green,.1},{-58,89,1,1,W.Yellow,0},{68,89,1,1,W.Yellow,0}} do
   W.brick(decor,o*CFrame.new(b[1],0,b[2])*CFrame.Angles(0,b[6],0),b[3],b[4],b[5])
  end
  W.brick(decor,o*CFrame.new(12,1.6,87)*CFrame.Angles(0,.5,0),1,1,W.Blue)
  W.brick(decor,o*CFrame.new(-12,1.6,87)*CFrame.Angles(0,-.4,0),2,1,W.Yellow)
  m.Parent=root Moat.build(m,o,true,rear) table.insert(Plots.all(),plot)
  task.wait()
 end
end
return P
