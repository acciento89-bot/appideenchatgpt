# Family Life OS — Project State

Last updated: 2026-08-18
Status: LOCAL SUPABASE DB CONTRACT GREEN / LIVE BACKEND NEXT
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation repository: NOT CREATED YET — prototype temporarily lives in the central App Factory repo

## Current checkpoints

- Foundation PR `#3` — MERGED
- Foundation merge: `cd86aa4980133020b05629f9930aff598d9f9b35`
- First executable UI PR `#4` — MERGED
- UI merge: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
- First green UI CI: `32180561109`
- Adaptive UI/accessibility PR `#5` — MERGED
- Adaptive merge: `aa70b24ebb21d472c66ac13d790096510f65a309`
- Final adaptive CI: `32182627951` — SUCCESS
- Backend contract/repository PR `#6` — MERGED
- Backend merge: `cb0a3f99f749ee46ce8b3b6d39c79d50bfe3341b`
- Final backend Swift head before squash: `ab68d1f25883886715d7892d6b90a5578c193924`
- Final backend Swift CI: `32184778802` — SUCCESS
- Supabase DB validation PR `#7` — MERGED
- Final DB validation branch head: `f2ecc11881af78896e5cba4f7f75c3409f5e2d02`
- Final DB CI run: `32185816675` — SUCCESS
- Supabase DB validation merge: `ff9b4695efb4fa49d605e05a53b18bd352872fe3`

## Product thesis

> Put family chaos in. Get an organized plan out.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

The product is centered on a Family Inbox and ingestion-to-action workflow, not on being another generic family calendar.

`Import prüfen` is the signature trust boundary: extraction/AI output remains editable proposal data until explicit user confirmation.

## Locked product decisions

- DACH-first behavior with globally extensible architecture.
- Native SwiftUI client.
- iPhone first with intentional iPad adaptation.
- iOS/iPadOS 18+ direction.
- Shared backend required from v1.
- Supabase selected as backend foundation.
- Central EU / Frankfurt preferred hosted region.
- Postgres + Row Level Security are the primary household-isolation boundary.
- Family documents use private object storage later; no public source-document bucket.
- AI processing is server-side only; no provider/service-role secret in the app.
- MVP input types: photo, screenshot/image, PDF/document share, pasted/direct text and voice.
- Direct mailbox surveillance is not MVP.
- Extraction creates editable proposals only; user confirmation creates canonical household data.
- Confirmed items retain source and proposal provenance.
- Primary destinations: Heute, Inbox, Plan, Familie.
- Capture is an action, not a fifth tab; Settings is not a fifth permanent tab.
- MVP action kinds: event, task, deadline, payment, preparation/reminder.
- Family Pro subscription remains provisional because AI/storage/sync create recurring costs.
- Child/guest permission architecture exists from day one.
- No future backend/AI pass may weaken review-before-confirmation.

## Executable prototype

Temporary path:

`apps/011-family-life-os/prototype/`

Project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Shared scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Target:

- iOS/iPadOS 18.0
- iPhone + iPad

Swift CI workflow:

`.github/workflows/family-life-os-prototype-build.yml`

The GitHub connector still does not expose repository creation. Move implementation to an app-specific repository when that becomes available; the central prototype path is temporary.

## Implemented UI / UX

### App shell

Compact width:

- native `TabView`
- Heute
- Inbox
- Plan
- Familie
- independent navigation stacks

Regular width / iPad:

- adaptive `NavigationSplitView`
- persistent sidebar
- selected destination in detail column
- constrained content widths rather than stretched phone cards

### Heute

- conditional attention surface
- factual family brief
- chronological timeline
- task completion
- member identity via avatar/name + accent
- tomorrow/preparation section from plan data
- deterministic busy/calm/conflict fixtures
- real shared-member schedule-overlap detection
- conflict attention + row indicators
- semantic Light/Dark surfaces

### Inbox

Statuses implemented:

- `Wartet auf Upload`
- `Wird hochgeladen`
- `Wird analysiert`
- `Prüfen`
- `Teilweise übernommen`
- `Erledigt`
- `Analyse fehlgeschlagen`

Behavior implemented:

- Offen / Verarbeitet / Alle filters
- image / PDF / text / voice source types
- queued offline state + recovery copy
- processing and failure states
- proposal counts
- capture menu
- review/partial rows actionable
- non-actionable rows are not dead buttons
- meaningful empty states
- visible `Text-Beispiel importieren` path exercises the repository ingestion boundary

### Import prüfen

- original source remains reachable
- compact stacked layout
- regular-width source/proposal two-column layout
- independently includable/editable proposal cards
- date/time/reminder editing
- unresolved child assignment blocks confirmation
- assignment resolves blocker
- VoiceOver labels/hints and stable accessibility identifiers
- accessibility-size form reflow
- confirmation delegates to repository
- accepted items retain source + source-proposal provenance
- unresolved and ready-to-confirm deterministic fixtures

### Plan

