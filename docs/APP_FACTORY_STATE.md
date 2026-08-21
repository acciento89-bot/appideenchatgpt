# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-21
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS — Build 4 physically verified / OpenAI live / household isolation + StoreKit next
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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | COMPLETE V1 + PR31/34/40 MERGED + SUPABASE/OPENAI LIVE + BUILD 4 PHYSICAL QA IN PROGRESS |

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
- App Store Connect metadata, screenshots, age rating, content rights, DSA and review information completed
- KeepMeter `0.1.0 (1)` submitted to Apple App Review on 2026-08-20
- repository Gate #27 records `App Store Review submitted / Apple review decision pending`
- KeepMeter gate/documentation PR #34 merged; merge `2d99da17f712bb6de911fd92561a91cd149eaf16`

Do not regress KeepMeter to “StoreKit/ASC/TestFlight still open.” The next meaningful external event is Apple's review decision or review feedback.

# Portfolio app #002 — Kamilunavo Trace

Authoritative app state:

`apps/002-evidaro/PROJECT_STATE.md`

Naming:

- `ProofVault` retired because a substantially overlapping iPhone/iPad app now uses `ProofVault: Document Vault`
- `Evidaro` retired as public name; retained only in historical internal paths/fixtures
- final public name locked for this release as `Kamilunavo Trace`
- repository research is not legal trademark clearance

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
- Pass 6 optional device-owner-auth privacy lock — PR #28 — merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`
- Pass 7 DE/EN localization + accessibility — PR #29 — merge `bf3ecf74887c08d52bbadf11a13174c83133b093`
- Pass 8 `.evpack` verification — PR #32 — merge `e5c57335888a80e120fefea686b29f6ed8715b2f`

Release pass — GREEN / MERGED / BUILD 1 UPLOADED:

- PR #33 — merged
- final tested release head `090b1471…`
- static release run `32412043585` — SUCCESS
- unsigned iPhone Release/TestFlight validation `32412043598` — SUCCESS
- full simulator integrity/relaunch `32412043953` — SUCCESS
- release merge `69b8a1d99082ff804f2a532c636af3008d79546a`
- public name `Kamilunavo Trace`; bundle `de.kamilunavo.trace`
- `.evpack` v1 format id `de.kamilunavo.trace.evpack`
- Lifetime Pro non-consumable `de.kamilunavo.trace.pro.lifetime`
- Free: up to 3 cases; received-bundle verification remains free
- Pro: unlimited cases + PDF export + `.evpack` export
- App Store Connect app record exists
- signed TestFlight Build 1 `0.1.0 (1)` upload succeeded via protected bridge
- bridge run `32445560808`; upload job `96665754912`
- Apple processing / TestFlight visibility remains an external confirmation gate

External next for #002:

- create/configure Lifetime Pro IAP and final price if not already done
- confirm Apple TestFlight processing visibility
- physical iPhone camera/OCR/biometric/VoiceOver/Dynamic Type QA
- real TestFlight Lifetime purchase, relaunch entitlement recovery and Restore

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative detailed state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-21

Complete-v1 is the baseline. PR #31, PR #34 and PR #40 are merged. Hosted Supabase migration + Edge v3 are live. Build 4 is visible in TestFlight, installed on a physical iPhone, and has completed the first real production-runtime canaries. OpenAI is now production-proven.

### Repository promotion

PR #31:

- validated head `29b942fca118792146acc6079a0fe07697a3bd8d`
- merge `0db452c41a4c197cb95d0bb48b9455561435f8d4`

PR #34:

- final exact head `1802a909b27e61ee4ecc5b0ce3d8f9342529d84d`
- Database Tests `32464891177` — SUCCESS
- Prototype Build `32464891211` — SUCCESS
- iPhone/iPad validation `32464891184` — SUCCESS
- merge `1de4a500b15fa733306f75605f817dd10b5fa43b`

PR #40:

- fixes fallback parser treating dotted German date `21.08.` as clock time `21:08`
- head `8df3e5fc5a1cd1ae67d0889ba0732772dd183276`
- Prototype Build `32473333689` — SUCCESS
- Database Tests `32473333746` — SUCCESS
- merge `ad531aef1f2c78b6d04df1a2217353157001e824`
- fallback marker is now `family-rules-v3`

Do not regress these PRs to open/pending/unmerged state.

### Hosted Supabase — LIVE

Project:

- ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- household locale/timezone `de-DE` / `Europe/Berlin`

Live backend:

- migration `source_ingestion_idempotency`
- hosted `process-family-source` Edge Function version `3`
- Edge status `ACTIVE`
- JWT verification enabled
- schema version `3`

