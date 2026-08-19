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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | PHYSICAL TESTFLIGHT + HOSTED MANUAL FLOW PROVEN / PR #13 MERGED |

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

The first real-device loop is now partially proven beyond App Store Connect visibility.

User-provided physical iPhone screenshots verify:

- internal TestFlight build installed and running on real iPhone
- hosted household surface loads (`Ich`, owner/full access)
- hosted backend diagnostics sheet is present
- on-device hosted config shows Frankfurt/EU and callback `de.kamilunavo.familyprototype://login-callback`
- user manually used Inbox -> text example import
- resulting hosted import state is visibly present in Inbox and Plan
- imported canonical Plan items show provenance (`Aus Import`)

Evidence boundary:

- physical TestFlight installation — VERIFIED
- hosted manual data path on device — visibly working
- fresh Magic Link callback round-trip — NOT explicitly re-verified yet
- one-button `Hosted E2E jetzt prüfen` result — NOT yet verified
- second real authenticated user/session — NOT yet verified

### Existing green checkpoints

- PR #8 hosted Supabase vertical slice — MERGED / iOS + DB green
- PR #9 Auth/RLS hardening — MERGED / iOS + DB green / two-household isolation green
- PR #10 authenticated hosted E2E smoke harness — MERGED / compile green
- PR #11 physical-device Release/TestFlight pipeline — MERGED
- PR #12 App Store bundle validation fixes — MERGED
- App Store Connect app record — EXISTS
- signed Family Life OS build visible in App Store Connect/TestFlight — YES
- physical iPhone TestFlight installation — YES
- manual hosted text import visibly reaches Inbox/Plan on-device — YES

### PR #13 — completion + live Today

- PR `#13` — MERGED
- tested head `498f5a7a036a038454bbd387100bb32faf4b31e9`
- squash commit `ce7d5c0b09a1cd5f4944b2b88d7c14d205affa71`
- Prototype Build run `32278953444` / #26 — SUCCESS
- TestFlight PR validation run `32278953395` / #7 — SUCCESS
- PR validation upload step skipped by design

PR #13 implements physical-device feedback:

- deadlines, payments, tasks and preparation items can be marked complete
- completion available in Plan
- completion available directly in Today -> `Braucht Aufmerksamkeit`
- completion available in `Für morgen vorbereiten`
- existing hosted repository completion path is used, not UI-only state
- Today now uses actual current date/time instead of hard-coded 18 August
- greeting follows current time
- Today/tomorrow filters are real-date based
- hard-coded Lina/Ben family-summary fixture leakage removed
- family overview now derives from current hosted plan/attention/conflict state
- Today `+` opens a pending review or starts the current internal deterministic text-test import
- deterministic reference date retained for previews

Important: the user's screenshots predate PR #13. The merged completion/live-Today behavior still needs a newer internal device build before physical verification.

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
- provisional bundle id `de.kamilunavo.familyprototype`
- internal marketing version `0.1.0`

Data boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Implementations:

- `InMemoryFamilyRepository`
- `SupabaseFamilyRepository`

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- last recorded `ACTIVE_HEALTHY`
- Supabase Swift `2.54.1` pinned
- publishable client key only
- no service-role secret in app

Hosted client capabilities:

- Magic Link auth/session gate
- custom app redirect handling
- exact callback validation
- household bootstrap
- hosted members/Inbox/proposals/assignees/Plan reads
- deterministic server fixture text import
- reviewed proposal edits + assignee persistence
- canonical confirm RPC
- persisted remote completion
- remote child profile creation
- authenticated hosted E2E diagnostics harness

Diagnostics remain intentionally available for the first **internal TestFlight/device smoke** and must be gated before external TestFlight/App Store distribution.

## Auth redirect state

Callback:

`de.kamilunavo.familyprototype://login-callback`

User confirmed on **2026-08-19** that this redirect URL is configured in hosted Supabase Auth URL Configuration.

Do not regress to “Auth redirect not configured”. A fresh physical-device Magic Link callback/session round-trip still needs explicit verification.

## Apple/TestFlight state

Known Apple team:

- Team ID `TKG684N5GL`

Canonical workflow:

`.github/workflows/family-life-os-testflight.yml`

Current Apple/device state:

- explicit Bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- Apple Bundle ID resource previously verified as `2NV99ZM2PM`
- App Store Connect app record — EXISTS
- signed build visible in App Store Connect/TestFlight — YES
- physical TestFlight installation — YES
- hosted manual text path on physical device — visibly working

Obsolete blockers:

- ASC secrets missing
- Bundle ID missing
- App Store Connect app record missing
- provisioning profile as current blocker
- signed upload not yet successful
- physical TestFlight install not proven

## #011 validation boundary

Validated:

- hosted migrations rolled out
- hosted Security Advisor clean at last check
- `SupabaseFamilyRepository` compiles
- fresh local Supabase/Postgres + pgTAP green
- two-identity RLS isolation green locally
- direct hosted SQL isolation green
- PR #9 Xcode + DB green
- PR #10 smoke harness compile green
- Supabase callback allow-list configured
- Release physical-device `iphoneos` build green
- App Store Connect app record exists
- signed build reached App Store Connect/TestFlight
- physical iPhone TestFlight installation proven
- manual deterministic hosted text import visibly reaches Inbox/Plan on-device
- PR #13 Simulator build green
- PR #13 Release/device PR validation green

Not yet release-validated:

- PR #13 completion/live-Today behavior on updated physical device build
- fresh Magic Link callback/session round-trip
- one-button hosted E2E result from real authenticated iPhone/iPad
- second real authenticated Data API session/isolation
- Realtime
- private Storage
- photo/PDF ingestion
- OCR
- real AI extraction
- physical-device/manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## #011 next steps

1. Produce/install an updated internal build containing PR #13.
2. Verify deadline/payment/preparation completion persists after navigation/reload.
3. Run **Backend-Diagnose -> Hosted E2E jetzt prüfen** and require all steps including cleanup to pass.
4. Explicitly test a fresh Magic Link round-trip through `de.kamilunavo.familyprototype://login-callback`.
5. Repeat with a second real authenticated session for final Auth/Data-API isolation coverage.
6. Add Realtime only after those physical-device gates are green.
7. Add private Storage + photo/PDF share intake.
8. Add OCR.
9. Add real AI extraction last while retaining explicit proposal review/confirmation.
10. Gate diagnostics before external distribution and perform physical-device + VoiceOver QA before release readiness.

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
2. Read the selected app-specific state.
3. For #011 read `apps/011-family-life-os/PROJECT_STATE.md` and `BACKEND_CONTRACT.md`.
4. Inspect current `main` and latest relevant CI gates before code changes.
5. Continue #011 from **updated PR #13 device build -> completion persistence -> Hosted E2E -> fresh Magic Link -> second session**.
6. Do not regress to “ASC secrets missing”.
7. Do not regress to “Bundle ID missing”.
8. Do not regress to “App Store Connect app record missing”.
9. Do not regress to “signed TestFlight upload not successful”.
10. Do not regress to “physical TestFlight not installed” — user provided physical-device screenshots on 2026-08-19.
11. Do not claim one-button Hosted E2E or fresh Magic Link passed until actually exercised.
12. Do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device gates are green.
13. Preserve every other portfolio entry when updating one workstream.