- agenda-first list
- day grouping
- member filters
- event/task/deadline/payment/preparation rows
- task/preparation completion
- `Aus Import` provenance indicator
- filtered empty state
- accessibility reflow

### Familie

- household summary
- Owner / Adult / Child roles
- adult full-access vs child-without-login distinction
- permission messaging
- large-text adaptation
- invite action explicitly disabled in prototype rather than pretending to work

## Accessibility / appearance baseline

Implemented:

- Dynamic Type-aware layout
- accessibility-size row/form reflow
- VoiceOver labels and hints for critical controls
- stable accessibility identifiers
- family identity never relies on color alone
- practical touch-target sizing
- semantic Light/Dark surfaces
- Dark Mode previews
- accessibility-size previews
- regular-width previews
- explicit empty/offline/error states

Manual physical-device and VoiceOver QA is still a future release gate; this section is an implementation baseline, not a release certification.

## Swift repository boundary — GREEN

Current architecture:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Current implementation:

`InMemoryFamilyRepository`

Planned production implementation:

`SupabaseFamilyRepository`

Source files:

- `prototype/FamilyLifePrototype/Data/FamilyRepository.swift`
- `prototype/FamilyLifePrototype/Data/InMemoryFamilyRepository.swift`
- `prototype/FamilyLifePrototype/Data/FixtureTextExtractionService.swift`

`FamilyRepository` operations:

- `currentSnapshot()`
- `ingestText(...)`
- `confirmReviewedProposals(...)`
- `setPlanItemCompleted(...)`

`DemoStore` remains observable UI state but delegates ingestion, confirmation and completion persistence-like work to the repository.

The deterministic `FixtureTextExtractionService` is explicitly not AI. It recognizes only the locked school-letter fixture and produces the four expected proposals to prove the contract without network credentials.

Optimistic completion remembers the previous local state and rolls only that value back if repository persistence fails.

## Domain / provenance model

Added and retained:

- `ProposalReviewStatus`: proposed / confirmed / rejected
- `ActionProposal.reviewStatus`
- `PlanItem.sourceProposalID`

`sourceProposalID` is both provenance and the application/database idempotency key for canonical confirmation.

## Supabase SQL contract — GREEN ON FRESH LOCAL POSTGRES

Backend contract:

`apps/011-family-life-os/BACKEND_CONTRACT.md`

Migrations:

- `supabase/migrations/20260818224000_family_core.sql`
- `supabase/migrations/20260818224500_fix_member_uniqueness_and_confirm_retry.sql`
- `supabase/migrations/20260818224700_private_helper_permissions.sql`
- `supabase/migrations/20260818225000_tighten_client_write_surface.sql`

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

Security / integrity decisions:

- RLS enabled on client-exposed collaborative tables.
- Multiple child/guest profiles without login are allowed in the same household.
- `(household_id, user_id)` uniqueness applies only when `user_id` is non-null.
- private membership helpers use restricted `SECURITY DEFINER`, explicit empty `search_path`, and limited execute grants.
- authenticated client UPDATE privileges are narrowed to product-editable columns.
- processing status, review finalization and canonical provenance are server/RPC-owned.
- machine extraction rows remain trusted-server-owned.
- direct canonical provenance must resolve to source/proposal in the same household.

## Atomic confirmation RPC — LOCALLY VALIDATED

RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Contract:

1. resolve source household
2. require current authenticated owner/adult membership
3. verify every requested proposal belongs to the source
4. reject excluded/rejected/unresolved proposals
5. create or reuse one canonical `plan_item` per proposal
6. unique `source_proposal_id` prevents duplicate canonical rows
7. copy only same-household assignees
8. mark proposal confirmed
9. mark source partial while proposals remain open, otherwise done
10. retry reuses the existing canonical item rather than duplicating it

The final RPC is tightly scoped `SECURITY DEFINER` because it owns writes to server-controlled review/status/provenance columns. It retains explicit authenticated household checks, an empty `search_path`, and restricted execution.

## Supabase / pgTAP database CI — GREEN

Local Supabase workspace:

`apps/011-family-life-os/supabase/config.toml`

Explicit seed file:

`apps/011-family-life-os/supabase/seed.sql`

Database CI workflow:

`.github/workflows/family-life-os-database-tests.yml`

Workflow behavior:

1. Ubuntu GitHub runner
2. official Supabase CLI setup
3. fresh local Supabase/Postgres database start
4. apply all migrations
5. execute `supabase test db`

Final clean run:

- workflow: `Family Life OS Database Tests`
- run: `32185816675`
- result: SUCCESS
- Supabase CLI: `2.115.0`
- Postgres image: `ghcr.io/supabase/postgres:15.8.1.085`
- all four #011 migrations applied successfully
- pgTAP file: `family_core_rls.test.sql .. ok`
- `Files=1, Tests=12`
- `All tests successful.`
- `Result: PASS`

The earlier successful DB run also passed, but the final run was repeated after CI hygiene cleanup. The deprecated local Inbucket config was removed and an explicit empty `seed.sql` was added so those project-owned warnings no longer appear.

