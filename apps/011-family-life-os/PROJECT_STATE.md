# Family Life OS — Project State

Last updated: 2026-08-18
Status: FOUNDATION / UX LOCK / ARCHITECTURE SELECTED
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current branch: `agent/family-life-os-foundation`
Current draft PR: #2
Implementation repository: NOT CREATED YET

## Current product thesis

> Put family chaos in. Get an organized plan out.

Family Life OS is centered on a Family Inbox and an ingestion-to-action workflow, not on being another generic shared family calendar.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

## Accepted decisions

- DACH-first product behavior, architecture extensible internationally.
- iPhone-first native SwiftUI client with intentional iPad adaptation.
- Minimum deployment direction is iOS/iPadOS 18+, with iOS 26+ visual APIs gated by availability.
- Shared backend is required from v1 because household collaboration is core.
- **Supabase** is the selected foundation backend for the first implementation.
- Preferred backend region is **Central EU / Frankfurt**.
- Postgres + Row Level Security is the primary household data-isolation boundary.
- Private object storage is required for family source documents.
- AI processing is server-side only; no provider/service-role secrets ship in the app.
- Family Inbox is the center of differentiation.
- MVP inputs: photo, screenshot/library image, PDF/document share, shared/pasted text, direct text and voice.
- Direct mailbox scanning is NOT MVP.
- AI output creates editable proposals, never silently canonical family data.
- Every confirmed AI-generated action retains provenance to its source item.
- Core destinations: Heute, Inbox, Plan, Familie.
- Settings are not a permanent fifth tab.
- MVP focuses on events, tasks, deadlines, reminders, payment reminders and preparation actions.
- Free + recurring Family Pro subscription is the provisional monetization direction because sync/storage/AI create recurring cost.
- Lifetime unlock is not the default monetization model.
- German + English localization architecture from first build.
- Apple-native UI conventions; Liquid Glass on iOS 26+ primarily in functional/navigation surfaces, not decorative content cards.
- Children/guest permission architecture is planned from day one even if all child/guest account flows are not MVP.
- The **Import prüfen** workflow is the product's core trust boundary/signature screen and must be excellent before scope expands.

## UX locked for first prototype

### App shell

Four persistent top-level destinations:

1. Heute
2. Inbox
3. Plan
4. Familie

Each destination owns its navigation state. Capture is an action, not a fifth tab.

### Heute

- conditional attention section only when something needs action
- short factual Family Brief when the system can support it from confirmed data
- lightweight chronological timeline instead of giant calendar cards
- preparation-for-tomorrow section only when useful
- calm empty state when no action is needed

### Inbox

- raw incoming family information + processing status
- simple filters: Offen / Verarbeitet / Alle
- explicit upload/analyze/review/error states
- original source always retained while needed for provenance

### Import prüfen

- source preview always reachable
- independent editable proposal cards
- proposal types: Termin, Aufgabe, Frist, Zahlung, Vorbereitung
- ambiguity is marked on the uncertain field itself
- confirmation CTA reflects included proposal count
- no silent canonical writes from AI

### Plan

- Agenda-first MVP
- member filters
- full calendar visualization can follow vertical-slice validation

### Familie

- household + member list
- role architecture: Owner / Adult / Child / Guest-Caregiver
- child/guest data isolation enforced server-side, not only in UI

## Brand state

Public name remains intentionally open so implementation is not blocked by naming.

Internal `Family Life OS` may NOT become the public positioning without reconsideration because current competitor **Famiqo** already uses `Family Life Operating System`.

Rejected in first naming pass:

- Famiqo — existing exact territory
- Kinora — multiple current family/child products, including a child organizer
- Familoop — current family secure-messaging product
- Kinbox — current software plus historical exact-family/social use creates conflict risk

Brand direction:

- calm, capable, warm, trustworthy
- no cartoon-family identity
- no robot/AI-sparkle primary logo
- app icon direction: abstract `Gather -> Order`
- final public name requires App Store/web + EUIPO/DPMA/domain clearance pass

## Technical architecture

Canonical technical direction is in `TECH_ARCHITECTURE.md`.

Core stack:

- SwiftUI native client
- Swift concurrency
- local cache/offline queue where appropriate
- Supabase Auth
- Supabase Postgres
- Row Level Security
- private Supabase Storage
- Realtime for collaborative freshness where useful
- server/Edge Function orchestration for AI
- APNs-backed server notification flow

Important architecture rules:

- shared backend is canonical for collaborative household data
- views do not execute raw backend queries directly
- all household client-exposed tables use RLS
- no public document bucket
- no raw family documents in generic telemetry/logging
- model output is structured and validated before proposals are stored
- proposal confirmation is idempotent/transactional to prevent duplicates

## UI fixture pack locked

