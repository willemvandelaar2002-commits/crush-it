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
 local p=Players.LocalPlayer local state local pending
 local navy=Color3.fromRGB(19,23,42) local blue=Color3.fromRGB(45,114,207)
 local function make(class,props,parent) local v=Instance.new(class) for k,x in props do v[k]=x end v.Parent=parent return v end
 local function text(parent,name,value,pos,size)
  local v=make("TextLabel",{Name=name,Text=value,Position=pos,Size=size,TextScaled=true,TextWrapped=true,BackgroundTransparency=1},parent) Style.text(v,2) return v
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
 local toast=text(gui,"Notice","",UDim2.new(.5,0,1,-150),UDim2.fromOffset(640,40)) toast.AnchorPoint=Vector2.new(.5,0) toast.TextColor3=Color3.fromRGB(255,225,136)
 local noticeUntil=0
 local indexView=require(script.Parent.CrusherIndex).new(gui,act)
 local book=Style.iconButton(gui,{name="BookButton",image=Icons.Book,label="INDEX",a=blue,b=navy})
 Style.placeHudButton(book,0) book.Activated:Connect(indexView.toggle)
 local bar=require(script.Parent.InventoryBar).new(gui,function() indexView.open(1) end)
 -- screen point of a roll pedestal on your plot (start of the fly-in)
 local function pedestalPoint(slot)
  local plot=workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Plot"..tostring(p:GetAttribute("Plot")))
  local st=plot and plot:FindFirstChild("RollStation",true) local cam=workspace.CurrentCamera
  if not st then return nil end
  for _,v in st:GetChildren() do if v.Name=="Pedestal" and v:GetAttribute("Slot")==slot then
   local sp,on=cam:WorldToViewportPoint(v.Position+Vector3.new(0,4,0))
   if on then return Vector2.new(sp.X,sp.Y)-game:GetService("GuiService"):GetGuiInset() end
  end end
  return nil
 end
 -- Preserve the legacy shop caller's reference without retaining an action toolbar.
 local compatibility=make("Frame",{Name="FactoryActions",Visible=false,Size=UDim2.fromOffset(1,1)},gui)
 make("TextButton",{Name="CrushButton",Visible=false,Size=UDim2.fromOffset(1,1)},compatibility)
 local function redraw()
  if not state then return end
  balances.Text="CARRIED "..Format.cash(state.carried).."  |  READY "..Format.cash(state.available)
  tutorial.Text=C.Tutorial[state.tutorial]
  indexView.update(state)
 end
 -- PlayerGui-hosted SurfaceGuis receive mouse input reliably. Replicated world
 -- templates remain visible to other players; only the owner's copies are interactive.
 -- With streaming, plot parts load in and out; every time a control's part
 -- (re)appears it gets a fresh copy, and copies of parts that left are dropped.
 local copies={} -- original SurfaceGui -> {copy, connections}
 local plotConnections={}
 local function unbind(original)
  local c=copies[original] if not c then return end copies[original]=nil
  for _,x in c.connections do x:Disconnect() end c.copy:Destroy()
 end
 local function clearWorld()
  for _,x in plotConnections do x:Disconnect() end table.clear(plotConnections)
  for original in copies do unbind(original) end
 end
 local function bindOne(original)
  if copies[original] or not original:IsA("SurfaceGui") or not original:GetAttribute("CrusherWorldControls") then return end
  local adornee=original.Parent if not (adornee and adornee:IsA("BasePart")) then return end
  local copy=original:Clone() copy.Name="PlotControls" copy.Adornee=adornee copy.Enabled=original.Enabled copy.Active=true copy.Parent=p.PlayerGui
  original.Enabled=false
  local connections={}
  copies[original]={copy=copy,connections=connections}
  local function mirror(a,b)
   for _,prop in (if a:IsA("TextLabel") or a:IsA("TextButton") then {"Text","Visible","TextColor3"} else if a:IsA("GuiObject") then {"Visible"} else {}) do
    table.insert(connections,a:GetPropertyChangedSignal(prop):Connect(function() b[prop]=a[prop] end))
   end
   local ac,bc=a:GetChildren(),b:GetChildren()
   for i,child in ac do if bc[i] then mirror(child,bc[i]) end end
  end
  mirror(original,copy)
  -- the part streamed out (or was destroyed): drop this copy
  table.insert(connections,original.AncestryChanged:Connect(function() if not original:IsDescendantOf(workspace) then unbind(original) end end))
  for _,v in copy:GetDescendants() do if v:IsA("TextButton") and v:GetAttribute("Action") then
   WorldFx.bind(v)
   v.Activated:Connect(function()
    if not state then return end
    local action=v:GetAttribute("Action") local bay=v:GetAttribute("Bay")
    if action=="Upgrade" or action=="Bay" then pending={row=WorldFx.rowOf(v),t=os.clock(),unlock=action=="Bay" and not state.bays[tostring(bay)]} end
    if action=="Manage" then if bay<=state.unlocked then indexView.open(bay) else toast.Text="Unlock bays in order using their green plaques." noticeUntil=os.clock()+4 end
    elseif action=="Bay" then
     local id=state.bays[tostring(bay)]
     if id then act("Level",{id=id,bay=bay})
     elseif bay==state.unlocked+1 then act("Unlock",{bay=bay})
     elseif bay<=state.unlocked then indexView.open(bay)
     else toast.Text="Unlock bay "..(state.unlocked+1).." first." noticeUntil=os.clock()+4 end
    else act(action,{id=v:GetAttribute("UpgradeId")}) end
   end)
  end end
 end
 local function bindWorld()
  clearWorld()
  local index=p:GetAttribute("Plot") if not index then return end
  local plot=workspace:WaitForChild("Plots"):WaitForChild("Plot"..index)
  for _,original in plot:GetDescendants() do bindOne(original) end
  table.insert(plotConnections,plot.DescendantAdded:Connect(function(v)
   if v:IsA("SurfaceGui") then task.defer(bindOne,v) end -- attributes/children arrive with it
  end))
 end
 p:GetAttributeChangedSignal("Plot"):Connect(function() task.spawn(bindWorld) end)
 task.spawn(bindWorld)
 Net.event("CrusherState").OnClientEvent:Connect(function(v)
  state=v
  if v.boughtSlot and v.result then task.spawn(bar.flyIn,v.result,pedestalPoint(v.boughtSlot),v) else bar.update(v) end
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
 Net.event("CrusherOpen").OnClientEvent:Connect(function(kind,bay) if kind=="Inventory" then indexView.open(bay or 1) end end)
 Net.event("Notice").OnClientEvent:Connect(function(v) toast.Text=v.text or "" noticeUntil=os.clock()+5 end)
 local last=0 Run.RenderStepped:Connect(function()
  if os.clock()-last<.1 then return end last=os.clock()
  if os.clock()>noticeUntil then toast.Text="" end
 end)
 act("Sync")
end
return H
