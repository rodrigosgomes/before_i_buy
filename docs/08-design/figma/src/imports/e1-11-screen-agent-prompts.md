# Delivery 1 — Master Prompt and Tasks for the 11 Base Screens

**Usage:** reproducible briefing for design, Figma, Flutter, or Web agents

**Reference viewport:** `393 × 852 px`

**Web:** mobile-first from `320 px`, centered content with maximum width of `640 px`

## 1. Expected Outcome

Produce a harmonious set of 11 base screens proving the two Delivery 1 handoffs:

`creator captures and publishes a private dilemma → guest opens and votes without an account`

The screens must feel like chapters of the same experience. Do not create eleven isolated visual concepts. The agent must first execute the shared task `E1-DS00` and only then assemble screens `E1-S01` to `E1-S11`.

## 2. Mandatory Sources

Before starting work, read completely and follow, in this order:

1. `docs/01-product/first-delivery-mini-prd.md`;
2. `docs/06-delivery/DECISION_LOG.md`;
3. `docs/08-design/e1-design-system-contract.md`;
4. `docs/DESIGN.md`;
5. this document.

In case of conflict, the Decision Log and mini-PRD prevail. Do not recover features from older documents that are outside Delivery 1.

## 3. Copyable Master Prompt

Use the block below as the prefix for any screen task.

```text
You are product director and senior UI designer for Before I Buy. Create a shippable interface for Brazilian adults, following the Playful Calm direction and Material Design 3 Expressive. The product is a private social game for purchase decisions, not a bank, spreadsheet, therapy, public network, or casino.

First read the Delivery 1 mini-PRD, Decision Log, and the e1-design-system-contract.md contract. Do not change product rules. This delivery includes only local draft, explicit review, private publishing, invite, and guest voting without an account.

Exclusively use tokens and Bib* components from the contract. If a component is missing, do not silently improvise: log the gap, propose the smallest reusable extension, and implement it before the screen. Preserve names, anatomy, states, and copy between Flutter Material 3 and React/MUI.

Visual direction: warm canvas #FAF9F6, white or sandstone surfaces, River Slate text, accessible dark terracotta primary action, rounded shapes of 18–28 px, expressive typographic hierarchy, simple icons, and brief motion. Buy, Wait, and Skip have equal moral weight. Do not use right/wrong green/red, artificial urgency, anxious countdowns, confetti, coins, rankings, followers, public feeds, or financial aesthetics.

Copy: Brazilian Portuguese, short, warm, and non-moralizing sentences. Do not add product URLs, vote comments/reasons, guest name/email, Reveal opt-in, decision, reflection, score, or AI. The public link preview is always generic. Before voting, no aggregates may be shown or inferred.

Accessibility: WCAG 2.2 AA, minimum 48×48 target, AA contrast, up to 200% text scale, predictable reading order, visible Web focus, full keyboard navigation, semantic labels, and no information conveyed by color alone. Provide reduced motion alternatives.

Use the canonical fixture: Lu; Fone com cancelamento de ruído; R$ 2.400,00; Tecnologia; “Quero mais foco para trabalhar e viajar com menos ruído.”; Para mim; 3-day pause; votes Buy 1, Wait 2, Skip 1.

For the requested screen, deliver:
1. main 393×852 frame;
2. 320 px or 200% text variant;
3. loading, empty, error, or selection state where applicable;
4. list of Bib* components used;
5. focus/reading order and accessible labels;
6. responsive and motion behavior;
7. handoff in the format defined in the contract.
```

## 4. Base Screens Inventory

| ID | Client | Screen | Role in Flow |
|---|---|---|---|
| `E1-S01` | Flutter | Empty home | Start the first temptation |
| `E1-S02` | Flutter | New temptation | Capture the dilemma in under 2 minutes |
| `E1-S03` | Flutter | Dilemma review | Confirm content and explicit publishing |
| `E1-S04` | Flutter | Guest preview | Make audience and content visible before publishing |
| `E1-S05` | Flutter | Published & share | Deliver private link via native share sheet |
| `E1-S06` | Flutter | Active dilemma without votes | Monitor and re-share without pressure |
| `E1-S07` | Web | Secure invite opening | Validate access without leaking content |
| `E1-S08` | Web | Voting before selection | Explain and allow prediction without account |
| `E1-S09` | Web | Vote selected | Confirm intent before submission |
| `E1-S10` | Web | Vote confirmed | Provide immediate closure without account or Reveal |
| `E1-S11` | Web | Aggregates after voting | Show anonymous distribution and allow changing vote |

