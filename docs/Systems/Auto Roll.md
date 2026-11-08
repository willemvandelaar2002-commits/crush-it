# Auto Roll and Auto Buy (7 Nov, Willem)

- 7 Nov (later, Willem's reference video): the player TICKS rarities (C.AutoRoll.Rarities; Legendary, Limited,
  Secret, Divine by default) instead of one "and up" rarity; it stops on / auto-buys any ticked rarity.
- 7 Nov (Willem: "make the crushers individually clickable anyway"): tapping a crusher card targets just that
  crusher. Picks are rarity names and crusher ids; the tick box = every crusher of the rarity (it clears single
  picks of that rarity), tapping a card of a ticked rarity unticks it and keeps the others, picking every crusher
  of a rarity becomes the tick again. A number in the tick box = how many single crushers are picked. The server
  only accepts crushers of the window's rarities (max 100 entries).
- **AUTO ROLL** is free for everyone after the tutorial. It runs on the server (server/AutoRoll), so it keeps
  rolling wherever you walk: roll -> wait for the reveal (and any big-roll cinematic) -> if a pedestal shows the
  chosen rarity or better (C.AutoRoll.Choices: Rare, Epic, Legendary (default), Limited, Secret; "Limited+" also
  stops on Secret/Divine) it **stops** with a notice ("a Legendary Toyzilla is on your pedestal!"), otherwise it
  rolls again (C.RollSeconds apart, like by hand).
- **AUTO BUY** is a game pass (Store perk "AutoBuy", R$ 89 suggested, id 0 until Willem creates it): with it on,
  Auto Roll buys the best offer it stops for and keeps going; if that fails (cash, full inventory) it stops and
  says why. The server checks the pass; losing it switches auto buy off.
- HUD + window (client/AutoRoll, 7 Nov): Willem's AUTO ROLL button (blue off / green on) just left of the crusher hotbar (follows its left edge as it grows) opens the
  **Auto Roller** window: title bar (dice, X), rarity tabs with tick boxes on the left, the viewed rarity's crushers
  with odds (??? if not discovered) in the middle, START / STOP, and the Auto Buy box (price button, then ON/OFF;
  SOON while the pass has id 0).
- On the roll machine (8 Nov, Willem: a separate console stood in the stairs on bigger plots, then in front of
  the trash can; two panels side by side looked bad): one ROLL A CRUSHER panel, its ROLL button a bit narrower
  with a smaller blue AUTO button on its right (Action "AutoRoll", CrusherHud -> AutoRollHud.Open). The HUD
  button only shows while Auto Roll runs ("AUTO: ON").
- Art (7 Nov, Willem's CrushIt-AutoRoller-Component-Art): backplate 88560195984273 (960x600 window, positions are
  fractions of it), rarity tab 89940482051531 and crusher card 109318241376424 (grey, tinted per rarity; the card is
  9-sliced), START 137227985984200, STOP 122128869328114, Auto Buy panel 112110722481101 (its button is the tab art,
  green / grey). The design reference (85952094260378) is not used. Uploads are 1023 px wide, so the ImageRect
  values are in those pixels. Text, ticks, the viewing outline and the target outline are live on top.
- Colour (7 Nov): ImageColor3 can only darken the grey art, so assets/autoroller holds ready-coloured tabs and
  cards per rarity (tint.py; cards purple with a rim in the rarity colour, like the design reference). Their ids go
  in ART.Tabs / ART.Cards / ART.BuyOn / ART.BuyOff; empty = grey art + a brightened tint.
- Card pictures are CrusherIcons, the same images as the Index; undiscovered crushers are black there too.
- (before:) HUD (client/AutoRoll): Willem's art (bar 140479169859430; AUTO ROLL button blue 118340677613688 / green 111686894944891 in the see-through first slot), above the crusher hotbar: AUTO ROLL on/off, STOP AT (tap to cycle, in the rarity
  colour), AUTO BUY (a lock that opens the pass purchase without the pass; hidden until the pass exists).
  Phones: the same bar at 0.62 scale. Shown with the Shop button.
- State in attributes AutoRoll / AutoRollPicks / AutoBuy (not saved: auto roll starts off each session).
- Remote "AutoRoll"(on, picks (list of rarity names and crusher ids), buy). Shop funnel source "AutoBuyButton".
- SKIP ANIMATION (8 Nov, Willem): a toggle right of "Tap crushers to target them" (attribute AutoRollSkip, 4th
  argument of the AutoRoll remote, not saved). While Auto Roll runs with it on, server/AutoRoll sets ctx.fastRoll
  for its roll: the pedestal reveal takes C.AutoRoll.RevealSeconds (0.3 s) and the next roll comes after
  C.AutoRoll.SkipSeconds (1.5 s, normal 3). Measured: 4 rolls / 15 s normal, 9 with skip. Big cinematics
  (Limited, Secret, Divine) still play. Manual rolls are unchanged.
