# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-20
Status: ACTIVE
Current user-selected workstream: #002 Evidaro (PROVISIONAL)
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
| 002 | Evidaro (PROVISIONAL; ProofVault retired) | Case-based evidence timeline with per-item hashes, snapshot seals and proof export | Freemium + Pro / likely Lifetime | ACTIVE — PASS 7 DE/EN + ACCESSIBILITY + LOCALIZED PDF IMPLEMENTED; FINAL EXACT-HEAD GATE REQUIRED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking | Freemium | QUEUED |
| 004 | SubZero | Detect/track subscriptions and recurring costs | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Gift ideas per person/occasion via share sheet | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists, dates | Subscription | QUEUED |
| 008 | BeforeAfter | Guided repeat photography/alignment/comparison | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Fast portrait reaction/high-score game | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | BUILD 2 DEVICE + HOSTED E2E GREEN / AUTH DOUBLE-SESSION NEXT |

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

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Build/share evidence pack**

Merged green passes:

- Pass 1 foundation — PR #15 — merge `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`
- Pass 2 SwiftData + hashed media — PR #20 — merge `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`
- Pass 3 camera + process-relaunch persistence — PR #22 — merge `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- Pass 3 handoff — PR #23 — merge `0be5e5e08bdd045bbb0994c1da508d9a86ab6951`
- Pass 4 local derived Apple Vision OCR — PR #24 — merge `ad3876dbac044759223d0bdf7a1c095e461bc16b`
- Pass 5 integrity-checked multi-page PDF evidence pack — PR #27 — merge `22f8b560c2529fb064feaa591b901acecf8da573`
- Pass 6 optional device-owner-auth privacy lock — PR #28 — final head `a55f55ebe72280e411670f4757624914d0c1d6ed`, merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`

Current Pass 7:

- PR #29 `Add Evidaro DE/EN localization and accessibility hardening` — OPEN
- branch `agent/002-evidaro-localization-accessibility`
- first complete source gate head `ae6a3b8fbdf25eca08ac040ce614664f5fd718de`
- workflow run `32362074699` — SUCCESS
- build job `96403585360` — SUCCESS
- that run proved preflight, Xcode simulator build, persistence, OCR, PDF, privacy lock and German runtime localization

Pass-7 implementation now includes:

- explicit English and German resources for the app UI and camera/Face ID usage descriptions
- hash-stable persisted enum raw values with separate localized presentation names
- localized Home, case creation, evidence intake, case detail, OCR controls, privacy lock and device-auth prompts
- Dynamic Type adaptive home/action layouts
- VoiceOver headings, combined case-card semantics and full-hash accessibility labels/values
- full DE/EN localization of the generated evidence-pack PDF: metadata, cover, fields, OCR labels, image/PDF preview pages, seal history, continuation text, footer and export errors
- German PDF process-relaunch gate: generate in German, terminate, reopen in German, validate localized PDF again and require identical PDF SHA-256
- PDF/localization presentation changes do not alter original media bytes, evidence-record hashes, manifests or seals

Pass-7 final merge gate:

1. exact documentation-aligned PR #29 head must pass preflight
2. generic Xcode iOS Simulator build must pass
3. persistence process-relaunch smoke must pass
4. Apple Vision OCR + OCR persistence must pass
5. English PDF evidence-pack integrity/relaunch smoke must pass
6. German PDF evidence-pack localization/integrity/relaunch smoke must pass
7. privacy-lock persistence smoke must pass
8. German runtime localization smoke must pass
9. only then merge PR #29

Open physical/release checks after Pass 7:

- physical iPhone camera capture + permission UX
- physical-device OCR spot check
- physical Face ID/Touch ID/device-passcode lock UX
- DE/EN localization review on device
- VoiceOver navigation + largest Dynamic Type review
- final identity/name due diligence and App Store icon
- final Freemium + likely Lifetime Pro entitlement decision
- signed TestFlight / App Store record

Trust boundary:

- no legal-admissibility claim
- no claim that a timestamp independently proves when the real-world event occurred
- hashes are integrity aids, not legal certification
- OCR is derived metadata only
- generated PDF is a derived presentation and does not replace originals
- v1 stays local-first; no evidence upload to Kamilunavo servers

Do not regress Evidaro to `ProofVault`, `QUEUED`, Foundation-only, pre-OCR, pre-PDF or pre-privacy-lock state.

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-19

Family Life OS `0.1.0 (2)` has completed the updated physical-device validation pass on a real iPhone.

User-confirmed Build-2 results:

- Build 2 processed by Apple, visible in TestFlight, installed and launches
- PR #13 completion controls work in Plan and Today for deadline/payment/preparation items
- completed state survives app restart through the hosted persistence path
- Today uses the real current date/time-derived greeting
- old Lina/Ben fixture leakage is gone from the hosted device UI
- **Backend-Diagnose -> Hosted E2E jetzt prüfen** passes on the physical device, including cleanup