## 5. Shared Task — `E1-DS00`

### Objective

Create the foundation before any screen, so that different agents assemble
compatible interfaces in Flutter and MUI.

### Work

1. Materialize tokens from the contract into a single semantic source.
2. Create the primitives `BibPageShell`, `BibTopBar`, `BibPrimaryButton`,
   `BibSecondaryButton`, `BibTextButton`, `BibTextField`, `BibCurrencyField`,
   `BibSelectField`, `BibSegmentedChoice`, `BibInlineMessage`,
   `BibBottomActionBar`, and `BibLoadingBlock`.
3. Create the domain components `BibDraftBanner`, `BibPrivacyNotice`,
   `BibDilemmaSummary`, `BibGuestPreviewFrame`, `BibStatusChip`,
   `BibEmptyState`, `BibVoteOption`, and `BibVoteDistribution`.
4. Produce an equivalent catalog/Storybook with normal, pressed, focus, loading,
   disabled, error, and enlarged text states.
5. Configure Material 3 theme in Flutter and MUI `createTheme` on Web from the
   generated tokens, without magic values in components.
6. Create the shared canonical fixture and reference snapshots.

### Composition Rules

- Four-column grid, 16 px horizontal margin, and vertical rhythm of 12/20/32.
- One dominant CTA per screen; destructive actions never compete visually.
- Mobile app uses safe area; Web uses centered content and maintains comfortable
  reading on desktop without turning into a dashboard.
- Action bar may be fixed only when it does not obscure keyboard, focus, or
  text.
- Icons are always accompanied by labels on important actions.
- Selected voting state uses border, filled icon, “Meu palpite” (“My prediction”)
  label, and gentle container shift.

### Planned Validation

- automated contrast testing for token pairs;
- screenshot/golden test for each component state;
- 200% text test at 320 px;
- keyboard and focus testing for Web components;
- semantics/aria-name, role, state, and announced error testing;
- visual comparison between mobile and Web `BibDilemmaSummary`.

### Output

Approved catalog, versioned tokens, adapted components on both platforms, and no
product screens assembled yet.

## 6. Specific Screen Prompts

### `E1-S01` — Empty Home

**Emotional objective:** make the first step feel lightweight: take a desire out
of your head and put it in a calmer space.

**Visual hierarchy:** minimal `BibTopBar` with brand mark and product name;
organic hero occupying the first third; headline; supporting text; small
three-chapter representation; bottom CTA.

**Canonical copy:**

- title: **“Um pouco de espaço antes de decidir”** (“A little space before deciding”);
- support: “Organize a vontade, peça perspectiva a pessoas próximas e escolha no
  seu tempo.” (“Sort out what you're feeling, get perspective from people close
  to you, and choose on your own time.”);
