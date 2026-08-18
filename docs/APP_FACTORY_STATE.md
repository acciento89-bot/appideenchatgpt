# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Current user-selected workstream: #011 Family Life OS
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
| 011 | Family Life OS (INTERNAL CODENAME) | Family Inbox: photo/PDF/text/voice -> reviewed events, tasks, deadlines, payments and preparation actions | Freemium + Family Pro subscription | EXECUTABLE UI + ADAPTIVE QUALITY PASS GREEN |

## Portfolio app #001 — KeepMeter

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

Latest recorded app-state update commit:

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

Status: EXECUTABLE UI + ADAPTIVE QUALITY PASS GREEN
Internal codename only; public brand not locked.

### Current checkpoints

- Foundation PR: `acciento89-bot/appideenchatgpt#3` — merged 2026-08-18
- Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`
- First executable UI PR: `acciento89-bot/appideenchatgpt#4` — merged 2026-08-18
- First executable UI merge commit: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
- First green prototype workflow run: `32180561109`
- Adaptive UI/accessibility PR: `acciento89-bot/appideenchatgpt#5` — merged 2026-08-18
- Adaptive UI/accessibility merge commit: `aa70b24ebb21d472c66ac13d790096510f65a309`
- Final green adaptive-quality workflow run: `32182627951`
- Final quality-pass head before squash: `fc957da0e5f55adf6f5f71d5834a7905c6359e43`
- App-specific project state checkpoint after adaptive pass: `5bd73c35d92c08c6731f538f791e3b2810f901e4`

### Product thesis

> **Put family chaos in. Get an organized plan out.**

Core loop:

**Capture -> Understand -> Review -> Act -> Follow up**

#011 is not intended to be another generic family calendar, chores app or all-in-one organizer. Its differentiation target is the complete Family Inbox ingestion-to-action workflow: family information arrives as photo, screenshot, PDF, text or voice; the system extracts structured proposals; the user reviews/edits them; confirmed events/tasks/deadlines/payments/preparation actions then surface at the right time.

### Canonical docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/PROJECT_STATE.md`
- `apps/011-family-life-os/prototype/README.md`

`apps/011-family-life-os/PROJECT_STATE.md` is the authoritative #011 handoff until its own implementation repository exists.

### Executable implementation

The executable prototype currently lives temporarily under:

`apps/011-family-life-os/prototype/`

It contains:

- standalone `FamilyLifePrototype.xcodeproj`
- shared scheme
- separated domain/data/view files
- dedicated iOS Simulator CI workflow
- provisional bundle id `de.kamilunavo.familyprototype`
- iOS/iPadOS 18.0 target
- iPhone + iPad target families

The connected GitHub tooling does not currently expose repository creation. Move the implementation to an app-specific repository once repository creation becomes available.

### Current interactive surfaces

- Heute
- Inbox
- Plan
- Familie
- interactive `Import prüfen`
- realistic Familie Berger fixture household
- school-letter source preview
- independent proposal selection/editing
- unresolved child assignment blocks confirmation
- assignment/date/reminder editing
- confirmation converts proposals into canonical in-memory PlanItems
- Plan agenda/member filtering/provenance
- Family roles/permission presentation

### Adaptive iPad pass — complete

Compact width keeps the four-tab shell.

Regular width now uses a genuine `NavigationSplitView` with:

- persistent sidebar for Heute / Inbox / Plan / Familie
- selected destination in detail
- constrained content widths rather than stretched phone cards

`Import prüfen` now adapts on regular width to:

- source/original column
- proposal/review column
- persistent confirmation area

The initial sidebar implementation was caught by CI because the targeted iOS `List(selection:)` API required an optional selection binding. It was corrected to an explicit `Binding<AppSection?>`.

### Accessibility / appearance baseline — implemented

- Dynamic Type-aware layouts
- Agenda rows reflow vertically at accessibility text sizes
- member rows reflow at accessibility text sizes
- Import Review date controls reflow at accessibility sizes
- critical controls have VoiceOver labels/hints
- stable accessibility identifiers added for important interactions
- member identity does not rely only on color
- practical 44pt completion target
- non-actionable Inbox states are not fake/dead buttons
- meaningful empty states
- semantic Light/Dark system surfaces
- Dark Mode previews
- accessibility-size previews
- regular-width previews

