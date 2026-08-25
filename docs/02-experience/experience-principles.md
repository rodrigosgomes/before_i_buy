# Experience principles

## 1. Emotional design target

The experience should feel like a thoughtful exchange among friends, not a finance lecture, courtroom, shopping ad, or addiction loop.

Desired qualities:

- curious;
- warm;
- concise;
- lightly playful;
- honest about uncertainty;
- non-judgmental;
- calm enough to interrupt urgency.

## 2. Language rules

### Prefer

- “What will Future You be glad you did?”
- “You chose to buy it. How does that choice feel now?”
- “You skipped it. Would you make the same choice again?”
- “Three friends think waiting would give you more clarity.”
- “Not enough history yet—complete more Reveals to see a pattern.”

### Avoid

- “Good job saving money.”
- “Bad purchase.”
- “Financial crime.”
- “Your friends were right; you were wrong.”
- “AI says you should buy.”
- “You failed your streak.”
- “Only 2 hours left!” unless the user set a real deadline.

### Outcome language

- **Aligned prediction**, not winner.
- **Different from the outcome**, not loser.
- **Unresolved**, not wrong, when the owner chose Not sure or withheld a result.
- **Would make the same choice again**, not rational/correct decision.
- **Bought an alternative**, not smarter purchase.
- **Returned/refunded**, not failed purchase.
- **Item unavailable**, not skipped, because the choice was not voluntary.

## 3. Reflection design

Research on purchase interventions suggests that a pause can interrupt immediate shopping flow and that prompts about need, alternatives, and reasons can support reflection, while overly burdensome tasks harm experience ([Kwon et al., 2021](https://www.bckwon.com/pdf/purchase.pdf)).

Product implication:

- Ask one required reflection question, not a questionnaire.
- Reuse the owner's own original reason.
- Add at most one optional contextual prompt.
- Use category-aware timing: 7 days for short-lived outcomes and 30 days for durable purchases; allow Too early to tell once.
- Ask whether a bought item was kept or returned/refunded before interpreting satisfaction.
- Use gift-specific reflection and keep it outside self-use satisfaction analytics.
- Never block the owner from deciding.
- Make “buy” and “skip” equally legitimate.

## 4. Gamification with purpose

### Allowed in MVP

- count of resolved predictions;
- accuracy only after five resolved confident predictions;
- private recent outcomes;
- gentle category descriptors after sufficient history.

Behavioral purpose: encourage completion and demonstrate learning.

### Deferred

- friend-specific accuracy;
- category expertise;
- group challenges;
- Reveal completion milestones.

### Prohibited for now

- daily-use streaks;
- global leaderboards;
- coins/loot boxes;
- public “biggest saver/spender” rankings;
- loss-framed notifications;
- infinite-scroll public feed;
- variable rewards unrelated to a real outcome.

## 5. Insight design

Every personal insight must include:

- the observation;
- sample size;
- time range;
- underlying dilemmas;
- neutral language;
- an explanation that correlation is not causation where relevant.

Example:

> You would make the same choice again for 4 of 5 travel decisions in the last 12 months. This is a small sample, so treat it as a pattern to watch—not a rule.

Never label categories as inherently “good” or “bad.” Never compare users' spending amounts.

### Illusion Filter experiment

When the optional self-prediction experiment is active, the owner may later see:

- what they privately expected;
- what friends predicted in aggregate;
- what they actually reported.

The comparison is owner-private by default, uses neutral language, and is not presented as a personality diagnosis. Show it only for completed entries and include sample size for any aggregate pattern. The extra creation question must be removed if it materially increases abandonment.

## 6. Accessibility target

Use [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/) as the web target and apply equivalent principles to mobile semantics.

Required design behaviors:

- support system text scaling without clipped content;
- minimum 44×44 logical-pixel touch targets, with adequate spacing;
- contrast that passes AA for text and meaningful controls;
- never encode Buy/Wait/Skip or correct/incorrect by color alone;
- screen-reader labels include control purpose and state;
- predictable focus order and visible focus on web;
- no swipe-only required action;
- reduced-motion alternative for Reveal animation;
- captions/transcripts for any future audio/video;
- error messages adjacent to fields and announced to assistive technology;
- accessible authentication with paste/password-manager support;
- Portuguese-first content tested for longer labels and screen-reader pronunciation.

## 7. Visual direction

The app may be expressive, but product images and friend content should remain primary.

Recommended qualities:

- calm neutral surfaces;
- one warm accent for actions;
- distinct but non-moral semantic treatment for Buy, Wait, and Skip;
- rounded cards used sparingly;
- restrained Reveal motion that communicates closure;
- no casino, stock-trading, courtroom, or red-versus-green profit/loss aesthetic.

## 8. Privacy in the interface

- Show audience and link-preview behavior before publish.
- Use a generic social preview by default.
- Warn before uploading screenshots that may contain names, addresses, order numbers, or payment details.
- Make revoke, delete, report, and block findable from the relevant item.
- Explain private versus participant-visible notes at the input point.
- Explain that the owner self-prediction is private and hidden from voters.
- Keep offline captures visibly labeled **Draft—not shared yet** until explicit publish.
- Make guest Reveal consent dilemma-specific, separate from marketing, and easy to withdraw.
- Never use contacts permission as the default invitation path.

## 9. Content templates

### Create prompt

**Why are you considering this now?**

Helper: “What do you expect this to change, replace, or make possible?”

### Optional private self-prediction

**Do you expect Future You to make the same choice again?**

- Yes
- Not sure
- No

Helper: “Private—friends will not see this before or after voting unless a future sharing option is explicitly added.”

### Vote prompt

**What will Future [name] be glad they did?**

- Buy — likely glad
- Wait — too soon
- Skip — likely glad

Helper: “Be useful and kind. They make the final call.”

### Decision prompt

**The pause is over. What did you decide?**

“Your friends offered perspective. The choice is yours.”

- Bought the original
- Bought an alternative
- Skipped it
- It became unavailable
- Still deciding

### Bought reflection

**Did you keep it?**

- Kept it
- Returned or refunded it

**Would you make the same choice again?**

“You wanted this because: [original reason]”

### Skipped reflection

**How does skipping it feel now?**

- Glad I skipped
- Still want it
- Bought an alternative
- The original became unavailable

Then: **Would you make the same choice again?**

### Gift reflection

**Did choosing this gift feel worthwhile?**

- Yes
- Not sure
- No

Helper: “Gift outcomes stay separate from insights about purchases for your own use.”

### Too early

**Too early to tell?**

“We can ask once more later. This outcome stays unresolved until then.”

### Private closure

“You can keep this reflection private. Friends will know the dilemma closed, but they will not see or score the outcome.”

## 10. Design review checklist

- Does the flow preserve user agency?
- Is Buy treated as a valid outcome?
- Can the task finish quickly?
- Is audience/visibility clear at the moment of sharing?
- Is every color signal duplicated with text/iconography?
- Does the screen work at large text sizes?
- Is there any unnecessary social comparison?
- Does a score have a clear learning purpose?
- Are uncertainty and small samples visible?
- Can users recover, revoke, block, report, and delete?
