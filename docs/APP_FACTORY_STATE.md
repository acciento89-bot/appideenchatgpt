# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-21
Status: ACTIVE
Current user-selected workstream: #002 Kamilunavo Trace — TestFlight Build 1 uploaded / Apple processing + IAP/device QA next
Repository purpose: persistent handoff/state repository for the full App Factory so work can continue across chat limits and new conversations without losing decisions or progress.

> This file is the portfolio-level single source of truth. Read it first, then the selected app-specific state. Detailed historical checkpoints remain in Git history.

## Mandatory workflow

1. Update this repository after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
2. Read this file first in a new chat, then the selected app's project state.
3. Major source passes must pass CI/regression gates before merge/TestFlight.
4. Do not weaken a core product loop by adding adjacent features.
5. Do not force subscriptions where lifetime/one-time better fits economics.
6. Re-check current App Store/web and trademark/domain sources before locking a public name.
7. Never overwrite another candidate's state while updating one workstream.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter | Return-window + actual-usage decision tool | Freemium + Lifetime Pro | APP STORE REVIEW SUBMITTED — APPLE DECISION PENDING |
| 002 | Kamilunavo Trace (internal path `002-evidaro`) | Local-first evidence cases + original hashes + snapshot seals + localized PDF + offline `.evpack` verifier | Freemium + Lifetime Pro | TESTFLIGHT BUILD 1 UPLOADED — APPLE PROCESSING / IAP + DEVICE QA PENDING |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking | Freemium | QUEUED |
| 004 | SubZero | Detect/track subscriptions and recurring costs | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Gift ideas per person/occasion via share sheet | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists, dates | Subscription | QUEUED |
| 008 | BeforeAfter | Guided repeat photography/alignment/comparison | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Fast portrait reaction/high-score game | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | COMPLETE V1 / PR #31 MERGED / PR #34 FINAL PROMOTION |

# Portfolio app #001 — KeepMeter

Authoritative repo/state:

- repo `acciento89-bot/keepmeter`
- state `docs/PROJECT_STATE.md`

Current checkpoint:

- native SwiftUI iPhone app / iOS 17+ / local-first / SwiftData / UserNotifications
- DE/EN
- Free tier: 5 active purchases
- StoreKit 2 Lifetime Pro product `de.kamilunavo.keepmeter.pro.lifetime`
- Lifetime Pro purchase, entitlement, restore and relaunch were user-verified on TestFlight/device
- App Store Connect metadata, screenshots, age rating, content rights, DSA and review information were completed by the user
- KeepMeter `0.1.0 (1)` was submitted to Apple App Review on 2026-08-20
- repository Gate #27 records `App Store Review submitted / Apple review decision pending`
- KeepMeter gate/documentation PR #34 merged; merge commit `2d99da17f712bb6de911fd92561a91cd149eaf16`

Do not regress KeepMeter to “StoreKit/ASC/TestFlight still open.” The next meaningful external event is Apple's review decision or review feedback.

# Portfolio app #002 — Kamilunavo Trace

Authoritative app state:

`apps/002-evidaro/PROJECT_STATE.md`

Naming:

- original working title `ProofVault` is retired because a substantially overlapping iPhone/iPad app now uses `ProofVault: Document Vault`
- `Evidaro` is retired as the public name and retained only where historical internal paths/fixtures make renaming unnecessary
- updated 2026-08-20 public-web research found an existing `Evidaro` project in the housing-conditions / housing-disrepair space with a surveyor-oriented product direction
- final public name is locked for this release as `Kamilunavo Trace`
- no repository research should be treated as legal trademark clearance

Product thesis:

> Capture facts while they are fresh. Seal evidence you can verify later.

Core loop:

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Build/share PDF or `.evpack` -> Verify received bundle locally**

Merged green passes:

- Pass 1 foundation — PR #15 — merge `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`
- Pass 2 SwiftData + hashed media — PR #20 — merge `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`
- Pass 3 camera + process-relaunch persistence — PR #22 — merge `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- Pass 3 handoff — PR #23 — merge `0be5e5e08bdd045bbb0994c1da508d9a86ab6951`
- Pass 4 local derived Apple Vision OCR — PR #24 — merge `ad3876dbac044759223d0bdf7a1c095e461bc16b`
- Pass 5 integrity-checked multi-page PDF evidence pack — PR #27 — merge `22f8b560c2529fb064feaa591b901acecf8da573`
- Pass 6 optional device-owner-auth privacy lock — PR #28 — final head `a55f55ebe72280e411670f4757624914d0c1d6ed`, merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`

Pass 7 — GREEN / MERGED:

