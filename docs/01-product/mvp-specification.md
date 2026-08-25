# MVP specification

## 1. Objective

Build the smallest product that can test whether private purchase dilemmas create a completed social learning loop.

The MVP is successful only if users create, friends vote, owners resolve, owners reflect later, and voters view the Reveal.

## 2. Release slice

### Included

- adult-only onboarding and account creation for owners;
- manual dilemma creation;
- image upload or product link;
- item name, price/currency, category, reason, and pause window;
- purchase purpose: for self or gift;
- optional private owner self-prediction behind an experiment flag;
- offline local draft with explicit review/publish after reconnection;
- private unlisted invite link;
- guest recipient landing page and vote;
- one-dilemma guest Reveal subscription after voting, with separate consent;
- optional 280-character vote reason;
- results hidden until vote or voting closes;
- owner decision update: Bought original, Bought alternative, Skipped, Item unavailable, Still deciding;
- category-aware bought follow-up after 7 or 30 days; 90-day capability stored but not enabled by default;
- skipped follow-up after 7 days;
- return/refund and gift-specific reflection handling;
- “Would you make the same choice again?” resolution;
- participant Reveal;
- private owner history and voter prediction history;
- minimal push/email notification orchestration;
- revoke link, delete dilemma, report, block, and account deletion;
- analytics events defined in the metrics document.

### Excluded

- public feed, discovery, hashtags, followers, DMs, or open comments;
- bank/Open Finance connections;
- automated financial advice;
- AI verdicts, summaries, or personal predictions;
- brand accounts, ads, affiliate links, sponsorships;
- global leaderboards, XP, coins, or daily streaks;
- web product as a full creator experience—the web surface exists for guest voting and Reveals;
- minors;
- multi-item comparisons, subscriptions, resale, and 90-day long-horizon follow-ups as active flows.

## 3. Roles

| Role | Capabilities |
|---|---|
| Owner | Creates and manages dilemmas, sees private results, records decision and reflection, controls visibility |
| Authenticated participant | Votes, receives Reveal, maintains prediction history, reports content |
| Guest participant | Opens invite link, chooses temporary display name, votes once, may opt in to this dilemma's Reveal, and may claim history after account creation |
| Moderator/operator | Reviews reports, hides content, revokes abusive links, suspends accounts, audits actions |

## 4. Functional requirements

### FR-01 Account and eligibility

- Owner confirms they are an adult and accepts Terms and Privacy Notice.
- Sign-in uses email magic link or Apple/Google where available.
- A guest can vote without account creation.
- Age policy and legal wording must receive counsel review before public release.

### FR-02 Create a Temptation

Required:

- item name, 2–80 characters;
- price greater than zero and ISO currency;
- category;
- reason, 10–500 characters;
- pause window: 24 hours, 3 days, or 7 days.

Optional:

- one image;
- product URL;
- how long the owner has wanted it.
- purchase purpose `for_self` or `gift`, defaulting to `for_self` but always visible;
- private owner self-prediction in the active experiment: Yes / Not sure / No to “Do you expect Future You to make the same choice again?”

Acceptance criteria:

- A valid dilemma can be published in under two minutes in usability testing.
- Draft survives app interruption.
- Creation works offline as a local draft.
- An offline draft is labeled **Draft—not shared yet** and is never silently published when connectivity returns.
- After reconnection, the owner reviews and explicitly publishes the draft.
- Owner sees exactly what recipients will see.
- Visibility defaults to private/unlisted.
- Sensitive information warning appears near free text and image upload.

### FR-03 Invite and access

- Publishing creates a high-entropy, unguessable invite token.
- Owner can share through the native share sheet.
- Link opens a mobile web page when the app is absent and the app detail when installed.
- Owner can revoke and regenerate access.
- Link previews disclose item name/image only if owner explicitly enables previews; default preview is generic.

Acceptance criteria:

- Revoked link no longer displays dilemma content.
- Search engines are instructed not to index invite pages.
- Private content never appears in a public listing or sitemap.

### FR-03A Guest Reveal subscription

- After voting, a guest may subscribe to this dilemma's Reveal by providing an email address or creating an account.
- Consent is specific to the one dilemma and is not bundled with marketing.
- The guest can unsubscribe from the confirmation and every delivery.
- If no account is created, the routing address is deleted after Reveal delivery plus a short operational grace period defined in the retention policy.
- Subscription failure never invalidates the submitted vote.

### FR-04 Vote

Question: **“What will Future [name] be glad they did?”**

Options:

- **Buy — likely glad**
- **Wait — too soon**
- **Skip — likely glad**

Rules:

- one active vote per participant identity/device token;
- participant may change vote until owner records a decision;
- optional reason up to 280 characters;
- aggregate results appear only after voting or when the vote window closes;
- “Wait” counts as participation but not prediction accuracy.

Acceptance criteria:

- Median guest vote completion time is under 20 seconds.
- A user cannot infer other votes before submitting through supported UI/API paths.
- Owner may hide an abusive reason without changing the vote count.

### FR-05 Decision update

- Owner records Bought original, Bought an alternative, Skipped, Item unavailable, or Still deciding.
- Bought alternative may capture an optional alternative price, but the product does not label it smarter or claim verified savings.
- Owner may decide before timer completion.
- “Still deciding” schedules one reminder and allows a new target date up to 30 days.
- Decision locks confident predictions for later scoring.

Acceptance criteria:

- Participants receive at most one aggregated decision update.
- Owner can correct an accidental decision within a short grace period; the audit history remains internal.

### FR-06 Reflection

Follow-up schedule:

