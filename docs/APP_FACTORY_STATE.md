# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Repository purpose: Persistent handoff/state repository for the full App Factory so work can continue across limited chat lengths and new ChatGPT conversations without losing decisions or progress.

## Mandatory workflow

1. Build/validate the apps sequentially, starting with #001 unless the user explicitly selects another App Factory candidate.
2. This repository is the central App Factory memory and must be updated after every major design, development, naming, monetization, release, TestFlight, App Store, or strategy pass.
3. Each app gets its own repository once implementation starts.
4. Each app repository must contain `docs/PROJECT_STATE.md` as its app-specific single source of truth.
5. The central state must record at minimum active app/phase, repo, commit/PR, accepted/rejected decisions, monetization, scope, blockers, release status and next steps.
6. Before continuing App Factory work in a new chat, read this file first and then read the selected app's project state.
7. Keep v1 focused and validate before overbuilding.
8. Do not force subscriptions when a one-time/lifetime unlock fits better.
9. Before locking a name or positioning, check current App Store/web competition and appropriate trademark/domain sources.
10. Major source passes must pass CI/regression gates before merge/TestFlight.
11. Never overwrite another App Factory candidate's recorded state when updating one candidate; preserve concurrent project sections.

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost per use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — polished MVP green; StoreKit/QA next |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking in one place | Freemium | QUEUED |
| 004 | SubZero | Detect and track subscriptions, show recurring costs, reminders | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Save gift ideas per person/occasion via share sheet, price/link/photo | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison with criteria and optional shared ratings | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists and dates | Subscription due to AI/cloud cost | QUEUED |
| 008 | BeforeAfter | Guided repeat photography with overlay/alignment, comparison, collage/video | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators and explain risk factors | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Very fast portrait reaction/high-score game with short sessions | Ads + IAP | QUEUED |
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events, tasks, deadlines, payments and preparation actions | Freemium + Family Pro subscription | FIRST EXECUTABLE UI SLICE GREEN |

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

`45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Latest app-state update commit:

`fb84802c477593f243c5187bc46b5d021cd0ee4d`

### Current concept

#001 is no longer a generic receipt/warranty tracker.

Current thesis:

> **Is this purchase actually worth keeping before the return window closes?**

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

The user adds a purchase, logs actual use, watches cost per use and the return countdown, and receives a transparent KEEP / REVIEW / RETURN? signal before the deadline.

### Why the concept pivoted

The original receipt-scan / return-window / warranty concept was found to be crowded in 2026. Close/adjacent products found during validation included Belegio, Lyfe, Warranty Box, KeepSlip, ValueGuard, Reclaimo, Return & Refund Tracker, ReturnCue AI and Refundly. Adjacent cost-per-use products also exist.

KeepMeter therefore must not position itself as another receipt vault or generic cost-per-use calculator. Its differentiation is the combined deadline-aware decision loop.

### Locked implementation decisions

- Native iPhone utility.
- SwiftUI + SwiftData.
- iOS 17+.
- Local-first; no account/backend for core v1.
- UserNotifications for deadline reminders.
- Deterministic/explainable decision engine rather than opaque AI.
- German + English from the first build.
- Free tier capped at 5 active purchases.
- Archived/finished purchases do not count toward the active cap.
- StoreKit 2 Lifetime Pro unlock.
- No subscription in v1.
- Provisional bundle ID: `de.kamilunavo.keepmeter`.
- Current StoreKit product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Lifetime price target roughly EUR 7.99–12.99; exact tier not locked.

### Implemented and compiling

- Dedicated KeepMeter repository and project-state file.
- Native Xcode project + shared scheme.
- SwiftData `Purchase` / `UsageEvent` models.
- Active / kept / returned states.
- Dashboard, Add Purchase, Purchase Detail and Archive.
- One-tap usage logging.
- Cost-per-use and return-window calculations.
- Explainable KEEP / REVIEW / RETURN? engine.
- Local reminders + cancellation on completion.
- StoreKit 2 entitlement/purchase/restore plumbing.
- Free-tier enforcement at 5 active purchases.
- Lifetime Pro paywall.
- 3-page onboarding.
- Tabs: Active / Insights / Archive / Settings.
- Insights dashboard.
- Settings / explicit Pro management.
- English + German localization.
- GitHub Actions unsigned iOS Simulator build workflow.
- First coherent visual system across every MVP surface.

### Visual system — first polish complete

PR #2 applied the first cohesive KeepMeter design across Onboarding, Dashboard, Purchase Detail, Insights, Archive, Add Purchase, Settings and Paywall:

- adaptive branded background
- reusable material-card language with restrained borders/shadows
- semantic keep/review/return colors
- visible return-window progress
- stronger uses / cost-per-use / deadline metric hierarchy
- redesigned decision hero
- prominent one-tap usage action
- polished final keep/return controls
- Lifetime-first Pro presentation emphasizing one-time purchase/no subscription
- success haptic after logging usage
- additional DE/EN visual copy

System-aware backgrounds/materials make the direction light/dark compatible, but dedicated appearance QA is still required.

### Verified build gates

**Gate 1 — functional MVP**

- PR #1 `Validate current KeepMeter MVP build`
- Workflow run `32178808223`
- Result: SUCCESS
- Merge checkpoint `bf024336455d2a65da1e7d5f25ac87f142a3de8d`

**Gate 2 — visual polish**

- Branch `agent/visual-polish-v1`
- PR #2 `Polish KeepMeter MVP visual system`
- 11 changed files / ~1,200 additions during the pass
- Workflow run `32179763750`
- Full iOS Simulator `xcodebuild`: SUCCESS
- PR #2 squash-merged
- Merge checkpoint `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

