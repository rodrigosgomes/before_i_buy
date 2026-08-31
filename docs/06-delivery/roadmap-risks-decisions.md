# Roadmap, risks, and decisions

## 1. Delivery recommendation

Per DEC-004, the project starts directly with code rather than making concierge validation a prerequisite. Product evidence is therefore collected during the controlled closed beta, and the MVP release gates remain mandatory before expansion.

## 2. Roadmap

### Phase 0 — Archived evidence plan (not a prerequisite)

This phase is not required before implementation under DEC-004. Its templates, interview scripts, and thresholds remain useful for the closed beta and go/iterate/stop reviews.

Deliverables:

- recruit five friend groups;
- concierge loop template;
- clickable create/vote/Reveal prototype;
- optional owner self-prediction/Illusion Filter variant;
- offline-draft recovery and explicit-publish prototype;
- one-dilemma guest Reveal consent prototype;
- interview scripts and consent;
- baseline event spreadsheet;
- vote-mechanic comparison;
- go/iterate/stop review.

Original evidence criteria, now applied as closed-beta review inputs:

- at least four of six behavioral thresholds pass;
- reflection and Reveal-open thresholds must pass or be close enough for one clearly defined iteration;
- no critical privacy/tone objection lacks a plausible fix.

### Phase 1 — Technical foundation

Duration hypothesis: 2–3 weeks after go decision.

Deliverables:

- stack spikes;
- schema and state-transition design;
- auth and guest scoped-session proof;
- RLS/access-policy matrix and tests;
- universal/app link proof;
- scheduled-job/outbox proof;
- privacy, retention, abuse, and incident drafts;
- CI and environment setup.

Exit criteria:

- all eight technical spikes resolved;
- threat model reviewed;
- no blocker in managed backend, region, backup, or deletion.

### Phase 2 — Closed-loop MVP

Duration hypothesis: 6–10 weeks for a small experienced team; estimate only after spikes.

Build order:

1. account/profile and protected offline local draft with explicit publish;
2. dilemma publish, private media, purpose, and optional owner-expectation experiment;
3. invite exchange, guest vote web flow, and one-dilemma Reveal consent;
4. owner results and detailed decision outcomes;
5. category-aware delayed reflection jobs and return/gift handling;
6. Reveal, prediction records, and owner-private Illusion Filter comparison;
7. histories and notifications;
8. report/block/revoke/delete;
9. analytics, operations, and accessibility hardening.

Exit criteria: MVP release gates in the product specification pass.

### Phase 3 — Eight-week closed beta

Deliverables:

- 10–20 groups, 50–100 owners;
- weekly cohort reviews;
- support/moderation rota;
- two qualitative interview waves;
- scoring semantics review;
- documented continue/iterate/stop decision.

No public feed or paid acquisition during this phase.

### Phase 4 — Retention improvements

Only after closed-loop thresholds pass:

- link/image metadata extraction;
- evidence-gated activation of 90-day long-horizon follow-up;
- better private group continuity;
- transparent category/reason insights;
- participant-to-owner referral loop;
- account-based cross-device guest history.

### Phase 5 — Experimental expansion

Gated individually:

- AI-assisted reflection questions;
- AI summaries with source traceability;
- “Future You” model after sufficient personal history;
- opt-in public/community surfaces;
- private-group challenges;
- premium insights/export.

## 3. Ranked product risks

