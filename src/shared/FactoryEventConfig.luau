--!strict
-- Event-only tuning. Existing production, roll, shop and plot numbers stay intact.
return {
	Enabled = true,
	Interval = 15 * 60, -- first announcement and time between completed rounds
	Announce = 20, Assemble = 6, Active = 180, Finale = 7, Victory = 6, Recover = 3,
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
	MaxVisiblePlots = 6, VisualDistance = 420,
}
