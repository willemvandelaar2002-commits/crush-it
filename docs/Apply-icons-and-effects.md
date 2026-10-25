# Apply icons and row effects — 25 October 2026

The replacement ZIP includes 35 transparent PNGs, an installer and client row effects.
Five imported specials await original FBX/OBJ files. This does not upload or publish.
Based on main 7e4acf7, preserving the MAX button and actual HUD image-ID fix.

1. Give the complete ZIP to the connected Codex/Claude session. Extract, then run:
   python3 /path/to/CrushIt-UI-Update/install.py --repo /path/to/crush-it
   It checks patches and file hashes before editing, selects the combined patch
   or icon-only patch if the row effects are already applied, and copies the PNGs
   into assets/crusher-icons. Conflicting current work stops before any edits.
2. Bulk-import icons/Crusher_*.png into this experience's Studio Asset Manager,
   keeping names exactly, without .png. Local files and Rojo cannot upload images.
   Source registry uses the named assets, with actual image-ID overrides supported.
   Existing Shared.Icons remains untouched. Never substitute private thumbnails.
3. Sync Rojo (port 34873), run tools/crusher-icons/verify_uploads.luau in Command Bar.
   Expect 35 loaded, zero failed, five special exports pending. If aliases fail,
   put actual uploaded image content URIs in Shared.CrusherIcons.Overrides.
4. Fresh desktop Play: Index/Owned open, scroll, close/reopen, black silhouettes,
   both rewards tabs, quest shop, native hotbar pictures, keys, equip/unequip,
   placing crushers and respawn. Check labels, odds, coating names, output and MAX.
5. Row test: five Epics inactive; sixth produces a small purple burst, rising motes
   and a travelling pedestal glint with +25% scrap. Removing one clears effects.
   Rapid repeats don't spam bursts; new activation after 2.5 seconds can celebrate.
   Legendary is gold with existing +40%; lower rarities retain original trim/pulse.
   Check all original rows and extension, range beyond 135 studs and back, low/high
   quality, real streaming if enabled, bay controls, collect/sell, audio and Output.
6. For the last five icons, send original imported FBX models or run the included
   prepare_studio_exports.luau in EDIT mode. Export ONE named clone at a time as
   TwinTitan.obj, RocketPress.obj, Magnetron.obj, GoldenKing.obj and Toyzilla.obj.
   Keep MTL/textures alongside each. Originals remain in ServerStorage unchanged.

Offline: 110 game sources compile; 140 actual-module lifecycle/image/hotbar/effect
checks and 140 PNG checks pass. No connected Studio rendering/input test is claimed.
Current world/carried/roll models, numbers, saves and remotes remain unchanged.
The only server edit is a presentation attribute used by the native backpack.

Run the repeatable mock-service checks with:
python3 tools/crusher-icons/verify_offline.py --luau /path/to/luau
Phone implementation stays deferred. Restart Play after image uploads, since failed
asset results are cached for that session. The contact sheet is not a Studio capture.
