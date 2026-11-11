--!strict
-- Compatible catalogue API. All thirty-five code-built shapes share the
-- authored identity builder; five imported specials still use SpecialCrushers.
local RS=game:GetService("ReplicatedStorage")
local Identity=require(RS.Shared.CrusherIdentityRig)
local Motion=require(RS.Shared.CrusherMotion)
local B={}
local V=Vector3.new local F=CFrame.new local A=CFrame.Angles

function B.build(origin,typeId)
	local v=Identity.build(origin,typeId)
	if v then B.tag(v) end
	return v
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

-- the contact pose of every moving part, for the clients (Shared.CrusherMotion)
function B.tag(v)
	local groups={}
	for i,g in v.groups do
		local list={}
		for _,entry in g.rest do table.insert(list,{part=entry.part,down=B.target(v,g,entry,1)}) end
		for _,entry in g.rods do local down,size=B.rodTarget(v,g,entry,1) table.insert(list,{part=entry.part,down=down,size=size}) end
		groups[i]=list
	end
	Motion.tagGroups(v.model,.4,groups)
end

-- 11 Nov: the strike itself is shared with the clients (Shared.CrusherMotion); in the
-- game the server only sends a strike event (CrusherMotionServer). Kept for specs/dev.
function B.strike(v,event)
	local view=Motion.view(v.model) if view then Motion.play(view,event) end
end

return B
