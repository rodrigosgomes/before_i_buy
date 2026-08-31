# Before I Buy documentation

This folder is the working product specification for **Before I Buy**, a mobile social decision game for real purchase dilemmas.

> **Positioning:** Spend on what you will be glad you bought. Skip what you will forget you wanted.

## Current recommendation

Proceed with changes and validate before committing to a full build. The credible wedge is not another Buy/Wait/Skip tool. It is the closed loop:

**Temptation → friend predictions → pause → decision update → later reflection → Reveal → prediction reputation → personal insight**

The private, invite-link MVP should test this loop with real friend groups. A public community, complex AI, affiliate revenue, and leaderboards are intentionally excluded.

## Document map

| Area | Document | Purpose |
|---|---|---|
| Product | [Product requirements](01-product/product-requirements.md) | Vision, users, hypotheses, product decisions, prioritization, monetization, recommendation |
| Product | [MVP specification](01-product/mvp-specification.md) | Buildable scope, requirements, acceptance criteria, non-goals, release gates |
| Product | [First delivery mini-PRD](01-product/first-delivery-mini-prd.md) | Canonical scope for the first technical delivery: private creation, invite, and guest vote |
| Experience | [Journeys, stories, and screens](02-experience/journeys-stories-screens.md) | End-to-end flows, user stories, screen states, notifications, edge cases |
| Experience | [Experience principles](02-experience/experience-principles.md) | Voice, accessibility, gamification, insight design, content rules |
| Strategy | [Competitive analysis](03-strategy/competitive-analysis.md) | Current products, observed overlap, inferences, differentiation requirements |
| Strategy | [Validation and launch](03-strategy/validation-and-launch.md) | Experiments, success/failure signals, private-beta and cold-start plan |
| Strategy | [Metrics and analytics](03-strategy/metrics-and-analytics.md) | North Star, funnel metrics, event taxonomy, guardrails |
| Trust | [Trust, safety, and privacy](04-trust/trust-safety-privacy.md) | Privacy model, moderation, minors, legal review, retention, abuse handling |
| Technical | [Technical architecture](05-technical/technical-architecture.md) | Recommended stack, system boundaries, security, jobs, deep links, operations |
| Technical | [Conceptual data model](05-technical/conceptual-data-model.md) | Entities, relationships, lifecycles, visibility and deletion rules |
| Delivery | [Roadmap, risks, and decisions](06-delivery/roadmap-risks-decisions.md) | Phases, ranked risks, dependencies, decision log, open questions |
| Delivery | [Quality process and merge](06-delivery/quality-process.md) | Mandatory task/PR process, test strategy, CI gates, adversarial review, and branch protection |
| Delivery | [Definition of Done](06-delivery/definition-of-done.md) | Shared merge contract for scope, tests, coverage, security, and review |
| Delivery | [Supabase CLI local](06-delivery/supabase-cli-setup.md) | Reproducible local database commands and remote-operation safety boundaries |
| Delivery | [Task 0 — guest session and RLS foundation](06-delivery/tasks/T0-guest-session-and-rls-foundation.md) | Approved implementation plan to remove direct guest access and establish a one-dilemma guest session |
| Delivery | [Guest invite external-beta gate](06-delivery/guest-invite-external-beta-gate.md) | Required rate-limit, cookie-origin, and privacy evidence before exposing guest invites externally |
| Marketing | [Marketing and monetization](07-marketing/README.md) | Recommended revenue sequence, social-platform patterns, emotional game mechanics, pricing, and experiments |
| Marketing | [Monetization strategy](07-marketing/monetization-strategy.md) | Subscription, Circle Pass, cosmetics, creator economy, commercial models, and guardrails |
| Marketing | [Game mechanics and emotional value](07-marketing/game-mechanics-and-emotional-value.md) | Ethical use of vanity, satisfaction, influence, belonging, curiosity, reciprocity, and mastery |
| Marketing | [Experiments, pricing, and economics](07-marketing/experiments-pricing-and-economics.md) | Price hypotheses, monetization funnels, guardrails, and unit-economics model |
| Design | [Closed-loop screen concepts](08-design/README.md) | High-fidelity mobile UI boards for the eight stages from Temptation through personal insight |

## Status vocabulary

- **Observed:** supported by a cited source or direct product observation.
- **Assumption:** plausible, but not yet validated with target users.
- **Inference:** conclusion drawn from observations; still needs testing.
- **Recommendation:** a product decision made for the initial plan.
- **Open question:** a choice whose answer could materially change scope or positioning.

## Product decision snapshot

| Decision | MVP choice | Confidence |
|---|---|---|
| Launch audience | Adults in Brazil who already ask close friends about discretionary purchases | Medium |
| Social model | Private dilemmas shared by invite link; account required to create, guest can vote | Medium-high |
| Core vote | Future-framed Buy / Wait / Skip prediction, with optional short reason | Medium |
| Owner self-prediction | Optional private experiment comparing owner expectation, friend predictions, and actual outcome | Medium |
| Waiting window | Suggested 72 hours; owner may choose 24 hours, 3 days, or 7 days and may decide early | Medium |
| Follow-up | Category-aware: 7 days for short-lived outcomes, 30 days for durable purchases; 90-day capability deferred | Medium |
| Satisfaction outcome | “Would you make the same choice again?” Yes / Not sure / No | Medium-high |
| Scoring | Correct confident predictions only; no public global leaderboard | Medium |
| Outcome fidelity | Distinguish original purchase, alternative, skipped, unavailable, returned/refunded, and gift purpose | Medium-high |
| Offline capture | Local draft with explicit review and publish after reconnection | Medium-high |
| Guest Reveal | One-dilemma opt-in after voting; no bundled marketing consent | High |
| AI | None in closed beta; link metadata extraction may follow | High |
| Monetization | None during validation; test Future You Plus subscription first after product gates pass | High |
| Public feed | Not in MVP | High |
| Initial age policy | Adults only pending legal and child-safety design review | High |

## Change discipline

When a product decision changes:

1. update the decision log in the delivery document;
2. update the affected requirement and acceptance criteria;
3. update the data model and analytics event if behavior changes;
4. record the evidence or experiment that caused the change.

## Source-of-truth order

When product documents conflict, resolve the conflict before implementation. The order of precedence is:

1. accepted entries in the [Decision Log](06-delivery/DECISION_LOG.md);
2. the [MVP specification](01-product/mvp-specification.md);
3. the active delivery mini-PRD for the implementation slice;
4. supporting product, experience, trust, technical, and strategy documents.

The active mini-PRD may narrow a release slice but cannot override an accepted product, security, or privacy decision.
