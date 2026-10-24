--!strict
-- Batched, proximity-filtered cosmetics over the existing Hit RemoteEvent.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tags=game:GetService("CollectionService")
local F=require(RS.Shared.CrusherFeedback)
local Net=require(RS.Shared.Net)
local S={} local queue={} local lastFlush=0
function S.track(v,typeId)
	v.model:SetAttribute("FeedbackPosition",v.base.Position)
	v.model:SetAttribute("FeedbackType",typeId)
	Tags:AddTag(v.model,F.Tag)
end
function S.strike(v,event,before)
	local timing=F.timing(event.cycle,v.special~=nil)
	v.feedbackSequence=(v.feedbackSequence or 0)+1
	if #queue<F.MaxServerQueue then table.insert(queue,{
		model=v.model,input=v.input,base=v.base,position=v.base.Position,
		impactAt=workspace:GetServerTimeNow()+timing.hit,sequence=v.feedbackSequence,
		fraction=event.fraction,before=before,completed=event.completed,typeId=v.model:GetAttribute("FeedbackType"),
	}) end
	return timing
end
function S.flush(now)
	if now-lastFlush<F.BatchInterval then return end lastFlush=now
	if #queue==0 then return end
	local valid={} local serverNow=workspace:GetServerTimeNow()
	for _,event in queue do if event.model.Parent and F.fresh(event.impactAt,serverNow) then table.insert(valid,event) end end
	queue={}
	for _,player in Players:GetPlayers() do
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local events=F.nearest(valid,root.Position,F.MaxBatch,F.InterestDistance)
			if #events>0 then Net.event("Hit"):FireClient(player,{crusherFeedback=true,events=events}) end
		end
	end
end
return S
