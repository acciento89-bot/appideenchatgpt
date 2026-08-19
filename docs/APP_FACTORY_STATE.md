# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-19
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS
Repository purpose: persistent handoff/state repository for the full App Factory so work can continue across chat limits and new conversations without losing decisions or progress.

> This file is the portfolio-level single source of truth. Detailed historical states remain preserved in Git history and in each app-specific project state.

## Mandatory workflow

1. Build/validate apps sequentially starting with #001 unless the user explicitly selects another workstream.
2. Update this repository after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Read this file first in a new chat, then the selected app's project state.
4. Major source passes must pass CI/regression gates before merge/TestFlight.
5. Do not weaken a core product loop by adding adjacent features.
6. Do not force subscriptions where lifetime/one-time monetization better fits economics.
7. Re-check current App Store/web and appropriate trademark/domain sources before locking a public name.
8. Never overwrite another candidate's state while updating one workstream.

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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | HOSTED TEXT + TWO-USER RLS GREEN / DEVICE MAGIC LINK VALIDATION NEXT |

# Portfolio app #001 — KeepMeter

## Authoritative state

App repo:

`acciento89-bot/keepmeter`

App state:

`acciento89-bot/keepmeter/docs/PROJECT_STATE.md`

Current recorded verified checkpoint:

`45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Latest recorded app-state update:

`fb84802c477593f243c5187bc46b5d021cd0ee4d`

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

Locked implementation:

- native iPhone utility
- SwiftUI + SwiftData
- iOS 17+
- local-first; no account/backend for core v1
- UserNotifications for deadline reminders
- explainable deterministic decision engine
- German + English from first build
- Free tier: 5 active purchases
- StoreKit 2 Lifetime Pro; no subscription in v1
- provisional bundle id `de.kamilunavo.keepmeter`
- product id `de.kamilunavo.keepmeter.pro.lifetime`

Implemented/green:

- Dashboard / Add Purchase / Detail / Archive
- usage logging + cost per use
- return countdown
- KEEP / REVIEW / RETURN? engine
- local reminders
- StoreKit entitlement/purchase/restore plumbing
- free-tier enforcement + paywall
- onboarding
- Active / Insights / Archive / Settings
- DE/EN localization
- coherent visual system
- GitHub Actions simulator build gate

Recorded gates:

- functional MVP run `32178808223` — SUCCESS
- visual polish run `32179763750` — SUCCESS
- visual polish merge checkpoint `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Open work:

1. local `.storekit` config and App Store Connect Lifetime IAP
2. persistence/relaunch + notification QA
3. free-limit / purchase / restore QA
4. light/dark + accessibility QA
5. final icon/identity/name due diligence
6. first signed TestFlight only after QA gates are green

# Portfolio app #011 — Family Life OS

Internal codename only; public brand not locked.

Authoritative app state:

`apps/011-family-life-os/PROJECT_STATE.md`

## Current checkpoint

Latest major pass: hosted Auth callback hardening + two-user household isolation.

### PR #8 — hosted Supabase vertical slice

- PR `#8` — MERGED
- tested head `13297c5fd40705509dce298d741229ccd26b76bb`
- merge commit `747d5bed505ef527501d24b9a24144ffb04a24f1`
- final Xcode/iOS Simulator run `32221107674` / run #17 — SUCCESS
- final Supabase/Postgres/pgTAP run `32221107641` / run #8 — SUCCESS

### PR #9 — Auth/RLS hardening

- PR `#9` — MERGED
- tested head `a884bf8f36dfdc560c5aa4e5fde2d98cefb33ee9`
- merge commit `649f2104353154e199b3844ec79ca6e8d23a60ad`
- final Xcode/iOS Simulator run `32222381445` / run #19 — SUCCESS
- final Supabase/Postgres/pgTAP run `32222381440` / run #10 — SUCCESS
- both required gates passed on the same tested head before merge
- new callback guard accepts only the expected app scheme + `login-callback` host
- new 14-assertion pgTAP test validates two authenticated households remain isolated
- direct hosted SQL smoke in Frankfurt also proved cross-household read/update isolation
- temporary hosted smoke-test users/households were fully removed afterwards
- hosted security advisor currently reports no lints

## Product thesis / trust boundary

