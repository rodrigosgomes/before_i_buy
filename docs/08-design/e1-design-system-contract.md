# Delivery 1 — Design System Shared Contract

**Status:** specification for design and future implementation

**Scope:** 11 base screens of Delivery 1

**Base:** Material Design 3 Expressive in Flutter and Material UI (MUI) in the Web client

## 1. Objective

This document defines the visual source of truth that different agents must
use when designing or implementing Delivery 1 screens. Flutter and Next.js do
not share widgets, but must share:

- the same semantic tokens;
- the same component names and anatomies;
- the same interaction states;
- the same canonical copy in Portuguese;
- the same visual validation fixtures;
- the same accessibility criteria.

An agent must not create a local color, spacing, radius, variant, or component
to solve a single screen without first checking this contract.

## 2. Scope Boundaries

Delivery 1 screens may represent only:

`local draft → explicit review → private publish → invite → vote`

Do not include product URLs, text reasons for votes, persistent guest
names, Reveal opt-in, guest accounts, decisions, reflections, Reveal, scoring,
AI, public feeds, followers, or rankings.

The creator uses the mobile app. The guest uses a responsive Web page without
installation and without registration. Aggregates appear to the guest only after
a valid vote.

## 3. Sharing Architecture

The structure below is the recommended destination when clients are created;
it does not claim that these directories already exist:

```text
design-system/
  tokens/
    source/
      color.tokens.json
      dimension.tokens.json
      typography.tokens.json
      motion.tokens.json
    generated/
      flutter/
      web/
  contracts/
    components/
    content/
    fixtures/
  previews/
    reference-393x852/

apps/mobile/lib/design_system/       # Flutter Material 3 adapter
apps/guest-web/src/design_system/    # React + MUI adapter
```

### Ownership Rules

1. `design-system/tokens/source` is the source; generated files are never
   manually edited.
2. `design-system/contracts/components` describes anatomy, properties, states,
   and accessible semantics.
3. Flutter and Web may implement different technologies, but cannot change the
   meaning of a component.
4. A shared visual change starts in the contract and creates an update task for
   both adapters.
5. A screen-specific component is only allowed when there is no plausible second
   occurrence and its composition uses existing primitives.

### Figma Design Library

When a Figma file exists, maintain a single published library for Delivery 1,
organized as follows:

```text
00 Cover & changelog
01 Foundations        # color, dimension, type, and motion variables
02 Bib Primitives     # buttons, fields, shell, top bar, and feedback
03 Bib Domain         # dilemma summary, vote option, and distributions
04 Patterns           # form, preview, confirmation, and empty state
10 E1 Mobile Screens  # E1-S01 to E1-S06
11 E1 Web Screens     # E1-S07 to E1-S11
99 QA                 # 320 px, 200% text, focus, loading, and errors
```

- Name components like `Bib/Button/Primary`, `Bib/VoteOption/Wait`, and
  `Bib/DilemmaSummary/Default`.
- Mirror tokens as semantic variables; do not create local color styles.
- Screens use instances. Do not detach components to adjust a screen.
- Library changes require a short changelog with component, reason, and
  affected screens.
- Agents work on task branches/pages, but integrate component changes first
  into the library and only then update screens.
- Flutter and Web must be able to trace each implementation to the same `Bib`
  name.

## 4. Canonical Tokens

### 4.1 Colors

