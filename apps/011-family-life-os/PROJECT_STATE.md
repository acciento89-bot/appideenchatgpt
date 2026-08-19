# Family Life OS — Project State

Last updated: 2026-08-19
Status: HOSTED SUPABASE VERTICAL SLICE MERGED / IOS + DB GATES GREEN
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation location: `apps/011-family-life-os/` in the central App Factory repository

> This file is the app-specific single source of truth. Older exhaustive checkpoints remain available in Git history; this state is intentionally compacted around the current verified implementation so new chats do not continue from stale milestones.

## Current verified checkpoint

- Hosted Supabase PR `#8` — MERGED
- Final tested PR head: `13297c5fd40705509dce298d741229ccd26b76bb`
- Merge commit: `747d5bed505ef527501d24b9a24144ffb04a24f1`
- iOS Simulator workflow: `Family Life OS Prototype Build`
- Final iOS run: `32221107674` / run #17 — SUCCESS
- Database workflow: `Family Life OS Database Tests`
- Final DB run: `32221107641` / run #8 — SUCCESS
- Both required gates passed on the same tested head before merge.

Compiler issue fixed before merge:

- `FamilyView.swift:93`
- `HostedAppView.swift:74`
- cause: SwiftUI `Section` calls combining a title shorthand with a trailing footer closure resolved to the wrong initializer under the CI compiler
- fix: explicit `header` / `footer` closures
- CI now preserves Xcode build diagnostics as a short-lived artifact on failure so future compiler failures do not require guesswork.

## Product thesis

> Put family chaos in. Get an organized plan out.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

The product is a Family Inbox and workflow engine, not a generic shared-calendar clone.

`Import prüfen` is the locked trust boundary:

- imported source remains reachable
- extraction produces editable proposals only
- proposals can be independently included/excluded
- unresolved required information blocks confirmation
- explicit user confirmation creates canonical family data
- confirmed items retain source + proposal provenance
- future AI/OCR work may not bypass this review-before-confirmation boundary

## Locked product / architecture decisions

- DACH-first behavior, globally extensible architecture.
- Native SwiftUI client.
- iPhone first with intentional iPad adaptation.
- iOS/iPadOS 18+.
- Shared backend from v1.
- Supabase is the backend foundation.
- Hosted development project is in the EU / Frankfurt region.
- Postgres + RLS are the primary household isolation boundary.
- Family documents will use private object storage; no public source-document bucket.
- AI processing is server-side only; privileged/service-role credentials never ship in the app.
- MVP intake types: photo/screenshot, PDF/document share, direct/pasted text and voice.
- Direct mailbox surveillance is not MVP.
- Primary destinations: Heute, Inbox, Plan, Familie.
- Capture is an action, not a fifth tab.
- MVP action kinds: event, task, deadline, payment, preparation/reminder.
- Child/guest permission architecture exists from day one.
- Family Pro subscription remains provisional pending AI/storage/sync unit economics.

## Executable iOS prototype

Project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Shared scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Swift CI:

`.github/workflows/family-life-os-prototype-build.yml`

Implemented UI:

- compact iPhone `TabView`: Heute / Inbox / Plan / Familie
- regular-width/iPad `NavigationSplitView`
- adaptive Import Review including two-column regular-width layout
- Dynamic Type and accessibility-size reflow
- VoiceOver labels/hints and stable accessibility identifiers
- semantic Light/Dark surfaces
- busy/calm/conflict Today fixtures
- schedule-overlap detection
- Inbox queued/processing/review/partial/done/failed states
- task completion
- family roles and child profile creation
- source/proposal provenance

## Repository boundary

Architecture:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Implementations:

- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted data

Core repository operations:

- `currentSnapshot()`
- `ingestText(...)`
- `confirmReviewedProposals(...)`
- `setPlanItemCompleted(...)`
- `addChild(named:)`

The deterministic fixture extraction remains intentionally non-AI. It exists to validate the end-to-end workflow before OCR/LLM variability is introduced.

## Hosted Supabase state

Hosted development project:

- region: Frankfurt / EU
- client uses only the publishable client key
- no service-role secret in the iOS bundle
- Supabase Swift / `Supabase` pinned to `2.54.1`

Hosted hardening / vertical-slice migrations added in PR #8:

- `20260819041232`
- `20260819041753`

Hosted rollout state recorded by PR #8:

- advisor hardening migration deployed
- hosted text vertical-slice RPC migration deployed
- hosted security advisor clean after rollout
- performance advisor only reported expected INFO-level unused-index notices on the new/empty database

Hosted iOS client now implements:

- Supabase client environment
- Magic Link auth/session gate
- custom app redirect handling
- first-household bootstrap
- hosted reads for members, Inbox sources, proposals, assignees and Plan items
- deterministic server-side text fixture ingestion through `ingest_text_fixture`
- reviewed proposal edit/assignee persistence
- canonical confirmation RPC call
- remote task completion
- remote child-profile creation to resolve child assignment blockers

Important auth prerequisite still open:

