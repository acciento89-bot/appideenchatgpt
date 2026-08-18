# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Repository purpose: Persistent handoff/state repository for the full App Factory so work can continue across limited chat lengths and new ChatGPT conversations without losing decisions or progress.

## Mandatory workflow

1. Build/validate the apps sequentially, starting with #001.
2. This repository is the central App Factory memory and must be updated after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Each app gets its own repository once implementation starts.
4. Each app repository must contain `docs/PROJECT_STATE.md` as its app-specific single source of truth.
5. The central state must record at minimum:
   - active app and current phase
   - repository URL/name
   - current branch / commit / PR when known
   - accepted decisions
   - rejected directions
   - monetization model
   - current feature scope
   - open risks / blockers
   - TestFlight / App Store status
   - exact next steps
6. Before continuing App Factory work in a new chat, read this file first and then read the active app's `docs/PROJECT_STATE.md`.
7. Keep v1 focused: one clear user problem, minimal screens, minimal backend, monetization from v1 where appropriate.
8. Do not force subscriptions when a one-time purchase or lifetime unlock is a better fit.
9. Before locking a name or positioning, check the current market and App Store/web competition.
10. App Factory validation may materially pivot an idea before or during early implementation if the original concept is already commoditized.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost per use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — first green MVP build; polish/QA next |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking in one place | Freemium | QUEUED |
| 004 | SubZero | Detect and track subscriptions, show recurring costs, reminders | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Save gift ideas per person/occasion via share sheet, price/link/photo | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison with criteria and optional shared ratings | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists and dates | Subscription due to AI/cloud cost | QUEUED |
| 008 | BeforeAfter | Guided repeat photography with overlay/alignment, comparison, collage/video | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators and explain risk factors | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Very fast portrait reaction/high-score game with short sessions | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events, tasks, deadlines, payments and preparation actions | Freemium + Family Pro subscription | FOUNDATION — UX locked; architecture selected |

## Current active app — #001 KeepMeter

### Repositories

Master App Factory repository:

`acciento89-bot/appideenchatgpt`

App-specific repository:

`acciento89-bot/keepmeter`

App-specific authoritative state:

`acciento89-bot/keepmeter/docs/PROJECT_STATE.md`

Default branch: `main`

Current verified app checkpoint:

`bf024336455d2a65da1e7d5f25ac87f142a3de8d`

Current app-state update commit:

`0db1a265a442a10cce5c4109d2ed943fce5408dc`

Validation PR:

`acciento89-bot/keepmeter#1` — merged after green CI

Validated workflow run:

`32178808223` — SUCCESS

### Current concept

#001 is no longer a generic receipt/warranty tracker.

Current thesis:

> **Is this purchase actually worth keeping before the return window closes?**

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

The user adds a purchase, logs actual use, watches cost per use and the return countdown, and receives a transparent KEEP / REVIEW / RETURN? signal before the deadline.

### Why the concept pivoted

The original receipt-scan / return-window / warranty concept was found to be crowded in 2026. Close or adjacent products found during validation included Belegio, Lyfe, Warranty Box, KeepSlip, ValueGuard, Reclaimo, Return & Refund Tracker, ReturnCue AI and Refundly.

Adjacent cost-per-use products also exist, including CostPerUse, UseWorth and Skip or Buy; Presence+ includes a clothing-specific Keep/Return flow with cost-per-wear.

KeepMeter therefore must not position itself as another receipt vault or another generic cost-per-use calculator. Its differentiation is the combined deadline-aware decision loop.

### Product specification

Canonical central product spec:

`apps/001-keepmeter/PRODUCT_SPEC.md`

Original product-spec commit:

`f2f4a60288a8184d7c67f406b77136e1a8431012`

### Locked implementation decisions

- Native iPhone utility.
- SwiftUI + SwiftData.
- iOS 17+.
- Local-first; no account/backend for core v1.
- UserNotifications for deadline reminders.
- Deterministic/explainable decision engine rather than an opaque AI verdict.
- German + English from the first build.
- Free tier capped at 5 active purchases.
- Archived/finished purchases do not count toward the active cap.
- StoreKit 2 Lifetime Pro unlock.
- No subscription in v1.
- Provisional bundle ID: `de.kamilunavo.keepmeter`.
- Current StoreKit product ID in code: `de.kamilunavo.keepmeter.pro.lifetime`.
- Lifetime price target remains roughly EUR 7.99–12.99; exact App Store tier is not yet locked.

