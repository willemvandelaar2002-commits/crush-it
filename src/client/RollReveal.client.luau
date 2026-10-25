--!strict
-- Owner-only, bounded reveal accents. World pedestals remain the purchase UI.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Tags=game:GetService("CollectionService")
local SoundService=game:GetService("SoundService")
local Content=game:GetService("ContentProvider")
local Config=require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local C=require(RS.Shared.CrusherConfig)
local P=require(RS.Shared.CrusherRollPresentation)
local Style=require(RS.Shared.Kit.Style)
local Net=require(RS.Shared.Net)
local me=Players.LocalPlayer
local function make(class,props,parent)
	local v=Instance.new(class) for k,x in props do v[k]=x end v.Parent=parent return v
end
local folder=make("Folder",{Name="LocalRollReveals"},workspace)
local gui=make("ScreenGui",{Name="CrusherDiscoveries",ResetOnSpawn=false,DisplayOrder=8,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},me:WaitForChild("PlayerGui"))
local function label(parent,name,y,height,size)
	local l=make("TextLabel",{Name=name,BackgroundTransparency=1,Text="",TextScaled=true,
		Position=UDim2.fromOffset(8,y),Size=UDim2.new(1,-16,0,height),TextSize=size or 24},parent)
	Style.text(l,2) return l
end
local pools={}
for i=1,P.MaxSlots do
	local anchor=make("Part",{Name="RevealAnchor"..i,Size=Vector3.one*.1,Anchored=true,
		CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,CastShadow=false},folder)
	local highlight=make("Highlight",{Name="RevealOutline"..i,Enabled=false,DepthMode=Enum.HighlightDepthMode.Occluded},folder)
	local board=make("BillboardGui",{Name="RevealBadge"..i,Size=UDim2.fromOffset(330,86),
		AlwaysOnTop=false,MaxDistance=85,LightInfluence=0,Adornee=anchor,Enabled=false},gui)
	pools[i]={anchor=anchor,highlight=highlight,board=board,title=label(board,"Rarity",0,43,32),
		sub=label(board,"Collection",47,30,20)}
end
local banner=make("Frame",{Name="Discovery",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-135),Size=UDim2.fromOffset(570,118),Visible=false},gui)
Style.panel(banner,Style.Colors.Gold,Style.Colors.Ink)
local scale=make("UIScale",{Scale=1},banner)
local heading=label(banner,"Heading",5,30,27) heading.Text="NEW DISCOVERY!"
local nameLabel=label(banner,"CrusherName",36,40,34)
local subLabel=label(banner,"CollectionHint",80,26,20)
local chime=make("Sound",{Name="RollAccent",SoundId="rbxassetid://"..Config.Sounds.LevelUp,Volume=.2},SoundService)
task.spawn(function() pcall(function() Content:PreloadAsync({chime}) end) end)
local pending={} local seen=setmetatable({},{__mode="k"})
local batches={} local finishedBatches={} local discoveryQueue={} local announced={}
local currentDiscovery local discoveryAt=0
local function candidate(model)
	if not seen[model] then pending[model]=os.clock() end
end
Tags:GetInstanceAddedSignal(P.Tag):Connect(candidate)
for _,model in Tags:GetTagged(P.Tag) do candidate(model) end
Net.event("CrusherState").OnClientEvent:Connect(function(state)
	local item=type(state)=="table" and state.discovery
	if type(item)~="table" or not C.typeById(item.type) or announced[item.type] then return end
	announced[item.type]=true
	if #discoveryQueue<#C.Types then table.insert(discoveryQueue,item) end
end)
local function show(model,now)
	local slot=model:GetAttribute("RevealSlot")
	if type(slot)~="number" or slot%1~=0 or not pools[slot] then return end
	local rarity=model:GetAttribute("RevealRarity") local r=C.rarity(rarity) if not r then return end
	local camera=workspace.CurrentCamera
	if not camera or (camera.CFrame.Position-model:GetPivot().Position).Magnitude>100 then return end
	local record=pools[slot] record.model=model record.at=model:GetAttribute("RevealAt") record.rarity=rarity
	local cf,size=model:GetBoundingBox()
	record.anchor.CFrame=CFrame.new(cf.Position+Vector3.new(0,size.Y/2+1,0))
	record.highlight.Adornee=model record.highlight.OutlineColor=r.color
	record.highlight.FillColor=r.color record.highlight.Enabled=true
	record.title.Text=string.upper(rarity)..(if P.profile(rarity).rank>=3 then "!" else "")
	record.title.TextColor3=r.color:Lerp(Color3.new(1,1,1),.2)
	record.sub.Text=if model:GetAttribute("RevealUnowned") then "UNOWNED · BUY TO COLLECT" else "IN YOUR COLLECTION"
	record.board.Enabled=P.profile(rarity).rank>=2
	local key=model:GetAttribute("RevealRoll")
	if type(key)=="string" and not finishedBatches[key] then
		local batch=batches[key]
		if not batch then batch={at=now+.55,profile=P.profile(rarity)} batches[key]=batch
		elseif P.profile(rarity).rank>batch.profile.rank then batch.profile=P.profile(rarity) end
	end
end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
	elapsed+=dt if elapsed<1/30 then return end elapsed=0
	local now=workspace:GetServerTimeNow()
	for model,added in pending do
		local at=model:GetAttribute("RevealAt")
		if os.clock()-added>3 or (type(at)=="number" and not P.fresh(at,now)) then pending[model]=nil seen[model]=true
		elseif model:IsDescendantOf(workspace) and model:GetAttribute("RevealOwner")==me.UserId and at then
			if model:FindFirstChildWhichIsA("BasePart",true) then show(model,now) pending[model]=nil seen[model]=true end
		end
	end
	for _,record in pools do if record.model then
		local age=now-record.at local profile=P.profile(record.rarity)
		local t=math.clamp(age/profile.duration,0,1)
		if not record.model.Parent or t>=1 then
			record.highlight.Enabled=false record.highlight.Adornee=nil record.board.Enabled=false record.model=nil
		else
			record.sub.Text=if record.model:GetAttribute("RevealUnowned") then "UNOWNED · BUY TO COLLECT" else "IN YOUR COLLECTION"
			record.highlight.OutlineTransparency=t record.highlight.FillTransparency=.88+.12*t
			record.board.StudsOffsetWorldSpace=Vector3.new(0,math.sin(t*math.pi)*.28,0)
		end
	end end
	for key,batch in batches do if now>=batch.at then
		if batch.profile.rank>=2 and chime.IsLoaded and not chime.IsPlaying then
			chime.PlaybackSpeed=batch.profile.pitch chime:Play()
		end
		batches[key]=nil
		finishedBatches[key]=now
	end end
	for key,at in finishedBatches do if now-at>5 then finishedBatches[key]=nil end end
	if currentDiscovery and now-discoveryAt>=2.7 then currentDiscovery=nil banner.Visible=false end
	if not currentDiscovery and #discoveryQueue>0 then
		currentDiscovery=table.remove(discoveryQueue,1) discoveryAt=now
		local r=C.rarity(currentDiscovery.rarity)
		nameLabel.Text=C.typeById(currentDiscovery.type).name nameLabel.TextColor3=r.color:Lerp(Color3.new(1,1,1),.15)
		subLabel.Text=currentDiscovery.rarity.." · ADDED TO YOUR INDEX" banner.Visible=true
	end
	if currentDiscovery then local t=math.clamp((now-discoveryAt)/.3,0,1)
		scale.Scale=1-.16*(1-t)^2+.035*math.sin(t*math.pi)
	end
end)
