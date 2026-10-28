--!strict
-- Win reward reels (28 Oct, after the reference): one horizontal strip of
-- prize tiles per reel, scrolling fast and slowing onto the red centre line.
-- The SERVER already picked and granted every result (FactoryEventRules.grant);
-- this only shows it. Filler tiles are random by the same weights (visual).
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local E=require(RS.Shared.FactoryEventConfig)
local Rules=require(RS.Shared.FactoryEventRules)
local Style=require(RS.Shared.Kit.Style)
local Icons=require(RS.Shared.Icons)
local Format=require(RS.Shared.Format)
local Boosts=require(RS.Shared.BoostConfig)

local TILE,GAP=78,8
local STEP=TILE+GAP
local INK=Style.Colors.Ink
-- look per prize kind/id (styling only; amounts come from config/server)
local LOOK={
	Cash={color=Color3.fromRGB(70,200,70),icon="Cash"},
	BigCash={color=Color3.fromRGB(255,200,40),icon="Cash"},
	CashBoost={color=Color3.fromRGB(230,70,60),icon="DoubleCash"},
	LuckBoost={color=Color3.fromRGB(60,190,90),icon="Lucky"},
	Legendary={color=Color3.fromRGB(255,170,30),icon="Press"},
	Mythic={color=Color3.fromRGB(255,70,190),icon="Press"},
}
local function look(id) return LOOK[id] or {color=Color3.fromRGB(120,120,140),icon="Trophy"} end

local Reels={}
Reels.__index=Reels

local function round(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function edge(p,th,col) local s=Instance.new("UIStroke") s.Thickness=th s.Color=col or INK s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function text(parent,value,pos,size,z)
	local t=Instance.new("TextLabel") t.Text=value t.BackgroundTransparency=1 t.Position=pos t.Size=size t.TextScaled=true t.ZIndex=z t.Parent=parent
	Style.text(t,2) return t
end

function Reels.new(gui)
	local self=setmetatable({},Reels)
	local root=Instance.new("Frame") root.Name="RewardReels" root.AnchorPoint=Vector2.new(.5,0) root.Position=UDim2.new(.5,0,0,118)
	root.Size=UDim2.fromOffset(900,0) root.AutomaticSize=Enum.AutomaticSize.Y root.BackgroundTransparency=1 root.Visible=false root.ZIndex=10 root.Parent=gui
	local list=Instance.new("UIListLayout") list.Padding=UDim.new(0,8) list.HorizontalAlignment=Enum.HorizontalAlignment.Center list.SortOrder=Enum.SortOrder.LayoutOrder list.Parent=root
	local title=text(root,"BEAR DEFEATED! YOUR REWARDS",UDim2.new(),UDim2.fromOffset(520,36),12) title.LayoutOrder=0
	title.TextColor3=Color3.fromRGB(255,220,70)
	local summary=text(root,"",UDim2.new(),UDim2.fromOffset(760,34),12) summary.LayoutOrder=99
	summary.BackgroundColor3=INK summary.BackgroundTransparency=.25 round(summary,12) summary.Visible=false
	do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,4) pad.PaddingBottom=UDim.new(0,4) pad.PaddingLeft=UDim.new(0,14) pad.PaddingRight=UDim.new(0,14) pad.Parent=summary end
	self.root=root self.summary=summary self.rows={} self.round=nil self.conn=nil
	return self
end

function Reels:tileText(id,values)
	local prize=Rules.prize(id) :: any
	if not prize then return "?" end
	if prize.kind=="cash" then return if values and values[id] then Format.cash(values[id]) else "CASH" end
	if prize.kind=="boost" then return prize.minutes.."m" end
	return string.upper(prize.rarity)
end

function Reels:tile(strip,i,id,values,odds)
	local L=look(id)
	local f=Instance.new("Frame") f.Name="Tile"..i f.Position=UDim2.fromOffset((i-1)*STEP,4) f.Size=UDim2.fromOffset(TILE,TILE)
	f.BackgroundColor3=L.color f.ZIndex=12 f.Parent=strip round(f,10) edge(f,3)
	local g=Instance.new("UIGradient") g.Rotation=90 g.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(150,150,150)) g.Parent=f
	local icon=Instance.new("ImageLabel") icon.Image=(Icons::any)[L.icon] or Icons.Trophy icon.BackgroundTransparency=1
	icon.AnchorPoint=Vector2.new(.5,.5) icon.Position=UDim2.fromScale(.5,.47) icon.Size=UDim2.fromScale(.62,.62) icon.ZIndex=13 icon.Parent=f
	text(f,self:tileText(id,values),UDim2.new(0,3,0,2),UDim2.new(1,-6,0,20),14)
	text(f,string.format("%g%%",odds[id] or 0),UDim2.new(0,3,1,-22),UDim2.new(1,-6,0,20),14)
	return f
