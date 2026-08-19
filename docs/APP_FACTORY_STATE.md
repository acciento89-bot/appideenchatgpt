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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | TESTFLIGHT BUILD 2 UPLOADED / PHYSICAL BUILD 2 VALIDATION NEXT |

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

The first real-device hosted loop is proven far enough to move into the updated PR #13 device-validation pass, and the updated signed build has now reached Apple.

User-provided physical iPhone screenshots verify the earlier internal build:

- internal TestFlight build installed and running on real iPhone
- hosted household surface loads (`Ich`, owner/full access)
- hosted backend diagnostics sheet is present
- on-device hosted config shows Frankfurt/EU and callback `de.kamilunavo.familyprototype://login-callback`
- user manually used Inbox -> text example import
- resulting hosted import state is visibly present in Inbox and Plan
- imported canonical Plan items show provenance (`Aus Import`)

New TestFlight Build 2 checkpoint:

- version/build `0.1.0 (2)`
- source includes merged PR #13
- protected bridge run `32285397950`
- Family Life upload job `96173603213`
- Release `iphoneos` build — SUCCESS
- archive — SUCCESS
- Apple cloud-signing/export/upload — SUCCESS
- exact Apple/Xcode result: `UPLOAD SUCCEEDED with no errors.`
- upload exit status `0`
- protected App Store Connect secret values were not printed or committed
- temporary bridge changes in `acciento89-bot/onemorefloor` were cleaned after upload and trigger PR #98 was closed without merge

Evidence boundary:

- physical installation of earlier TestFlight build — VERIFIED
- hosted manual data path on device — visibly working
- Build 2 Apple upload — VERIFIED
- Build 2 post-upload processing / TestFlight visibility — NOT yet explicitly observed
- Build 2 physical installation / PR #13 behavior — NOT yet verified
- fresh Magic Link callback round-trip — NOT explicitly re-verified yet
- one-button `Hosted E2E jetzt prüfen` result — NOT yet verified
- second real authenticated user/session — NOT yet verified

### Existing green checkpoints

- PR #8 hosted Supabase vertical slice — MERGED / iOS + DB green
- PR #9 Auth/RLS hardening — MERGED / iOS + DB green / two-household isolation green
- PR #10 authenticated hosted E2E smoke harness — MERGED / compile green
- PR #11 physical-device Release/TestFlight pipeline — MERGED
- PR #12 App Store bundle validation fixes — MERGED
- PR #13 completion/live-Today pass — MERGED / Simulator + Release/device PR validation green
- App Store Connect app record — EXISTS
- physical iPhone TestFlight installation of earlier build — YES
- manual hosted text import visibly reaches Inbox/Plan on-device — YES
- signed Build 2 containing PR #13 uploaded successfully to Apple — YES

### PR #13 — completion + live Today

- PR `#13` — MERGED
- tested head `498f5a7a036a038454bbd387100bb32faf4b31e9`
- squash commit `ce7d5c0b09a1cd5f4944b2b88d7c14d205affa71`
- Prototype Build run `32278953444` / #26 — SUCCESS
- TestFlight PR validation run `32278953395` / #7 — SUCCESS
- included in signed TestFlight Build 2 `0.1.0 (2)`

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

Important: PR #13 is uploaded in Build 2 but still requires physical-device verification once Apple processing completes and the user installs/updates it through TestFlight.

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
- latest uploaded build `0.1.0 (2)`

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

Canonical project workflow:

`.github/workflows/family-life-os-testflight.yml`

Current Apple/device state:

- explicit Bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- Apple Bundle ID resource previously verified as `2NV99ZM2PM`
- App Store Connect app record — EXISTS
- earlier signed build physically installed — YES
- hosted manual text path on physical device — visibly working
- Build 2 `0.1.0 (2)` upload — SUCCESS (`32285397950`, job `96173603213`, exit `0`)
- Build 2 Apple processing / physical installation — pending explicit observation

Obsolete blockers:

- ASC secrets missing
- Bundle ID missing
- App Store Connect app record missing
- provisioning profile as current blocker
- signed upload not yet successful
- physical TestFlight install not proven
- PR #13 still needs a signed upload

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
- physical iPhone TestFlight installation of earlier build proven
- manual deterministic hosted text import visibly reaches Inbox/Plan on-device
- PR #13 Simulator build green
- PR #13 Release/device PR validation green
- Build 2 signed Apple upload green and contains PR #13

Not yet release-validated:

- Build 2 post-upload processing / TestFlight visibility
- Build 2 physical installation
- PR #13 completion/live-Today behavior on physical device
- completion persistence across navigation/relaunch/hosted refresh
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

1. Install/update to Build 2 `0.1.0 (2)` once Apple finishes processing it in TestFlight.
2. Verify real Today date/time-derived greeting and absence of stale Lina/Ben fixture data.
3. Verify deadline/payment/task/preparation completion from Plan and Today persists after navigation, relaunch and hosted refresh.
4. Run **Backend-Diagnose -> Hosted E2E jetzt prüfen** and require all steps including cleanup to pass.
5. Explicitly test a fresh Magic Link round-trip through `de.kamilunavo.familyprototype://login-callback`.
6. Repeat with a second real authenticated session for final Auth/Data-API isolation coverage.
7. Add Realtime only after those physical-device gates are green.
8. Add private Storage + photo/PDF share intake.
9. Add OCR.
10. Add real AI extraction last while retaining explicit proposal review/confirmation.
11. Gate diagnostics before external distribution and perform physical-device + VoiceOver QA before release readiness.

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
5. Continue #011 from **Build 2 physical install -> completion/live-Today persistence -> Hosted E2E -> fresh Magic Link -> second session**.
6. Do not regress to “ASC secrets missing”.
7. Do not regress to “Bundle ID missing”.
8. Do not regress to “App Store Connect app record missing”.
9. Do not regress to “signed TestFlight upload not successful” — Build 2 upload succeeded in run `32285397950`.
10. Do not regress to “physical TestFlight not installed” — an earlier build is proven installed by user screenshots on 2026-08-19.
11. Do not claim Build 2 is installed/processed until explicitly observed.
12. Do not claim one-button Hosted E2E or fresh Magic Link passed until actually exercised.
13. Do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device gates are green.
14. Preserve every other portfolio entry when updating one workstream.
