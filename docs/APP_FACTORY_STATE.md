# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-19
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS
Repository purpose: persistent handoff/state repository for the full App Factory so work can continue across chat limits and new conversations without losing decisions or progress.

> This file is the portfolio-level single source of truth. Detailed historical states remain in Git history and each app-specific state.

## Mandatory workflow

1. Build/validate apps sequentially starting with #001 unless the user explicitly selects another workstream.
2. Update this repository after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Read this file first in a new chat, then the selected app's project state.
4. Major source passes must pass CI/regression gates before merge/TestFlight.
5. Do not weaken a core product loop by adding adjacent features.
6. Do not force subscriptions where lifetime/one-time better fits economics.
7. Re-check current App Store/web and appropriate trademark/domain sources before locking a public name.
8. Never overwrite another candidate's state while updating one workstream.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost/use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — polished MVP green; StoreKit/QA next |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking | Freemium | QUEUED |
| 004 | SubZero | Detect/track subscriptions and recurring costs | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Gift ideas per person/occasion via share sheet | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists, dates | Subscription | QUEUED |
| 008 | BeforeAfter | Guided repeat photography/alignment/comparison | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Fast portrait reaction/high-score game | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | APP STORE CONNECT APP RECORD REQUIRED / BUNDLE ID VERIFIED |

# Portfolio app #001 — KeepMeter

## Authoritative state

App repo:

`acciento89-bot/keepmeter`

App state:

`acciento89-bot/keepmeter/docs/PROJECT_STATE.md`

Current recorded verified checkpoint:

`45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Latest recorded app-state update:

`fb84802c477593f243c5187bc46b5d021cd0ee4d`

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

Locked implementation:

- native iPhone utility
- SwiftUI + SwiftData
- iOS 17+
- local-first; no account/backend for core v1
- UserNotifications for deadline reminders
- explainable deterministic decision engine
- German + English from first build
- Free tier: 5 active purchases
- StoreKit 2 Lifetime Pro; no subscription in v1
- provisional bundle id `de.kamilunavo.keepmeter`
- product id `de.kamilunavo.keepmeter.pro.lifetime`

Implemented/green:

- Dashboard / Add Purchase / Detail / Archive
- usage logging + cost per use
- return countdown
- KEEP / REVIEW / RETURN? engine
- local reminders
- StoreKit entitlement/purchase/restore plumbing
- free-tier enforcement + paywall
- onboarding
- Active / Insights / Archive / Settings
- DE/EN localization
- coherent visual system
- GitHub Actions simulator build gate

Recorded gates:

- functional MVP run `32178808223` — SUCCESS
- visual polish run `32179763750` — SUCCESS
- visual polish merge checkpoint `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Open work:

1. local `.storekit` config and App Store Connect Lifetime IAP
2. persistence/relaunch + notification QA
3. free-limit / purchase / restore QA
4. light/dark + accessibility QA
5. final icon/identity/name due diligence
6. first signed TestFlight only after QA gates are green

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint

Latest major pass: real Apple/TestFlight credential + registration-path probe.

### Already green before Apple registration probe

- PR #8 hosted Supabase vertical slice — MERGED / iOS + DB green
- PR #9 Auth/RLS hardening — MERGED / iOS + DB green / two-household isolation green
- PR #10 authenticated hosted E2E smoke harness — MERGED / compile green
- PR #11 physical-device Release/TestFlight pipeline — MERGED
- Release generic `iphoneos` build — SUCCESS
- unsigned physical-device artifact — SUCCESS
- hosted Supabase callback allow-list — USER-CONFIRMED configured

### Apple/TestFlight credential + registration probe — 2026-08-19

The previous `ASC SECRETS NEXT` assumption is obsolete.

A secure bridge in `acciento89-bot/onemorefloor` reused that repository's existing working App Store Connect API credentials without exposing or copying secret values.

Bridge evidence:

- bridge workflow: `acciento89-bot/onemorefloor/.github/workflows/family-life-os-testflight-bridge.yml`
- draft probe PR: `acciento89-bot/onemorefloor#84`
- decisive run: `32247708814`
- job: `96051837747`
- Family Life OS package resolution — SUCCESS
- unsigned Release device build — SUCCESS
- ASC credential presence — SUCCESS
- API key preparation — SUCCESS
- Release archive creation — SUCCESS
- export/upload path — FAILED with raw `xcodebuild` exit status `70`
- exact decisive Xcode diagnostic: `No profiles for 'de.kamilunavo.familyprototype' were found`
- no successful TestFlight upload occurred

Apple App Store Connect API probe evidence:

- probe run: `32248236864`
- handoff issue: `acciento89-bot/onemorefloor#88`
- bundle identifier: `de.kamilunavo.familyprototype`
- Bundle ID matches: `1`
- Apple Bundle ID resource id: `2NV99ZM2PM`
- App Store Connect app records: `0`
- provisioning profiles: `0`

**Current verified blocker:** the explicit Bundle ID is already registered, but the App Store Connect app record does not exist yet. The public App Store Connect API cannot create a brand-new app record, so this one record must be created once in App Store Connect before the signed TestFlight path can continue.

## Auth redirect state

Callback:

`de.kamilunavo.familyprototype://login-callback`

The user confirmed on **2026-08-19** that this redirect URL has been added in hosted Supabase Auth URL Configuration.

Do not regress to “Auth redirect not configured”. Physical-device callback/session establishment remains unverified until the internal build is installed and Magic Link is exercised.

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

- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted data

Hosted Supabase:

- project ref `bqctetqraszsvknczjjr`
- Frankfurt / `eu-central-1`
- last observed `ACTIVE_HEALTHY`
- Supabase Swift pinned `2.54.1`
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
- one-button authenticated hosted E2E diagnostics harness

The diagnostics UI is intentionally allowed for the first **internal TestFlight/device smoke** and must be gated before external TestFlight/App Store distribution.

## Apple/TestFlight path

Known Apple team:

- Team ID `TKG684N5GL`

Canonical workflow:

`.github/workflows/family-life-os-testflight.yml`

Current Apple state:

- explicit Bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- Apple Bundle ID resource `2NV99ZM2PM`
- App Store Connect app record — MISSING
- provisioning profile — NONE
- working ASC credentials — VERIFIED through bridge
- Release archive — VERIFIED through bridge
- signed TestFlight upload — NOT YET SUCCESSFUL

One-time manual App Store Connect record values:

- Platform: iOS
- Name: `Family Life OS` as temporary internal name; public brand remains unlocked
- Primary Language: German
- Bundle ID: `de.kamilunavo.familyprototype`
- SKU: `KAMILUNAVO-FAMILY-001`
- User Access: Full Access unless intentionally restricted

After app-record creation, rerun TestFlight build `1`; use automatic/cloud signing and only react to a new exact Apple diagnostic if it still fails.

Do not claim a Family Life OS TestFlight upload succeeded until an actual signed workflow run reports success.

## #011 validation boundary

Validated:

- hosted migrations rolled out
- hosted Security Advisor clean at last check
- `SupabaseFamilyRepository` compiles
- fresh local Supabase/Postgres + pgTAP green
- two-identity RLS isolation green in local pgTAP
- direct hosted SQL isolation green
- PR #9 Xcode + DB gates green on same head
- PR #10 hosted smoke harness compile green
- Supabase callback allow-list user-confirmed configured
- PR #11 Release generic physical-device `iphoneos` build green
- PR #11 physical-device artifact packaging green
- TestFlight pipeline merged
- existing working ASC credentials proven against Family Life OS bridge
- Release archive proven through bridge
- Bundle ID existence proven via Apple API
- missing app record proven via Apple API
- zero provisioning profiles proven via Apple API

Not yet release-validated:

- App Store Connect app record creation
- automatic distribution provisioning after record creation
- signed Family Life OS TestFlight upload
- physical-device Magic Link callback/session
- one-button hosted smoke report from a real authenticated iPhone/iPad
- two real authenticated devices/sessions over Data API
- Realtime
- private Storage
- photo/PDF ingestion
- OCR
- real AI extraction
- physical-device/manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## #011 next steps

1. Create the iOS app record in App Store Connect for `de.kamilunavo.familyprototype` using the values above.
2. Rerun signed internal TestFlight build `1`; require actual upload success or fix the new exact Apple diagnostic.
3. Install the internal TestFlight build on a physical iPhone/iPad.
4. Execute Magic Link and verify authenticated return through the configured callback.
5. Open **Backend-Diagnose** -> **Hosted E2E jetzt prüfen** and require every step including cleanup to pass.
6. Repeat with a second real authenticated session for final Auth/Data-API isolation coverage.
7. Add Realtime only after physical-device hosted text smoke is green.
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
5. Continue #011 from **App Store Connect app record -> signed internal TestFlight -> physical-device Magic Link -> authenticated hosted E2E smoke**.
6. Do not regress to “ASC secrets missing” — working credentials were proven through the secure bridge on 2026-08-19.
7. Do not regress to “Bundle ID missing” — Apple API probe found resource `2NV99ZM2PM`.
8. Do not regress to “Auth redirect not configured” — user confirmed it configured on 2026-08-19.
9. Do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device hosted text smoke is proven.
10. Preserve every other portfolio entry when updating one workstream.
