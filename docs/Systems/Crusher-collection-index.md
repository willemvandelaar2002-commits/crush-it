# Forty collectible crushers and the Index

24 Oct art update: the procedural first pass below is superseded for thirteen
Epic/Legendary types by [[Crusher identities]]. The roster, odds and production
bands remain current. Imported special templates remain unchanged.

2026-10-23. The combined patch now implements **40 live, rollable types**, eight
per existing rarity: the original eleven plus twenty-nine code-built rigs.
The earlier eleven-type UI patch and proposed-only roster are superseded.
Apply `crush-it-40-crushers.patch`; see [[../Apply-40-crushers]].

## Complete active roster

The five imported special models remain in use. Six legacy procedural presses
remain unchanged. The 29 additions have individual part-built mechanisms in
`server/CatalogCrushers.luau`; Rojo installs their builder, so there is no new
Blender/FBX import step for those models. They are a procedural first art pass,
ready for Studio appearance review and later mesh refinement.

### Common — eight types; base odds about 1 in 11 each

| Stable ID | Crusher | Model / mechanism | Production band |
| --- | --- | --- | --- |
| `Bumper` | Bumper Press | Existing procedural press | Bumper |
| `Steel` | Steel Stamp | Existing procedural press | Steel |
| `Clamp` | Clamp Crusher | Wide C-clamp body; pressure screw travels down through one open side. | Bumper |
| `Spring` | Spring Stamp | Twin oversized exposed springs and a rounded stamping shoe. | Bumper |
| `Screw` | Screw Press | Tall threaded central spindle and a large handwheel. | Steel |
| `Rivet` | Rivet Press | Slender offset arm with a narrow punch and a circular work table. | Steel |
| `Bottle` | Bottle Squasher | Short box frame, ribbed bottle guide and a broad ribbed platen. | Bumper |
| `Bench` | Bench Crusher | Low workbench silhouette with a horizontal squeeze jaw. | Steel |

### Uncommon — eight types; base odds about 1 in 36 each

| Stable ID | Crusher | Model / mechanism | Production band |
| --- | --- | --- | --- |
| `Cobalt` | Cobalt Crusher | Existing procedural press | Cobalt |
| `RocketPress` | Rocket Press | Existing imported special template | Cobalt |
| `Gearbox` | Gearbox Crusher | Visible interlocking side gears turn a crank-driven platen. | Cobalt |
| `Flywheel` | Flywheel Press | Large single flywheel drives an offset stamping linkage. | Cobalt |
| `Pneumatic` | Pneumatic Press | Twin bulbous air tanks, pressure gauge and a compact fast punch. | Cobalt |
| `DoubleStamp` | Double Stamp | Two narrow punches on one beam, moving in opposite phases. | Cobalt |
| `Boiler` | Boiler Press | Round central boiler, steam pipes and a bell-shaped descending head. | Cobalt |
| `Conveyor` | Conveyor Crusher | Long low body with a roller-fed crushing gate. | Cobalt |

### Rare — eight types; base odds about 1 in 133 each

| Stable ID | Crusher | Model / mechanism | Production band |
| --- | --- | --- | --- |
| `Mega` | Mega Piston | Existing procedural press | Mega |
| `Magnetron` | Magnetron | Existing imported special template | Mega |
| `Thunder` | Thunder Press | Split forked columns, lightning-shaped braces and a capacitor-powered head. | Mega |
| `Frost` | Frostbite Press | Angular ice-like clear guards, insulated pipes and a crystalline platen. | Mega |
| `Furnace` | Furnace Crusher | Broad enclosed furnace body with a glowing window and a heavy hot stamp. | Mega |
| `ScrapShark` | Scrap Shark | Horizontal shark-jaw mechanism, dorsal housing and interlocking teeth. | Mega |
| `SteamHammer` | Steam Hammer | Tall narrow stack with a suspended hammer and side steam valves. | Mega |
| `JunkyardJaw` | Junkyard Jaw | Asymmetric excavator-style hydraulic arm closes a huge serrated claw. | Mega |

### Epic — eight types; base odds about 1 in 444 each

| Stable ID | Crusher | Model / mechanism | Production band |
| --- | --- | --- | --- |
| `Titan` | Titan Hydraulic | Existing procedural press | Titan |
| `TwinTitan` | Twin Titan | Existing imported special template | Titan |
| `Laser` | Laser Press | Open triangular frame with lens-ring emitters above the physical platen. | Titan |
| `Plasma` | Plasma Piston | Large translucent cylindrical core, rings and a floating-looking press shoe. | Titan |
| `Gravity` | Gravity Well | Arch suspension and orbiting weight blocks around a heavy spherical hammer. | Titan |
| `Quake` | Quake Hammer | Very wide low feet and an oversized hanging pile-driver head. | Titan |
| `Cyclone` | Cyclone Crusher | Turbine housings and a spiral cage around the moving ram. | Titan |
| `Mecha` | Mecha Fist | Two braced mechanical arms drive a giant robotic punching fist. | Titan |

### Legendary — eight types; base odds about 1 in 4,000 each

