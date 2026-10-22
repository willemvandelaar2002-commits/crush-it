--!strict
-- Collection and the two global upgrade panels. Server snapshots own all values.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local C=require(RS.Shared.CrusherConfig)
local Net=require(RS.Shared.Net)
local Style=require(RS.Shared.Kit.Style)
local Icons=require(RS.Shared.Icons)
local Format=require(RS.Shared.Format)
local H={}
function H.start()
	local p=Players.LocalPlayer local state=nil local selectedBay=1 local noticeUntil=0 local resultUntil=0 local resultText=""
	local navy=Color3.fromRGB(19,23,42) local blue=Color3.fromRGB(45,114,207) local green=Color3.fromRGB(73,186,107)
	local function make(class,props,parent) local v=Instance.new(class) for k,x in props do v[k]=x end v.Parent=parent return v end
	local gui=make("ScreenGui",{Name="CrushHud",ResetOnSpawn=false,DisplayOrder=2,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},p:WaitForChild("PlayerGui"))
	local function text(parent,name,value,pos,size)
		local v=make("TextLabel",{Name=name,Text=value,Position=pos,Size=size,TextScaled=true,BackgroundTransparency=1,TextWrapped=true},parent) Style.text(v,2) return v
	end
	local function button(parent,name,value,pos,size,color,callback)
		local b=make("TextButton",{Name=name,Text=value,Position=pos,Size=size,TextScaled=true,TextWrapped=true,AutoButtonColor=false},parent)
		Style.button(b,color or blue) b.Activated:Connect(callback) return b
	end
	local function act(name,args) Net.event("CrusherAction"):FireServer(name,args) end
	local tutorial=text(gui,"Tutorial","Loading your factory...",UDim2.fromScale(.5,0),UDim2.fromOffset(620,48)) tutorial.AnchorPoint=Vector2.new(.5,0)
	local balances=text(gui,"FactoryBalances","",UDim2.fromScale(.5,0),UDim2.fromOffset(650,32)) balances.AnchorPoint=Vector2.new(.5,0)
	local toast=text(gui,"Notice","",UDim2.new(.5,0,1,-108),UDim2.fromOffset(580,34)) toast.AnchorPoint=Vector2.new(.5,0) toast.TextColor3=Color3.fromRGB(255,223,130)
	local reveal=text(gui,"RollReveal","",UDim2.fromScale(.5,.47),UDim2.fromOffset(520,85)) reveal.AnchorPoint=Vector2.new(.5,.5) reveal.Visible=false reveal.ZIndex=15
	local bar=make("Frame",{Name="FactoryActions",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,1)},gui)
	local panels={} local open,redraw local uiSignature=nil
	for _,kind in {"Inventory","Production","Rolling"} do
		local panel=make("Frame",{Name=if kind=="Inventory" then "Book" else kind.."Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.53),Size=UDim2.new(.9,0,.76,0),BackgroundColor3=navy,Visible=false,ZIndex=5},gui)
		make("UISizeConstraint",{MaxSize=Vector2.new(850,590)},panel) Style.workshopPanel(panel,blue) Style.modal(panel)
		text(panel,"Title",if kind=="Inventory" then "YOUR CRUSHERS" else string.upper(kind).." UPGRADES",UDim2.fromOffset(12,5),UDim2.new(1,-64,0,32))
		button(panel,"Close","X",UDim2.new(1,-43,0,6),UDim2.fromOffset(32,30),Color3.fromRGB(225,79,76),function() panel.Visible=false end)
		for i,tab in {"Inventory","Production","Rolling"} do button(panel,tab.."Tab",if tab=="Inventory" then "CRUSHERS" else string.upper(tab),UDim2.new((i-1)/3,8,0,43),UDim2.new(1/3,-16,0,32),blue,function() open(tab) end) end
		local content=make("ScrollingFrame",{Name=if kind=="Production" then "Upgrades" else "Content",Position=UDim2.fromOffset(8,kind=="Inventory" and 121 or 84),Size=UDim2.new(1,-16,1,kind=="Inventory" and -131 or -94),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Active=true},panel)
		make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},content)
		panels[kind]={frame=panel,content=content}
	end
	local bays={}
	for i=1,C.MaxBays do bays[i]=button(panels.Inventory.frame,if i==2 then "Card_Size" else "Bay"..i,"Bay "..i,UDim2.new((i-1)/3,8,0,83),UDim2.new(1/3,-16,0,30),blue,function()
		if not state then return end
		if i>state.unlocked then
			if i==state.unlocked+1 then act("Unlock") else toast.Text="Unlock bay "..(state.unlocked+1).." first." noticeUntil=os.clock()+4 end
		else selectedBay=i redraw() end
	end) end
	open=function(kind) for name,v in panels do v.frame.Visible=name==kind end end
	local book=Style.iconButton(gui,{name="BookButton",icon="",image=Icons.Book,label="CRUSHERS",a=blue,b=navy})
	Style.placeHudButton(book,0) book.Activated:Connect(function() open("Inventory") end)
	local inv=button(bar,"CrushButton","CRUSHERS",UDim2.fromScale(0,0),UDim2.new(.25,-6,1,0),blue,function() open("Inventory") end)
	local roll=button(bar,"RollButton","ROLL $"..C.RollCost,UDim2.fromScale(.25,0),UDim2.new(.25,-6,1,0),Color3.fromRGB(156,92,220),function() act("Roll") end)
	button(bar,"CollectButton","COLLECT",UDim2.fromScale(.5,0),UDim2.new(.25,-6,1,0),blue,function() act("Collect") end)
	button(bar,"SellButton","SELL",UDim2.fromScale(.75,0),UDim2.new(.25,-6,1,0),green,function() act("Sell") end)
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize local compact=v.X<900 local portrait=v.Y>v.X
		bar.Size=UDim2.fromOffset(if compact then math.min(360,v.X-20) else 600,if compact then 44 else 52)
		bar.Position=UDim2.new(.5,0,1,if portrait then -160 else -16)
		tutorial.Position=UDim2.new(.5,0,0,if compact then 96 else 18) tutorial.Size=UDim2.fromOffset(math.min(620,v.X*.92),44)
		balances.Position=UDim2.new(.5,0,0,if compact then 59 else 72) balances.Size=UDim2.fromOffset(math.min(650,v.X*.92),30)
		toast.Size=UDim2.fromOffset(math.min(580,v.X*.9),38) toast.Position=UDim2.new(.5,0,1,if portrait then -210 else -100)
		reveal.Size=UDim2.fromOffset(math.min(520,v.X*.85),85)
		Style.placeHudButton(book,0)
	end fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	local function clearRows(content) for _,v in content:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end end
	local function benefit(id,lv)
		if id=="Damage" then return string.format("Damage x%.2f -> x%.2f",C.DamageFactor^lv,C.DamageFactor^(lv+1)) end
		if id=="Speed" then return string.format("Cycle x%.2f -> x%.2f",C.SpeedFactor^lv,C.SpeedFactor^(lv+1)) end
		if id=="Yield" then return string.format("Scrap x%.1f -> x%.1f",1+C.YieldPerLevel*lv,1+C.YieldPerLevel*(lv+1)) end
		if id=="Luck" then return "Rare weights +"..math.floor(C.LuckPerLevel*lv*100).."% -> +"..math.floor(C.LuckPerLevel*(lv+1)*100).."% per rarity rank" end
		return string.format("Paid roll interval %.2fs -> %.2fs",C.rollSeconds(lv),C.rollSeconds(lv+1))
	end
	redraw=function()
		if not state then return end
		balances.Text="CASH "..Format.cash(state.cash).."   |   CARRIED "..Format.cash(state.carried).."   |   READY "..Format.cash(state.available)
		tutorial.Text=if state.tutorial==#C.Tutorial and state.unlocked>=C.MaxBays then "All bays unlocked. Level your crushers and keep collecting and selling!" else C.Tutorial[state.tutorial]
		for i,b in bays do b.Text=if i>state.unlocked+1 then "Unlock bay "..(state.unlocked+1).." first" else if i>state.unlocked then "Unlock bay "..i.." "..Format.cash(C.BayCosts[i]) else "Bay "..i..(if i==selectedBay then " SELECTED" else "") end
		-- Production snapshots arrive every second. Keep live buttons and scroll
		-- position intact when only cash/ready scrap changes underneath a finger.
		local key={tostring(selectedBay),tostring(state.unlocked),state.lastRoll or ""}
		for _,id in C.UpgradeOrder do table.insert(key,tostring(state.upgrades[id])) end
		for _,v in state.items do table.insert(key,v.id..":"..v.level..":"..v.stats.cps) end
		local equippedIds={}
		for i=1,C.MaxBays do local id=state.bays[tostring(i)] table.insert(key,id or "-") if id then equippedIds[id]=true end end
		local signature=table.concat(key,"|") if signature==uiSignature then return end uiSignature=signature
		clearRows(panels.Inventory.content)
		local sorted=table.clone(state.items)
		table.sort(sorted,function(a,b)
			local ap=if a.id==state.lastRoll then 0 else if equippedIds[a.id] then 1 else 2
			local bp=if b.id==state.lastRoll then 0 else if equippedIds[b.id] then 1 else 2
			if ap~=bp then return ap<bp end if a.stats.cps~=b.stats.cps then return a.stats.cps>b.stats.cps end return a.id<b.id
		end)
		for index,item in sorted do
			local equipped=nil for k,id in state.bays do if id==item.id then equipped=k end end
			local row=make("Frame",{Name=item.id,Size=UDim2.new(1,-8,0,116),LayoutOrder=index,BackgroundColor3=navy},panels.Inventory.content)
			Style.panel(row,C.rarity(item.rarity).color:Lerp(navy,.55),navy)
			text(row,"CrusherInfo",C.typeById(item.type).name.."  ["..string.sub(item.id,1,8).."]\n"..item.rarity.." / "..item.modifier.." x"..C.modifier(item.modifier).mult.." / Lv "..item.level.."\n"..Format.cash(item.stats.cps*60).." scrap/min"..(if equipped then " / BAY "..equipped else " / stored"),UDim2.fromOffset(8,5),UDim2.new(.66,-12,1,-10))
			button(row,"Level","LEVEL + "..(if item.level>=C.MaxLevel then "MAX" else Format.cash(item.cost)),UDim2.new(.67,0,0,8),UDim2.new(.31,0,0,42),green,function() act("Level",{id=item.id}) end)
			button(row,"Equip",if equipped then "UNEQUIP" else (if state.bays[tostring(selectedBay)] then "REPLACE BAY " else "EQUIP BAY ")..selectedBay,UDim2.new(.67,0,0,61),UDim2.new(.31,0,0,42),blue,function()
				if equipped then act("Unequip",{id=item.id}) else act("Equip",{id=item.id,bay=selectedBay}) end
			end)
		end
		for _,kind in {"Production","Rolling"} do
			local content=panels[kind].content clearRows(content)
			for i,id in C.UpgradeOrder do if C.Upgrades[id].group==kind then
				local lv=state.upgrades[id] local row=make("Frame",{Name=if id=="Damage" then "Card_Power" else "Card_"..id,Size=UDim2.new(1,-8,0,88),LayoutOrder=i,BackgroundColor3=navy},content)
				Style.panel(row,blue,navy)
				text(row,"Benefit",C.Upgrades[id].name.." Lv "..lv.."\n"..benefit(id,lv),UDim2.fromOffset(8,4),UDim2.new(.68,-12,1,-8))
				button(row,"Buy",if lv>=C.MaxGlobal then "MAX" else "BUY "..Format.cash(C.globalCost(id,lv)),UDim2.new(.7,0,0,12),UDim2.new(.28,0,1,-24),green,function() act("Upgrade",{id=id}) end)
			end end
		end
	end
	Net.event("CrusherState").OnClientEvent:Connect(function(snapshot)
		state=snapshot
		if snapshot.message then toast.Text=snapshot.message noticeUntil=os.clock()+5 end
		if snapshot.result then
			local v=snapshot.result resultText=v.rarity.." / "..v.modifier.."\n"..C.typeById(v.type).name
			resultUntil=snapshot.rollReadyAt+2
		end
		redraw()
	end)
	Net.event("CrusherOpen").OnClientEvent:Connect(function(kind,bay) if bay then selectedBay=bay end open(kind) redraw() end)
	Net.event("Notice").OnClientEvent:Connect(function(v) toast.Text=v.text or "" noticeUntil=os.clock()+5 end)
	local last=0 Run.RenderStepped:Connect(function()
		if os.clock()-last<.1 then return end last=os.clock()
		if os.clock()>noticeUntil then toast.Text="" end
		if state then
			local left=math.max(0,state.rollReadyAt-workspace:GetServerTimeNow())
			roll.Text=if left>0 then string.format("ROLL %.1fs",left) else "ROLL $"..C.RollCost
			reveal.Visible=workspace:GetServerTimeNow()<resultUntil
			reveal.Rotation=if left>0 then math.sin(os.clock()*12)*3 else 0
			reveal.Text=if left>0 then C.Types[math.floor(os.clock()*9)%#C.Types+1].name..string.format("\nRolling... %.1fs",left) else resultText
		end
	end)
	Net.event("CrusherAction"):FireServer("Sync")
end
return H
