# Product requirements

## 1. Executive summary

Before I Buy helps people pause on discretionary purchases, ask people they trust what Future Them will think, record the eventual choice, and close the loop later with a Reveal. The user benefit is better self-knowledge about satisfying versus regretted purchases. The social benefit is the anticipation of finding out what happened and whether a prediction was right.

The concept should not be positioned as budgeting, expense tracking, financial advice, or anti-shopping. Existing products already cover cooling periods, private decision checklists, public purchase voting, and AI purchase advice. The unvalidated opportunity is the combination of friend predictions, delayed outcomes, prediction reputation, and longitudinal personal satisfaction.

**Recommendation:** implement the narrow first technical slice and collect evidence in a controlled private-group beta. Expand beyond the closed loop only if users reliably complete both the decision and later-reflection stages.

## 2. Vision and promise

### Vision

Help people understand what kinds of spending genuinely improve their lives, one real decision at a time.

### User promise

> Bring us the things you are unsure about. We will help you pause, hear from people who know you, and remember what Future You actually thought.

### What the product is

- a social decision game built around real purchase dilemmas;
- a lightweight reflection tool before and after a decision;
- a private record of desire decay, satisfaction, and regret;
- a feedback loop in which friends learn how well they understand one another.

### What the product is not

- a budget, bank account, debt, or investment tracker;
- a moral score for consuming less;
- a marketplace or product recommendation engine;
- financial, psychological, or therapeutic advice;
- an AI authority that tells users what to buy.

## 3. Problem statement

### Observed