| Token | Value | Usage |
|---|---:|---|
| `color.canvas` | `#FAF9F6` | Warm main background |
| `color.surface` | `#FFFFFF` | Elevated surface |
| `color.surfaceSubtle` | `#EFECE6` | Sections and field groups |
| `color.textPrimary` | `#4F5D65` | Main text |
| `color.textSecondary` | `#6E7B82` | Secondary text with validated contrast |
| `color.brandTerracotta` | `#C56C51` | Brand, illustration, and container; do not use with small white text |
| `color.actionPrimary` | `#A94F38` | Filled button with white text; AA contrast |
| `color.actionPrimaryPressed` | `#8F3F2C` | Pressed state |
| `color.onActionPrimary` | `#FFFFFF` | Content on primary action |
| `color.buyContainer` | `#DCEAE5` | Semantic background for Buy (Comprar) |
| `color.waitContainer` | `#E8E3EC` | Semantic background for Wait (Esperar) |
| `color.skipContainer` | `#E9E0D5` | Semantic background for Skip (Deixar pra lá) |
| `color.infoContainer` | `#E4EEF4` | Neutral information |
| `color.warningContainer` | `#F4EBC4` | Non-urgent warning / attention |
| `color.error` | `#A33A3A` | Textual error and outline; never a moral signal for decisions |
| `color.outline` | `#C8C3BC` | Neutral borders |
| `color.focus` | `#245E73` | High-contrast Web focus ring |

Buy, Wait, and Skip have the same visual weight. Distinction must simultaneously
use label, icon, border, and container; never color alone.

### 4.2 Typography

Headline font: `Manrope`, fallback `Inter`, sans-serif.

Interface font: `Inter`, sans-serif.

| Token | Specification |
|---|---|
| `type.display` | 32/38, weight 700 |
| `type.headline` | 26/32, weight 700 |
| `type.titleLarge` | 22/28, weight 700 |
| `type.title` | 18/24, weight 650 |
| `type.body` | 16/24, weight 400 |
| `type.bodyStrong` | 16/24, weight 600 |
| `type.label` | 14/20, weight 600 |
| `type.caption` | 12/18, weight 500 |

Do not scale down text to fit content. Allow reflow and vertical expansion up to
at least 200% text scale.

### 4.3 Dimensions

| Token | Value |
|---|---:|
| `space.1` to `space.8` | `4, 8, 12, 16, 20, 24, 32, 40 px` |
| `radius.field` | `16 px` |
| `radius.cardCompact` | `20 px` |
| `radius.cardHero` | `28 px` |
| `radius.button` | `20 px` |
| `size.touchMin` | `48 px` |
| `size.buttonHeight` | `52 px` |
| `layout.mobileMargin` | `16 px` |
| `layout.webContentMax` | `640 px` |

### 4.4 Elevation and Motion

- low elevation: wide shadow, maximum 10% opacity;
- state transitions: 200–300 ms;
- option selection: maximum scale `1.02`;
- success: maximum 600 ms, no loop;
- respect `prefers-reduced-motion` and equivalent setting on mobile;
- never use bounce, shake, roulette, confetti, or pulsating countdowns.

## 5. Shared Components

All receive the `Bib` prefix in the contract. Examples: `BibPrimaryButton` in
Flutter and React, even though implementations are independent.

| Component | Responsibility and Minimum States |
|---|---|
| `BibPageShell` | Safe area, canvas, max width, scroll, and responsive action bar |
| `BibTopBar` | Back, title, optional action, and navigation semantics |
| `BibBrandMark` | Small abstract brand mark; do not block loading with illustrations |
| `BibPrimaryButton` | `enabled`, `pressed`, `focus`, `loading`, `disabled` |
| `BibSecondaryButton` | Same states, clear secondary hierarchy |
| `BibTextButton` | Tertiary action with minimum 48 px touch target |
| `BibTextField` | Persistent label, helper, counter, error, and focus |
| `BibCurrencyField` | Localized BRL input, internal value in cents, error preserving input |
| `BibSelectField` | Opens accessible sheet/menu; never relies on placeholder as label |
| `BibSegmentedChoice` | Purpose and pause; keyboard, screen reader, and wraps on large text |
| `BibDraftBanner` | Private local state: “Rascunho — não compartilhado” (“Draft — not shared”) |
| `BibPrivacyNotice` | Icon, short title, explanation, and optional link; `neutral` and `attention` variants |
| `BibDilemmaSummary` | Item, price, category, purpose, reason, and pause |
| `BibGuestPreviewFrame` | Frame faithfully reproducing the width and order of the Web page |
| `BibStatusChip` | Textual state with icon; never color alone |
| `BibEmptyState` | Hero, message, support copy, and one dominant action |
| `BibVoteOption` | Buy/Wait/Skip; `idle`, `selected`, `focus`, `disabled` |
| `BibVoteDistribution` | Label, icon, count, percentage, and sample size; no user identities |
| `BibLoadingBlock` | Skeleton without sensitive data or excessive layout shift |
| `BibInlineMessage` | `info`, `success`, `warning`, `error`; announced by assistive technology |
| `BibBottomActionBar` | Fixed CTA when safe; must yield space to keyboard and enlarged text |
| `BibConsentChecklist` | Two independent internal-demo acceptances for Terms and Privacy Notice; exposes pending/completed state, labels the copy as legally invalid, and keeps legal links disabled until approved versions exist |