> Put family chaos in. Get an organized plan out.

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` remains the signature trust boundary:

- source stays reachable
- proposals remain editable/includable
- unresolved required fields block confirmation
- extraction/AI cannot silently create canonical family data
- explicit confirmation is mandatory
- confirmed items retain source + proposal provenance

## Executable client

Temporary implementation path:

`apps/011-family-life-os/prototype/`

Project:

`FamilyLifePrototype.xcodeproj`

Target:

- SwiftUI
- iOS/iPadOS 18+
- iPhone + iPad
- provisional bundle id `de.kamilunavo.familyprototype`

Implemented UI/UX:

- Heute / Inbox / Plan / Familie
- adaptive iPad `NavigationSplitView`
- compact iPhone tabs
- two-column iPad Import Review
- busy/calm/conflict Today fixtures
- shared-member schedule overlap detection
- queued/processing/review/partial/done/failed Inbox states
- Dynamic Type adaptation
- VoiceOver labels/hints + accessibility IDs
- semantic light/dark surfaces
- source/proposal provenance
- editable school-letter review flow
- family roles + real child-profile creation through hosted repository

## Repository / hosted backend state

Boundary:

`SwiftUI View -> DemoStore -> FamilyRepository -> data source`

Implementations:

- `InMemoryFamilyRepository` for previews/regression fixtures
- `SupabaseFamilyRepository` for hosted data

Hosted development project:

- ref `bqctetqraszsvknczjjr`
- `eu-central-1` / Frankfurt
- observed state `ACTIVE_HEALTHY`
- Supabase Swift / `Supabase` pinned to `2.54.1`
- publishable client key only in app
- no service-role secret shipped

Hosted migrations present:

- `20260819040837` family core
- `20260819041003` member uniqueness + confirmation retry
- `20260819041013` private helper permissions
- `20260819041031` tighten client write surface
- `20260819041232` hosted advisor hardening
- `20260819041753` hosted text vertical slice

Hosted client capabilities implemented:

- Magic Link auth/session gate
- custom app redirect handling
- exact callback validation before session exchange
- household bootstrap
- members / Inbox sources / proposals / assignees / Plan reads from hosted Postgres/RLS
- server fixture text import via `ingest_text_fixture`
- reviewed proposal edits + assignee persistence
- canonical confirmation RPC
- remote task completion
- remote child-profile creation

External Auth configuration still required:

`de.kamilunavo.familyprototype://login-callback`

must be confirmed/added in hosted Supabase Auth -> URL Configuration -> Additional Redirect URLs before physical-device Magic Link validation.

The currently connected Supabase tool surface cannot mutate this hosted Dashboard allow-list setting.

## Database contract

Core schema remains:

- households
- household_members
- source_items
- extraction_runs
- action_proposals
- action_proposal_assignees
- plan_items
- plan_item_assignees
- reminders

Security baseline:

- RLS across client-exposed collaborative tables
- multiple child/guest profiles without login allowed
- restricted membership helpers / empty `search_path`
- client write surface narrowed to product-editable columns
- processing/review/provenance server-owned where required
- canonical provenance constrained to same household
- two-user isolation coverage is now a mandatory regression gate

Atomic RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

remains responsible for authorization, proposal/source validation, unresolved rejection, canonical plan creation/reuse, same-household assignees, proposal finalization, source status transition and idempotent retry.

## #011 validation boundary

Validated now:

- hosted migrations/hardening rolled out
- hosted security advisor clean
- `SupabaseFamilyRepository` + hosted auth/client code compiles
- exact callback scheme/host validation compiles
- final iOS CI is green
- fresh local Supabase/Postgres migration + pgTAP gate is green
- two authenticated household identities are isolated in local pgTAP coverage
- direct hosted SQL smoke under authenticated identities proved one-household/one-source visibility and zero-row foreign UPDATE behavior
- hosted test cleanup returned zero remaining test users/households
- PR #9 merged to main

Not yet release-validated:

- real-device Magic Link after redirect allow-list confirmation
- full authenticated school-letter vertical slice manually exercised from iPhone/iPad
- two-real-user household isolation over the actual Supabase Data API/session path
- Realtime
- private Storage
- photo/PDF ingestion
- OCR
- real AI extraction
- physical-device/manual VoiceOver QA
- StoreKit/subscription implementation
- TestFlight readiness

Do not regress to the old statement “live backend next.” Hosted Supabase is connected and the database-level two-user isolation is now tested. The remaining gate is the real authenticated device/session path.

## #011 next steps

1. Confirm/add the custom Magic Link redirect in hosted Supabase Auth settings.
2. Execute Magic Link login on a physical iPhone/iPad.
3. Execute the authenticated German school-letter fixture from the iOS client end to end.
4. Verify hosted Inbox -> proposals -> edits/assignees -> confirmation -> Plan/Today + provenance.
5. Verify retry/idempotency against hosted data from the real client.
6. Validate isolation with two real authenticated sessions over the Supabase Data API.
7. Add Realtime only after the hosted text flow is proven.
8. Add private Storage + photo/PDF share intake.
9. Add OCR.
10. Add real AI extraction last while retaining explicit proposal review/confirmation.
11. Physical-device + VoiceOver QA before a TestFlight checkpoint.

## #011 brand guardrail

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

1. Read this file first.
2. Read the selected app-specific state.
3. For #011 read `apps/011-family-life-os/PROJECT_STATE.md` and `BACKEND_CONTRACT.md`.
4. Inspect current `main` and latest relevant CI gates before code changes.
5. Continue #011 from hosted Auth redirect + real authenticated device E2E validation.
6. Do not jump to Realtime/Storage/OCR/AI before the hosted text path is proven manually.
7. Preserve every other portfolio entry when updating one workstream.
