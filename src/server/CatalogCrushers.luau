--!strict
-- Compatible catalogue API. All thirty-five code-built shapes share the
-- authored identity builder; five imported specials still use SpecialCrushers.
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Identity=require(RS.Shared.CrusherIdentityRig)
local B={}
local V=Vector3.new local F=CFrame.new local A=CFrame.Angles

function B.build(origin,typeId)
	return Identity.build(origin,typeId)
end

-- Kept separate from playback so bounds and endpoint checks can sample the
-- exact transform without waiting on a tween or touching live world models.
function B.target(v,g,entry,amount)
	if g.pivot then
		return g.pivot*A(g.angle*amount,0,0)*g.pivot:Inverse()*entry.cf
	end
	return F(v.origin:VectorToWorldSpace(g.axis)*g.stroke*amount)*entry.cf
end

function B.rodTarget(v,g,entry,amount)
	local travel=g.stroke*amount
	return F(-v.origin.UpVector*travel/2)*entry.cf, V(entry.size.X+travel,entry.size.Y,entry.size.Z)
end

function B.strike(v,event)
	v.strikes+=1 local duration=math.min(.6,event.cycle*.7)
	for i,g in v.groups do
		if #v.groups>1 and not event.completed and i~=((v.strikes-1)%#v.groups+1) then continue end
		for _,entry in g.rest do
			local p=entry.part local rest=entry.cf
			Tween:Create(p,TweenInfo.new(duration*.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=B.target(v,g,entry,1)}):Play()
			task.delay(duration*.48,function()
				if v.model.Parent and p.Parent then Tween:Create(p,TweenInfo.new(duration*.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=rest}):Play() end
			end)
		end
		for _,entry in g.rods do
			local p=entry.part local down,size=B.rodTarget(v,g,entry,1)
			Tween:Create(p,TweenInfo.new(duration*.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=down,Size=size}):Play()
			task.delay(duration*.48,function()
				if v.model.Parent and p.Parent then Tween:Create(p,TweenInfo.new(duration*.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=entry.cf,Size=entry.size}):Play() end
			end)
		end
	end
end

return B
