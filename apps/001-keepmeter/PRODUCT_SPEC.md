# App Factory #001 — KeepMeter

Status: PRODUCT SPEC LOCKED FOR MVP (name still provisional)
Last updated: 2026-08-18

## Product thesis

KeepMeter is not another receipt archive, warranty vault, or generic return tracker.

Its core question is:

> Is this purchase actually worth keeping before the return window closes?

The app combines three signals that are usually separate:

1. purchase price,
2. actual usage,
3. time remaining to return.

From those inputs it gives the user a simple decision view: KEEP, REVIEW, or RETURN.

## Why the concept changed

The original #001 concept (receipt scan + return deadlines + warranty reminders) is highly saturated in 2026. Current products already cover nearly the same workflow, including Belegio, Lyfe, KeepSlip, Warranty Box, Return & Refund Tracker, ValueGuard, Reclaimo and ReturnCue AI.

A second obvious pivot — return shipment/refund evidence tracking — is also already covered closely by ReturnCue AI and Refundly.

A third adjacent category — cost-per-use tracking — exists too, but current products generally focus on either long-term cost-per-use OR return tracking, not a focused cross-category "use it enough before the return deadline" decision loop.

KeepMeter therefore combines return-window urgency with actual usage and cost-per-use as the primary experience.

## Positioning

Short positioning:

**Use it. Measure it. Keep it — or return it in time.**

German:

**Nutzen. Wert prüfen. Rechtzeitig entscheiden.**

The app is for normal consumer purchases such as:

- clothing and shoes
- electronics
- kitchen gadgets
- fitness equipment
- hobby purchases
- tools
- accessories
- impulse purchases

It is intentionally not a budgeting app, bank-linking app, tax scanner, warranty database, or business expense system.

## MVP user journey

1. User adds a purchase manually or from a photo/share flow.
2. User confirms name, price, purchase date and return-by date.
3. The purchase appears on the home dashboard with a visible return countdown.
4. Every time the user uses the item, they tap `+ Use`.
5. KeepMeter recalculates cost per use.
6. The app shows a simple decision status:
   - KEEP
   - REVIEW
   - RETURN
7. The app reminds the user before the return window closes.
8. If the user decides to return the item, they can mark it returned/archive it.
9. If the user keeps it, the item can continue as a long-term value tracker.

## MVP screens

### 1. Onboarding

Three short cards maximum:

- "Bought it. But was it worth it?"
- "Track real use before the return window closes."
- "See your cost per use and decide in time."

No account creation.

### 2. Home / Decision Dashboard

Primary sections:

- Needs attention
- Return windows closing soon
- Recently added
- Kept items

Each item card shows:

- item name
- price
- uses
- cost per use
- days left to return
- current decision badge

### 3. Add Purchase

Required fields:

- name
- price
- purchase date
- return-by date OR return period in days

Optional:

- photo
- merchant
- category
- note

MVP should allow manual entry first. OCR/photo extraction can be added only if it does not delay the first usable build.

### 4. Purchase Detail

Shows:

- hero image/icon
- current KeepMeter score/status
- price
- usage count
- cost per use
- return countdown
- usage timeline
- `+ Used it` primary action
- Keep / Return actions

### 5. Insights

Simple MVP metrics only:

- money kept
- money returned
- purchases rescued before deadline
- best-value purchase
- worst-value active purchase

Do not turn this into a full finance analytics product.

### 6. Settings / Pro

- reminder timing
- currency
- language
- Face ID lock (post-MVP if needed)
- export/backup (post-MVP)
- Pro unlock

## Decision logic v1

The app must not pretend the decision is objective truth. It provides a transparent heuristic.

Inputs:

- price
- usage count
- time elapsed since purchase
- time remaining in return window
- optional target cost-per-use chosen by the user

Core calculation:

`costPerUse = price / max(usageCount, 1)`

Suggested status logic for first prototype:

- KEEP: target cost-per-use reached OR usage pace strongly indicates it will be reached
- REVIEW: uncertain / middle range
- RETURN: low usage + deadline approaching + target materially missed

