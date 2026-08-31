# Technical architecture

## 1. Architecture goal

Ship a private-link social loop with a small team, while keeping authorization, delayed jobs, deletion, and observability robust enough for sensitive user-generated content.

## 2. Recommended stack

### Client surfaces

- **Flutter mobile app** for iOS and Android owner/authenticated experiences.
- **Small responsive web application** for guest vote and Reveal links. Prefer a lightweight server-rendered TypeScript framework over a full Flutter Web payload because link recipients must reach one interaction quickly.

Tradeoff: two presentation stacks add some duplication. Keep the web surface deliberately narrow and share API contracts, design tokens, content strings, and generated types.

### Managed backend

Recommended MVP candidate:

- Supabase Auth;
- Postgres database;
- private object storage;
- Edge/server functions for privileged mutations and link handling;
- scheduled worker/cron for due transitions and notification outbox.

Why: it combines auth, relational data, storage, and access policies for a small team. Supabase documents that exposed tables should use Row Level Security and least privilege ([RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security)), and that Storage access can also be governed by RLS policies ([Storage access control](https://supabase.com/docs/guides/storage/security/access-control)).

This is a recommendation, not a lock-in decision. A short spike must verify scheduled jobs, regional/data-transfer needs, backup/restore, deletion, observability, and cost before implementation.

## 3. System context

```text
Flutter app ───────┐
                   ├── HTTPS API / Auth ── Postgres + RLS
Guest web app ─────┘            │          Private media storage
                                │          Outbox / scheduled jobs
                                ├── Push provider (APNs/FCM)
                                ├── Transactional email provider
                                └── Minimal analytics/observability
```

No bank, Open Finance, marketplace, affiliate, or AI provider integration exists in MVP.

## 4. Trust boundaries

1. Mobile and web clients are untrusted.
2. Publishable client keys identify the project but do not grant access by themselves.
3. Database grants plus RLS enforce row access.
4. Privileged service credentials exist only in server functions/workers.
5. Invite tokens grant narrowly scoped guest access and must not become general session credentials.
6. Analytics receives only minimized, pseudonymous events.
7. Notification providers receive only routing token/address and message content required for delivery.

Supabase warns that service-role/secret keys bypass RLS and must never be exposed on the frontend ([security guidance](https://supabase.com/docs/guides/database/secure-data)).

## 5. Authentication and guest participation

### Owner/authenticated user

- Email magic link initially; Apple/Google sign-in can follow if store release requires or conversion benefits.
- Store refresh tokens only through platform-secure mechanisms supported by the SDK.
- Re-authentication required for account deletion and sensitive email changes.

### Guest

- Invite URL contains a random token with at least 128 bits of entropy.
- Persist only a hash of the token server-side.
- Exchange valid token for a short-lived, dilemma-scoped guest session.
- Guest session can view one dilemma, submit/change one vote, and subscribe to that Reveal.
- A guest Reveal subscription is scoped to one dilemma, uses separate consent, and creates no marketing permission.
- Claiming a vote requires a single-use signed claim token after account creation.

Do not use IP address as identity. Use rate limits and device/session hints only as abuse friction, with privacy review.

## 6. Authorization model

Every entity defines allowed operations by role.

| Resource | Owner | Auth participant | Guest with valid scope | Operator |
|---|---|---|---|---|
| Dilemma public fields | CRUD | Read if participant/invite | Read one scoped item | Restricted review |
| Owner private note | CRUD | None | None | No routine access |
| Vote | Read aggregates; hide reason | CRUD own before lock | CRUD scoped own before lock | Restricted review |
| Decision/reflection | CRUD own | Read published Reveal only | Read published Reveal if subscribed/token valid | Restricted review |
| Media | CRUD own | Time-limited read if authorized | Time-limited scoped read | Quarantine/review |
| Report | Read own status | Create own | Create scoped | Manage |

Create automated policy tests for every row and storage policy. Test negative cases first.

## 7. API boundaries

Prefer intent-based endpoints/functions for security-sensitive transitions:

- `publishDilemma`
- `recordOwnerExpectation` behind the experiment flag
- `exchangeInviteToken`
- `submitVote`
- `subscribeGuestToReveal`
- `withdrawGuestRevealSubscription`
- `recordDecision`
- `completeReflection`
- `publishReveal`
- `revokeInvite`
- `reportContent`
- `requestAccountDeletion`

These functions validate state, authorization, input, rate limit, and event/outbox creation atomically. Read-only lists/details may use direct RLS-protected queries if policy complexity remains testable.

## 8. Delayed jobs and notifications

Use a durable outbox/job table rather than relying on in-process timers.

Job types:

- decision due;
- decision reminder;
- reflection due;
- reflection reminder;
- decision update;
- Reveal notification;
- guest Reveal routing-address deletion after delivery/grace period;
- deletion cleanup;
- media cleanup.

Requirements:

- idempotency key per logical job;
- retry with bounded exponential backoff;
- dead-letter/failed state visible to operators;
- current entity state checked before send;
- category timing rule and version captured when scheduling: 7 days for short-lived outcomes, 30 days for durable purchases, and dormant 90-day capability until enabled by experiment;
- quiet hours and user preferences applied at delivery;
- no sensitive item detail in lock-screen notification by default;
- metrics for scheduled, attempted, delivered, failed, and suppressed.

## 9. Deep links

- Use HTTPS app/universal links on a controlled domain.
- Route `/d/{token}` to guest dilemma and `/r/{token}` to Reveal.
- If app is installed and user is authorized, open native detail.
- Otherwise serve mobile web; never force store installation before voting.
- After voting, the web flow may collect a separate one-dilemma Reveal subscription; failure or refusal must not affect the vote.
- Preserve the invite token only through the minimum handoff path.
- Set `Referrer-Policy: no-referrer`, `Cache-Control` appropriate for private content, and `X-Robots-Tag: noindex, nofollow`.
- Open Graph content is always generic; item-specific previews are not supported.

## 10. Media handling

- One image per dilemma in MVP.
- Validate signature/MIME, dimensions, and file size server-side.
- Re-encode to supported raster formats and strip metadata where feasible.
- Generate thumbnails asynchronously.
- Store original/derived assets in private buckets with owner IDs and access policy.
- Serve through authorized, short-lived URLs or authenticated proxy.
- Remove all variants through a tracked deletion job.

Do not fetch arbitrary product URLs server-side in MVP. Link metadata extraction introduces SSRF, tracking, malware, and correctness risks and belongs in a separately threat-modeled post-MVP service.

## 11. Offline draft capture

- Dilemma creation writes a local draft before attempting network publication.
- Local state distinguishes `local_draft`, `publish_ready`, `publishing`, `published`, and `publish_failed`; it never reuses the server's published state prematurely.
- Offline or interrupted drafts display **Draft—not shared yet**.
- Reconnection may refresh validation and media preparation, but the owner must review and explicitly publish.
- Publishing uses a client-generated idempotency key so retries cannot create duplicate dilemmas.
- A successfully published server response replaces the local provisional ID with the canonical server ID transactionally.
- Local drafts use platform-protected application storage and support explicit discard.
- Analytics records only coarse draft lifecycle events, never draft text, URL, exact price, image, or owner self-prediction.

## 12. Data and analytics

- Exact product data remains in product tables.
- Analytics receives category, wait window, price band, booleans, timestamps, and pseudonymous IDs.
- Owner self-prediction remains in owner-private product data; analytics receives only experiment exposure/completion and coarse outcome agreement after privacy review.
- Guest Reveal email/token remains in notification infrastructure and is automatically removed after delivery plus the approved grace period unless claimed by an account.
- Use an internal analytics event table/outbox first; forward only approved fields to any third party.
- Make event schemas versioned and testable.
- Keep operational logs structured but free of invite tokens, exact URLs, free text, and notification payloads.

## 13. Reliability and backup

- Schema migrations are versioned, reviewed, and reversible where possible.
- Automated database backups are enabled and restore is rehearsed before beta.
- Confirm separately how object storage is backed up; database backup alone may not cover stored media.
- Critical mutations use transactions.
- Outbox prevents state changes from being committed without the corresponding notification/event intent.
- Define RPO/RTO for beta: proposed RPO ≤24 hours, RTO ≤8 hours, then tighten based on usage.
- Status page is unnecessary for tiny beta, but internal incident communication is required.

## 14. Observability

Monitor:

- API error and latency by endpoint;
- authentication failures;
- RLS/authorization denials and anomalies;
- invite exchange and vote rate limits;
- job queue age/failures;
- notification delivery/suppression;
- media processing failures;
- report queue age;
- deletion queue age;
- guest Reveal routing-address deletion age;
- offline-draft publish failures and duplicate-prevention outcomes;
- client crash-free sessions and web-vote completion.

Alerts must avoid sensitive payloads.

## 15. Accessibility and localization

- Portuguese (`pt-BR`) first; English-ready string architecture.
- ICU/plural-aware localization, not string concatenation.
- Money as integer minor units plus ISO 4217 currency.
- UTC timestamps with explicit user timezone.
- Screen-reader semantics, focus, large text, contrast, reduced motion, and non-gesture alternatives are release criteria.
- Web target follows [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/).

## 16. Environments and delivery

- Separate local/dev, staging, and production projects.
- No production personal data copied to lower environments.
- Seed synthetic dilemmas for tests.
- CI runs formatting, static analysis, unit, contract, policy, migration, and security checks.
- Staging supports full delayed-loop testing with accelerated clocks.
- Feature flags control guest claim, scoring display, and experimental copy—not authorization or safety fundamentals.

## 17. Test strategy

### Unit

- state transitions;
- category timing and timing-rule versioning;
- original/alternative/skipped/unavailable/returned/gift outcome handling;
- owner self-prediction privacy and Illusion Filter eligibility;
- scoring semantics;
- notification suppression;
- money/date handling;
- analytics redaction.

### Integration

- every RLS policy by role;
- invite exchange/revoke;
- one-dilemma guest Reveal consent, withdrawal, delivery, and deletion;
- vote uniqueness/change/lock;
- decision/reflection/reveal transaction;
- job retries/idempotency;
- media authorization/deletion.

### End to end

- mobile offline draft → reconnect/review/publish → web guest vote/Reveal opt-in → mobile decision with alternative/return/gift variants → accelerated category-timed reflection → web/app Reveal;
- revoked link;
- private reflection;
- blocked participant;
- account deletion;
- offline draft/retry.

### Security

- threat modeling;
- dependency and secret scanning;
- static/dynamic tests;
- authorization fuzzing;
- link/token leakage tests;
- rate-limit and abuse tests;
- independent review before public launch.

## 18. Technical spikes before build

1. Guest scoped-session and claim flow.
2. RLS matrix for owner/participant/guest/operator.
3. Universal/app link fallback with generic previews.
4. Durable scheduled jobs and accelerated-clock tests.
5. Private-media authorization and deletion.
6. Supabase region, DPA, backup/restore, storage backup, and cost review.
7. Offline local draft, explicit publish, idempotent retry, and duplicate prevention.
8. Guest one-dilemma Reveal consent and automatic contact-data deletion.

If any spike makes the managed stack unsafe or operationally awkward, keep the architecture boundaries and substitute backend services before implementation spreads.