This is an implementation baseline, not a claim that manual physical-device/VoiceOver QA is finished.

### Expanded deterministic QA state coverage

Inbox now includes:

- `Wartet auf Upload`
- `Wird hochgeladen`
- `Wird analysiert`
- `Prüfen`
- `Teilweise übernommen`
- `Erledigt`
- `Analyse fehlgeschlagen`

Offline queued state copy:

`Wird synchronisiert, sobald du wieder online bist.`

Today now has deterministic scenarios for:

- busy / standard
- calm
- conflict

Conflict scenario includes real overlap detection for events sharing a household member and surfaces both an attention item and row-level indicators.

Import Review includes both unresolved and ready-to-confirm deterministic states.

### Build gates

Dedicated workflow:

`.github/workflows/family-life-os-prototype-build.yml`

Prototype history:

- run `32180375921` — failed on one Swift `foregroundStyle` type mismatch; fixed
- run `32180561109` — SUCCESS; PR #4 then merged

Adaptive quality history:

- run `32182317924` — failed on iOS-incompatible non-optional sidebar `List(selection:)`; fixed
- run `32182408384` — SUCCESS after functional sidebar fix
- preview hygiene pass replaced ignored `.previewDevice(...)` usage with regular-width environment previews
- final run `32182627951` — **SUCCESS** on head `fc957da0e5f55adf6f5f71d5834a7905c6359e43`
- app-source log check: no Swift compile warnings and no remaining preview warnings; build ended `BUILD SUCCEEDED`
- remaining warnings are external to app source: no AppIntents dependency and GitHub Actions Node-version notice from `actions/checkout@v4`

PR #5 was squash-merged only after the final successful build.

### Locked trust rules

`Import prüfen` remains the signature trust-boundary screen:

- source remains reachable
- extracted proposals are independently editable
- unresolved fields are explicitly marked
- AI/extraction does not silently create canonical family data
- explicit confirmation is required
- confirmed items retain source provenance

Today remains a calm briefing/timeline, not a duplicate calendar dashboard. Plan remains agenda-first. Child/guest roles remain architected from day one.

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

Canonical collaborative household data lives on the backend. Views must not issue raw Supabase queries directly. Service-role/AI secrets never ship in the app.

### First real backend vertical slice — next

Prove this exact data path first:

1. household/member records
2. create plain-text school-letter source
3. persist structured proposal records
4. fetch proposals through repository/service boundary
5. review/edit in current `Import prüfen`
6. transactionally confirm accepted proposals
7. create canonical plan items + assignees
8. preserve source provenance
9. Today/Plan refresh from repository data

Photo/PDF/private Storage/OCR follows only after the text contract works. Real AI extraction follows only after structured proposal validation is in place.

### Brand guardrail

`Family Life OS` is an internal codename only. It is not locked public positioning.

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

1. Implement Supabase schema and RLS for households, members, sources, proposals and plan items.
2. Introduce repository/service interfaces so the UI is no longer coupled to `DemoStore` as the eventual source of truth.
3. Prove the plain-text school-letter ingestion/persistence/confirmation path end to end.
4. Add the minimum secure auth/household membership needed for collaborative data.
5. Add private Storage + photo/PDF/OCR only after text data contracts are proven.
6. Add real AI extraction only behind validated structured output and explicit review.
7. Perform physical iPhone/iPad + manual VoiceOver QA before any TestFlight readiness claim.
8. Move to an app-specific repository when repository creation becomes available.
9. Update both #011 project state and this master state after every major pass.

## Handoff rule for new chats

When continuing the App Factory:

1. Read `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md`.
2. Read the selected app's project state (`acciento89-bot/keepmeter/docs/PROJECT_STATE.md` for #001; `apps/011-family-life-os/PROJECT_STATE.md` for #011 until its own repo exists).
3. Inspect current repo branch/commit/build state before coding.
4. If the user selected #011, continue from the Supabase/repository-interface vertical slice recorded above.
5. Update only the relevant candidate section while preserving all concurrent project sections.
