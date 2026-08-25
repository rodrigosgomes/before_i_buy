# Validation and launch

## 1. Validation principle

Do not build a public social network to test whether people will finish one private loop. Validate the vulnerable behaviors manually first:

1. authentic posting;
2. guest voting;
3. decision reporting;
4. delayed reflection;
5. Reveal reopening;
6. repeat participation.

## 2. Prioritized experiments

### Experiment 1 — WhatsApp concierge loop

**Priority:** P0, before product build

**Hypothesis:** existing friend groups will post and complete real dilemmas when a facilitator structures the loop.

**Target:** five Brazilian friend groups, 4–8 adults each; at least 20 owners/participants total.

**Test:**

- Recruit through known group organizers.
- Use a simple form to create a dilemma.
- Generate a private voting page or poll.
- Send decision reminder at selected pause.
- Send reflection prompt after 7 or 30 days.
- Manually format and deliver the Reveal.
- Interview owners and two voters per group.

**Success:**

- ≥40% of recruited participants create at least one dilemma;
- ≥50% of unique invite visitors vote;
- ≥70% of dilemmas record a decision;
- ≥50% of eligible dilemmas complete reflection;
- ≥50% of voters open or acknowledge the Reveal;
- at least three groups start a second dilemma without facilitator pressure.

**Failure signal:** voting is high but fewer than 30% of owners reflect later, or participants say the group chat alone is preferable.

**Decision:** whether the closed loop deserves a software MVP.

### Experiment 2 — Clickable create and guest-vote prototype

**Priority:** P0, parallel with concierge preparation

**Hypothesis:** structured sharing adds value without feeling like finance entry or oversharing.

**Target:** 12 owners and 24 invited recipients.

**Test:** moderated owner creation—including an offline-draft recovery task and optional private self-prediction—then unmoderated guest voting from shared prototype links.

**Success:**

- median creation under two minutes;
- offline participants understand that the recovered item is still private and requires explicit publish;
- median guest vote under 20 seconds;
- ≥80% understand audience and link privacy;
- ≥70% correctly explain that friends predict but do not decide;
- ≥70% rate tone as non-judgmental.

**Failure signal:** price exposure or account confusion prevents posting/voting.

**Decision:** flow, copy, privacy defaults, and whether price should be optional.

### Experiment 3 — Simulated delayed Reveal

**Priority:** P0

**Hypothesis:** voters care enough about outcomes to return after delay.

**Target:** recipients from Experiment 1.

**Test:** randomly assign Reveal timing and notification wording while keeping ethical, non-manipulative copy. Offer guests a one-dilemma Reveal subscription after voting and measure opt-in, delivery, open/acknowledgement, unsubscribe, and interview recall.

**Success:** ≥50% open/acknowledge; ≥60% can recall the dilemma; ≥30% vote again within 14 days.

**Failure signal:** voters remember the decision update but not the later satisfaction result.

**Decision:** whether to keep a two-stage update or compress decision and reflection.

### Experiment 4 — Prediction mechanic comparison

**Priority:** P1

**Hypothesis:** future-framed Buy/Wait/Skip is clearer and more engaging than plain advice or pure binary prediction.

**Variants:**

- A: Should they Buy / Wait / Skip?
- B: Will it feel Worth it / Not worth it?
- C: Future-framed Buy / Wait / Skip.

**Measure:** comprehension, response time, reason quality, desire to see outcome, perceived judgment.

**Success:** selected variant improves desire-to-see-outcome without reducing completion by more than 10%.

**Decision:** lock MVP vote model and scoring semantics.

### Experiment 5 — Category-aware reflection timing

**Priority:** P1 during closed beta

**Hypothesis:** 7-day prompts fit short-lived/consumed outcomes, 30-day prompts fit durable purchases, and a single Too early to tell reschedule prevents forced or low-quality answers.

**Test:** compare completion and perceived timing across fashion, tech, beauty, home, hobby, gifts, and experiences. Store a 90-day-capable rule for long-horizon categories but do not activate it during the initial MVP cohort.

**Failure signal:** more than 25% say the prompt is materially too early/late for their category.

**Decision:** category mapping, whether Too early to tell is sufficient, and whether 90-day follow-up should ever activate.

### Experiment 6 — Insight value diary study

**Priority:** P2

**Hypothesis:** users perceive value before a statistically large history exists.

**Target:** 15 active owners over eight weeks.

**Test:** show chronological history only, then progressively add category and reason summaries with sample warnings.

**Success:** users accurately describe a useful pattern and report at least one changed or affirmed decision without treating the app as authority.

**Decision:** post-MVP insight scope and premium potential.

### Experiment 7 — Owner self-prediction and Illusion Filter

**Priority:** P1 during prototype and closed beta

**Hypothesis:** an optional private self-prediction creates a meaningful “what I expected versus what happened” insight without materially increasing creation abandonment.

