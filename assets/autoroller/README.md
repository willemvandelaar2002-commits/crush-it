# Auto Roller coloured art (7 Nov)

Made from Willem's grey Rarity-Tab / Crusher-Card art (CrushIt-AutoRoller-Component-Art) by `tint.py`:
each rarity gets a ready-coloured tab and a purple card with a rim in the rarity colour (like the
design reference). Roblox can only darken an image with ImageColor3, so tinting the grey art in game
looks dull; these are coloured beforehand.

Upload all 18 PNGs (Creator Hub / Asset Manager bulk import) and put the ids in
`src/client/AutoRoll.client.luau` → `ART.Tabs`, `ART.Cards`, `ART.BuyOn` (Tab-Buy), `ART.BuyOff` (Tab-Off).
Until then the window uses the grey art with a tint.
