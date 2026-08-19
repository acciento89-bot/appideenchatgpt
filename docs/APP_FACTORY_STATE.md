# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-19
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS
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
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool | Freemium + Lifetime Pro | ACTIVE — polished MVP green; StoreKit/QA next |
| 002 | ProofVault | Evidence/documentation vault | Freemium + Pro | QUEUED |
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

Current recorded direction:

- native SwiftUI iPhone utility
- iOS 17+
- local-first
- SwiftData
- UserNotifications
- explainable deterministic decision engine
- DE/EN
- Free tier: 5 active purchases
- StoreKit 2 Lifetime Pro
- provisional bundle id `de.kamilunavo.keepmeter`
- product id `de.kamilunavo.keepmeter.pro.lifetime`

Green product surface:

- Dashboard / Add Purchase / Detail / Archive
- usage logging + cost/use
- return countdown
- KEEP / REVIEW / RETURN? engine
- reminders
- StoreKit entitlement/purchase/restore plumbing
- free-tier enforcement + paywall
- onboarding
- Active / Insights / Archive / Settings
- DE/EN localization
- visual system
- GitHub Actions simulator gate

Next KeepMeter work:

1. local `.storekit` config + App Store Connect Lifetime IAP
2. persistence/relaunch + notification QA
3. free-limit / purchase / restore QA
4. light/dark + accessibility QA
5. icon/identity/name due diligence
6. signed TestFlight after QA gates

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint — 2026-08-19

Family Life OS `0.1.0 (2)` has completed the updated physical-device validation pass on a real iPhone.

User-confirmed Build-2 results:

- Build 2 processed by Apple, visible in TestFlight, installed and launches
- PR #13 completion controls work in Plan and Today for deadline/payment/task/preparation items
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
2. Read `apps/011-family-life-os/PROJECT_STATE.md` and `BACKEND_CONTRACT.md`.
3. Inspect current `main` and latest relevant CI gates before code changes.
4. Continue #011 from **fresh Magic Link -> second real session -> Realtime -> private Storage/photo/PDF intake**.
5. Do not regress to “Build 2 not installed” or “PR #13 unverified”.
6. Do not regress to “Hosted E2E not tested” — the user confirmed the Build-2 E2E checklist works perfectly.
7. Do not claim fresh Magic Link or second-session isolation passed until explicitly exercised.
8. Do not jump to Realtime/Storage/OCR/AI before the two remaining authenticated physical-device gates are green.
9. Preserve every other portfolio entry when updating one workstream.