Future major source passes must continue to use CI as a regression gate.

### Current decision-engine rules

- deadline passed -> REVIEW
- zero uses and <= 3 days remaining -> RETURN?
- <= 1 use and <= 3 days remaining -> REVIEW
- zero uses after >= 60% of return window -> REVIEW
- >= 3 uses -> KEEP signal
- early window -> REVIEW / gather more signal
- otherwise -> REVIEW / more evidence needed

The UI explains the reason. No universal cost threshold pretends to define personal value.

### Naming

Working name: `KeepMeter` — **PROVISIONAL**.

Preliminary exact-name searching found no obvious exact consumer-app collision, but formal trademark clearance and domain reservation are not recorded. Previously rejected/unavailable/unsuitable directions include ReturnRadar, Belegio, Keepture, Receiptra, Reclaimo, Refundly, KeepScore, WorthKeep / KeepWorth, ReturnCue and ProofNest.

### Rejected directions

- generic receipt/warranty vault
- clone of existing receipt/refund tools
- finance/budgeting suite
- bank linking
- inbox access for v1
- mandatory account/backend
- opaque AI verdict
- forced subscription

### Build / release status

- Functional iOS Simulator compile: GREEN.
- Visual-polish iOS Simulator compile: GREEN.
- No physical-device QA yet.
- No persistence/relaunch QA yet.
- No notification-delivery QA yet.
- No StoreKit local/sandbox purchase QA yet.
- No TestFlight build yet.
- No App Store submission yet.
- Matching Lifetime IAP still needs App Store Connect configuration.

### Open MVP work

- StoreKit local `.storekit` test configuration.
- App Store Connect Lifetime product setup.
- Persistence/relaunch QA.
- Notification permission/delivery QA.
- Free-limit / purchase / restore QA.
- Dedicated light/dark appearance QA.
- Accessibility pass.
- Dynamic notification localization cleanup.
- Final visual identity / app icon.
- Final-enough name/domain/trademark due diligence.
- TestFlight readiness + signed upload.

### Immediate next steps

1. Add StoreKit local testing and exercise free -> Pro -> restore.
2. QA persistence and notifications.
3. Run dedicated light/dark + accessibility passes.
4. Lock icon/branding after stronger name checks.
5. Prepare first signed TestFlight build only after QA gates are green.

