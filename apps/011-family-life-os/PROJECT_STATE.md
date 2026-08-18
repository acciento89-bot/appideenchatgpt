# Family Life OS — Project State

Last updated: 2026-08-18
Status: FOUNDATION MERGED / UX LOCKED / ARCHITECTURE SELECTED
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Foundation PR: `#3` — MERGED
Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`
Central App Factory state checkpoint: `f40aacb932990cf50835510d8196ad5ed9f9eaf1`
Implementation repository: NOT CREATED YET

## Product thesis

> Put family chaos in. Get an organized plan out.

The product is centered on a Family Inbox and an ingestion-to-action workflow, not on being another generic shared family calendar.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

## Accepted decisions

- DACH-first behavior, globally extensible architecture.
- iPhone-first native SwiftUI client with intentional iPad adaptation.
- iOS/iPadOS 18+ deployment direction; iOS 26+ visual APIs gated by availability.
- Shared backend required from v1.
- Supabase selected as foundation backend.
- Central EU / Frankfurt preferred region.
- Postgres + Row Level Security as primary household isolation boundary.
- Private object storage for family documents.
- AI processing server-side only; no provider/service-role secrets in app.
- Family Inbox is the core differentiation surface.
- MVP sources: photo, screenshot/image, PDF/document share, pasted/direct text and voice.
- Direct mailbox surveillance is not MVP.
- AI creates editable proposals only; users confirm before canonical data is created.
- Confirmed items retain provenance to their source.
- Core destinations: Heute, Inbox, Plan, Familie.
- Settings are not a fifth permanent tab; capture is an action, not a tab.
- MVP actions: events, tasks, deadlines, payments and preparation actions/reminders.
- Family Pro recurring subscription is provisional monetization because AI/storage/sync create recurring cost.
- German + English localization architecture from first build.
- Child/guest permission architecture from day one.
- `Import prüfen` is the signature trust-boundary screen and must be excellent before scope expands.

## UX locked for first prototype

### Heute

- conditional attention only when needed
- factual compact family brief from confirmed data only
- lightweight chronological timeline
- conditional tomorrow/preparation section
- calm empty state

### Inbox

- raw incoming family information + processing state
- simple `Offen / Verarbeitet / Alle` filters
- explicit upload/analyze/review/failure states
- source remains available for provenance/recovery

### Import prüfen

- original source always reachable
- independently editable proposals
- types: Termin / Aufgabe / Frist / Zahlung / Vorbereitung
- uncertainty highlighted at the specific field
- confirmation disabled only for unresolved required fields
- no silent canonical writes

### Plan

- Agenda-first MVP
- member filtering
- full calendar visualization follows only if vertical slice is strong

### Familie

- household + members
- roles: Owner / Adult / Child / Guest-Caregiver
- sensitive permissions enforced server-side

## Brand state

Public name remains open and must not block implementation.

`Family Life OS` is an internal codename only. It should not become public positioning without re-evaluation because competitor Famiqo currently uses `Family Life Operating System`.

First-pass rejected directions:

- Famiqo
- Kinora
- Familoop
- Kinbox

Brand character:

- calm
- capable
- warm
- trustworthy
- discreet
- premium without luxury styling

Preferred icon concept: **Gather -> Order** — several rounded loose pieces becoming one organized form.

No cartoon-family, robot/AI-sparkle or generic house/checkmark identity.

Final public name requires App Store/web + EUIPO/DPMA/domain checks before lock.

## Technical architecture

Canonical architecture: `TECH_ARCHITECTURE.md`.

Core stack:

- SwiftUI
- Swift concurrency / Observation
- local cache/offline queue where appropriate
- Supabase Auth
- Supabase Postgres
- RLS
- private Supabase Storage
- Realtime where useful
- server/Edge Function AI orchestration
- APNs-backed server notifications

Rules:

- backend is canonical for collaborative household data
- views do not issue raw backend queries directly
- every client-exposed household table uses RLS
- no public family-document bucket
- no raw family documents in generic telemetry/logs
- model output is structured and validated
- confirmation is transactional/idempotent

Initial core entities:

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

A child/guest may exist as a household member without an authenticated user account.

## UI fixture pack locked

Demo household: `Familie Berger` with Mara, Jonas, Lina and Ben.

Signature fixture is a German school letter that yields exactly four proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

The first review must resolve an ambiguous child assignment and edit at least one proposed field before confirmation.

Visual QA fixtures include busy/calm/conflict Today, mixed Inbox states, failed analysis, partial processing, unresolved and ready Import Review, Plan agenda, Family list, Dark Mode, iPad split view, Dynamic Type and offline capture.

## Deferred / rejected for MVP

- generic calendar + shopping + chores clone
- family chat/social network
- live GPS
- video/audio calling
- bank integration/full budgeting
- meal/recipe platform
- complex chore reward economy
- automatic mailbox surveillance
- autonomous real-world bookings/calls
- medical-advice assistant
- generic AI-chat-first interface
- decorative Liquid Glass everywhere

## Canonical docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/UX_SCREEN_SPEC.md`
- `apps/011-family-life-os/BRAND_DIRECTION.md`
- `apps/011-family-life-os/TECH_ARCHITECTURE.md`
- `apps/011-family-life-os/UI_FIXTURES.md`
- `apps/011-family-life-os/PROJECT_STATE.md`

