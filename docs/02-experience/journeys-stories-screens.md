# Journeys, stories, and screens

## 1. Experience model

The product has two intertwined journeys:

- **Owner journey:** uncertainty → structured pause → decision → later reflection → self-knowledge.
- **Participant journey:** invitation → prediction → anticipation → Reveal → reputation and repeat participation.

Every screen should make the next state obvious without implying that Buy or Skip is morally superior.

## 2. Owner journey

### Stage A — Create

1. Owner taps **New temptation**.
2. Adds item name, price, optional image/link, category, why they want it, and whether it is for themselves or a gift.
3. In the active experiment, may privately predict whether Future Them will make the same choice again.
4. Selects a pause; 3 days is preselected but editable.
5. Reviews recipient preview and privacy warning.
6. Publishes and shares an invite link. If offline, the item remains a clearly labeled local draft until the owner reconnects, reviews, and explicitly publishes.

Emotional goal: “I got this out of my head and into a calmer space.”

Failure risks:

- creation feels like expense entry;
- “why” feels like interrogation;
- price sharing feels embarrassing;
- recipient preview leaks more than expected.

### Stage B — Gather perspective

1. Home shows time remaining and vote count, not an addictive real-time ticker.
2. Owner may read aggregated results and short reasons after at least one vote.
3. Owner can hide abusive text, revoke link, or share again.

Emotional goal: “People understood my dilemma and gave me useful perspective.”

### Stage C — Decide

1. At pause completion, owner sees original reason, vote distribution, and representative reasons.
2. Chooses Bought original, Bought an alternative, Skipped, Item unavailable, or Still deciding.
3. Adds optional private note about why.
4. Participants receive one decision update.

Emotional goal: “This is my choice; the crowd did not make it for me.”

### Stage D — Reflect

1. A category-aware follow-up resurfaces the original reason after 7 or 30 days; long-horizon 90-day timing remains experimental.
2. If the item was bought, the owner first records whether it was kept or returned/refunded. Gift decisions use a gift-specific prompt.
3. Owner answers whether they would make the same choice again, or chooses Too early to tell and reschedules once.
4. Adds an optional shareable reflection.
5. Previews the Reveal and chooses Share result or Keep reflection private.
6. In the self-prediction experiment, sees a private comparison of their original expectation, friend predictions, and actual outcome.

Emotional goal: “I can compare what I expected with what actually happened.”

### Stage E — Learn

History shows resolved decisions in chronological order. After enough data, patterns are presented with sample counts and plain caveats.

## 3. Participant journey

### Stage A — Invitation

1. Recipient opens an unlisted link from a trusted person.
2. Sees the owner, item, price, reason, remaining pause, and privacy context.
3. No account wall appears before voting.

### Stage B — Predict

1. Prompt: **What will Future Lu be glad she did?**
2. Recipient chooses Buy, Wait, or Skip and may add one short reason.
3. Results appear only after submission.
4. Recipient can opt into this one dilemma's Reveal with email/push or claim the vote by creating an account. Reveal consent is separate from marketing and can be withdrawn without affecting the vote.

### Stage C — Return

1. Decision update answers “what did they do?” without resolving the prediction.
2. Reveal later answers “how did it turn out?”
3. Participant sees their own prediction in context and a gentle accuracy result.
4. CTA is **See another dilemma** only when another private-group item exists; otherwise **Create your own**.

## 4. User stories and acceptance criteria

### Owner

#### US-O1 Create a dilemma

As an owner, I want to capture a purchase and my reason quickly so I can pause without completing a financial form.

Acceptance:

- required inputs are visible and understandable;
- draft is recoverable;
- offline capture stays labeled **Draft—not shared yet** and never auto-publishes;
- purchase purpose is visible and gift outcomes are not mixed with self-use insights;
- the optional self-prediction remains private and does not increase median creation time beyond the experiment threshold;
- valid publish takes under two minutes in usability tests;
- app never asks for income, balance, debt, or bank access;
- preview matches the guest page.

#### US-O2 Control audience

As an owner, I want to share only with people I choose so sensitive spending is not exposed.

Acceptance:

- default is unlisted;
- owner can revoke the link immediately;
- generic link preview is default;
- deleted/revoked content cannot be opened from old notifications.

#### US-O3 Receive predictions

As an owner, I want a concise view of what friends think so their input is useful without becoming a comment pile-on.

Acceptance:

