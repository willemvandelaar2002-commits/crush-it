--!strict
-- Optional, server-authoritative co-op event. Never moves/consumes owned crushers.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Net=require(RS.Shared.Net)
local E=require(RS.Shared.FactoryEventConfig)
local Rules=require(RS.Shared.FactoryEventRules)
local C=require(RS.Shared.CrusherConfig)
local Events={}
local started=false
function Events.start(api)
	if started then return end started=true
	local state=Instance.new("Folder") state.Name="FactoryEventState"
	state:SetAttribute("Enabled",E.Enabled) state:SetAttribute("Phase","Idle") state.Parent=RS
	if not E.Enabled then return end
	local remote=Net.event("FactoryEventState") local action=Net.event("FactoryEventAction")
	local phase="Idle" local since=workspace:GetServerTimeNow() local untilAt=since+E.Interval
	local roundId="" local hp,maxHp=0,0 local roster={} local requestAt={}
	local outcome="" local lastBroadcast=0 local accumulated=0
	local function now() return workspace:GetServerTimeNow() end
	local function count() local n=0 for _ in roster do n+=1 end return n end
	local function publishAttributes()
		state:SetAttribute("RoundId",roundId) state:SetAttribute("PhaseStarted",since)
		state:SetAttribute("PhaseEnds",untilAt) state:SetAttribute("Hp",hp) state:SetAttribute("MaxHp",maxHp)
		state:SetAttribute("Outcome",outcome) state:SetAttribute("Phase",phase)
	end
	local function packet(p)
		local participants={}
		for player,r in roster do
			table.insert(participants,{userId=player.UserId,name=player.DisplayName,origin=r.origin,plotIndex=r.plotIndex,
				points=r.points,grade=r.grade,dominant=r.dominant,count=r.count,power=r.power,slots=r.slots,
				present=r.present==true,pulseUntil=r.pulseUntil or 0})
		end
		table.sort(participants,function(a,b) return a.userId<b.userId end)
		local r=roster[p]
		return {phase=phase,started=since,ends=untilAt,roundId=roundId,hp=hp,maxHp=maxHp,
			outcome=outcome,participants=participants,you=if r then {points=r.points,grade=r.grade,
				count=r.count,active=r.active,hits=r.hits,present=r.present==true,
				pulseReady=r.pulseReady or 0,eligible=Rules.eligible(r),reward=r.reward or 0} else nil}
	end
	local function broadcast()
		publishAttributes()
		for _,p in Players:GetPlayers() do remote:FireClient(p,packet(p)) end
		lastBroadcast=now()
	end
	local function setPhase(name,duration)
		phase=name since=now() untilAt=since+duration broadcast()
	end
	local function ownPlot(p,r)
		local plot=api.eventPlot(p)
		if not plot or plot.index~=r.plotIndex then return false end
		local char=p.Character local root=char and char:FindFirstChild("HumanoidRootPart")
		local humanoid=char and char:FindFirstChildOfClass("Humanoid")
		return root and humanoid and humanoid.Health>0 and Rules.inside(r.origin:PointToObjectSpace(root.Position)) or false
	end
	local function totalPower()
		local n=0 for _,r in roster do n+=r.power end return n
	end
	local function remove(p)
		if not roster[p] then return end
		roster[p]=nil
		if phase=="Active" then hp,maxHp=Rules.resize(hp,maxHp,totalPower()*E.TargetSeconds) end
		if count()==0 and phase~="Idle" and phase~="Announce" and phase~="Recover" then
			outcome="Cancelled" setPhase("Recover",E.Recover)
		else broadcast() end
	end
	local function snapshot(p)
		local plot=api.eventPlot(p) local fleet=api.eventFleet(p)
		if not plot or not fleet or fleet.count==0 then return nil end
		fleet.origin=plot.origin fleet.plotIndex=plot.index fleet.active=0 fleet.hits=0 fleet.nextStrike=0
		return fleet
	end
	local function announce()
		if phase~="Idle" then return false end
		roster={} hp=0 maxHp=0 outcome=""
		roundId=Http:GenerateGUID(false)
		setPhase("Announce",E.Announce) return true
	end
	local function recover(result)
		outcome=result setPhase("Recover",E.Recover)
	end
	local function victory()
		outcome="Victory"
		for p,r in roster do
			local d=api.getData(p)
			if d then
				local granted,amount=Rules.grant(d,roundId,r,C.money)
				if granted then
					r.reward=amount api.sync(p)
					-- The ID ledger and cash are saved together; retry via autosave if storage is down.
					task.spawn(function()
						if not api.save(p) then warn("[FactoryEvent] Reward save deferred to autosave for "..p.UserId) end
					end)
				end
			end
		end
		setPhase("Victory",E.Victory)
	end
	local function tick(dt)
		local t=now()
		if phase=="Active" then
			for p,r in roster do
				r.present=ownPlot(p,r)
				if r.present then
					r.active+=math.min(dt,1) -- lag cannot manufacture participation time
					if t>=r.nextStrike then
						r.nextStrike=since+(math.floor((t-since)/E.Strike)+1)*E.Strike r.hits+=1
						local pulsed=r.pulsePending==true and (r.pulseUntil or 0)>=t
						r.pulsePending=false
						hp=math.max(0,hp-Rules.damage(r.power,pulsed))
					end
				end
			end
			if hp<=0 and maxHp>0 then setPhase("Finale",E.Finale) return end
		end
		if t>=untilAt then
			if phase=="Idle" then announce()
			elseif phase=="Announce" then
				-- Freeze exactly the currently equipped fleet at the assembly boundary.
				for p in roster do roster[p]=snapshot(p) end
				if count()==0 then recover("No participants") else setPhase("Assemble",E.Assemble) end
			elseif phase=="Assemble" then
				maxHp=totalPower()*E.TargetSeconds hp=maxHp
				setPhase("Active",E.Active)
				for _,r in roster do r.nextStrike=since+E.Strike end
			elseif phase=="Active" then recover("Timeout")
			elseif phase=="Finale" then victory()
			elseif phase=="Victory" then setPhase("Recover",E.Recover)
			elseif phase=="Recover" then roster={} hp=0 maxHp=0 setPhase("Idle",E.Interval) end
		end
		if t-lastBroadcast>=E.Broadcast and phase~="Idle" then broadcast() end
	end
	action.OnServerEvent:Connect(function(p,name)
		if type(name)~="string" or #name>12 then return end
		local t=now() if t-(requestAt[p] or -math.huge)<.15 then return end requestAt[p]=t
		if name=="Sync" then remote:FireClient(p,packet(p))
		elseif name=="Join" and phase=="Announce" then
			if roster[p] then return end
			local r=snapshot(p)
			if not r then Net.event("Notice"):FireClient(p,{text="Place at least one crusher in your factory first."}) return end
			roster[p]=r broadcast()
		elseif name=="Leave" then remove(p)
		elseif name=="Pulse" and phase=="Active" then
			local r=roster[p]
			if not r or not ownPlot(p,r) or t<(r.pulseReady or 0) or not Rules.onBeat(t,since) then return end
			r.pulseReady=t+E.PulseCooldown
			r.pulsePending=true
			-- Applies to the next authoritative strike, not to a client-supplied hit.
			r.pulseUntil=t+E.Strike+.25 broadcast()
		end
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
	-- No live client or chat command can start/win/cancel an event.
	if RunService:IsStudio() then
		local dev=Instance.new("BindableFunction") dev.Name="DevFactoryEvent"
		dev.OnInvoke=function(command)
			if command=="Start" then return announce()
			elseif command=="Cancel" then recover("Cancelled") return true
			elseif command=="Win" and phase=="Active" then hp=0 setPhase("Finale",E.Finale) return true
			elseif command=="State" then return packet(nil) end
			return false
		end
		dev.Parent=game:GetService("ServerStorage")
	end
	publishAttributes()
end
return Events
