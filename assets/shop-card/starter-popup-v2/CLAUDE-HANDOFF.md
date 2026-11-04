# Starter-pack popup V2: independent animated buttons

Read CLAUDE.md and docs/Home.md first. Implement this against the current client-side starter-offer controller. This pack supersedes the earlier one-image backplate. Do not use the old StarterPack-Backplate.png: its buttons were baked in.

## Three assets to upload

| Filename | Use |
| --- | --- |
| StarterPack-Background.png | Static decorative panel with the purchase/close areas cleared |
| PurchaseButton.png | Separate green glossy ImageButton |
| CloseButton.png | Separate red glossy ImageButton; add native X text |

Use only real returned Roblox image IDs supplied after upload. Design-Reference.png shows the approved original design, not the working UI. No new crusher/cash/boost icons are required: reuse existing mappings, including the actual Candy Colossus icon. The reference's candy crusher is conceptual, not a replacement model. No Blender assets or ViewportFrames.

## Layout

Use a centered 4:3 root frame, initially around 760x570 on 1920x1080. Scale the WHOLE composition to fit available desktop space. Apply UIAspectRatioConstraint. Preserve the background's full canvas and alpha margins; do not crop or nine-slice it. The panel, header, rarity plaque and reward-card backgrounds remain static. Do not draw duplicate opaque panels.

layout.json supplies normalized x,y,width,height rectangles relative to the FULL background canvas, with top-left origin. Treat them as starting guides and visually verify in Studio. Background is 1448x1086. Button PNGs have been trimmed to remove excess transparent canvas while retaining a small edge margin. Use ScaleType=Fit so the red button remains square and green button retains its long shape.

Create stable transparent root Frames at each button rectangle. Center the corresponding ImageButton within each root (AnchorPoint=.5,.5; Position=.5,.5). Each ImageButton contains its own UIScale and text label. Text scales WITH the button. The roots stay fixed so the layout and surrounding art do not move. Use BackgroundTransparency=1, AutoButtonColor=false. Keep sufficient clearance for hover growth; parent ClipsDescendants=false where needed. No green or red duplicate button should remain under the animated image.

Use separate ImageLabels for crusher/cash/boost; Fit, transparent, above background. Use native outlined FredokaOne/established display typography for every label. Read actual runtime data for cash, price, multiplier and boost duration. Reference values $9K and R$69 are examples ONLY. Labels: SPECIAL OFFER; STARTER PACK; MYTHIC; CANDY COLOSSUS; Guaranteed crusher; live amount plus CASH; Instant cash; actual multiplier plus CASH; actual boost duration; GET STARTER PACK plus live price; Browse shop; X.

## Motion and input

- Green button: hover scale 1.035 over 0.12s, press scale 0.97 over 0.07s, release to hover/normal as appropriate. Red close button: hover 1.07, press 0.94. Animate the separate ImageButton and child text, never the full background.
- Track hover, pointer-down and selection state; cancel the previous tween before a new one. Handle release outside, MouseLeave, selection lost and popup close so buttons never remain squashed. Use Activated for existing purchase/close callbacks; do not trigger from hover. Guard duplicate activation and preserve existing pending-purchase behavior. Keep close available.
- Crusher icon may float +/-3px over about 3s, slight 1-degree tilt. Cash/boost can pop 4% on hover; no continuous distracting flashing. Cancel idle tweens while popup is hidden/destroyed. Respect any existing reduced-motion preference.
- Brief popup scale-in/backdrop fade is fine. Keep Browse shop a native transparent TextButton. Preserve keyboard/gamepad focus/selection if supported; no phone redesign in this pass.

## Preserve behavior

This is a visual change only. Reuse existing offer timing/cooldowns, eligibility, one-time ownership rules, dismissal, shop navigation, purchase callbacks and success handling. No new product, reward, pricing, auto-popup trigger or scarcity/countdown. Do not treat prompt closure as a completed purchase. Do not grant rewards client-side. Keep server scripts, Net, Config and Store unchanged. Preserve existing ShopHud/OpenShop/OpenOffer and other named UI contracts. Prefer reusing current ScreenGui/controller; any new ScreenGui uses ZIndexBehavior=Sibling. Preserve shared Style API and LF endings.

## Validate

In Studio Play, check image loading, no Output errors, aligned static and animated layers at 1920x1080 and 1280x720, all three icons showing, text staying inside panels, hover and press returning correctly after exit/close, close immediately dismissing, Browse shop opening the actual shop, existing purchase callback called exactly once, ownership/price/reward display intact. Stop all tweens and clean connections on teardown. Add a dated line to docs/Decisions log.md and show the result. This pack itself has not been tested in Studio and contains no installed game-code patch.