This means the Build-2 device gate and the one-button hosted E2E gate are GREEN.

Still intentionally open:

- fresh physical-device Magic Link callback/session round-trip
- second real authenticated user/session through the Data API
- Realtime
- private Storage and photo/PDF intake
- OCR
- real AI extraction/provider
- VoiceOver/release hardening
- StoreKit/subscription

## Existing green checkpoints

- PR #8 hosted Supabase vertical slice — MERGED / iOS + DB green
- PR #9 Auth/RLS hardening — MERGED / iOS + DB green / two-household SQL isolation green
- PR #10 authenticated hosted E2E harness — MERGED / compile green
- PR #11 physical-device Release/TestFlight pipeline — MERGED
- PR #12 App Store bundle validation fixes — MERGED
- PR #13 completion/live-Today pass — MERGED / Simulator + Release/device CI green
- App Store Connect app record — EXISTS
- signed Build 2 `0.1.0 (2)` upload — SUCCESS
- protected bridge run `32285397950`
- Family Life upload job `96173603213`
- exact upload result `UPLOAD SUCCEEDED with no errors.` / exit `0`
- physical Build 2 installation — VERIFIED
- hosted manual import path — VERIFIED on device
- PR #13 completion/live-Today behavior — VERIFIED on device
- hosted completion persistence after app restart — VERIFIED
- Hosted E2E diagnostics including cleanup — VERIFIED on device

## Product thesis / trust boundary

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` remains the signature trust boundary:

- source stays reachable
- proposals stay editable/includable
- unresolved required fields block confirmation
- extraction/AI cannot silently create canonical family data
- explicit confirmation mandatory
- confirmed items retain source + proposal provenance

## Hosted backend / client state

Implementation path:

`apps/011-family-life-os/prototype/`

Project:

`FamilyLifePrototype.xcodeproj`

Target:

- SwiftUI
- iOS/iPadOS 18+
- iPhone + iPad
- bundle id `de.kamilunavo.familyprototype`
- current internal build `0.1.0 (2)`

Data boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Implementations:

- `InMemoryFamilyRepository`
- `SupabaseFamilyRepository`

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- Supabase Swift `2.54.1` pinned
- publishable client key only
- no service-role secret in app

Current proven hosted device path includes household data, manual text import, proposal confirmation, canonical Plan data, provenance, persisted completion and authenticated E2E diagnostics with cleanup.

## Auth redirect state

Callback:

`de.kamilunavo.familyprototype://login-callback`

Hosted Supabase allow-list configuration is USER-CONFIRMED DONE on 2026-08-19.

The remaining auth task is a deliberate fresh real-device Magic Link round-trip, not redirect configuration.

## Apple/TestFlight state

Known Apple team:

- Team ID `TKG684N5GL`

Canonical project workflow:

`.github/workflows/family-life-os-testflight.yml`

Current Apple/device state:

- explicit Bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- App Store Connect app record — EXISTS
- Build 2 signed upload — SUCCESS
- Build 2 TestFlight processing/visibility — VERIFIED by user
- Build 2 physical installation/launch — VERIFIED by user

Obsolete blockers:

- ASC secrets missing
- Bundle ID missing
- App Store Connect app record missing
- provisioning profile as current blocker
- signed upload not successful
- Build 2 not installed
- PR #13 still needs physical verification
- Hosted E2E still untested

## #011 next steps

1. Explicitly test a fresh Magic Link round-trip through `de.kamilunavo.familyprototype://login-callback` and verify a valid hosted session returns to the app.
2. Repeat authenticated Data API coverage with a second real user/session and verify household isolation from the client path.
3. Add Realtime only after both remaining auth/session gates are green.
4. Add private Storage + photo/PDF share intake.
5. Add OCR after Storage/share intake is stable.
6. Add real AI extraction last while retaining editable proposals + explicit confirmation.
7. Gate diagnostics before external distribution and perform physical-device + VoiceOver QA.
8. Add StoreKit/subscription only after the Family Inbox core is stable enough for release hardening.

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
3. For #011 read `apps/011-family-life-os/PROJECT_STATE.md` and `BACKEND_CONTRACT.md`.
4. Inspect current `main` and latest relevant CI gates before code changes.
5. Do not regress KeepMeter to pre-TestFlight/pre-StoreKit state; it is submitted to Apple review.
6. Do not regress Evidaro to `ProofVault`, `QUEUED`, Foundation-only, pre-OCR, pre-PDF or pre-privacy-lock state; Pass 7 is the active DE/EN + accessibility + localized-PDF gate.
7. Do not claim physical camera, physical-iPhone OCR, real biometric prompt, VoiceOver or largest-Dynamic-Type validation until explicitly exercised on hardware.
8. Do not regress Family Life OS to “Build 2 not installed”, “PR #13 unverified” or “Hosted E2E untested”.
9. Preserve every other portfolio entry when updating one workstream.