- Current tools offer structured pauses and private Buy/Wait/Skip decisions. Examples include [Wait Before You Buy](https://apps.apple.com/gb/app/wait-before-you-buy/id6758269198) and [Should I Buy This?](https://apps.apple.com/nl/app/should-i-buy-this-spending/id6788594106).
- Public voting already exists: [Should U Buy](https://shouldubuy.com/) describes a crowd-sourced “purchase court.”
- AI advice plus post-purchase learning already exists: [FourTip](https://apps.apple.com/us/app/fourtip-ai-shopping-advisor/id6784199126) advertises four AI perspectives, follow-up, and learning purchase patterns.
- Research on online-purchase interventions found that interruptions and reflection can break the immediate buying flow, while excessive workload harms the experience ([Kwon et al., WWW 2021](https://www.bckwon.com/pdf/purchase.pdf)).

### Assumption

People who already send “Should I buy this?” messages to close friends will accept a purpose-built flow if posting takes less than two minutes and friends can respond without installing the app.

### Problem

The moment of uncertainty is currently fragmented across shopping pages, group chats, notes, wishlists, and memory. Advice disappears, the final outcome is rarely reported, and neither purchaser nor friends learn from what happened.

### Opportunity

Turn an existing social behavior into a closed learning loop with just enough structure to create anticipation and reusable insight.

## 4. Product principles

1. **Satisfaction over restriction.** A purchase can be the good outcome.
2. **Reflection, not judgment.** The interface asks what matters; it does not shame.
3. **Friends before crowds.** Trust and relevance matter more than feed volume in the first release.
4. **Outcome over verdict.** The later Reveal is more important than the initial vote.
5. **Low friction at every handoff.** Posting under two minutes; voting under 20 seconds; follow-up under 30 seconds.
6. **Private by default.** No salary, balances, debt, or total spending are required.
7. **Game mechanics must teach.** Scores exist only to reinforce completion and learning.
8. **No conflicted incentives.** The product must not profit from causing purchases during validation.

## 5. Target users

### Segment assessment

| Segment | Problem strength | Post likelihood | Vote likelihood | Privacy risk | Retention potential | Assessment |
|---|---:|---:|---:|---:|---:|---|
| Adults who already ask friends about fashion, tech, beauty, home, hobbies, or travel | High | High | High | Medium | Medium-high | Primary hypothesis |
| Conscious-consumption and deinfluencing audiences | High | Medium | High | Low-medium | Medium | Useful recruitment channel; avoid anti-shopping identity |
| Frequent online impulse shoppers | High | Medium | Medium | High | Medium | Need trust; may prefer private mode |
| Traditional budget-app users | Medium | Low | Low | High | Low-medium | Not a launch focus |
| Public style/opinion communities | Medium | High | High | High moderation load | High | Post-MVP only |
| Minors | Potentially high | Unknown | High | Very high | Unknown | Exclude at launch pending legal/safety work |

### Recommended early adopter

**Assumption:** adults in Brazil who make several discretionary online purchases per month and already share purchase links in small WhatsApp groups.

Why:

- the social behavior already exists;
- invite links fit the current channel;
- friends have context that anonymous crowds lack;
- Portuguese and BRL give a focused initial market;
- private groups reduce cold-start and moderation risk.

Tradeoff: this segment may not generate enough dilemmas for weekly retention. The Reveal loop must compensate, and this must be tested before building a public feed.

## 6. Jobs to be done

### Purchaser

- When I am tempted but uncertain, help me pause and get useful perspective without revealing my finances.
- When I decide, help me record why so I can compare expectation with reality later.
- When enough time has passed, help me answer whether the choice was right for me.
- Over time, show me patterns in the reasons and categories that lead to satisfaction or regret.

### Friend

- When someone I know is considering a purchase, let me respond quickly and kindly.
- Later, tell me what happened so the interaction does not disappear into a group chat.
- Help me learn where my predictions are useful without turning friendship into a harsh leaderboard.

### New recipient

- Let me understand and vote on a shared dilemma without installing or registering.
- Show enough value after the Reveal that I might create my own dilemma.

## 7. Core loop

1. **Temptation:** owner adds item, price, image/link, reason, audience, and whether the decision is for themselves or a gift. In an experiment, the owner may privately predict what Future Them will think.
2. **Pause:** system suggests 72 hours; owner selects 24 hours, 3 days, or 7 days.
3. **Prediction:** friends answer: **Buy — likely glad**, **Wait — too soon**, or **Skip — likely glad**, optionally adding a reason.
4. **Decision update:** owner records Bought original, Bought an alternative, Skipped, Item unavailable, or Still deciding. Participants receive a lightweight update.
5. **Reflection:** after a category-appropriate interval, the owner records whether the item was kept or returned/refunded and answers “Would you make the same choice again?” Gift decisions use a gift-specific prompt and remain outside self-purchase satisfaction analytics.
6. **Reveal:** participants see the choice, reflection, selected owner note, and whether their confident prediction aligned.
7. **Learning:** owner history and friend prediction record update.

### Why this mechanic

**Recommendation:** combine advice and prediction in one future-framed response. Plain Buy/Wait/Skip is useful but easy to copy; a pure probability question is less intuitive. Future-framed action labels preserve immediate utility while making the later outcome meaningful.

**Tradeoff:** “Wait” is not directly scoreable. The MVP should count it as participation but not accuracy. If this reduces motivation, test a two-step flow later rather than complicating the initial vote.

## 8. Key hypotheses

| ID | Hypothesis | Confidence | Evidence needed |
|---|---|---:|---|
| H1 | People will post authentic dilemmas to selected friends | Low-medium | At least 40% of recruited testers create one within 7 days |
| H2 | Invite recipients will vote without an account | Medium | At least 50% of unique link visitors complete a vote |
| H3 | Owners will report the decision | Medium | At least 70% of dilemmas receive Bought/Skipped/Still deciding |
| H4 | Owners will complete delayed reflection | Low | At least 50% of eligible dilemmas complete reflection within 7 days of prompt |
| H5 | Voters care about the Reveal | Low-medium | At least 50% of notified voters open it |
| H6 | Prediction history increases participation | Low | Repeat voters cast 25% more predictions after their first Reveal |
| H7 | Personal insight becomes valuable before 10 completed dilemmas | Low | Qualitative evidence of changed decisions or self-understanding |
| H8 | A private owner self-prediction creates useful insight without materially reducing posting | Low | Optional field completion, creation-time impact, and owner value after Reveal |

## 9. Differentiation

### Table stakes

- item, price, image, link, category, and reason;
- a pause or reminder;
- Buy/Wait/Skip-style interaction;
- history and basic totals;
- shareable links.

### Potential differentiation

- friend prediction framed around Future You;
- two-stage outcome: decision update, then later Reveal;
- reputation based on resolved predictions rather than volume;
- personal insight based on satisfaction and stated reasons, not only category or amount.

### Network and retention potential

- Each dilemma recruits voters through an invite link.
- Each resolved dilemma creates a reason for those voters to return.
- Prediction history can create friend-specific identity.

None of these are proven network effects. They only matter if posts resolve and people reopen Reveals.

## 10. Core product decisions

### Voting

Use three responses: **Buy — likely glad**, **Wait — too soon**, **Skip — likely glad**. Allow one optional reason capped at 280 characters. Do not show live percentages until the recipient votes to reduce social anchoring.

### Waiting

Suggest 72 hours. Allow 24 hours, 3 days, or 7 days. The owner may decide early; the UI notes that the pause ended early without punishment.

### Follow-up and satisfaction

- Short-lived outcomes such as meals, events, and immediately consumed experiences: ask after 7 days.
- Durable goods such as clothing, technology, hobbies, beauty, and home items: ask after 30 days.
- Long-horizon purchases such as travel, courses, and annual commitments: store a 90-day-capable schedule, but keep 90-day delivery behind a post-MVP timing experiment.
- Skipped: ask after 7 days whether the user is glad they skipped, still wants it, bought an alternative, or the original became unavailable.
- Bought: first ask whether the owner kept or returned/refunded the item, then ask the satisfaction question.
- Gift purpose: ask whether choosing the gift felt worthwhile and exclude the result from self-use satisfaction analytics.
- Primary resolution: **Would you make the same choice again? Yes / Not sure / No.**
- “Too early to tell” reschedules once without scoring the prediction yet.
- Optional note: 280 characters.

This wording works for both buying and skipping and produces a clear outcome without implying that spending less is always better.

### Social architecture

- Creator account required.
- Dilemma is private and unlisted by default.
- Owner shares a capability-style invite link.
- Guest can view and vote with a temporary pseudonym; after voting, they may separately opt in to this dilemma's Reveal or create an account.
- A guest Reveal opt-in is not marketing consent and expires after delivery plus the approved grace period.
- Owner can revoke the link.
- No follower graph or public feed in MVP.

### Gamification

- Count resolved confident predictions and accuracy.
- Show private friend-group history and category hints only after minimum sample thresholds.
- Do not use global leaderboards, XP, coins, daily streak pressure, or “money saved” celebrations in MVP.

### Notifications

Prioritize only actions that close the loop:

1. owner decision due;
2. owner reflection due;
3. participant Reveal ready;
4. one optional reminder that voting closes soon.

Aggregate vote activity; do not notify for every vote.

## 11. Feature prioritization

| Feature | Stage | Reason | Exit criterion for next stage |
|---|---|---|---|
| Create dilemma manually | MVP | Tests posting behavior | 40% tester activation |
| Private invite link | MVP | Solves cold start through existing groups | 50% visitor-to-vote conversion |
| Guest vote | MVP | Minimizes acquisition friction | Abuse remains manageable |
| Pause and decision update | MVP | Core behavioral transition | 70% decision completion |
| Delayed reflection and Reveal | MVP | Core differentiated loop | 50% reflection and Reveal-open rates |
| Basic prediction history | MVP | Tests game motivation | Repeat voting rises after Reveal |
| Private owner history | MVP | Immediate memory value | Users reference history in interviews |
| Alternative/unavailable/return/gift outcomes | MVP | Prevents misleading satisfaction and scoring data | Outcome choices remain understandable and quick |
| Offline draft with explicit publish | MVP | Captures in-store decisions without accidental sharing | Draft recovery and reconnect tests pass |
| Guest one-dilemma Reveal subscription | MVP | Tests the curiosity/return loop without an account wall | Consent and Reveal-delivery conversion are healthy |
| Link metadata extraction | Post-MVP | Reduces creation friction | Manual-entry abandonment is material |
| Comments/discussion | Post-MVP | Richer context but moderation cost | Short reasons prove insufficient |
| Category insights | Post-MVP | Needs enough resolved history | At least 10 resolved dilemmas/user |
| Public community/feed | Future/experimental | Major safety and liquidity burden | Private loop already retains |
| AI summaries/questions | Future/experimental | Requires data and trust | Clear pain not solved by templates |
| Private owner self-prediction and Illusion Filter | Experimental | Compares expectation, friend prediction, and lived outcome | Adds value without raising creation abandonment more than 10% |
| Global leaderboard | Reject for now | Encourages performative judgment | Revisit only with safety evidence |
| Affiliate links/sponsored products | Reject for now | Conflicts with trust | Independent governance and user demand |
| Bank/Open Finance connection | Reject for now | Changes product category and risk | Not aligned with current wedge |

## 12. Personal insights

### MVP

- number of dilemmas created;
- decisions: bought original, bought an alternative, skipped, item unavailable, or still deciding;
- choices the user would make again;
- private chronological history;
- prediction participation and resolved accuracy.
- outcome fidelity: original, alternative, skipped, unavailable, returned/refunded, and gift-purpose decisions are not collapsed into misleading categories.

### Post-MVP, with minimum samples

- satisfaction by category and price band;
- desire decay after waiting;
- reasons associated with positive or negative outcomes;
- agreement with friends;
- categories where friends predict the user well.
- **Illusion Filter:** owner-private comparison of their initial expectation with friend predictions and actual outcome, shown only after enough completed experimental entries.

Do not present correlations as causes. Every insight must show sample size and allow the user to inspect underlying dilemmas.

Owner self-predictions are private by default and must not be shown to voters before they vote. The experiment must measure whether the extra creation step causes abandonment; it can be removed without affecting the core loop.

## 13. AI opportunities

| Opportunity | Stage | Value | Data required | Risk | Non-AI alternative |
|---|---|---|---|---|---|
| Extract link/image metadata | Post-MVP | Faster posting | URL or image | Wrong price/item; merchant tracking | Manual edit with link preview |
| Contextual reflection question | Post-MVP test | Better reflection | Item and reason | Generic or judgmental output | Category templates |
| Summarize reasons | Future | Faster synthesis at scale | Voter text | Misrepresentation | Highlights and counts |
| Dynamic follow-up | Future | Closes expectation loop | Original reason and outcome | Sensitive inference | Reuse original reason verbatim |
| Personal pattern narrative | Future | Self-knowledge | Sufficient history | False certainty | Transparent statistics |
| Future You prediction | Experimental | Signature experience | Large personal history | Overclaiming authority | Rules with sample disclosure |
| AI verdict | Reject | Familiar but off-strategy | User context | Replaces humans; weak trust | Friend prediction |

## 14. Monetization

### Recommendation

Do not monetize during validation. Measure whether the loop creates repeat behavior first.

### Plausible later model

Freemium subscription for advanced private history, richer insights, export, and durable small-group features. The free loop must remain complete enough to invite and Reveal.

The sequenced revenue portfolio—including Future You Plus, Circle Pass, cosmetics, Creator Circles, and high-risk commercial experiments—is defined in the [marketing and monetization strategy](../07-marketing/README.md).

### Avoid

- pre-decision affiliate commissions or commerce ranking;
- paid product placement disguised as an organic dilemma;
- sponsored “worth it” outcomes;
- selling behavioral purchase data;
- monetization that rewards more purchasing or more compulsive app use.

## 15. Success definition

The product is valuable when a meaningful share of created dilemmas reaches a later, viewed outcome—not when it maximizes raw posts or votes.

**North Star Metric:** weekly resolved dilemmas with at least one participant viewing the Reveal.

See the metrics document for definitions and guardrails.

## 16. Final recommendation

**Proceed with changes.** Per DEC-004, begin with the narrow technical slice and measure the delayed-reflection and Reveal hypotheses in a controlled closed beta. If real friend groups do not complete delayed reflection and open Reveals, the central differentiation fails even if voting is popular.

### Recommended MVP

Private, link-shared dilemmas; guest voting; configurable short pause; decision update; 30-day/7-day reflection; Reveal; basic private histories; essential notifications; report/block/revoke controls.

### Top three hypotheses

1. People will post authentic dilemmas.
2. Owners will complete delayed reflections.
3. Voters will return for Reveals and predict again.

### Top three failure modes

1. Voting is fun but posting is too vulnerable or infrequent.
2. Delayed outcomes are not completed, breaking the loop.
3. Group-chat sharing is good enough, so structured history adds little value.

### First three experiments

1. Closed-beta test of the first technical slice with five friend groups.
2. Usability test of create, vote, and Reveal screens with invited recipients before each later slice.
3. Notification and delayed-recall test using the durable scheduling path before the reflection release.
