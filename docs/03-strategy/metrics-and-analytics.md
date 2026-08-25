# Metrics and analytics

## 1. Measurement principle

Measure completed learning loops, not addictive activity. More posts, notifications, or screen time are not inherently positive.

## 2. North Star Metric

### Weekly Revealed Dilemmas With a Viewer (WRDV)

Number of distinct dilemmas in a calendar week that:

1. recorded a decision;
2. completed an eligible later reflection;
3. published a participant-visible Reveal; and
4. had at least one earlier participant view that Reveal.

Why:

- represents value for owner and participant;
- requires the differentiated loop to close;
- cannot be inflated by empty posts or low-intent votes alone;
- is understandable across product, growth, and operations.

Tradeoff: it lags by 7–30 days. Use leading indicators for weekly operations without changing the North Star.

## 3. Funnel definitions

| Stage | Metric | Definition | Initial decision threshold |
|---|---|---|---:|
| Recruit | Eligible owner enrolled | Adult tester accepted and account created | Context only |
| Activate owner | Owner activation | Creates first published dilemma within 7 days | ≥40% |
| Reach | Unique invite visitor | First eligible view of unlisted link | Context only |
| Activate participant | Guest vote conversion | Eligible votes / unique invite visitors | ≥50% |
| Subscribe guest | Dilemma-specific Reveal opt-in | Guest Reveal subscriptions / eligible guest voters | Observe first; no launch gate yet |
| Liquidity | Dilemma with response | Published dilemma with ≥2 distinct votes within 24h | ≥60% |
| Decide | Decision completion | Dilemmas with Bought/Skipped/Still deciding / due dilemmas | ≥70% |
| Reflect | Reflection completion | Completed eligible reflections / due reflections | ≥50% |
| Reveal | Reveal view rate | Participants who view / notified eligible participants | ≥50% |
| Repeat voter | 30-day repeat participation | Participants voting in ≥2 dilemmas / first-time voters | ≥30% |
| Creator conversion | Participant-to-owner | Participants creating a dilemma within 30 days | Explore, no gate yet |

Thresholds are hypotheses for closed-beta decisions, not forecasts or industry benchmarks.

## 4. Supporting metrics

### Activation and friction

- create start-to-publish conversion;
- offline-draft recovery-to-publish conversion and accidental-publish reports;
- self-prediction experiment exposure, completion, and incremental creation abandonment;
- median and p90 creation duration;
- field-level abandonment, without logging sensitive free text;
- guest page load-to-vote conversion;
- median vote duration;
- optional-reason completion.
- one-dilemma Reveal opt-in, delivery, open, unsubscribe, and routing-address deletion completion.

### Social liquidity

- time to first vote;
- median votes per dilemma;
- percentage with zero votes after 24 hours;
- unique groups contributing weekly;
- distribution of votes by owner/group to detect concentration.

### Loop health

- early-decision rate;
- Still deciding rate and eventual closure;
- reflection lateness;
- private-closure rate;
- unresolved prediction rate;
- decision-update and Reveal notification open rates;
- second-dilemma rate by group.

### Behavioral value

- same-choice-again Yes/Not sure/No distribution;
- original/alternative/skipped/unavailable/returned-or-refunded/gift outcome distribution;
- skipped-and-still-wants distribution;
- desire decay by wait window;
- owner-reported usefulness in interviews;
- percent citing a prior dilemma when making a new decision.
- experimental self-prediction versus friend aggregate versus actual outcome, shown only with adequate samples and never treated as a success KPI.

These metrics describe behavior; they must not be framed as financial outcomes without evidence.

## 5. Guardrail metrics

| Guardrail | Why | Alert condition |
|---|---|---|
| Reports per 100 participants | Social safety | >2 in beta or any severe pattern |
| Blocks per 100 cross-user interactions | Trust breakdown | Rising two cohorts in a row |
| Owner hides reason | Tone/moderation signal | >5% of reasons |
| Delete/revoke within 10 minutes | Privacy mismatch | >5% of published dilemmas |
| Notification opt-out | Pressure/annoyance | >20% after first loop |
| Guest Reveal unsubscribe/complaint | Consent or expectation mismatch | Any repeated complaint or >20% unsubscribe before delivery |
| Self-prediction creation drop | Extra reflection harms activation | >10% relative decline versus control |
| Private reflection rate | Sharing discomfort | >40% and rising |
| Owner-reported shame/judgment | Product harm | Any repeated qualitative theme |
| Accessibility critical failure | Exclusion | Any release-blocking defect |
| Unauthorized-access incident | Privacy/security | Any confirmed incident |

