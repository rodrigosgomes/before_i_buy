# Conceptual data model

## 1. Modeling principles

- Model the real lifecycle explicitly; do not infer state only from timestamps.
- Keep product data separate from analytics and notification routing.
- Enforce visibility at the data layer.
- Preserve an internal audit of sensitive transitions without exposing deleted content indefinitely.
- Treat invite tokens as credentials.
- Use immutable IDs; mutable display data should not be identity.

## 2. Relationship overview

```text
Account 1──1 Profile
Account 1──* Dilemma
Dilemma 1──0..1 OwnerExpectation
Dilemma 1──* InviteAccess
Dilemma 1──0..1 MediaAsset
Dilemma 1──* Participation
Participation 1──1 Vote
Dilemma 1──0..1 Decision
Decision 1──0..1 Reflection
Reflection 1──0..1 Reveal
Account 1──* NotificationEndpoint
Dilemma/Participation ──* Report
Account *──* Account through Block
Resolved Vote ──> PredictionRecord/Aggregate
State changes ──> OutboxEvent ──> Job/Notification
```

An explicit Friend/Circle graph is deferred. MVP access is dilemma-scoped through invite and participation records.

## 3. Entities

### Account

Purpose: authentication subject and lifecycle owner.

Key fields:

- immutable ID;
- auth-provider reference;
- account status;
- eligibility assertion and policy version;
- terms/privacy versions accepted;
- locale/timezone;
- created/deletion-requested/deleted timestamps.

Privacy: highly restricted. Product tables reference immutable ID, never email.

Lifecycle: active → restricted → deletion_pending → deleted/anonymized.

### Profile

Purpose: participant-facing identity.

Fields: account ID, display name, optional avatar asset, short handle if needed, profile moderation state.

MVP avoids public searchable profiles and follower counts.

### Dilemma

Purpose: a purchase decision and root aggregate.

Fields:

- ID and owner ID;
- item name;
- exact price minor units and currency;
- category enum;
- purpose enum `for_self` or `gift`;
- product URL optional;
- reason;
- wanted-since bucket optional;
- pause option and due time;
- follow-up timing rule/version and planned 7/30/90-day bucket;
- visibility `unlisted`;
- state;
- published/decision/reflection/closed/deleted timestamps;
- generic-versus-item link-preview choice;
- version for optimistic concurrency.

States:

`draft`, `collecting_votes`, `decision_due`, `bought_original`, `bought_alternative`, `skipped`, `unavailable`, `still_deciding`, `reflection_due`, `revealed`, `closed_private`, `expired`, `deleted`, `moderation_hidden`.

Privacy: owner private before publish; then only owner, authorized operators, and valid scoped participants/invite sessions.

Local offline drafts are client-side provisional records, not published `Dilemma` rows. They keep a client-generated idempotency key and become a server dilemma only after explicit review and publish.

### OwnerExpectation

Purpose: optional private input for the self-prediction/Illusion Filter experiment.

Fields: dilemma ID; answer `yes`, `not_sure`, `no`; experiment variant/version; created/updated timestamp; comparison eligibility.

Privacy: owner-only. It is excluded from participant APIs, vote anchoring, Reveal payloads, and raw analytics. The owner-private comparison is derived only after completed reflection.

### MediaAsset

Purpose: image and derivatives.

Fields: owner, dilemma, private storage path, content type, size/dimensions, processing state, content hash, created/deletion timestamps.

Lifecycle: pending → processing → ready | rejected → deletion_pending → deleted.

### InviteAccess

Purpose: revocable guest capability and attribution source.

Fields:

- dilemma ID;
- token hash, never plaintext;
- status;
- created/expires/revoked timestamps;
- generic/item-preview flag;
- rate-limit counters or references;
- optional campaign/source code that contains no personal data.

Lifecycle: active → revoked | expired.

### Participation

Purpose: one person's relationship to one dilemma.

Fields: dilemma ID; account ID or guest subject ID; join source; Reveal subscription state; one-dilemma consent timestamp/version; blocked/removed status; first/last interaction timestamps; claim state.

Constraint: one active participation identity per dilemma. Guest claim migrates ownership transactionally.

### Vote

Purpose: future-framed response and optional reason.

Fields: participation ID; choice `buy`, `wait`, `skip`; optional reason; created/updated/locked timestamps; visibility/moderation state.

Lifecycle: active/editable → locked → resolved | unresolved → deleted/anonymized.

Privacy: owner and the voter can see reason; other voters see aggregate counts only in MVP.

### Decision

Purpose: owner's recorded action.

Fields: dilemma ID; choice `bought_original`, `bought_alternative`, `skipped`, `unavailable`, `still_deciding`; optional alternative price/currency; decided timestamp; whether early; optional owner-private note; grace-period deadline; superseded marker for corrected input.

Only one current decision exists; corrections are auditable internally.

### Reflection

Purpose: delayed owner evaluation.

Fields:

- decision ID;
- same-choice-again `yes`, `not_sure`, `no`;
- disposition `kept`, `returned_refunded`, nullable;
- skipped detail `glad_skipped`, `still_wants`, `bought_alternative`, `original_unavailable`, nullable;
- gift outcome `worthwhile`, `not_sure`, `not_worthwhile`, nullable;
- too-early/rescheduled timestamp, nullable and allowed once;
- optional owner note;
- note visibility;
- due/completed timestamps;
- timing rule version.

Privacy: private until owner explicitly publishes Reveal content.

### Reveal

Purpose: immutable participant-visible projection of approved outcome fields.

Fields: dilemma ID; published timestamp; decision projection; reflection projection; owner-approved note; aggregate vote snapshot; version; visibility/closure state.

Why projection: later private edits should not accidentally change what was shared without an explicit republish action and audit trail.

