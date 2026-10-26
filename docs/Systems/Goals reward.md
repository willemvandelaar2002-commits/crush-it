# Goals reward

26 October 2026: the free time-skip reward now requires BOTH board goals:

1. Favorite confirmation from the owning player's Roblox prompt/query.
2. Group membership checked on the server.

The existing `C.Goals` reward calculation, minimum, group ID and saved cooldown
remain unchanged. Liking the experience is optional: it is no longer presented
as a verified reward requirement. The first row is labelled FAVORITE THE GAME.

## Favorite flow and verification limit

This implementation uses client-reported favorite confirmation plus server-side
group membership.
`AvatarEditorService` operates on the local player's favorite state. A modified
client can forge a completion report; this is NOT an independently verified
server favorite/like check and the challenge is not proof against that.

The owning player clicks Favorite near their own board. `FavoriteStart` issues
a 120-second, session-local challenge over the existing CrusherAction/CrusherState
events. `client/FavoriteGoal` first attempts GetFavoriteAsync for an already
favorited experience. If unavailable/false it opens PromptSetFavorite and waits
for PromptSetFavoriteCompleted with AvatarPromptResult.Success. Click, cancel,
failure, timeout and permission denial alone never complete the goal. No new
inventory-read permission prompt is opened.

Only the outstanding challenge token can acknowledge that normal flow.
Confirmation consumes it; unsolicited, expired and replayed acknowledgements
are ignored. Fast already-favorited acknowledgements are not dropped by the
generic request interval. A new session starts unconfirmed and uses the same
favorite query/prompt flow; no unverified persistent favorite flag is saved.

The client ignores unrelated completions when its own prompt is not active,
suppresses double-clicks, times out stalled work and disconnects when its HUD
is destroyed. Timers and asynchronous reads check the controller generation.

## Claim flow

`GoalsReward.view` drives both the state snapshot and the board's claim state.
Claim is grey/ineligible until BOTH requirements and the existing cooldown pass.
The owner-local SurfaceGui mirrors the existing PurchaseState/hint attributes.

The server still enforces owning-station proximity. Claim requires favorite
confirmation, checks the saved cooldown, then holds a per-session claim mutex
while refreshing group membership. After the yielding API it verifies that the
same player session and profile are still active. The final gate and cash /
cooldown mutations are non-yielding. Overlapping requests cannot grant twice.
Group-check failures do not grant a reward. Repeated claims during cooldown do
not generate extra group queries. Existing `timeSkipAt` persistence is retained.

No new RemoteEvent names, reward values or profile migration were introduced.

## Validation

- 69 pure goal-gate/client lifecycle checks pass in the Luau CLI.
- 16 checks execute the actual server request-handler body with mocked services:
  successful claim, direct client flags, fast acknowledgment, cooldown replay,
  fresh negative membership, overlapping claims, stale/replaced profile,
  removed session and exception cleanup.
- Changed Luau files compile; diffs use LF.
- Studio Play was unavailable in the asset workspace. Test Roblox's real prompt
  success/cancel/error, an already-favorited account, joining during the session,
  claiming without either/both goals, repeated claims, rejoin and player removal.

Apply client, server, shared board construction and both new modules together;
do not install only the UI or only the reward gate. Preserve any newer work in
CrusherGame/CrusherHud when integrating the patch.

API references:
https://create.roblox.com/docs/reference/engine/classes/AvatarEditorService
https://create.roblox.com/docs/reference/engine/classes/GroupService

## Connected integration — 26 October 2026

Applied cleanly over the current Factory V/60-bay, fusion, MAX, icon-loader,
hidden-stair pointer and owner-row zoom fixes. Existing reward amount, minimum,
group ID, cooldown, saved fields and remote names remain unchanged.

Fresh Studio suites passed GoalsReward 69, CrusherRules 371, UpgradeView 441,
DailySpin 285, QuestRules 12, FactoryProgression 213, CrusherRows 1,756 and
RollPresentation 3,656 (6,803 total). The supplied 16 offline handler checks
were not separately rerun in this integration. Rojo build and whitespace passed.

On the actual owning player's board, server membership was true and favorite
confirmation false: FAVORITE THE GAME remained incomplete and the skip button
had Short/ineligible state. Repeated real remote claim requests carrying forged
favorite/group flags, and an unsolicited confirmation token, were rejected.
The saved timeSkipAt stayed at zero. Output contained the existing asset
203785492 warning and the test-suite success line, with no new game-script errors.

No profile injection, successful reward claim or change to the user's Roblox
favorites was performed. Actual prompt success/cancel/error, already-favorited
accounts, joining mid-session, a successful full claim and live rejoin remain
manual checks. Favorite confirmation retains the client-report limitation above.
Studio was returned to Edit mode; nothing was published or committed.
