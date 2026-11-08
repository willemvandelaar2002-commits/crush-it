# Exotic crushers — 8 November 2026

Six permanent regular-roll crushers: Maglev Mauler, Origami Clamp, Wrecking
Winch, Cam Cruncher, Screw Stamper and Drawbridge Crusher. Exotic sits
between Legendary and Secret (rank 4.25, leaving all old ranks unchanged).
Limited remains the weekend-only event tier at rank 4.5.

Exotic uses weight .04 (1 in 2,500 for any of six, 1 in 15,000 each before
luck). Common loses .04 so the total stays 100 and all other base odds
stay unchanged. During Lucky Weekend the Limited pool still adds .02.
Existing luck, boost, pity, first-roll and Index formulae apply normally.
New profiles stop autorolling on Exotic by default; saved target choices
are not reset. All six are appended after existing types to preserve order.

Price 200,000; value 280, multiplier 2.1: basic output is 588 per completed
input, between Legendary's 440 and Secret's 726. They inherit the Quantum
damage, HP and cycle. A six-Exotic row gives a row-only 44% bonus; breaking
the row removes it. Event fleet points are 5.5 per Exotic, between 5 and 6.
Coral/mint cards, row and bay effects match the models. No big-roll
cinematic is triggered for Exotic alone.

Templates use ServerStorage.SpecialCrusherMeshes.<TypeId>. Motion metadata
in shared/ExoticCrusherAssets uses the existing motion kit. No server
production code or purchase IDs changed. Meshes/PNG icons still require
Studio import. Upload the six supplied PNGs as Crusher_<TypeId> in this
experience; CrusherIcons' Ready resolver uses those names until real image
IDs are entered in Overrides. No IDs have been invented.

Assets: the source Blender generator and measured manifest are in
assets/exotic-crushers. The distributable pack contains six FBXs with
embedded colour atlases, six transparent 512x512 icon renders, and the
editable Blender project. The .blend timeline demonstrates the motion;
the FBXs contain open poses only.

Verification: six FBX reimports and Blender motion curves; Luau compilation;
the real rules, row and roll-presentation fixture suites under Luau CLI
with small datatype/service adapters, plus Exotic roll/buy/migration/row
checks. The JSON adapter only detaches tables; Roblox serialization, live
persistence and Studio Play are not tested here. Import scale, yaw, mesh
pivot behaviour, icons, real bay clearance and rendered effects must be
checked in Studio before publishing.