### Implemented and compiling as of 2026-08-18

- Dedicated KeepMeter repository and app-specific state file.
- Native `KeepMeter.xcodeproj` and shared scheme.
- SwiftData `Purchase` and `UsageEvent` models.
- Active / kept / returned states.
- Dashboard ordered by return urgency.
- Add Purchase flow.
- Purchase Detail flow.
- Archive.
- One-tap usage logging.
- Cost-per-use calculation.
- Return-window countdown / elapsed ratio.
- Explainable KEEP / REVIEW / RETURN? engine.
- Local return reminders and reminder cancellation on completion.
- StoreKit 2 entitlement service.
- Lifetime Pro purchase and restore plumbing.
- Free-tier enforcement at 5 active purchases.
- Lifetime Pro paywall.
- 3-page onboarding.
- Main navigation tabs: Active / Insights / Archive / Settings.
- Lightweight Insights dashboard with tracked value, total uses, average cost/use, active decisions, kept/returned counts and best-value purchase.
- Settings / explicit Pro management entry.
- Local-first privacy messaging and onboarding reset in Settings.
- English and German localization resources.
- GitHub Actions unsigned iOS Simulator build workflow.
- `EntitlementStore` compile fix (`Combine` import).

### Verified build gate

The first real simulator compile is confirmed green.

- Validation branch: `agent/ci-validation`.
- PR: #1 `Validate current KeepMeter MVP build`.
- Workflow run: `32178808223`.
- Build job: SUCCESS.
- Xcode target: KeepMeter / Debug / generic iOS Simulator / code signing disabled.
- All workflow steps completed successfully.
- PR #1 was squash-merged.
- Merge commit: `bf024336455d2a65da1e7d5f25ac87f142a3de8d`.

Future major source passes should continue to use CI as a regression gate before TestFlight.

### Current decision-engine rules

Current conservative prototype rules:

- deadline passed -> REVIEW
- zero uses and <= 3 days remaining -> RETURN?
- <= 1 use and <= 3 days remaining -> REVIEW
- zero uses after >= 60% of the return window -> REVIEW
- >= 3 uses -> KEEP signal
- early window -> REVIEW / gather more signal
- otherwise -> REVIEW / more evidence needed

The UI explains the reason. Cost per use is displayed, but no universal monetary threshold pretends to define personal value.

### Naming

Working name: `KeepMeter`.

Status: **PROVISIONAL**.

Rejected/unavailable/unsuitable directions found during research include ReturnRadar, Belegio, Keepture, Receiptra, Reclaimo, Refundly, KeepScore, WorthKeep / KeepWorth, ReturnCue and ProofNest.

A preliminary exact-name search did not surface an obvious consumer app using `KeepMeter`, but formal trademark clearance and domain reservation are not recorded yet.

### Rejected directions

- Do not revive generic receipt/warranty-vault positioning.
- Do not clone Belegio, KeepSlip, ReturnCue AI, Refundly or similar products.
- Do not turn v1 into finance/budgeting software.
- Do not link bank accounts.
- Do not access user inboxes for v1.
- Do not require an account/backend.
- Do not make an unexplainable AI recommendation.
- Do not force a subscription.

### Build / release status

- First CI iOS Simulator build: GREEN.
- Onboarding / Insights / Settings / StoreKit plumbing compile in the verified build.
- No physical-device QA yet.
- No persistence/relaunch QA yet.
- No notification-delivery QA yet.
- No StoreKit local/sandbox purchase QA yet.
- No TestFlight build yet.
- No App Store submission yet.
- Matching Lifetime In-App Purchase still needs App Store Connect configuration before real purchase testing.

### Open MVP work

- First high-polish visual system.
- Visual identity and app icon.
- Dynamic DE/EN notification-format cleanup.
- StoreKit local test configuration.
- App Store Connect Lifetime product creation/configuration.
- Persistence/relaunch QA.
- Notification permission/delivery QA.
- Free-limit / purchase / restore QA.
- Light/dark-mode polish.
- Accessibility pass.
- Final name/domain/trademark due diligence.
- TestFlight readiness pass and first signed upload.

### Immediate next steps

1. Apply a coherent visual polish pass without breaking the green core architecture.
2. Establish app-icon / visual-identity direction.
3. Add StoreKit local testing and exercise free -> Pro / restore behavior.
4. QA persistence, reminders and the decision loop.
5. Complete light/dark and accessibility passes.
6. Lock public branding only after stronger name/domain/trademark due diligence.
7. Upload first TestFlight build only after the QA gates are green.