- PR #29 `Add Evidaro DE/EN localization and accessibility hardening` — MERGED
- final PR head `84ef850678551e7cb0f22004c05e070adabece9d`
- exact workflow run `32383741929` / run #82 — **SUCCESS**
- build job `96473002571` — **SUCCESS**
- merge commit `bf3ecf74887c08d52bbadf11a13174c83133b093`

Pass-7 implementation includes:

- explicit English and German resources for app UI and camera/Face ID usage descriptions
- hash-stable persisted enum raw values with separate localized presentation names
- localized Home, case creation, evidence intake, case detail, OCR controls, privacy lock and device-auth prompts
- Dynamic Type adaptive home/action layouts
- VoiceOver headings, combined case-card semantics and full-hash accessibility labels/values
- full DE/EN localization of the generated evidence-pack PDF: metadata, cover, fields, OCR labels, image/PDF preview pages, seal history, continuation text, footer and export errors
- English and German PDF process-relaunch gates
- localization/presentation changes do not alter original media bytes, evidence-record hashes, manifests or seals

Pass-7 completion:
- final head `84ef850678551e7cb0f22004c05e070adabece9d` passed preflight, Xcode Simulator, persistence, OCR, English PDF, German PDF, privacy lock and German runtime localization before merge

Pass 8 — GREEN / MERGED:

- PR #32 — MERGED
- final exact head `d3af5d59abea850dd7724beb92e223a691172ba3`
- full simulator run `32408185123` / run #98 — SUCCESS
- merge `e5c57335888a80e120fefea686b29f6ed8715b2f`
- `.evpack` valid/tamper/derived-OCR/process-relaunch checks green

Release pass — Kamilunavo Trace — GREEN / MERGED / BUILD 1 UPLOADED:

- PR #33 — GREEN / MERGED
- final tested release head `090b1471…`
- static release run `32412043585` — SUCCESS
- unsigned iPhone Release/TestFlight validation run `32412043598` — SUCCESS
- full simulator integrity/relaunch run `32412043953` — SUCCESS
- release merge `69b8a1d99082ff804f2a532c636af3008d79546a`
- public name `Kamilunavo Trace`; bundle `de.kamilunavo.trace`
- public `.evpack` v1 format id `de.kamilunavo.trace.evpack`
- Lifetime Pro non-consumable `de.kamilunavo.trace.pro.lifetime`
- Free: up to 3 cases; received-bundle verification remains free
- Pro: unlimited cases + PDF export + `.evpack` export
- App Store Connect app record — EXISTS
- signed TestFlight Build 1 `0.1.0 (1)` upload — SUCCESS via protected One More Floor bridge
- bridge run `32445560808`; upload job `96665754912`; Apple export result `Upload succeeded.` / `EXPORT SUCCEEDED`
- Apple processing / TestFlight visibility — PENDING external confirmation

External next:

- create/configure Lifetime Pro IAP `de.kamilunavo.trace.pro.lifetime` and final price if not already done
- wait for/confirm Apple TestFlight processing visibility
- physical iPhone camera/OCR/biometric/VoiceOver/Dynamic Type QA
- real TestFlight Lifetime purchase, relaunch entitlement recovery and Restore

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-21

Complete-v1 is the baseline. Do not regress #011 to the old Build-2-only roadmap.

Promotion state:

- PR #31 `Family Life OS: harden timezone and review trust boundary`
  - validated head `29b942fca118792146acc6079a0fe07697a3bd8d`
  - Prototype / Database / Device-TestFlight validation — SUCCESS
  - merged to `main` on 2026-08-21
  - merge commit `0db452c41a4c197cb95d0bb48b9455561435f8d4`
  - hosted Edge Function changes are still NOT deployed live
- PR #34 `Family Life OS: durable offline source queue`
  - branch `agent/family-life-os-offline-queue`
  - retargeted to `main` after PR #31 merge
  - latest fully validated application-code checkpoint before retarget: `fd7381e97c349dd282df5b12ffcf68c4bd476538`
  - Prototype Build run `32455964319` — SUCCESS
  - Database Tests run `32455964347` — SUCCESS
  - iPhone/iPad device validation run `32455964321` — SUCCESS
  - final post-retarget CI/merge is the current promotion step
  - migration is still NOT deployed live

PR #31 closes release-critical trust bugs:

- household-timezone-aware extraction
- no fabricated 09:00 for missing source times
- all backend unresolved fields remain explicit blockers
- member/time/start/due ambiguities resolve independently
- offset-less provider timestamps rejected

PR #34 adds production-grade source durability:

- text/photo/camera/PDF/voice captured locally before network work
- atomic protected local queue
- local Inbox visibility + manual send/discard
- stable client request UUID + tenant-scoped idempotency
- deterministic retry-safe Storage path
- queue bound to authenticated user + household
- server rejects cross-household routing
- processing lease prevents duplicate parallel extraction after a lost Edge response
- automatic `NWPathMonitor` resume on real offline -> online transition
- initial/repeated online observations do not duplicate normal startup sync