- percentages and counts are clear;
- reasons are capped and individually hideable;
- no friend is ranked by harshness or activity;
- owner can report/block.

#### US-O4 Record a decision

As an owner, I want to record the real outcome—including an alternative or unavailable item—so the loop continues without distorting my history.

Acceptance:

- deciding early is allowed;
- original purchase, alternative, skipped, unavailable, and still-deciding outcomes are distinct;
- Still deciding has one new due date;
- owner can correct an accidental tap during a grace period;
- participants receive one aggregate update.

#### US-O5 Complete reflection

As an owner, I want the app to remind me why I considered the item and ask one meaningful question so I can judge the choice honestly.

Acceptance:

- original reason is shown;
- follow-up timing matches the supported 7-day or 30-day category rule;
- kept, returned/refunded, gift, and too-early outcomes are handled explicitly;
- primary answer takes one tap;
- note is optional;
- exact participant-visible content is previewed;
- private closure is possible.

#### US-O6 Review history

As an owner, I want to revisit past dilemmas so I can spot patterns without being told a simplistic financial story.

Acceptance:

- each insight exposes its sample;
- unresolved items are distinct from negative outcomes;
- deleted items disappear from personal insight calculations after deletion completes.

### Participant

#### US-P1 Vote as a guest

As a recipient, I want to vote from the link without installing or registering.

Acceptance:

- page explains the product in one sentence;
- vote takes under 20 seconds;
- privacy notice is accessible but not blocking;
- authentication is offered only after vote completion.
- a one-dilemma Reveal subscription is offered after voting with separate consent and an unsubscribe path;

#### US-P2 Give context

As a participant, I want to explain my choice briefly without opening a long discussion.

Acceptance:

- reason is optional and capped at 280 characters;
- tone cue asks for useful, kind reasoning;
- owner can hide/report abusive text;
- blocked users cannot submit further text.

#### US-P3 Receive a Reveal

As a participant, I want to learn what happened so my earlier prediction has meaning.

Acceptance:

- Reveal includes decision and later reflection;
- it distinguishes wrong, right, waiting, and unresolved outcomes;
- it does not expose private owner notes;
- notification deep-links to the correct result.

### New user

#### US-N1 Understand value before signup

As a first-time recipient, I want to experience one complete vote before deciding whether the app is useful.

Acceptance:

- the guest page works without app installation;
- account benefit is explained after voting;
- no contact import is requested during first use.

#### US-N2 Claim participation

As a guest who signs up, I want my vote and future Reveal subscription attached to my account.

Acceptance:

- claim token is single-use and expires;
- user sees what will transfer;
- a claim cannot take over another participant's vote.

## 5. Screen inventory

### 5.1 Onboarding and sign-in

Purpose: explain “social decision game,” confirm adult eligibility, and create an owner account.

Primary content:

- concise value proposition;
- three-step loop illustration;
- privacy promise;
- sign-in options;
- Terms, Privacy, and age confirmation.

States: first visit, returning, link-driven guest, authentication error, ineligible age.

### 5.2 Home

Purpose: show actions that need attention before passive content.

Sections, in order:

1. Needs your action
2. Your active dilemmas
3. Recent Reveals
4. Friend-group dilemmas available to vote

Empty state: create first dilemma or open a sample Reveal. Do not simulate a fake community feed.

### 5.3 Create/edit Temptation

Use one scrollable flow or two short steps, not a wizard with many pages.

Content:

- item/image/link;
- price and currency;
- category;
- why now;
- how long wanted, optional;
- purpose: for self or gift;
- optional private Future You self-prediction when the experiment is active;
- pause selection;
- recipient preview and share-privacy choice.

Offline state: the screen saves locally, displays **Draft—not shared yet**, and requires explicit review/publish after reconnection.

### 5.4 Dilemma detail

Owner variant:

- state/timer;
- item and reason;
- share control;
- aggregate vote results and reasons;
- decision action;
- revoke/delete/report controls.

Participant variant:

- item and owner context;
- vote card or submitted vote;
- results after vote;
- follow-Reveal status;
- report/block.

### 5.5 Guest vote page

Mobile web, optimized for link entry. It must contain one dominant interaction and no app-install interstitial before the vote. After submission, a secondary opt-in offers delivery of this dilemma's Reveal by email or account claim; marketing consent is never preselected or bundled.

### 5.6 Decision/reflection sheet

