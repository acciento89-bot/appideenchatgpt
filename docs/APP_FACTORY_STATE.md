# Kamilunavo App Factory — Master Project State

Last updated: 2026-08-18
Status: ACTIVE
Repository purpose: Persistent handoff/state repository for the full App Factory so work can continue across limited chat lengths and new ChatGPT conversations without losing decisions or progress.

## Mandatory workflow

1. Build the apps sequentially, starting with #001.
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

## Portfolio queue

| # | Working title | Core idea | Planned monetization | Status |
|---|---|---|---|---|
| 001 | ReturnRadar (REJECTED NAME — replacement required) | Receipt/purchase tracker: scan receipts, track return windows, warranty, proof of purchase, reminders | Prefer Lifetime / optional Pro | ACTIVE — discovery/naming |
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

### Concept

A consumer iPhone app for purchase documentation and deadline tracking.

Core workflow:
1. User scans/imports a receipt.
2. App extracts merchant, item, price and purchase date where possible.
3. User confirms/corrects detected data.
4. App stores the receipt/proof of purchase.
5. App tracks configured return deadlines and warranty/guarantee information.
6. User receives reminders before important deadlines.
7. Dashboard shows active purchases, expiring deadlines and total documented purchase value.

### Current decisions

- Build all 10 ideas sequentially; #001 is first.
- Keep #001 focused and consumer-facing; no handcraft/SHK positioning.
- Prefer a one-time/lifetime Pro model over another forced subscription unless later cloud costs require otherwise.
- German + English should be considered from the first release architecture.
- App should work with as little backend as possible where feasible.
- A clean, native Apple-quality UX is required.

### Naming finding

`ReturnRadar` is rejected as the product name. Current market checks on 2026-08-18 found existing use of the name, including an iPhone app in essentially the same return/warranty-tracking space. The concept remains valid, but the product needs a distinctive new name and stronger differentiation.

### Rejected directions

- Do not use `ReturnRadar` as the shipping product name.
- Do not create a direct clone of an existing receipt/return tracker.
- Do not turn v1 into a huge finance/subscription/order-management suite.
- Do not require an account/backend unless a concrete v1 feature needs it.

### Immediate next steps

1. Find and verify a distinctive replacement name for app #001.
2. Check App Store/web competition for the selected name and adjacent receipt/return/warranty products.
3. Define the differentiated v1 value proposition.
4. Lock v1 screens and data model.
5. Decide exact monetization and free-vs-Pro limits.
6. Create the app-specific GitHub repository.
7. Add `docs/PROJECT_STATE.md` to that repository immediately.
8. Start implementation.

## Handoff rule for new chats

When the user says to continue the App Factory, first inspect this repository and this file. Do not rely only on chat memory. Update this file after every major pass so it remains the authoritative cross-chat handoff state.
