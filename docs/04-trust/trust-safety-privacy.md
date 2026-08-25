# Trust, safety, and privacy

## 1. Safety objective

Before I Buy asks people to expose desire, price, and personal reasoning to others. The product succeeds only if users can do that without financial shame, harassment, unwanted disclosure, manipulation, or dark-pattern pressure.

Private invite links reduce risk but do not eliminate it. Links can be forwarded, screenshots can escape, guests can abuse text, and spending patterns can reveal sensitive facts.

## 2. Regulatory posture

This document is product guidance, not legal advice. Obtain Brazilian privacy and consumer-law review before external beta.

Relevant current references:

- Brazil's [Lei Geral de Proteção de Dados Pessoais — LGPD, Law 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm) governs personal-data processing and establishes principles and data-subject rights.
- The ANPD emphasizes the best interests of children and adolescents when their data is processed ([ANPD guidance](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-divulga-enunciado-sobre-o-tratamento-de-dados-pessoais-de-criancas-e-adolescentes)).
- Brazil's newer digital child-protection requirements and ANPD's 2026 age-assurance guidance require specific legal review before the service can safely include or be likely to be accessed by minors ([ANPD notice](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-publica-orientacoes-preliminares-e-cronograma-para-afericao-de-idade-no-ambiente-digital)).

### Launch recommendation

- Adults only.
- Do not collect full date of birth unless legal review establishes necessity.
- Use a clear age eligibility assertion and monitor likely underage use during the closed beta.
- Before public launch, obtain counsel advice on age assurance, Terms, lawful bases, notices, international transfers, data-subject requests, and ECA Digital obligations.

## 3. Data inventory

| Data | Purpose | Sensitivity/risk | MVP handling |
|---|---|---|---|
| Account identifier and email/provider ID | Authentication, account recovery | Personal data | Store with auth provider; limit product access |
| Display name/avatar | Social context | Personal, impersonation risk | Optional avatar; moderation and change history |
| Eligibility assertion | Adult-only policy | Sensitive if over-collected | Store yes/no plus policy version |
| Item name/category | Core dilemma | May reveal health, religion, sexuality, hobbies | Owner controls; private by default |
| Product image/screenshot | Core dilemma | Can contain faces, addresses, order/payment data | Warn, scan basic metadata, private storage |
| Product URL | Context | Can contain tracking/order tokens | Normalize/redact known query parameters; never log full URL in analytics |
| Exact price/currency | Core decision | Financial-context signal | Product database only; analytics gets coarse band |
| Owner self-prediction | Optional private insight experiment | Personal expectation that could feel diagnostic or embarrassing | Owner-only, hidden from voters and routine analytics |
| Owner reason/reflection | Core learning loop | Highly personal free text | Participant-visible only after explicit preview |
| Vote and reason | Social prediction | Opinion, harassment risk | Author-visible; hide/report/block |
| Invite token | Access capability | Secret-like credential | High entropy, hash at rest, revocable, no indexing |
| Notification address/token | Loop closure | Personal/device data | Separate store, consent/opt-out, rotation |
| Guest Reveal email/token | One-dilemma outcome delivery | Personal contact data and consent risk | Separate explicit consent; no marketing; delete after delivery plus grace period |
| Offline local draft | Capture without connectivity | Sensitive data may remain on a lost/shared device | Protected app storage; visibly unpublished; user can discard before sync |
| Analytics IDs/events | Product validation | Re-identification risk | Pseudonymous, minimized, no free text |
| Reports/moderation evidence | Safety operations | Sensitive and adversarial | Restricted operator access and retention policy |

## 4. Privacy model

### Defaults

- Every dilemma is private/unlisted.
- Invite page uses a generic social preview by default.
- Search indexing is disabled.
- Live results are hidden until the recipient votes.
- Owner decides whether reflection/note appears in Reveal.
- Owner self-prediction is private by default and never shown to voters before or after voting in the approved experiment.
- Offline captures remain local, visibly unpublished drafts until explicit review and publish.
- Contacts are not imported in MVP.
- No public profile, follower count, or public spending history.

### Invite-link warning

Treat an invite link like a key: anyone who receives a forwarded link may access the dilemma until it is revoked. Explain this before sharing and provide a one-tap revoke control.

Do not market an unlisted link as end-to-end private or confidential.

### Data-subject controls

- View and edit profile.
- Export owned dilemmas and reflections in a readable format.
- Delete individual dilemma.
- Revoke invite access.
- Delete account.
- Manage notification permissions.
- Withdraw a guest one-dilemma Reveal subscription without deleting the submitted vote.
- View blocked users.
- Contact support for access, correction, portability, opposition, and other applicable requests.

## 5. Retention schedule proposal

Final periods require legal and operational review.

| Record | Active retention | After deletion/closure | Reason |
|---|---|---|---|
| Active dilemma and media | Until owner deletes/account closes | Remove from primary access promptly; backup expiry target ≤35 days | Product function and recovery |
| Vote | While dilemma exists | Delete/anonymize with dilemma; limited abuse evidence exception | Reveal and participant history |
| Reflection/Reveal | While owner retains it | Delete/anonymize with dilemma | Personal history |
| Revoked invite token | Hash/state while dilemma exists | Remove with dilemma | Prevent reuse/audit |
| Notification tokens | Until opt-out/account deletion | Delete promptly | Delivery only |
| Guest one-dilemma routing address | Until Reveal delivery/withdrawal | Delete after delivery plus approved short grace period if no account exists | Dilemma-specific consent only |
| Product analytics | Proposed 13 months | De-identify/delete association where feasible | Cohort validation |
| Application logs | Proposed 30 days | Automatic deletion | Reliability/security |
| Security logs | Proposed 90 days | Restricted deletion schedule | Abuse/incident detection |
| Moderation case | Case plus defined appeal window | Minimize; retain only justified evidence | Safety and defense of claims |