Complete-v1 already includes:

- hosted auth + invite acceptance
- household/member management
- realtime refresh
- photo/camera/screenshot capture
- PDF/document capture
- text capture
- voice recording + transcription
- private Supabase Storage
- image/PDF OCR
- server-side structured extraction with deterministic fallback
- review-before-confirmation and original-source provenance
- source retry/archive lifecycle
- agenda/week Plan + Plan CRUD + persisted completion
- optimistic version conflicts + activity history
- notification preferences/local reminders
- biometric lock
- StoreKit 2 Family Pro surface/restore
- offline snapshot cache and share-extension intake foundations

## Apple / TestFlight state

Bundle ID:

`de.kamilunavo.familyprototype`

Apple team:

`TKG684N5GL`

Build 2 was physically installed and user-verified on iPhone, including persisted completion and hosted E2E diagnostics with cleanup.

Build 3 is not missing. A later protected bridge attempt proved App Store Connect already contained build `3`: Apple rejected the duplicate attempt because the bundle version had to be higher than previously uploaded version `3`.

Bridge evidence:

- repo `acciento89-bot/onemorefloor`
- run `32366765776`
- bridge head `3f300e3a70f33d86a73a26195eea0b2f3775a9f9`

Any next Apple upload must use build number greater than `3`.

## Hosted/live boundary

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- household locale/timezone `de-DE` / `Europe/Berlin`
- RLS-enabled collaborative data model
- active JWT-protected `process-family-source` Edge Function

Not live yet:

- PR #31 Edge Function timezone/trust changes
- PR #34 source-ingestion idempotency migration/offline protocol

Merging repository code does not deploy those changes. Do not run the new offline upload protocol against production until the hosted migration/function changes are intentionally promoted.

Real provider evidence remains open: the last hosted audit only proved fixture extraction runs. Do not claim OpenAI extraction or `OPENAI_API_KEY` availability until a live `extraction_runs` record proves the provider/model.

## Product thesis / trust boundary

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` remains the signature trust boundary:

- original source remains reachable
- OCR/AI produces editable proposals only
- unresolved required values block confirmation
- never invent missing date/time/person data
- explicit user confirmation creates canonical family data
- confirmed items retain source/proposal provenance

## #011 next promotion sequence

1. Finish the exact post-#31 `main` validation for PR #34.
2. Merge PR #34 after the exact resulting head is green.
3. Deploy Edge + migration to hosted Supabase only with explicit live-deployment authorization.
4. Run live canaries for Europe/Berlin timezone, missing-time blocking, offline->online exactly-once ingestion, household isolation and processing-lease recovery.
5. Inspect live `extraction_runs` provider/model.
6. Publish the next TestFlight build using build number > 3.
7. Perform physical-device offline/online QA and StoreKit/App Store release gates separately.

## #011 brand guardrail

`Family Life OS` is internal only.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Avoid generic house/checkmark, cartoon family, or robot/AI sparkle identity.

## Deferred / rejected for #011 MVP

- generic calendar/shopping/chores clone
- family social/chat replacement
- live GPS
- video/audio calls
- bank/full budgeting
- meal/recipe platform
- complex chore economy
- automatic mailbox surveillance
- autonomous bookings/calls
- medical-advice assistant
- generic AI-chat-first interface
- decorative Liquid Glass everywhere

## Handoff rule for new chats

1. Read this file first.
2. For #002 read `apps/002-evidaro/PROJECT_STATE.md` and continue only from its current green/in-progress gate.
3. For #011 read `apps/011-family-life-os/PROJECT_STATE.md` first; it is the detailed authoritative checkpoint.
4. Inspect current `main`, PR #34 and latest relevant CI before source, merge or deployment changes.
5. Do not regress KeepMeter to pre-TestFlight/pre-StoreKit state; it is submitted to Apple review.
6. Do not regress #002 to `ProofVault`, `Evidaro` public branding, pre-Pass-8, pre-release or pre-TestFlight state; Pass 7/8 and Release PR #33 are merged and signed Build 1 upload succeeded.
7. Do not claim physical camera, physical-iPhone OCR, real biometric prompt, VoiceOver, largest-Dynamic-Type or physical `.evpack` verification for Kamilunavo Trace until explicitly exercised on hardware.
8. Do not regress Family Life OS to Build-2-only, “Realtime/Storage/OCR not implemented”, or “Build 3 missing”.
9. Do not claim PR #31/#34 behavior is live before explicit hosted deployment + verification.
10. Preserve every other portfolio entry when updating one workstream.