### PredictionRecord

Purpose: resolved scoring fact for one confident vote.

Fields: participation/vote ID; Reveal version; eligibility; outcome `aligned`, `different`, `unresolved`; category; resolved timestamp; rule version.

Never compute historical scores with silently changed rules. Rule version makes experiments and migrations explicit.

### PredictionAggregate

Purpose: privacy-safe cached count for profile display.

Fields: account ID; rule version; eligible count; aligned count; optional category counts; recalculated timestamp.

Display only above minimum thresholds. Source of truth remains PredictionRecord.

### NotificationEndpoint

Purpose: route push/email for an account or opted-in guest.

Fields: subject ID; optional dilemma scope for guests; channel; encrypted/routed address or token; consent state/version; locale/timezone; quiet hours; last success/failure; expires/delete-after timestamp; revoked timestamp.

Keep separate from analytics. A guest endpoint is valid only for its subscribed dilemma and is deleted after Reveal delivery plus the approved grace period unless claimed by an account.

### NotificationIntent / OutboxEvent

Purpose: durable request generated transactionally from product state.

Fields: type; aggregate ID; recipient; idempotency key; due time; payload template variables; status; attempts; last error; created/delivered/suppressed timestamps.

Payload must avoid sensitive lock-screen details by default.

### Report

Purpose: user safety escalation.

Fields: reporter; target type/ID; reason category; optional description; severity; status; assigned operator; timestamps; resolution; restricted evidence reference.

### Block

Purpose: prevent future interaction between two accounts.

Fields: blocker, blocked subject, created timestamp. The blocked subject is not notified.

### ModerationAction

Purpose: accountable operator intervention.

Fields: operator; target; action; reason/policy; report link; created/expires timestamps; appeal status.

### AnalyticsEvent

Purpose: minimized first-party product measurement.

Fields: schema version; pseudonymous subject/group/dilemma IDs; event name/time; allowlisted coarse properties. No free text, image, URL, invite token, or exact price.

## 4. State transitions

| From | Event | To | Actor |
|---|---|---|---|
| draft | publish | collecting_votes | Owner |
| collecting_votes | due time reached | decision_due | Scheduled worker |
| collecting_votes/decision_due | record original purchase | bought_original | Owner |
| collecting_votes/decision_due | record alternative purchase | bought_alternative | Owner |
| collecting_votes/decision_due | record skipped | skipped | Owner |
| collecting_votes/decision_due | record unavailable | unavailable | Owner |
| collecting_votes/decision_due | extend | still_deciding | Owner |
| still_deciding | new due reached | decision_due | Worker |
| bought_original/bought_alternative/skipped/unavailable | category-timed reflection due reached | reflection_due | Worker |
| reflection_due | choose too early once | same state with new due time | Owner |
| reflection_due | complete and share | revealed | Owner |
| reflection_due | complete privately | closed_private | Owner |
| decision_due/still_deciding | maximum age reached | expired | Worker |
| any active | delete | deleted | Owner/operator policy |
| any visible | severe safety action | moderation_hidden | Operator |

State mutations must validate allowed source state and use transactions plus outbox creation.

## 5. Scoring matrix

| Vote | Decision | Same choice again | Result |
|---|---|---|---|
| Buy | Bought original and kept | Yes | Aligned |
| Buy | Bought original and kept | Not sure/No | Different or unresolved; validate in product test |
| Buy | Skipped | Any | Different |
| Skip | Skipped | Yes | Aligned |
| Skip | Skipped | Not sure/No | Different or unresolved; validate in product test |
| Skip | Bought original and kept | Any | Different |
| Buy/Skip | Bought alternative, unavailable, returned/refunded, or gift | Any | Unresolved until rules are validated |
| Wait | Any | Any | Unscored participation |
| Any | Reflection private/missing/too early | — | Unresolved |

Because the semantics are not yet validated, store the raw facts and a rule version. Do not make aggregate accuracy the only record.

## 6. Deletion and anonymization

### Dilemma deletion

1. Mark deleted and immediately deny user access.
2. Revoke all invite tokens and notification intents.
3. Remove from histories and score aggregates.
4. Queue media deletion and derived-event de-association.
5. Retain only minimal justified moderation/security evidence when applicable.
6. Expire backups according to the documented window.

### Account deletion

1. Re-authenticate and record request.
2. Disable sign-in and cancel endpoints/jobs.
3. Apply owned-dilemma deletion.
4. Remove/anonymize votes on other users' dilemmas while preserving aggregates only if lawful, expected, and non-identifying.
5. Remove profile and auth subject.
6. Track completion across vendors/backups.

Deletion jobs must be idempotent and observable.

## 7. Indexing/query needs

- owner dilemmas by state and due time;
- participant dilemmas by active/Reveal state;
- due dilemmas/reflections/jobs;
- vote uniqueness by dilemma plus participant;
- active invite token hash;
- unresolved reports by severity/age;
- outbox by due/status;
- prediction records by account/rule/category.

Do not add public full-text search in MVP.

## 8. Open data decisions

- Whether price can be optional or hidden from participants.
- Whether guest display name is stored or only shown to owner.
- Whether multiple invite links per dilemma are needed for group attribution.
- Whether a Circle entity should replace inferred groups after beta.
- Exact treatment of Buy/Skip predictions when owner answers Not sure/No.
- Whether owner can edit a published reason and how participants are notified.
- Whether product URLs should be retained after decision.
- Whether self-prediction should remain optional, where it appears in creation, and the minimum sample for the Illusion Filter.
- Exact category-to-7/30-day mapping and the evidence required to activate the dormant 90-day schedule.
- Whether alternative price should be retained if the product does not calculate or claim savings.
- Whether gift follow-up needs an expected-giving date before it can become first-class.