## 6. Event taxonomy

### Identity and consent

- `account_created`
- `eligibility_confirmed`
- `terms_accepted`
- `notification_consent_changed`
- `account_deletion_requested`

### Dilemma creation

- `dilemma_create_started`
- `dilemma_draft_saved`
- `offline_draft_recovered`
- `offline_draft_publish_reviewed`
- `owner_self_prediction_recorded`
- `dilemma_published`
- `dilemma_share_invoked`
- `invite_link_revoked`
- `dilemma_deleted`

Properties:

- `dilemma_id` pseudonymous ID;
- category enum;
- purpose enum `for_self` or `gift`;
- currency;
- price band, derived server-side—not exact amount in analytics;
- wait-window enum;
- image/link presence booleans;
- audience mode.

Do not send item name, URL, free-text reason, image, or exact price to third-party analytics.

### Participation

- `invite_opened`
- `vote_submitted`
- `vote_changed`
- `vote_reason_added`
- `guest_vote_claimed`
- `guest_reveal_subscription_offered`
- `guest_reveal_subscription_created`
- `guest_reveal_subscription_withdrawn`
- `guest_reveal_address_deleted`
- `report_submitted`
- `user_blocked`

Properties:

- guest/authenticated;
- vote enum;
- time since publish;
- group/dilemma pseudonymous ID.

### Resolution

- `decision_prompted`
- `decision_recorded`
- `outcome_detail_recorded`
- `reflection_prompted`
- `reflection_completed`
- `reflection_kept_private`
- `reveal_published`
- `reveal_notified`
- `reveal_viewed`

Properties:

- decision enum, including original, alternative, skipped, unavailable, and still deciding;
- kept/returned-or-refunded and gift-purpose enums;
- early/on-time/late;
- same-choice-again enum;
- too-early/rescheduled boolean;
- timing-rule version and 7/30/90-day bucket;
- delay bucket;
- prediction outcome enum.

Never place owner notes in analytics.

## 7. Metric rules

- Exclude staff, test, spam, and deleted-before-view dilemmas from product KPIs with documented rules.
- Keep raw denominators visible; never report only percentages.
- Use cohort dates based on publish time.
- Define one timezone for business reporting while storing timestamps in UTC.
- Distinguish guest device estimates from authenticated people.
- Do not claim “money saved”; skipped price is hypothetical, not verified savings.
- Do not compare users by spending amount.

## 8. Experiment framework

Every experiment record must include:

- hypothesis and owner;
- target population;
- primary metric and guardrails;
- unit of randomization;
- exposure event;
- planned duration/sample rationale;
- stop conditions;
- result and limitations;
- decision taken.

Do not A/B test manipulative urgency, shame, disclosure defaults, or safety controls.

## 9. Dashboards

### Weekly product dashboard

- WRDV and four-week trend;
- new published dilemmas;
- vote conversion;
- decision completion;
- reflection completion;
- Reveal view rate;
- repeat voter rate;
- safety guardrails.

### Cohort dashboard

- owners by first published week;
- group-level completion;
- second-dilemma rate;
- time-to-stage distributions;
- category and wait-window cuts with minimum sample rules.

### Operations dashboard

- scheduled jobs due/failed;
- notification delivery;
- unresolved reports and severity;
- access-control errors;
- deletion queue status;
- link abuse/rate-limit alerts.

## 10. Data minimization and retention

- Product database holds exact data needed for the experience.
- Analytics receives pseudonymous IDs and coarse derived properties only.
- Free text, URLs, images, and exact price stay out of third-party analytics.
- Guest Reveal routing addresses stay in notification infrastructure, not analytics, and are deleted after delivery plus the approved grace period if no account is created.
- Document event retention before beta; default recommendation is 13 months for product analytics and shorter for raw operational logs.
- Account deletion removes or irreversibly anonymizes analytics associations where feasible and legally appropriate.
- Any change requires privacy review and updated documentation.
