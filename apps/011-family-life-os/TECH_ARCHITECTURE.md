# Family Life OS — Technical Architecture v0.1

Status: FOUNDATION DIRECTION
Date: 2026-08-18

## Architecture goals

Priorities:

1. trustworthy household isolation
2. fast native iOS experience
3. simple collaborative sync
4. safe attachment handling
5. server-side AI processing
6. source provenance
7. clean path to iPad and later Android/web if justified
8. EU-first data residency

## Client

- SwiftUI
- iOS/iPadOS 18+ deployment direction
- iOS 26+ Liquid Glass enhancements behind availability checks
- Swift concurrency (`async/await`)
- Observation (`@Observable`) where useful
- `NavigationStack` per top-level section
- adaptive iPad layouts including `NavigationSplitView`

Use a local cache for confirmed household data and queued mutations so the core plan remains usable during transient network loss. SwiftData may be used for app-owned cache/fixtures where it cleanly fits, but it is not the canonical source of truth for shared household data.

## Backend direction — Supabase

Selected foundation direction: **Supabase** for the first implementation.

Reasons:

- managed Postgres
- Auth, Storage and Realtime building blocks
- official Swift support
- Row Level Security suitable for household isolation
- Central EU / Frankfurt region option
- server/Edge Functions for AI orchestration and secrets
- lower v1 infrastructure burden than building all components separately

This is an implementation direction, not an irreversible vendor lock. View code must not couple directly to backend queries.

## Region

Prefer **Central EU (Frankfurt)** for production/staging. An EU region alone is not a GDPR guarantee; contracts, subprocessors, retention, lawful basis, deletion/export behavior and privacy disclosures still matter.

## Security model

Every collaborative row must belong to a household directly or through a securely resolvable relation. Never rely on client-side filtering for isolation.

Enable RLS on every client-exposed household table before granting authenticated access.

Conceptual helpers:

- `is_household_member(auth.uid(), household_id)`
- `household_role(auth.uid(), household_id)`

Service-role credentials, AI provider secrets and privileged storage credentials are server-side only.

## Authentication

Adult MVP direction:

- Sign in with Apple
- email magic link / OTP fallback if needed

First adult creates a household. Additional adults join through expiring server-generated invites.

Child/guest records may exist without authenticated accounts. Never model children as unrestricted adults and hide permissions only in the UI.

## Initial relational model

### `profiles`

- id = auth user id where applicable
- display_name
- avatar_path
- timestamps

### `households`

- id
- name
- created_by
- timestamps

### `household_members`

- id
- household_id
- optional user_id
- display_name
- role: owner/adult/child/guest
- accent_key
- avatar_path
- invite_status
- timestamps

### `source_items`

Raw Family Inbox item:

- id
- household_id
- created_by_member_id
- source_type: image/pdf/text/voice/share
- display_title
- original_text where applicable
- storage_path where applicable
- processing_status
- processing_error_code
- created_at / processed_at
- retention/deletion metadata

### `extraction_runs`

Auditable processing attempt:

- id
- source_item_id
- model/provider metadata suitable for debugging/cost tracking
- normalized output JSON
- status
- timestamps

Store product-relevant structured output/log metadata only, not provider-internal reasoning.

### `action_proposals`

Editable extracted candidate before confirmation:

- id
- source_item_id
- extraction_run_id
- proposal type
- title
- candidate start/end/due date
- amount/currency
- candidate assignees
- location
- notes
- unresolved fields JSON
- include state
- review state

### `plan_items`

Canonical v1 event/task/deadline/payment/preparation abstraction:

- id
- household_id
- kind
- title
- starts_at / ends_at / due_at
- all_day
- location
- amount_minor / currency
- notes
- status
- created_by_member_id
- source_item_id nullable
- source_proposal_id nullable
- timestamps

### Supporting tables

- `plan_item_assignees`
- `reminders`
- `household_invites`

Invite tokens should be protected/hashed where practical and expire.

## AI ingestion pipeline

Never call a model provider directly from iOS with a secret key.

Pipeline:

1. iOS creates `source_item`
2. attachment uploads to private storage if needed
3. server validates household access
4. server obtains private source content
5. OCR/pre-processing as required
6. model receives minimum necessary content + strict structured schema
7. server validates normalized proposals
8. `action_proposals` are stored
9. client receives completion via refresh/realtime/polling
10. user reviews/edits
11. transactional confirmation creates canonical `plan_items`

AI constraints:

- weak person identity -> unresolved assignment, not guessing
- do not fabricate dates/times
- preserve source traceability when feasible
- no high-impact medical/legal interpretation
- extraction output is proposal data, not authoritative truth

## Attachment storage

Use private object storage.

Path concept:

`households/<household-id>/sources/<source-id>/<filename>`

Rules:

- no public family-document buckets
- authenticated policies or short-lived signed URLs
- validate MIME type and size
- normalize filenames
- preserve original according to retention settings

## Privacy / retention

- raw sources can be deleted while confirmed plan items may be retained, with clear provenance-loss explanation
- household/account deletion starts complete deletion workflow
- minimize AI-provider retention where available
- generic telemetry must not contain raw family-document content
- never log full source documents in ordinary app logs

## Realtime / sync

Useful for confirmed plan items, assignments, completion state, household membership and Inbox processing status. The app must remain correct if realtime delivery is late; normal fetch/refresh remains authoritative.

## Push notifications

Use APNs through a server-side notification path. Device tokens belong to authenticated users/devices. Generate notifications from confirmed canonical data only. Do not expose sensitive source-document text on lock screens by default.

## App architecture boundaries

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

### Services / repositories

- AuthService
- HouseholdRepository
- InboxRepository
- PlanRepository
- UploadService
- NotificationService

Views do not execute raw Supabase queries directly.

## First executable backend contract

Implement only what is required for:

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

Photo/PDF upload follows after the text path proves the data contract.

## Testing gates

Security:

- household A cannot query household B
- guest cannot mutate adult-only data
- expired invite fails
- signed source URL expires
- removed membership loses access immediately

Sync:

- two adult clients see confirmed changes
- offline queued completion reconciles
- duplicate confirmation does not create duplicate plan items

AI:

- ambiguous date returns unresolved field
- no-action source returns zero proposals cleanly
- malformed output fails validation without corrupting canonical data
- retry creates a new extraction run instead of overwriting audit history

## Decisions locked

- native SwiftUI client
- iOS/iPadOS 18+ direction
- Supabase foundation backend
- EU/Frankfurt preference
- Postgres + RLS primary data-security boundary
- private object storage
- server-side AI only
- proposal-before-confirmation trust model
- source provenance retained
- backend is canonical for shared household data

## Still open

- exact AI provider/model
- OCR/document extraction implementation
- privacy retention periods
- production email/OTP configuration
- push implementation details
- calendar interoperability
- billing entitlement backend design
- later Android/web strategy