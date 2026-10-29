--!strict
-- Reference-style collection browser. Types/odds come only from the live config;
-- Owned preserves unique instances and sends the existing equip transactions.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.Shared.CrusherConfig)
local Rows = require(RS.Shared.CrusherRows)
local Rules = require(RS.Shared.CrusherRules)
local CrusherIcon = require(script.Parent.CrusherIcon)
local Style = require(RS.Shared.Kit.Style)
local Icons = require(RS.Shared.Icons)
local Format = require(RS.Shared.Format)
local I = {}
local ink = Style.Colors.Ink
local blue = Color3.fromRGB(60, 172, 255)
local green = Color3.fromRGB(70, 225, 86)
local white = Color3.new(1, 1, 1)

local function make(class, props, parent)
	local node = Instance.new(class)
	for key, value in props do node[key] = value end
	node.Parent = parent
	return node
end
local function label(parent, name, value, position, size, fontSize)
	local node = make("TextLabel", {Name=name, Text=value, Position=position, Size=size,
		TextSize=fontSize or 24, TextWrapped=true, BackgroundTransparency=1, ZIndex=3}, parent)
	Style.text(node, 2)
	return node
end
local function button(parent, name, value, position, size, colour, callback)
	local node = make("TextButton", {Name=name, Text=value, Position=position, Size=size,
		TextSize=22, TextWrapped=true, ZIndex=3}, parent)
	Style.button(node, colour)
	local corner = node:FindFirstChildOfClass("UICorner")
	if corner then corner.CornerRadius = UDim.new(0, 4) end
	node.Activated:Connect(callback)
	return node
end

