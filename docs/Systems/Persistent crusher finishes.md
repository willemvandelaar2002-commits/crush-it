# Persistent crusher finishes

28 Oct 2026: visual-only replacement for the existing coating/fusion dressing.
Uses the existing `CrusherFinish.apply`, `dress`, `fused`, `Looks`, `VisualModifier`,
`Fused` and `CoatingFx` contracts. Working bays, carried minis and coated/fused
ViewportFrames continue to use one shared implementation.

- Polished keeps dark outlines and face/screen details, chrome surfaces and small glints.
- Frost adds six pointed crystal decorations with sparse snow and low-opacity ground mist.
- Fire adds five paired orange/yellow toy flames and sparse rising embers. No large Fire objects.
- Charged adds two rear coil caps and brief thin lightning confined to the rear top beam.
- Fusion adds gold base rails, lime corner cores, a front chevron badge and two lime gems.
  It layers over a coating rather than repainting the whole crusher green.

No crusher positions, ram sizes, production, recipe, modifiers, multiplier, costs,
odds or saves change. Dressing bounds explicitly exclude existing finish models,
so fusion does not grow around coating decorations. Apply/fused remain idempotent.
Imported mesh textures and SurfaceAppearance maps remain intact; PBR colour maps
receive a tint. Their authored material maps may affect the final sheen.
No client code moves welded/held parts; only cosmetic opacity, emitters, arcs and
three budgeted lights are animated.

Optional place-only templates: `ReplicatedStorage.CrusherFinishMeshes` containing
MeshParts `FinishCrystal`, `FinishFlame`, `FinishStar`. The Blender pack has FBXs
and an Edit installer; native fallbacks work without uploaded mesh IDs. Import
orientation must be upright Y; flame/star are thin on Z. Rebuild/re-equip existing
crushers after installing meshes and publish the place.

One `CoatingAnimator` scheduler groups both finish roots by their owner: detailed
particles on the nearest 12 crushers within 85 studs; quiet pulses on up to 24
within 140; static geometry beyond that. At most three point lights per client.
Disabled particles/arcs/lights start off, and `LocalEventHidden` immediately stops
them. ViewportFrames retain static geometry and do not run ambient emitters.

Offline checks cover all 35 authored procedural identities, original rig transforms,
row headroom, idempotence, additive fusion bounds, small-part budgets, LOD, event
hiding and cleanup. Imported place-only special crushers are not available in Git
and require Studio checks. Studio Play/import, actual particle texture rendering,
current events and full-plot performance remain unverified.
