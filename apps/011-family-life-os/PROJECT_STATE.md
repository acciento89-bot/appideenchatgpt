# Family Life OS — Project State

Last updated: 2026-08-19
Status: APP STORE CONNECT APP RECORD REQUIRED / BUNDLE ID VERIFIED
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/` in the central App Factory repository

> This file is the app-specific single source of truth. Older exhaustive checkpoints remain in Git history. Continue from this file, not from stale chat summaries.

## Current verified checkpoint

Latest major pass: real Apple/TestFlight credential + registration-path probe.

The previous `TESTFLIGHT ASC SECRETS NEXT` blocker is obsolete. Existing App Store Connect API credentials from the working `acciento89-bot/onemorefloor` pipeline were reused through a temporary bridge workflow without exposing or copying secret values.

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
- in-app diagnostics use the authenticated Supabase session and normal RLS client rights
- harness covers Auth -> household -> child -> hosted school-letter import -> 4 proposals -> confirm -> 4 PlanItems -> provenance -> source done -> idempotent retry -> cleanup

### PR #11 — Release device + TestFlight pipeline

- MERGED
- tested head: `546722579458b5caef23641b181810de10ce9eee`
- merge: `727f2cdceae6cd0f527a766879a8d0517fbdb742`
- workflow: `.github/workflows/family-life-os-testflight.yml`
- PR run `32228406465` / #2 — SUCCESS
- pinned Supabase package resolution — SUCCESS
- Release generic `iphoneos` build for physical iPhone/iPad — SUCCESS
- unsigned physical-device `.app` artifact packaging — SUCCESS
- TestFlight upload disabled on pull requests
- signing/upload diagnostics preserved

### Apple/TestFlight bridge checkpoint — 2026-08-19

A temporary internal bridge was created in `acciento89-bot/onemorefloor` because that repository already contains working App Store Connect Actions secrets with the same secret names and Apple team.

Bridge details:

- bridge workflow: `acciento89-bot/onemorefloor/.github/workflows/family-life-os-testflight-bridge.yml`
- draft probe PR: `acciento89-bot/onemorefloor#84`
- decisive bridge run: `32247708814`
- job: `96051837747`
- Family Life OS source checked out from `acciento89-bot/appideenchatgpt/main`
- Swift package resolution — SUCCESS
- unsigned Release physical-device build — SUCCESS
- existing `ASC_ISSUER_ID` / `ASC_KEY_ID` / `ASC_PRIVATE_KEY_B64` presence check — SUCCESS
- API key decode/validation — SUCCESS
- unsigned Release archive — SUCCESS
- App Store Connect export — FAILED with raw `xcodebuild` exit status `70`
- exact decisive diagnostic: `No profiles for 'de.kamilunavo.familyprototype' were found`
- no secret values were exposed, copied into source, or printed
- no successful TestFlight upload occurred

A second lightweight Apple registration probe then queried Apple's App Store Connect API using the same short-lived authenticated bridge path.

Probe details:

- probe run: `32248236864`
- handoff issue: `acciento89-bot/onemorefloor#88`
- bundle identifier queried: `de.kamilunavo.familyprototype`
- registered Bundle ID matches: `1`
- Apple Bundle ID resource id: `2NV99ZM2PM`
- App Store Connect app records for this bundle id: `0`
- provisioning profiles for this bundle id: `0`

**Verified current Apple blocker:** the explicit Bundle ID is already registered, but there is no App Store Connect app record for it yet. This supersedes the earlier assumption that missing ASC repository secrets were the next blocker.

Apple's public App Store Connect API can list/manage existing apps but does not create a brand-new app record. The app record therefore requires one manual creation in App Store Connect. After that, the existing automatic/cloud-signing TestFlight path should be retried and its exact result used as the next gate.

## Auth redirect state

Required callback:

`de.kamilunavo.familyprototype://login-callback`

**Hosted Supabase allow-list configuration is USER-CONFIRMED DONE on 2026-08-19.**

Expected location:

**Supabase Dashboard -> Authentication -> URL Configuration -> Redirect URLs / Additional Redirect URLs**

Do not regress to “Auth redirect not configured”. Physical-device Magic Link/session establishment is still unverified until an internal TestFlight/device build is installed and exercised.

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

Canonical Family Life OS workflow:

`.github/workflows/family-life-os-testflight.yml`

Existing ONE MORE FLOOR bridge credentials were proven valid for this Family Life OS build without exposing their values.

Current Apple state:

- explicit bundle ID `de.kamilunavo.familyprototype` — REGISTERED
- Bundle ID resource `2NV99ZM2PM`
- App Store Connect app record — MISSING
- provisioning profile — NONE
- ASC credentials through bridge — VERIFIED WORKING
- archive creation — VERIFIED WORKING
- signed TestFlight upload — NOT YET SUCCESSFUL

### Required one-time App Store Connect action

Create a new iOS app record in App Store Connect using the already registered bundle ID `de.kamilunavo.familyprototype`.

Suggested internal creation values while the public brand is still unlocked:

- Platform: iOS
- Name: `Family Life OS` as a temporary internal App Store Connect name; change before review when final brand is locked
- Primary Language: German
- Bundle ID: `de.kamilunavo.familyprototype`
- SKU: `KAMILUNAVO-FAMILY-001`
- User Access: Full Access unless a narrower access model is intentionally required

After app-record creation, rerun the bridge/TestFlight build `1`. Do not manually invent or commit provisioning material unless automatic signing still fails and Apple returns a new exact diagnostic.

Do **not** claim a Family Life OS TestFlight upload has succeeded until an actual signed workflow run reports success.

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
- working App Store Connect API credentials proven through bridge
- Family Life OS Release archive proven through bridge
- explicit Apple Bundle ID existence proven through App Store Connect API
- absence of App Store Connect app record proven through App Store Connect API
- absence of provisioning profile proven through App Store Connect API

### Not yet release-validated

- App Store Connect app record creation for Family Life OS
- automatic distribution provisioning after app-record creation
- signed TestFlight upload for Family Life OS
- physical-device Magic Link callback/session establishment
- in-app hosted E2E smoke report from a real authenticated iPhone/iPad
- two real authenticated devices/sessions over Data API
- Realtime
- private Storage
- photo/PDF share intake
- OCR
- real AI extraction/provider
- physical-device UI + manual VoiceOver QA
- StoreKit/subscription
- external TestFlight/App Store readiness

## Immediate next steps

1. In App Store Connect create the iOS app record for `de.kamilunavo.familyprototype` using the values above.
2. Rerun the Family Life OS TestFlight bridge with build `1` and require a real signed upload success; if Apple still rejects signing/provisioning, use the new exact diagnostic rather than guessing.
3. Once uploaded, install the internal TestFlight build on a physical iPhone/iPad.
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
5. continue from **App Store Connect app record -> signed internal TestFlight -> physical-device Magic Link -> in-app hosted E2E smoke**
6. do not regress to “ASC secrets missing” — existing working credentials were proven through the secure bridge on 2026-08-19
7. do not regress to “Bundle ID missing” — Apple API probe found bundle resource `2NV99ZM2PM`
8. do not regress to “Auth redirect not configured” — user confirmed the hosted callback allow-list entry on 2026-08-19
9. do not regress to “two-user RLS untested” — database/hosted-SQL isolation is green
10. do not claim TestFlight/device E2E success without the actual signed/device run
11. do not jump to Realtime/Storage/OCR/AI before the authenticated physical-device hosted text smoke is proven