| Stable ID | Crusher | Model / mechanism | Production band |
| --- | --- | --- | --- |
| `Quantum` | Quantum Press | Existing procedural press | Quantum |
| `GoldenKing` | Golden King | Existing imported special template | Quantum |
| `Toyzilla` | Toyzilla | Existing imported special template | Quantum |
| `Starforge` | Starforge | Star-shaped overhead gantry, suspended gold hammer and a bright core. | Quantum |
| `DragonJaw` | Dragon Jaw | Long horned dragon head above a fixed jaw, with wing-shaped side braces. | Quantum |
| `BlackHole` | Black Hole Engine | Circular magnetic cage, dark central sphere and curved gravity-fed jaw. | Quantum |
| `Clockwork` | Clockwork Colossus | Clock-face crossbeam, pendulum weights and a geared crown-shaped stamp. | Quantum |
| `FactoryHeart` | Factory Heart | Toy-factory marquee, four piston arms and a heart-shaped mechanical core. | Quantum |

## Production and rolling

- `CrusherRoster` extends the actual `CrusherConfig.Types` and rarity pools.
  It is not a separate list used only for presentation. Each new ID is rollable,
  can be equipped and levelled, produces scrap, and survives normal migration.
- Existing type IDs, stats, imported templates, legacy tier migration and
  saved instances remain. The hub Mega Crusher remains scenery.
- Rarity weights stay 70 / 22 / 6 / 1.8 / 0.2. Each rarity now has eight equally
  selected types. Displayed type odds are recomputed from those pools; original
  individual type odds necessarily become rarer. Luck/pass behaviour is retained.
- New types inherit their named existing band's damage, input HP, yield and
  cycle. Common still has four Bumper-band and four Steel-band types, preserving
  its previous 50/50 output mix. Other rarity bands already had matching stats.
  This adds collection and visual variety without inflating production rewards.
- No new abilities, currencies, mutation catalogue or modifier bonuses.
  Existing Standard/Rusty/Polished/Charged instances continue to work.

## Rigs and performance

Each new rig has its own geometry, an explicit working surface, positive input
clearance and a named moving assembly. All geometry is anchored/non-colliding.
Full rest poses fit the 8.6 x 9.4 x 8 bay envelope uniformly. Motions include
vertical presses, a horizontal vise, hinged jaws and alternating double stamps.
Piston shafts telescope with fixed upper endpoints. Input height is fitted to
real rest clearance, including raised anvil/jaw/roller work surfaces.

One static sanitised preview per live type is replicated for Index viewports.
Hidden/closed cards release their viewport clones. Roll silhouettes use a lazy
cache of at most six models per pedestal (30 with all five unlocked); each outline is detached before
an old silhouette is evicted. They no longer prebuild forty hidden rigs per plot.

## Inventory space and discovery

Owned retains unique-instance equipment and levels. To keep duplicate rolls
from permanently blocking the 80-slot inventory, an **unequipped duplicate**
can be recycled with a second confirmation click, showing its level first.
The server checks ownership, equipped state and remaining copies at transaction
time. Equipped machines and the last copy of every type are protected. There
is no refund, payout or cash exploit. Cancelling/closing expires confirmation.

Since the last copy of each type remains owned, discovery is still derived from
owned types without a new save schema. If last-copy deletion or trading is added
later, introduce a permanent discovered-type ledger before allowing it.

## Desktop UI

Blue studded header, tilted book icon, red close button, outlined Fredoka text,
rarity cards, scrollbars and actual live-type progress follow the approved UI.
**Index** shows all 40 types with rarity filters, base odds and undiscovered
silhouettes. **Owned** keeps individual instances, levels, output, equipment and
protected duplicate recycling. World SWAP opens Owned with the correct bay.
Individual levels and global upgrades stay on physical plaques/boards.
`CrushHud`, `Book`, `BookButton`, `CrushButton` and the Shop interface remain.
New ScreenGuis use Sibling. Phones remain deferred.

## Integration and Studio verification ? 23 Oct 2026

Merged against the newer project while preserving free rolls with paid pedestal
purchases, five rolling pedestals, 24 working bays, streaming control rebinding,
the cash HUD and the recent Rewards UI. Recycling is allowed through the inventory
remote alongside equip/unequip; authoritative rules still reject equipped,
foreign and last-of-type instances. The older paid-roll flow is superseded.

Completed in the connected Crush it Studio place:

- Rojo build and whitespace checks passed. Fresh Play loaded the changed modules.
- CrusherRules.spec: 326 assertions passed, including all 40 roll offers,
  purchasing, migration, production and protected recycling.
- SpecialCrushers.spec: 52 checks passed across all five imported templates.
- CatalogCrushers.spec: 11,761 checks passed across all 29 new rigs, including
  bay bounds, work-surface clearance, safe parts, stationary frames, moving
  shafts and return to rest after real tweens.
- At 1636 x 753, the live Index contained 40 cards. Every rarity filter showed
  eight entries; All restored 40. Scrolling instantiated all 40 model previews
  with cameras and models, including unknown silhouettes. The desktop Index
  and five-pedestal reveal were visually inspected in screenshots.
- Real mouse clicks equipped a Clamp in bay 1 and confirmed duplicate recycling;
  the instance count decreased. The equipped Clamp visibly changed part positions
  during automatic production. Equip/unequip was exercised for a duplicate.
- Five-pedestal rolling revealed five offers. A second roll retained 30 cached
  silhouettes and all five outlines after eviction. Buying an offer added the
  revealed crusher to Owned.
- Play Output showed no crusher/UI script errors. Existing DataStore access
  warnings and asset 203785492 type mismatch messages remain.

Tests used Studio's in-memory profiles and disposable Play fixtures. No live
player data was changed. Studio was returned to Edit mode with the merged
sources installed; the game was not published.

Remaining: physical-phone behavior, live save persistence and multiplayer load
are unverified. Every new rig passed engine motion tests, but a separate visual
review of each of the 29 machines in a working bay has not been completed.
