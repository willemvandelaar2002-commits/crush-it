# Crusher icons — 25 October 2026

35 exact code-built rigs are rendered as transparent 512px portraits with a uniform
three-quarter camera, bright paint, soft upper highlight, small cosmetic bevels and
#13172A silhouette outline. Five imported specials await their actual FBX/OBJ files.
manifest.json records this incomplete art scope explicitly. preview.jpg is an asset
contact sheet, not a Studio screenshot. World/carried/roll models remain 3D.

CrusherIcon shares loaded images across Index/Owned, rewards and the quest shop.
Undiscovered cards tint their portrait black. Names, odds, output, coating labels,
instance equip/recycle actions, scrolling hydration and close/reopen remain.
Coatings use their existing label; each level/finish does not generate new art.
One preload per image URI per session; slow/failed/moderated images keep a static
actual model, with a generic icon only while its source has not replicated. Late
models hydrate automatically. Successful images dispose fallback geometry/listeners.
Destroyed views unsubscribe and pending loads cannot resurrect them. Camera fitting
uses all eight bounds corners and current aspect ratio.

CrusherTools adds only a CrusherType presentation attribute. The separate client
script sets native Tool.TextureId after a confirmed image load. Missing uploads keep
text slots. Backpack replacement/respawn rebind; number keys, equip, placement, held
model and tooltip are preserved. No custom backpack authority, server economy,
saves, RemoteEvent or shared game number changes. Existing Shared.Icons image IDs
and MAX upgrade button work are preserved.

Upload PNGs to this experience's Asset Manager with exact names Crusher_<TypeId>.
CrusherIcons.Overrides accepts actual image content IDs if named aliases do not
resolve. Do not use private-decal thumbnails. Verify using verify_uploads.luau,
then restart Play (failed results are cached for the running session).
Asset aliases are documented at https://create.roblox.com/docs/projects/assets.

Studio is not connected here. Connected agent must verify uploads/moderation,
Index/Owned scrolling, silhouettes, both rewards tabs, quest shop, tool images,
equip/place, number keys, respawn and Output in fresh desktop Play. Five missing
special images intentionally retain model fallbacks. Phone work remains deferred.

## Connected integration — 25 October 2026

Merged the complete ZIP with newer Index recycling/MAX and progression work.
Preserved coating details in model fallbacks by passing the instance modifier
to CrusherIcon and applying CrusherFinish before camera fitting. The recent
hidden-stair CanQuery fix and existing Shared.Icons IDs remain unchanged.
All 35 supplied PNG hashes, 512x512 RGBA headers and unique image IDs verified.

The user explicitly approved uploading and connecting the 35 portraits. Studio's
upload connector returned image content IDs, now in CrusherIcons.Overrides and
assets/crusher-icons/manifest.json. Checked sample metadata identifies Image
assets owned by account 124358167; these were not named experience aliases.
Fresh Play's content check returned 0 loaded / 35 failed / 5 missing special
portraits. Inserting one uploaded image through the connector also failed its
metadata lookup. This does not establish whether processing or asset permissions
are responsible. Do not upload duplicate copies to work around the issue.

Manual completion: check processing/moderation in Asset Manager/Creator Hub,
grant the experience permission to the uploaded assets where needed, and rerun
tools/crusher-icons/verify_uploads.luau in fresh Play. Roblox documents private
asset permissions at https://create.roblox.com/docs/projects/assets/privacy.
Only treat the portraits/native hotbar images as verified after 35 load.
The five absent imported-model PNGs still need actual source mesh exports.

Studio Index/Owned displayed safe actual-model fallbacks and black silhouettes;
six visible Owned fallbacks retained finish details. Three close/reopen cycles
released all icons while closed and returned to ten visible icons each time.
Native backpack Tools remained present. All 5,613 progression/row/rules/upgrade/
spin/quest/roll suite checks passed, and Rojo/whitespace checks passed. Output
on the last Play contained the existing asset 203785492 warning, with no new
game-script errors. No inventory test injections or purchases were used.

Uploaded portrait appearance/transparency, hotbar pictures/number-key/respawn,
both reward tabs, quest-shop interaction and full streaming/device review remain
unverified. Python/Luau CLI helpers were not run on this machine. Studio returned
to Edit mode; nothing was published. Code/assets remain uncommitted.

## Load issue resolved — 25 October 2026

After the user shared the images with the group and experience, fresh Play
still reported failure from raw URI preloads. An actual ImageLabel probe loaded
the same portrait successfully. The raw-ID check was misleading and cannot
establish that earlier failures were caused by asset permissions or moderation.

CrusherIcon.ready and verify_uploads now preload a disposable ImageLabel per
URI, supplying image content context, and destroy it afterward. Shared caching,
fallbacks and unsubscribe behavior remain. The offline adapter accepts these
image objects; the CLI suite was not rerun on this machine.

Fresh Play verified 35 loaded / 0 failed / 5 missing special portraits. The
Index displayed loaded portrait art with black undiscovered silhouettes; ten
native tools had image textures and the one remaining tool, Magnetron, correctly
had no portrait. The corresponding manifest records uploaded-verified-in-studio.
This supersedes the pending-load/manual-permission status above. No more asset
permission changes or reuploads are required for these 35. Output contained only
the existing asset 203785492 warning. Rojo build and whitespace checks passed.