`de.kamilunavo.familyprototype://login-callback`

must be present in the hosted Supabase Auth redirect allow-list before real-device Magic Link login can complete reliably.

## Database contract / security

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

Security / integrity rules:

- RLS on client-exposed collaborative tables
- multiple child/guest profiles without login allowed per household
- authenticated-user uniqueness only when `user_id` is non-null
- private membership helpers use restricted `SECURITY DEFINER`, empty `search_path`, and narrow execute grants
- client update privileges limited to product-editable columns
- processing/review/provenance state remains server/RPC-owned where required
- machine extraction rows are trusted-server-owned
- canonical source/proposal provenance must resolve inside the same household

Atomic confirmation RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Contract:

1. resolve source household
2. require authenticated owner/adult membership
3. verify requested proposals belong to source
4. reject excluded/rejected/unresolved proposals
5. create or reuse one canonical `plan_item` per proposal
6. unique `source_proposal_id` prevents duplicate canonical rows
7. copy same-household assignees only
8. mark proposal confirmed
9. transition source partial/done according to remaining proposals
10. retries reuse the canonical item instead of duplicating it

## Validation boundary

### Green / verified now

- SwiftUI prototype builds in GitHub Xcode/iOS Simulator CI
- `SupabaseFamilyRepository` compiles with the app
- Supabase Swift package resolution works with the pinned dependency
- fresh local Postgres/Supabase migration path is green
- RLS/RPC pgTAP coverage is green
- hosted hardening/text migrations were rolled out before PR #8
- hosted security advisor was clean after rollout
- final PR #8 iOS and database gates both passed on `13297c5fd40705509dce298d741229ccd26b76bb`
- PR #8 merged to `747d5bed505ef527501d24b9a24144ffb04a24f1`

### Not yet release-validated

- real-device Magic Link after redirect allow-list confirmation
- complete live school-letter flow executed manually from an authenticated iPhone/iPad client
- two-real-user hosted household-isolation E2E test over the Data API
- multi-device Realtime behavior
- private Storage
- photo/PDF share ingestion
- OCR
- real AI extraction/provider
- physical iPhone/iPad UI QA
- manual VoiceOver QA
- StoreKit/subscription implementation
- TestFlight/App Store release readiness

Do not claim those open items are finished merely because compile and DB gates are green.

## Signature vertical slice

Locked source: German class-trip school letter.

Expected proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

Hosted path now intended by the implementation:

1. authenticate
2. bootstrap household
3. Inbox -> text fixture import
4. hosted `ingest_text_fixture`
5. load source + proposals from Postgres/RLS
6. user reviews/edits proposals
7. resolve child ambiguity where necessary
8. persist proposal edits/assignees
9. call canonical confirmation RPC
10. reload Plan/Today from hosted data with provenance retained

The next validation pass must exercise that exact path on a real authenticated client before Storage/OCR/AI is added.

## Regression gates

Before every merge touching the hosted Family Life OS implementation:

1. iOS Simulator Xcode build must pass
2. fresh Supabase/Postgres migrations + pgTAP must pass
3. for cross-layer changes, both gates must be green on the same PR head
4. no service-role/private backend secret may enter the client bundle
5. review-before-confirmation and provenance must remain intact
6. household RLS must not be weakened for convenience
7. failure diagnostics should remain available through the Xcode CI artifact path

## Brand state

`Family Life OS` remains an internal codename only.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Brand character:

- calm
- capable
- warm
- trustworthy
- discreet
- premium without luxury styling

Preferred icon concept: **Gather -> Order**.

Avoid cartoon-family, robot/AI-sparkle and generic house/checkmark identity.

Final public name still requires current App Store/web + EUIPO/DPMA/domain checks before lock.

## Deferred / rejected for MVP

- generic calendar + shopping + chores clone
- family chat/social-network replacement
- live GPS
- video/audio calling
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic mailbox surveillance
- autonomous bookings/calls
- medical-advice assistant
- generic AI-chat-first interface
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

## Immediate next steps

1. Confirm/add `de.kamilunavo.familyprototype://login-callback` in hosted Supabase Auth redirect URLs.
2. Run the authenticated hosted school-letter vertical slice from the iOS client end to end.
3. Verify resulting Inbox/proposals/Plan data and retry/idempotency behavior against hosted Postgres.
4. Validate household isolation with two real authenticated users.
5. Add Realtime only after the hosted text path is proven manually.
6. Then add private Storage + photo/PDF intake.
7. Add OCR after Storage/share intake is stable.
8. Add real AI extraction last, retaining editable proposals and explicit confirmation.
9. Perform physical-device + VoiceOver QA before any TestFlight release checkpoint.

## Handoff rule

For any new chat or continuation:

1. read `docs/APP_FACTORY_STATE.md`
2. read this file
3. inspect current `main`
4. inspect the latest Family Life OS Xcode + database gate state
5. continue from the immediate next steps above
6. do not regress to the pre-PR-#8 statement that the live backend is merely “next”
