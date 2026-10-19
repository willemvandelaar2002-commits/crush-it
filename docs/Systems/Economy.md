# Economy

All numbers in `src/shared/Config.luau`. t = tier (1 = Apple), l = level.

| Thing | Formula |
|---|---|
| Object HP | 3 · 3.4^(t-1) |
| Object value | 3 · 6^(t-1) |
| Power (damage per press) | 1.28^l, cost 10 · 1.75^l |
| Speed (seconds per press) | max(0.3, 0.93^l), cost 15 · 1.8^l, max level 17 |
| Value (cash multiplier) | 1 + 0.2·l, cost 25 · 1.9^l |
| Bigger press (tier t → t+1) | value(t) · 10 · 1.32^(t-1) |
| Conveyor | 0.8 s between objects |

Simulated first run (greedy buyer): tier 2 at ~1.3 min, Car ~12 min, Tank
~23 min, Plane ~77 min. Later tiers slow down on purpose; rebirth takes over.

Tiers: Apple, Teddy Bear, Phone, TV, Fridge, Car, Truck, Tank, House, Plane,
Ship, Statue, Planet.