## First executable vertical slice

1. household + sample members
2. Heute UI
3. import school-letter fixture
4. Inbox processing state
5. four structured proposals
6. open `Import prüfen`
7. resolve ambiguous assignment / edit one field
8. confirm selected proposals
9. confirmed items appear in Plan
10. relevant items surface in Heute
11. every created item links back to source

No adjacent feature module may hide a weak version of this loop.

## Visual quality bar

- calm, premium, family-warm but not childish
- system-native typography and controls
- restrained color
- person accents as identity, not decoration
- explicit loading/error/offline states
- Dynamic Type, VoiceOver, Dark Mode, Reduce Motion/Transparency
- real adaptive iPad layout
- iOS 26 native Liquid Glass primarily in functional/navigation surfaces

## Foundation history

The original PR #2 became stale because `main` advanced in parallel with KeepMeter. It was intentionally not force-merged. A clean current-main-based branch was created and merged as PR #3 so no KeepMeter state was rolled back.

Clean foundation commits before squash merge:

- product specification: `08f2af30ef949593763da20c8c460fa5b577c99f`
- design system: `ef7b1231db5a5bf6e9a213790fab092472fb90f0`
- core UX specification: `c0e18ab6eabd7a885ba832b2f1f18dd3433ad31d`
- brand direction: `b6decbe2327773dc41e815a76fcd3e8adf1f9cd9`
- technical architecture: `746731e10cfaa8641d6663ff67c3c09105f06ee8`
- UI fixtures: `16d73a2aa6ceb7427feee1c1c3b0cc6891075cbb`
- project state: `809166a25b4adaa7a5a88a0262afaad8c2105a26`

Merged foundation commit: `cd86aa4980133020b05629f9930aff598d9f9b35`.

## Open decisions

1. final public brand/name and EU collision clearance
2. exact AI provider/model and extraction implementation
3. subscription pricing and AI quota after cost modeling
4. attachment retention/privacy/legal defaults
5. calendar interoperability scope
6. child independent-login timing
7. final icon artwork and palette
8. app-specific implementation repository creation

## Immediate next steps

1. Create the app-specific implementation repository when repository creation is available.
2. Scaffold SwiftUI app shell + domain/service boundaries.
3. Implement fixture-driven Heute, Inbox and Import prüfen before real AI integration.
4. Add Supabase schema/RLS and text-fixture ingestion path.
5. Validate vertical slice on iPhone/iPad, Dark Mode and Dynamic Type.
6. Only after the core loop is excellent, expand Plan/calendar and adjacent modules.
7. Update this project state and the central App Factory state after every major pass.

## Handoff rule

Before continuing this app in a new chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE and UI_FIXTURES. Do not reconstruct scope from memory.