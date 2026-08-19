# Family Life OS — Project State

Last updated: 2026-08-19
Status: DEVICE RELEASE BUILD GREEN / TESTFLIGHT ASC SECRETS NEXT
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/` in the central App Factory repository

> This file is the app-specific single source of truth. Older exhaustive checkpoints remain in Git history. Continue from this file, not from stale chat summaries.

## Current verified checkpoint

Latest major pass: physical-device Release build + safe TestFlight pipeline.

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
- direct hosted Frankfurt isolation smoke green
- temporary hosted test identities/data removed
- hosted Security Advisor clean at last check

### PR #10 — authenticated hosted E2E smoke harness

- MERGED
- tested head: `eb4b14998d630ec9c1951548fcaac71671ff625b`
- merge: `a56f0776ea701a50b549e4167415d4b0056afde1`
- iOS run `32225259430` / #21 — SUCCESS
- no DB workflow required because no database schema/policy/function contract changed

The in-app diagnostics harness uses only the current authenticated Supabase session and normal RLS client rights. It verifies Auth -> household -> child resolution -> hosted school-letter import -> exactly four proposals -> confirmation -> exactly four PlanItems -> provenance -> source done -> idempotent retry -> cleanup.

### PR #11 — Release device + TestFlight pipeline

- MERGED
- tested head: `546722579458b5caef23641b181810de10ce9eee`
- merge: `727f2cdceae6cd0f527a766879a8d0517fbdb742`
- workflow: `.github/workflows/family-life-os-testflight.yml`
- PR workflow run `32228406465` / #2 — SUCCESS
- pinned Supabase package resolution — SUCCESS
- Release generic `iphoneos` build for physical iPhone/iPad — SUCCESS
- unsigned physical-device `.app` artifact packaging — SUCCESS
- TestFlight upload is disabled on pull requests
- workflow checks App Store Connect credentials without printing secret values
- when credentials are absent, main/manual runs keep the Release-device validation but explicitly skip TestFlight instead of producing a false CI failure
- when credentials are present, upload uses Apple cloud distribution signing and must fail visibly if Apple signing/upload fails

Verified repository credential state during PR #11:

- `ASC_ISSUER_ID` — absent
- `ASC_KEY_ID` — absent
- `ASC_PRIVATE_KEY_B64` — absent
- no secret values were exposed or copied

Because the connected GitHub tool surface does not expose Actions-secret mutation, these credentials cannot be copied from another repository by the assistant without revealing/re-entering them.

## Auth redirect state

Required callback:

`de.kamilunavo.familyprototype://login-callback`

**Hosted Supabase allow-list configuration is now USER-CONFIRMED DONE on 2026-08-19.**

Expected location:

**Supabase Dashboard -> Authentication -> URL Configuration -> Redirect URLs / Additional Redirect URLs**

This removes the known configuration blocker, but the callback has **not yet been exercised from a physical iPhone/iPad**, so real-device Magic Link/session establishment remains unverified.

## Product thesis

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

The product is a Family Inbox/workflow engine, not a generic shared-calendar clone.

`Import prüfen` is the locked trust boundary:

- source remains reachable
- extraction creates editable proposals only
- proposals are independently includable/editable
- unresolved required information blocks confirmation
- explicit user confirmation creates canonical family data
- confirmed items retain source + proposal provenance
- OCR/AI may not bypass review-before-confirmation

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
- private Storage later for family documents
- AI processing server-side only
- `SwiftUI View -> DemoStore -> FamilyRepository -> data source`
- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted production-direction data
- Realtime only after authenticated device text path is proven
- private Storage/photo/PDF after that, then OCR, then real AI

## Executable iOS prototype

Project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Current internal version path:

`0.1.0 (1)`

Implemented UI/UX:

- Heute / Inbox / Plan / Familie
- compact iPhone tabs
- adaptive iPad `NavigationSplitView`
- two-column regular-width Import Review
- Dynamic Type/accessibility-size reflow
- VoiceOver labels/hints + accessibility identifiers
- semantic Light/Dark surfaces
- busy/calm/conflict Today states
- overlap detection
- Inbox queued/processing/review/partial/done/failed states
- editable review flow
- child profile creation
- source/proposal provenance
- hosted backend diagnostic sheet with one-button authenticated E2E smoke run

The diagnostics UI is intentionally allowed in **internal TestFlight builds** because it is needed for the first physical-device backend smoke. It must be gated to DEBUG/internal builds before external TestFlight/App Store distribution.

