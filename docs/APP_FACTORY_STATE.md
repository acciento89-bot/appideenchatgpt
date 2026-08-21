# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-21
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS (INTERNAL CODENAME)
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
| 002 | Evidaro (PROVISIONAL; ProofVault retired) | Case-based evidence timeline with per-item hashes, snapshot seals and proof export | Freemium + Pro / likely Lifetime | ACTIVE — PASS 4 LOCAL VISION OCR FIRST FULL GATE GREEN; FINAL DOC-ALIGNED GATE REQUIRED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking | Freemium | QUEUED |
| 004 | SubZero | Detect/track subscriptions and recurring costs | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Gift ideas per person/occasion via share sheet | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists, dates | Subscription | QUEUED |
| 008 | BeforeAfter | Guided repeat photography/alignment/comparison | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Fast portrait reaction/high-score game | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | COMPLETE V1 BASELINE + PR #31/#34 FULL CI GREEN / PROMOTION + LIVE CANARY PENDING |

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

# Portfolio app #002 — Evidaro

Authoritative app state:

`apps/002-evidaro/PROJECT_STATE.md`

Naming:

- original working title `ProofVault` is retired because a substantially overlapping iPhone/iPad app now uses `ProofVault: Document Vault`
- current candidate `Evidaro` is provisional, not legal/trademark clearance

Product thesis:

> Capture facts while they are fresh. Seal evidence you can verify later.

Core loop:

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Share/export manifest**

Foundation green checkpoint:

- PR #15 merged to `main`
- workflow run `32312124275`
- build job `96257080572`
- Evidaro foundation preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- foundation merge commit `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`

Foundation includes:

- native SwiftUI iPhone prototype / iOS 17+
- case dashboard + case creation
- evidence timeline
- note/source evidence capture
- SHA-256 content hash per evidence item
- repeatable snapshot seals
- shareable text manifest
- dedicated Xcode project/shared scheme
- dedicated `macos-26` GitHub Actions build gate

Pass 2 green checkpoint:

- PR #20 `Add Evidaro SwiftData persistence and hashed media intake` — MERGED
- final PR head `cef51f701627661b58822656641b8ce1c9f2b3a0`
- workflow run `32329202541`
- build job `96306455813`
- persistence/media preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`

Pass 2 includes:

- SwiftData-backed case/evidence/seal models
- persistent ModelContainer / ModelContext
- private local media storage under Application Support
- PhotosPicker image intake
- Files/PDF intake
- original imported byte stream hashed separately with SHA-256
- evidence-record hash includes original-media hash
- original filename/hash displayed in timeline and manifest
- imported original can be shared back out
- `AddEvidenceView` decomposed into smaller SwiftUI components after Xcode 26.6 type-checker failures; only the fully green revision was merged

Pass 3 green checkpoint:

- PR #22 `Add Evidaro camera capture and relaunch persistence gate` — MERGED
- final PR head `1e9ff37129fc386ec278f0b3d2f5e58fa391ccfb`
- workflow run `32330580003`
- build job `96310288293`
- camera/persistence preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- process-relaunch persistence smoke — SUCCESS
- merge commit `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- post-merge handoff PR #23 — MERGED
- handoff merge commit `0be5e5e08bdd045bbb0994c1da508d9a86ab6951`

Pass 3 includes:

- direct camera photo intake on camera-capable iPhones
- camera privacy usage description in Debug and Release
- captured photos routed through the existing private media storage + SHA-256 path
- app-root ownership of the persistent `EvidenceStore`
- automated two-process simulator persistence proof for case, evidence item, stored media bytes, media hash, evidence-record hash and snapshot seal
- exact smoke media SHA-256 survives restart: `5e647718ecb46672d74a0cfa0416a8af0d7bca687ed0349fd146e1191f197728`
- exact smoke seal SHA-256 survives restart: `f9799ea52f49197a71782d15f488545a5bd32cab7bd305e78e6aacc2b12450ff`

Pass-3 boundary:

- automated simulator persistence is proven
- camera integration compiles and is wired to the same media/hash path
- physical iPhone camera hardware and permission-prompt UX are not yet device-verified and remain a pre-release spot check

Pass 4 current checkpoint:

- PR #24 `Add local derived OCR with integrity gate` — OPEN / draft until final exact-head gate
- first green source head `848e365961f6e764948f1920ebf8ef4714af3588`
- workflow run `32335007814`
- build job `96322753291`
- OCR/camera/persistence preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- existing process-relaunch persistence smoke — SUCCESS
- real Apple Vision OCR smoke in iPhone Simulator — SUCCESS
- OCR persistence after app-process restart — SUCCESS

Pass 4 includes:

- local Apple Vision OCR for stored images and PDFs
- OCR stored separately as derived text + recognition time + engine + page count
- recognition validates original stored bytes against the saved original-media SHA-256 before OCR
- OCR never rewrites original media bytes, media SHA-256, evidence-record SHA-256 or prior snapshot seals
- OCR output is intentionally excluded from the canonical integrity manifest/seal and can be refreshed independently
- user-visible `Recognize` / `Refresh` flow with explicit derived-data trust messaging
- deterministic runtime fixture recognizes `EVIDARO 4827`, then verifies the result and integrity state again after process restart
- exact OCR smoke media SHA-256 before/after: `d94f8834fd845ea011f36f753c9ddb91d7dd1dbb24ac2e5b04d7b508d9724355`
- exact OCR smoke evidence-record SHA-256 before/after: `dee235dd17e24fdb04b6a215d4077e03acaea41872c681da55edd996bebaea42`
- exact pre-OCR seal SHA-256 unchanged after OCR/restart: `86fc0200ebf3c861c686c693cc42437c7ab8716d98f7b42ff158140f71aa4ed8`

Pass-4 boundary:

- Vision OCR is runtime-proven in an iPhone Simulator, not yet on a physical iPhone
- OCR remains derived/reviewable data, not authoritative evidence
- physical iPhone camera hardware/permission UX is still open
- because spec/state documentation advances PR #24 beyond the first green source head, the exact final documentation-aligned head must pass the same complete gate before merge

Do not regress Evidaro to Foundation-only, Pass-2-pending, camera/persistence-pending, or “OCR not implemented.”

Next Evidaro gates:

1. rerun preflight + Xcode + persistence + Vision OCR + OCR relaunch verification on the exact final PR #24 documentation head
2. merge PR #24 only after that exact-head gate is green
3. PDF evidence-pack export after OCR/media stability
4. physical-device camera/permission + OCR spot check before release hardening
5. optional location/context metadata
6. Face ID/privacy lock
7. DE/EN + accessibility hardening
8. final identity/name due diligence
9. StoreKit Pro/Lifetime decision
10. signed TestFlight

Trust boundary:

- no legal-admissibility claim
- no claim that a timestamp independently proves when the real-world event occurred
- hashes are integrity aids, not legal certification
- OCR is derived metadata only
- v1 stays local-first; no evidence upload to Kamilunavo servers

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-21

Complete-v1 is the baseline. Do not regress #011 to the old Build-2-only roadmap.

Open hardening stack:

- PR #31 `Family Life OS: harden timezone and review trust boundary`
  - branch `agent/family-life-os-timezone-hardening`
  - validated head `29b942fca118792146acc6079a0fe07697a3bd8d`
  - CI green
  - not merged / not deployed live
- PR #34 `Family Life OS: durable offline source queue`
  - branch `agent/family-life-os-offline-queue`
  - stacked on PR #31
  - latest fully validated app-code head `fd7381e97c349dd282df5b12ffcf68c4bd476538`
  - Prototype Build run `32455964319` — SUCCESS
  - Database Tests run `32455964347` — SUCCESS
  - iPhone/iPad device validation run `32455964321` — SUCCESS
  - not merged / migration not deployed live

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
- the visible upload step was intentionally `continue-on-error`; the recorded `xcodebuild` result contained Apple's duplicate-build-number rejection

Any next Apple upload must use build number greater than `3`.

## Hosted/live boundary

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- household locale/timezone `de-DE` / `Europe/Berlin`
- RLS-enabled collaborative data model
- active JWT-protected `process-family-source` Edge Function

Not live yet:

- PR #31 timezone/AI trust changes
- PR #34 idempotency/offline migration

Do not run the new offline upload protocol against production until those changes are intentionally promoted.

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

1. Merge PR #31 only with explicit merge authorization.
2. Retarget/update PR #34 after #31 reaches `main`, then verify the exact resulting state.
3. Merge PR #34 only with explicit merge authorization.
4. Deploy Edge + migration to hosted Supabase only with explicit live-deployment authorization.
5. Run live canaries for Europe/Berlin timezone, missing-time blocking, offline->online exactly-once ingestion, household isolation and processing-lease recovery.
6. Inspect live `extraction_runs` provider/model.
7. Publish the next TestFlight build using build number > 3.
8. Perform physical-device offline/online QA and StoreKit/App Store release gates separately.

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
4. Inspect current `main`, PR #31 and PR #34 plus latest relevant CI before source or promotion changes.
5. Do not regress KeepMeter to pre-TestFlight/pre-StoreKit state; it is submitted to Apple review.
6. Do not regress Evidaro to `ProofVault`, `QUEUED`, Foundation-only, Pass-2-pending or Pass-3-pending state; Pass 3 is green/merged and Pass 4 OCR is implemented with a first full green runtime gate.
7. Do not claim physical camera or physical-iPhone OCR validation for Evidaro until explicitly exercised on hardware.
8. Do not regress Family Life OS to Build-2-only, “Realtime/Storage/OCR not implemented”, or “Build 3 missing”.
9. Do not claim PR #31/#34 behavior is live before explicit hosted deployment + verification.
10. Preserve every other portfolio entry when updating one workstream.
