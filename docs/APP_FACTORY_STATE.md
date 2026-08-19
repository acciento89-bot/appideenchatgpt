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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | HOSTED E2E HARNESS GREEN / DEVICE AUTH ALLOWLIST NEXT |

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

Latest major pass: hosted authenticated E2E smoke harness.

### PR #8 — hosted Supabase vertical slice

- MERGED
- tested head `13297c5fd40705509dce298d741229ccd26b76bb`
- merge `747d5bed505ef527501d24b9a24144ffb04a24f1`
- iOS run `32221107674` / #17 — SUCCESS
- DB run `32221107641` / #8 — SUCCESS

### PR #9 — Auth/RLS hardening

- MERGED
- tested head `a884bf8f36dfdc560c5aa4e5fde2d98cefb33ee9`
- merge `649f2104353154e199b3844ec79ca6e8d23a60ad`
- iOS run `32222381445` / #19 — SUCCESS
- DB run `32222381440` / #10 — SUCCESS
- exact callback validation
- 14-assertion two-household pgTAP test
- direct hosted Frankfurt isolation smoke green
- temporary test data fully removed
- hosted Security Advisor clean at last check

### PR #10 — hosted E2E smoke harness

- MERGED
- tested head `eb4b14998d630ec9c1951548fcaac71671ff625b`
- merge `a56f0776ea701a50b549e4167415d4b0056afde1`
- Xcode/iOS Simulator run `32225259430` / #21 — SUCCESS
- no DB workflow triggered because PR #10 changed no database schema/policies/functions

The in-app diagnostics harness now tests through the normal authenticated RLS client path:

- Auth session
- household load
- child resolution
- hosted canonical school-letter import
- exactly 4 proposals
- review readiness
- canonical confirmation
- exactly 4 PlanItems
- source + proposal provenance
- source `done`
- confirm retry/idempotency
- cleanup of temporary data

The harness itself is compiled/merged but has **not yet been run through a real physical-device authenticated Magic Link session**.

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
- one-button hosted E2E diagnostics harness

Before TestFlight, the diagnostics UI must be removed or gated to DEBUG/internal builds.

## External Auth gate

Exact callback:

`de.kamilunavo.familyprototype://login-callback`

Must be present in:

**Supabase Dashboard -> Auth -> URL Configuration -> Additional Redirect URLs**

The connected Supabase tool surface cannot mutate that setting and the repository contains no existing `SUPABASE_ACCESS_TOKEN` management workflow. Do not invent or expose credentials to automate it.

## #011 validation boundary

Validated:

- hosted migrations rolled out
- hosted Security Advisor clean at last check
- `SupabaseFamilyRepository` compiles
- fresh local Supabase/Postgres + pgTAP green
- two-identity RLS isolation green in local pgTAP
- direct hosted SQL isolation green
- PR #9 Xcode + DB gates green on same head
- PR #10 hosted smoke harness Xcode run #21 green
- PR #10 merged

Not yet release-validated:

- callback presence in hosted Auth allow-list
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
- TestFlight readiness

## #011 next steps

1. Add/confirm `de.kamilunavo.familyprototype://login-callback` in hosted Supabase Auth Additional Redirect URLs.
2. Run the app on a physical iPhone/iPad.
3. Execute Magic Link login and verify authenticated return to app.
4. Open the stethoscope **Backend-Diagnose** control.
5. Run **Hosted E2E jetzt prüfen** and require every step including cleanup to pass.
6. Repeat with a second real authenticated session for the final Auth/Data-API isolation surface if needed.
7. Add Realtime only after the device smoke is green.
8. Add private Storage + photo/PDF share intake.
9. Add OCR.
10. Add real AI extraction last while retaining explicit proposal review/confirmation.
11. Remove/gate diagnostics and perform physical-device + VoiceOver QA before TestFlight.

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
5. Continue #011 from hosted Auth allow-list + real physical-device E2E smoke.
6. Do not jump to Realtime/Storage/OCR/AI before the authenticated hosted text smoke is proven on device.
7. Preserve every other portfolio entry when updating one workstream.