`BibConsentChecklist` is an internal onboarding fixture in Task 3A. It does not
write to `profiles`, grant publication permission, or represent legally valid
consent. Its Terms and Privacy Notice controls remain independent, and disabled
links must be announced as unavailable rather than rendered as actionable text.

## 6. Material Mapping

| Contract | Flutter Material 3 | Web MUI |
|---|---|---|
| Theme | `ThemeData(useMaterial3: true)` + `ColorScheme` | `createTheme` + `CssBaseline` |
| Primary action | Themed `FilledButton` | `Button variant="contained"` |
| Secondary action | `OutlinedButton` | `Button variant="outlined"` |
| Fields | `TextFormField` | `TextField` |
| Selectors | `ModalBottomSheet` / adaptive control | Responsive `Dialog`, `Menu`, or `Drawer` |
| Choices | `SegmentedButton` / semantic composition | `ToggleButtonGroup` / semantic composition |
| Feedback | `MaterialBanner` / inline | `Alert` / inline |
| Skeleton | Custom Material composition | `Skeleton` |

Do not expose MUI components directly to screens. Create `Bib*` wrappers so that
a library change does not alter the visual contract.

## 7. Shared Visual Fixture

All agents must initially use the same fixture to facilitate visual diffing
between screens and platforms:

```json
{
  "creatorDisplayName": "Lu",
  "itemName": "Fone com cancelamento de ruído",
  "price": "R$ 2.400,00",
  "category": "Tecnologia",
  "reason": "Quero mais foco para trabalhar e viajar com menos ruído.",
  "purpose": "Para mim",
  "pause": "3 dias",
  "remaining": "2 dias",
  "votes": {
    "buy": 1,
    "wait": 2,
    "skip": 1
  }
}
```

The fixture is fictitious.

## 8. Inter-Agent Working Protocol

Before designing a screen, the agent must:

1. read the mini-PRD, Decision Log, this contract, and the screen prompt;
2. list the `Bib*` components that will be reused;
3. propose any missing component as a separate change to the contract;
4. implement or design the common component states first;
5. compose the screen exclusively using primitives/components;
6. deliver default viewport, enlarged text, loading, error, and Web focus where
   applicable;
7. record in the handoff which tokens and components were used or modified.

Mandatory handoff format:

```text
Screen: E1-Sxx
Tokens consumed: [...]
Components reused: [...]
Components added/modified: [...]
States delivered: [...]
Verifications: contrast, 200% text, keyboard, screen reader, reduced motion
Pending issues or contract deviations: none | describe
```

## 9. System Review Gate

- Flutter and Web present the same order of information in the invite.
- No aggregates are visible before voting.
- No public preview contains dilemma content.
- All actions have a minimum touch target of 48 px.
- Regular text and significant controls achieve AA contrast.
- Buy/Wait/Skip remain semantically neutral.
- No local component duplicates a `Bib*` component.
- Screens remain usable down to 320 px and with 200% text scale.
