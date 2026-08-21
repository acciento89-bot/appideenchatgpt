# Family Life OS — Project State

Last updated: 2026-08-21
Status: COMPLETE V1 + PR #31/#34/#40 MERGED + HOSTED BACKEND LIVE + BUILD 4 PHYSICALLY VERIFIED + OPENAI LIVE
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this checkpoint, not from stale chat summaries. Older checkpoints remain in Git history.

## Executive checkpoint

Family Life OS is a complete Family Inbox/workflow baseline with the locked trust boundary:

**Capture -> Understand -> Review -> Act -> Follow up**

The complete-v1 baseline and the release-critical hardening passes are merged on `main`. The source-ingestion migration and current Edge Function are live in hosted Supabase. Build 4 is visible in TestFlight, installed on a physical iPhone, and has now exercised the real production backend.

The previously unproven provider/runtime boundary is closed:

- deterministic fallback `family-rules-v3` has run successfully in production
- OpenAI has run successfully in production with `gpt-5.6-luna`
- Europe/Berlin wall-clock handling is physically and server-side verified
- missing-time proposals remain explicitly unresolved with no fabricated time/reminder
- durable offline capture, restart persistence and automatic reconnect sync have been physically exercised

The next release gates are physical household/account isolation plus StoreKit/App Store purchase/restore readiness.

## Git / promotion state

### PR #31 — timezone and review trust boundary

- PR: `#31 Family Life OS: harden timezone and review trust boundary`
- validated head: `29b942fca118792146acc6079a0fe07697a3bd8d`
- merged to `main`: `0db452c41a4c197cb95d0bb48b9455561435f8d4`
- Prototype / Database / iPhone-iPad validation: GREEN

Merged behavior:

- preserve complete backend `unresolved_fields`
- member/date/time/due blockers resolve independently
- confirmation remains blocked until required ambiguities are resolved
- deterministic extraction uses the household IANA timezone
- no fabricated 09:00 for a source that contains a date but no time
- provider timestamps without `Z` or an explicit UTC offset are rejected
- unresolved proposals do not receive reminder suggestions
- Europe/Berlin summer/winter/DST gap/overlap regressions are covered

### PR #34 — durable offline source queue

- PR: `#34 Family Life OS: durable offline source queue`
- final exact PR head: `1802a909b27e61ee4ecc5b0ce3d8f9342529d84d`
- Database Tests: `32464891177` — SUCCESS
- Prototype Build: `32464891211` — SUCCESS
- iPhone/iPad TestFlight/device validation: `32464891184` — SUCCESS
- merged to `main`: `1de4a500b15fa733306f75605f817dd10b5fa43b`

Durable capture behavior:

- text/photo/camera/PDF/voice persisted locally before network work begins
- protected atomic local queue under Application Support
- queued sources appear immediately in Inbox
- local actions are `Jetzt senden` / `Verwerfen`
- queue survives app restart
- startup, foreground, manual refresh and real offline -> online transitions resume sync
- stable `clientRequestID` drives server idempotency
- queue record is bound to authenticated user + target household
- deterministic Storage path/upsert supports retry after lost response
- fresh processing lease avoids parallel duplicate extraction
- review/partial/done states skip duplicate processing

### PR #40 — dotted-date clock parser regression

The first physical Build-4 fallback canary exposed a real parsing bug:

`Elternabend am 21.08.2026 um 18:00 Uhr.`

was initially parsed by `family-rules-v2` as **21:08 local** because the generic time regex consumed `21.08.` from the date.

Fix:

- dedicated `extractClockTime` helper
- `HH:mm` preferred
- dotted clock syntax only accepted with clock context such as `Uhr` / `um`
- bare dotted dates are never treated as clock times
- regression coverage for `18:00 Uhr`, `18.00 Uhr`, `18 Uhr`, and date-only input
- fallback marker bumped to `family-rules-v3`

Git evidence:

- PR: `#40 Family Life OS: fix dotted-date clock parsing`
- head: `8df3e5fc5a1cd1ae67d0889ba0732772dd183276`
- Prototype Build run `32473333689` — SUCCESS
- Database Tests run `32473333746` — SUCCESS
- merged to `main`: `ad531aef1f2c78b6d04df1a2217353157001e824`

The server-side fix was deployed before merge for the physical canary; repository and production are now aligned.

## Hosted Supabase — LIVE

Project:

- ref `bqctetqraszsvknczjjr`
- region `eu-central-1` / Frankfurt
- household locale/timezone observed as `de-DE` / `Europe/Berlin`
- Supabase Swift client `2.54.1`

### Migration promoted

Migration `source_ingestion_idempotency` is live from:

`supabase/migrations/20260821060000_source_ingestion_idempotency.sql`

Verified:

