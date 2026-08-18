# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Repository purpose: Persistent handoff/state repository for the full App Factory so work can continue across limited chat lengths and new ChatGPT conversations without losing decisions or progress.

## Mandatory workflow

1. Build/validate the apps sequentially, starting with #001.
2. This repository is the central App Factory memory and must be updated after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Each app gets its own repository once implementation starts.
4. Each app repository should also contain `docs/PROJECT_STATE.md` as its app-specific single source of truth.
5. The central state here must record at minimum:
   - active app and current phase
   - repository URL/name once created
   - current branch / commit / PR when known
   - accepted decisions
   - rejected directions
   - monetization model
   - current feature scope
   - open risks / blockers
   - TestFlight / App Store status
   - exact next steps
6. Before continuing App Factory work in a new chat, read this file first.
7. Keep v1 focused: one clear user problem, minimal screens, minimal backend, monetization from v1 where appropriate.
8. Do not force subscriptions when a one-time purchase or lifetime unlock is a better fit.
9. Before locking a name or positioning, check the current market and App Store/web competition.
10. App Factory validation is allowed to materially pivot an idea before code is written if the original concept is already commoditized.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost per use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — MVP spec locked, naming still provisional |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking in one place | Freemium | QUEUED |
| 004 | SubZero | Detect and track subscriptions, show recurring costs, reminders | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Save gift ideas per person/occasion via share sheet, price/link/photo | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison with criteria and optional shared ratings | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists and dates | Subscription due to AI/cloud cost | QUEUED |
| 008 | BeforeAfter | Guided repeat photography with overlay/alignment, comparison, collage/video | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators and explain risk factors | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Very fast portrait reaction/high-score game with short sessions | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events, tasks, deadlines, payments and preparation actions | Freemium + Family Pro subscription | FOUNDATION — UX LOCKED / ARCHITECTURE SELECTED |

## Current active app — #001

### Current concept

#001 is no longer a generic receipt/warranty tracker.

The original concept was materially pivoted after current-market validation on 2026-08-18 showed that the category is already highly crowded with apps that provide receipt scanning, return deadlines, warranty tracking, local reminders, claim packs and/or refund follow-up.

The focused product thesis is:

> **Is this purchase actually worth keeping before the return window closes?**

Core loop:

1. Add a purchase.
2. Set/confirm price and return deadline.
3. Log actual usage with one tap.
4. See current cost per use.
5. See time left to return.
6. Get a transparent KEEP / REVIEW / RETURN recommendation.
7. Decide before the deadline.

If kept, the item can continue as a long-term value tracker.

### Product spec

Canonical current MVP specification:

`apps/001-keepmeter/PRODUCT_SPEC.md`

Created in commit:

`f2f4a60288a8184d7c67f406b77136e1a8431012`

### Current decisions

- Build all App Factory ideas sequentially, but validate before wasting implementation time.
- #001 remains first and is being built as a consumer iPhone utility.
- #001 has pivoted from "receipt/warranty vault" to "use it enough before the return deadline".
- Working name is **KeepMeter**, currently provisional.
- KeepMeter must be local-first and require no account/backend for its core workflow.
- SwiftUI + SwiftData are the planned native stack.
- UserNotifications will handle return-deadline reminders.
- StoreKit 2 will handle a one-time Lifetime Pro unlock.
- German + English localization must be architected from the first build.
- Monetization target: free tier + one-time Lifetime Pro, not a subscription.
- Current free-tier proposal: max 5 active tracked purchases, unlimited archived/returned items.
- Current Lifetime Pro target range: EUR 7.99–12.99, exact tier to be chosen before release.

### Market validation findings — 2026-08-18

Original receipt/return/warranty concept competitors found include Belegio, Lyfe, Warranty Box, KeepSlip, ValueGuard, Reclaimo, Return & Refund Tracker, ReturnCue AI and Refundly.

Adjacent cost-per-use products include CostPerUse, UseWorth and Skip or Buy. Presence+ also contains a clothing-specific Keep/Return flow with cost-per-wear.

Therefore KeepMeter must not position itself as "another cost-per-use app" either. Its differentiation is the combined real-time decision loop:

**Bought -> Use -> Measure -> Decide before deadline.**

