--!strict
-- Compact inventory; purchases and production controls live on world furniture.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local C=require(RS.Shared.CrusherConfig)
local Net=require(RS.Shared.Net)
local Style=require(RS.Shared.Kit.Style)
local Icons=require(RS.Shared.Icons)
local Format=require(RS.Shared.Format)
local WorldFx=require(script.Parent.WorldFx)
local H={}
function H.start()
 local p=Players.LocalPlayer local state local selectedBay=1 local signature="" local pending
 local navy=Color3.fromRGB(19,23,42) local blue=Color3.fromRGB(45,114,207)
 local function make(class,props,parent) local v=Instance.new(class) for k,x in props do v[k]=x end v.Parent=parent return v end
 local function text(parent,name,value,pos,size)
  local v=make("TextLabel",{Name=name,Text=value,Position=pos,Size=size,TextScaled=true,TextWrapped=true,BackgroundTransparency=1},parent) Style.text(v,2) return v
 end
 local function button(parent,name,value,pos,size,callback)
  local v=make("TextButton",{Name=name,Text=value,Position=pos,Size=size,TextScaled=true,TextWrapped=true},parent)
  Style.button(v,blue) v.Activated:Connect(callback) return v
 end
 local function act(name,args) Net.event("CrusherAction"):FireServer(name,args) end
 local gui=make("ScreenGui",{Name="CrushHud",ResetOnSpawn=false,DisplayOrder=2,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},p:WaitForChild("PlayerGui"))
 local tutorial=text(gui,"Tutorial","Loading factory...",UDim2.new(.5,0,0,70),UDim2.fromOffset(650,46)) tutorial.AnchorPoint=Vector2.new(.5,0)
 local balances=text(gui,"FactoryBalances","",UDim2.new(.5,0,0,122),UDim2.fromOffset(650,30)) balances.AnchorPoint=Vector2.new(.5,0)
 require(script.Parent.CashHud).start(gui)
 local function fitDesktopHeader()
  local width=math.clamp(workspace.CurrentCamera.ViewportSize.X-580,300,650)
  tutorial.Size=UDim2.fromOffset(width,46) balances.Size=UDim2.fromOffset(width,30)
 end
 fitDesktopHeader() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitDesktopHeader)
 local toast=text(gui,"Notice","",UDim2.new(.5,0,1,-90),UDim2.fromOffset(640,40)) toast.AnchorPoint=Vector2.new(.5,0) toast.TextColor3=Color3.fromRGB(255,225,136)
 local noticeUntil=0
 local panel=make("Frame",{Name="Book",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.53),Size=UDim2.fromOffset(660,500),BackgroundColor3=navy,Visible=false,ZIndex=5},gui)
 Style.workshopPanel(panel,blue) Style.modal(panel)
 text(panel,"Title","YOUR CRUSHERS",UDim2.fromOffset(12,6),UDim2.new(1,-65,0,32))
 button(panel,"Close","X",UDim2.new(1,-44,0,6),UDim2.fromOffset(32,32),function() panel.Visible=false end)
 local selector=text(panel,"BaySelection","",UDim2.fromOffset(75,49),UDim2.new(1,-150,0,34))
 local redraw
 button(panel,"PreviousBay","<",UDim2.fromOffset(12,49),UDim2.fromOffset(48,34),function() selectedBay=math.max(1,selectedBay-1) redraw() end)
 button(panel,"NextBay",">",UDim2.new(1,-60,0,49),UDim2.fromOffset(48,34),function() selectedBay=math.min(state and state.unlocked or 1,selectedBay+1) redraw() end)
 text(panel,"Help","Choose a bay and equip a crusher. Level up at its green world plaque.",UDim2.fromOffset(12,89),UDim2.new(1,-24,0,34))
 local content=make("ScrollingFrame",{Name="Content",Position=UDim2.fromOffset(10,130),Size=UDim2.new(1,-20,1,-140),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},panel)
 make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},content)
 local book=Style.iconButton(gui,{name="BookButton",image=Icons.Book,label="CRUSHERS",a=blue,b=navy})
 Style.placeHudButton(book,0) book.Activated:Connect(function() panel.Visible=not panel.Visible end)
 -- Preserve the legacy shop caller's reference without retaining an action toolbar.
 local compatibility=make("Frame",{Name="FactoryActions",Visible=false,Size=UDim2.fromOffset(1,1)},gui)
 make("TextButton",{Name="CrushButton",Visible=false,Size=UDim2.fromOffset(1,1)},compatibility)
 redraw=function()
  if not state then return end
  selectedBay=math.clamp(selectedBay,1,state.unlocked)
  balances.Text="CARRIED "..Format.cash(state.carried).."  |  READY "..Format.cash(state.available)
  tutorial.Text=C.Tutorial[state.tutorial]
  selector.Text="BAY "..selectedBay.." / "..state.unlocked.."   "..C.bayName(selectedBay)
  local key={tostring(selectedBay),tostring(state.unlocked),state.lastRoll or ""}
  for _,v in state.items do table.insert(key,v.id..v.level..v.stats.cps) end
  for i=1,C.MaxBays do table.insert(key,state.bays[tostring(i)] or "-") end
  local nextSignature=table.concat(key,"|") if signature==nextSignature then return end signature=nextSignature
  for _,v in content:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
  local items=table.clone(state.items)
  table.sort(items,function(a,b) if a.id==b.id then return false end if a.id==state.lastRoll then return true elseif b.id==state.lastRoll then return false end if a.stats.cps==b.stats.cps then return a.id<b.id end return a.stats.cps>b.stats.cps end)
  for index,item in items do
   local equipped for bay,id in state.bays do if item.id==id then equipped=bay end end
   local row=make("Frame",{Name="OwnedCrusher"..index,Size=UDim2.new(1,-8,0,106),LayoutOrder=index},content)
   Style.panel(row,C.rarity(item.rarity).color:Lerp(navy,.5),navy)
   text(row,"CrusherInfo",C.typeById(item.type).name.." / Lv "..item.level.."\n"..item.rarity.." / "..item.modifier.."\n"..Format.cash(item.stats.cps*60).." scrap/min"..(if equipped then " / BAY "..equipped else " / stored"),UDim2.fromOffset(8,4),UDim2.new(.68,-12,1,-8))
   button(row,"Equip",if equipped then "UNEQUIP" else (if state.bays[tostring(selectedBay)] then "REPLACE BAY " else "EQUIP BAY ")..selectedBay,UDim2.new(.7,0,0,17),UDim2.new(.28,0,1,-34),function()
    if equipped then act("Unequip",{id=item.id}) else act("Equip",{id=item.id,bay=selectedBay}) end
   end)
  end
 end
 -- PlayerGui-hosted SurfaceGuis receive mouse input reliably. Replicated world
 -- templates remain visible to other players; only the owner's copies are interactive.
 local worldConnections={} local worldCopies={}
 local function clearWorld()
  for _,c in worldConnections do c:Disconnect() end table.clear(worldConnections)
  for _,v in worldCopies do v:Destroy() end table.clear(worldCopies)
 end
 local function bindWorld()
  clearWorld()
  local index=p:GetAttribute("Plot") if not index then return end
  local plot=workspace:WaitForChild("Plots"):WaitForChild("Plot"..index)
  for _,original in plot:GetDescendants() do
   if not original:IsA("SurfaceGui") or not original:GetAttribute("CrusherWorldControls") then continue end
   local copy=original:Clone() copy.Name="PlotControls_"..#worldCopies copy.Adornee=original.Parent copy.Enabled=original.Enabled copy.Active=true copy.Parent=p.PlayerGui
   table.insert(worldCopies,copy) original.Enabled=false
   local function mirror(a,b)
    for _,prop in (if a:IsA("TextLabel") or a:IsA("TextButton") then {"Text","Visible","TextColor3"} else if a:IsA("GuiObject") then {"Visible"} else {}) do
     table.insert(worldConnections,a:GetPropertyChangedSignal(prop):Connect(function() b[prop]=a[prop] end))
    end
    local ac,bc=a:GetChildren(),b:GetChildren()
    for i,child in ac do if bc[i] then mirror(child,bc[i]) end end
   end
   mirror(original,copy)
   for _,v in copy:GetDescendants() do if v:IsA("TextButton") and v:GetAttribute("Action") then
    WorldFx.bind(v)
    v.Activated:Connect(function()
     if not state then return end
     local action=v:GetAttribute("Action") local bay=v:GetAttribute("Bay")
     if action=="Upgrade" or action=="Bay" then pending={row=WorldFx.rowOf(v),t=os.clock(),unlock=action=="Bay" and not state.bays[tostring(bay)]} end
     if action=="Manage" then if bay<=state.unlocked then selectedBay=bay redraw() panel.Visible=true else toast.Text="Unlock bays in order using their green plaques." noticeUntil=os.clock()+4 end
     elseif action=="Bay" then
      local id=state.bays[tostring(bay)]
      if id then act("Level",{id=id,bay=bay})
      elseif bay==state.unlocked+1 then act("Unlock",{bay=bay})
      elseif bay<=state.unlocked then selectedBay=bay redraw() panel.Visible=true
      else toast.Text="Unlock bay "..(state.unlocked+1).." first." noticeUntil=os.clock()+4 end
     else act(action,{id=v:GetAttribute("UpgradeId")}) end
    end)
   end end
  end
 end
 p:GetAttributeChangedSignal("Plot"):Connect(function() task.spawn(bindWorld) end)
 task.spawn(bindWorld)
 Net.event("CrusherState").OnClientEvent:Connect(function(v)
  state=v
  -- world purchase feedback: the next answer after a board/plaque click
  if pending and v.message and os.clock()-pending.t<2 then
   if v.message=="Done!" then WorldFx.success(pending.row,if pending.unlock then "BAY UNLOCKED!" else nil) v.message=nil
   else WorldFx.fail(pending.row) end
   pending=nil
  end
  -- rolls are revealed on the roll machine's pedestals; no screen spoiler
  if v.message then toast.Text=v.message noticeUntil=os.clock()+5 end
  redraw()
 end)
 Net.event("CrusherOpen").OnClientEvent:Connect(function(kind,bay) if kind=="Inventory" then selectedBay=bay or selectedBay redraw() panel.Visible=true end end)
 Net.event("Notice").OnClientEvent:Connect(function(v) toast.Text=v.text or "" noticeUntil=os.clock()+5 end)
 local last=0 Run.RenderStepped:Connect(function()
  if os.clock()-last<.1 then return end last=os.clock()
  if os.clock()>noticeUntil then toast.Text="" end
 end)
 act("Sync")
end
return H
