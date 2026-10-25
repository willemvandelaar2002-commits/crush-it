# Crusher portraits — 25 October 2026

35 transparent 512×512 PNGs rendered from the actual Luau-built rigs. Same camera,
lighting, navy outline and render-only bevel treatment; game models unchanged.
Upload only Crusher_*.png to this experience's Asset Manager, preserving filenames
as asset names without .png. The registry uses these named experience assets;
actual image IDs in Shared.CrusherIcons.Overrides take precedence if aliases fail.
Use image content IDs, as in the existing Shared.Icons fix; no private-decal thumbnails.

Five final images require Studio-only meshes: TwinTitan, RocketPress, Magnetron,
GoldenKing, Toyzilla. They retain actual model previews; no guessed proxy artwork.
Send original FBX files or run tools/crusher-icons/prepare_studio_exports.luau in
Studio Edit, export each named clone as OBJ, and retain its MTL/textures alongside it.

Regenerate the code rigs with Python 3, numpy, Pillow and a Luau CLI:
python3 tools/crusher-icons/export_geometry.py --luau /path/to/luau --out geometry.json
python3 tools/crusher-icons/render_icons.py geometry.json --out assets/crusher-icons

preview.jpg is a contact sheet, not a Studio screenshot. manifest.json records the
35 completed renders and five pending exports. Local files/Rojo do not upload images.

Connected integration: the 35 files were uploaded with the user's approval.
Actual image IDs are in manifest.json and Shared.CrusherIcons.Overrides. Fresh
Studio verification now confirms all 35 loading after the user shared assets
and the loader was corrected to preload ImageLabels instead of raw asset IDs.
Index silhouettes and available native hotbar pictures work. No further grants
or duplicate uploads are needed for these 35. Five special portraits remain absent.
