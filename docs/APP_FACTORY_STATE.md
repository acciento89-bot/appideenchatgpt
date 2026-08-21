# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-21
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS — hosted backend promoted / Build 4 uploaded / physical live canary next
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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | COMPLETE V1 + PR31/34 MERGED + SUPABASE LIVE + BUILD 4 UPLOADED / PHYSICAL CANARY NEXT |

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

Authoritative detailed state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-21

Complete-v1 is the baseline. PR #31 and PR #34 are merged, their hosted backend changes have been intentionally promoted, and Family Life OS `0.1.0 (4)` has been successfully handed to App Store Connect/TestFlight.

### Repository promotion

PR #31:

- final validated head `29b942fca118792146acc6079a0fe07697a3bd8d`
- merge `0db452c41a4c197cb95d0bb48b9455561435f8d4`

PR #34:

- final exact post-main head `1802a909b27e61ee4ecc5b0ce3d8f9342529d84d`
- Database Tests `32464891177` — SUCCESS
- Prototype Build `32464891211` — SUCCESS
- iPhone/iPad validation `32464891184` — SUCCESS
- merge `1de4a500b15fa733306f75605f817dd10b5fa43b`

Do not regress either PR to open/pending/unmerged state.

### Hosted Supabase — LIVE

Project:

- ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- household locale/timezone `de-DE` / `Europe/Berlin`

Promoted on 2026-08-21:

- migration `source_ingestion_idempotency`
- hosted `process-family-source` Edge Function version `2`
- Edge status `ACTIVE`
- JWT verification enabled

Post-migration verification:

- `source_items.client_request_id` exists
- tenant-scoped idempotency index exists
- 5-argument `create_source_item` and 7-argument `finalize_source_upload` are active
- `anon` execute denied
- `authenticated` execute granted

Production DB canary was run inside a transaction and rolled back. It proved:

- duplicate `clientRequestID` resolves to one source
- wrong-household routing is rejected
- deferred upload finalize is idempotent and remains queued
- simulated lost-response retry still resolves to one source
- no canary rows were intentionally retained

### Timezone/review trust now deployed

- household IANA timezone used for deterministic extraction
- no invented 09:00 for missing source time
- member/time/start/due blockers remain independent
- explicit offset/Z required for provider timestamps
- unresolved proposals receive no reminder suggestion

### Edge/provider evidence boundary

Do not overclaim the runtime provider.

After deployment there had not yet been a real authenticated Edge-v2 canary. The latest observed `extraction_runs` still contained only older fixture evidence (`fixture` / `school-letter-v1`, schema 1).

Therefore do not claim:

- `OPENAI_API_KEY` exists
- OpenAI has run in production
- rules fallback has run on Edge v2
- 18:00 Europe/Berlin behavior has been proven by a live schema-v3 extraction

The first Build-4 source import is the next proof point; inspect its resulting `extraction_runs` provider/model afterward.

### Durable offline source path now deployed

- text/photo/camera/PDF/voice are persisted locally before network work
- queue survives app restart
- local Inbox visibility
- stable client request UUID
- tenant-scoped server idempotency
- deterministic retry-safe Storage path/upsert
- queue bound to authenticated user + household
- automatic `NWPathMonitor` offline -> online resume
- fresh processing lease avoids duplicate parallel extraction after lost response

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
- source built from `appideenchatgpt/main`
- Apple exporter: `ARCHIVE SUCCEEDED`, `Upload succeeded`, `EXPORT SUCCEEDED`
- bridge result: SUCCESS

Safe claim: Build 4 was successfully uploaded/handed to App Store Connect/TestFlight.

Apple processing/TestFlight visibility remains pending until externally observed.

### Security / StoreKit boundaries

Security advisor still reports security-definer warnings for the ingestion RPCs and the older hosted E2E RPC, plus leaked-password protection disabled. The new ingestion RPCs are nevertheless execution-restricted to authenticated users and enforce household permission checks. Do not describe the advisor warnings as resolved.

StoreKit 2 Family Pro foundation exists, but paid release readiness is not proven until App Store Connect IAP products and a real sandbox/TestFlight purchase + restore path are verified.

## #011 next physical sequence

One step at a time:

1. Wait until Build 4 is visible in TestFlight and install it.
2. First live Edge-v2 canary: capture exactly `Elternabend am 21.08.2026 um 18:00 Uhr.` and verify review displays 18:00 Europe/Berlin.
3. Inspect the resulting hosted schema-v3 `extraction_runs` provider/model.
4. Then test date without time -> explicit unresolved time, never fake 09:00.
5. Then test offline capture -> reconnect -> exactly one source.
6. Then finish physical account/household isolation and StoreKit/release QA.

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
2. For #002 read `apps/002-evidaro/PROJECT_STATE.md` and preserve its current Kamilunavo Trace release state.
3. For #011 read `apps/011-family-life-os/PROJECT_STATE.md` first; it is the detailed authoritative checkpoint.
4. Inspect current `main` and any newer Family PRs before code changes.
5. Do not regress KeepMeter to pre-TestFlight/pre-StoreKit state; it is submitted to Apple review.
6. Do not regress Kamilunavo Trace to `ProofVault`, `Evidaro` public branding, pre-Pass-8, pre-release or pre-TestFlight state.
7. Do not regress Family Life OS to Build-2-only, PR31/34-pending, backend-not-deployed, or Build-3-missing state.
8. Treat Family Edge v2 + migration as live, but do not claim a real provider run until a schema-v3 hosted extraction proves it.
9. Treat Build 4 as uploaded successfully, while processing/visibility remains unconfirmed until observed.
10. Preserve every other portfolio entry when updating one workstream.