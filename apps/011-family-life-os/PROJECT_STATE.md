# Family Life OS — Project State

Last updated: 2026-08-19
Status: TESTFLIGHT BUILD 2 UPLOADED / PHYSICAL BUILD 2 VALIDATION NEXT
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this file, not from stale chat summaries.

## Current verified checkpoint

The project is now beyond the first physical-device smoke and has a second signed internal build uploaded to Apple containing the physical-device feedback pass from PR #13.

User-provided physical iPhone screenshots on 2026-08-19 verify the first installed internal build:

- the internal Family Life OS TestFlight build is installed and launches on a real iPhone
- the hosted UI loads household state (`Ich`, owner/full access)
- Hosted Backend diagnostics are available in the installed build
- hosted configuration shown on-device is Frankfurt/EU with the publishable client key and callback `de.kamilunavo.familyprototype://login-callback`
- the user manually used Inbox -> text example import
- imported hosted data is visibly present in Inbox and Plan
- imported canonical Plan items include deadline/payment/preparation output and provenance (`Aus Import`)

New signed build checkpoint on 2026-08-19:

- Family Life OS `0.1.0 (2)` was built and uploaded through the protected internal App Store Connect bridge
- upload source was `acciento89-bot/appideenchatgpt` `main`, including merged PR #13
- bridge workflow run: `32285397950`
- Family Life upload job: `96173603213`
- Release `iphoneos` build: SUCCESS
- protected App Store Connect credential presence check: SUCCESS
- archive: SUCCESS
- Apple cloud-signing/export/upload: SUCCESS
- Apple/Xcode upload log: `UPLOAD SUCCEEDED with no errors.`
- upload step exit status: `0`
- exported metadata: `CFBundleIdentifier=de.kamilunavo.familyprototype`, marketing version `0.1.0`, build `2`
- App Store Connect secret values were never printed or committed
- temporary One More Floor bridge jobs/workflows were removed after the successful upload; trigger PR #98 was closed without merge

Evidence boundary:

- Build 2 upload acceptance by Apple is VERIFIED
- Apple post-upload processing / Build 2 visibility in TestFlight is not yet explicitly observed
- Build 2 installation on the physical iPhone is not yet verified
- physical TestFlight installation of the earlier build remains VERIFIED
- a working hosted session/data path on the device is strongly evidenced by loaded hosted household/import data
- a fresh Magic Link callback round-trip has NOT yet been explicitly re-verified in this checkpoint
- the one-button **Hosted E2E jetzt prüfen** result has NOT yet been shown/verified
- a second real authenticated user/session has NOT yet been verified

## Latest UX/functionality pass — PR #13

PR #13: `Family Life OS: completion and live Today`

- tested head: `498f5a7a036a038454bbd387100bb32faf4b31e9`
- merged to `main`
- squash commit: `ce7d5c0b09a1cd5f4944b2b88d7c14d205affa71`
- changed files: `PlanView.swift`, `TodayView.swift`
- Family Life OS Prototype Build run `32278953444` / #26 — SUCCESS
- Family Life OS TestFlight PR validation run `32278953395` / #7 — SUCCESS
- PR validation correctly skipped signed upload
- PR #13 is included in uploaded TestFlight Build 2 (`0.1.0 (2)`)

Implemented from physical-device feedback:

- deadlines can be marked completed
- payments can be marked completed
- tasks can be marked completed
- preparation items can be marked completed
- completion is available from Plan
- completion is available directly inside Today -> `Braucht Aufmerksamkeit`
- completion is available in `Für morgen vorbereiten`
- existing repository completion path is used, so hosted completion persists through Supabase rather than being UI-only
- optimistic UI rollback remains in `DemoStore.toggleCompletion` if the repository update fails

Physical screenshot cleanup discovered and fixed in PR #13:

- removed hard-coded `Dienstag, 18. August` production behavior
- Today now uses the device/current reference date
- greeting is derived from the current time
- Today filtering uses the actual current day
- tomorrow preparation uses the actual next day
- removed hard-coded Lina/Ben family summary leakage from hosted builds
- family overview is derived from current plan/attention/conflict data
- Today `+` / `Etwas hinzufügen` now opens a pending review, or starts the current internal deterministic text-test import when no review is waiting
- previews keep an injected fixture date so regression previews stay deterministic

Important: PR #13 has now reached Apple in Build 2, but its behavior still requires physical verification after Build 2 becomes available/installed through TestFlight.

