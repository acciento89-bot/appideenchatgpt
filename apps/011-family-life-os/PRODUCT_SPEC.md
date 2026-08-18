# Family Life OS — Product Specification v0.1

Status: FOUNDATION / VALIDATION
Date: 2026-08-18
Public name: NOT LOCKED
Internal working title: Family Life OS
Portfolio position: Candidate #011

## 1. Product thesis

Family Life OS is not another family calendar. Its job is to reduce the mental load created by information arriving from many places and requiring somebody to turn that information into actions.

Core promise:

> Put family chaos in. Get an organized plan out.

The product should accept the way family information already arrives — photo, screenshot, PDF, shared text, voice and manual input — understand it, propose concrete actions, and place those actions into a shared family system only after the user confirms them.

The product wins if a family spends less time maintaining an organizer than it previously spent remembering things manually.

## 2. Market reality and positioning

The family-organizer category is validated but crowded. Existing products already cover combinations of shared calendars, chores, shopping, budgets, meal planning, messaging, location and AI-assisted input.

Known strong/adjacent competitors include FamilyWall, familymind, Nori, Fami, FamilyManager, MyNestPlan and newer German-language family organizers.

Therefore the following are NOT sufficient differentiation:

- shared family calendar
- color-coded family members
- shopping lists
- chores
- generic AI chat
- voice-created events
- photo-to-calendar extraction by itself
- "all family tools in one app"

Differentiation must come from the complete ingestion-to-action workflow:

**Capture -> Understand -> Review -> Act -> Follow up**

The family inbox and the automation layer are the product center. Calendar, tasks and reminders are destinations for understood information, not the headline product.

## 3. Primary jobs to be done

### JTBD A — "Turn this into something I won't forget"

When a parent receives a school letter, screenshot, PDF, message or verbal instruction, they want to put it somewhere once and trust that dates, payments, forms, materials and reminders will be surfaced at the right time.

### JTBD B — "Tell me what matters today"

A parent should be able to open the app for ten seconds and know what the family needs to do, bring, pay, sign, attend or prepare today and soon.

### JTBD C — "Give responsibility to the right person"

A task or event should clearly belong to one or more family members without forcing everyone to see private adult information.

### JTBD D — "Keep the whole family synchronized"

Changes must propagate quickly and clearly, with an activity history for important changes.

## 4. Product principles

1. **Input before administration.** Adding information must be faster than manually organizing it elsewhere.
2. **Confirm before acting.** AI proposes; the family confirms. No silent creation of high-impact events, payments or reminders.
3. **Today before database.** The home screen answers "what matters now?", not "how much data have we stored?"
4. **One source, many actions.** One school letter may generate an event, task, payment reminder and packing reminder.
5. **Calm UI.** No game-dashboard visual noise for adults.
6. **Children see a child-appropriate surface.** They should not navigate adult finances, documents or administrative settings.
7. **Privacy is a feature.** Family documents and children-related data are sensitive by default.
8. **AI must be inspectable.** Every extracted action must be traceable back to its source item.
9. **DACH-first workflows, globally extensible architecture.** School/Kita/household patterns should feel native to German-speaking families without hardcoding the whole product to one country.
10. **Do not build every family feature in v1.** Focus is ingestion, today view, shared actions and reminders.

## 5. v1 MVP scope

### 5.1 Family setup

- Create household.
- Invite second adult via secure invite link/code.
- Add child profiles without requiring child accounts.
- Optional child account later.
- Assign a distinct member accent color.
- Adult / child / guest role model prepared from day one.

### 5.2 Today

The default opening screen.

Shows only relevant items:

- today’s events
- due tasks
- upcoming deadlines that require preparation
- items needing confirmation from the inbox
- time-critical reminders
- concise "tomorrow" preview when useful

The screen must not become a full calendar month view.

### 5.3 Family Inbox

Accepted MVP inputs:

- photo from camera
- photo/screenshot from library
- PDF/document shared into the app
- text pasted/shared into the app
- direct text input
- voice input

Deferred until later unless implementation proves trivial:

- direct Gmail/Outlook mailbox access
- automatic background email scanning
- WhatsApp account integration

The share extension is important because screenshots/PDFs/messages should enter Family Life OS without forcing the user to manually reopen and reproduce information.

### 5.4 AI extraction and review

For each inbox item, the server-side extraction pipeline may propose:

- event
- task
- deadline
- reminder
- payment reminder
- person assignment
- location
- material / bring-along item
- follow-up task

Example source:

"Klassenfahrt am 18.09. Abfahrt 07:30. 35 EUR bis 05.09. überweisen. Einverständniserklärung bis 01.09. abgeben. Lunchpaket mitbringen."

Proposed actions:

1. Event: Klassenfahrt — 18.09., 07:30
2. Task: Einverständniserklärung abgeben — due 01.09.
3. Payment reminder: 35 EUR — due 05.09.
4. Preparation task: Lunchpaket vorbereiten — suggested 17.09.

Review UI:

- source preview remains visible
- each proposed action is individually editable
- "Übernehmen" confirms all selected actions
- uncertain fields are explicitly highlighted for review
- user can reject individual proposals
- source stays linked to created actions

### 5.5 Plan

Unified planning surface for:

- calendar events
- tasks
- deadlines

Views:

- Agenda/list first
- Week second
- Month view optional after MVP validation

Family-member filters are always easy to reach.

### 5.6 Family

- household members
- roles
- profile color/avatar
- invitation state
- permissions overview
- guest access prepared, not necessarily exposed in MVP

### 5.7 Notifications

MVP notification types:

- event reminder
- task due reminder
- preparation reminder
- new/changed item assigned to the user
- inbox item awaiting confirmation

Do not spam. Multiple low-priority reminders should be digestible rather than emitted individually where practical.

## 6. Navigation architecture

Primary iPhone tab structure:

1. **Heute**
2. **Inbox**
3. **Plan**
4. **Familie**

Global quick-add/import action remains reachable from the main shell.

Settings live behind the account/family control rather than becoming a fifth permanent tab.

On iPad, the same information architecture should adapt to NavigationSplitView where appropriate instead of simply stretching iPhone cards.

## 7. Core UX flows

### Flow A — first launch

1. Value proposition: "Alles rein. Familie organisiert."
2. Create household.
3. Add first family members.
4. Ask for notification permission only when the value is clear.
5. Land on Today with one guided example import.

Maximum onboarding goal: get to first useful action quickly.

### Flow B — school letter

1. Tap Import or share photo/PDF into app.
2. Upload + extraction state.
3. Review proposed actions.
4. Assign child/person if not confidently inferred.
5. Confirm.
6. Today/Plan now reflect the created actions.
7. Created actions retain "from [source document]" provenance.

### Flow C — voice dump

User says:

"Donnerstag um vier hat Nico Zahnarzt und Diana soll ihn hinbringen. Erinner uns am Vorabend an die Versicherungskarte."

Proposals:

- event Thursday 16:00, participant Nico
- responsible adult Diana
- preparation task/reminder: Versicherungskarte, previous evening

### Flow D — changed plan

1. Adult edits event time.
2. Server records change.
3. Affected family members receive a concise change notification.
4. Dependent preparation reminders are recalculated when appropriate.

## 8. Permission model

### Owner adult

- manage household
- invite/remove members
- view/manage shared family content
- manage billing
- manage roles

### Adult

- create/edit shared events/tasks
- import documents
- invite only if owner allows
- private personal items possible later

### Child

- view assigned events/tasks
- complete tasks
- limited profile controls
- no access to billing, adult-private documents or family administration

### Guest / grandparent / babysitter — post-MVP but architected

Permission-scoped access examples:

- selected children
- selected days/events
- emergency contacts
- pickup information

No blanket access to household documents or billing.

## 9. Data model — v1 foundation

### Household

- id
- name
- locale
- timezone
- createdAt

### User

- id
- auth identity
- display name
- notification preferences

### Membership

- householdId
- userId
- role
- permissions
- status

### PersonProfile

Represents adults/children even if no login account exists.

- id
- householdId
- linkedUserId optional
- name
- type adult/child/other
- accent
- avatar

### InboxItem

- id
- householdId
- createdBy
- sourceType photo/pdf/text/voice/share
- processingStatus
- sourceAttachmentId optional
- rawText optional
- createdAt

### ActionProposal

- id
- inboxItemId
- type event/task/deadline/payment/preparation
- structuredPayload
- confidence metadata
- selected
- reviewStatus

### Event

- id
- householdId
- title
- start/end
- location optional
- sourceInboxItemId optional
- participants

### Task

- id
- householdId
- title
- dueAt optional
- assignedTo
- type normal/payment/preparation
- sourceInboxItemId optional
- completedAt optional

### Reminder

- id
- targetType
- targetId
- triggerAt
- deliveryTargets

### Attachment

- id
- householdId
- storageKey
- contentType
- size
- retentionPolicy

### ActivityLog

- actor
- action
- entity
- timestamp
- relevant before/after metadata

## 10. AI architecture

AI must never be called directly from the client with provider secrets.

Pipeline:

1. Client uploads/imports source.
2. Backend validates type/size and stores source in EU-hosted storage.
3. OCR/document extraction when necessary.
4. Structured extraction request to an AI provider.
5. Server validates model output against a strict schema.
6. Date/time normalization uses household timezone and locale.
7. Proposed actions are persisted as proposals only.
8. User reviews and confirms.
9. Backend creates canonical events/tasks/reminders.