## Candidate #011 — Family Life OS

Status: FIRST EXECUTABLE UI VERTICAL SLICE GREEN
Internal codename only; public brand not locked.
Foundation PR: `acciento89-bot/appideenchatgpt#3` — merged 2026-08-18.
Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`.
UI prototype PR: `acciento89-bot/appideenchatgpt#4` — merged 2026-08-18.
UI prototype merge commit: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`.
Green prototype workflow run: `32180561109`.
App-specific project state checkpoint after prototype: `c6855780d8ec1602afb25394f3881df52b2ba980`.

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
- `apps/011-family-life-os/prototype/README.md`

App-specific project state is the authoritative handoff for #011 until its own implementation repository is created.

### First executable implementation

Because the connected GitHub tooling does not expose repository creation, the executable prototype currently lives temporarily under:

`apps/011-family-life-os/prototype/`

It contains a standalone `FamilyLifePrototype.xcodeproj`, shared scheme, separated domain/data/view files and a dedicated CI workflow. It must move to an app-specific repository once repository creation is available.

Implemented interactive surfaces:

- native four-tab shell: Heute / Inbox / Plan / Familie
- realistic Familie Berger fixture household
- Today attention/brief/timeline/preparation UI
- Inbox filters and upload/processing/review/partial/done/failed states
- capture menu entry points
- interactive `Import prüfen`
- original school-letter source preview
- independent proposal selection/editing
- unresolved child assignment blocks confirmation
- assignment/date/reminder editing
- confirmation converts proposals into canonical in-memory PlanItems
- Plan agenda, day grouping, member filters and provenance indicator
- Family member/role/permission presentation

### Build gate

Dedicated workflow:

`.github/workflows/family-life-os-prototype-build.yml`

First compile run `32180375921` found one Swift `foregroundStyle` type-inference issue in `ImportReviewView`. That was corrected by using explicit `Color` values.

Second compile run `32180561109` completed **SUCCESS** on prototype head `c0d19f94074c7288bb1838541638d2d49b329331`.

PR #4 was squash-merged only after the successful iOS Simulator build.

### Locked UX direction

Primary destinations:

1. Heute
2. Inbox
3. Plan
4. Familie

Capture is an action, not a fifth tab. Settings/account is not a permanent fifth destination.

`Import prüfen` remains the signature trust-boundary screen:

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
- Realtime where useful, normal fetch remains authoritative
- APNs-backed notification path
- local cache/offline queue where appropriate

Canonical collaborative household data lives on the backend. Views do not issue raw Supabase queries directly. Service-role/AI secrets never ship in the app.

### First vertical-slice fixture

The executable prototype uses a German school-letter import that produces exactly four proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

The user resolves an ambiguous child assignment and can edit fields before confirmation. Confirmed items become PlanItems and retain source provenance.

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

1. Run dedicated visual/interaction QA against the locked fixture matrix.
2. Add previews for busy/calm/error/unresolved states and regular-width iPad.
3. Refine genuine iPad split-view adaptation.
4. Run Dark Mode, Dynamic Type and VoiceOver passes.
5. Move to an app-specific repository once repository creation is available.
6. Implement Supabase schema/RLS and repository interfaces.
7. Prove real text-fixture ingestion before photo/PDF/OCR.
8. Keep real AI output structured, reviewable and non-canonical until explicit confirmation.
9. Update both #011 project state and this master state after every major pass.

## Handoff rule for new chats

When continuing the App Factory:

1. Read `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md`.
2. Read the selected app's project state (`acciento89-bot/keepmeter/docs/PROJECT_STATE.md` for #001; `apps/011-family-life-os/PROJECT_STATE.md` for #011 until its own repo exists).
3. Inspect current repo branch/commit/build state before coding.
4. Continue from recorded next steps.
5. Update only the relevant candidate section while preserving all concurrent project sections.
