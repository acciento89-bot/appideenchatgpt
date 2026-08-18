# Family Life OS — Technical Architecture v0.1

Status: FOUNDATION DIRECTION
Date: 2026-08-18

## 1. Architecture goals

The architecture must support the product's differentiator without turning v1 into infrastructure work.

Priorities:

1. trustworthy household isolation
2. fast native iOS experience
3. simple collaborative sync
4. safe attachment handling
5. server-side AI processing
6. source provenance
7. clean path to iPad and later Android/web if justified
8. EU-first data residency

## 2. Client

### Native Apple client

- SwiftUI
- iOS/iPadOS 18+ deployment target direction
- iOS 26+ Liquid Glass enhancements behind availability checks
- Swift concurrency (`async/await`)
- Observation (`@Observable`) for reference state where useful
- `NavigationStack` per top-level section
- adaptive iPad layouts, including `NavigationSplitView` where appropriate

### Local persistence/cache

Use a local cache for confirmed household data and queued mutations so the core plan remains usable during transient network loss.

Implementation choice to validate during scaffold:

- SwiftData for app-owned local cache/fixtures where it cleanly fits
- do not make SwiftData the source of truth for shared household data

Canonical collaborative data lives on the backend.

## 3. Backend direction — Supabase

Selected foundation direction: **Supabase** for the first implementation.

Reasons:

- managed Postgres
- first-party Auth, Storage and Realtime building blocks
- official Swift client/SwiftUI guidance
- Row Level Security suitable for household isolation
- Central EU / Frankfurt deployment option
- Edge/server functions provide a clean place for AI orchestration and secrets
- lower v1 infrastructure burden than hand-building auth, storage, realtime and APIs separately

This is an implementation direction, not an irreversible vendor lock. Domain/service boundaries in the app should avoid coupling view code directly to Supabase queries.

## 4. Region

Provision production/staging in a European region, preferably **Central EU (Frankfurt)** for DACH-first latency/data-residency goals.

Do not claim legal/compliance guarantees solely from selecting an EU region. GDPR obligations still include contracts, subprocessors, retention, lawful basis, deletion/export handling and privacy disclosure.

## 5. Security model

### Core rule

Every collaborative row must belong to a household either directly or through a relation that can be securely resolved to household membership.

Never rely on client-side filtering for isolation.

### Row Level Security

Enable RLS for every client-exposed household table before granting authenticated client access.

Policies should verify current authenticated user membership and role.

Conceptual helper:

`is_household_member(auth.uid(), household_id)`

Role-aware helper:

`household_role(auth.uid(), household_id)`

Sensitive actions such as invite management, role changes and destructive household actions require stricter role checks.

### Service role

Service-role credentials are server-side only.

Never ship:

- service-role keys
- AI provider secrets
- privileged storage credentials

inside the iOS app.

## 6. Authentication

### Adult MVP

Preferred sign-in options:

- Sign in with Apple
- email magic link / OTP fallback if needed

Avoid password-heavy onboarding unless necessary.

### Household onboarding

First adult creates household.

Additional adults join using a server-generated invite token/link with expiration and one-time/limited use semantics.

### Child/guest accounts

Data model supports them from day one, but full independent login can be deferred.

Never model children as normal unrestricted authenticated adults and attempt to remove access only in UI.

## 7. Initial relational model

### `profiles`

- `id` UUID = auth user id where applicable
- `display_name`
- `avatar_path`
- timestamps

### `households`

- `id`
- `name`
- `created_by`
- timestamps

### `household_members`

- `id`
- `household_id`
- optional `user_id`
- `display_name`
- `role` enum-like value: owner/adult/child/guest
- `accent_key`
- `avatar_path`
- `invite_status`
- timestamps

Important: a child/guest can exist as a household member without an authenticated `user_id`.

### `source_items`

Raw family inbox item.

Fields:

- `id`
- `household_id`
- `created_by_member_id`
- `source_type`: image/pdf/text/voice/share
- `display_title`
- `original_text` where applicable
- `storage_path` where applicable
- `processing_status`
- `processing_error_code`
- `created_at`
- `processed_at`
- retention/deletion metadata

### `extraction_runs`

Auditable machine-processing attempt.

- `id`
- `source_item_id`
- processing model/provider metadata suitable for debugging/cost tracking
- normalized output JSON
- status
- timestamps

Do not expose sensitive chain-of-thought or provider-internal reasoning. Store only product-relevant structured results/log metadata.

### `action_proposals`

Editable extracted candidate before confirmation.

- `id`
- `source_item_id`
- `extraction_run_id`
- proposal type
- title
- candidate start/end/due date
- amount/currency where relevant
- candidate assignees
- location
- notes
- unresolved fields JSON
- include state
- review state

### `plan_items`

Canonical household event/task/deadline/payment/preparation abstraction for v1.

Fields:

- `id`
- `household_id`
- `kind`: event/task/deadline/payment/preparation
- `title`
- `starts_at`
- `ends_at`
- `due_at`
- `all_day`
- `location`
- `amount_minor`
- `currency`
- `notes`
- `status`
- `created_by_member_id`
- `source_item_id` nullable for provenance
- `source_proposal_id` nullable
- timestamps

### `plan_item_assignees`

Many-to-many plan item to household member.

### `reminders`

- `id`
- `plan_item_id`
- target member/user
- trigger time/offset
- delivery state

### `household_invites`

- secure token hash, not raw reusable token where avoidable
- household
- intended role
- created by
- expiration
- redemption metadata

## 8. AI ingestion pipeline

### Never call model provider directly from iOS with a secret key

Pipeline:

1. iOS creates `source_item`
2. attachment uploads to private storage if applicable
3. server function validates household access
4. server obtains signed/private source content
5. text extraction/pre-processing runs as required
6. model receives minimum necessary content and a strict structured-output schema
7. normalized proposals are validated server-side
8. `action_proposals` are stored
9. client receives completion via polling/realtime/event refresh
10. user reviews
11. confirmation transaction creates canonical `plan_items`

### Structured output

The model must output a schema, not prose that the client heuristically parses.

Example conceptual result:

- source summary
- proposals array
- type
- title
- temporal fields
- persons mentioned
- amount
- location
- reminder suggestion
- required clarification fields

### AI safety/trust constraints

- do not infer a child/person identity when evidence is weak; return unresolved assignment
- do not fabricate dates/times
- preserve source text references/offsets when feasible for traceability
- high-impact medical/legal interpretation is outside scope
- extraction output is proposal data, not authoritative truth

## 9. Attachment storage

Use private object storage.

Storage path concept:

`households/<household-id>/sources/<source-id>/<filename>`

Rules:

- no public buckets for family documents
- access through authenticated policies or short-lived signed URLs
- validate MIME type and size
- strip/normalize dangerous filenames
- server-side processing may generate a normalized preview, but original source remains preserved according to retention settings

## 10. Privacy / retention direction

MVP must expose understandable controls, not bury them in legal text.

Provisional defaults to validate legally/product-wise:

- users can delete raw source after extraction while optionally retaining confirmed plan items
- deleting a source clearly explains provenance loss
- account/household deletion starts complete deletion workflow
- AI/provider retention settings must be configured to minimize external retention where available
- telemetry must avoid raw family-document content

Do not log full source documents to generic application logs.

## 11. Realtime / sync

Realtime is useful for:

- newly confirmed plan items
- assignment changes
- completion state
- household/member changes
- Inbox processing status where practical

The UI must remain correct if realtime delivery is delayed; normal refresh/fetch remains authoritative.

## 12. Push notifications

Use APNs via a server-side notification service/function.

Store device push tokens associated with authenticated users/devices, not merely household members without login.

Notification generation uses confirmed canonical plan/reminder data only.

Do not send sensitive source-document text in lock-screen notifications by default.

## 13. App architecture boundaries

Suggested modules/layers:

### App shell

- navigation
- session
- dependency wiring

### Domain

- Household
- Member
- SourceItem
- ActionProposal
- PlanItem
- Reminder

### Features

- Today
- Inbox
- ImportReview
- Plan
- Family
- Account/Settings

### Services

- AuthService
- HouseholdRepository
- InboxRepository
- PlanRepository
- UploadService
- NotificationService

Views do not execute raw Supabase queries directly.

## 14. First executable slice — backend contract

For the prototype, implement only what is needed for:

1. authenticated adult/session fixture or dev sign-in
2. one household
3. 2–4 household members
4. source item creation
5. text fixture ingestion first
6. proposal storage/retrieval
7. review edit/confirm
8. transactional conversion to plan items
9. Today/Plan fetch
10. provenance fetch

Photo/PDF upload can enter immediately after the text fixture proves the data path.

## 15. Testing gates

### Data/security

- user in household A cannot query household B rows
- guest role cannot mutate adult-only data
- expired invite fails
- source signed URL expires
- deleted membership immediately loses household access

### Sync

- two adult clients see confirmed plan change
- offline queued task completion reconciles cleanly
- duplicate confirm request does not create duplicate plan items

### AI

- ambiguous date returns unresolved field
- source with no actionable information returns zero proposals cleanly
- malformed model output fails validation without corrupting canonical data
- retry creates a new extraction run rather than overwriting audit history

## 16. Current decisions locked by this document

- native SwiftUI client
- iOS/iPadOS 18+ direction
- Supabase foundation backend
- EU/Frankfurt project region preference
- Postgres + RLS as the primary data security boundary
- private object storage
- server-side AI only
- proposal-before-confirmation trust model
- source provenance retained
- canonical shared data belongs to backend, not local-only SwiftData

## 17. Still open

- exact AI provider/model
- OCR/document extraction implementation details
- exact privacy retention periods
- production email/OTP provider configuration
- push provider implementation details
- calendar interoperability scope
- billing entitlement backend design
- later Android/web strategy