# Family Life OS — Project State

Last updated: 2026-08-19
Status: BUILD 2 DEVICE + HOSTED E2E GREEN / FRESH MAGIC LINK + SECOND SESSION NEXT
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this file, not from stale chat summaries. Older exhaustive checkpoints remain in Git history.

## Current verified checkpoint

Family Life OS `0.1.0 (2)` is now physically validated on a real iPhone.

User confirmation on 2026-08-19 after installing the updated TestFlight build verifies the full Build-2 checklist from the preceding device-validation pass:

- Build 2 is processed by Apple, visible through TestFlight, installed and launches on the physical iPhone
- PR #13 completion controls work for deadlines, payments, tasks and preparation items
- completion works from Plan and from Today
- completed state survives app restart, proving the hosted persistence path is not UI-only
- Today uses the real current date/time-derived greeting instead of the old hard-coded 18 August fixture
- stale Lina/Ben fixture leakage is gone from the hosted device UI
- **Backend-Diagnose -> Hosted E2E jetzt prüfen** completes successfully on the real device, including cleanup

This closes the updated PR #13 physical-device gate and the one-button hosted E2E gate.

Evidence boundary still open:

- a fresh physical-device Magic Link callback/session round-trip has NOT yet been explicitly re-verified in this checkpoint
- a second real authenticated user/session has NOT yet been verified through the Data API
- Realtime, private Storage, photo/PDF intake, OCR and real AI extraction remain intentionally deferred until the auth/session gates are green

## Apple / TestFlight checkpoint

Current internal build:

- marketing version `0.1.0`
- build `2`
- bundle id `de.kamilunavo.familyprototype`
- Apple team `TKG684N5GL`

Signed upload checkpoint:

- protected bridge run `32285397950`
- Family Life upload job `96173603213`
- Release `iphoneos` build: SUCCESS
- archive: SUCCESS
- Apple cloud-signing/export/upload: SUCCESS
- exact upload result: `UPLOAD SUCCEEDED with no errors.`
- upload exit status: `0`
- App Store Connect secret values were never printed or committed
- temporary One More Floor bridge changes were removed after upload; PR #98 was closed without merge

Build 2 is now also physically installed and exercised successfully.

Obsolete blockers — do not regress to these:

- ASC secrets missing
- Bundle ID missing
- App Store Connect app record missing
- signed upload not successful
- Build 2 not processed/visible
- Build 2 not installed
- PR #13 still needs physical validation
- one-button Hosted E2E still untested

## Latest UX/functionality pass — PR #13

PR #13: `Family Life OS: completion and live Today`

- tested head `498f5a7a036a038454bbd387100bb32faf4b31e9`
- merged to `main`
- squash commit `ce7d5c0b09a1cd5f4944b2b88d7c14d205affa71`
- Family Life OS Prototype Build run `32278953444` / #26 — SUCCESS
- Family Life OS TestFlight PR validation run `32278953395` / #7 — SUCCESS
- included in signed TestFlight Build 2 `0.1.0 (2)`
- physical-device behavior — USER-CONFIRMED GREEN on 2026-08-19

Implemented and now physically verified:

- deadlines can be marked completed
- payments can be marked completed
- tasks can be marked completed
- preparation items can be marked completed
- completion from Plan
- completion from Today -> `Braucht Aufmerksamkeit`
- completion from `Für morgen vorbereiten`
- hosted repository completion persistence survives app restart
- Today uses the actual current date
- greeting derives from current time
- Today/tomorrow filtering is real-date based
- hard-coded Lina/Ben hosted fixture leakage removed
- family overview derives from current hosted plan/attention/conflict state
- Today `+` opens a pending review or starts the current internal deterministic text-test import when no review is waiting

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

Bundle ID:

`de.kamilunavo.familyprototype`

Current internal build:

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

Diagnostics remain intentionally available for the internal TestFlight cycle and must be gated before external TestFlight/App Store distribution.

## Hosted Supabase

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Supabase Swift:

`2.54.1` pinned

Hosted migrations:

- `20260819040837` — family core
- `20260819041003` — member uniqueness + confirmation retry
- `20260819041013` — private helper permissions
- `20260819041031` — tightened client write surface
- `20260819041232` — hosted advisor hardening
- `20260819041753` — hosted text vertical slice

Hosted client capabilities now physically exercised through the internal build include:

- active hosted household/session data path
- household bootstrap/read path
- hosted member/Inbox/proposal/assignee/Plan reads through Postgres/RLS
- deterministic hosted fixture text import
- reviewed proposal confirmation to canonical Plan items
- remote/persisted completion
- source/proposal provenance
- authenticated hosted E2E diagnostics including cleanup

Additional implemented capabilities awaiting their explicit next gate:

- Magic Link auth/session gate
- custom URL scheme
- exact callback validation
- remote child profile creation

## Auth redirect state

Required callback:

`de.kamilunavo.familyprototype://login-callback`

Hosted Supabase allow-list configuration is **USER-CONFIRMED DONE on 2026-08-19**.

Do not regress to “Auth redirect not configured”. The remaining auth gate is a deliberate **fresh** physical-device Magic Link round-trip, not configuration work.

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
- Supabase callback allow-list configured
- App Store Connect app record exists
- Build 2 signed upload accepted by Apple
- Build 2 processed/visible in TestFlight
- Build 2 installed and launched on physical iPhone
- hosted household/manual text-import path works on physical device
- PR #13 completion/live-Today behavior works on physical device
- completion persists after app restart
- current date/time Today behavior physically verified
- stale Lina/Ben fixture leakage absent on Build 2
- in-app **Hosted E2E jetzt prüfen** all-green on real device, including cleanup

### Not yet release-validated

- fresh physical-device Magic Link callback/session round-trip
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

1. Explicitly test a fresh Magic Link sign-in and verify `de.kamilunavo.familyprototype://login-callback` returns to the app with a valid hosted session.
2. Repeat authenticated Data API coverage with a second real user/session and verify household isolation from the client path.
3. Once both auth/session gates are green, add Realtime.
4. Add private Storage + photo/PDF share intake.
5. Add OCR after Storage/share intake is stable.
6. Add real AI extraction last while preserving editable proposals + explicit confirmation.
7. Gate diagnostics before external distribution and complete physical-device + VoiceOver QA.
8. Add StoreKit/subscription only after the core Family Inbox workflow is stable enough for release hardening.

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
5. continue from **fresh Magic Link -> second real session -> Realtime -> private Storage/photo/PDF intake**
6. do not regress to “Build 2 not installed” — user confirmed Build 2 works on-device on 2026-08-19
7. do not regress to “PR #13 still needs physical validation” — its device checklist is green
8. do not regress to “Hosted E2E not tested” — the user confirmed the Build-2 Backend-Diagnose E2E checklist works perfectly
9. do not claim fresh Magic Link or second-session isolation passed until explicitly exercised
10. do not jump to Realtime/Storage/OCR/AI before the two remaining authenticated physical-device gates are green