Backups and vendors must be included in the deletion design; a UI disappearance is not the entire deletion process.

## 6. Abuse cases and controls

| Abuse | Prevent | Detect | Respond |
|---|---|---|---|
| Link forwarding/doxxing | Generic preview, warn owner, revocable high-entropy token | Unusual view geography/velocity without invasive tracking | Revoke link, notify owner if material |
| Harassing vote reason | Kindness cue, length cap, rate limit, block | Reports, repeated hidden reasons | Hide, warn/suspend, preserve minimal evidence |
| Spam/promotional posts | Invite-only creators, URL rate limits, no brands | Link/domain repetition, reports | Remove, suspend, block domain if needed |
| Vote manipulation | One vote per account/guest claim, device/session friction, rate limits | Burst/anomaly monitoring | Exclude suspicious votes, lock link |
| Impersonation | Verified auth channels, report impersonation | Reports, duplicate patterns | Suspend pending review |
| Malicious media | MIME/signature validation, size limits, image re-encoding | Malware/content pipeline alerts | Quarantine/remove |
| Secret/token leakage | Redact URLs, no invite token in logs/analytics, Referrer-Policy | Secret scanning, access audits | Revoke/rotate, investigate |
| Scraping | No index, rate limit, token scope, minimal guest endpoint | Request-volume patterns | Throttle/revoke |
| Coercive financial judgment | Neutral copy, owner control, no public rankings | Qualitative reports, block/hide rate | Content action and product change |

## 7. Moderation model

### Launch scope

- User reports dilemma, image, owner identity, or vote reason.
- User blocks another account.
- Owner hides a reason from their view and Reveal.
- Operator can hide content, revoke links, restrict guest voting, suspend accounts, and record a case outcome.
- No automated permanent sanctions.

### Severity

| Severity | Examples | Target response |
|---|---|---|
| Critical | Credible threat, child sexual exploitation, exposed payment/identity secrets | Immediate escalation and access restriction |
| High | Doxxing, targeted harassment, fraud, repeated impersonation | Review within 24 hours in beta |
| Medium | Insults, spam, unwanted promotion | Review within 2 business days |
| Low | Disagreement, off-topic but non-abusive content | User controls; sample review |

Document escalation, appeals, operator access, and jurisdiction-specific reporting obligations before launch.

## 8. Financial and psychological safety

### Product boundaries

- The product does not assess affordability or suitability.
- Friend votes are opinions, not financial advice.
- AI, if added, must never imply clinical or financial authority.
- The product must not shame Buy or reward Skip as morally superior.
- Do not claim the app treats compulsive shopping.

### Vulnerability cues

If user text suggests distress, debt crisis, coercion, self-harm, or compulsive behavior, the MVP should not auto-diagnose. Provide a neutral support entry point and locally appropriate resources reviewed by qualified professionals. Do not expose the cue to friends or include it in analytics.

### Anti-addiction design

- no infinite public feed;
- no daily streak loss;
- no variable-reward notifications;
- no countdown urgency beyond the owner-selected pause;
- no pressure to post purchases to keep status;
- notification frequency caps and quiet hours;
- no monetary leaderboard.

## 9. Security requirements

- Server-side authorization for every object; UI hiding is not access control.
- Row-level ownership/audience policies tested for owner, participant, guest, moderator, and anonymous contexts.
- Invite tokens are random, high entropy, revocable, scoped, and stored hashed.
- Service/admin credentials never ship in client apps.
- Media is stored private and served through time-limited authorized access.
- TLS in transit and managed encryption at rest.
- Secrets stored in managed secret storage, not source or analytics.
- Offline drafts use platform-protected application storage; sensitive draft content is not exposed in device backups without explicit review of backup behavior.
- Rate limits on invite views, votes, sign-in, reports, and media upload.
- Audit sensitive moderator and deletion actions.
- Dependency, static, dynamic, and mobile security testing before release.
- Incident-response contacts, severity, containment, notification, and postmortem process defined.

Use the OWASP Mobile Application Security Verification Standard as an implementation checklist during engineering review.

## 10. Privacy acceptance tests

1. Anonymous user cannot enumerate or fetch a dilemma without a valid token.
2. Participant cannot access owner-private notes or other owners' items.
3. Revoked link fails across web, app, cache, preview, and notification paths.
4. Invite token and full product URL never appear in analytics or routine logs.
5. Deleting a dilemma removes media access and participant views.
6. Account deletion cascades or queues every owned object and records progress.
7. Blocked user cannot submit new content to the blocker.
8. Generic preview remains generic until owner explicitly changes it.
9. Large screenshots with embedded metadata are re-encoded and stripped where feasible.
10. Operator access is least-privilege and auditable.
11. Owner self-prediction is absent from participant APIs, Reveal payloads, and analytics exports.
12. Guest Reveal subscription can be withdrawn, does not enroll marketing, and the routing address is deleted on schedule.
13. Reconnecting an offline device cannot publish a draft without explicit owner confirmation.

## 11. Pre-launch checklist

- [ ] Data inventory and processing record approved
- [ ] Privacy notice and Terms reviewed
- [ ] Legal bases and consent boundaries documented
- [ ] Age/child-safety approach reviewed under current Brazilian law
- [ ] Vendor/subprocessor and cross-border review complete
- [ ] Retention and deletion jobs tested
- [ ] Threat model and abuse-case review complete
- [ ] Incident-response tabletop complete
- [ ] Report/block/revoke workflows tested with users
- [ ] Accessibility and vulnerable-user language reviewed
- [ ] No critical/high security findings open