| Rank | Risk | Impact | Likelihood | Validation/mitigation | Exit signal |
|---:|---|---:|---:|---|---|
| 1 | Owners do not complete delayed reflection | Critical | High | Concierge and timing tests; one-tap prompt | ≥50% completion |
| 2 | People vote but will not post authentic dilemmas | Critical | Medium-high | Recruit from real recent behavior; privacy variants | ≥40% owner activation |
| 3 | Group chat is good enough | High | Medium-high | Compare structured Reveal/history with chat control | Users prefer structured loop and repeat |
| 4 | Purchase frequency is too low for retention | High | High | Measure group-level, not individual, return; Reveal loop | ≥30% repeat voters |
| 5 | Price/reason sharing feels exposing | High | Medium | Prototype hidden/optional price and generic previews | ≥80% privacy comprehension |
| 6 | Prediction scoring rewards judgment | High | Medium | Neutral language; minimum samples; no leaderboard | Low hide/block/report and positive interviews |
| 7 | Delayed Reveal loses salience | High | Medium | Decision update plus later Reveal; timing experiment | ≥50% Reveal view |
| 8 | Invite links leak | High | Medium | Generic preview, token scope, revocation, no index | No unauthorized test access |
| 9 | Guest voting attracts abuse/manipulation | High | Medium | Rate limit, report/block, scoped session, anomaly review | Reports under guardrail |
| 10 | Insights take too long to become useful | Medium | High | History first, small-sample caveats, diary study | Qualitative value before advanced analytics |
| 11 | Gamification feels childish | Medium | Medium | Resolved prediction history only | Tone tests pass |
| 12 | AI distracts from human value | Medium | Medium | No AI in MVP; require user problem first | AI only added against measured friction |
| 13 | Owner self-prediction adds friction or feels diagnostic | High | Medium | Optional experiment, private by default, neutral comparison | Creation decline ≤10% and positive qualitative value |
| 14 | Richer outcomes confuse decision/reflection | Medium | Medium | Progressive disclosure and usability tests | Fast, correctly classified outcomes |
| 15 | Category timing is wrong for an individual item | Medium | Medium | Too early once, timing experiment, rule versioning | <25% timing mismatch |

## 4. Technical risks

| Risk | Mitigation |
|---|---|
| RLS policy error exposes private dilemmas | Deny-by-default schema, role matrix, automated negative tests, independent review |
| Invite token appears in logs/referrers | Token hashing, redaction, no-referrer, structured-log allowlist, leakage tests |
| Scheduled follow-ups fail silently | Durable outbox, retries, job-age dashboard, dead-letter alerts, accelerated-clock E2E |
| Media survives deletion | Tracked asset variants, deletion job, reconciliation report, backup policy |
| Guest identity duplicates/manipulates votes | One scoped session, rate limits, account claim, anomaly detection; accept residual risk |
| Two client stacks drift | Narrow web scope, shared contracts/tokens/copy, contract and visual tests |
| Vendor lock-in | Standard Postgres schema, explicit service boundary, migration/export runbook |
| Exact price/free text leaks to analytics | Allowlisted event schema and automated redaction tests |
| Offline retry duplicates or accidentally publishes a dilemma | Local unpublished state, explicit review/publish, idempotency keys, E2E reconnect tests |
| Guest Reveal address outlives consent/purpose | Dilemma-scoped endpoint, withdrawal, deletion job, retention dashboard |
| Owner self-prediction leaks to voters | Separate owner-only entity, participant API negative tests, no Reveal projection by default |

## 5. Decision log