## Hosted Supabase

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Last observed project state:

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
- custom URL scheme in Info.plist
- exact expected callback validation before session exchange
- household bootstrap
- member/Inbox/proposal/assignee/Plan reads through Postgres/RLS
- deterministic hosted fixture text import
- proposal edits + assignee persistence
- canonical confirmation RPC
- remote task completion
- remote child profile creation
- authenticated hosted E2E diagnostics

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

Security/integrity baseline:

- RLS on client-exposed collaborative tables
- multiple child/guest profiles without login allowed
- authenticated-user uniqueness only when `user_id` is non-null
- restricted private helper functions with empty `search_path`
- client write surface limited to product-editable fields
- processing/review/provenance server/RPC-owned where required
- canonical provenance constrained to same household
- two-user isolation mandatory regression gate

Canonical RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

It owns authorization, source/proposal validation, unresolved rejection, canonical PlanItem create/reuse, same-household assignees, proposal finalization, source-state transition and idempotent retry.

## Apple / TestFlight path

Known Apple team used by the existing Kamilunavo cloud-signing setup:

- Team ID `TKG684N5GL`

Family Life OS TestFlight workflow:

`.github/workflows/family-life-os-testflight.yml`

Behavior:

1. resolve packages
2. build Release for generic physical iOS device with signing disabled
3. preserve unsigned device artifact
4. detect ASC credential presence without logging values
5. on PR: never upload
6. on main/manual run with credentials: create archive + App Store Connect export with automatic cloud signing
7. capture export diagnostics
8. fail on a real Apple upload/signing failure
9. if credentials are absent: skip upload while keeping device-build gate meaningful
10. remove temporary API-key file on every run

Current blocker to an actual TestFlight upload:

GitHub Actions repository secrets must be configured in `acciento89-bot/appideenchatgpt`:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

The same App Store Connect API credentials already used by the user's working Kamilunavo/ONE MORE FLOOR pipeline may be reused if they have the necessary access, but the secret values must never be committed to Git or pasted into source code.

Do **not** claim a Family Life OS TestFlight upload has succeeded until a signed workflow run actually reports success.

## Validation boundary

### Green / verified

- SwiftUI client builds in Xcode/iOS Simulator CI
- hosted `SupabaseFamilyRepository` compiles
- Supabase dependency resolution works
- fresh local migration path green
- pgTAP RLS/RPC coverage green
- hosted migrations deployed
- hosted Security Advisor clean at last check
- direct hosted two-identity SQL isolation green
- PR #9 Xcode + DB gates green on same head
- PR #10 authenticated smoke harness compiles
- Supabase callback allow-list configuration user-confirmed complete
- PR #11 generic Release `iphoneos` physical-device build green
- PR #11 unsigned device artifact green
- safe TestFlight cloud-signing workflow merged to main

### Not yet release-validated

- physical-device Magic Link callback/session establishment
- in-app hosted E2E smoke report from a real authenticated iPhone/iPad
- two real authenticated devices/sessions over Data API
- signed TestFlight upload for Family Life OS
- Apple bundle/app-record/provisioning path for this provisional bundle id
- Realtime
- private Storage
- photo/PDF share intake
- OCR
- real AI extraction/provider
- physical-device UI + manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## Immediate next steps

1. Add the three App Store Connect Actions secrets to `acciento89-bot/appideenchatgpt`.
2. Run `Family Life OS TestFlight` manually with build `1` and require signed upload success; if Apple rejects bundle/app configuration, use captured diagnostics and fix the exact blocker.
3. Install the internal TestFlight build on a physical iPhone/iPad.
4. Request Magic Link and verify `de.kamilunavo.familyprototype://login-callback` returns into the app with an authenticated session.
5. Open **Backend-Diagnose** and run **Hosted E2E jetzt prüfen**.
6. Require every smoke step including cleanup to pass.
7. Repeat with a second real authenticated Supabase user/session for final Data-API isolation coverage.
8. Only then add Realtime.
9. Add private Storage + photo/PDF share intake.
10. Add OCR after Storage/share intake is stable.
11. Add real AI extraction last while preserving editable proposals + explicit confirmation.
12. Gate diagnostics for external distribution and perform physical-device + VoiceOver QA before release readiness.

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
5. continue from ASC-secrets -> signed internal TestFlight -> physical-device Magic Link -> in-app hosted E2E smoke
6. do not regress to “live backend next” — hosted backend is integrated
7. do not regress to “Auth redirect not configured” — user confirmed the hosted callback allow-list entry on 2026-08-19
8. do not regress to “two-user RLS untested” — database/hosted-SQL isolation is green
9. do not claim TestFlight/device E2E success without the actual signed/device run