The remaining GitHub log warning is the external Node-version notice from `actions/checkout@v4`; it is not a Family Life OS application/database failure.

### 12 database assertions cover

- core tables exist
- multiple no-login child profiles are allowed
- household A cannot read household B rows
- unresolved proposal confirmation fails
- valid proposal confirmation succeeds
- confirmation retry succeeds
- retry produces only one canonical plan item
- child role does not receive adult household-management permission

## Current validation boundary

### Validated now

- executable SwiftUI prototype compiles in macOS/Xcode CI
- adaptive iPhone/iPad UI passes its build gate
- repository/data Swift refactor compiles
- final repository head `ab68d1f25883886715d7892d6b90a5578c193924` passed run `32184778802`
- Supabase schema applies from scratch to local Postgres
- RLS/RPC pgTAP contract passes all 12 tests
- final DB validation head `f2ecc11881af78896e5cba4f7f75c3409f5e2d02` passed run `32185816675`
- PR #7 merged to `ff9b4695efb4fa49d605e05a53b18bd352872fe3`

### Not yet validated

- hosted Supabase development/production project
- real Sign in with Apple / Auth session
- live Data API access from the iOS client
- `SupabaseFamilyRepository`
- live hosted confirmation RPC
- live multi-device sync / Realtime
- private Storage
- photo/PDF import
- OCR
- real AI provider
- physical iPhone/iPad QA
- manual VoiceOver QA

Do not describe the live backend as connected yet. What is green is the **local clean-database schema/RLS/RPC contract**.

## Signature text vertical slice

Locked source: German class-trip school letter.

Expected proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

Current in-memory path:

1. Inbox -> `Text-Beispiel importieren`
2. `DemoStore.ingestSchoolLetterText()`
3. `FamilyRepository.ingestText()`
4. deterministic fixture extraction
5. source enters review
6. `Import prüfen`
7. user resolves child ambiguity / edits fields
8. `FamilyRepository.confirmReviewedProposals()`
9. canonical PlanItems are created with source/proposal provenance
10. source becomes partial/done

Next milestone: make this exact visible path operate against a hosted Supabase development project through `SupabaseFamilyRepository` without changing the UX contract.

## CI history

- `32180375921` — failed on Swift foreground-style inference; fixed
- `32180561109` — SUCCESS; PR #4 merged
- `32182317924` — failed on iPad sidebar selection API; fixed
- `32182408384` — SUCCESS
- `32182627951` — SUCCESS; PR #5 merged
- `32184322336` — repository refactor intermediate SUCCESS
- `32184431611` — SUCCESS, exposed one Swift completion rollback warning
- completion rollback was refactored
- `32184778802` — final backend Swift SUCCESS; PR #6 merged
- first Supabase DB gate run — migrations + 12 tests SUCCESS
- `32185816675` — final clean Supabase DB gate SUCCESS; PR #7 merged

## Brand state

Public name remains open and must not block implementation.

`Family Life OS` is an internal codename only.

First-pass rejected naming directions:

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

Preferred icon concept: **Gather -> Order** — rounded loose pieces becoming one organized form.

Avoid cartoon-family, robot/AI-sparkle and generic house/checkmark identity.

Final public name requires current App Store/web + EUIPO/DPMA/domain checks before lock.

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

## Open decisions

1. final public brand/name and EU collision clearance
2. exact AI provider/model and extraction implementation
3. subscription pricing and AI quota after cost modeling
4. attachment retention/privacy/legal defaults
5. calendar interoperability scope
6. child independent-login timing
7. final icon artwork and palette
8. app-specific implementation repository creation
9. hosted Supabase project/account connection details

## Immediate next steps

1. Create/connect a hosted Supabase development project in the preferred EU/Frankfurt region.
2. Apply the now-green migration set to that development project.
3. Implement `SupabaseFamilyRepository` using authenticated client access and the proven RPC contract.
4. Add the minimum Auth/household bootstrap needed for a real adult household.
5. Prove the exact school-letter text flow against hosted Supabase: source -> proposals -> review -> atomic confirm -> Today/Plan refresh.
6. Test household isolation over the actual Data API with two authenticated test users.
7. Add Realtime only after normal fetch/mutation behavior is correct.
8. Only then add private Storage + photo/PDF ingestion + OCR.
9. Add real AI extraction only after structured-output validation preserves explicit review.
10. Perform physical iPhone/iPad + manual VoiceOver QA before TestFlight readiness claims.
11. Move to an app-specific repository when repository creation becomes available.
12. Update this state and the central App Factory state after every major pass.

## Handoff rule

Before continuing #011 in a new chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE, UI_FIXTURES, BACKEND_CONTRACT and the prototype README. Inspect current `main` and both Swift/DB CI states before code changes. Continue with hosted Supabase + `SupabaseFamilyRepository`; do not jump to Storage/OCR/AI before the hosted text path is green.