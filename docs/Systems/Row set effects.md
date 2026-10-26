# Row set effects — 25 October 2026

Full Epic rows retain their +25% scrap and gain purple rising sparkles, a pale
travelling energy glint and a brief sparkle burst when the sixth member completes
the set. Legendary uses gold with its existing +40%; lower rarities keep trim/pulse.

Client-only RowSetEffects reuses four slots, each six tiny invisible hosts, six
emitters and one small glint: 28 local parts / 24 emitters at full capacity.
5 Hz candidate scans and 20 Hz animation, within 135 studs; owner plot prioritised.
For the player's own rows, distance uses the nearer of camera and character,
so normal camera zoom-out does not suppress effects beside the player's factory.
Other plots still use camera distance, and the four-slot cap remains.
Epic rate 1.8 particles/s/bay, Legendary 3; lifetime .7–1.25s, size at most .30 studs.
Four/five burst particles per bay; deduplicated, fresh within .8s, one burst per row
per 2.5s. Initially active rows do not burst. Effects clear on set break, culling,
missing rails, tag removal, streaming and script teardown. No per-frame Instances,
new sounds, lights, Highlights, model, remote, server, economy or save changes.
Built-in sparkle texture requires no upload. Background remains visible.

After applying, sync Rojo and test fresh desktop Studio Play: 5/6 to 6/6 Epic,
break/re-equip including rapid repeats, Legendary gold, all original and expansion
rows, camera beyond 135 studs and back, late rails, low/high graphics, bay controls,
collect/sell and Output. Studio is not connected here; no actual render/input pass
is claimed. The icon patch is independent. Phone work remains deferred.

Connected Studio check, 25 October: actual RowSetEffects fixtures selected four
of five Epic/Legendary rows, enabled 24 emitters/four glints and retained 52
effect descendants across repeated updates. Set break released its slot,
another row reused it, and empty selection/destroy cleared all effects. These
were disposable visual fixtures, not production-profile mutations. Existing
5,613 suite checks passed. Full activation-burst appearance, actual network
streaming, script teardown and low/high graphics performance remain manual.

26 October visibility fix: the reported row was correctly Epic 6/6 (+25%) but
the zoomed-out camera was 151.7 studs away while the character was 86.5 studs
away. Camera-only range filtering had culled its particles and travelling glint.
The owner-aware range above fixes this for both trim pulse and extra effects.
Fresh Play verified six emitters and one glint at that same zoom, exclusion of
a non-owned row outside camera range and an owned row outside both ranges,
immediate set-break cleanup/re-enable, and constant 13 effect descendants for
the one active slot. Local fixtures were removed and attributes restored;
no profile injection or purchase was used. Rojo build and whitespace passed.


## Stronger glow (26 Oct)

- Bloom is almost off in this place, so neon parts don't glow; the glow is built from translucent layers instead.
- Per bay, per active row (`RowSetEffects.luau`): a camera-facing `RowCurtain` beam rising 9 studs from the rail (pulsing transparency 0.4–0.6 at the base), a `RowHaze` smoke emitter (rate 4) and `RowSparkles` box emitters across the bay width.
- `RowOutline` Highlights (outline only, Occluded) on the crushers of the 2 nearest active rows (`HIGHLIGHT_ROWS`), 12 in total, staying under Roblox's 31 limit.
- Server aura (`CrusherRowVisuals`): pillars 0.7 thick, plus a new Top bar, both at 0.05 base transparency.
- Avoid the `forcefield_glow_main` texture for the haze: it reads as grey shards.