Use a focused modal or full-height sheet. Re-show the original reason and make the owner—not the poll—the final authority.

### 5.7 Reveal

Hierarchy:

1. **Result is in**
2. decision and elapsed time;
3. same-choice-again answer;
4. owner-approved note;
5. group prediction distribution;
6. participant's prediction and status;
7. next action.

### 5.8 Profile/history/settings

Contains personal history, eligible prediction statistics, notification settings, blocked accounts, export/delete, Terms, Privacy, and support. No follower count.

## 6. Important states

Every relevant surface must design for:

- loading and slow network;
- no votes yet;
- only one vote;
- voting closed;
- decision overdue;
- reflection overdue;
- result private;
- invite revoked;
- item deleted;
- user blocked;
- content under moderation;
- offline draft;
- link opened on unsupported/old app version.

## 7. Notification matrix

| Trigger | Recipient | Default | Message intent | Suppression |
|---|---|---|---|---|
| Pause ends | Owner | On | Record your decision | Quiet hours; skip if resolved |
| Decision still missing +48h | Owner | On, once | Close or extend | Never repeat |
| Decision recorded | Participants | On, one aggregate | What happened next | Skip if owner chose private update |
| Reflection due | Owner | On | Compare expectation with reality | Quiet hours |
| Reflection missing +72h | Owner | On, once | Complete or close privately | Never repeat |
| Reveal ready | Participants | On | See outcome and prediction | Skip blocked/revoked/deleted |
| Reveal ready | Subscribed guest | Explicit opt-in | Deliver this one outcome | Unsubscribed, address invalid, blocked/revoked/deleted; delete routing address after policy grace period |
| New vote | Owner | Off individually | Avoid noisy social validation | Show in-app count only |

## 8. Edge-case policy

| Edge case | MVP behavior | Later consideration |
|---|---|---|
| Owner buys before timer ends | Allow and label “decided early” | Analyze effect on satisfaction |
| Changes mind repeatedly | Latest decision during grace period; then fixed | Decision timeline |
| Never records decision | Two prompts, then expire after 30 days | Friend nudge only with consent |
| Never reflects | Close as unresolved; no scores | Alternate shorter follow-up |
| Deletes dilemma | Remove participant access and exclude from analytics | Limited abuse-evidence retention |
| Price changes | Owner may edit before decision; preserve snapshot internally | Price history |
| Item unavailable | Owner selects Item unavailable; it remains distinct from voluntary Skip and is unscored | Availability reason detail |
| Bought an alternative | Record alternative separately; optional alternative price; never call it smarter or verified savings | Alternative comparison insight |
| Return/refund | Record at reflection; exclude from ordinary kept-purchase satisfaction and prediction scoring | Return reason analysis after sufficient samples |
| Sells later | Not modeled | Long-term check-in |
| Regret changes over time | One editable grace period | 90-day second reflection |
| Multiple items | Ask owner to create separate dilemmas | Comparison flow |
| Gift | Mark purpose at creation; use gift-specific reflection and exclude from self-use satisfaction | Recipient-aware timing only if validated |
| Subscription | Discouraged in MVP help text | Renewal follow-up |
| Travel/car/furniture | Store 90-day-capable timing; keep disabled in MVP and allow Too early to tell | Activate category timing after experiment |
| Sensitive item | Unlisted default, generic preview, owner controls | Local-only mode |
| Brand manipulation | No brand accounts; rate limits and moderation | Verified commercial policy |
| Harassment | Hide, report, block; operator review | Automated detection |
| Minor attempts access | Block account creation; minimize collected age data | Age-assurance design |

## 9. Usability test tasks

1. Create and share a R$850 sneaker dilemma.
2. Save the dilemma offline, reconnect, verify that it is still private, and publish it.
3. Vote from a guest link, explain the choice, and opt into only that Reveal.
4. Create a gift dilemma and explain how its later insight should differ.
5. Record that the original item was unavailable and an alternative was purchased.
6. Complete a returned-item reflection.
7. Interpret the private owner-expectation versus friends-versus-outcome comparison.
8. Find how to revoke access.
9. Record an early purchase.
10. Complete a category-timed reflection from a reminder.
11. Interpret a Reveal where the participant voted Skip but the owner bought and would buy again.
12. Delete a dilemma and explain what will happen to participants' access.

Capture completion, time, errors, hesitation, perceived judgment, privacy expectations, and understanding of prediction scoring.
