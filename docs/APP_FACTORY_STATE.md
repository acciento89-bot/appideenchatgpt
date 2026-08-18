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

## Current active app — #001

### Current concept

#001 is no longer a generic receipt/warranty tracker.

The original concept was materially pivoted after current-market validation on 2026-08-18 showed that the category is already highly crowded with apps that provide receipt scanning, return deadlines, warranty tracking, local reminders, claim packs and/or refund follow-up.

The new focused product thesis is:

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

- Build all 10 App Factory ideas sequentially, but validate before wasting implementation time.
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

The original receipt/return/warranty concept was found to have many close competitors. Examples found during the current check include:

- Belegio: receipt scanning, AI extraction, warranty, return-window reminders, spending stats.
- Lyfe: receipts, warranty and return windows with automatic extraction.
- Warranty Box: return deadlines, warranties and receipts, local/private positioning.
- KeepSlip: receipts, return windows, warranties, iCloud, widgets, Spotlight, export.
- ValueGuard: purchase tracker, policies, returns, warranties and spending.
- Reclaimo: return-window reminder product.
- Return & Refund Tracker: return deadlines, refund states, warranty and proof storage.
- ReturnCue AI: receipt/order import, return stages, drop-off proof and refund evidence.
- Refundly: automated return/refund tracking.

Adjacent cost-per-use products also exist, including CostPerUse, UseWorth and Skip or Buy. Presence+ also contains a clothing-specific Keep/Return flow with cost-per-wear.

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

## Handoff rule for new chats

When the user says to continue the App Factory, first inspect this repository and this file. Then inspect the active app's product/project-state file. Do not rely only on chat memory. Update this file after every major pass so it remains the authoritative cross-chat handoff state.
