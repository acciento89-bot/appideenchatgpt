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
| 001 | KeepMeter (PROVISIONAL) | Return-window + actual-usage decision tool: cost per use, usage pace, deadline, Keep/Review/Return | Freemium + Lifetime Pro | ACTIVE — native implementation underway |
| 002 | ProofVault | Evidence/documentation vault for photos, videos, chats and PDFs; structured reports | Freemium + Pro | QUEUED |
| 003 | ParcelPilot | Orders, deliveries, returns and refund tracking in one place | Freemium | QUEUED |
| 004 | SubZero | Detect and track subscriptions, show recurring costs, reminders | Pro / Lifetime | QUEUED |
| 005 | GiftBrain | Save gift ideas per person/occasion via share sheet, price/link/photo | Lifetime | QUEUED |
| 006 | DecideIt | Weighted decision comparison with criteria and optional shared ratings | Freemium | QUEUED |
| 007 | Rambl | Voice dump -> structured tasks, notes, lists and dates | Subscription due to AI/cloud cost | QUEUED |
| 008 | BeforeAfter | Guided repeat photography with overlay/alignment, comparison, collage/video | Pro / Lifetime | QUEUED |
| 009 | ScamLens | Analyze screenshots/messages for suspicious indicators and explain risk factors | Credits / Pro | QUEUED |
| 010 | SwipeOrDie | Very fast portrait reaction/high-score game with short sessions | Ads + IAP | QUEUED |

## Current active app — #001 KeepMeter

### Repositories

Master App Factory repository:

`acciento89-bot/appideenchatgpt`

App-specific repository:

`acciento89-bot/keepmeter`

App-specific authoritative state:

`acciento89-bot/keepmeter/docs/PROJECT_STATE.md`

Default branch: `main`

Latest app-specific state checkpoint commit:

`eb0d8e6e313371d9be633ead4cf88d842956b8eb`

Implementation checkpoint immediately before state update:

`92e2ea4ef203b16eadf9f2d54090213db81815c6`

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

### Implemented as of 2026-08-18

- Dedicated KeepMeter repository created.
- App-specific `docs/PROJECT_STATE.md` created.
- Native `KeepMeter.xcodeproj` created.
- Shared Xcode scheme created.
- SwiftData `Purchase` model.
- SwiftData `UsageEvent` model.
- Active / kept / returned states.
- Dashboard ordered by return urgency.
- Add Purchase flow.
- Purchase Detail flow.
- Archive.
- One-tap usage logging.
- Cost-per-use calculation.
- Return-window countdown / elapsed ratio.
- Explainable KEEP / REVIEW / RETURN? engine.
- Local return reminders.
- Reminder cancellation when purchase is completed.
- StoreKit 2 entitlement service.
- Lifetime Pro purchase and restore plumbing.
- Free-tier enforcement at 5 active purchases.
- Lifetime Pro paywall.
- English localization resource.
- German localization resource.
- GitHub Actions unsigned iOS Simulator build workflow.

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

- Xcode project exists.
- GitHub Actions simulator-build workflow exists at `.github/workflows/ios-build.yml`.
- The connected GitHub interface used during this pass does not expose push-triggered workflow-run listing, so a green simulator build has not yet been confirmed from this environment.
- No device QA yet.
- No TestFlight build yet.
- No App Store submission yet.
- StoreKit code exists, but the matching Lifetime In-App Purchase still needs App Store Connect configuration before real purchase testing.

### Open MVP work

- First confirmed green simulator build; fix compile/project issues if any.
- Onboarding (max 3 cards).
- Lightweight Insights.
- Settings / explicit Pro management entry.
- Visual identity and app icon.
- Dynamic DE/EN notification-format cleanup.
- StoreKit local test configuration.
- App Store Connect Lifetime product creation/configuration.
- Persistence/relaunch QA.
- Notification QA.
- Light/dark-mode polish.
- Accessibility pass.
- Final name/domain/trademark due diligence.
- TestFlight readiness pass.

### Immediate next steps

1. Get the first simulator build green and fix anything CI/Xcode finds.
2. Add onboarding and Settings/Pro entry point.
3. Design the first polished visual system and app icon direction.
4. Add StoreKit testing and App Store Connect product configuration when appropriate.
5. QA the core loop, persistence, reminders and Pro/free-limit behavior.
6. Lock the public name only after stronger due diligence.
7. Upload to TestFlight only after the core build is stable.

## Handoff rule for new chats

When the user says to continue the App Factory:

1. Read `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md`.
2. Read the active app's `docs/PROJECT_STATE.md` — currently `acciento89-bot/keepmeter/docs/PROJECT_STATE.md`.
3. Inspect the current repo branch/commit/build state before coding.
4. Continue from the recorded next steps rather than reconstructing from chat memory.
5. Update both state files after every major pass.