The detail screen must explain WHY the status is shown rather than presenting an unexplained AI verdict.

## Notifications

Default local notifications:

- 7 days before return deadline
- 3 days before return deadline
- 1 day before return deadline

Example intent:

"3 days left to decide. You've used your headphones twice — currently €89.50 per use."

Notification wording must avoid shaming users.

## Privacy / architecture

MVP principles:

- local-first
- no account
- no backend required for core features
- no bank access
- no email inbox access
- no purchase-data upload required
- SwiftUI native iOS app
- SwiftData for local persistence unless a concrete compatibility reason requires Core Data
- UserNotifications for local deadline reminders
- PhotosPicker / camera import for optional product image
- StoreKit 2 for Pro unlock
- localization architecture from day one for German and English

## Monetization

Preferred model: freemium + one-time lifetime unlock.

MVP proposal:

Free:

- up to 5 active tracked purchases
- unlimited archived/returned items
- core return reminders
- cost-per-use tracking

Pro Lifetime target price:

- launch target: EUR 7.99 to EUR 12.99
- exact App Store price to be selected before release

Pro unlocks:

- unlimited active purchases
- deeper insights
- custom reminder schedules
- optional data export/backup once implemented

No subscription in v1.

## Name

Current provisional working name: **KeepMeter**

Reason:

- communicates "measure whether to keep"
- short and pronounceable in German and English
- preliminary web/App Store search did not surface an obvious consumer app using the exact name

Important: this is not yet a legal trademark clearance or confirmed domain reservation. Final name lock requires a formal trademark/domain check before App Store metadata and branding are finalized.

Rejected names / directions:

- ReturnRadar — direct conflict / adjacent existing product
- Belegio — already active in the exact original category
- Keepture — existing photo messenger
- Receiptra — existing receipt/expense projects
- Reclaimo — existing return reminder and warranty businesses
- Refundly — existing refund tracking products
- KeepScore — existing scoring apps and retail trademark usage
- WorthKeep / KeepWorth — existing products
- ReturnCue — existing current App Store product

## Competitive differentiation gate

Do not add features simply because competitors have them.

KeepMeter wins only if the first-run experience makes this loop obvious within seconds:

**Bought → Use → Measure → Decide before deadline.**

Any feature that weakens that loop is out of scope for v1.

## MVP data model

### Purchase

- id: UUID
- name: String
- priceMinorUnits: Int
- currencyCode: String
- merchant: String?
- category: String?
- purchaseDate: Date
- returnDeadline: Date
- targetCostPerUseMinorUnits: Int?
- imageData / image reference: optional
- status: active | kept | returned | archived
- createdAt: Date
- updatedAt: Date

### UsageEvent

- id: UUID
- purchaseId: UUID relationship
- usedAt: Date
- quantity: Int (default 1)
- note: String?

### ReminderPreference

- purchaseId: UUID relationship
- offsetsDays: [Int] conceptually (implementation may normalize to separate rows/value storage)

## MVP acceptance gates

The first TestFlight-worthy build is not ready until all are true:

- user can add/edit/delete a purchase
- return countdown is correct
- user can log/unlog usage
- cost per use updates correctly
- decision status is deterministic and explainable
- local notifications schedule/update/cancel correctly
- app survives relaunch with persisted data
- German and English localizations exist for primary UI
- free limit and StoreKit Pro state work
- no account/backend dependency
- empty/error states are intentionally designed
- iPhone layouts are polished in light and dark mode

## Next implementation steps

1. Finalize naming check for KeepMeter enough to use as repository/bundle working name.
2. Create the app-specific GitHub repository when repository-creation tooling is available.
3. Add `docs/PROJECT_STATE.md` there immediately.
4. Scaffold SwiftUI app and SwiftData models.
5. Implement Home, Add Purchase and Purchase Detail first.
6. Add usage logging + decision engine.
7. Add local notifications.
8. Add StoreKit 2 lifetime unlock.
9. Add German/English localization.
10. Run first simulator/device QA pass and update both project-state files.