## Candidate #011 — Family Life OS

Status: FOUNDATION / UX LOCKED / ARCHITECTURE SELECTED
Internal codename only; public brand not locked.
Foundation PR: `acciento89-bot/appideenchatgpt#3` — merged 2026-08-18.
Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`.

### Product thesis

> **Put family chaos in. Get an organized plan out.**

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

#011 is not intended to be another generic family calendar, chores app or all-in-one organizer. Its differentiation target is the complete Family Inbox ingestion-to-action workflow: family information arrives as photo, screenshot, PDF, text or voice; the system extracts structured proposals; the user reviews/edits them; confirmed events/tasks/deadlines/payments/preparation actions then surface at the right time.

### Canonical foundation docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/PROJECT_STATE.md`

App-specific project state is the authoritative handoff for #011 until its own implementation repository is created.

### Locked UX direction

Primary destinations:

1. Heute
2. Inbox
3. Plan
4. Familie

Capture is an action, not a fifth tab. Settings/account is not a permanent fifth destination.

`Import prüfen` is the signature trust-boundary screen:

- source remains reachable
- extracted proposals are independently editable
- unresolved fields are explicitly marked
- AI does not silently create canonical family data
- confirmed items retain source provenance

Today is a calm briefing/timeline, not a duplicate calendar dashboard. Plan starts agenda-first. Child/guest roles are architected from day one.

### Technical architecture direction

- native SwiftUI client
- iPhone first, intentional adaptive iPad UI
- iOS/iPadOS 18+ direction, iOS 26+ visual APIs gated
- Supabase foundation backend
- Central EU / Frankfurt preferred region
- Postgres + Row Level Security for household isolation
- private family-document storage
- server-side AI only
- structured validated proposal output
- Realtime where useful, but normal fetch remains authoritative
- APNs-backed notification path
- local cache/offline queue where appropriate

Canonical collaborative household data lives on the backend. Views do not issue raw Supabase queries directly. Service-role/AI secrets never ship in the app.

### First vertical-slice fixture

The first executable prototype is locked around a German school-letter import that produces exactly four proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

The user must resolve an ambiguous child assignment and edit at least one proposed field before confirmation. Confirmed items then appear in Plan/Heute and link back to the source.

### Brand guardrail

`Family Life OS` is an internal codename only. Current competitor Famiqo uses `Family Life Operating System`, so that phrase is not treated as distinctive public positioning.

First-pass rejected naming directions include Famiqo, Kinora, Familoop and Kinbox. Final public name requires current App Store/web plus EUIPO/DPMA/domain checks.

Preferred icon concept direction: **Gather -> Order** — loose rounded pieces converging into one organized form. Avoid cartoon-family, robot/AI-sparkle and generic house/checkmark identity.

### Deferred / rejected for MVP

- generic calendar + shopping + chores clone
- family chat/social network replacement
- live GPS
- video/audio calls
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic mailbox surveillance
- autonomous bookings/calls
- medical-advice assistant
- generic AI-chat-first UI
- decorative Liquid Glass everywhere

### Open decisions

- final public brand/name
- exact AI provider/model and extraction implementation
- subscription pricing and AI quota
- attachment retention/privacy/legal defaults
- calendar interoperability
- child independent-login timing
- final icon artwork/palette
- app-specific implementation repository creation

### Immediate next steps

1. Create the app-specific implementation repository when repository creation is available.
2. Scaffold the native SwiftUI app shell and domain/service boundaries.
3. Implement fixture-driven Heute, Inbox and Import prüfen before real AI integration.
4. Implement Supabase schema/RLS and text-fixture ingestion path.
5. Validate the end-to-end vertical slice on iPhone/iPad, Dark Mode and Dynamic Type.
6. Only after that core loop is excellent, expand Plan/calendar and adjacent family modules.
7. Update both the #011 project state and this master state after every major pass.

## Handoff rule for new chats

When the user says to continue the App Factory:

1. Read `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md`.
2. Read the active app's `docs/PROJECT_STATE.md` — currently `acciento89-bot/keepmeter/docs/PROJECT_STATE.md` for #001.
3. Inspect the current repo branch/commit/build state before coding.
4. Continue from the recorded next steps rather than reconstructing from chat memory.
5. Update both state files after every major pass.

If the user explicitly asks to continue #011 Family Life OS, additionally read `apps/011-family-life-os/PROJECT_STATE.md` and its linked canonical foundation docs before continuing.