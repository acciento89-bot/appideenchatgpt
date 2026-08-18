# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS
Repository purpose: Persistent handoff/state repository for the full App Factory so work can continue across chat limits and new conversations without losing decisions or progress.

## Mandatory workflow

1. Build/validate apps sequentially starting with #001 unless the user explicitly selects another candidate.
2. This repository is the central App Factory memory and must be updated after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Each app gets its own repository once implementation starts and repository creation is available.
4. Each app repository must contain `docs/PROJECT_STATE.md` as its app-specific single source of truth.
5. Before continuing work, read this file first and then the selected app's project state.
6. Major source passes must pass CI/regression gates before merge/TestFlight.
7. Keep v1 focused; do not add adjacent features to hide a weak core loop.
8. Do not force subscriptions when lifetime/one-time better matches product economics.
9. Before locking a public name or positioning, re-check current App Store/web and appropriate trademark/domain sources.
10. Never overwrite another candidate's state while updating one workstream.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost/use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — polished MVP green; StoreKit/QA next |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking | Freemium | QUEUED |
| 004 | SubZero | Detect/track subscriptions and recurring costs | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Gift ideas per person/occasion via share sheet | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists, dates | Subscription | QUEUED |
| 008 | BeforeAfter | Guided repeat photography/alignment/comparison | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Fast portrait reaction/high-score game | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | LOCAL SUPABASE DB CONTRACT GREEN / LIVE BACKEND NEXT |

# Portfolio app #001 — KeepMeter

## Repositories / authoritative state

App repo:

`acciento89-bot/keepmeter`

Authoritative app state:

`acciento89-bot/keepmeter/docs/PROJECT_STATE.md`

Current recorded verified checkpoint:

`45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Latest recorded app-state update:

`fb84802c477593f243c5187bc46b5d021cd0ee4d`

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

KeepMeter is deliberately not another receipt/warranty vault or generic cost-per-use calculator. Its differentiation is the combined deadline-aware decision loop.

## Locked implementation decisions

- Native iPhone utility.
- SwiftUI + SwiftData.
- iOS 17+.
- Local-first; no account/backend for core v1.
- UserNotifications for deadline reminders.
- Explainable deterministic decision engine rather than opaque AI.
- German + English from first build.
- Free tier: 5 active purchases.
- StoreKit 2 Lifetime Pro; no subscription in v1.
- Provisional bundle id `de.kamilunavo.keepmeter`.
- Product id `de.kamilunavo.keepmeter.pro.lifetime`.
- Lifetime target approximately EUR 7.99–12.99; exact tier not locked.

## Implemented / green

- native Xcode project + shared scheme
- SwiftData purchase/usage models
- Active / kept / returned states
- Dashboard / Add Purchase / Detail / Archive
- usage logging + cost per use
- return countdown
- explainable KEEP / REVIEW / RETURN? engine
- local reminders
- StoreKit entitlement/purchase/restore plumbing
- free-tier enforcement + paywall
- onboarding
- Active / Insights / Archive / Settings tabs
- DE/EN localization
- first coherent visual system
- GitHub Actions simulator build gate

Build gates:

- functional MVP run `32178808223` — SUCCESS
- visual polish run `32179763750` — SUCCESS
- visual polish merge checkpoint `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

## KeepMeter open work

- local `.storekit` config
- App Store Connect Lifetime IAP setup
- persistence/relaunch QA
- notification delivery QA
- free-limit / purchase / restore QA
- dedicated light/dark + accessibility QA
- notification localization cleanup
- final icon/identity
- final naming/domain/trademark due diligence
- TestFlight readiness + signed upload

## KeepMeter next steps

1. StoreKit local testing.
2. Persistence + notification QA.
3. Appearance/accessibility pass.
4. Final icon/branding/name checks.
5. First signed TestFlight only after QA gates are green.

# Candidate #011 — Family Life OS

Status: LOCAL SUPABASE DB CONTRACT GREEN / LIVE BACKEND NEXT
Internal codename only; public brand not locked.