## Apple/TestFlight checkpoint

Known Apple team:

- Team ID `TKG684N5GL`

Bundle:

- `de.kamilunavo.familyprototype`
- Apple Bundle ID resource previously verified as `2NV99ZM2PM`

Current signed build:

- `0.1.0 (2)`
- Apple upload completed successfully on 2026-08-19
- bridge run `32285397950`
- upload job `96173603213`
- exact upload result: `UPLOAD SUCCEEDED with no errors.` / exit `0`
- post-upload Apple processing and physical installation still need observation

Obsolete blockers — do not regress to these:

- “ASC secrets missing”
- “Bundle ID missing”
- “App Store Connect app record missing”
- “signed TestFlight upload not successful”
- “physical TestFlight install not proven”
- “PR #13 still needs a signed upload”

## Core product thesis

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

This is a Family Inbox/workflow engine, not a generic shared-calendar clone.

`Import prüfen` is the locked trust boundary:

- source remains reachable
- extraction creates editable proposals only
- proposals can independently be included/edited
- unresolved required information blocks confirmation
- explicit user confirmation creates canonical family data
- confirmed items retain source + proposal provenance
- OCR/AI may never bypass review-before-confirmation

## Locked architecture

- Native SwiftUI
- iPhone first with intentional iPad adaptation
- iOS/iPadOS 18+
- DACH-first behavior
- Supabase backend
- hosted region Frankfurt / `eu-central-1`
- Postgres + RLS are primary household isolation boundary
- publishable client key only in app
- no service-role/provider secret in iOS
- AI processing server-side only
- `SwiftUI View -> DemoStore -> FamilyRepository -> data source`
- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted production-direction data
- Realtime only after authenticated physical-device text path is fully proven
- private Storage/photo/PDF after that
- OCR after Storage/share intake
- real AI extraction last

## Executable iOS prototype

Project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Scheme:

`FamilyLifePrototype`

Provisional bundle ID:

`de.kamilunavo.familyprototype`

Current internal marketing version path:

`0.1.0`

Latest uploaded internal build:

`0.1.0 (2)`

Implemented UI/UX:

- Heute / Inbox / Plan / Familie
- compact iPhone tabs
- adaptive iPad `NavigationSplitView`
- two-column regular-width Import Review
- Dynamic Type/accessibility reflow
- VoiceOver labels/hints + accessibility identifiers
- semantic Light/Dark surfaces
- Today attention/conflict/quiet states
- overlap detection
- Inbox queued/processing/review/partial/done/failed states
- editable review flow
- child profile creation
- source/proposal provenance
- persisted completion for actionable Plan items
- hosted backend diagnostic sheet with one-button authenticated E2E smoke

Diagnostics are intentionally allowed in the first **internal TestFlight** cycle and must be gated before external TestFlight/App Store distribution.

## Hosted Supabase

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Last recorded project state:

`ACTIVE_HEALTHY`

Supabase Swift:

`2.54.1` pinned

Hosted migrations:

- `20260819040837` — family core
- `20260819041003` — member uniqueness + confirmation retry
- `20260819041013` — private helper permissions
- `20260819041031` — tightened client write surface
- `20260819041232` — hosted advisor hardening
- `20260819041753` — hosted text vertical slice

Hosted client capabilities:

- Magic Link auth/session gate
- custom URL scheme
- exact callback validation
- household bootstrap
- hosted member/Inbox/proposal/assignee/Plan reads through Postgres/RLS
- deterministic hosted fixture text import
- proposal edits + assignee persistence
- canonical confirmation RPC
- remote/persisted completion
- remote child profile creation
- authenticated hosted E2E diagnostics

## Auth redirect state

Required callback:

`de.kamilunavo.familyprototype://login-callback`

Hosted Supabase allow-list configuration is **USER-CONFIRMED DONE on 2026-08-19**.

Do not regress to “Auth redirect not configured”. A fresh physical-device Magic Link callback/session round-trip still needs explicit confirmation even though an active hosted device data path is now evidenced.

## Database / security contract

Core tables:

- `households`
- `household_members`
- `source_items`
- `extraction_runs`
- `action_proposals`
- `action_proposal_assignees`
- `plan_items`
- `plan_item_assignees`
- `reminders`

Canonical RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Security baseline:

- RLS on collaborative client-exposed tables
- authenticated-user uniqueness only when `user_id` non-null
- multiple child/guest profiles allowed without login
- private helper functions restricted with empty `search_path`
- client write surface limited to product-editable fields
- server/RPC owns processing/review/provenance fields where required
- same-household provenance enforced
- two-user isolation is a mandatory regression gate

## Validation boundary

### Green / verified

- SwiftUI client builds in Simulator CI
- generic Release physical-device `iphoneos` build green
- hosted `SupabaseFamilyRepository` compiles
- Supabase dependency resolution works
- fresh migrations green
- pgTAP RLS/RPC green
- hosted migrations deployed
- hosted Security Advisor clean at last check
- direct hosted two-identity SQL isolation green
- Supabase callback allow-list user-confirmed configured
- App Store Connect app record exists
- earlier signed build reached App Store Connect/TestFlight
- physical iPhone TestFlight installation proven by user screenshots
- hosted household state visible on physical device
- manual deterministic hosted text import visibly reaches Inbox/Plan on physical device
- PR #13 Simulator CI green
- PR #13 Release/device PR validation green
- Build 2 Release `iphoneos` build green
- Build 2 signed App Store Connect upload accepted by Apple with exit `0`
- Build 2 contains PR #13 completion/live-Today fixes

### Not yet release-validated

- Apple processing / TestFlight visibility of Build 2 after upload
- Build 2 installed and exercised on physical device
- PR #13 completion/live-Today behavior on physical device
- completion persistence across navigation/app relaunch/remote refresh on Build 2
- fresh physical-device Magic Link callback/session round-trip
- in-app `Hosted E2E jetzt prüfen` all-green result from real device
- second real authenticated user/session Data API isolation
- Realtime
- private Storage
- photo/PDF share intake
- OCR
- real AI extraction/provider
- physical-device manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## Immediate next steps

1. Wait only for Apple to finish processing Build 2, then install/update to `0.1.0 (2)` through TestFlight.
2. Verify Today shows the real current date/time-derived greeting and no stale Lina/Ben fixture data.
3. Mark imported deadline/payment/task/preparation items completed from Plan and Today and verify completion persists after navigation, app relaunch and hosted refresh.
4. Run **Backend-Diagnose -> Hosted E2E jetzt prüfen** on the physical device and require every step including cleanup to pass.
5. Explicitly test a fresh Magic Link sign-in and verify `de.kamilunavo.familyprototype://login-callback` returns to the app with a valid session.
6. Repeat authenticated Data API coverage with a second real user/session.
7. Once the above device gates are green, add Realtime.
8. Add private Storage + photo/PDF share intake.
9. Add OCR after Storage/share intake is stable.
10. Add real AI extraction last while preserving editable proposals + explicit confirmation.
11. Gate diagnostics before external distribution and complete physical-device + VoiceOver QA.

## Brand guardrail

`Family Life OS` is internal only.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Avoid generic house/checkmark, cartoon family and robot/AI-sparkle identity.

Final public name still requires current App Store/web + EUIPO/DPMA/domain clearance.

## Deferred / rejected for MVP

- generic calendar/shopping/chores clone
- family chat/social-network replacement
- live GPS
- video/audio calls
- bank/full budgeting
- meal/recipe platform
- complex chore economy
- automatic mailbox surveillance
- autonomous bookings/calls
- medical-advice assistant
- generic AI-chat-first UI
- decorative Liquid Glass everywhere

## Canonical docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/BACKEND_CONTRACT.md`
- `apps/011-family-life-os/PROJECT_STATE.md`
- `apps/011-family-life-os/prototype/README.md`

## Handoff rule

For every continuation/new chat:

1. read `docs/APP_FACTORY_STATE.md`
2. read this file
3. inspect current `main`
4. inspect latest Family Life OS Simulator/Device/TestFlight CI state
5. continue from **Build 2 physical install -> completion/live-Today persistence -> Hosted E2E -> fresh Magic Link -> second real session**
6. do not regress to “physical TestFlight not installed” — an earlier internal build is proven installed by real-device screenshots on 2026-08-19
7. do not regress to “PR #13 still needs TestFlight upload” — Build 2 upload succeeded in run `32285397950`
8. do not regress to “hosted path not working at all” — manual hosted text import visibly reached Inbox/Plan on-device
9. do not claim Build 2 is installed/processed until observed through TestFlight/on-device
10. do not claim the one-button hosted E2E passed until its result is actually shown
11. do not claim a fresh Magic Link callback test passed until explicitly exercised
12. do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device gates above are green
