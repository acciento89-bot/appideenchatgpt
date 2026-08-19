# Family Life OS — Project State

Last updated: 2026-08-19
Status: HOSTED E2E HARNESS GREEN / DEVICE AUTH ALLOWLIST NEXT
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/` in the central App Factory repository

> This file is the app-specific single source of truth. Older exhaustive checkpoints remain in Git history. Continue from this file, not from stale chat summaries.

## Current verified checkpoint

Latest major pass: authenticated hosted E2E smoke-test harness.

### PR #8 — hosted Supabase vertical slice

- MERGED
- tested head: `13297c5fd40705509dce298d741229ccd26b76bb`
- merge: `747d5bed505ef527501d24b9a24144ffb04a24f1`
- iOS run `32221107674` / #17 — SUCCESS
- DB run `32221107641` / #8 — SUCCESS

### PR #9 — Auth/RLS hardening

- MERGED
- tested head: `a884bf8f36dfdc560c5aa4e5fde2d98cefb33ee9`
- merge: `649f2104353154e199b3844ec79ca6e8d23a60ad`
- iOS run `32222381445` / #19 — SUCCESS
- DB run `32222381440` / #10 — SUCCESS
- exact callback validation added
- 14-assertion two-household pgTAP isolation test added
- direct hosted Frankfurt test proved cross-household reads invisible and foreign UPDATE affects zero rows
- temporary hosted test users/households were fully removed
- hosted Security Advisor returned no lints

### PR #10 — hosted authenticated E2E smoke harness

- MERGED
- tested head: `eb4b14998d630ec9c1951548fcaac71671ff625b`
- merge: `a56f0776ea701a50b549e4167415d4b0056afde1`
- iOS Simulator workflow: `Family Life OS Prototype Build`
- iOS run `32225259430` / #21 — SUCCESS
- DB workflow intentionally did not trigger: PR #10 changed no migration, table, policy, function or database contract

PR #10 adds an in-app hosted backend diagnostics/smoke harness that uses only the current authenticated Supabase session and normal RLS client rights. No service-role or management credential is used.

The harness validates:

1. active Auth session
2. hosted household load/bootstrap state
3. existing child reuse or temporary child creation
4. canonical German school-letter import through hosted `ingest_text_fixture`
5. exactly four proposals
6. explicit resolution of the required child assignment
7. production `SupabaseFamilyRepository` confirmation path
8. exactly four canonical PlanItems
9. source + proposal provenance on every created item
10. Inbox source reaches `done`
11. direct canonical confirm retry
12. idempotency remains exactly four PlanItems
13. cleanup of temporary PlanItems/source
14. cleanup of temporary child when one was created
15. cleanup attempt also runs after a test failure

The actual physical-device smoke run is **not yet validated** because real Magic Link callback completion still depends on the hosted Auth redirect allow-list.

## Product thesis

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

The product is a Family Inbox and workflow engine, not a generic shared-calendar clone.

`Import prüfen` is the locked trust boundary:

- source remains reachable
- extraction creates editable proposals only
- proposals are independently includable/editable
- unresolved required information blocks confirmation
- explicit user confirmation creates canonical family data
- confirmed items retain source + proposal provenance
- future OCR/AI may not bypass review-before-confirmation

## Locked architecture

- Native SwiftUI
- iPhone first, intentional iPad adaptation
- iOS/iPadOS 18+
- DACH-first behavior
- Supabase backend
- hosted development region Frankfurt / `eu-central-1`
- Postgres + RLS are primary household isolation
- publishable client key only in app
- no service-role/provider secret in iOS
- private Storage later for family documents
- AI processing server-side only
- `SwiftUI View -> DemoStore -> FamilyRepository -> data source`
- `InMemoryFamilyRepository` retained for previews/regression fixtures
- `SupabaseFamilyRepository` is hosted production-direction data source
- Realtime only after hosted authenticated text path is proven
- Storage/photo/PDF after that, then OCR, then real AI

## Executable iOS prototype

Project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Implemented UI/UX:

- Heute / Inbox / Plan / Familie
- compact iPhone tabs
- adaptive iPad `NavigationSplitView`
- two-column regular-width Import Review
- Dynamic Type / accessibility-size reflow
- VoiceOver labels/hints + accessibility identifiers
- Light/Dark semantic surfaces
- busy/calm/conflict Today states
- overlap detection
- Inbox queued/processing/review/partial/done/failed states
- editable review flow
- child profile creation
- source/proposal provenance
- hosted backend diagnostic sheet with one-button E2E smoke run

Before TestFlight, the diagnostics UI must be removed or gated to DEBUG/internal builds.

## Hosted Supabase

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Last observed project state:

`ACTIVE_HEALTHY`

Supabase Swift:

`2.54.1` pinned

Hosted migrations present:

- `20260819040837` — family core
- `20260819041003` — member uniqueness + confirmation retry
- `20260819041013` — private helper permissions
- `20260819041031` — tightened client write surface
- `20260819041232` — hosted advisor hardening
- `20260819041753` — hosted text vertical slice

Hosted capabilities implemented:

- Magic Link auth/session gate
- custom URL scheme in Info.plist
- exact expected callback validation before session exchange
- household bootstrap
- member/Inbox/proposal/assignee/Plan reads through hosted Postgres/RLS
- deterministic server fixture text import
- proposal edits + assignee persistence
- canonical confirmation RPC
- remote task completion
- remote child profile creation
- in-app hosted E2E smoke diagnostics

## External Auth gate — STILL OPEN

Exact callback:

`de.kamilunavo.familyprototype://login-callback`