| ID | Decision | Status | Rationale | Revisit trigger |
|---|---|---|---|---|
| D-001 | Private invite-link MVP, no public feed | Accepted | Reduces cold start and safety burden; tests trusted social loop | Private loop retains and users request discovery |
| D-002 | Account required to create; guest can vote | Accepted | Ownership/deletion need identity; vote conversion needs low friction | Abuse or claim complexity overwhelms benefit |
| D-003 | Future-framed Buy/Wait/Skip | Provisional | Combines advice and outcome anticipation | Mechanic experiment favors another model |
| D-004 | 72h suggested pause with 24h/3d/7d choices | Provisional | Useful default without coercion | Category/timing test shows mismatch |
| D-005 | Category-aware follow-up: 7d short-lived, 30d durable; 90d dormant | Accepted for implementation, mapping provisional | Improves relevance while keeping the first beta observable | >25% timing mismatch or experiment favors simpler rule |
| D-006 | Same-choice-again as primary satisfaction measure | Accepted | Works for both buy and skip; neutral and lightweight | Users cannot map experience to answer |
| D-007 | Wait unscored | Provisional | Avoid pretending an ambiguous prediction resolved | Scoring comprehension/motivation suffers |
| D-008 | No global leaderboards/streak pressure | Accepted | Safety and product-purpose alignment | Strong evidence of safe learning benefit |
| D-009 | No AI in closed beta | Accepted | Core hypothesis is human social loop | Measured creation/synthesis pain blocks completion |
| D-010 | No monetization during validation | Accepted | Avoid incentive conflict before value proof | Retention loop passes and pricing research begins |
| D-011 | Brazil, Portuguese, adults-only first | Accepted | Focus and current legal/safety scope | Expansion readiness and counsel review |
| D-012 | Flutter mobile plus narrow responsive web | Proposed | Cross-platform app plus fast guest link | Technical spike shows unacceptable complexity/performance |
| D-013 | Supabase/Postgres managed backend candidate | Proposed | Small-team speed and relational/RLS fit | Region, backup, deletion, cost, or security spike fails |
| D-014 | Optional private owner self-prediction and Illusion Filter experiment | Accepted as experiment | Tests expectation-versus-outcome insight without changing core loop | Creation decline >10%, privacy confusion, or low owner value |
| D-015 | Distinguish original, alternative, skipped, unavailable, returned/refunded, and gift outcomes | Accepted | Prevents misleading insight and scoring data | Usability cannot keep reflection under 30 seconds |
| D-016 | Offline capture remains unpublished until explicit review/publish | Accepted | Supports in-store capture without accidental social disclosure | Research shows negligible need or unacceptable client complexity |
| D-017 | Guest Reveal subscription is one-dilemma and separate from marketing | Accepted | Tests curiosity loop with minimal acquisition friction and consent scope | Low delivery value or consent complaints |
| D-018 | Alternative/return/gift/unavailable outcomes remain unscored initially | Accepted | Avoids invented prediction semantics | Validated scoring model and user comprehension |

## 6. Open questions

### Product

- Should price be required, optional, or hideable per audience?
- Does a decision update increase or reduce desire for the later Reveal?
- What makes a prediction “correct” when the owner buys but regrets, or skips but still wants?
- Should voters see individual reasons or only owner-curated/aggregate reasons?
- Which categories belong in the 7-day versus 30-day rule, and when should dormant 90-day timing activate?
- Does the optional self-prediction produce useful insight without harming creation, and what sample threshold should govern the Illusion Filter?
- Should alternative price be retained if the product deliberately avoids claiming money saved?
- Does private closure damage participant trust or increase owner safety enough to justify it?

### Experience

- Is “Temptation” warm and understandable in Brazilian Portuguese, or does it imply moral weakness?
- What Portuguese labels best preserve neutrality for Buy/Wait/Skip?
- Will generic link previews reduce click-through too much?
- How should the Reveal handle contradictory or changing feelings?

### Safety/legal

- What age-assurance approach is required under current Brazilian law for this service?
- What lawful bases and notices apply to guest participants and notification subscriptions?
- How should participant votes be handled when an account is deleted?
- What operator evidence retention is justified after content deletion?

### Technical

- Can the managed backend meet preferred region, DPA, storage backup, and deletion requirements?
- Should guest web be server-rendered TypeScript or a smaller shared-code alternative?
- How will push/email opt-in work for guests without unnecessary personal data?
- What grace period is required after guest Reveal delivery before deleting the routing address?
- Which platform-protected store and backup behavior are acceptable for offline drafts?
- Is one invite token per dilemma sufficient, or are group-specific links needed?

## 7. Team shape for MVP

Minimum practical team:

- product lead/founder conducting validation;
- product designer with research responsibility;
- one Flutter engineer;
- one backend/web engineer;
- fractional trust/privacy/security review;
- part-time beta support/moderation owner.

One full-stack engineer can prototype the loop, but production beta should not leave authorization, delayed jobs, web conversion, mobile UX, safety operations, and research with no independent review.

## 8. Immediate next actions

1. Recruit five pilot groups using recent “should I buy this?” behavior as the screen.
2. Build the concierge form, vote page, and Reveal template.
3. Prototype three vote-mechanic variants.
4. Draft participant consent/privacy explanation for the manual test.
5. Define the experiment spreadsheet from the metrics taxonomy.
6. Schedule the first go/iterate/stop review before any production build.
