
local E=require(shared.FactoryEventConfig)
local ER=require(shared.FactoryEventRules)
local CR=require(shared.CrusherRules)
local C=require(shared.CrusherConfig)
local controllerChecks=0
local function check(ok,message) assert(ok,message) controllerChecks+=1 end
local profiles={} local plots={} local saves=0
local function player(userId,x)
	local p=Instance.new('Player') p.UserId=userId p.DisplayName='Tester'..userId p.Parent=services.Players
	local char=Instance.new('Model') char.Parent=workspace p.Character=char
	local root=Instance.new('Part') root.Name='HumanoidRootPart' root.CFrame=CFrame.new(x,5,0) root.Parent=char
	local hum=Instance.new('Humanoid') hum.Health=100 hum.Parent=char
	table.insert(players,p)
	profiles[p]=CR.migrate({cash=0},function() return 'owned-'..userId end)
	plots[p]={index=userId,origin=CFrame.new(x,0,0)}
	return p,root
end
local a,aroot=player(1,0) local b,broot=player(2,300)
local api={getData=function(p) return profiles[p] end,save=function() saves+=1 return true end,sync=function() end,
	eventPlot=function(p) return plots[p] end,eventFleet=function(p)
		local d=profiles[p] if not d then return nil end
		return ER.snapshot(d,C.bayCapacity(d.crushers.plotLevel),C.rarityOf,function(item) return CR.stats(d,item,{},false) end)
	end}
require(shared.FactoryEvents).start(api)
local dev=services.ServerStorage:FindFirstChild('DevFactoryEvent')
local function state() return dev.OnInvoke('State') end
local function advance(seconds)
	local count=math.ceil(seconds/.2) local dt=seconds/count
	for _=1,count do clock+=dt services.RunService.Heartbeat:Fire(dt) end
end
local function request(p,name) clock+=.16 remotes.FactoryEventAction.OnServerEvent:Fire(p,name) end
check(state().phase=='Idle','starts idle')
check(dev.OnInvoke('Start') and not dev.OnInvoke('Start'),'one announcement only')
request(a,'Join') request(b,'Join') request(a,'Join')
check(#state().participants==2,'duplicate join is idempotent')
request(a,'Damage')
check(state().hp==0,'unknown client action cannot supply damage')
advance(E.Announce+1)
check(state().phase=='Assemble','announcement assembles')
check(#state().participants==2 and state().participants[1].plotIndex==1,'origins/plot IDs replicated')
advance(E.Assemble+1)
check(state().phase=='Active' and state().maxHp>0,'active shield scales to roster')
local originalPoints=state().participants[1].points
profiles[a].crushers.owned[1].level=100
check(state().participants[1].points==originalPoints,'loadout values frozen after assembly')
local hp=state().hp
request(a,'Pulse') request(a,'Pulse')
check(state().hp==hp,'client pulse never directly damages boss')
advance(8)
check(state().hp<hp,'server strikes reduce shared shield')
-- Other plot / out of bounds / dead character do not contribute.
broot.CFrame=CFrame.new(0,5,0)
advance(2)
check(not remotes.FactoryEventState.sent[b].you.present,'another player plot cannot count as your own')
local activeBefore=remotes.FactoryEventState.sent[b].you.active
advance(5)
check(remotes.FactoryEventState.sent[b].you.active==activeBefore,'away time does not qualify')
broot.CFrame=CFrame.new(300,5,0)
advance(3)
check(remotes.FactoryEventState.sent[b].you.present,'returning resumes participation')
local ratio=state().hp/state().maxHp
request(b,'Leave')
check(#state().participants==1 and math.abs(state().hp/state().maxHp-ratio)<1e-7,'leaving preserves shared progress')
request(b,'Join')
check(#state().participants==1,'roster closed after assembly')
advance(28)
check(remotes.FactoryEventState.sent[a].you.eligible,'own-plot strikes and time qualify')
dev.OnInvoke('Win')
check(state().phase=='Finale','shield break triggers shared final blow')
local cash=profiles[a].cash
check(cash==0,'no reward before final blow')
advance(E.Finale+1)
check(state().phase=='Victory' and profiles[a].cash>cash,'final blow commits reward')
check(profiles[b].cash==0,'leaver does not receive victory reward')
check(profiles[a].factoryEvents.wins==1,'one recorded win')
local paid=profiles[a].cash
advance(E.Victory+E.Recover+2)
check(state().phase=='Idle' and #state().participants==0,'returns idle without stale fleet')
check(profiles[a].cash==paid,'recovery cannot duplicate payout')
for _,job in queuedTasks do job.fn(table.unpack(job.args)) end
check(saves==1,'one save attempt for eligible winner')
-- Empty round, explicit cancellation, death, player removal and timeout.
dev.OnInvoke('Start') advance(E.Announce+1)
check(state().phase=='Recover','no participants cancels cleanly')
advance(E.Recover+1) dev.OnInvoke('Start') request(a,'Join')
dev.OnInvoke('Cancel')
check(state().phase=='Recover','cancel from announce cleans up')
advance(E.Recover+1) dev.OnInvoke('Start') request(a,'Join')
advance(E.Announce+E.Assemble+3)
a.Character:FindFirstChildOfClass('Humanoid').Health=0 advance(2)
check(not remotes.FactoryEventState.sent[a].you.present,'dead players cannot contribute')
advance(state().ends-clock+.3)
check(state().phase=='Recover' and state().outcome=='Timeout','unbroken shield times out')
check(profiles[a].cash==paid,'timeout never pays')
advance(E.Recover+1) dev.OnInvoke('Start') request(a,'Join')
advance(E.Announce+E.Assemble+3)
services.Players.PlayerRemoving:Fire(a)
check(state().phase=='Recover','last participant disconnect aborts cleanly')
advance(E.Recover+1)
a.Character:FindFirstChildOfClass('Humanoid').Health=100
dev.OnInvoke('Start') request(a,'Join') advance(E.Announce+E.Assemble+.4)
advance(state().started+1.9-clock)
request(a,'Pulse')
local pulseHp=state().hp local pulsePower=state().participants[1].power
advance(.2)
check(math.abs((pulseHp-state().hp)-ER.damage(pulsePower,true))<1e-6,'overdrive boosts the next server strike')
local afterPulseHp=state().hp local ready=remotes.FactoryEventState.sent[a].you.pulseReady
request(a,'Pulse')
check(remotes.FactoryEventState.sent[a].you.pulseReady==ready,'cooldown rejects a repeated pulse')
advance(2)
check(math.abs((afterPulseHp-state().hp)-ER.damage(pulsePower,false))<1e-6,'one pulse cannot boost two strikes')
dev.OnInvoke('Cancel')
check(#warnings==0,'controller raised no runtime warnings')
print('PASS|Actual server controller|'..controllerChecks)
