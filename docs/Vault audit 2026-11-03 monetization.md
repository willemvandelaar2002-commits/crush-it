# Monetization vs the vault (3 Nov 2026)

Willem: "nobody has bought anything yet". Checked against Monetization Overview, Pricing and Store Design, Robux Price
Points and Offer Design, Game Passes, Genre Playbook - RNG and Collection Games, Ethical Design and Player Trust
(Roblox docs as of October 2026 plus rules of thumb).

## Context first
- Revenue = players reached x retention x payer conversion x spend per payer (vault). Players so far: a few hundred,
  almost all from cheap sponsored ads, most on phones, short sessions. Zero buyers in that group is low but not
  shocking; the shop funnel (Opened -> Saw a Robux price -> Bought, Creator Dashboard) will say where it stops.
- Vault build order: loop worth paying for -> 2-3 permanent passes -> starter pack -> currency packs -> rewarded
  video -> subscription -> live offers. We have passes, a strong starter pack and cash packs.

## What is right
- One ProcessReceipt, prices from GetProductInfo, purchase log, id 0 = COMING SOON, PolicyService on the crate,
  odds shown, pop-up gate, honest texts (fixed 3 Nov).
- Ladder: impulse items under 100 (cash 19/59/129 with rising value, boosts 19-29, Auto Collect 99, starter 69),
  core passes 149-249, a direct-sale Mythic at 399.
- Starter pack (69): a Mythic crusher + 30 min of cash + a boost, once per player: clearly the best value (vault).

## Why nobody buys (most likely first)
1. **Phones can't really use the shop.** 70%+ of players are on phones; the shop panel shrinks to 48%: 22 texts at
   8-10 px, tabs 20 px tall, close button 30 px (measured 3 Nov at 750x381). Vault: "Phone first. The shop needed a
   dedicated phone layout with 54 px minimum tap targets."
2. **The starter pack is never offered.** It sits in the shop's FEATURED tab. Vault: show it once after a good
   moment (after the tutorial, a first Epic+, Factory II), through the pop-up gate, max one unprompted offer in a
   first session. We show no offer at any moment.
3. **No "starter shop" for non-payers.** The shop opens on 5 tabs and many cards. Vault: for players who never
   bought, open on a short page (starter pack, one cheap pass, one cash pack); long lists paralyse first buyers.
4. **The genre's best sellers are missing.** RNG games sell speed and social luck: Fast Roll / Double Roll passes,
   a VIP pass (399), and a **server-wide luck boost** (everyone in the server gets 2x luck, the buyer is announced -
   social visibility sells, vault). Our luck/cash products are personal and cheap. The core 299-599 rung is empty
   except one Mythic.
5. **4 of 5 Mythic direct sales have product id 0** (Jackpot Press, Seraph Press, Phantom Pirate, Candy Colossus):
   they show COMING SOON. Direct-sale exclusives are the cleanest RNG monetization (vault).
6. **Turbo is cash-only.** An instant Robux Turbo (e.g. ULTRA x8 15 min) is a natural consumable at the moment a
   player wants speed.

## Plan (ranked)
1. Phone shop layout + a short "starter" page for non-payers (starter pack, Auto Collect 99, Cash Pile 19).
2. Starter pack offer card once, after the tutorial is done and the first goal reward (pop-up gate, dismissible).
3. Server Luck product (99): 2x luck for everyone in the server for 15 min, buyer announced server-wide.
4. VIP pass (399): x1.5 cash, +1 roll pedestal, VIP tag; and/or Double Roll pass (two results per roll).
5. Willem: create the 4 missing Mythic products on the dashboard (or hide them).
6. Robux Turbo consumable at the Turbo pump.