**Test:** randomly offer the private Yes / Not sure / No Future You question after the required creation fields. After reflection, show the owner a private comparison of self-expectation, friend aggregate, and actual outcome.

**Success:**

- creation completion decreases by no more than 10% relative to control;
- median creation time stays within the two-minute target;
- at least 50% of eligible owners describe the comparison as useful or surprising for a concrete reason;
- no repeated privacy misunderstanding about friends seeing the self-prediction.

**Failure signal:** owners treat the question as a promise, feel judged by the comparison, or creation abandonment rises materially.

**Decision:** retain, revise, or remove the field; determine whether the Illusion Filter belongs in history after sufficient samples.

## 3. Interview guide

### Owners

- Tell me about the last time you sent a purchase link to friends.
- What made you share or keep it private?
- How did you decide who to ask?
- What would feel uncomfortable to reveal: item, price, reason, outcome?
- Did the pause or friend input change anything?
- Would you want friends to know later whether it was worth it? Why?
- What would make you complete the 30-day check-in?
- When would this feel judgmental or childish?

### Participants

- What were you trying to help the owner decide?
- Did the options match what you wanted to say?
- Did you expect to hear what happened?
- What part of the Reveal mattered?
- Would a prediction score feel fun, useful, or uncomfortable?
- Would you post your own dilemma after this experience?

Avoid asking “Would you use this app?” as primary evidence. Focus on recent behavior and observed completion.

## 4. Launch strategy

### Phase 0 — Manual pilot

- Portuguese only.
- Brazil only.
- Adults only.
- Five invitation-only friend groups.
- No app store release.
- Operator manually supports reminders and Reveals.

### Phase 1 — Closed product beta

- 50–100 owner accounts across 10–20 groups.
- Mobile app for owners; mobile web for guest votes/Reveals.
- No public discovery.
- Weekly cohort review and qualitative interviews.
- Eight-week observation window.

### Phase 2 — Referral beta

Open one invitation slot after a participant views a Reveal or completes two votes. Do not open a generic public waitlist until group-level completion is healthy.

### Phase 3 — Broader launch

Only after:

- closed-loop thresholds hold across multiple cohorts;
- moderation and guest-abuse controls are stable;
- organic second-dilemma rate is healthy;
- a clear positioning message outperforms impulse-control framing.

## 5. Cold-start design

The atomic network is a friend group, not the whole app.

- Owner brings the initial audience through an existing messaging channel.
- Guest can vote without installing and may separately opt into only that dilemma's Reveal.
- Reveal brings the same group back.
- Empty Home shows owned/shared activity, not a fake public feed.
- Sample dilemmas are clearly labeled demos and never mixed with real people.
- If a dilemma has no votes after 24 hours, help the owner reshare or close it; do not route it publicly without consent.

## 6. Organic loops

### Share loop

Owner creates → sends unlisted link → friend votes → post-vote account offer.

MVP metric: guest-vote conversion, one-dilemma Reveal opt-in, and guest-to-account conversion. Account conversion is secondary; do not damage voting or bundle marketing consent to increase it.

### Reveal loop

Friend votes → decision update → later Reveal → friend returns → sees own prediction → votes again.

This is the primary retention hypothesis.

### Creator loop

Participant experiences a useful Reveal → creates own dilemma → invites overlapping group.

MVP metric: participant-to-owner conversion within 30 days.

### Social identity loop

After sufficient resolved predictions, participant sees a private descriptor such as “You read Lu's tech choices well.”

Deferred until scoring semantics and safety are validated.

### Challenge loop

Defer. Challenges can shift the product toward restriction, streak pressure, and performative consumption.

## 7. Acquisition channels to test

1. Founder-led recruitment of existing WhatsApp groups.
2. Small conscious-consumption or fashion/tech communities, framed around decision quality rather than saving.
3. Creator demonstrations of a full dilemma-to-Reveal story.
4. Referral after a Reveal.

Avoid paid acquisition until a cohort completes the loop. A low-cost vote is meaningless if reflection and Reveal fail.

## 8. Launch positioning test

Test these messages:

- **Recommended:** “Spend on what you will be glad you bought.”
- “Ask friends now. See what Future You says later.”
- “The purchase decisions your group chat never follows up on.”

Measure create intent after users see the complete loop, not click-through alone.

## 9. Stop/continue rules

### Continue

Proceed from manual pilot to product beta if at least four of six core thresholds pass and reflection/Reveal are among the passing behaviors.

### Iterate

Iterate once if posting and voting work but delayed completion falls between 30% and 50%. Test shorter timing, one-tap reflection, and stronger expectation-setting.

### Stop or reposition

Stop the social outcome thesis if reflection remains below 30% after one focused iteration, or if users consistently prefer an unstructured group chat. Consider a private purchase journal only as a new thesis, not a disguised continuation.