### Name validation

Rejected / unavailable / unsuitable names found during research:

- ReturnRadar — rejected due to existing adjacent use.
- Belegio — active product in exact original category.
- Keepture — existing photo messenger.
- Receiptra — existing receipt/expense projects.
- Reclaimo — existing return reminder/warranty/complaint brands.
- Refundly — existing refund products.
- KeepScore — existing scorekeeping apps and retail trademark usage.
- WorthKeep / KeepWorth — existing products.
- ReturnCue — active App Store product.
- ProofNest — active App Store/web products, including receipt/warranty and evidence products.

`KeepMeter` is the current provisional working name because a preliminary exact-name web/App Store check did not surface an obvious consumer app using that exact name. This is NOT yet a formal trademark clearance or confirmed domain reservation.

### MVP screens locked

1. Onboarding — maximum 3 cards.
2. Home / Decision Dashboard.
3. Add Purchase.
4. Purchase Detail with `+ Used it` as primary action.
5. Lightweight Insights.
6. Settings / Pro.

### MVP data model locked

Primary entities:

- Purchase
- UsageEvent
- ReminderPreference

Key Purchase data:

- UUID
- name
- price + currency
- merchant/category optional
- purchase date
- return deadline
- optional target cost per use
- optional image
- status: active / kept / returned / archived
- timestamps

Key UsageEvent data:

- UUID
- purchase relationship
- usedAt
- quantity
- optional note

### Decision-engine rule

The recommendation must be deterministic and explainable, not an unexplained AI verdict.

Core calculation:

`costPerUse = price / max(usageCount, 1)`

The first prototype combines cost-per-use, usage pace and remaining return time into KEEP / REVIEW / RETURN. Exact thresholds will be tuned after the UI flow exists.

### Rejected directions

- Do not revive the original generic receipt/warranty tracker positioning.
- Do not build a clone of Belegio, KeepSlip, ReturnCue AI, Refundly or similar products.
- Do not turn v1 into finance/budgeting software.
- Do not link bank accounts.
- Do not access user email inboxes for v1.
- Do not require an account or backend.
- Do not make an AI recommendation that cannot explain itself.
- Do not force a subscription.

### Current blocker

The connected GitHub tooling can edit existing repositories but currently exposes no repository-creation action. Local GitHub CLI (`gh`) is not installed in the execution environment, so the app-specific repository cannot be created automatically in this pass.

This does NOT block product/spec work in the central repository. The app-specific repo should be created as soon as repository creation is available, then `docs/PROJECT_STATE.md` must be added immediately.

### Immediate next steps

1. Perform final-enough name/trademark/domain due diligence for `KeepMeter` before public branding is locked.
2. Create the app-specific repository once repo creation is available.
3. Add `docs/PROJECT_STATE.md` immediately.
4. Scaffold SwiftUI + SwiftData app.
5. Implement Home, Add Purchase and Purchase Detail first.
6. Implement usage logging and explainable decision engine.
7. Add local notification scheduling/updating/canceling.
8. Add StoreKit 2 Lifetime Pro unlock.
9. Add German/English localization.
10. Run first simulator/device QA pass.
11. Update both app-specific and master state after the implementation pass.

## Candidate #011 — Family Life OS

Status: FOUNDATION / UX LOCKED / ARCHITECTURE SELECTED
Current working branch: `agent/family-life-os-foundation`
Current draft PR: `#2`
Public name: NOT LOCKED
Implementation repository: NOT CREATED YET

### Product thesis

#011 is deliberately not positioned as another generic family calendar or "all family tools in one app" product.

Core promise:

> **Put family chaos in. Get an organized plan out.**

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

Family information can enter via photo, screenshot, PDF/document share, text, voice or manual input. The app converts the source into structured proposals such as events, tasks, deadlines, payment reminders and preparation actions. AI proposals are editable and must be confirmed before becoming canonical family data.

### Naming / positioning guardrail — 2026-08-18

`Family Life OS` is now an **internal codename/product thesis only**, not intended public positioning.

Reason: current competitor **Famiqo** publicly uses `Family Life Operating System`, creating an immediate differentiation/collision problem for that phrase.

Additional first-pass rejects:

- Kinora — multiple current family/child products including a child organizer.
- Familoop — current family-focused secure messaging product.
- Kinbox — current unrelated software plus historical family/social-network exact-term usage creates needless collision risk.

Final public name must pass App Store/web, EUIPO, DPMA and domain checks before lock.

### Canonical foundation docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/PROJECT_STATE.md`

### Foundation branch history / major pass commits

- Product specification: `8fff64f7ad973debb6c0a808d963e799b2f17029`
- Design system: `3de8df37bf3d6c2eff82eeabccbfffccd23b3cbf`
- Initial project state: `011e6f5a4ebffb18bf5eb3ed236ce2ce8606c17c`
- Initial master-state update: `42278032063a9f5a2b9fa3134a11190fe2ada3f8`
- Core UX screen specification: `01353de30c0891f49f8e93d8dcf2349f71043a85`
- Brand direction: `2016842f5f897e8eb83f22cc95ecb4fe1c868a6c`
- Technical architecture: `a53a7802c8832e9ac603da3f2e40aa3c40a6c961`
- Project-state architecture/UX update: `bbaf49292df86a42020a5b368eae2b25e67c6224`
- UI fixture pack: `6eec4c2198713448b251600949d301697bb34f99`

### Market guardrail

Current family-organizer competition is strong. FamilyWall already provides a broad all-in-one suite. familymind is explicitly positioned as a proactive German-language AI family assistant. Nori offers multimodal AI input including voice/photo/file flows. Fami and many other products already combine shared calendars, chores, shopping, meal planning and/or budgets.

Therefore #011 may NOT claim differentiation from any single one of these features:

- shared calendar
- chores
- family color coding
- generic AI chat
- voice-created events
- photo/PDF extraction alone
- all-in-one family organization

The differentiation target is the quality and low-friction nature of the complete ingestion-to-action workflow.

### UX locked for first prototype

#### Primary navigation

Four persistent destinations:

1. Heute
2. Inbox
3. Plan
4. Familie

Capture is a global action, not a fifth tab. Settings/account is not a permanent top-level tab.

#### Heute

- no giant dashboard/calendar clone
- conditional attention section only when needed
- factual compact family brief based only on confirmed data
- lightweight chronological timeline
- conditional prepare-for-tomorrow actions
- calm empty state when there is nothing urgent

#### Inbox

- raw incoming family information + processing state
- simple Offen / Verarbeitet / Alle filters
- statuses for upload, analysis, review, partial completion, complete and failure
- original source remains available for provenance and recovery

#### Import prüfen — signature screen

This is the product's trust boundary and key differentiation surface.

- source preview remains reachable throughout review
- independent editable proposals
- proposal kinds: Termin / Aufgabe / Frist / Zahlung / Vorbereitung
- uncertain fields are marked directly and require resolution when necessary
- user explicitly confirms proposals before canonical data is created
- confirmed items retain source provenance

#### Plan

- Agenda-first MVP
- member filtering
- full calendar visualization may follow after the ingestion vertical slice is excellent

#### Familie

- household + members
- role architecture: Owner / Adult / Child / Guest-Caregiver
- child/guest isolation enforced server-side, not only in UI

### Technical architecture selected

Foundation stack:

- native SwiftUI client
- iOS/iPadOS 18+ deployment direction
- iOS 26+ visual enhancements behind availability checks
- Supabase backend
- preferred Central EU / Frankfurt region
- Postgres
- Row Level Security for household isolation
- Supabase Auth
- private object Storage
- Realtime where useful for collaboration/status
- server/Edge Functions for AI orchestration and secrets
- APNs-backed server notification flow
- local cache/offline mutation queue where appropriate

Rules:

- canonical collaborative household data lives on backend
- UI views do not execute raw backend queries directly
- service-role/AI secrets never ship in the app
- no public source-document bucket
- no raw family documents in generic telemetry/logs
- model output is structured/validated and produces proposals, not direct canonical writes
- proposal confirmation must be transactional/idempotent

### Initial relational model direction

Core entities:

- profiles
- households
- household_members
- source_items
- extraction_runs
- action_proposals
- plan_items
- plan_item_assignees
- reminders
- household_invites

