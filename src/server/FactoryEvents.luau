--!strict
-- Server-authoritative co-op event. Never moves/consumes owned crushers.
-- 28 Oct: everyone with a loaded plot takes part automatically (no Join/Leave),
-- including players who arrive mid-round. On top of the automatic strikes:
--   * event cores: picked up on your own plot (one at a time), loaded into the
--     port of your super crusher -> the next strike hits x Cores.Multiplier, or
--     x CriticalMultiplier while your port glows gold (server-timed window).
--   * bear paw slam: a danger circle under one present player (fairly rotated,
--     capped), resolved on the server at impact time from the player's real
--     position. Hit = held core dropped + a short slow-down. Nothing else.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Net=require(RS.Shared.Net)
local E=require(RS.Shared.FactoryEventConfig)
local Rules=require(RS.Shared.FactoryEventRules)
local C=require(RS.Shared.CrusherConfig)
local Config=require(RS.Shared.Config)
local Events={}
local started=false
local rng=Random.new()
function Events.start(api)
	if started then return end started=true
	local state=Instance.new("Folder") state.Name="FactoryEventState"
	state:SetAttribute("Enabled",E.Enabled) state:SetAttribute("Phase","Idle") state.Parent=RS
	if not E.Enabled then return end
	local remote=Net.event("FactoryEventState") local action=Net.event("FactoryEventAction")
	local notice=Net.event("Notice")
	local phase="Idle" local since=workspace:GetServerTimeNow() local untilAt=E.nextStart(since)
	local variant=E.variantAt(untilAt) -- which version (E.Variants) the coming/running round is
	local roundId="" local hp,maxHp=0,0 local roster={} local requestAt={}
	local outcome="" local lastBroadcast=0 local accumulated=0
	local hazards={} local nextSlam=0 local hazardId=0
	local world=Instance.new("Folder") world.Name="FactoryEventWorld" world.Parent=workspace
	local function now() return workspace:GetServerTimeNow() end
	local function count() local n=0 for _ in roster do n+=1 end return n end
	local function publishAttributes()
		state:SetAttribute("RoundId",roundId) state:SetAttribute("PhaseStarted",since)
		state:SetAttribute("PhaseEnds",untilAt) state:SetAttribute("Hp",hp) state:SetAttribute("MaxHp",maxHp)
		state:SetAttribute("Outcome",outcome) state:SetAttribute("Phase",phase) state:SetAttribute("Variant",variant)
	end
	local function packet(p)
		local participants={}
		for player,r in roster do
			if r.pending then continue end
			table.insert(participants,{userId=player.UserId,name=player.DisplayName,origin=r.origin,plotIndex=r.plotIndex,
				points=r.points,grade=r.grade,dominant=r.dominant,count=r.count,power=r.power,slots=r.slots,
				present=r.present==true,pulseUntil=r.pulseUntil or 0,critUntil=r.critUntil or 0,
				loaded=r.boost or 0,fallback=r.fallback==true,dealt=r.dealt or 0})
		end
		table.sort(participants,function(a,b) return a.userId<b.userId end)
		local list={} for _,h in hazards do table.insert(list,{id=h.id,userId=h.userId,position=h.position,warnAt=h.warnAt,at=h.at,result=h.result}) end
		local r=roster[p]
		return {phase=phase,started=since,ends=untilAt,roundId=roundId,hp=hp,maxHp=maxHp,variant=variant,
			outcome=outcome,participants=participants,hazards=list,
			you=if r and not r.pending then {points=r.points,grade=r.grade,
				count=r.count,active=r.active,hits=r.hits,present=r.present==true,carrying=r.carrying,
				critUntil=r.critUntil or 0,loaded=r.boost or 0,fallback=r.fallback==true,
				eligible=Rules.eligible(r),reward=r.reward or 0,prizes=r.prizes,values=r.values,rank=r.rank} else nil}
	end
	local function broadcast()
		publishAttributes()
		for _,p in Players:GetPlayers() do remote:FireClient(p,packet(p)) end
		lastBroadcast=now()
	end
	local function setPhase(name,duration)
		phase=name since=now() untilAt=since+duration broadcast()
	end
	local function rootOf(p)
		local char=p.Character local root=char and char:FindFirstChild("HumanoidRootPart")
		local humanoid=char and char:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health>0 then return root,humanoid end
		return nil,nil
	end
	local function ownPlot(p,r)
		local plot=api.eventPlot(p)
		if not plot or plot.index~=r.plotIndex then return false end
		local root=rootOf(p)
		return root~=nil and Rules.inside(r.origin:PointToObjectSpace(root.Position))
	end
	local function totalPower()
		local n=0 for _,r in roster do if not r.pending then n+=r.power end end return n
	end
	-- Event cores (world parts, visible to everyone; only the plot owner can use them)
	local function dropCarry(p,r)
		r.carrying=nil
		local char=p.Character local held=char and char:FindFirstChild("EventCoreCarry")
		if held then held:Destroy() end
	end
	local function clearWorld()
		world:ClearAllChildren()
		for p,r in roster do if not r.pending then dropCarry(p,r) end end
		hazards={}
	end
	local function corePart(parent,cf,size)
		local Rig=RS.Shared:FindFirstChild("FactoryBearRig")
		local library=RS:FindFirstChild("FactoryEventMeshes")
		local look=E.variant(variant)
		-- Halloween: a glowing ghost candy (CandySoul) instead of a reactor core
		local candy=look.pickup and library and library:FindFirstChild(look.pickup)
		if candy and candy:IsA("Model") then
			local m=candy:Clone() m.Name="Core"
			for _,part in m:GetDescendants() do if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false end end
			local _,box=m:GetBoundingBox()
			m:ScaleTo(m:GetScale()*size*1.2/math.max(box.X,box.Y,box.Z)) m:PivotTo(cf) m.Parent=parent
			return m
		end
		local template=library and library:FindFirstChild(look.boss)
		if Rig and template and template:GetAttribute("FactoryBearReady")==true then
			local ok,m=pcall(function() return require(Rig).core(template,cf,size) end)
			if ok and m then m.Parent=parent return m end
		end
		local ball=Instance.new("Part") ball.Name="Core" ball.Shape=Enum.PartType.Ball ball.Size=Vector3.one*size
		ball.Material=Enum.Material.Neon ball.Color=Color3.fromRGB(174,77,255) ball.CFrame=cf
		ball.Anchored=true ball.CanCollide=false ball.CanTouch=false ball.CanQuery=false ball.Parent=parent
		return ball
	end
	local spawnCore
	local function prompt(parent,text,object,owner)
		local pr=Instance.new("ProximityPrompt") pr.ActionText=text pr.ObjectText=object
		pr.KeyboardKeyCode=Enum.KeyCode.E pr.HoldDuration=0 pr.RequiresLineOfSight=false
		pr.MaxActivationDistance=E.Cores.PromptDistance pr:SetAttribute("OwnerUserId",owner) pr.Parent=parent
		return pr
	end
	spawnCore=function(p,r)
		if phase~="Active" or roster[p]~=r then return end
		local free={}
		for i,spot in E.Cores.Spots do if not r.coreAt[i] then table.insert(free,i) end end
		if #free==0 or r.coreCount>=E.Cores.Max then return end
		local i=free[rng:NextInteger(1,#free)]
		local holder=Instance.new("Model") holder.Name="EventCorePickup" holder:SetAttribute("OwnerUserId",p.UserId) holder.Parent=world
		local cf=r.origin*CFrame.new(E.Cores.Spots[i])*CFrame.new(0,1.6,0)
		corePart(holder,cf,4)
		local grab=Instance.new("Part") grab.Name="Grab" grab.Size=Vector3.new(3,3,3) grab.CFrame=cf grab.Transparency=1
		grab.Anchored=true grab.CanCollide=false grab.CanTouch=false grab.CanQuery=false grab.Parent=holder
		local light=Instance.new("PointLight") light.Color=E.variant(variant).accent light.Range=10 light.Brightness=1.4 light.Parent=grab
		local tag=Instance.new("BillboardGui") tag.Name="CoreTag" tag.Size=UDim2.fromOffset(110,34) tag.StudsOffset=Vector3.new(0,3.6,0)
		tag.AlwaysOnTop=true tag.MaxDistance=120 tag.Parent=grab
		local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text=if E.variant(variant).pickup then "CANDY" else "CORE"
		text.TextScaled=true text.Font=Enum.Font.FredokaOne text.TextColor3=Color3.fromRGB(230,180,255) text.Parent=tag
		local stroke=Instance.new("UIStroke") stroke.Thickness=2.5 stroke.Color=Color3.fromRGB(19,23,42) stroke.Parent=text
		r.coreAt[i]=holder r.coreCount+=1
		local pr=prompt(grab,"Pick up",if E.variant(variant).pickup then "Candy soul" else "Event core",p.UserId)
		pr.Triggered:Connect(function(who)
			if who~=p or roster[p]~=r or phase~="Active" or r.carrying or not holder.Parent then return end
			if not ownPlot(p,r) then return end
			holder:Destroy() r.coreAt[i]=nil r.coreCount-=1
			r.carrying="core"
			local root=rootOf(p)
			if root then
				local ball=corePart(p.Character,root.CFrame*CFrame.new(0,4,-.6),3)
				ball.Name="EventCoreCarry"
				for _,part in (if ball:IsA("BasePart") then {ball} else ball:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored=false part.Massless=true
						local weld=Instance.new("WeldConstraint") weld.Part0=root weld.Part1=part weld.Parent=part
					end
				end
			end
			task.delay(E.Cores.Respawn,function() spawnCore(p,r) end)
			broadcast()
		end)
	end
	local function buildPort(p,r)
		local port=Instance.new("Part") port.Name="EventCorePort" port.Size=Vector3.new(6,3,2)
		port.CFrame=r.origin*CFrame.new(E.Cores.Port)*CFrame.new(0,1.5,0) port.Transparency=1
		port.Anchored=true port.CanCollide=false port.CanTouch=false port.CanQuery=false
		port:SetAttribute("OwnerUserId",p.UserId) port.Parent=world
		local pr=prompt(port,"Load core","Super crusher",p.UserId)
		pr.MaxActivationDistance=12
		pr.Triggered:Connect(function(who)
			if who~=p or roster[p]~=r or phase~="Active" or r.carrying~="core" then return end
			if not ownPlot(p,r) then return end
			local t=now()
			local critical=t<=(r.critUntil or 0)
			dropCarry(p,r)
			r.boost=math.max(r.boost or 0,if critical then E.Cores.CriticalMultiplier else E.Cores.Multiplier)
			r.loads+=1
			if critical then r.critUntil=0 r.nextCrit=t+rng:NextNumber(E.Cores.CriticalEvery[1],E.Cores.CriticalEvery[2]) end
			local word=if E.variant(variant).pickup then "CANDY" else "CORE"
			notice:FireClient(p,{text=if critical then "CRITICAL "..word.."! x"..E.Cores.CriticalMultiplier.." hit" else (if word=="CANDY" then "Candy" else "Core").." loaded! x"..E.Cores.Multiplier.." hit"})
			broadcast()
		end)
		r.port=port
	end
	local function startWork(p,r)
		r.coreAt={} r.coreCount=0 r.loads=0
		buildPort(p,r)
		for _=1,E.Cores.Max do spawnCore(p,r) end
		r.nextCrit=now()+rng:NextNumber(6,E.Cores.CriticalEvery[1])
	end
	local function snapshot(p)
		local plot=api.eventPlot(p) local fleet=api.eventFleet(p)
		if not plot or not fleet then return nil end
		if fleet.count==0 then
			-- no placed crusher: an event-only stand-in machine (no inventory change)
			fleet.power=E.FallbackPower fleet.grade=1 fleet.dominant="Common" fleet.fallback=true
		end
		fleet.origin=plot.origin fleet.plotIndex=plot.index fleet.active=0 fleet.hits=0 fleet.nextStrike=0
		return fleet
	end
	local function remove(p)
		local r=roster[p] if not r then return end
		if not r.pending then
			if r.port then r.port:Destroy() end
			for _,core in r.coreAt or {} do core:Destroy() end
			dropCarry(p,r)
		end
		roster[p]=nil
		for i=#hazards,1,-1 do if hazards[i].userId==p.UserId then table.remove(hazards,i) end end
		if phase=="Active" then hp,maxHp=Rules.resize(hp,maxHp,totalPower()*E.TargetSeconds) end
		if count()==0 and phase~="Idle" and phase~="Announce" and phase~="Recover" then
			outcome="Cancelled" clearWorld() setPhase("Recover",E.Recover)
		else broadcast() end
	end
	-- Automatic entry: during Announce everyone is listed (pending); the fleet
	-- is frozen at Assemble. Arrivals later get their snapshot at once; in
	-- Active the shield keeps its percentage when its maximum grows.
	local function enroll(p)
		if roster[p] or not api.getData(p) or not api.eventPlot(p) then return end
		if phase=="Announce" then roster[p]={pending=true} broadcast() return end
		if phase~="Assemble" and phase~="Active" then return end
		local r=snapshot(p) if not r then return end
		roster[p]=r
		if phase=="Active" then
			hp,maxHp=Rules.resize(hp,maxHp,totalPower()*E.TargetSeconds)
			r.nextStrike=since+(math.floor((now()-since)/E.Strike)+1)*E.Strike
			startWork(p,r)
		end
		broadcast()
	end
	local function announce(forced)
		if phase~="Idle" then return false end
		variant=if E.Variants[forced or ""] then forced else E.variantAt(now()+1)
		roster={} hp=0 maxHp=0 outcome="" hazards={}
		roundId=Http:GenerateGUID(false)
		setPhase("Announce",E.Announce)
		for _,p in Players:GetPlayers() do enroll(p) end
		return true
	end
	local function recover(result)
		outcome=result clearWorld() setPhase("Recover",E.Recover)
	end
	local function victory()
		outcome="Victory"
		-- damage ranking decides the number of reward reels
		local ranked={}
		for p,r in roster do if not r.pending then table.insert(ranked,{p=p,dealt=r.dealt or 0}) end end
		table.sort(ranked,function(a,b) if a.dealt~=b.dealt then return a.dealt>b.dealt end return a.p.UserId<b.p.UserId end)
		for i,e in ranked do roster[e.p].rank=i end
		local Boosts=require(script.Parent.Boosts)
		for p,r in roster do
			local d=api.getData(p)
			if d and not r.pending then
				local granted,result=Rules.grant(d,roundId,r,C.money,{
					random=function() return rng:NextNumber() end,
					giveCrusher=function(rarity,typeId) return api.giveCrusher(p,rarity,typeId) end,
					addBoost=function(id,minutes) return Boosts.add(p,id,minutes) end,
				})
				if granted then
					r.reward=result.cash r.prizes=result.prizes r.values=result.values api.sync(p)
					-- The ID ledger and cash are saved together; retry via autosave if storage is down.
					task.spawn(function()
						if not api.save(p) then warn("[FactoryEvent] Reward save deferred to autosave for "..p.UserId) end
					end)
				end
			end
		end
		setPhase("Victory",E.Victory)
	end
	local function slams(t)
		-- resolve due slams on the server, from the target's actual position
		for _,h in hazards do
			if not h.result and t>=h.at then
				local p=Players:GetPlayerByUserId(h.userId) local r=p and roster[p]
				local root,humanoid=nil,nil
				if p then root,humanoid=rootOf(p) end
				local flat=if root then Vector3.new(root.Position.X-h.position.X,0,root.Position.Z-h.position.Z).Magnitude else math.huge
				if p and r and root and flat<=E.Slam.Radius then
					h.result="hit"
					if r.carrying then dropCarry(p,r) end
					humanoid.WalkSpeed=E.Slam.StaggerSpeed
					task.delay(E.Slam.Stagger,function() if humanoid.Parent then humanoid.WalkSpeed=Config.PlayerWalkSpeed end end)
					notice:FireClient(p,{text="SMASHED! Watch out for the red circle."})
				else
					h.result="dodged"
					if p then notice:FireClient(p,{text="DODGED!"}) end
				end
				h.doneAt=t
			end
		end
		for i=#hazards,1,-1 do if hazards[i].doneAt and t-hazards[i].doneAt>1.5 then table.remove(hazards,i) end end
		if t<nextSlam then return end
		nextSlam=t+rng:NextNumber(E.Slam.Every[1],E.Slam.Every[2])
		local live=0 for _,h in hazards do if not h.result then live+=1 end end
		if live>=E.Slam.MaxActive then return end
		-- fair rotation: the present player who was targeted longest ago
		local pick,pickAt=nil,math.huge
		for p,r in roster do
			if not r.pending and r.present then
				local busy=false for _,h in hazards do if h.userId==p.UserId and not h.result then busy=true end end
				if not busy and (r.lastSlam or 0)<pickAt then pick,pickAt=p,(r.lastSlam or 0) end
			end
		end
		if not pick then return end
		local root=rootOf(pick) if not root then return end
		roster[pick].lastSlam=t
		hazardId+=1
		table.insert(hazards,{id=hazardId,userId=pick.UserId,position=root.Position-Vector3.new(0,3,0),warnAt=t,at=t+E.Slam.Warn})
		broadcast()
	end
	local function tick(dt)
		local t=now()
		if phase=="Active" then
			for p,r in roster do
				if r.pending then continue end
				r.present=ownPlot(p,r)
				if not r.present and r.carrying then dropCarry(p,r) end
				if r.nextCrit and t>=r.nextCrit and (r.critUntil or 0)<t then
					r.critUntil=t+E.Cores.CriticalSeconds
					r.nextCrit=t+E.Cores.CriticalSeconds+rng:NextNumber(E.Cores.CriticalEvery[1],E.Cores.CriticalEvery[2])
				end
				if r.present then
					r.active+=math.min(dt,1) -- lag cannot manufacture participation time
					if t>=r.nextStrike then
						r.nextStrike=since+(math.floor((t-since)/E.Strike)+1)*E.Strike r.hits+=1
						local mult=math.max(1,r.boost or 0) r.boost=0
						if mult>1 then r.pulseUntil=t+E.Strike+.25 end
						local dealt=math.min(hp,Rules.damage(r.power,false)*mult)
						hp-=dealt r.dealt=(r.dealt or 0)+dealt -- for the boss bar's top damage list
					end
				end
			end
			slams(t)
			if hp<=0 and maxHp>0 then clearWorld() setPhase("Finale",E.Finale) return end
		end
		if t>=untilAt then
			if phase=="Idle" then announce()
			elseif phase=="Announce" then
				-- Freeze exactly the currently equipped fleet at the assembly boundary.
				for p in roster do roster[p]=snapshot(p) end
				for _,p in Players:GetPlayers() do if not roster[p] then roster[p]=snapshot(p) end end
				if count()==0 then recover("No players") else setPhase("Assemble",E.Assemble) end
			elseif phase=="Assemble" then
				maxHp=totalPower()*E.TargetSeconds hp=maxHp
				setPhase("Active",E.Active)
				nextSlam=since+E.Slam.Every[1]*.6
				for p,r in roster do r.nextStrike=since+E.Strike startWork(p,r) end
			elseif phase=="Active" then recover("Timeout")
			elseif phase=="Finale" then victory()
			elseif phase=="Victory" then setPhase("Recover",E.Recover)
			elseif phase=="Recover" then
				roster={} hp=0 maxHp=0
				local nextAt=E.nextStart(now()) variant=E.variantAt(nextAt)
				setPhase("Idle",nextAt-now())
			end
		end
		if t-lastBroadcast>=E.Broadcast and phase~="Idle" then broadcast() end
	end
	action.OnServerEvent:Connect(function(p,name)
		if type(name)~="string" or #name>12 then return end
		local t=now() if t-(requestAt[p] or -math.huge)<.15 then return end requestAt[p]=t
		if name=="Sync" then enroll(p) remote:FireClient(p,packet(p)) end
	end)
	-- arrivals (profile and plot ready) join the running round
	Players.PlayerAdded:Connect(function(p)
		task.spawn(function()
			if api.whenLoaded(p) then
				for _=1,40 do if api.eventPlot(p) or not p.Parent then break end task.wait(.25) end
				if p.Parent then enroll(p) end
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(p) requestAt[p]=nil remove(p) end)
	RunService.Heartbeat:Connect(function(dt)
		accumulated+=dt if accumulated<E.Tick then return end local step=accumulated accumulated=0
		local ok,err=xpcall(function() tick(step) end,debug.traceback)
		if not ok then
			warn("[FactoryEvent] Aborted safely: "..tostring(err))
			recover("Interrupted")
		end
	end)
	-- No live client can start/win/cancel an event.
	if RunService:IsStudio() then
		local dev=Instance.new("BindableFunction") dev.Name="DevFactoryEvent"
		dev.OnInvoke=function(command,arg)
			if command=="Start" then return announce(arg) -- arg: "Bear" or "Halloween" (default: the scheduled one)
			elseif command=="Cancel" then recover("Cancelled") return true
			elseif command=="Win" and phase=="Active" then
				-- Studio test win: count everyone taking part as qualified, so the
				-- reward reels show even when /event win comes right after the start
				for _,r in roster do if not r.pending then r.active=math.max(r.active,E.MinimumActive) r.hits=math.max(r.hits,E.MinimumHits) end end
				hp=0 clearWorld() setPhase("Finale",E.Finale) return true
			elseif command=="Slam" and phase=="Active" then nextSlam=0 return true
			elseif command=="Critical" and phase=="Active" then for _,r in roster do if not r.pending then r.nextCrit=0 end end return true
			elseif command=="State" then return packet(nil) end
			return false
		end
		dev.Parent=game:GetService("ServerStorage")
	end
	publishAttributes()
end
return Events
