# Eternal crushers (proposed tier, not in the game yet)

Six models planned (ChatGPT pack 8 Nov: ChronoColossus, Worldbreaker, InfinityEngine, AstralLeviathan,
RiftMonarch, RealitySplitter): a rollable tier above Divine, below Mythic. **Not added:** no rarity,
odds, types, Index entries or economy yet; that waits for Willem's call on the tier.

## Astral Leviathan (9 Nov), the first upgraded model
- Source: Hunyuan3D image-to-3D prototype of Willem's concept (100k faces, 4K PBR).
- Claude's Blender pass (Blender 5.2 via the Blender MCP on Willem's PC):
  welded the generator's split mesh, cut the upper head free at the gold cheek hinge (straight planes,
  both gold discs stay on the Frame), filled the cuts with the armour navy, removed a floating sliver,
  decimated to Frame 6,000 + UpperJaw 3,000 triangles, colour texture 4K -> 1024.
- Motion: the head rests tipped 12 degrees up (baked into the FBX) and bites 32 degrees down about the
  hinge, where upper and lower teeth meet. Input sits in the mouth (`inputCenter`, size 0.32).
- Files: Willem's PC, Downloads\CrushIt-Coating-and-Plot-Props\AstralLeviathan (FBX, PNG, game-ready
  .blend with the prototype hidden inside, manifest.json, previews).
- Studio: template `ServerStorage.SpecialCrusherMeshes.AstralLeviathan` (Willem's import, cm scale,
  place file: **Willem must publish**). Metadata `shared/EternalCrusherAssets.luau` (motion format).
- Test: DEV panel "Eternal preview (bay 1)": Astral Leviathan / Clear. Checked in Play: textured, faces
  the walkway, fit 1.57 (9.4 studs tall), the head swings 0 -> 32 degrees down every 2 s, no errors.