A child/guest household member may exist without an authenticated user account so permissions do not need to be faked through adult accounts.

### Brand / visual identity direction

Brand personality:

- calm
- capable
- warm
- trustworthy
- discreet
- premium without luxury styling

Avoid cartoon-family, robot/AI-sparkle and generic house/checkmark identity.

Preferred app-icon concept direction:

**Gather -> Order** — multiple rounded pieces converging into one organized form, representing loose family information becoming a shared plan.

Final palette/name/icon artwork remains open until collision and visual testing are complete.

### Locked UI fixture scenario

First executable prototype uses a deterministic demo household and a school-letter scenario.

Required end-to-end proof:

1. Household + sample members exist.
2. User opens Heute.
3. User imports a school letter fixture.
4. Inbox shows processing.
5. Extraction returns four proposals: event, deadline/task, payment, preparation.
6. Import prüfen requires resolving an ambiguous child assignment.
7. User edits at least one proposed field.
8. User confirms selected proposals.
9. Confirmed items appear in Plan.
10. Relevant items surface in Heute.
11. Each item links back to the original source.

Visual QA fixtures also cover calm day, schedule conflict, failed analysis, partial processing, offline queue, Dark Mode, iPad split layout and Dynamic Type accessibility sizes.

### Accepted foundation decisions

- DACH-first workflows, globally extensible architecture.
- iPhone-first native SwiftUI client with intentional iPad adaptation.
- Shared backend required from v1.
- Family Inbox is the core product surface.
- Primary tabs: Heute, Inbox, Plan, Familie.
- Settings are not a fifth permanent tab.
- MVP sources: photo, screenshot/image, PDF/document share, text and voice.
- Direct mailbox scanning is not MVP.
- AI creates proposals only; users confirm before actions become canonical.
- Confirmed actions retain provenance to source material.
- Core action types: events, tasks, deadlines, reminders, payment reminders and preparation actions.
- Subscription is appropriate because AI, storage, sync and notification infrastructure have recurring costs.
- German/English localization architecture from first build.
- Child/guest permission model architected from day one.
- Apple-native design. On iOS 26+, Liquid Glass is reserved mainly for functional/navigation layers and important controls rather than decorative content cards.
- Supabase/Postgres/RLS + private storage is the selected v1 backend direction.

### Deferred / rejected for MVP

- family chat/social network replacement
- live GPS
- video/audio calling
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic mailbox surveillance
- autonomous real-world bookings/calls
- medical-advice assistant
- generic AI-chat-first UI
- decorative Liquid Glass everywhere

### Current open decisions

1. Final public brand/name and formal-enough EU trademark/domain clearance.
2. Exact AI provider/model and structured extraction implementation.
3. Exact subscription pricing and AI quota after cost modeling.
4. Attachment retention defaults and privacy/legal review.
5. Calendar sync/import scope.
6. Child independent-login timing.
7. Final app icon artwork and brand palette.
8. App-specific implementation repository creation.

### Immediate next steps

1. Create first visual UI implementation/spec pass for Heute, Inbox and Import prüfen using locked fixtures.
2. Create app-specific repository when implementation begins and repository creation is available.
3. Scaffold SwiftUI app shell + domain/service boundaries.
4. Implement fixture-driven Heute, Inbox and Import prüfen before real AI integration.
5. Implement Supabase schema + RLS and a text-fixture ingestion path.
6. Validate full vertical slice on iPhone/iPad, Dark Mode and Dynamic Type.
7. Only after the core flow is excellent, expand Plan/calendar and additional family modules.
8. Update `apps/011-family-life-os/PROJECT_STATE.md` and this master state after every major pass.

## Handoff rule for new chats

When the user says to continue the App Factory, first inspect this repository and this file. Then inspect the active app's product/project-state file. If the user explicitly asks to continue Family Life OS, inspect `apps/011-family-life-os/PROJECT_STATE.md`, `PRODUCT_SPEC.md`, `DESIGN_SYSTEM.md`, `UX_SCREEN_SPEC.md`, `BRAND_DIRECTION.md`, `TECH_ARCHITECTURE.md` and `UI_FIXTURES.md` before continuing. Do not rely only on chat memory. Update this file after every major pass so it remains the authoritative cross-chat handoff state.