# Crush It

24 Oct Daily Spin: the plaza station opens an image-based wheel with one free
spin every 24 hours. The server selects/persists cash, Golden Rush and crusher
prizes; paid spins stay disabled. See [[Systems/Daily Spin]] for provisional
weights, save recovery, Studio checks and remaining live verification.

24 Oct upgrade clarity: bay plaques identify THIS CRUSHER and preview its next
level output. FACTORY UPGRADES affects ALL YOUR CRUSHERS; ROLL UPGRADES affects
FUTURE ROLLS. Existing prices and progression are retained. See [[Systems/Upgrade controls]].

24 Oct Blender scenery integration: imported duck, teddy and recolourable cars
replace their procedural displays. Two block shelves also reuse the robot and
brick models. Place-file templates live in ReplicatedStorage.FactoryToyModels;
missing templates retain procedural fallbacks. See [[Systems/Blender prop briefs]]
for pivot conventions, Studio checks and the required place save.

23 Oct forty-crusher update: all 40 types are active in the roll catalogue,
with 29 distinct code-built rigs alongside the original eleven. The desktop
Index/Owned UI uses actual model previews, base odds and protected duplicate
recycling. See [[Systems/Crusher-collection-index|Full roster and verification]]
and [[Apply-40-crushers|Patch application instructions]].

24 Oct crushing feedback: nearby machines get timed squash, contact/hold/release
and small pooled scrap bursts. One local audio mix selects the nearest two
crushers, merges simultaneous hits and caps impact starts at four per second.
Collect/sell cues stand out through a temporary machinery duck. See
[[Systems/Crusher feedback]] and [[Apply-crusher-feedback]].

22 Oct imported crusher integration: TwinTitan, RocketPress, Magnetron,
GoldenKing and Toyzilla are collectible types using anchored place templates,
manifest-fitted bays and separate moving rams. See [[Systems/Special crusher models]]
for tested dimensions, animation, fallback and place-save requirements.

24 Oct crusher identities: thirteen Epic/Legendary rigs have stronger toy
silhouettes, animated gears/cores/orbits and restrained glow. The three imported
Epic/Legendary specials remain intact. Bays, rolling, Index and carried models
share the new shapes; economy and saves are unchanged. See
[[Systems/Crusher identities]] and [[Apply-crusher-identities]].

22 Oct gameplay redesign: collect and level hydraulic crushers, equip them in
three rear working bays, automatically crush inputs, collect scrap and sell
directly for cash. Separate Production and Rolling boards, instance inventory
and a new tutorial replace manual crushing, object-tier progression and smelting.
Existing profiles migrate without a wipe, with legacy recovery retained. See
[[Systems/Collectible crushers]] for economy, migration and validation limits.

22 Oct current factory refinement: twelve skylights and four broad opaque
infill bays give a roughly half-solid roof. Overhead beam shadow bars are
removed while display contact shadows remain. Brighter golden flooring and distinct
car/duck/block/packing displays soften and organise the hall. See
[[Systems/Toy factory environment]] and [[Systems/Blender prop briefs]].

22 Oct factory polish: finished cream ceiling sections and framed skylights,
heavier structural beams, larger stocked shelves and mascots, a readable rear
marquee, golden floors with coarser studs, and cleaner lighting depth. Layout,
presses, trains and UI are unchanged. Save the place's new derived floor
material with the existing assets. See [[Systems/Toy factory environment]].

21 Oct toy-factory patch: the reference picture is the visual target. A bright
skylit hall, colourful beams, oversized toy shelves, mascot displays and a
gantry now surround the existing Toy Train Loop. Imported studs, the raised
commons and island gaps are retained. See [[Systems/Toy factory environment]]
for integration details and Studio checks.

Reference-led land update (21 Oct): a broad raised workshop commons joins
the centre to the train loop, with wider lanes, four work bays, contained
planting and framed storage aprons. Its outer shoulder has been pulled back
to restore the sandy separation from the plot islands. Background visibility
was verified at higher preview quality; low graphics still culls distant
scenery. See [[Systems/Scrapyard environment]].

Imported studs adopted (21 Oct): plot floors, the hub and plastic scenery now
use the approved MaterialService.Studs finish. Presses and UI keep their
existing treatment. See [[Systems/Stud material comparison]] for the switch
back and place-save requirements.

Latest world art pass (21 Oct): golden sand, charcoal routes, larger grouped
perimeter yards, yellow crane landmarks, a striped-awning workshop, substantial
green cliff terraces and warmer daylight. See [[Systems/Scrapyard environment]]
for the current Studio verification and remaining device checks.

Small, quick game to test alongside WarChest: one loop, few systems, out fast.

- [[Plan]] — the idea and the milestones
- [[Systems/Economy]] — objects, upgrades, prices and the timing behind them
- [[Systems/Collectible crushers]] — current roll/equip/produce/collect/sell loop and save migration
- [[Systems/Press and plots]] — the world, the press, crushing
- [[Systems/Shop]] — Robux passes/products, onboarding, analytics, thumbnail
- [[Systems/Progression]] — rebirth, golden/diamond objects, collection book
- [[Systems/Scrap]] — crush -> scrap -> sell at your scrap shop (the core loop since 20 Oct)
- [[Systems/Helpers]] — Mini Presses you buy and merge that crush for you
- [[Systems/Style kit]] — reusable studded look (Style + Build) for this and future games
- [[Systems/Toy workshop]] — blue-grey workshop theme and earlier UI Play checks
- [[Systems/Scrapyard environment]] — completed environment pass, Studio checks and remaining manual tests
- [[Systems/Toy factory environment]] — reference-led toy-factory patch and Studio review
- [[Systems/Collectible crushers]] — rolling, bays, boards, plot layout
- [[Systems/Hub plaza]] — the factory centre: stage, Mega Crusher, hub stations
- [[Decisions log]]
- [[Backlog]]

## Status (19 Oct 2026, end of first session)
Published as "Crush it" (placeId 132070482662061, Willem's account).
Done: core loop, 13 objects (AI meshes), 13 presses (AI mesh frames per stage
+ code ram), effects + sounds, rebirth, golden/diamond, collection book,
Robux shop (ids still 0), offline earnings, onboarding banner, analytics,
upgrade board, /credits, Destroy-a-Vault studded look + reusable style kit.
Props (trees, bushes, rocks, fences, lamps) added in the kit + Decor.luau.
HUD: goal bar, icon buttons, rainbow offers, cash bottom-left (20 Oct).
Leaderboard (Here / Friends / Global) top right (20 Oct).
Free rewards: playtime gifts + 7-day daily check-in (20 Oct).
Friend boost + invite button, Robux signs on the plot (20 Oct).
New Steel press frame, ground guide path (20 Oct).
Scrap loop: crushing drops scrap, pick it up, sell at the scrap shop island behind your plot; Auto Collect pass; warm sunset sky (20 Oct).
Reference-video pass (20 Oct): smelter with deposit/collect pads, buy pads, cliffs + lavafalls, factory look, brick paths, numbered tutorial, zone label.
Islands: every plot is an island in a bright lava sea with wooden bridges to a hub island (20 Oct).
Next ideas: helper units (like the capybaras/tanks), Halloween event; create the passes/products and fill Store ids; proper thumbnail.

21 Oct environment update: approved server art pass replaces exterior lava with a sandy scrapyard, stepped green-capped cliffs, concrete routes, workshop prop clusters and a CRUSH IT entrance. See [[Systems/Scrapyard environment]] for checks and remaining manual tests.
