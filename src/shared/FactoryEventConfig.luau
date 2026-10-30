--!strict
-- Event-only tuning. Existing production, roll, shop and plot numbers stay intact.
local E = {
	-- Plot-local box over the crusher platform: stage decorations inside it
	-- hide during the event (side walls at |x| 79, rear beacon at z -109 and
	-- the front yard stay). Measured on a Factory V plot, 28 Oct.
	PlatformZone={HalfWidth=78,Back=-105,Front=12,Above=1.5},
	Enabled = true,
	Interval = 15 * 60, -- first announcement and time between completed rounds
	Announce = 13, Assemble = 8, Active = 180, Finale = 7, Victory = 8, Recover = 3, -- 29 Oct: Victory 11 -> 8 (reels shorter) -- Victory 11: room for the reward reels -- 28 Oct: Announce+Assemble = the intro cutscene
	Tick = .2, Broadcast = .5, Strike = 2,
	TargetSeconds = 90, MinimumActive = 30, MinimumHits = 10,
	Points = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Secret=6, Divine=7, Mythic=8},
	Grades = { -- points change the silhouette, never the saved crusher rarity
		{points=0, name="SUPER PRESS"}, {points=15, name="TWIN HYDRAULIC"},
		{points=45, name="REACTOR PRESS"}, {points=100, name="TITAN ENGINE"},
		{points=200, name="FACTORY COLOSSUS"},
	},
	MaxPower = 25, -- 1 + log10(1 + real fleet output): avoids one huge factory deleting the event
	PulseCooldown = 6, PulseWindow = .75, PulseMultiplier = 3,
	RewardSeconds = 120, MinReward = 250, MaxReward = 1e12, LedgerSize = 20,
	-- 28 Oct: the win reward is a set of spinning reels (like the reference).
	-- Every qualifying player spins; the damage ranking decides how many reels.
	-- The server picks every result when the bear falls and saves it at once;
	-- the reels only show it. TEST DEFAULTS: weights and amounts not approved.
	Reels = {
		ByRank = {3, 2, 2}, Others = 1, -- #1 gets 3 reels, #2-#3 get 2, everyone else 1
		Spin = 3.2, Stagger = .4, Tiles = 34, -- seconds per reel, delay between reels, tiles per strip (29 Oct: was 4.2 / .55)
		Prizes = {
			{id="Cash", kind="cash", seconds=120, weight=38},                -- your cash/sec x seconds
			{id="BigCash", kind="cash", seconds=360, weight=18},
			{id="CashBoost", kind="boost", boost="Cash", minutes=10, weight=20},
			{id="LuckBoost", kind="boost", boost="Luck", minutes=10, weight=15},
			{id="Legendary", kind="crusher", rarity="Legendary", weight=8},
			{id="Mythic", kind="crusher", rarity="Mythic", weight=1, notShop=true}, -- 30 Oct: 1% (was 2), never a shop-only Mythic
		},
		FullFallback = "BigCash", -- a crusher prize with a full inventory pays this instead
	},
	PlotHalfWidth = 80, PlotRear = -125, PlotFront = 118, PlotHeight = 65, -- PlotFront: Plots.Front 112 + 6
	VisualOrigin = Vector3.new(0, 1, -13), -- clear middle gap between the existing wing banks
	SuperScale = 2.6, -- 28 Oct: the super crusher is built 2.6x (the whole bank platform hides during the event)
	MaxVisiblePlots = 6, VisualDistance = 420,
	Music = 131187734101917, MusicVolume = .5, -- Willem's event song (normal music fades out)
	-- event sound effects (Creator Store, checked to load 28 Oct)
	Sounds = {
		Roar = 9113980319, Screech = 9125474863, Impact = 9116700296, Whoosh = 123796710194563,
		Alarm = 3165700530, Charge = 93424230108648, Sparkle = 117011707307950, Fanfare = 9067124098,
		Shatter = 9114589178, Clunk = 9125788628, PowerUp = 3406813517,
	},
	-- 28 Oct: everyone takes part automatically. Players with no placed crusher
	-- get an event-only stand-in machine with this power (no inventory change).
	FallbackPower = 1.5,
	-- Event cores: pick one up on your plot, load it into your super crusher's
	-- port; the next strike does CoreMultiplier x damage (CriticalMultiplier while
	-- the port glows gold). Plot-local spots measured clear of stations/paths.
	Cores = {
		Max = 3, Respawn = 5, PromptDistance = 9,
		Spots = { Vector3.new(-30,1.6,98), Vector3.new(30,1.6,98), Vector3.new(-24,1.6,60), Vector3.new(18,1.6,54), Vector3.new(0,1.6,92) },
		Port = Vector3.new(0,1.6,9), -- in front of the (2.6x) super crusher
		Multiplier = 4, CriticalMultiplier = 10,
		CriticalEvery = { 18, 28 }, CriticalSeconds = 8,
	},
	-- Bear paw slam: a red danger circle under one player at a time, then the slam.
	Slam = { Every = { 13, 19 }, Warn = 2.2, Radius = 9, MaxActive = 2, Stagger = 1.2, StaggerSpeed = 5 },
}

-- 29 Oct: two versions of the event, taking turns on the hour (Willem: "13:00
-- normal event, 14:00 Halloween event"). Same rules and rewards; only the boss,
-- cores, colours and words change. Order[1] runs on even UTC hours (13:00 in
-- Amsterdam winter time), Order[2] on odd ones. Hourly=false: the old Interval.
E.Schedule = { Hourly = true, Order = { "Bear", "Halloween" } }
E.Variants = {
	Bear = {
		boss = "FactoryBear", -- ReplicatedStorage.FactoryEventMeshes
		bossWord = "bear", Boss = "Bear",
		accent = Color3.fromRGB(173, 65, 255), -- cores, beams, port rings
		sky = Color3.fromRGB(120, 60, 190), skyDecay = Color3.fromRGB(60, 20, 110),
		ambient = Color3.fromRGB(125, 95, 165), outdoor = Color3.fromRGB(140, 105, 190),
		tint = Color3.fromRGB(235, 226, 255),
	},
	Halloween = {
		boss = "PumpkinForeman", core = "PumpkinCore", pickup = "CandySoul",
		bossWord = "pumpkin", Boss = "Pumpkin",
		music = 83398637668977, -- Willem's Halloween song
		accent = Color3.fromRGB(184, 255, 68), -- lime candy energy
		-- 29 Oct: spooky night: violet sky, orange glow on the horizon, a big moon
		sky = Color3.fromRGB(70, 40, 105), skyDecay = Color3.fromRGB(255, 120, 35), haze = 2.4, density = .3, moon = 22,
		ambient = Color3.fromRGB(105, 95, 135), outdoor = Color3.fromRGB(115, 100, 145),
		tint = Color3.fromRGB(250, 238, 230),
		candies = 18, -- little candies floating round you during the round
	},
}
-- Which version a round started at server time `t` is.
function E.variantAt(t: number): string
	if not E.Schedule.Hourly then return E.Schedule.Order[1] end
	local order = E.Schedule.Order
	return order[math.floor(t / 3600) % #order + 1]
end
-- When the next round is announced after time `t`.
function E.nextStart(t: number): number
	if not E.Schedule.Hourly then return t + E.Interval end
	return (math.floor(t / 3600) + 1) * 3600
end
function E.variant(name: string?): any
	return E.Variants[name or ""] or E.Variants.Bear
end
return E
