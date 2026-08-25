# Generation prompts

The images were created with the built-in image-generation tool using the `ui-mockup` workflow. The second board used the first board as a visual-system reference. A final targeted edit removed an unapproved 14-day pause option from the first board.

## Prompt 1 — Decision phase

```text
Use case: ui-mockup
Asset type: polished mobile product UI board, first half of the Before I Buy closed loop
Primary request: Create a high-fidelity product-design presentation board showing four distinct smartphone screens side by side for these exact stages: 1) Temptation, 2) Friend predictions, 3) Pause, 4) Decision update.
Scene/backdrop: warm off-white editorial presentation background with very subtle paper texture; no decorative scene objects.
Style/medium: realistic, shippable consumer mobile UI, not concept art; contemporary calm social app; highly legible spacing and practical controls.
Composition/framing: wide landscape board with four complete evenly sized portrait phones, straight-on, generous spacing, no overlap. Put a small stage number and title above each phone.
Visual system: cream surfaces, charcoal typography, one warm coral/terracotta action accent, muted teal and lavender secondary accents, restrained rounded cards, thin dividers, friendly editorial sans-serif, product photo remains primary. Neutral treatment of Buy, Wait, Skip—no red-versus-green moral coding.
Screen 1 — exact title "New temptation". Show a tasteful product photo card for neutral unbranded over-ear headphones, item name "Noise-cancelling headphones", price "R$ 2,400", prompt "Why are you considering this now?", short answer "Better focus for work and travel", pause selector with "3 days" selected, privacy row "Close friends", primary button "Review & share".
Screen 2 — exact title "What will Future Lu be glad she did?" Show the same headphones and reason in compact form; three equal choice cards "Buy — likely glad", "Wait — too soon", "Skip — likely glad"; optional reason field; primary button "Send prediction". No results visible before voting.
Screen 3 — exact title "A little space helps". Show same item, a calm circular 2-day remaining indicator, text "The pause ends Friday", four small friend avatars, summary "4 friends shared perspective", a quiet card "Your choice is still yours", secondary action "View perspectives", no urgency.
Screen 4 — exact title "The pause is over". Re-show the original reason, compact prediction distribution Buy 25%, Wait 50%, Skip 25%, two short representative reason snippets, prompt "What did you decide?", choices "Bought the original", "Bought an alternative", "Skipped it", "It became unavailable", "Still deciding", with "Bought the original" selected and primary button "Save decision".
Text: use only the specified UI copy plus minimal standard status-bar text; render all specified wording accurately.
Constraints: consistent app shell and design tokens across all four screens; accessible contrast; large readable text; touch-friendly controls; no follower counts; no leaderboards; no banking imagery; no charts implying profit or loss; no logos other than a tiny abstract warm circular app mark; no watermark.
Avoid: finance dashboard aesthetic, casino/game-show styling, neon gradients, glassmorphism, excessive shadows, childish illustrations, crowded tiny text, purchase celebration, moral judgment.
```

## Prompt 2 — Reflection and learning phase

```text
Use case: ui-mockup
Asset type: polished mobile product UI board, second half of the Before I Buy closed loop
Input images: Image 1 is a strict visual-system and presentation-layout reference only; create a new board and new screens, do not repeat its screen content.
Primary request: Create a high-fidelity product-design presentation board showing four distinct smartphone screens side by side for these exact stages: 5) Later reflection, 6) Reveal, 7) Prediction reputation, 8) Personal insight.
Scene/backdrop: match Image 1's warm off-white editorial presentation background and straight-on four-phone composition exactly.
Style/medium: realistic, shippable consumer mobile UI, not concept art; match Image 1's phone hardware, cream surfaces, charcoal typography, coral/terracotta primary accent, muted teal and lavender secondary accents, restrained cards, spacing, icons, shadows, and typography.
Composition/framing: wide landscape board with four complete evenly sized portrait phones, straight-on, generous spacing, no overlap. Put a small stage number and title above each phone, matching Image 1.
Use the same unbranded noise-cancelling headphones and the same fictional user Lu from Image 1 for continuity.
Screen 5 — exact title "How does the choice feel now?" Compact item header with headphones, "Noise-cancelling headphones", "30 days later", original reason "Better focus for work and travel". First prompt "Did you keep it?" with "Kept it" selected and "Returned or refunded it" unselected. Main prompt "Would you make the same choice again?" with three equal options "Yes", "Not sure", "No", and "Yes" selected. Optional note field and primary button "Preview Reveal".
Screen 6 — exact title "Result is in". Celebratory but restrained closure card: "Lu bought the headphones" and "Would make the same choice again". Show group prediction bar Buy 25%, Wait 50%, Skip 25%; participant callout "You predicted Wait" and neutral status "Different from the outcome"; owner-approved note "They made travel and focused work noticeably calmer." Primary button "See prediction history". No confetti explosion.
Screen 7 — exact title "Your prediction reputation". Show private profile summary "12 resolved predictions", "7 aligned", "3 different", "2 unresolved". Include calm calibration ring "58% aligned" and three category rows: "Tech 4 of 6", "Travel 2 of 3", "Style 1 of 3". Add small explanatory card "A pattern to watch—not a verdict." No public rank, no follower count, no global leaderboard.
Screen 8 — exact title "What Future You is learning". Show personal private insight dashboard with headline card "You would make the same choice again for 8 of 10 completed decisions". Include sample and timeframe "10 decisions · Last 12 months". Three insight cards: "Travel brings lasting satisfaction — 3 of 3", "Waiting changed 4 decisions", "Friends underestimated your tech upgrades — 3 of 5". Include owner-private comparison card titled "Illusion Filter" with three simple labels "You expected", "Friends predicted", "You reported" and a neutral aligned/mixed summary. Bottom link "Review the decisions behind this".
Text: use only the specified UI copy plus minimal standard status-bar text; render all specified wording accurately.
Constraints: exact visual continuity with Image 1; accessible contrast; readable UI; all data presented as private and sample-based; Buy and Skip remain equally legitimate; no paywall; no follower counts; no public ranks; no leaderboards; no money-saved claims; no banking imagery; no logos other than the same tiny abstract warm circular app mark; no watermark.
Avoid: finance dashboard aesthetic, profit/loss colors, casino or game-show styling, trophies, crowns, medals, neon gradients, excessive confetti, moral judgment, shame, childish illustrations, crowded tiny text.
```

## Prompt 3 — Pause-option correction

```text
Use case: precise-object-edit
Asset type: polished mobile product UI board
Input images: Image 1 is the edit target.
Primary request: On phone screen 1 only, change the "Pause before deciding" segmented control from four choices to exactly three equal choices: "1 day", "3 days", "7 days". Keep "3 days" selected with the same coral highlight and check mark.
Constraints: change only that segmented control. Preserve every other pixel-level design decision as closely as possible: all four phones, headings, screen copy, product image, colors, typography, spacing, icons, shadows, backdrop, proportions, and all content on phone screens 2, 3, and 4. Do not add "14 days" anywhere. No watermark.
```

