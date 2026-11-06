# Feedback survey

One-tap survey (client/Feedback.client.luau, server/Feedback.luau, Shared/FeedbackConfig.luau), added 5 Nov.

- Pops up once per save after `AskAfterMinutes` (10) of play in a session, after the tutorial, when no other window,
  cutscene or event is up. The FEEDBACK button on the Rewards > Codes tab opens it any time.
- Page 1: LOVE IT / IT'S OK / NOT FUN, logged as custom event `FeedbackRating` (value 3/2/1). Custom Field 1 =
  LoveIt / ItsOk / NotFun since 6 Nov (before: the label; "IT'S OK" showed as N/A).
- Page 3 (6 Nov, Willem: 59% likes): after LOVE IT, "Could you give Crush It a 👍 LIKE on the game page?" with
  SURE! (goes on to page 2). No reward: rewarding likes/favourites is discouraged (vault Community Building).
  Logged as `FeedbackLikeAsk`.
- Page 2: wishes (more crushers, faster progress, cheaper shop, less confusing, more with friends, it's great),
  tap any, each logged once as `FeedbackWish` (Custom Field 1 = key).
- Fixed answers only, no typed text (nothing to filter).
- First numbers (7 days to 6 Nov): 31 LOVE IT, 12 IT'S OK, 10 NOT FUN unique users; 54 wishes, top "it's great" 13,
  faster progress 10, more crushers 10.

Read it in Creator Analytics > Explore > Custom events, aggregation Count Unique Users, breakdown Custom field 1.
