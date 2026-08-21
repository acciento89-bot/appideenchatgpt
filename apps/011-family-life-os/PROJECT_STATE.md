# Family Life OS — Project State

Last updated: 2026-08-21
Status: COMPLETE V1 BASELINE + TRUST/TIMEZONE HARDENING + DURABLE OFFLINE QUEUE GREEN IN CI
Internal portfolio slot: #011
Public brand/name: NOT LOCKED
Implementation location: `apps/011-family-life-os/`

> This file is the app-specific single source of truth. Continue from this file, not from stale chat summaries. Older checkpoints remain in Git history.

## Executive checkpoint

Family Life OS has moved well beyond the old Build-2 hosted-text prototype checkpoint.

The current product direction is a complete Family Inbox/workflow system with this locked trust boundary:

**Capture -> Understand -> Review -> Act -> Follow up**

The complete-v1 baseline is already merged on `main`. Two follow-up hardening PRs are intentionally still unmerged:

- PR #31 — timezone + proposal-review trust hardening
- PR #34 — durable offline source queue + idempotent retry + processing lease + automatic connectivity resume, stacked on PR #31

Neither PR #31 nor PR #34 has been promoted to the hosted Supabase backend yet.

## Current Git / PR state

### PR #31 — timezone and review trust boundary

Branch:

`agent/family-life-os-timezone-hardening`

PR:

`#31 Family Life OS: harden timezone and review trust boundary`

Validated head:

`29b942fca118792146acc6079a0fe07697a3bd8d`

State:

- draft/open
- CI green
- not merged
- Edge Function changes not deployed live

Key fixes:

- preserve backend `unresolved_fields` instead of collapsing every blocker into member assignment
- member/date/time/due blockers resolve independently
- confirmation remains blocked until all unresolved fields are genuinely resolved
- deterministic extraction uses the household IANA timezone
- no invented 09:00 when source text contains a date but no time
- provider timestamps require explicit offset or `Z`
- unresolved proposals do not receive reminder suggestions
- DST summer/winter/gap/overlap regression coverage

### PR #34 — durable offline source queue

Branch:

`agent/family-life-os-offline-queue`

PR:

`#34 Family Life OS: durable offline source queue`

Base:

`agent/family-life-os-timezone-hardening` / PR #31

Latest fully validated app-code head:

`fd7381e97c349dd282df5b12ffcf68c4bd476538`

Exact green validation on that head:

- Family Life OS Prototype Build run `32455964319` / #73 — SUCCESS
- Family Life OS Database Tests run `32455964347` / #57 — SUCCESS
- Family Life OS TestFlight/device validation run `32455964321` / #58 — SUCCESS

The TestFlight/device validation workflow compiled the unsigned iPhone/iPad device target. It did not publish a new Apple build because this repository does not contain App Store Connect signing secrets.

State:

- draft/open
- cleanly stacked on #31
- full Simulator/device/database validation green
- not merged
- migration not deployed live

## Durable offline capture — implemented in PR #34

Every supported source is persisted locally before network work begins:

- text
- photo library / screenshot
- camera
- PDF / document
- voice

Durability behavior:

- queue metadata and binary payload are stored separately under Application Support
- atomic writes
- file protection enabled
- queued item appears immediately in Inbox
- local-only actions are `Jetzt senden` and `Verwerfen`
- queue survives app restart
- sync runs on normal app load, foreground activation and manual Inbox refresh

### Automatic connectivity resume

PR #34 now also uses `NWPathMonitor` through an async stream.

Rules:

- initial online observation does not duplicate normal startup sync
- repeated online observations do not retrigger
- going offline is passive
- a real offline -> online transition automatically resumes the queue
- launching offline and later becoming online automatically resumes
- existing `beginSync()` in-flight guard serializes overlapping Scene/network events

Regression:

`prototype/Tests/ConnectivityResumePolicyRegression.swift`