- `source_items.client_request_id` exists
- tenant-scoped partial unique index exists on `(household_id, client_request_id)`
- `create_source_item(text,text,text,uuid,uuid)` is active
- `finalize_source_upload(uuid,text,text,text,bigint,text,boolean)` is active
- `anon` cannot execute either new privileged RPC
- `authenticated` can execute them
- legacy calls remain compatible through defaults

### Edge Function promoted

Hosted `process-family-source` is now:

- version `3`
- status `ACTIVE`
- `verify_jwt = true`
- schema version `3`

Version 3 contains the timezone/review hardening plus the PR-40 clock parser fix.

Provider selection is server-side:

- `openai` when `OPENAI_API_KEY` exists
- deterministic `rules` fallback otherwise
- configured OpenAI model: `gpt-5.6-luna`
- fallback marker: `family-rules-v3`

Unlike the older checkpoint, both provider paths are now proven by real production runs.

## Production DB / runtime canaries

### DB-only idempotency canary — GREEN / rolled back

A transaction-scoped production DB canary was fully rolled back and proved:

- same `clientRequestID` twice returns the same source
- exactly one source row exists for the idempotency key
- durable text begins `queued`, attempts `0`, no processing lease timestamp
- routing to an unrelated household is rejected
- deferred file finalize can be repeated without duplicating the attachment
- retry after a simulated fresh processing start still resolves to the same source

### Physical Build-4 fallback canary — bug found then fixed

Initial real run:

- provider `rules`
- model `family-rules-v2`
- source: `Elternabend am 21.08.2026 um 18:00 Uhr.`
- bad stored value: `2026-08-21T19:08:00Z` = 21:08 Europe/Berlin

After PR-40 fix / Edge v3:

- provider `rules`
- model `family-rules-v3`
- source: `Elternabend am 21.08.2026 um 18:00 Uhr.`
- stored: `2026-08-21T16:00:00Z` = **18:00 Europe/Berlin**
- no unresolved fields
- fallback reminder stored one hour before

### Physical missing-time fallback canary — GREEN

Source:

`Elternabend am 22.08.2026.`

Observed in `Import prüfen`:

- date recognized
- 00:00 shown only as the review placeholder
- explicit `Uhrzeit festlegen` / unresolved-time state
- confirmation blocked while the time is unresolved

Server evidence:

- provider `rules`
- model `family-rules-v3`
- `unresolved_fields = {"time":"required"}`
- `suggested_reminder_at = null`
- canonical placeholder instant corresponds to 00:00 Europe/Berlin on 22.08.2026

### Physical offline queue canary — GREEN

While offline, a text source was captured and immediately appeared as:

- `Wartet auf Upload`
- `lokal gesichert`

Verified by the user:

- source survives app termination/relaunch while offline
- reconnecting automatically resumes sync without manual send
- processing reaches `Import prüfen`

Server inspection of three separately user-created `Zahnarzt am 24.08.2026 um 15:30 Uhr.` test sources showed:

- three intentionally distinct `client_request_id` values
- each request ID had exactly one server row
- each extraction succeeded with `family-rules-v3`
- each stored `13:30Z` = 15:30 Europe/Berlin

Those three rows were **not** a duplicate-ingestion bug; the user intentionally created the source three times.

### Physical OpenAI explicit-time canary — GREEN

After the user configured `OPENAI_API_KEY` in hosted Supabase secrets:

Source:

`Elternabend am 26.08.2026 um 18:30`

Live run:

- provider `openai`
- model `gpt-5.6-luna`
- schema version `3`
- status `succeeded`
- stored `2026-08-26T16:30:00Z` = **18:30 Europe/Berlin**
- no unresolved fields

This is the first direct production proof that OpenAI is configured and active for Family Life OS.

### Physical OpenAI missing-time canary — GREEN

Source:

`Elternabend am 27.08.2026`

Live run:

- provider `openai`
- model `gpt-5.6-luna`
- schema version `3`
- status `succeeded`
- `unresolved_fields = {"time":"required"}`
- `suggested_reminder_at = null`
- placeholder instant corresponds to 00:00 Europe/Berlin on 27.08.2026

Therefore the review trust boundary is proven on both the deterministic fallback and OpenAI provider path.

## Security advisor boundary

The hosted security advisor still reports:

- `rpc_run_hosted_e2e` as security-definer
- `create_source_item` as security-definer
- `finalize_source_upload` as security-definer
- leaked-password protection disabled

For the two ingestion RPCs, execution is explicitly revoked from `public`/`anon`, granted to `authenticated`, and the functions enforce active adult/owner household membership plus household permission checks.

Do not describe the advisor warnings themselves as fixed.

## Apple / TestFlight checkpoint

Bundle ID:

`de.kamilunavo.familyprototype`

Apple team:

`TKG684N5GL`

Marketing version:

`0.1.0`

