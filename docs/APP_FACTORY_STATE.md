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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events/tasks/deadlines/payments/preparation | Freemium + Family Pro subscription | HOSTED SUPABASE VERTICAL SLICE MERGED / IOS + DB GATES GREEN |

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

Latest major pass: hosted Supabase vertical slice.

- PR `#8` — MERGED
- tested PR head `13297c5fd40705509dce298d741229ccd26b76bb`
- merge commit `747d5bed505ef527501d24b9a24144ffb04a24f1`
- final Xcode/iOS Simulator run `32221107674` / run #17 — SUCCESS
- final Supabase/Postgres/pgTAP run `32221107641` / run #8 — SUCCESS
- both required gates passed on the same tested head before merge
- app-specific state updated on main by commit `4223c05703293cda0d9c3f76cb95fdec144725a4`

The final compiler blocker before merge was not a Supabase API problem. It was two SwiftUI `Section` calls with title+footer shorthand resolving to the wrong initializer in CI. `FamilyView.swift` and `HostedAppView.swift` now use explicit header/footer closures. The Xcode workflow also preserves build diagnostics as a failure artifact for future debugging.

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

Hosted development state:

- Supabase project in EU / Frankfurt
- Supabase Swift / `Supabase` pinned to `2.54.1`
- publishable client key only in app
- no service-role secret shipped
- hosted advisor hardening migration `20260819041232`
- hosted text vertical-slice migration `20260819041753`
- hosted security advisor clean after rollout
- expected INFO-level unused-index notices only from performance advisor on the new/empty database

Hosted client capabilities now implemented:

- Magic Link auth/session gate
- custom redirect handling
- household bootstrap
- members / Inbox sources / proposals / assignees / Plan reads from hosted Postgres/RLS
- server fixture text import via `ingest_text_fixture`
- reviewed proposal edits + assignee persistence
- canonical confirmation RPC
- remote task completion
- remote child-profile creation

Still required before real-device auth E2E:

`de.kamilunavo.familyprototype://login-callback`

must be confirmed/added in the hosted Supabase Auth redirect allow-list.

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

Atomic RPC:

`public.confirm_action_proposals(source_item_id, proposal_ids)`

remains responsible for authorization, proposal/source validation, unresolved rejection, canonical plan creation/reuse, same-household assignees, proposal finalization, source status transition and idempotent retry.

## #011 validation boundary

Validated now:

- hosted migrations/hardening rolled out
- hosted security advisor clean after rollout
- `SupabaseFamilyRepository` + hosted auth/client code compiles
- final iOS CI is green
- fresh local Supabase/Postgres migration + pgTAP gate is green
- both final gates passed on the same PR #8 head
- PR #8 merged to main

Not yet release-validated:

- real-device Magic Link after redirect allow-list confirmation
- full authenticated school-letter vertical slice manually exercised from iPhone/iPad
- two-real-user hosted household-isolation E2E
- Realtime
- private Storage
- photo/PDF ingestion
- OCR
- real AI extraction
- physical-device/manual VoiceOver QA
- StoreKit/subscription implementation
- TestFlight readiness

Do not regress to the old statement “live backend next.” The hosted backend is now connected in the implementation and migrations have been rolled out, but the real-device authenticated end-to-end flow still requires manual validation.

## #011 next steps

1. Confirm/add the custom Magic Link redirect in hosted Supabase Auth settings.
2. Execute the authenticated German school-letter fixture from the iOS client end to end.
3. Verify hosted Inbox -> proposals -> edits/assignees -> confirmation -> Plan/Today + provenance.
4. Verify retry/idempotency against hosted data.
5. Validate RLS with two real authenticated users.
6. Add Realtime only after the hosted text flow is proven.
7. Add private Storage + photo/PDF share intake.
8. Add OCR.
9. Add real AI extraction last while retaining explicit proposal review/confirmation.
10. Physical-device + VoiceOver QA before a TestFlight checkpoint.

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
5. Continue #011 from hosted Auth redirect + real authenticated E2E validation.
6. Do not jump to Storage/OCR/AI before the hosted text path is proven manually.
7. Preserve every other portfolio entry when updating one workstream.
