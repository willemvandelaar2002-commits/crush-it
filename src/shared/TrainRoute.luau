--!strict
-- The toy trains' timetable (server/Hub.luau builds them, client/Train.client.luau
-- drives and rides them). Every lap is one leg per plot: stand at the plot's
-- stop for Config.Loop.TrainStop seconds, then drive on to the next one in
-- Config.Loop.TrainMove seconds (smooth start and stop). Everything follows from the
-- server clock, so every player sees the trains in the same place.

local Config = require(script.Parent.Config)

local TrainRoute = {}

TrainRoute.CENTRE_BEHIND = 27 -- studs from the engine's pivot back to the middle of the train
local function STEP(): number return math.rad(360 / Config.Plots.Count) end

-- Angle (radians, 0 = +Z, increasing in the travel direction) where the engine
-- stands when the middle of the train is at plot `index`'s stop.
function TrainRoute.stopAngle(index: number): number
	return math.rad(Config.plotAngle(index)) + TrainRoute.CENTRE_BEHIND / Config.Loop.TrainRadius
end

-- (engine angle, angular speed in rad/s, plot index it is standing at or nil)
function TrainRoute.at(t: number, phaseLegs: number): (number, number, number?)
	local L = Config.Loop
	local leg = L.TrainStop + L.TrainMove
	local tt = (t + phaseLegs * leg) % (leg * Config.Plots.Count)
	local k = math.floor(tt / leg)
	local u = tt - k * leg
	local start = TrainRoute.stopAngle(k + 1)
	if u < L.TrainStop then
		return start, 0, k + 1
	end
	local s = (u - L.TrainStop) / L.TrainMove
	local eased = s * s * (3 - 2 * s)
	local speed = STEP() * 6 * s * (1 - s) / L.TrainMove
	return start + STEP() * eased, speed, nil
end

-- The engine's CFrame on the rails at angle `a` (facing the travel direction).
function TrainRoute.frame(a: number, y: number): CFrame
	local r = Config.Loop.TrainRadius
	local pos = Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
	return CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), 0, -math.sin(a)))
end

return TrainRoute