end

function Reels:clear()
	if self.conn then self.conn:Disconnect() self.conn=nil end
	for _,r in self.rows do r.frame:Destroy() end
	self.rows={} self.summary.Visible=false self.root.Visible=false self.round=nil
end

-- prizes: server results; values: cash amounts per cash prize id
-- onTick(reelIndex) as a tile passes the line, onLand(reelIndex, won), onDone()
function Reels:play(roundId,prizes,values,hooks)
	self:clear()
	self.round=roundId
	local odds=Rules.odds()
	local ids={} local weights={}
	for _,p in E.Reels.Prizes do table.insert(ids,p.id) table.insert(weights,p.weight) end
	local total=0 for _,w in weights do total+=w end
	local rng=Random.new()
	local function filler() local x=rng:NextNumber()*total for i,w in weights do x-=w if x<0 then return ids[i] end end return ids[#ids] end
	local target=E.Reels.Tiles-5 -- winner sits a few tiles before the end of the strip
	for i,won in prizes do
		local frame=Instance.new("Frame") frame.Name="Reel"..i frame.LayoutOrder=i frame.Size=UDim2.fromOffset(900,TILE+8)
		frame.BackgroundColor3=Color3.fromRGB(70,30,120) frame.ClipsDescendants=true frame.ZIndex=11 frame.Parent=self.root
		round(frame,12) edge(frame,4)
		local strip=Instance.new("Frame") strip.Name="Strip" strip.BackgroundTransparency=1 strip.Size=UDim2.fromOffset(E.Reels.Tiles*STEP,TILE+8) strip.ZIndex=12 strip.Parent=frame
		for t=1,E.Reels.Tiles do self:tile(strip,t,if t==target then won.id else filler(),values,odds) end
		local line=Instance.new("Frame") line.Name="Line" line.AnchorPoint=Vector2.new(.5,0) line.Position=UDim2.fromScale(.5,0)
		line.Size=UDim2.new(0,4,1,0) line.BackgroundColor3=Color3.fromRGB(255,40,40) line.BorderSizePixel=0 line.ZIndex=16 line.Parent=frame
		-- strip x so that the centre of tile n sits on the line (+ a random spot inside the tile)
		local function xFor(n,jitter) return 450-((n-1)*STEP+TILE/2+jitter) end
		local endX=xFor(target,rng:NextNumber(-TILE*.35,TILE*.35))
		local startX=xFor(3,0)
		strip.Position=UDim2.fromOffset(startX,0)
		table.insert(self.rows,{frame=frame,strip=strip,startX=startX,endX=endX,
			duration=E.Reels.Spin+(i-1)*E.Reels.Stagger,landed=false,lastTile=3,won=won,winTile=strip:FindFirstChild("Tile"..target)})
	end
	self.root.Visible=true
	local began=os.clock()
	self.conn=Run.RenderStepped:Connect(function()
		local t=os.clock()-began local done=true
		for i,r in self.rows do
			local a=math.clamp(t/r.duration,0,1)
			local e=1-(1-a)^4 -- fast start, long slow-down
			local x=r.startX+(r.endX-r.startX)*e
			r.strip.Position=UDim2.fromOffset(x,0)
			local tileNow=math.floor((450-x)/STEP)+1
			if tileNow~=r.lastTile then r.lastTile=tileNow if hooks.onTick and not r.landed then hooks.onTick(i) end end
			if a>=1 and not r.landed then
				r.landed=true
				if r.winTile then
					local s=r.winTile:FindFirstChildOfClass("UIStroke") if s then s.Color=Color3.fromRGB(255,255,255) s.Thickness=5 end
					r.winTile.Size=UDim2.fromOffset(TILE+6,TILE+6) r.winTile.Position=r.winTile.Position-UDim2.fromOffset(3,4)
				end
				if hooks.onLand then hooks.onLand(i,r.won) end
			end
			if not r.landed then done=false end
		end
		if done then
			if self.conn then self.conn:Disconnect() self.conn=nil end
			self.summary.Text=self:describe(prizes) self.summary.Visible=true
			if hooks.onDone then hooks.onDone() end
		end
	end)
end

function Reels:describe(prizes)
	local parts={}
	for _,won in prizes do
		if won.kind=="cash" then table.insert(parts,Format.cash(won.cash or 0)..(if won.fallback then " (inventory full)" else ""))
		elseif won.kind=="boost" then
			local b=Boosts.find(won.boost) local name=if b then b.title else tostring(won.boost)
			table.insert(parts,name.." "..tostring(won.minutes).."m")
		elseif won.kind=="crusher" then table.insert(parts,(won.rarity or "").." "..(won.name or "crusher")) end
	end
	return "YOU GOT: "..table.concat(parts," + ").."!"
end

return Reels