Post-migration verification:

- `source_items.client_request_id` exists
- tenant-scoped idempotency index exists
- 5-argument `create_source_item` and 7-argument `finalize_source_upload` active
- `anon` execute denied
- `authenticated` execute granted

DB rollback canary proved same-request idempotency, wrong-household rejection, deferred-finalize idempotency and lost-response retry behavior.

### Physical Build-4 runtime evidence

Rules fallback:

- initial `family-rules-v2` canary exposed the dotted-date bug (`21.08.` -> 21:08)
- Edge v3 / `family-rules-v3` corrected the same source to 18:00 Europe/Berlin
- date-without-time source remained `time = required`
- no reminder was produced while time was unresolved

Offline queue:

- offline source appears immediately as `Wartet auf Upload` / `lokal gesichert`
- local source survives app termination/relaunch while offline
- reconnect automatically resumes sync
- separately created test sources had separate client request IDs and exactly one server row per request ID

OpenAI:

- user configured `OPENAI_API_KEY` in hosted Supabase secrets
- real schema-v3 run proved `provider = openai`, `model = gpt-5.6-luna`
- `Elternabend am 26.08.2026 um 18:30` stored as `16:30Z` = 18:30 Europe/Berlin
- date-without-time `Elternabend am 27.08.2026` remained `time = required`
- missing-time OpenAI proposal had no reminder

The production provider boundary is closed: both `family-rules-v3` and OpenAI are proven live.

### Apple / TestFlight

Bundle:

`de.kamilunavo.familyprototype`

Build 2:

- physically installed and user-verified
- completion persistence + hosted E2E including cleanup verified

Build 3:

- already existed in App Store Connect before the historical retry
- do not describe it as missing

Build 4:

- protected bridge repo `acciento89-bot/onemorefloor`
- bridge commit `bc77c18f5ee5ef65ea2a1822635fc86c8b41fa10`
- workflow run `32466397060`
- upload job `96723790084`
- Apple exporter: `ARCHIVE SUCCEEDED`, `Upload succeeded`, `EXPORT SUCCEEDED`
- user confirmed Build 4 visible in TestFlight and installed it
- physical runtime canaries above were performed with Build 4

PR #40 is server-side; no new TestFlight build is required solely for that parser fix.

### Security / StoreKit boundaries

Security advisor still reports security-definer warnings for the ingestion RPCs and older hosted E2E RPC plus leaked-password protection disabled. The ingestion RPCs remain execution-restricted to authenticated users and perform household permission checks. Do not describe advisor warnings as resolved.

StoreKit 2 Family Pro foundation exists for:

- monthly `de.kamilunavo.family.familypro.monthly`
- annual `de.kamilunavo.family.familypro.annual`
- product loading
- entitlement observation
- purchase
- Restore via `AppStore.sync()`

Paid release readiness is not proven until App Store Connect products and a real TestFlight/sandbox purchase, relaunch entitlement recovery and Restore are physically verified.

## #011 next physical sequence

One step at a time:

1. Physical household/account isolation, especially ownership of locally queued sources across login/household changes.
2. Verify monthly + annual Family Pro products in App Store Connect.
3. Real TestFlight/sandbox purchase.
4. Relaunch entitlement recovery.
5. Restore / `AppStore.sync()`.
6. Remaining App Store release metadata/device gates.

## #011 product/trust guardrail

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` remains mandatory:

- original source reachable
- OCR/AI creates editable proposals only
- unresolved required values block confirmation
- never invent missing date/time/person information
- explicit confirmation creates canonical Plan data
- confirmed items retain provenance

`Family Life OS` remains an internal name. Preferred icon direction remains **Gather -> Order**.

## Handoff rule for new chats

1. Read this file first.
2. For #001 preserve KeepMeter as submitted to Apple review with StoreKit/TestFlight already proven.
3. For #002 read `apps/002-evidaro/PROJECT_STATE.md`; preserve Kamilunavo Trace public branding, merged Pass 7/8/release state and successful Build 1 upload.
4. For #011 read `apps/011-family-life-os/PROJECT_STATE.md`; it is the detailed authoritative checkpoint.
5. Inspect current `main` and newer Family PRs before changes.
6. Do not regress Family Life OS to Build-2-only, Build-3-missing, PR31/34/40-pending, backend-not-deployed, provider-unproven or Build-4-not-installed state.
7. Treat Family Edge v3 + idempotency migration as live.
8. Treat both `family-rules-v3` and `openai` / `gpt-5.6-luna` production execution as proven.
9. Preserve the Review trust boundary and household isolation on every future Family pass.
10. Preserve every other portfolio entry when updating one workstream.