### Build 2

User-verified on a physical iPhone:

- installed and launched
- Plan/Today completion controls work
- completion persists across restart
- hosted E2E diagnostic passed including cleanup

### Build 3

Build 3 already existed in App Store Connect. A later protected bridge retry was rejected only because bundle version `3` had already been used. Do not describe Build 3 as missing.

### Build 4 — upload + physical install SUCCESS

The protected bridge overrides `CURRENT_PROJECT_VERSION` during archive, so the app source did not need a source-only build-number bump.

Bridge evidence:

- repo `acciento89-bot/onemorefloor`
- branch `agent/family-life-os-testflight-bridge`
- bridge commit `bc77c18f5ee5ef65ea2a1822635fc86c8b41fa10`
- workflow run `32466397060`
- upload job `96723790084`
- source ref built: `acciento89-bot/appideenchatgpt` `main`
- source checkpoint used for archive: `1de4a500b15fa733306f75605f817dd10b5fa43b`

Apple exporter evidence:

- `ARCHIVE SUCCEEDED`
- `Upload succeeded`
- `The app was uploaded successfully.`
- `EXPORT SUCCEEDED`
- final bridge status: SUCCESS

The user later confirmed Build 4 was visible in TestFlight and installed it on a physical iPhone. Build 4 then completed the production canaries documented above.

No new Apple build is required solely for the PR-40 parser change because that parser executes server-side in the hosted Edge Function. Future app-source releases still use the normal next build number.

## Complete-v1 baseline

Already included before the hardening passes:

- hosted auth + invite acceptance
- household/member management
- Realtime refresh
- photo/camera/screenshot capture
- PDF/document capture
- text capture
- voice recording + transcription
- private Supabase Storage
- image/PDF OCR
- server-side structured extraction + deterministic fallback
- editable `Import prüfen` review boundary
- original-source provenance/viewer
- source retry/archive lifecycle
- agenda/week Plan + Plan CRUD
- persisted completion
- optimistic version conflicts + activity history
- notification preferences/local reminders
- biometric app lock
- StoreKit 2 Family Pro surface/restore
- offline snapshot-cache foundation
- share-extension intake foundation
- release/privacy permissions
- internal diagnostics

Do not regress to a roadmap that says Realtime, Storage, photo/PDF intake, OCR or complete-v1 are still unimplemented.

## StoreKit boundary

Client foundation exists for:

- monthly `de.kamilunavo.family.familypro.monthly`
- annual `de.kamilunavo.family.familypro.annual`
- product loading
- current entitlements
- purchase
- `AppStore.sync()` restore

Paid-IAP release readiness is still **not proven** until App Store Connect products and a real TestFlight/sandbox purchase, relaunch entitlement recovery and Restore path are physically verified.

## Next physical-device sequence

Do these one at a time:

1. Test household/account isolation on the physical Build-4 path, including queued/local source ownership across login or household changes.
2. Verify App Store Connect Family Pro monthly/annual products are correctly configured.
3. Perform a real TestFlight/sandbox Family Pro purchase.
4. Verify entitlement survives relaunch.
5. Verify Restore / `AppStore.sync()` on a clean/relevant state.
6. Finish remaining App Store release metadata/device gates.

## Locked product rules

- native SwiftUI
- intentional iPhone + iPad support
- iOS/iPadOS 18+
- DACH-first
- Supabase/Postgres + RLS as primary household isolation boundary
- server-side AI only
- no service-role/provider secret in iOS
- source provenance preserved
- OCR/AI creates editable proposals only
- canonical Plan data requires explicit user confirmation
- ambiguous required values remain blocking; never invent missing date/time/person data

## Brand guardrail

`Family Life OS` remains internal only.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Final public name still requires current App Store/web + EUIPO/DPMA/domain clearance.

## Canonical docs

- `PRODUCT_SPEC.md`
- `DESIGN_SYSTEM.md`
- `UX_SCREEN_SPEC.md`
- `BRAND_DIRECTION.md`
- `TECH_ARCHITECTURE.md`
- `UI_FIXTURES.md`
- `BACKEND_CONTRACT.md`
- `PROJECT_STATE.md`
- `prototype/README.md`

## Handoff rule

For every continuation/new chat:

1. read `docs/APP_FACTORY_STATE.md`
2. read this file
3. inspect current `main` and any newer Family PRs
4. treat PR #31, #34 and #40 as merged
5. treat migration + Edge Function v3 as hosted/live
6. treat Build 4 as visible, installed and physically exercised
7. do not say Build 3 is missing
8. treat real `family-rules-v3` and `openai` / `gpt-5.6-luna` schema-v3 executions as production-proven
9. preserve the Review trust boundary and household isolation on every future feature pass
10. next physical gates are household/account isolation and StoreKit/App Store purchase/restore QA
