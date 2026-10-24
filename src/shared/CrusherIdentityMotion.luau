--!strict
-- Local cosmetic budget, shared with disposable verification fixtures.
local M = {MaxActive=4,Distance=105,SelectionInterval=.2,Step=1/30}
function M.nearest(candidates,position)
	local ranked={}
	for model,sequence in candidates do
		if model.Parent and model.Name=="EquippedCrusher" and model:GetAttribute("InventoryId")
			and model:IsDescendantOf(workspace) then
			local distance=(model:GetPivot().Position-position).Magnitude
			if distance<=M.Distance then table.insert(ranked,{model=model,distance=distance,sequence=sequence}) end
		end
	end
	table.sort(ranked,function(a,b)
		return if a.distance==b.distance then a.sequence<b.sequence else a.distance<b.distance
	end)
	local selected={}
	for i=1,math.min(M.MaxActive,#ranked) do selected[ranked[i].model]=true end
	return selected
end
function M.turn(rest,axis,rate,now)
	return rest*CFrame.fromAxisAngle(axis,(now*rate)%(2*math.pi))
end
function M.beat(rest,fit,now)
	return rest*CFrame.new(0,math.sin(now*4.5)*.065*fit,0)*CFrame.Angles(0,0,math.sin(now*4.5)*.035)
end
function M.glow(rest,now)
	return math.clamp(rest+.08+.08*math.sin(now*3),0,1)
end
return M
