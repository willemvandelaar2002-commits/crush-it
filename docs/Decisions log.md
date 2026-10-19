# Decisions log

- 2026-10-19: Picked Crush It as the next game (empty niche, simple loop). Start small, upgrade the press so it gets bigger.
- 2026-10-19: World built by code, Rojo port 34873 next to WarChest.
- 2026-10-19: Milestone 2: more detailed objects (screens, lights, faces), press rises in on upgrade with a banner, debris + shockwave on the final hit. Willem: core loop "looks good for now".
- 2026-10-19: Milestone 3: per-object crush styles (kind per object) and real sound effects from the Creator Store; all ids in Config.Sounds so they're easy to swap after listening.
- 2026-10-19: Milestone 4: rebirth (first at Car, +50% cash each), Golden 5% x10 / Diamond 0.5% x50 objects, collection book with permanent cash bonuses. Objects.luau moved to Shared so the book can show 3D previews.
- 2026-10-19: Milestone 5: Robux shop (4 passes, 3 cash packs, Golden Rush), offline earnings card, onboarding ring, funnel analytics, first thumbnail/icon. All Robux ids 0 until Willem creates them.
- 2026-10-19: Press redesign: own procedural model (PressBuilder) instead of Creator Store models (free models often hide scripts and couldn't grow per tier). 13 named presses in 5 stages, always bigger each tier.
- 2026-10-19: /credits (and /cash) chat command for testing: Studio + the place owner only.
- 2026-10-19: Objects are AI-generated meshes (ReplicatedStorage.ObjectMeshes in the place file); presses stay code-built for now, AI press frames were mixed.
- 2026-10-19: Press frames are AI meshes per stage (Rusty, Steel, Industrial, Mega, Titan); ram/bed stay code so the press can move. Plots enlarged to 120.
- 2026-10-19: Took Destroy a Vault's style: coloured upgrade rows, in-world upgrade board next to the press, top tutorial banner with pointing hand.
- 2026-10-19: Stud pattern everywhere (floors, pad, rims, walkway, board, UI rows), bright grass floors, dark pad under the press, coloured plot rims.
- 2026-10-19: Reusable style kit (shared/Kit/Style, server/Kit/Build) in the Destroy a Vault look; Crush It restyled with the Teal theme (yellow ground, raised teal platforms, chunky signs, floating labels, gradient panel rows).
- 2026-10-19: Props in the kit (tree, bush, rock, fence, lamp) and Decor.luau placing them round the plots; seeded so the layout is fixed. Can be switched off with Config.Look.Props.
