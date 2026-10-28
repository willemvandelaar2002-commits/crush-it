--!strict
-- Event-only tuning. Existing production, roll, shop and plot numbers stay intact.
return {
	Enabled = true,
	Interval = 15 * 60, -- first announcement and time between completed rounds
	Announce = 13, Assemble = 8, Active = 180, Finale = 7, Victory = 6, Recover = 3, -- 28 Oct: Announce+Assemble = the intro cutscene
	Tick = .2, Broadcast = .5, Strike = 2,
	TargetSeconds = 90, MinimumActive = 30, MinimumHits = 10,
	Points = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6},
	Grades = { -- points change the silhouette, never the saved crusher rarity
		{points=0, name="SUPER PRESS"}, {points=15, name="TWIN HYDRAULIC"},
		{points=45, name="REACTOR PRESS"}, {points=100, name="TITAN ENGINE"},
		{points=200, name="FACTORY COLOSSUS"},
	},
	MaxPower = 25, -- 1 + log10(1 + real fleet output): avoids one huge factory deleting the event
	PulseCooldown = 6, PulseWindow = .75, PulseMultiplier = 3,
	RewardSeconds = 120, MinReward = 250, MaxReward = 1e12, LedgerSize = 20,
	PlotHalfWidth = 80, PlotRear = -125, PlotFront = 118, PlotHeight = 65, -- PlotFront: Plots.Front 112 + 6
	VisualOrigin = Vector3.new(0, 1, -13), -- clear middle gap between the existing wing banks
	SuperScale = 1.8, -- 28 Oct: the super crusher is built 1.8x (the bays hide during the event)
	MaxVisiblePlots = 6, VisualDistance = 420,
	-- 28 Oct: everyone takes part automatically. Players with no placed crusher
	-- get an event-only stand-in machine with this power (no inventory change).
	FallbackPower = 1.5,
	-- Event cores: pick one up on your plot, load it into your super crusher's
	-- port; the next strike does CoreMultiplier x damage (CriticalMultiplier while
	-- the port glows gold). Plot-local spots measured clear of stations/paths.
	Cores = {
		Max = 3, Respawn = 5, PromptDistance = 9,
		Spots = { Vector3.new(-30,1.6,98), Vector3.new(30,1.6,98), Vector3.new(-24,1.6,60), Vector3.new(18,1.6,54), Vector3.new(0,1.6,92) },
		Port = Vector3.new(0,1.6,3.5), -- in front of the (1.8x) super crusher
		Multiplier = 4, CriticalMultiplier = 10,
		CriticalEvery = { 18, 28 }, CriticalSeconds = 8,
	},
	-- Bear paw slam: a red danger circle under one player at a time, then the slam.
	Slam = { Every = { 13, 19 }, Warn = 2.2, Radius = 9, MaxActive = 2, Stagger = 1.2, StaggerSpeed = 5 },
}
