# Family Life OS — Project State

Last updated: 2026-08-21
Status: COMPLETE V1 + PR #31/#34 MERGED + HOSTED BACKEND PROMOTED + BUILD 4 UPLOADED
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this checkpoint, not from stale chat summaries. Older checkpoints remain in Git history.

## Executive checkpoint

Family Life OS is now a complete Family Inbox/workflow baseline with the locked trust boundary:

**Capture -> Understand -> Review -> Act -> Follow up**

The complete-v1 baseline and both release-critical hardening passes are merged on `main`. The source-ingestion migration and timezone/review-hardened Edge Function have also been intentionally promoted to the hosted Supabase project. Build 4 was accepted by App Store Connect/TestFlight upload tooling.

The next unproven boundary is no longer deployment. It is the first real authenticated Build-4/Edge-v2 canary on a physical device.

## Git / promotion state

### PR #31 — timezone and review trust boundary

- PR: `#31 Family Life OS: harden timezone and review trust boundary`
- validated head: `29b942fca118792146acc6079a0fe07697a3bd8d`
- merged to `main`: `0db452c41a4c197cb95d0bb48b9455561435f8d4`
- Prototype / Database / iPhone-iPad validation: GREEN

Key behavior now merged and deployed:

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
- final exact PR head after merging current `main`: `1802a909b27e61ee4ecc5b0ce3d8f9342529d84d`
- exact-head Database Tests: `32464891177` — SUCCESS
- exact-head Prototype Build: `32464891211` — SUCCESS
- exact-head iPhone/iPad TestFlight/device validation: `32464891184` — SUCCESS
- merged to `main`: `1de4a500b15fa733306f75605f817dd10b5fa43b`

Durable capture behavior:

- text/photo/camera/PDF/voice persisted locally before network work begins
- protected atomic local queue under Application Support
- queued sources appear immediately in Inbox
- local actions are `Jetzt senden` / `Verwerfen`
- queue survives app restart
- startup, foreground, manual refresh and real offline -> online transitions resume sync
- initial/repeated online observations do not duplicate startup sync
- in-flight guard serializes overlapping sync triggers
- queue record is bound to authenticated user + target household
- stable `clientRequestID` drives server idempotency
- deterministic Storage path/upsert supports retry after a lost response
- fresh processing lease avoids parallel duplicate extraction
- review/partial/done server states skip duplicate processing

## Hosted Supabase — LIVE as of 2026-08-21

Project:

- ref `bqctetqraszsvknczjjr`
- region `eu-central-1` / Frankfurt
- household locale/timezone observed as `de-DE` / `Europe/Berlin`
- Supabase Swift client `2.54.1`

### Migration promoted

Migration `source_ingestion_idempotency` was applied to the hosted project from the merged repository migration:

`supabase/migrations/20260821060000_source_ingestion_idempotency.sql`

Post-deploy verification confirmed:

- `source_items.client_request_id` exists
- tenant-scoped partial unique index exists on `(household_id, client_request_id)`
- `create_source_item(text,text,text,uuid,uuid)` is active
- `finalize_source_upload(uuid,text,text,text,bigint,text,boolean)` is active
- `anon` cannot execute either new privileged RPC
- `authenticated` can execute them
- legacy calls remain compatible through defaults

### Edge Function promoted

Hosted `process-family-source` is now:

- version `2`
- status `ACTIVE`
- `verify_jwt = true`
- schema version `3`

The deployed code includes the timezone helpers, unresolved-field rules, explicit-offset provider validation, reminder suppression while unresolved, and normalized-output timezone metadata.

Provider selection remains server-side:

- `openai` only when `OPENAI_API_KEY` exists
- deterministic `rules` fallback otherwise
- default configured OpenAI model string in code: `gpt-5.6-luna`
- deterministic fallback model marker: `family-rules-v2`

Do not infer from configuration that OpenAI is actually available. A real production run must prove the provider/model.

## Production DB canaries — GREEN / rolled back

