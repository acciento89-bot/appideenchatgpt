# Family Life OS — Project State

Last updated: 2026-08-19
Status: TESTFLIGHT BUILD VISIBLE IN APP STORE CONNECT / PHYSICAL DEVICE SMOKE NEXT
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this file, not from stale chat summaries. Older exhaustive checkpoints remain in Git history.

## Current verified checkpoint

The Apple registration/upload blocker is cleared.

User-confirmed on 2026-08-19:

- the App Store Connect app record exists
- a Family Life OS build is visible in App Store Connect / TestFlight
- therefore a signed Apple upload has successfully reached App Store Connect

Important evidence distinction:

- earlier PR validation runs can be green while their upload step is intentionally skipped
- the build being visible in App Store Connect is the decisive evidence that an actual upload succeeded
- the exact successful upload workflow/run ID has not yet been matched back to the visible App Store Connect build in this checkpoint

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
- exact callback validation added
- 14-assertion two-household pgTAP isolation test added
- direct hosted Frankfurt isolation smoke green
- hosted Security Advisor clean at last check

### PR #10 — authenticated hosted E2E smoke harness

- MERGED
- tested head `eb4b14998d630ec9c1951548fcaac71671ff625b`
- merge `a56f0776ea701a50b549e4167415d4b0056afde1`
- iOS run `32225259430` / #21 — SUCCESS
- in-app diagnostics use the authenticated Supabase session and normal RLS client rights
- harness covers Auth -> household -> child -> hosted school-letter import -> 4 proposals -> confirm -> 4 PlanItems -> provenance -> source done -> idempotent retry -> cleanup

### PR #11 — Release device + TestFlight pipeline

- MERGED
- tested head `546722579458b5caef23641b181810de10ce9eee`
- merge `727f2cdceae6cd0f527a766879a8d0517fbdb742`
- workflow `.github/workflows/family-life-os-testflight.yml`
- PR run `32228406465` / #2 — SUCCESS
- pinned Supabase package resolution — SUCCESS
- Release generic `iphoneos` build — SUCCESS
- unsigned device artifact — SUCCESS

### PR #12 — App Store bundle validation fixes

- MERGED into `main`
- tested head `38b3f5ecbaa1d696bca0b6395e7a9a096b9a13cd`
- merge/squash commit `f767221...`
- prototype validation — GREEN
- TestFlight PR validation — GREEN
- PR upload step itself was intentionally skipped because PR runs are validation-only
- after the Apple/App Store configuration fixes, user confirms an actual build is now visible in App Store Connect

## Product thesis

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

This is a Family Inbox/workflow engine, not a generic shared-calendar clone.

`Import prüfen` is the locked trust boundary:

- source remains reachable
- extraction creates editable proposals only
- proposals can be independently included/edited
- unresolved required information blocks confirmation
- explicit confirmation creates canonical family data
- confirmed items retain source + proposal provenance
- OCR/AI may never bypass review-before-confirmation

## Locked architecture

- Native SwiftUI
- iPhone first with intentional iPad adaptation
- iOS/iPadOS 18+
- DACH-first behavior
- Supabase backend
- hosted development region Frankfurt / `eu-central-1`
- Postgres + RLS are primary household isolation boundary
- publishable client key only in app
- no service-role/provider secret in iOS
- AI processing server-side only
- `SwiftUI View -> DemoStore -> FamilyRepository -> data source`
- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted data
- Realtime only after authenticated physical-device text path is proven
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

Internal version path:

`0.1.0 (1)`

Implemented UI/UX includes:

- Heute / Inbox / Plan / Familie
- compact iPhone tabs
- adaptive iPad `NavigationSplitView`
- two-column regular-width Import Review
- Dynamic Type/accessibility reflow
- VoiceOver labels/hints + accessibility identifiers
- semantic Light/Dark surfaces
- busy/calm/conflict Today states
- overlap detection
- Inbox queued/processing/review/partial/done/failed states
- editable review flow
- child profile creation
- source/proposal provenance
- hosted backend diagnostic sheet with one-button authenticated E2E smoke

