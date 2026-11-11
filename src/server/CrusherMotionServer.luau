--!strict
-- 11 Nov (audit 8): one small "strike" event per crusher strike instead of tweening the
-- moving parts on the server. Batched like CrusherFeedbackServer (every BatchInterval)
-- and only sent to players near that factory (Shared.CrusherMotion.SendDistance).
-- The clients play the motion (client/CrusherMotion).
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Shared.CrusherFeedback)
local Motion=require(RS.Shared.CrusherMotion)
local Net=require(RS.Shared.Net)
local S={} local queue={} local lastFlush=0
local remote=Net.event(Motion.Remote)
-- v: the crusher visual (model, base); impactAt: server time of contact; y: the ram's
-- contact height (press rams only)
function S.strike(v,event,impactAt,y)
	if #queue>=F.MaxServerQueue then return end
	-- f: how flat the toy is after this strike (the clients squash their own toy, 8b)
	table.insert(queue,{model=v.model,position=v.base.Position,t=impactAt,c=event.cycle,k=if event.completed then 1 else nil,y=y,f=event.fraction})
end
function S.flush(now)
	if now-lastFlush<F.BatchInterval then return end lastFlush=now
	if #queue==0 then return end
	local list=queue queue={}
	local reach=Motion.SendDistance*Motion.SendDistance
	for _,player in Players:GetPlayers() do
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local out={}
			for _,e in list do
				local d=e.position-root.Position
				if e.model.Parent and d:Dot(d)<=reach then table.insert(out,{m=e.model,t=e.t,c=e.c,k=e.k,y=e.y,f=e.f}) end
			end
			if #out>0 then remote:FireClient(player,out) end
		end
	end
end
return S