`UI_FIXTURES.md` defines deterministic prototype content rather than lorem ipsum.

Demo household: `Familie Berger` with two adults and two child profiles.

Signature fixture: a German school-letter import that produces exactly four proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

The demo requires resolving an ambiguous child assignment and editing at least one proposed field before confirming, proving that the review workflow is genuinely interactive rather than a fake success screen.

Visual QA fixture states include normal busy Today, calm Today, schedule conflict, mixed Inbox states, failed analysis, partial confirmation, unresolved/ready Import Review, Plan agenda, Family members, Dark Mode, iPad split layout, Dynamic Type accessibility size and offline pending upload.

## Rejected / deferred directions

- generic calendar + shopping + chores clone
- family social network/chat replacement
- live GPS tracking
- video/audio calls
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic Gmail/Outlook mailbox surveillance in MVP
- autonomous real-world bookings/calls
- medical-advice assistant
- decorative overuse of AI chat UI
- decorative overuse of Liquid Glass
- public `Family Life OS` differentiation claim

## Canonical docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/PROJECT_STATE.md`

## Market validation guardrails

Current category is crowded. FamilyWall already has a broad all-in-one suite; newer products such as familymind and Nori are explicitly AI-first; Fami and other organizers cover calendar/tasks/meal/budget combinations.

Therefore the product may not claim uniqueness merely from AI, voice input, photo extraction, family calendar, chores or all-in-one positioning.

Differentiation remains the quality of the complete ingestion-to-action workflow and how little administration is required after information enters the inbox.

## First implementation slice

The first executable vertical slice must prove one end-to-end scenario:

1. Household + sample members.
2. Today UI.
3. User captures/imports a school-letter fixture.
4. Inbox source moves through processing state.
5. Structured extraction returns four proposals.
6. User opens Import prüfen.
7. User edits at least one ambiguous assignment/date.
8. User confirms selected proposals.
9. Confirmed event/task/deadline/preparation data appears in Plan.
10. Relevant data surfaces on Today.
11. Each generated item links back to its source.

No major adjacent feature module should be allowed to hide a weak version of this loop.

## Visual quality bar

- calm, premium, family-warm but not childish
- system-native typography and controls
- restrained color
- member accents used as identity, not decoration
- clear loading/error/offline states
- Dynamic Type, VoiceOver, Dark Mode, Reduce Motion/Transparency
- iPad layout adapts; no stretched iPhone design
- native iOS 26 tab/navigation Liquid Glass rather than decorative custom glass

## Current Git history on foundation branch

- initial product specification: `8fff64f7ad973debb6c0a808d963e799b2f17029`
- initial design system: `3de8df37bf3d6c2eff82eeabccbfffccd23b3cbf`
- initial project state: `011e6f5a4ebffb18bf5eb3ed236ce2ce8606c17c`
- master-state foundation update: `42278032063a9f5a2b9fa3134a11190fe2ada3f8`
- core UX screen specification: `01353de30c0891f49f8e93d8dcf2349f71043a85`
- brand direction: `2016842f5f897e8eb83f22cc95ecb4fe1c868a6c`
- technical architecture: `a53a7802c8832e9ac603da3f2e40aa3c40a6c961`
- project-state architecture/UX update: `bbaf49292df86a42020a5b368eae2b25e67c6224`
- UI fixture pack: `6eec4c2198713448b251600949d301697bb34f99`
- central master-state UX/architecture checkpoint: `6944a0f0359283472c24cc60a1949c3e23139dac`
- foundation state prepared for merge: `02cf167109d843978bfd5d14b92198559a7df9ed`
- final pre-merge state: `1d654530eeb8f2e827f2036dacb412ff361d9d27`

## Open decisions

1. Final public brand/name and formal-enough EU collision clearance.
2. Exact AI provider/model and structured extraction implementation.
3. Exact subscription pricing and AI quota after cost modeling.
4. Attachment retention defaults and legal/privacy review.
5. Calendar sync/import scope.
6. Child independent-login timing.
7. Final app icon artwork and brand palette.
8. App-specific implementation repository creation.

## Immediate next steps

1. Merge the completed foundation/UX/architecture documentation pass into main so the handoff is durable.
2. Create first visual UI implementation/spec pass for Heute, Inbox and Import prüfen using locked fixtures.
3. Create app-specific repository when implementation begins and repository creation is available.
4. Scaffold SwiftUI app shell + domain/service boundaries.
5. Implement fixture-driven Heute, Inbox and Import prüfen before real AI integration.
6. Implement Supabase schema/RLS and text-fixture ingestion path.
7. Validate vertical slice on iPhone/iPad, Dark Mode and Dynamic Type.
8. Update this state after every major pass.

## Handoff rule

Before continuing Family Life OS in another chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE and UI_FIXTURES. Do not reconstruct scope from memory.