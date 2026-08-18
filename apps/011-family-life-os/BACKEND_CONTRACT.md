# Family Life OS — Backend Contract v0.1

Status: IMPLEMENTATION CONTRACT / NOT YET DEPLOYED
Date: 2026-08-18

This document defines the first backend boundary for candidate #011. It intentionally proves the text-ingestion path before adding photo/PDF Storage, OCR or a real AI provider.

## 1. Core rule

The iOS UI must not treat local view state as canonical collaborative household data.

Current boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Prototype implementation:

`InMemoryFamilyRepository`

Planned production implementation:

`SupabaseFamilyRepository`

The view layer must not contain raw Supabase queries.

## 2. First production data path

The first real vertical slice must prove:

1. authenticated adult belongs to a household
2. client creates a plain-text `source_item`
3. trusted server processing produces structured `action_proposals`
4. client reads proposals through the repository
5. user edits/reviews them in `Import prüfen`
6. unresolved required fields block confirmation
7. accepted proposals are transactionally converted to canonical `plan_items`
8. `plan_item_assignees` are copied from proposal assignments
9. every canonical item retains `source_item_id` and `source_proposal_id`
10. a repeated confirmation request does not create duplicate plan items
11. Today/Plan refresh from canonical repository data

## 3. Client-owned operations

Authenticated adult clients may:

- read their household and members
- create text/source records for their own active adult membership
- read source processing state
- read extraction runs relevant to their household
- read/edit reviewable proposals
- edit proposal assignments within the same household
- invoke the proposal-confirmation RPC
- read/create/edit canonical plan items allowed by household role
- complete tasks

The client must not insert trusted machine extraction runs or machine-generated proposal rows directly.

## 4. Server-owned operations

Trusted Edge/server processing owns:

- validating uploaded/imported source content
- OCR/document parsing later
- AI provider calls later
- inserting `extraction_runs`
- inserting initial machine-generated `action_proposals`
- validating structured extraction output
- provider/model/cost/debug metadata that is appropriate to retain

Provider secrets and service-role credentials never ship in the app.

## 5. Relational tables

### `households`

Shared household identity, locale and timezone.

### `household_members`

Represents both authenticated adults and people without login accounts.

Important invariant:

- `(household_id, user_id)` is unique only when `user_id` is non-null
- multiple children/guests without a login are allowed in one household

### `source_items`

Raw Inbox source metadata and original text/storage reference.

Statuses:

- queued
- uploading
- processing
- review
- partial
- done
- failed

### `extraction_runs`

Auditable trusted processing attempts. Client has read-only access through RLS.

### `action_proposals`

Editable candidate actions before confirmation.

Kinds:

- event
- task
- deadline
- payment
- preparation

Review status:

- proposed
- confirmed
- rejected

`unresolved_fields` is the server/database representation of required ambiguity that still blocks confirmation.

### `action_proposal_assignees`

Many-to-many proposal -> household member assignment.

### `plan_items`

Canonical confirmed household data.

`source_proposal_id` is unique when present. This is the idempotency key that prevents a retry from creating a second canonical item for the same proposal.

### `plan_item_assignees`

Many-to-many canonical item -> household member assignment.

### `reminders`

Delivery schedule for confirmed canonical data only.

## 6. RLS model

Every exposed collaborative table has RLS enabled.

Private policy helpers:

- `private.is_household_member(household_id)`
- `private.can_manage_household(household_id)`
- `private.is_household_owner(household_id)`
- `private.is_current_user_member(member_id, household_id)`

They are `SECURITY DEFINER` only to perform membership lookup without recursive policy evaluation. Their `search_path` is explicitly empty and execution is restricted.

The `private` schema is not intended to be exposed through the Supabase Data API.

Authorization meaning:

- owner: household administration + shared data management
- adult: shared source/plan management
- child: read access to household data according to future product scoping, but no adult-management permission
- guest: architecture placeholder; permissions must be tightened before public guest access is enabled

The current v0.1 RLS model is deliberately conservative for mutations.

## 7. Atomic confirmation RPC

Function:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Behavior:

1. resolve source household under RLS
2. require active owner/adult permission
3. require every requested proposal to belong to the source
4. reject excluded/rejected/unresolved proposals
5. create one canonical `plan_item` per accepted proposal
6. use unique `source_proposal_id` as idempotency boundary
7. copy proposal assignments into `plan_item_assignees`
8. mark proposals confirmed
9. mark source `partial` while other proposals remain open, otherwise `done`
10. on retry, return/reuse the existing canonical plan item instead of duplicating it

The function runs as `SECURITY INVOKER`, so normal role/RLS boundaries remain active.

## 8. Swift repository contract

`FamilyRepository` currently exposes:

- `currentSnapshot()`
- `ingestText(...)`
- `confirmReviewedProposals(...)`
- `setPlanItemCompleted(...)`

`DemoStore` is still the observable UI state container, but it delegates persistence-like operations to the repository.

`InMemoryFamilyRepository` proves the behavior without credentials/network dependency.

`FixtureTextExtractionService` is deterministic and recognizes only the locked school-letter fixture. It is explicitly not presented as AI.

A future `SupabaseFamilyRepository` must implement the same user-visible behavior while translating it to Supabase Auth/Data API/RPC operations.

## 9. Text fixture path now represented in code

From Inbox:

`Text-Beispiel importieren`

Flow:

1. `DemoStore.ingestSchoolLetterText()` creates a `TextIngestionRequest`
2. `FamilyRepository.ingestText()` creates a text source
3. deterministic fixture extraction produces four proposals
4. source enters `review`
5. new source opens in `Import prüfen`
6. user resolves the ambiguous child and may edit fields
7. `DemoStore.confirmSelectedProposals()` delegates confirmation to the repository
8. repository creates canonical plan items and records proposal provenance

This proves the UI/repository contract before a live backend is connected.

## 10. Database tests

pgTAP test file:

`supabase/tests/database/family_core_rls.test.sql`

Coverage currently includes:

- core tables exist
- multiple no-login child profiles are allowed
- household A cannot read household B rows
- unresolved proposal confirmation fails
- valid proposal confirmation succeeds
- repeated confirmation succeeds without creating a duplicate plan item
- child role does not receive adult-management permission

These tests are source-controlled but are **not yet recorded as executed successfully**. They require a Supabase local/linked database with the migrations applied.

## 11. Current validation boundary

What is currently validated:

- Swift UI compiled green before this backend pass
- backend design is represented as versioned SQL migrations
- repository boundaries are implemented in Swift
- deterministic text ingestion can be exercised without network credentials

What is NOT yet validated:

- migrations applied successfully to a real/local Supabase Postgres instance
- pgTAP tests executed successfully
- Supabase Auth session flow
- live RLS behavior over the Data API
- live RPC behavior
- Realtime
- Storage
- OCR
- real AI provider

Do not label the Supabase backend as green until migrations + pgTAP tests actually pass against Postgres.

## 12. Next backend step

1. compile the refactored Swift prototype in CI
2. initialize/connect a Supabase development environment
3. apply migrations from a clean database
4. run `supabase test db`
5. fix every migration/RLS/test failure before remote deployment
6. implement `SupabaseFamilyRepository`
7. prove the exact school-letter text path against the real database
8. only then add private Storage/photo/PDF/OCR
9. real AI extraction comes after the structured contract is proven
