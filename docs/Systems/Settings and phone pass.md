# Settings, vibration and the 6 Nov phone pass

## Settings menu (client/Settings.client.luau, server/Settings.luau, Shared/SettingsConfig.luau)
- Blue gear "SETTINGS" at the end of the top-left button row (Style.HudRow / Style.placeAfterHudRow), shown when
  the Shop button is shown (the HUD appears step by step in the tutorial).
- Rows: MUSIC (ON / LOW / OFF), SOUNDS (ON / LOW / OFF), SCREEN SHAKE (ON / OFF), EFFECTS (AUTO / LOW / HIGH),
  VIBRATION (ON / OFF, only on touch screens and controllers).
- Saved in the profile as `d.settings` (only non-default values, validated on the server), mirrored to attributes
  `Set_<key>`, so they follow the player to every device. The client sets the attribute at once; the server saves
  and confirms.
- Music / Sounds: SoundGroups `Music` and `Sounds` under SoundService. Every Sound in SoundService, Workspace and
  PlayerGui is put in one (music by name: BackgroundMusic, EventMusic); the group volume is the setting, so no
  other script needs to know.
- Screen shake: `Style.shakeOn()`; checked by Main (CrushShake), BigRoll, FactoryEvent (boss intro) and Mega.
- Effects: `Style.lite()` reads `Set_Effects` first (Low = phone trims, High = everything even on a phone, Auto =
  device guess). client/PhoneLite now remembers what it changes and puts it back, so switching works both ways
  without a rejoin.

## Vibration (client/Haptics.client.luau)
HapticEffect (Roblox's newer API; the old HapticService is deprecated): Tick (UIClick), Buzz (UINotification),
Rumble (GameplayExplosion) in Workspace.Haptics. Your roll: Tick. Your Legendary+ (RarePull): Buzz. Your
Secret/Divine big roll: Rumble now and again just before the reveal. Plot upgrade: Rumble. Purchase: Buzz.
Golden toy grabbed: Tick. At most one of each per 0.25 s. Off with VIBRATION. Only on touch/gamepad. Not testable
in Studio: check on a real phone.

## Phone pass findings (Studio at 1636 x 498 = the phone layout; positions projected to 667x375, 800x360,
844x390, 932x430)
- The right-side offers (2X CASH ladder button, featured pass) were hidden on phones: the cash ladder is now a
  rainbow icon button "4X CASH" in the top-left row on small screens (Shop.client, PhoneCashButton).
- Active boost chips sat on the Friend Boost line (y 164 vs 158-180): moved to y 186.
- Shop on an iPhone SE shrank to half size (68 texts under 12 px, smallest 7.6 px). On phones it is now scaled by
  width only and made shorter (the page scrolls): 10 texts under 12 px, smallest 10.5 px.
- Other windows at iPhone SE size: all fit; smallest texts Rebirth 10.7 px, Starter Pack and Boosts 11.5 px, Index
  11.8 px (12 small "CRATE ONLY" tags). Left as is.
- Not checked: real-device feel, Roblox's own touch controls (jump button, thumbstick) over our HUD, notch insets.

- Lucky Weekend / Server Luck pills (top right, in the way on phones): on phones the countdown is hidden and the
  active weekend / Server Luck / Divine luck show as chips at the top of BoostsHud.ActiveBoosts (WeekendHud).
- Goals on phones (Tutorial.placeHeadline): in the free part of Roblox's top bar (GuiService.TopbarInset), tag +
  title + counter only (no hint line), scaled to fit (needs at least 0.4); tutorial steps stay under the button row.

## Phone HUD layout (6 Nov, Willem)
- Style.hudSlotPosition: on phones the HudRow buttons are a vertical column (Style.PhoneHud: 42 px, gap 4, a
  second column when the screen is short; `bottom` keeps room for cash). Buttons store their slot as attribute
  HudSlot (placeAfterHudRow uses it).
- CashHud: cash and Friend Boost bottom left on phones. Boost chips right of the column; FREE CASH GIFT right of
  REWARDS. SMASH phone scale 0.58.
- Style.topRightY: Equip Best / Mega Crusher (Travel Row) and the SETTINGS gear (icon only, far right) go up into
  Roblox's top bar when its right end is free (GuiService.TopbarInset), else just under it. The goal in the top
  bar stays left of them.
- Studio: /nopasses (play as if you own no passes, this session) and /passes (back to your real passes).
- 11 Nov (Willem: "make the settings button smaller and put it somewhere else ... not block in roblox"): on PC the
  gear is a small 40 px icon (no label) at the right end of Roblox's top bar, inside GuiService.TopbarInset (the part
  Roblox leaves free for games), so it never covers Roblox's buttons or the player list below the bar. Phones: as
  before (top right in the bar, Mega Crusher left of it).