It must be present in:

**Supabase Dashboard -> Auth -> URL Configuration -> Additional Redirect URLs**

The currently connected Supabase tool surface can inspect/query the project but does not expose mutation of this hosted Auth setting. Repository search also found no existing `SUPABASE_ACCESS_TOKEN` management-token workflow. Do not add a speculative workflow that could overwrite Auth configuration.

Until this callback is present and successfully exercised on a physical device, do **not** claim real-device Magic Link or the in-app hosted smoke test has passed.

## Database / security contract

Core tables:

- households
- household_members
- source_items
- extraction_runs
- action_proposals
- action_proposal_assignees
- plan_items
- plan_item_assignees
- reminders

Security/integrity baseline:

- RLS on client-exposed collaborative tables
- multiple child/guest profiles without login allowed
- authenticated user uniqueness only when `user_id` is non-null
- restricted private helper functions with empty `search_path`
- client write surface limited to product-editable fields
- processing/review/provenance remains server/RPC-owned where required
- canonical provenance constrained to same household
- two-user isolation is a mandatory regression gate

Canonical RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

It owns authorization, source/proposal validation, unresolved rejection, canonical PlanItem create/reuse, same-household assignees, proposal finalization, source status transition and idempotent retry.

## Validation boundary

### Green / verified

- SwiftUI client builds in Xcode/iOS Simulator CI
- hosted `SupabaseFamilyRepository` compiles
- Supabase dependency resolution works
- fresh local migration path is green
- pgTAP RLS/RPC coverage green
- hosted migrations deployed
- hosted Security Advisor clean at last check
- direct hosted two-identity SQL isolation test green
- PR #9 Xcode + DB gates green on the same head
- PR #10 smoke harness Xcode run #21 green on `eb4b14998d630ec9c1951548fcaac71671ff625b`
- PR #10 merged to `a56f0776ea701a50b549e4167415d4b0056afde1`

### Not yet release-validated

- hosted Auth allow-list callback presence
- physical-device Magic Link callback/session establishment
- in-app hosted E2E smoke report on a real authenticated iPhone/iPad
- two real authenticated devices/sessions over Data API
- Realtime
- private Storage
- photo/PDF share intake
- OCR
- real AI extraction/provider
- physical-device UI + VoiceOver QA
- StoreKit/subscription
- TestFlight/App Store readiness

## Immediate next steps

1. Add/confirm `de.kamilunavo.familyprototype://login-callback` in Supabase Auth -> URL Configuration -> Additional Redirect URLs.
2. Run the app on a physical iPhone/iPad.
3. Request Magic Link and verify the link returns into the app with an authenticated session.
4. Open the stethoscope **Backend-Diagnose** control.
5. Tap **Hosted E2E jetzt prüfen**.
6. Require every smoke step including cleanup to pass.
7. Repeat with a second real authenticated Supabase user/session if needed for the final Data-API Auth-surface isolation check.
8. Add Realtime only after the device smoke is green.
9. Add private Storage + photo/PDF share intake.
10. Add OCR after Storage/share intake is stable.
11. Add real AI extraction last while preserving editable proposals + explicit confirmation.
12. Remove/gate diagnostics for release and perform physical-device + VoiceOver QA before TestFlight.

## Brand guardrail

`Family Life OS` is internal only.

Rejected first-pass directions:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Avoid generic house/checkmark, cartoon family and robot/AI-sparkle identity.

Final name still requires current App Store/web + EUIPO/DPMA/domain clearance.

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
4. inspect latest Family Life OS CI state
5. continue from the external Auth allow-list + physical-device smoke test
6. do not regress to “live backend next” — hosted backend is integrated
7. do not regress to “two-user RLS untested” — database/hosted-SQL isolation is green
8. do not call the new E2E harness itself passed until it has run through a real authenticated device session