The complete app compiles green for Simulator and generic iPhone/iPad device targets with this monitor enabled.

## Offline idempotency and household isolation

Each durable source receives a stable client request UUID.

Database hardening in PR #34:

- `source_items.client_request_id`
- tenant-scoped unique idempotency index
- retry-safe source creation
- deterministic Storage path
- retry-safe Storage upsert
- legacy source-creation/finalization signatures remain compatible

Queue ownership:

- each local queue record is bound to the authenticated user ID
- each record is bound to the household ID active when captured
- a different login does not see or upload another user's local queue
- a different household does not inherit another household's queued source
- server rejects an explicit target household the authenticated adult cannot manage
- anonymous role cannot execute the new privileged ingestion signatures

## Processing lease / interrupted Edge response

PR #34 also protects against the hardest retry race: the network response disappears after server-side extraction has already started.

Behavior:

- idempotent queue imports begin in a neutral queued state
- Edge processing establishes the processing lease
- a fresh `processing` state means wait rather than starting a duplicate extraction
- stale processing can be recovered after the lease window
- review/partial/done sources skip duplicate Edge processing

This prevents parallel extraction while still allowing recovery from a crashed or abandoned processing attempt.

The fresh Supabase startup + pgTAP suite is green after this change.

## Complete-v1 baseline already on main

Complete-v1 functionality from the earlier merged integration includes:

- hosted auth and invite acceptance
- household/member management
- Realtime refresh
- photo/camera/screenshot capture
- PDF/document capture
- text capture
- voice recording + transcription
- private Supabase Storage
- image/PDF OCR
- server-side structured extraction + deterministic fallback
- editable `Import prüfen` trust boundary
- source provenance/original-source viewer
- retry/archive lifecycle
- agenda/week Plan
- Plan CRUD
- persisted completion
- optimistic version conflicts
- activity history
- notification preferences/local reminders
- biometric app lock
- StoreKit 2 Family Pro purchase/restore surface
- offline snapshot-cache foundation
- share-extension intake foundation
- release/privacy permissions
- internal diagnostics

Do not regress to the old checkpoint that claimed Realtime, Storage, photo/PDF, OCR or complete-v1 intake were still unimplemented.

## Apple / TestFlight checkpoint

Bundle ID:

`de.kamilunavo.familyprototype`

Apple team:

`TKG684N5GL`

Marketing version used by the current internal line:

`0.1.0`

### Build 2

Build 2 was user-verified on a physical iPhone:

- installed and launched
- completion controls work from Plan and Today
- completion persistence survives restart
- hosted E2E diagnostic passed including cleanup

### Build 3

Build 3 is **already present in App Store Connect/TestFlight history**.

Evidence:

- direct Family workflow run `32365949304` compiled successfully but could not perform a signed upload from `appideenchatgpt` because ASC secrets are not stored there
- protected bridge repo: `acciento89-bot/onemorefloor`
- bridge run `32366765776`
- bridge branch head `3f300e3a70f33d86a73a26195eea0b2f3775a9f9`

Important interpretation of the bridge run:

- archive/preflight/signing preparation succeeded
- the workflow step named `Upload Family Life OS to TestFlight` is intentionally `continue-on-error` and records the real `xcodebuild -exportArchive` exit status separately
- Apple rejected that bridge attempt because build number `3` had **already been uploaded previously**
- exact Apple diagnostic: the bundle version must be higher than the previously uploaded version `3`

Therefore do **not** describe Build 3 as missing or as a failed first upload. The bridge run was a duplicate-build-number attempt against an App Store Connect state that already contained build 3.

Any next Apple upload must use a build number greater than `3`.

## Hosted Supabase checkpoint

Project ref:

`bqctetqraszsvknczjjr`

Region:

`eu-central-1` / Frankfurt

Supabase Swift:

`2.54.1`

Known hosted state:

- project healthy
- collaborative public tables have RLS enabled
- Edge Function `process-family-source` is active with JWT verification
- household locale/timezone confirmed as `de-DE` / `Europe/Berlin`
- publishable key only in iOS client
- service-role/provider secrets remain server-side

Important deployment boundary:

- PR #31 timezone/extraction changes are NOT live yet
- PR #34 idempotency/offline migration is NOT live yet
- do not test the new offline upload protocol against production until its database migration has intentionally been deployed

## Real AI evidence boundary

Do not claim the real provider path has been proven yet.

At the last hosted audit:

- observed `extraction_runs` were fixture runs
- no confirmed OpenAI production extraction run was present
- existence of `OPENAI_API_KEY` was therefore not proven through a real run

The Edge Function can use deterministic rules fallback when provider configuration is absent.

A post-deploy live canary must verify which provider actually ran.

## StoreKit boundary

StoreKit 2 foundation exists in the client:

- Family Pro monthly ID: `de.kamilunavo.family.familypro.monthly`
- Family Pro annual ID: `de.kamilunavo.family.familypro.annual`
- product loading
- current entitlements
- purchase
- restore via `AppStore.sync()`

Do not claim paid IAP release readiness until App Store Connect product configuration and a real sandbox/review purchase path are verified.

## Locked architecture and product rules

- native SwiftUI
- iPhone + intentional iPad adaptation
- iOS/iPadOS 18+
- DACH-first
- Supabase/Postgres + RLS as primary household isolation boundary
- server-side AI only
- no service-role/provider secret in iOS
- source provenance is preserved
- OCR/AI creates editable proposals only
- canonical Plan data requires explicit user confirmation
- ambiguous required values remain blocking; never invent missing date/time/person data

## Immediate promotion sequence

The next safe promotion path is intentionally sequential:

1. Merge PR #31 only after explicit merge authorization.
2. Once #31 is on `main`, retarget/update PR #34 against the new `main` and verify the resulting exact head/merge state.
3. Merge PR #34 only after explicit merge authorization.
4. Deploy PR #31 Edge changes and PR #34 database migration to hosted Supabase only after explicit live-deployment authorization.
5. Run live hosted canaries:
   - timezone canary: `Elternabend am 21.08.2026 um 18:00 Uhr.` must resolve to 18:00 Europe/Berlin, not UTC wall-clock time
   - date-without-time proposal must remain explicitly unresolved, never become fake 09:00
   - offline capture -> network returns -> exactly one canonical source
   - account/household isolation for queued sources
   - interrupted processing response must not create parallel extraction
   - inspect `extraction_runs` provider/model to determine whether OpenAI or rules actually ran
6. Create the next TestFlight build with a build number greater than 3.
7. Perform physical-device offline/online QA and the remaining StoreKit/App Store release gates separately.

## Current non-actions / guardrails

As of this checkpoint:

- PR #31 has NOT been merged
- PR #34 has NOT been merged
- the new Supabase migration has NOT been deployed live
- the timezone-hardened Edge Function has NOT been deployed live
- no new TestFlight build above 3 has been published from these PRs

Do not perform any of those promotion actions without explicit authorization.

## Brand guardrail

`Family Life OS` remains an internal name.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Avoid generic house/checkmark, cartoon-family and robot/AI-sparkle identity.

Final public name still requires current App Store/web + EUIPO/DPMA/domain clearance.

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
4. inspect PR #31 and PR #34 exact heads/statuses
5. treat `fd7381e97c349dd282df5b12ffcf68c4bd476538` as the latest fully validated PR-34 **app-code** checkpoint unless newer code has since passed all gates
6. do not regress to the old Build-2-only roadmap
7. do not say Build 3 is missing: Apple already had build 3 when the bridge retried it
8. do not claim PR #31/#34 behavior is live until the hosted deployment is explicitly performed and verified
9. do not claim real OpenAI extraction is proven until a hosted `extraction_runs` record confirms it
10. preserve the Review trust boundary and household isolation on every future feature pass