## Current checkpoints

- Foundation PR #3 — MERGED
- Foundation merge `cd86aa4980133020b05629f9930aff598d9f9b35`
- First executable UI PR #4 — MERGED
- UI merge `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
- First green UI run `32180561109`
- Adaptive UI/accessibility PR #5 — MERGED
- Adaptive merge `aa70b24ebb21d472c66ac13d790096510f65a309`
- Final adaptive run `32182627951` — SUCCESS
- Backend contract/repository PR #6 — MERGED
- Final backend Swift head `ab68d1f25883886715d7892d6b90a5578c193924`
- Final backend Swift run `32184778802` — SUCCESS
- Backend merge `cb0a3f99f749ee46ce8b3b6d39c79d50bfe3341b`
- Supabase DB validation PR #7 — MERGED
- Final DB validation head `f2ecc11881af78896e5cba4f7f75c3409f5e2d02`
- Final DB validation run `32185816675` — SUCCESS
- DB validation merge `ff9b4695efb4fa49d605e05a53b18bd352872fe3`
- App-specific state after DB pass `d918d89b0e31654cc960cbf26be0a7ca697cdbc5`

Authoritative #011 handoff until an app-specific repo exists:

`apps/011-family-life-os/PROJECT_STATE.md`

## Product thesis / locked trust boundary

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` is the signature trust boundary:

- source remains reachable
- proposals independently editable/includable
- unresolved required fields block confirmation
- extraction/AI cannot silently create canonical family data
- explicit confirmation required
- confirmed items retain source + proposal provenance

## Canonical #011 docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/BACKEND_CONTRACT.md`
- `apps/011-family-life-os/PROJECT_STATE.md`
- `apps/011-family-life-os/prototype/README.md`

## Executable client state

Temporary implementation:

`apps/011-family-life-os/prototype/`

Project:

`FamilyLifePrototype.xcodeproj`

Target:

- SwiftUI
- iOS/iPadOS 18+
- iPhone + iPad
- provisional bundle id `de.kamilunavo.familyprototype`

Implemented:

- Heute / Inbox / Plan / Familie
- adaptive iPad `NavigationSplitView`
- compact iPhone tabs
- two-column iPad Import Review
- busy/calm/conflict Today fixtures
- real shared-member schedule overlap detection
- queued/processing/review/partial/done/failed Inbox states
- Dynamic Type adaptation
- VoiceOver labels/hints and accessibility IDs
- semantic light/dark surfaces
- source provenance
- editable school-letter review flow

## Swift repository boundary — GREEN

Current boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Current implementation:

`InMemoryFamilyRepository`

Planned production implementation:

`SupabaseFamilyRepository`

Repository operations:

- current snapshot
- text ingestion
- reviewed proposal confirmation
- plan completion update

The deterministic `FixtureTextExtractionService` is explicitly not AI. It exists only to prove the locked text source -> proposals -> review -> confirmation contract without credentials/network dependency.

Domain now includes proposal review status plus `sourceProposalID` as the provenance/idempotency key.

Inbox has a visible `Text-Beispiel importieren` path that exercises the repository boundary.

## Supabase SQL / RLS / RPC contract — GREEN LOCALLY

Backend contract:

`apps/011-family-life-os/BACKEND_CONTRACT.md`

Migrations:

- `20260818224000_family_core.sql`
- `20260818224500_fix_member_uniqueness_and_confirm_retry.sql`
- `20260818224700_private_helper_permissions.sql`
- `20260818225000_tighten_client_write_surface.sql`

Core schema:

- households
- household_members
- source_items
- extraction_runs
- action_proposals
- action_proposal_assignees
- plan_items
- plan_item_assignees
- reminders

Security/integrity decisions:

- RLS enabled across client-exposed collaborative tables.
- Multiple children/guests without login are allowed per household.
- login-user uniqueness applies only when `user_id` is non-null.
- private membership helpers have restricted execution and empty `search_path`.
- authenticated client update privileges are narrowed to product-editable columns.
- processing/review/provenance fields remain server/RPC-owned.
- machine extraction rows are trusted-server-owned.
- canonical plan provenance must resolve within the same household.

Atomic confirmation RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

Contract is locally validated for owner/adult authorization, source/proposal matching, unresolved rejection, same-household assignees, source status transitions and idempotent retry via unique `source_proposal_id`.

## Real local database gate — GREEN

Supabase workspace:

`apps/011-family-life-os/supabase/config.toml`

Database workflow:

`.github/workflows/family-life-os-database-tests.yml`

Final run:

- `32185816675`
- SUCCESS
- Supabase CLI `2.115.0`
- Postgres image `ghcr.io/supabase/postgres:15.8.1.085`
- all four migrations applied successfully to a fresh local database
- pgTAP: `family_core_rls.test.sql .. ok`
- `Files=1, Tests=12`
- `All tests successful.`
- `Result: PASS`

The project-owned deprecated Inbucket warning and missing seed warning were removed before the final run. Only the external GitHub `actions/checkout@v4` Node-version notice remains.

The 12 assertions cover core tables, multiple no-login children, cross-household read isolation, unresolved confirm rejection, valid confirmation, idempotent retry, no duplicate canonical item and child denial of adult-management permission.

## #011 validation boundary

Validated:

- executable SwiftUI and repository client compile in GitHub macOS/Xcode CI
- final repository/data run `32184778802` — SUCCESS
- clean local Supabase/Postgres migration from scratch
- local RLS/RPC pgTAP contract
- final database run `32185816675` — SUCCESS / 12 tests PASS
- PR #7 merged to `ff9b4695efb4fa49d605e05a53b18bd352872fe3`

Not yet validated:

- hosted Supabase dev/prod project
- actual Auth session from iOS
- live Data API requests from app
- `SupabaseFamilyRepository`
- hosted confirmation RPC
- multi-device Realtime
- private Storage
- photo/PDF ingestion
- OCR
- real AI extraction
- physical-device/manual VoiceOver QA

The correct statement is therefore: **local clean-database Supabase contract is green; live hosted backend is not connected yet.**

## Next real backend vertical slice

1. create/connect hosted Supabase development project in EU/Frankfurt
2. apply the green migration set to hosted dev
3. implement `SupabaseFamilyRepository`
4. add minimum Auth + household bootstrap
5. create the plain-text school-letter source through the live client
6. persist/read proposals
7. review/edit through existing `Import prüfen`
8. atomic hosted confirm -> plan items + assignees + provenance
9. refresh Today/Plan from live repository data
10. verify household isolation with two authenticated users over the actual Data API

Only after that is green:

- Realtime
- private Storage
- photo/PDF
- OCR
- real AI provider with validated structured output

## Brand guardrail

`Family Life OS` is internal only.

Rejected first-pass names:

- Famiqo
- Kinora
- Familoop
- Kinbox

Preferred icon direction: **Gather -> Order**.

Avoid generic house/checkmark, cartoon family, or robot/AI sparkle identity.

## Deferred / rejected for #011 MVP

- generic calendar/shopping/chores clone
- family social/chat replacement
- live GPS
- video/audio calls
- bank/full budgeting
- meal/recipe platform
- complex chore economy
- automatic mailbox surveillance
- autonomous bookings/calls
- medical-advice assistant
- generic AI-chat-first interface
- decorative Liquid Glass everywhere

## Handoff rule for new chats

1. Read this file.
2. Read the selected app-specific state.
3. For #011, continue from `apps/011-family-life-os/PROJECT_STATE.md` and `BACKEND_CONTRACT.md`.
4. Inspect current `main` + both Swift/DB CI states before code changes.
5. Continue with hosted Supabase + `SupabaseFamilyRepository`.
6. Do not jump to Storage/OCR/AI before the hosted text path is green.
7. Preserve other candidate sections when updating one workstream.