A production-database canary was executed inside a transaction and fully rolled back, so it left no test source rows behind.

Verified:

- same `clientRequestID` twice returns the same source
- exactly one source row exists for the idempotency key
- durable text begins `queued`, attempts `0`, no processing lease timestamp
- routing to an unrelated household is rejected
- deferred file finalize can be repeated without duplicating the attachment
- deferred finalize remains `queued`, attempts `0`, no processing timestamp
- retry after a simulated fresh processing start still resolves to the same source

This proves the hosted DB/RPC/idempotency layer. It does **not** substitute for a real JWT HTTP invocation of Edge Function v2.

## Remaining live Edge/provider evidence boundary

No authenticated Edge-v2 invocation was generated by the deployment tooling itself.

After deployment, `extraction_runs` still contained only the older fixture evidence:

- provider `fixture`
- model `school-letter-v1`
- schema version `1`

Therefore, as of this checkpoint:

- do not claim a real `openai` run occurred
- do not claim `OPENAI_API_KEY` exists
- do not claim the `rules` fallback ran on Edge v2 either
- do not claim the 18:00 timezone or missing-time behavior is production-runtime proven until Build 4 creates a real v2 extraction run

## Security advisor boundary

The hosted security advisor still reports:

- `rpc_run_hosted_e2e` as security-definer
- `create_source_item` as security-definer
- `finalize_source_upload` as security-definer
- leaked-password protection disabled

For the two new ingestion RPCs, execution is explicitly revoked from `public`/`anon`, granted to `authenticated`, and the functions enforce active adult/owner household membership plus household permission checks. The advisor warnings themselves remain present and must not be described as fixed.

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

### Build 4 — upload SUCCESS

The app repository was not source-bumped solely for the build number. The protected bridge overrides `CURRENT_PROJECT_VERSION` during archive.

Bridge:

- repo `acciento89-bot/onemorefloor`
- branch `agent/family-life-os-testflight-bridge`
- bridge commit `bc77c18f5ee5ef65ea2a1822635fc86c8b41fa10`
- workflow run `32466397060`
- upload job `96723790084`
- source ref built: `acciento89-bot/appideenchatgpt` `main`
- app source merge at promotion checkpoint: `1de4a500b15fa733306f75605f817dd10b5fa43b`

Apple exporter evidence:

- `ARCHIVE SUCCEEDED`
- `Upload succeeded`
- `The app was uploaded successfully.`
- `EXPORT SUCCEEDED`
- final bridge status: SUCCESS

Safe claim: **Family Life OS 0.1.0 (4) was successfully uploaded/handed to App Store Connect/TestFlight.**

Do not claim Apple processing or TestFlight visibility until it is actually observed.

## Complete-v1 baseline

Already included before the two hardening passes:

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

Do not claim paid-IAP release readiness until App Store Connect products and a real TestFlight/sandbox purchase/restore path are verified.

## Next physical-device sequence

Do these one at a time after Build 4 becomes visible in TestFlight:

1. Install Build 4 and create a text source exactly: `Elternabend am 21.08.2026 um 18:00 Uhr.`
2. Verify review shows the event at 18:00 Europe/Berlin. Then inspect the resulting live `extraction_runs` provider/model.
3. Only after step 2 is proven, test a date without time and confirm it stays unresolved instead of receiving a fake time.
4. Then test capture while offline -> reconnect -> exactly one source.
5. Then test physical-device household/account isolation and remaining StoreKit/release gates.

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
4. treat PR #31 and #34 as merged, not pending
5. treat the migration and Edge Function v2 as hosted/live, not pending deployment
6. treat Build 4 as uploaded successfully but processing/visibility as unconfirmed until observed
7. do not say Build 3 is missing
8. do not claim real OpenAI/rules provider execution until a schema-v3 hosted `extraction_runs` record proves it
9. preserve the Review trust boundary and household isolation on every future feature pass
10. next physical gate is Build-4 installation followed by the 18:00 Europe/Berlin canary