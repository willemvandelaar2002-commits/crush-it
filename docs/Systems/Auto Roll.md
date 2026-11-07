# Auto Roll and Auto Buy (7 Nov, Willem)

- **AUTO ROLL** is free for everyone after the tutorial. It runs on the server (server/AutoRoll), so it keeps
  rolling wherever you walk: roll -> wait for the reveal (and any big-roll cinematic) -> if a pedestal shows the
  chosen rarity or better (C.AutoRoll.Choices: Rare, Epic, Legendary (default), Limited, Secret; "Limited+" also
  stops on Secret/Divine) it **stops** with a notice ("a Legendary Toyzilla is on your pedestal!"), otherwise it
  rolls again (C.RollSeconds apart, like by hand).
- **AUTO BUY** is a game pass (Store perk "AutoBuy", R$ 149 suggested, id 0 until Willem creates it): with it on,
  Auto Roll buys the best offer it stops for and keeps going; if that fails (cash, full inventory) it stops and
  says why. The server checks the pass; losing it switches auto buy off.
- HUD (client/AutoRoll): Willem's art (bar 140479169859430; AUTO ROLL button blue 118340677613688 / green 111686894944891 in the see-through first slot), above the crusher hotbar: AUTO ROLL on/off, STOP AT (tap to cycle, in the rarity
  colour), AUTO BUY (a lock that opens the pass purchase without the pass; hidden until the pass exists).
  Phones: the same bar at 0.62 scale. Shown with the Shop button.
- State in attributes AutoRoll / AutoRollMin / AutoBuy (not saved: auto roll starts off each session).
- Remote "AutoRoll"(on, min, buy). Shop funnel source "AutoBuyButton".