function I.new(gui, act)
	local self = {} local state local tab = "Index" local filter = "All" local selectedBay = 1
	local signature = "" local records = {} local redraw local hydrate local recyclePending
	local panel = make("Frame", {Name="Book", AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.54,.52), Size=UDim2.fromOffset(980,650), Visible=false,
		BackgroundColor3=ink, BackgroundTransparency=.08, BorderSizePixel=0, ZIndex=5}, gui)
	make("UICorner", {CornerRadius=UDim.new(0,5)}, panel)
	make("UIStroke", {Color=ink, Thickness=4}, panel)
	Style.modal(panel)
	local header = make("Frame", {Name="Header", Size=UDim2.new(1,0,0,76), ZIndex=2}, panel)
	Style.collectionPanel(header, blue, Color3.fromRGB(33,121,207))
	Style.image(header, Icons.Book, {Name="BookIcon", Position=UDim2.fromOffset(20,34),
		Size=UDim2.fromOffset(114,114), Rotation=-12, ZIndex=4})
	local title = label(header,"Title","Index",UDim2.fromOffset(84,3),UDim2.new(1,-330,1,-6),48)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local count = label(header,"Count","0 / "..#C.Types,UDim2.new(1,-245,0,10),UDim2.fromOffset(160,54),34)
	button(header,"Close","X",UDim2.new(1,-67,0,10),UDim2.fromOffset(54,54),Style.Colors.Red,function() Style.setOpen(panel,false) end)
	local nav = make("Frame", {Name="Tabs", Position=UDim2.fromOffset(-157,103),
		Size=UDim2.fromOffset(142,150), BackgroundTransparency=1, ZIndex=2}, panel)
	local indexButton local ownedButton
	local function chooseTab(value)
		tab=value signature="" redraw()
	end
	indexButton=button(nav,"IndexTab","INDEX",UDim2.new(),UDim2.fromOffset(142,58),blue,function() chooseTab("Index") end)
	ownedButton=button(nav,"OwnedTab","OWNED",UDim2.fromOffset(0,72),UDim2.fromOffset(142,58),Style.Colors.Purple,function() chooseTab("Owned") end)
	ownedButton.Visible=false -- your crushers live in the bottom hotbar now
	local controls = make("Frame", {Name="Controls", Position=UDim2.fromOffset(12,88),
		Size=UDim2.new(1,-24,0,44), BackgroundTransparency=1, ZIndex=2}, panel)
	local filters = make("Frame", {Name="RarityFilters", Size=UDim2.fromScale(1,1), BackgroundTransparency=1}, controls)
	make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8),
		SortOrder=Enum.SortOrder.LayoutOrder}, filters)
	local filterButtons={}
	local options={{name="All",color=blue}}
	for _,rarity in C.Rarities do table.insert(options,{name=rarity.name,color=rarity.color}) end
	for order,option in options do
		local node=button(filters,"Filter_"..option.name,option.name,UDim2.new(),
			UDim2.new(1/#options,-8,1,0),option.color,function() filter=option.name signature="" redraw() end)
		node.TextSize=18 node.LayoutOrder=order filterButtons[option.name]=node
	end
	local bayControls=make("Frame",{Name="BayControls",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},controls)
	button(bayControls,"PreviousBay","<",UDim2.new(),UDim2.fromOffset(48,40),blue,function()
		selectedBay=math.max(1,selectedBay-1) signature="" redraw()
	end)
	local selector=label(bayControls,"BaySelection","BAY 1",UDim2.fromOffset(60,0),UDim2.new(1,-370,1,0),24)
	button(bayControls,"NextBay",">",UDim2.new(1,-298,0,0),UDim2.fromOffset(48,40),blue,function()
		selectedBay=math.min(state and state.unlocked or 1,selectedBay+1) signature="" redraw()
	end)
	-- Trash can: recycle every unequipped duplicate in one go (second click confirms).
	-- Keeps equipped crushers and the strongest copy of each type.
	local dupesPending=false
	local function extras()
		if not state then return {} end
		local equipped={} for bay,id in state.bays do equipped[bay]=id end
		return Rules.duplicateExtras(state.items,equipped,function(item) return item.stats.cps end)
	end
	-- in the header (the OWNED tab is hidden; your crushers live in the hotbar)
	local dupes dupes=button(header,"RecycleDuplicates","🗑 RECYCLE DUPES",UDim2.new(1,-480,0,14),UDim2.fromOffset(220,48),Style.Colors.Red,function()
		local n=#extras()
		if n==0 then dupesPending=false dupes.Text="🗑 NO DUPES" return end
		if dupesPending then dupesPending=false act("RecycleDuplicates",{}) return end
		dupesPending=true dupes.Text="CONFIRM · "..n.." CRUSHER"..(if n==1 then "" else "S")
		task.delay(3,function() if dupesPending then dupesPending=false signature="" redraw() end end)
	end)
	dupes.TextSize=18
	local content=make("ScrollingFrame",{Name="Content",Position=UDim2.fromOffset(10,145),
		Size=UDim2.new(1,-20,1,-207),BackgroundTransparency=1,BorderSizePixel=0,
		AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=7,ZIndex=2},panel)
	Style.scroll(content)
	make("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder},content)
	local footer=make("Frame",{Name="CollectionProgress",Position=UDim2.new(0,12,1,-49),Size=UDim2.new(1,-24,0,35),ZIndex=2},panel)
	Style.collectionPanel(footer,Color3.fromRGB(49,67,98),ink)
	local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=green,BorderSizePixel=0,ZIndex=1},footer)
	make("UICorner",{CornerRadius=UDim.new(0,3)},fill)
	Style.studsImage(fill,24,.75)
	local progress=label(footer,"ProgressText","Loading collection...",UDim2.new(),UDim2.fromScale(1,1),21)
	local empty=label(content,"Empty","",UDim2.new(),UDim2.fromOffset(200,220),24)
	empty.Visible=false
	local function clear()
		for _,record in records do record.card:Destroy() end
		table.clear(records)
	end
	local function preview(record)
		if record.rendered or not panel.Visible then return end
		record.viewport=CrusherIcon.new(record.card,record.type,{position=UDim2.fromOffset(0,30),size=UDim2.new(1,0,0,133),hidden=record.hidden,modifier=record.modifier,zIndex=2})
		record.rendered=true record.fallback.Visible=false
	end
	hydrate=function()
		if not panel.Visible then return end
		local top=content.CanvasPosition.Y local bottom=top+content.AbsoluteSize.Y
		for _,record in records do
			local y=record.card.AbsolutePosition.Y-content.AbsolutePosition.Y+top
			if y+record.card.AbsoluteSize.Y>=top-220 and y<=bottom+220 then preview(record)
			elseif record.viewport then record.viewport:Destroy() record.viewport=nil record.rendered=false record.fallback.Visible=true end
		end
	end
	local function card(def,item,order,equipped)
		local rarity=C.rarityOf(def.id)
		local colour=(if item then C.rarity(item.rarity) else rarity).color
		local frame=make("Frame",{Name="Card_"..(if item then item.id else def.id),LayoutOrder=order,ZIndex=1},content)
		Style.collectionPanel(frame,Style.lighten(colour,.22),Style.darken(colour,.24))
		local known=false
		for _,owned in state.items do if owned.type==def.id then known=true break end end
		if state.fusion and state.fusion.item and state.fusion.item.type==def.id then known=true end -- inside the Fusion Machine
		label(frame,"Name",if known then def.name else "???",UDim2.fromOffset(5,4),UDim2.new(1,-10,0,30),22)
		local fallback=Style.image(frame,Icons.Press,{Name="PreviewFallback",Position=UDim2.new(.5,0,0,94),Size=UDim2.fromOffset(94,94),ZIndex=2})
		fallback.ImageColor3=if known then white else Color3.new(0,0,0)
		label(frame,"Rarity",if item then item.rarity.." · Lv "..item.level else rarity.name,
			UDim2.fromOffset(4,158),UDim2.new(1,-8,0,25),19)
		if item then
			local stats=label(frame,"Output",Format.cash(item.stats.cps*60).." scrap/min",UDim2.fromOffset(4,182),UDim2.new(1,-8,0,23),16)
			stats.TextColor3=Color3.fromRGB(255,241,175)
			if (item.stats.rowBonus or 0)>0 then
				stats.Text=Format.cash(item.stats.cps*60).."/min · ROW +"..math.floor(item.stats.rowBonus*100+.5).."%"
				stats.TextScaled=true
			end
			local action=if equipped then "UNEQUIP · BAY "..equipped else "EQUIP · BAY "..selectedBay
			button(frame,"Equip",action,UDim2.new(0,7,1,-82),UDim2.new(1,-14,0,35),
				if equipped then Style.Colors.Blue else green,function()
					if equipped then act("Unequip",{id=item.id}) else act("Equip",{id=item.id,bay=selectedBay}) end
				end).TextSize=17
			local copies=0 for _,other in state.items do if other.type==item.type then copies+=1 end end
			if not equipped and copies>1 then
				local recycle
				recycle=button(frame,"Recycle","RECYCLE DUPLICATE",UDim2.new(0,7,1,-42),UDim2.new(1,-14,0,33),Style.Colors.Red,function()
					if recyclePending==item.id then recyclePending=nil act("Recycle",{id=item.id})
					else
						recyclePending=item.id recycle.Text="CONFIRM · LV "..item.level
						task.delay(3,function() if recyclePending==item.id then recyclePending=nil if recycle.Parent then recycle.Text="RECYCLE DUPLICATE" end end end)
					end
				end)
				recycle.TextSize=15
			else
				local guard=label(frame,"Protected",if equipped then "EQUIPPED" else "LAST OF THIS TYPE",UDim2.new(0,5,1,-39),UDim2.new(1,-10,0,28),15)
				guard.TextColor3=Color3.fromRGB(233,240,255)
			end
			if item.modifier~="Standard" or item.fused then
				local text=if item.fused and item.modifier~="Standard" then "FUSED · "..item.modifier elseif item.fused then "FUSED x"..C.Fusion.Mult else item.modifier
				local mod=label(frame,"Modifier",text,UDim2.fromOffset(5,135),UDim2.new(1,-10,0,22),17)
				if item.fused then mod.TextColor3=Color3.fromRGB(255,205,60) end
			end
		else
			local crate=def.crate==true
			local exclusive=crate or (C.rarityOf(def.id) and C.rarityOf(def.id).exclusive)
			local odds=label(frame,"Odds",if crate then "CRATE ONLY" elseif exclusive then "SHOP & SPIN ONLY" else "1 in "..tostring(C.oddsFor(def.id)),UDim2.fromOffset(4,185),UDim2.new(1,-8,0,28),if exclusive then 17 else 22)
			if exclusive then odds.TextColor3=Color3.fromRGB(255,150,225) end
		end
		table.insert(records,{card=frame,type=def.id,hidden=not known,fallback=fallback,modifier=if item then item.modifier else nil})
	end
	redraw=function()
		if not state then return end
		selectedBay=math.clamp(selectedBay,1,state.unlocked)
		filters.Visible=tab=="Index" bayControls.Visible=tab=="Owned"
		title.Text=if tab=="Index" then "Index" else "Your Crushers"
		selector.Text="BAY "..selectedBay.." / "..state.unlocked.." · "..C.bayName(selectedBay)
		local seen={} local unique=0
		for _,item in state.items do if not seen[item.type] then seen[item.type]=true unique+=1 end end
		count.Text=if tab=="Index" then unique.." / "..#C.Types else #state.items.." / "..C.MaxInventory
		progress.Text=if tab=="Index" then unique.." / "..#C.Types.." crushers discovered · base odds before luck"
			else "Choose a bay and equip a crusher. Level up at its world plaque."
		local row=state.rows and state.rows[Rows.index(selectedBay)]
		if tab=="Owned" and row then
			local heading=Rows.label(row)
			progress.Text=heading.." · "..(if row.active then "+"..math.floor(row.bonus*100+.5).."% SCRAP" else "MATCH A RARITY FOR A SCRAP BOOST")
		end
		fill.Size=UDim2.fromScale(unique/math.max(1,#C.Types),1) fill.Visible=tab=="Index"
		if not dupesPending then local n=#extras() dupes.Text=if n>0 then "🗑 RECYCLE "..n.." DUPE"..(if n==1 then "" else "S") else "🗑 NO DUPES"
			Style.setButtonColor(dupes,if n>0 then Style.Colors.Red else Color3.fromRGB(104,116,138)) end
		indexButton.TextTransparency=if tab=="Index" then 0 else .2
		ownedButton.TextTransparency=if tab=="Owned" then 0 else .2
		for name,node in filterButtons do node.TextTransparency=if name==filter then 0 else .2 end
		local keys={tab,filter,tostring(selectedBay),tostring(state.unlocked)}
		for _,item in state.items do table.insert(keys,item.id..":"..item.type..":"..item.rarity..":"..item.modifier..":"..item.level..":"..item.stats.cps..":"..tostring(item.fused)) end
		for bay=1,C.MaxBays do table.insert(keys,state.bays[tostring(bay)] or "-") end
		local nextSignature=table.concat(keys,"|")
		if signature==nextSignature or not panel.Visible then return end
		signature=nextSignature
		local position=content.CanvasPosition clear()
		local grid=content:FindFirstChildOfClass("UIGridLayout")
		recyclePending=nil
		grid.CellSize=UDim2.fromOffset(grid.CellSize.X.Offset,if tab=="Index" then 220 else 296)
		if tab=="Index" then
			local defs=table.clone(C.Types)
			table.sort(defs,function(a,b)
				local ra,rb=C.rarityOf(a.id),C.rarityOf(b.id)
				if ra.rank~=rb.rank then return ra.rank<rb.rank end
				return a.name<b.name
			end)
			for _,def in defs do if filter=="All" or C.rarityOf(def.id).name==filter then card(def,nil,#records+1,nil) end end
		else
			local items=table.clone(state.items)
			table.sort(items,function(a,b) if a.stats.cps~=b.stats.cps then return a.stats.cps>b.stats.cps end return a.id<b.id end)
			for order,item in items do
				local equipped for bay,id in state.bays do if item.id==id then equipped=bay break end end
				card(C.typeById(item.type),item,order,equipped)
			end
		end
		empty.Text=if tab=="Index" then "No crushers in this rarity." else "No owned crushers."
		empty.Visible=#records==0
		content.CanvasPosition=position
		task.defer(hydrate)
	end
	local function fitDesktop()
		local size=workspace.CurrentCamera.ViewportSize
		panel.Size=UDim2.fromOffset(math.clamp(size.X-360,560,1000),math.clamp(size.Y-155,440,720))
		local grid=content:FindFirstChildOfClass("UIGridLayout")
		local width=math.max(350,content.AbsoluteSize.X)
		local columns=math.max(2,math.floor((width-4)/192))
		grid.CellPadding=UDim2.fromOffset(12,12)
		grid.CellSize=UDim2.fromOffset(math.floor((width-24-(columns-1)*12)/columns),if tab=="Index" then 220 else 296)
		task.defer(hydrate)
	end
	content:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitDesktop)
	content:GetPropertyChangedSignal("CanvasPosition"):Connect(hydrate)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitDesktop)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		recyclePending=nil dupesPending=false
		if panel.Visible then fitDesktop() redraw() else
			for _,record in records do if record.viewport then record.viewport:Destroy() record.viewport=nil record.rendered=false record.fallback.Visible=true end end
		end
	end)
	function self.update(value) state=value redraw() end
	function self.open(bay)
		tab="Index"
		signature="" panel.Visible=true redraw()
	end
	function self.toggle() if panel.Visible then Style.setOpen(panel,false) else self.open() end end
	self.panel=panel fitDesktop()
	return self
end

return I
