--!strict
-- Shared clock, also used by the existing Mega.client driver: one ram owner.
local E=require(script.Parent.FactoryEventConfig)
local M={}
function M.controls(phase)
	return phase=="Assemble" or phase=="Active" or phase=="Finale" or phase=="Victory" or phase=="Recover"
end
function M.ram(phase,age)
	if phase=="Active" then return .08+.07*(1-math.cos(age*math.pi)),false end
	if phase=="Finale" then
		if age<2.5 then return 0,false end
		if age<2.85 then return ((age-2.5)/.35)^3,false end
		if age<4 then return 1,true end
		return math.max(0,1-(age-4)/2)^2,false
	end
	return 0,false
end
function M.plotStroke(age)
	if age<E.Strike-.25 then return 0 end
	local t=(age+.25)%E.Strike -- contact lands on the authoritative strike beat
	if t<.25 then return (t/.25)^3 end
	if t<.55 then return 1 end
	return math.max(0,1-(t-.55)/.9)^2
end
return M