- Short-lived/consumed categories: 7 days.
- Durable categories: 30 days.
- Long-horizon categories: store a 90-day rule, but keep it disabled until the timing experiment passes.
- Skipped and unavailable decisions: 7 days.

Bought-original flow:

- Did you keep it? Kept / Returned or refunded.
- If returned/refunded, capture the reason optionally and do not treat the purchase as a normal satisfaction sample.
- Would you make the same choice again? Yes / Not sure / No.
- Optional note: “What happened compared with what you expected?”

Skipped flow:

- Glad I skipped / Still want it / Bought an alternative / Original became unavailable.
- Then: Would you make the same choice again? Yes / Not sure / No.

Gift flow:

- Did choosing this gift feel worthwhile? Yes / Not sure / No.
- Optional note about the recipient response.
- Exclude gift outcomes from self-use satisfaction insights.

All flows:

- “Too early to tell” reschedules once and remains unresolved for scoring.

Acceptance criteria:

- Completion takes under 30 seconds.
- Owner previews exactly what will be shared in the Reveal.
- Owner may keep the reflection private; in that case voters receive “closed without a shared result” and no accuracy score.
- In the owner self-prediction experiment, the owner receives a private comparison of their expectation, group prediction, and outcome after completing reflection. It is not automatically shared in the Reveal.

### FR-07 Reveal and scoring

Reveal includes:

- item and owner;
- decision;
- make-same-choice-again answer;
- owner-approved note;
- vote distribution;
- participant's own vote;
- accuracy outcome for Buy/Skip predictions when resolution is unambiguous.

Scoring rules:

- Buy is correct only when owner bought and answered Yes.
- Skip is correct only when owner skipped and answered Yes.
- Bought-alternative, unavailable, returned/refunded, gift, and “too early” outcomes remain unscored until explicit scoring rules are validated.
- All other combinations are unresolved/incorrect pending product validation; do not fabricate precision.
- Wait is never marked wrong.
- Accuracy is hidden until at least five resolved confident predictions.

### FR-08 Histories

Owner history shows all own dilemmas and states. Participant history shows joined dilemmas that have not been deleted and the participant's vote. Basic counts must not imply causal financial insight.

### FR-09 Notifications

- Decision reminder at timer completion.
- One decision follow-up after 48 hours if incomplete.
- Reflection reminder when due and one reminder after 72 hours.
- Reveal notification to participants.
- Optional “voting closes soon” reminder only for participants who opened but did not vote and consented to messages.

Quiet hours and per-category opt-outs are required. No notification celebrates spending or shames skipping.

### FR-10 Safety and control

- Report dilemma or vote reason.
- Block owner/participant.
- Hide reason.
- Revoke invite link.
- Delete dilemma and account.
- Operator can hide, suspend, and retain minimal abuse evidence under documented policy.

## 5. State model

Primary path:

`draft → collecting_votes → decision_due → {bought_original | bought_alternative | skipped | unavailable} → reflection_due → {revealed | closed_private}`

`still_deciding` returns to `decision_due` at its new deadline. Active dilemmas may also become `expired` or `deleted` under the lifecycle rules.

Only the owner can transition decision states. Scheduled jobs transition to due/expired states but never decide for the owner.

## 6. Screen consolidation

The MVP uses eight primary surfaces:

1. Onboarding/sign-in
2. Home: active, needs action, recent Reveals
3. Create/edit Temptation
4. Dilemma detail: owner and participant variants
5. Guest vote web page
6. Decision/reflection sheet
7. Reveal
8. Profile/history/settings

Prediction score is part of profile; activity is part of Home. No separate public feed or analytics dashboard.

## 7. Quality attributes

- **Privacy:** private/unlisted by default; least-privilege access enforced server-side.
- **Accessibility:** target WCAG 2.2 AA principles for web and equivalent mobile semantics, focus, contrast, text scaling, reduced motion, and non-color cues.
- **Reliability:** scheduled decision/reflection jobs are idempotent and observable.
- **Offline clarity:** offline capture never implies that an unpublished draft has been shared; reconnect requires explicit owner review and publish.
- **Performance:** guest page usable on a mid-range mobile connection; image thumbnails optimized.
- **Localization:** Portuguese first; all money stored as integer minor units plus ISO currency; dates stored in UTC and presented in local timezone.
- **Deletion:** user-visible deletion begins immediately and completes across primary systems within the documented retention window.

## 8. Release gates

### Product gates

- Concierge/prototype evidence meets at least four of six core hypothesis thresholds.
- At least three of five test groups complete one full Reveal cycle.
- At least 70% of interviewed owners describe the tone as non-judgmental.

### Safety gates

- Threat model and abuse-case review complete.
- Link revocation, authorization, deletion, report, and block tests pass.
- Privacy notice, Terms, retention schedule, age approach, and incident process reviewed.
- No known critical or high-severity security findings.

### Experience gates

- Create median under two minutes.
- Guest vote median under 20 seconds.
- Reflection median under 30 seconds.
- Critical flows pass screen-reader, large-text, keyboard/web, contrast, and reduced-motion checks.

## 9. Definition of done for the MVP hypothesis

After an eight-week closed beta:

- at least 40% of invited owners create a dilemma;
- at least 50% of invite-link visitors vote;
- at least 70% of dilemmas record a decision;
- at least 50% of eligible dilemmas record reflection;
- at least 50% of notified voters view a Reveal;
- at least 30% of voters participate in a second dilemma;
- reports remain below 2% of participating users, with all high-severity reports actioned within 24 hours.

These are decision thresholds, not market forecasts. Failure should trigger iteration or stop, not metric reinterpretation.