AI output must be schema-constrained. Free-form prose is secondary; structured actions are primary.

No provider API key may ship in the iOS bundle.

## 11. Technical architecture direction

### Client

- SwiftUI
- async/await
- modern Observation APIs where deployment target permits
- NavigationStack per primary flow
- NavigationSplitView adaptation for iPad
- local cache for fast/offline reads
- share extension for incoming content
- push notifications
- StoreKit 2 for subscription state

### Backend

Need a shared backend from v1 because multi-user household synchronization is a core feature.

Recommended architecture qualities:

- EU-hosted
- PostgreSQL-backed relational data
- object storage for attachments
- authenticated API
- row/household-level authorization
- background job support for extraction and notification work
- push notification service
- audit/activity events

Exact implementation technology is deliberately not locked in v0.1; select based on deployment/operations fit before scaffolding.

### Sync

- optimistic local updates for simple edits
- server canonical timestamps/versioning
- conflict handling must be explicit for concurrent edits
- important changes generate activity records

## 12. Privacy and security requirements

Because the app can contain information about children, schools, appointments and family documents, privacy cannot be postponed.

Required from v1:

- TLS in transit
- encryption at rest at infrastructure/storage layer
- strict household authorization checks server-side
- signed/short-lived attachment access URLs
- no public attachment URLs
- AI provider calls only through backend
- data minimization in AI requests
- explicit deletion flow for household/account
- attachment deletion/retention policy
- no training on customer family content by Kamilunavo
- export capability planned
- security-sensitive actions logged
- app lock / Face ID option planned early

Do not market "end-to-end encrypted" unless the architecture actually provides client-side E2EE and the claim has been verified.

## 13. Monetization direction

This product has recurring sync, storage, notification and AI costs. A permanent lifetime unlock is therefore not the default business model.

Provisional model:

### Free

- one household
- core Today/Plan
- shared calendar/tasks
- limited monthly AI imports
- limited attachment storage

### Family Pro

Target validation range: approximately EUR 4.99–7.99/month, with annual discount.

Adds:

- higher AI allowance
- advanced multi-action extraction
- larger storage
- automation rules
- extended history
- guest/grandparent access
- advanced family summaries

Exact price and limits are not locked until AI/storage cost modeling and paywall testing are done.

## 14. Explicit non-goals for MVP

Do NOT build these before the core loop is excellent:

- family social network/chat replacement
- live GPS tracking
- video/audio calling
- full household budget/accounting
- bank account connection
- meal planning engine
- recipe platform
- large gamified chore economy
- medical advice assistant
- direct autonomous booking/calling of businesses
- automatic mailbox surveillance
- complex co-parenting/legal evidence features

These may be evaluated later, but they are distractions from the ingestion-to-action thesis.

## 15. Success metrics

Activation:

- household created
- second person/profile added
- first inbox item imported
- first proposed action confirmed

Core value:

- percentage of imports that yield at least one accepted action
- time from import to confirmed plan
- proposals edited before acceptance
- weekly households with at least one Today interaction
- weekly households with at least one import

Retention:

- week 1 / week 4 household retention
- households with 2+ active adults
- recurring use of share extension

Quality:

- extraction correction rate
- date/time error rate
- duplicate action rate
- notification disable rate
- sync conflict/error rate

## 16. First implementation slice

The first executable prototype should prove only this loop:

1. Household + two sample person profiles.
2. Today screen.
3. Inbox screen.
4. Import plain text or image.
5. Produce mocked/real structured action proposals.
6. Review proposal screen.
7. Confirm event/task into local/shared model.
8. Show result on Today.

Do not start with meal plans, budgets, rewards or location.

## 17. Launch-quality bar

- German and English localization architecture from first build.
- Dynamic Type supported.
- VoiceOver labels for interactive controls.
- Light/Dark mode.
- Empty/loading/error/offline states designed, not added at the end.
- No critical action hidden behind gesture-only interaction.
- iPhone first-class; iPad intentionally adaptive.
- All AI-generated proposals visibly reviewable before they become canonical family data.

## 18. Open decisions for next pass

1. Brand/name shortlist and current availability validation.
2. Exact backend stack and EU deployment model.
3. Minimum iOS/iPadOS deployment target.
4. Subscription price and monthly AI allowance after cost model.
5. Attachment retention defaults.
6. Whether calendar import/sync is MVP or first post-MVP feature.
7. Child-login scope for initial release.
8. First visual identity direction and app icon exploration.

## 19. Competitive guardrail

Before every major scope expansion ask:

> Does this make the family spend less effort organizing incoming life, or are we merely adding another organizer feature because competitors have it?

If the answer is the latter, do not add it without evidence.