- chapters: “Conte o que está pensando” / “Ouça perspectivas” / “Decida você”
  (“Share what you're thinking” / “Hear perspectives” / “You decide”);
- CTA: **“Criar minha primeira tentação”** (“Create my first temptation”);
- privacy: “Seus dilemas são privados e só abrem para quem recebe o link.”
  (“Your dilemmas are private and only open for those who receive the link.”).

**Components:** `BibPageShell`, `BibTopBar`, `BibBrandMark`, `BibEmptyState`,
`BibPrivacyNotice`, `BibPrimaryButton`, `BibBottomActionBar`.

**Direction:** abstract illustration with conversation and pause shapes,
without product, coins, or piggy bank. Avoid empty feed cards. CTA must be
visible without scrolling on standard frame, but follow flow under enlarged
text.

**States:** first open; short session loading; loading error with “Tentar
novamente” (“Try again”) CTA.

**Acceptance criteria:** it is evident there is no public community; the only
dominant action starts `E1-S02`; user understands privacy without reading legal
text.

### `E1-S02` — New Temptation

**Emotional objective:** capture context without feeling like expense logging
or an interrogation.

**Visual hierarchy:** top bar with back button and title; `BibDraftBanner`;
fields on a single scrollable page; purpose and pause as visual choices;
“Revisar” (“Review”) CTA at the bottom.

**Canonical copy and order:**

1. title: **“Nova tentação”** (“New temptation”);
2. banner: **“Rascunho — não compartilhado”** (“Draft — not shared”);
3. `Nome do item` (`Item name`) — helper “De 2 a 80 caracteres” (“From 2 to 80 characters”);
4. `Preço` (`Price`) — visual prefix `R$`, BRL input;
5. `Categoria` (`Category`);
6. question: **“Por que você está pensando nisso agora?”** (“Why are you considering this now?”);
7. helper: “O que você espera que isso mude, substitua ou torne possível?” (“What do you hope this changes, replaces, or makes possible?”);
8. reason counter: `0/500`, minimum 10;
9. `É para quem?` (`Who is this for?`) — “Para mim” (“For me”) / “É um presente” (“It's a gift”);
10. `Quanto espaço você quer antes de decidir?` (`How much space do you want before deciding?`) — “24 horas” / “3 dias” / “7 dias” (“24 hours” / “3 days” / “7 days”), with 3 days suggested;
11. CTA: **“Revisar”** (“Review”).

**Components:** `BibPageShell`, `BibTopBar`, `BibDraftBanner`, `BibTextField`,
`BibCurrencyField`, `BibSelectField`, `BibSegmentedChoice`,
`BibPrivacyNotice`, `BibPrimaryButton`, `BibBottomActionBar`.

**Direction:** use an expressive surface for the “why” question, but do not
split the form into a wizard. Labels remain visible. Do not add upload, camera,
URL, income, or budget.

**States:** empty; filled fixture; inline validations; keyboard open; draft
saved locally; offline with message “Salvo neste aparelho” (“Saved on this device”).

**Acceptance criteria:** completion possible in under two minutes; interruption
does not lose data; CTA never publishes; text scale does not clip choices.

### `E1-S03` — Dilemma Review

**Emotional objective:** provide control and create a mindful pause before any
sharing.

**Visual hierarchy:** title and short guidance; full editorial summary;
private status; two actions: edit and proceed to preview.

**Canonical copy:**

- title: **“Tudo certo para pedir uma perspectiva?”** (“All set to ask for perspective?”);
- support: “Confira com calma. Nada foi compartilhado ainda.” (“Take your time checking. Nothing has been shared yet.”);
- status: **“Rascunho — não compartilhado”** (“Draft — not shared”);
- sections: “O que você está considerando” (“What you are considering”), “Por que agora” (“Why now”), “Pausa escolhida” (“Chosen pause”);
- secondary action: “Editar” (“Edit”);
- CTA: **“Ver como meus amigos vão ver”** (“See how my friends will see it”).

**Components:** `BibPageShell`, `BibTopBar`, `BibDraftBanner`,
`BibDilemmaSummary`, `BibPrivacyNotice`, `BibSecondaryButton`,
`BibPrimaryButton`, `BibBottomActionBar`.

**Direction:** summary should read like a short story, with the reason on a
note/card-like surface; price is context, not hero. Do not show votes,
fictional people, or links.

**States:** normal review; recovered draft review with message “Recuperamos seu
rascunho. Revise antes de publicar” (“We recovered your draft. Review before publishing”);
long content; offline.

**Acceptance criteria:** no gesture publishes; editing returns with data
preserved; all guest-visible fields can be inspected.

### `E1-S04` — Guest Preview

**Emotional objective:** remove surprises about audience and exposure before
publishing.

**Visual hierarchy:** top bar with “Prévia” (“Preview”) label; faithful Web
frame; forwardable link warning; explicit proceed CTA.

**Canonical copy outside the frame:**

- title: **“É assim que o convite vai aparecer”** (“This is how the invite will appear”);
- support: “Somente quem abrir um link válido verá estas informações.” (“Only those who open a valid link will see this information.”);
- warning: **“Links podem ser encaminhados”** (“Links can be forwarded”);
- detail: “Você poderá revogar o acesso quando quiser.” (“You can revoke access whenever you want.”);
- secondary action: “Voltar e editar” (“Go back and edit”);
- CTA: **“Continuar para publicar”** (“Continue to publish”).

**Content inside the frame:** must reproduce top and order of `E1-S08`,
including name Lu, dilemma summary, and vote options, but show a banner
**“Prévia — nenhuma ação será enviada”** (“Preview — no action will be sent”) and
disable submission.

**Components:** `BibPageShell`, `BibTopBar`, `BibGuestPreviewFrame`,
`BibDilemmaSummary`, `BibVoteOption`, `BibPrivacyNotice`,
`BibSecondaryButton`, `BibPrimaryButton`, `BibBottomActionBar`.

**Direction:** frame must not look like a decorative screenshot; must be an
instance of the same Web page contract. Do not render OpenGraph with item data:
if social preview is shown, it must be generic.

**States:** standard content; 500-character reason; 200% text; return to
editing.

**Acceptance criteria:** data order matches `E1-S08`; publishing remains a
separate and explicit action; no fictional identities or aggregates appear.

### `E1-S05` — Published & Share

**Emotional objective:** confirm that the dilemma is private and frame the next
step as sharing with chosen people.

**Visual hierarchy:** subtle success indicator; title; invite status;
privacy explanation; share CTA; “Agora não” (“Not now”) action.

**Canonical copy:**

- title: **“Seu dilema está pronto”** (“Your dilemma is ready”);
- support: “Ele continua privado até você compartilhar o convite.” (“It stays private until you share the invite.”);
- status: **“Convite ativo · privado e não listado”** (“Active invite · private and unlisted”);
- notice: “A prévia no WhatsApp e em outros apps é genérica. Item, preço e seu
  nome aparecem somente depois que o link é validado.” (“The preview in WhatsApp
  and other apps is generic. Item, price, and your name appear only after the
  link is validated.”);
- CTA: **“Compartilhar convite”** (“Share invite”);
- secondary action: “Agora não” (“Not now”).

**Components:** `BibPageShell`, `BibTopBar`, `BibBrandMark`, `BibStatusChip`,
`BibDilemmaSummary`, `BibPrivacyNotice`, `BibPrimaryButton`, `BibTextButton`.

**Direction:** micro-celebration under 600 ms with settling shape, no confetti.
The summary can be compact. CTA opens native sheet; do not design a custom
contacts list or request address book permissions.

**States:** publishing complete; native sheet open; share canceled; error
retrieving link with safe retry, without showing token.

**Acceptance criteria:** “Published” does not mean public; canceling share keeps
invite manageable; no token or full URL appears visually or in error states.

### `E1-S06` — Active Dilemma Without Votes

**Emotional objective:** provide tracking and control without framing absence of
responses as failure or urgency.

**Visual hierarchy:** top bar; “Coletando palpites” (“Collecting predictions”)
status; compact summary; remaining time; social empty state; re-share; access
menu.

**Canonical copy:**

- status: **“Coletando palpites”** (“Collecting predictions”);
- deadline: “A pausa termina em 2 dias” (“The pause ends in 2 days”);
- empty title: **“Ainda sem palpites”** (“No predictions yet”);
- support: “Tudo bem. Compartilhe com alguém cuja perspectiva importa para
  você.” (“That's okay. Share with someone whose perspective matters to you.”);
- CTA: **“Compartilhar novamente”** (“Share again”);
- secondary action: “Gerenciar convite” (“Manage invite”);
- autonomy support: “A decisão final continua sendo sua.” (“The final decision remains yours.”).

**Components:** `BibPageShell`, `BibTopBar`, `BibStatusChip`,
`BibDilemmaSummary`, `BibEmptyState`, `BibPrivacyNotice`,
`BibPrimaryButton`, `BibSecondaryButton`.

**Direction:** time is calm text, never a circular countdown clock. Do not
create ghost avatars, “0 of X” bars, or pushy invites. “Gerenciar convite” leads
to future revoke/delete actions without making them heroes.

**States:** no votes; count loading; refresh error; offline using last known
state with textual timestamp.

**Acceptance criteria:** no simulated empty results; absence of votes does not
receive error coloring; re-sharing uses the same generic preview.

### `E1-S07` — Secure Invite Opening

**Emotional objective:** communicate fast response while server validates the
link, without revealing sensitive data or suggesting whether content exists.

**Visual hierarchy:** small brand mark; skeleton for title, summary, and three
options; subtle centered message.

**Canonical copy:** **“Abrindo convite…”** (“Opening invite…”). Do not display
name, item, price, category, reason, vote count, or invite state during
validation.

**Components:** `BibPageShell`, `BibBrandMark`, `BibLoadingBlock`.

**Direction:** ultra-lightweight Web. Skeleton uses geometry of upcoming page,
but no real text. Avoid large spinner and infinite animation; reduced motion
uses static blocks.

**States:** normal loading; slow network with “Isso está levando um pouco mais
de tempo” (“This is taking a little longer”); transition to `E1-S08`; transition
to generic unavailable; recoverable error and `429` without distinguishing
cause.

**Acceptance criteria:** no data appears before authorized response; no
significant layout shift; initial focus moves to next screen title or error
message, never to skeleton.

### `E1-S08` — Voting Before Selection

**Emotional objective:** allow a close friend to understand context and weigh
in within 20 seconds, with no account or installation.

**Visual hierarchy:** product brand mark and phrase; creator intro; dilemma
summary; central question; three equivalent options; autonomy helper.

**Canonical copy and order:**

1. small brand mark and “Before I Buy”;
2. **“Lu quer sua perspectiva”** (“Lu wants your perspective”);
3. “Você foi convidado a opinar sobre uma decisão de compra.” (“You've been invited to give your perspective on a purchase decision.”);
4. `BibDilemmaSummary` with full fixture and “A pausa termina em 2 dias” (“The pause ends in 2 days”);
5. question: **“O que a Lu provavelmente vai ficar feliz de ter feito?”** (“What will Lu likely be glad she did?”);
6. “Comprar — provavelmente vai ficar feliz” (“Buy — likely glad”);
7. “Esperar — ainda é cedo” (“Wait — too soon”);
8. “Deixar pra lá — provavelmente vai ficar feliz” (“Skip — likely glad”);
9. helper: “Seu palpite ajuda. A decisão final é da Lu.” (“Your prediction helps. The final decision is Lu's.”).

**Components:** `BibPageShell`, `BibBrandMark`, `BibDilemmaSummary`,
`BibVoteOption`, `BibPrivacyNotice`.

**Direction:** options stacked on 320–393 px and potentially three columns only
when width and legibility allow. No app install banner, login, email, name,
vote reason, or results. Price receives secondary hierarchy relative to reason.

**States:** normal without selection; focus on each option; invite near deadline
without urgent language; long text; 200% content.

**Acceptance criteria:** no hint of aggregates; Tab traverses options in order;
screen reader announces label, explanation, and unselected state.

### `E1-S09` — Vote Selected

**Emotional objective:** make intent unmistakable and still reversible prior to
sending.

**Visual hierarchy:** exactly maintains composition of `E1-S08`; selected option
receives neutral emphasis; action bar appears with CTA.

**Canonical copy of the example:**

- selected option: **“Esperar — ainda é cedo”** (“Wait — too soon”);
- internal badge: **“Meu palpite”** (“My prediction”);
- CTA: **“Enviar meu palpite”** (“Send my prediction”);
- implicit action: tapping another option replaces selection before submission.

**Components:** those from `E1-S08`, plus `BibPrimaryButton` and
`BibBottomActionBar`.

**Direction:** selection uses lavender container, stronger border, filled icon,
and max 1.02 scale. Unselected options remain legible and do not look wrong. CTA
must not cause jarring layout jump.

**States:** Buy selected; Wait selected; Skip selected; sending with options
disabled and progress in CTA; recoverable failure preserving choice.

**Acceptance criteria:** changing choice before sending is simple; submission is
idempotent; error does not clear selection; no justification field exists.

### `E1-S10` — Vote Confirmed

**Emotional objective:** acknowledge contribution before presenting group view.

**Visual hierarchy:** contained confirmation icon; headline; submitted
prediction; thank-you sentence; CTA to view aggregates.

**Canonical copy:**

- title: **“Seu palpite entrou”** (“Your prediction is in”);
- support: “Você escolheu Esperar. Obrigado por ajudar a Lu a pensar com um
  pouco mais de espaço.” (“You chose Wait. Thanks for helping Lu think with a
  little more space.”);
- CTA: **“Ver como o grupo respondeu”** (“See how the group responded”).

**Components:** `BibPageShell`, `BibBrandMark`, `BibInlineMessage`,
`BibStatusChip`, `BibPrimaryButton`.

**Direction:** microinteraction of 300–600 ms, replaced by simple transition
under reduced motion. Do not offer account, Reveal, marketing, or next dilemma.
Do not use “you got it right”, “good choice”, or celebrations tied to buy/skip.

**States:** standard confirmation; idempotent retry of same vote; result taking
time to load with CTA available; navigation error without resending.

**Acceptance criteria:** choice is clear; confirmation does not reveal aggregates
until next action; reload does not create duplicate participation.

### `E1-S11` — Aggregates After Voting

**Emotional objective:** put one's own prediction in context without inducing
competition, moral majority, or exposing individuals.

**Visual hierarchy:** title; explicit sample size; three equal-weight
distributions; session prediction; option to change until deadline.

**Canonical copy of fixture:**

- title: **“As perspectivas até agora”** (“Perspectives so far”);
- sample size: **“4 palpites”** (“4 predictions”);
- “Comprar — 1 palpite · 25%” (“Buy — 1 prediction · 25%”);
- “Esperar — 2 palpites · 50%” (“Wait — 2 predictions · 50%”);
- “Deixar pra lá — 1 palpite · 25%” (“Skip — 1 prediction · 25%”);
- status: **“Seu palpite: Esperar”** (“Your prediction: Wait”);
- support: “Você pode mudar seu palpite enquanto a pausa estiver aberta.” (“You
  can change your prediction while the pause is open.”);
- action: **“Alterar meu palpite”** (“Change my prediction”).

**Components:** `BibPageShell`, `BibTopBar` or compact Web header,
`BibVoteDistribution`, `BibStatusChip`, `BibPrivacyNotice`, `BibTextButton`.

**Direction:** bars use semantic containers of equal thickness; largest does not
receive victory color, crown, checkmark, or special animation. Percentage always
accompanied by count and sample size. Do not show names, avatars, reasons, or
rankings.

**States:** four votes; one vote showing 100% with sample “1 palpite”; vote
changed; deadline ended after submission, removing edit action; update fails
keeping last aggregates with message.

**Acceptance criteria:** user's choice is identifiable; sample size prevents
reading 100% as certainty; “Alterar” returns to `E1-S09` and replaces active
vote.

## 7. Task Sequencing

To reduce rework and preserve harmony:

1. `E1-DS00` — tokens, contracts, catalog, and fixtures;
2. `E1-S08` + `E1-S09` — define central voting component;
3. `E1-S03` + `E1-S04` — validate mobile/Web content parity;
4. `E1-S02` — uses stabilized input components;
5. `E1-S01` + `E1-S05` — establish empty/success without creating new visual
   languages;
6. `E1-S06` — combines summary, status, and empty state;
7. `E1-S07` + `E1-S10` + `E1-S11` — close loading, confirmation, and aggregates;
8. cross-cutting visual review and navigable happy path prototype.

Screen tasks may be executed by different agents only after `E1-DS00`. Changes
to the same shared component must not occur in parallel without a single contract
owner.

## 8. Task Deliverables

- main frame named with screen ID;
- necessary variants organized side-by-side, not mixed inside main frame;
- use of components, not anonymous shape groups;
- specifications for content, spacing, states, and behavior;
- prototype of dominant action and safe return;
- completed `Bib*` handoff;
- evidence of contrast, enlarged text, keyboard, and semantic reading;
- no out-of-scope asset or component without approved rationale.

## 9. Adversarial Review Before Approving the Set

The reviewer must attempt to find:

- accidental publishing from form or recovered draft;
- private info in generic social preview;
- URL, comment, guest name, or premature Reveal;
- aggregate visible or inferable before voting;
- Buy or Skip treated as morally correct response;
- install or sign-up CTA before/after voting;
- urgency created by deadline, zero votes, or majority;
- duplicate component with local token;
- breakage at 320 px, 200% text, keyboard, or screen reader;
- content mismatch between mobile preview and actual Web page.

Any occurrence blocks approval of the set.

## 10. Completion Criteria

Design work is complete when the 11 screens and variants form a continuous
prototype, the component catalog allows reassembling them without copying styles,
the creation flow remains under two minutes in testing, and voting remains
possible in under twenty seconds without an account.
