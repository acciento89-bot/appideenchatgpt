# Family Life OS — Project State

Last updated: 2026-08-18
Status: REPOSITORY CONTRACT GREEN / SUPABASE SCHEMA SOURCE-CONTROLLED / DB VALIDATION PENDING
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation repository: NOT CREATED YET — prototype temporarily lives in the central App Factory repo

## Current checkpoints

- Foundation PR: `#3` — MERGED
- Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`
- First executable UI PR: `#4` — MERGED
- First executable UI merge commit: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
- First green prototype CI run: `32180561109`
- Adaptive UI / accessibility PR: `#5` — MERGED
- Adaptive UI / accessibility merge commit: `aa70b24ebb21d472c66ac13d790096510f65a309`
- Final green quality-pass CI run: `32182627951`
- Backend contract / repository PR: `#6` — MERGED
- Backend contract merge commit: `cb0a3f99f749ee46ce8b3b6d39c79d50bfe3341b`
- Final backend branch head before squash: `ab68d1f25883886715d7892d6b90a5578c193924`
- Final backend Swift CI run: `32184778802` — SUCCESS

## Product thesis

> Put family chaos in. Get an organized plan out.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

The product is centered on a Family Inbox and ingestion-to-action workflow, not on being another generic shared family calendar.

`Import prüfen` remains the signature trust boundary. Extraction/AI output is proposal data only until the user explicitly confirms it.

## Accepted product decisions

- DACH-first behavior, globally extensible architecture.
- Native SwiftUI client.
- iPhone first, intentional iPad adaptation.
- iOS/iPadOS 18+ deployment direction.
- Shared backend required from v1.
- Supabase selected as backend foundation.
- Central EU / Frankfurt preferred region.
- Postgres + Row Level Security as primary household isolation boundary.
- Private object storage for family documents.
- AI processing server-side only; no provider/service-role secrets in app.
- MVP sources: photo, screenshot/image, PDF/document share, pasted/direct text and voice.
- Direct mailbox surveillance is not MVP.
- AI creates editable proposals only; users confirm before canonical data is created.
- Confirmed items retain provenance to their source.
- Core destinations: Heute, Inbox, Plan, Familie.
- Settings are not a fifth permanent tab; capture is an action, not a tab.
- MVP actions: events, tasks, deadlines, payments and preparation actions/reminders.
- Family Pro recurring subscription remains provisional because AI/storage/sync create recurring cost.
- Child/guest permission architecture exists from day one.
- Real backend/AI integration must never weaken review-before-confirmation.

## Executable prototype

Temporary implementation path:

`apps/011-family-life-os/prototype/`

Xcode project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Shared scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Target:

- iOS/iPadOS 18.0
- iPhone + iPad

Dedicated build workflow:

`.github/workflows/family-life-os-prototype-build.yml`

The connected GitHub tooling still does not expose repository creation. Move implementation to an app-specific repository when that becomes available; the central prototype location is temporary.

## UI / UX implementation state

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
- destination in detail column
- constrained content widths instead of stretched iPhone cards

### Heute

Implemented:

- conditional attention surface
- factual family brief
- chronological timeline
- task completion
- member identity via avatar/name + accent
- tomorrow/preparation section driven from plan data
- deterministic busy/calm/conflict fixtures
- real schedule-overlap detection for shared household members
- conflict attention row + row-level indicators
- semantic light/dark-compatible backgrounds

### Inbox

Implemented statuses:

- `Wartet auf Upload`
- `Wird hochgeladen`
- `Wird analysiert`
- `Prüfen`
- `Teilweise übernommen`
- `Erledigt`
- `Analyse fehlgeschlagen`

Implemented behavior:

- filters: Offen / Verarbeitet / Alle
- source types: image / PDF / text / voice
- explicit offline queued copy
- processing/failure states
- proposal count
- capture menu
- review/partial rows actionable
- non-actionable states are not dead buttons
- meaningful empty state
- `Text-Beispiel importieren` now exercises the repository text-ingestion path

### Import prüfen

Implemented:

- source always reachable during review
- compact stacked layout
- regular-width two-column source/proposal layout
- editable proposal cards
- independent include/exclude
- native date/time/reminder editing
- unresolved child assignment blocks confirmation
- assignment resolves blocker
- VoiceOver labels/hints + stable accessibility identifiers
- accessibility-size form reflow
- confirmation delegates to repository boundary
- accepted items retain source and source-proposal provenance
- deterministic unresolved + ready-to-confirm fixtures

### Plan

Implemented:

- Agenda-first
- day grouping
- member filters
- event/task/deadline/payment/preparation rows
- task/preparation completion
- `Aus Import` provenance indicator
- empty filtered state
- accessibility reflow

### Familie

Implemented:

- household summary
- Owner / Adult / Child roles
- full-access vs child-without-login distinction
- permissions messaging
- large-text adaptation
- prototype invite action explicitly disabled rather than pretending to work

## Accessibility / appearance baseline

Implemented baseline:

- Dynamic Type-aware layouts
- accessibility-size row/form reflow
- VoiceOver labels and hints for critical controls
- stable accessibility identifiers
- non-color-only family identity
- practical touch-target sizing
- semantic Light/Dark system surfaces
- Dark Mode previews
- accessibility-size previews
- regular-width previews
- explicit empty/offline/error states

This is not a claim that manual physical-device or VoiceOver QA is complete. Those remain release gates.

## Swift repository boundary — merged in PR #6

Current application boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Current data source:

`InMemoryFamilyRepository`

Planned production data source:

`SupabaseFamilyRepository`

New source files:

- `prototype/FamilyLifePrototype/Data/FamilyRepository.swift`
- `prototype/FamilyLifePrototype/Data/InMemoryFamilyRepository.swift`
- `prototype/FamilyLifePrototype/Data/FixtureTextExtractionService.swift`

`FamilyRepository` currently exposes:

- `currentSnapshot()`
- `ingestText(...)`
- `confirmReviewedProposals(...)`
- `setPlanItemCompleted(...)`

`DemoStore` remains observable UI state but delegates ingestion, confirmation and completion persistence-like operations to the repository.

The deterministic `FixtureTextExtractionService` is explicitly not AI. It recognizes the locked school-letter fixture and produces the four expected proposals so the data/review contract can be exercised without network credentials.

Optimistic task completion now rolls back only the local previous completion value if repository persistence fails.

## Domain/provenance additions

Added:

- `ProposalReviewStatus`: proposed / confirmed / rejected
- `ActionProposal.reviewStatus`
- `PlanItem.sourceProposalID`

`sourceProposalID` is the application-level idempotency/provenance key matching the database contract.

## Supabase SQL contract — source controlled, NOT yet database-validated

Backend contract doc:

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

Important invariants / security decisions:

- RLS enabled on client-exposed collaborative tables.
- Multiple children/guests without authenticated `user_id` are allowed in one household.
- `(household_id, user_id)` is unique only when `user_id` is non-null.
- private membership helpers use restricted `SECURITY DEFINER` with empty `search_path`.
- authenticated clients receive only the column update surface required by the product.
- processing status, review finalization and canonical provenance are not freely client-writable.
- machine extraction rows remain trusted-server-owned.
- direct plan-item provenance must resolve to source/proposal in the same household.

## Atomic proposal confirmation contract

RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Current source-controlled behavior:

1. resolve the source household
2. require current authenticated owner/adult membership
3. verify every requested proposal belongs to that source
4. reject excluded/rejected/unresolved proposals
5. create/reuse one canonical `plan_item` per proposal
6. use unique `source_proposal_id` as idempotency boundary
7. copy only same-household proposal assignees
8. mark proposal confirmed
9. mark source partial while proposals remain open, otherwise done
10. retry returns/reuses existing canonical item rather than duplicating it

The final form is `SECURITY DEFINER` only because it owns writes to server-controlled review/provenance/status columns; it retains explicit user/household checks, an empty `search_path`, and restricted `EXECUTE` permission.

## pgTAP security/contract tests — written, NOT yet executed

Test file:

`supabase/tests/database/family_core_rls.test.sql`

Current 12 assertions cover:

- core tables exist
- multiple no-login child profiles are allowed
- household A cannot read household B rows
- unresolved proposal confirmation fails
- valid confirmation succeeds
- confirmation retry succeeds
- confirmation retry creates only one canonical plan item
- child role does not receive adult household-management permission

The test plan count was statically corrected from 11 to 12 during the pass.

### Validation boundary

**Validated now:**

- repository/data Swift refactor compiles in the real GitHub macOS/Xcode gate
- exact final backend branch head `ab68d1f25883886715d7892d6b90a5578c193924`
- CI run `32184778802` completed SUCCESS
- PR #6 was merged only after exact-head green CI
- merge commit `cb0a3f99f749ee46ce8b3b6d39c79d50bfe3341b`

**Not yet validated:**

- migrations applied to a clean Supabase/Postgres database
- pgTAP tests executed successfully
- live Supabase Auth
- live Data API RLS behavior
- live confirmation RPC behavior
- Realtime
- private Storage
- OCR
- real AI provider

The current execution environment did not provide an initialized Supabase CLI/Postgres/Docker stack, so the SQL suite could not be honestly executed here. Do not call the database backend green until migrations apply and `supabase test db` passes against a real/local database.

## Signature text vertical slice

Locked source:

German class-trip school letter.

Expected proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

Current in-memory repository path:

1. Inbox -> `Text-Beispiel importieren`
2. `DemoStore.ingestSchoolLetterText()`
3. `FamilyRepository.ingestText()`
4. deterministic fixture extraction
5. source becomes reviewable
6. `Import prüfen`
7. user resolves child ambiguity / edits fields
8. `FamilyRepository.confirmReviewedProposals()`
9. canonical `PlanItem` values are created with source/proposal provenance
10. source becomes partial/done

The next milestone is to make this exact visible flow operate against real Supabase data without changing the UX contract.

## CI / compiler history

- run `32180375921` — failed on Swift `foregroundStyle` inference; fixed
- run `32180561109` — SUCCESS; PR #4 merged
- run `32182317924` — failed on iPad sidebar selection API; fixed
- run `32182408384` — SUCCESS
- run `32182627951` — SUCCESS; PR #5 merged
- backend refactor intermediate run `32184322336` — SUCCESS
- backend intermediate run `32184431611` — SUCCESS but exposed one Swift warning in completion rollback
- completion rollback was refactored to use the saved local previous state
- final backend exact-head run `32184778802` — SUCCESS
- PR #6 squash-merged to `cb0a3f99f749ee46ce8b3b6d39c79d50bfe3341b`

## Brand state

Public name remains open and must not block implementation.

`Family Life OS` is an internal codename only. Do not lock it as public positioning.

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
- family chat/social network
- live GPS
- video/audio calling
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic mailbox surveillance
- autonomous real-world bookings/calls
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

## Immediate next steps

1. Initialize/connect a Supabase development environment.
2. Apply all migrations to a clean database.
3. Run `supabase test db` and fix every migration/RLS/pgTAP failure before remote deployment.
4. Implement `SupabaseFamilyRepository` against the now-proven schema.
5. Add only the minimum Auth/household setup required to prove shared data securely.
6. Run the exact school-letter text path against the real database: source -> proposals -> review -> atomic confirmation -> Today/Plan refresh.
7. Only after the text contract is green, add private Storage + photo/PDF ingestion + OCR.
8. Add real AI extraction only after structured-output validation and explicit review remain intact.
9. Perform physical iPhone/iPad + manual VoiceOver QA before TestFlight readiness claims.
10. Move to an app-specific repository when repository creation becomes available.
11. Update this state and the central App Factory state after every major pass.

## Handoff rule

Before continuing this app in a new chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE, UI_FIXTURES, BACKEND_CONTRACT and the prototype README. Inspect current `main` and CI state before changing code. Continue with real Supabase migration/test validation and then `SupabaseFamilyRepository`; do not jump to OCR/AI before the text database contract is green.