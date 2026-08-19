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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | TESTFLIGHT BUILD VISIBLE / PHYSICAL DEVICE SMOKE NEXT |

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

Apple/TestFlight blocker is cleared.

User-confirmed:

- App Store Connect app record exists
- a Family Life OS build is visible in App Store Connect / TestFlight
- therefore a signed Apple upload successfully reached App Store Connect

Evidence note:

- PR validation workflows may show green while the upload step is skipped by design
- the visible App Store Connect build is the decisive evidence that a real upload succeeded
- exact successful upload workflow/run ID has not yet been matched back to the visible build in this checkpoint

### Existing green checkpoints

- PR #8 hosted Supabase vertical slice — MERGED / iOS + DB green
- PR #9 Auth/RLS hardening — MERGED / iOS + DB green / two-household isolation green
- PR #10 authenticated hosted E2E smoke harness — MERGED / compile green
- PR #11 physical-device Release/TestFlight pipeline — MERGED
- PR #12 App Store bundle validation fixes — MERGED
- Release generic `iphoneos` build — GREEN
- unsigned physical-device artifact — GREEN
- hosted Supabase callback allow-list — USER-CONFIRMED configured
- App Store Connect app record — EXISTS
- signed Family Life OS build visible in App Store Connect / TestFlight — YES

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
- internal version path `0.1.0 (1)`

Data boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Implementations:

- `InMemoryFamilyRepository`
- `SupabaseFamilyRepository`

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- last observed `ACTIVE_HEALTHY`
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
- remote completion
- remote child profile creation
- authenticated hosted E2E diagnostics harness

The diagnostics UI is intentionally allowed for the first **internal TestFlight/device smoke** and must be gated before external TestFlight/App Store distribution.

## Auth redirect state

Callback:

`de.kamilunavo.familyprototype://login-callback`

User confirmed on **2026-08-19** that this redirect URL is configured in hosted Supabase Auth URL Configuration.

Do not regress to “Auth redirect not configured”. Physical-device callback/session establishment remains unverified until exercised from TestFlight.

## Apple/TestFlight state

Known Apple team:

- Team ID `TKG684N5GL`

Canonical workflow:

`.github/workflows/family-life-os-testflight.yml`

Current Apple state:

- explicit Bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- Apple Bundle ID resource previously verified as `2NV99ZM2PM`
- App Store Connect app record — EXISTS
- signed build visible in App Store Connect/TestFlight — YES
- physical-device authenticated smoke — NEXT

Obsolete blockers:

- ASC secrets missing
- Bundle ID missing
- App Store Connect app record missing
- provisioning profile as current blocker
- signed upload not yet successful

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
- device artifact packaging green
- working ASC credentials previously proven through secure bridge
- Bundle ID exists
- App Store Connect app record exists
- signed build reached App Store Connect/TestFlight

Not yet release-validated:

- physical-device install of current TestFlight build
- Magic Link callback/session on physical device
- one-button hosted E2E smoke from a real authenticated iPhone/iPad
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

1. Install the current internal TestFlight build on a physical iPhone/iPad.
2. Request Magic Link and verify authenticated return through `de.kamilunavo.familyprototype://login-callback`.
3. Open **Backend-Diagnose** -> **Hosted E2E jetzt prüfen**.
4. Require every smoke step including cleanup to pass.
5. Repeat with a second real authenticated session for final Auth/Data-API isolation coverage.
6. Add Realtime only after physical-device hosted text smoke is green.
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
5. Continue #011 from **physical-device TestFlight install -> Magic Link -> authenticated hosted E2E smoke**.
6. Do not regress to “ASC secrets missing”.
7. Do not regress to “Bundle ID missing”.
8. Do not regress to “App Store Connect app record missing”.
9. Do not regress to “signed TestFlight upload not successful” — user confirmed a build visible in App Store Connect on 2026-08-19.
10. Do not regress to “Auth redirect not configured”.
11. Do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device hosted text smoke is proven.
12. Preserve every other portfolio entry when updating one workstream.