Diagnostics are intentionally allowed in the first **internal TestFlight** build. They must be gated before external TestFlight/App Store distribution.

## Hosted Supabase

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Last observed:

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
- remote task completion
- remote child profile creation
- authenticated hosted E2E diagnostics

## Auth redirect state

Required callback:

`de.kamilunavo.familyprototype://login-callback`

**Hosted Supabase allow-list configuration is USER-CONFIRMED DONE on 2026-08-19.**

Do not regress to “Auth redirect not configured”. Physical-device Magic Link/session establishment remains unverified until exercised from the TestFlight build.

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
- authenticated-user uniqueness only when `user_id` is non-null
- multiple child/guest profiles allowed without login
- restricted private helper functions with empty `search_path`
- client write surface limited to product-editable fields
- server/RPC owns processing/review/provenance fields where required
- same-household provenance enforced
- two-user isolation is a mandatory regression gate

## Apple / TestFlight state

Known Apple team:

- Team ID `TKG684N5GL`

Bundle:

- `de.kamilunavo.familyprototype`
- Apple Bundle ID resource previously verified as `2NV99ZM2PM`

Current verified state:

- explicit Bundle ID — REGISTERED
- App Store Connect app record — EXISTS, user-confirmed
- Release physical-device build — GREEN
- signed Family Life OS build visible in App Store Connect / TestFlight — YES, user-confirmed 2026-08-19
- physical-device install/session smoke — NEXT

The earlier states “ASC secrets missing”, “App Store Connect app record missing”, “provisioning profile blocker”, and “signed upload not yet successful” are obsolete.

## Validation boundary

### Green / verified

- SwiftUI client builds in Simulator CI
- hosted `SupabaseFamilyRepository` compiles
- Supabase dependency resolution works
- fresh migrations green
- pgTAP RLS/RPC green
- hosted migrations deployed
- hosted Security Advisor clean at last check
- direct hosted two-identity SQL isolation green
- Supabase callback allow-list user-confirmed configured
- Release generic physical-device `iphoneos` build green
- unsigned device artifact green
- App Store Connect API credentials previously proven through secure bridge
- Bundle ID exists
- App Store Connect app record now exists
- signed build reached App Store Connect / TestFlight

### Not yet release-validated

- physical-device install of the current TestFlight build
- physical-device Magic Link callback/session establishment
- in-app hosted E2E smoke from a real authenticated iPhone/iPad
- second real authenticated device/session Data API isolation
- Realtime
- private Storage
- photo/PDF share intake
- OCR
- real AI extraction/provider
- physical-device UI + manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## Immediate next steps

1. Install the current internal TestFlight build on a physical iPhone or iPad.
2. Request a Magic Link and verify `de.kamilunavo.familyprototype://login-callback` returns to the app with an authenticated session.
3. Open **Backend-Diagnose** and run **Hosted E2E jetzt prüfen**.
4. Require every smoke step, including cleanup, to pass.
5. Repeat the authenticated Data API path with a second real user/session for final isolation coverage.
6. Only then add Realtime.
7. Add private Storage + photo/PDF share intake.
8. Add OCR after Storage/share intake is stable.
9. Add real AI extraction last while preserving editable proposals + explicit confirmation.
10. Gate diagnostics before external distribution and perform physical-device + VoiceOver QA.

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
4. inspect latest Family Life OS Simulator/DB/Device/TestFlight CI state
5. continue from **physical-device TestFlight install -> Magic Link -> in-app hosted E2E smoke**
6. do not regress to “ASC secrets missing”
7. do not regress to “Bundle ID missing”
8. do not regress to “App Store Connect app record missing”
9. do not regress to “signed TestFlight upload not successful” — user confirmed a build visible in App Store Connect on 2026-08-19
10. do not regress to “Auth redirect not configured”
11. do not regress to “two-user RLS untested” — database/hosted-SQL isolation is green
12. do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device hosted text smoke is proven
