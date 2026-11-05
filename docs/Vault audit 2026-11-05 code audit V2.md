# Code audit with LihFolk Vault V2 (5 Nov 2026)

Method: V2 `commands/audit.md`: the checker rules (`hooks/scripts/rules.tsv`, applied by hand with grep because
running V2's scripts was blocked), then the skills roblox-secure-remotes, roblox-datastore-safety,
roblox-anti-exploit-review, roblox-monetization-compliance and roblox-performance-audit over `src/`.
Notes used: API Renames and Deprecations 2025-2026, Analytics and Funnels, Game Passes, Subscriptions and
Premium Payouts, Text Chat Customization with TextChatService, Developer Products and ProcessReceipt.

## Result: no P0 (nothing loses or duplicates data or purchases, no client-owned money)
- Remotes (19 handlers): server computes every price and reward; rate limits on the value-moving ones
  (Quests, Codes, Turbo, DailySpin, Travel, CrusherAction, FactoryEvents, Frenzy taps capped per second);
  state locks on the rest (daily, index rewards, free boost). No InvokeClient. Dev tools only in Studio;
  `/credits` only for Studio or the place owner.
- Data: session lock, UpdateAsync, retries, autosave, BindToClose, no save after a failed load (SaveOff).
- Receipts: grant and remember PurchaseId without yielding, Granted only after a confirmed save, purchase log.
- Crates: PolicyService gate (fails closed), odds shown before purchase.

## Fixed in this pass
| Prio | Finding | Fix |
|---|---|---|
| P2 | `ShopOpened` put any client text into an analytics custom field, no rate limit: anyone could flood the 8,000 value combinations and break the shop funnel breakdowns we rely on | Whitelist of the names the game sends (else "Other"), max 1 per 0.5 s |
| P2 | `UserOwnsGamePassAsync` failing once at join switched a paid pass off for the whole session | 4 tries with backoff |
| P3 | 10 renamed APIs (GetProductInfo, IsInGroup, IsFriendsWith) | `...Async` names |
| P3 | TrashMany counted `#ids` but iterated every key | only the counted list part |

## Open (not fixed)
- **Chat tags stop working:** `TextChatMessage.PrefixText` is unsupported under platform-integrated chat
  (default Feb 2027, required May 2027). The [VIP]/[PLUS] tags must move to an overhead name tag or Roblox's
  native prefixes (planned early 2027) before then.
- Notification package uses `OpenCloudService:InvokeAsync` (deprecated Jul 2026, no replacement named, still works).
- Referral: if the inviter's mailbox write fails after the invitee's claim is stored, the inviter misses that
  reward (rare; claim is not retried).
- `/credits` works for the owner in live servers: it puts test cash into the leaderboard and economy analytics.
- Performance: about 34 client scripts each with their own Heartbeat/RenderStepped (static, not measured).
  Measure on a phone with the MicroProfiler before changing anything.
- Purchase receipt UI (vault QoL): a "processing" state between the Roblox window and the grant.

## Added
- Roblox Plus card (Shop > Passes): `PromptRobloxSubscriptionPurchase`; Roblox pays 250 R$/month for 3 months
  per subscriber who signs up through it. Perk: [PLUS] chat tag (cosmetic only, as the vault requires).
