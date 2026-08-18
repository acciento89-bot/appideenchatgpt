# Family Life OS — Project State

Last updated: 2026-08-18
Status: FIRST EXECUTABLE UI VERTICAL SLICE GREEN
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Foundation PR: `#3` — MERGED
Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`
UI prototype PR: `#4` — MERGED
UI prototype merge commit: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
Green prototype CI run: `32180561109`
Implementation repository: NOT CREATED YET — prototype temporarily lives in the central App Factory repo

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
- Real backend/AI integration must not begin by weakening the review-before-confirmation rule already proven in the fixture flow.

## First executable SwiftUI vertical slice — GREEN

The first real iOS/iPadOS project now exists under:

`apps/011-family-life-os/prototype/`

This is a temporary implementation location because the connected GitHub tooling cannot create a new repository in this session. The prototype must move to an app-specific repository once repository creation is available; do not let the temporary central location become the permanent architecture.

### Implemented app shell

Four native SwiftUI tabs:

1. Heute
2. Inbox
3. Plan
4. Familie

Each is wrapped in its own `NavigationStack`. Import review is presented as a modal workflow.

### Implemented domain/data model

Fixture-driven domain types now exist for:

- household members / roles / accents
- plan items
- source/inbox items
- action proposals
- event / task / deadline / payment / preparation kinds

`DemoStore` uses the Observation framework and owns the interactive prototype state.

### Implemented Heute

- conditional attention surface
- compact factual family brief
- chronological family timeline
- task completion affordance
- member identity via avatar/name + accent
- tomorrow/preparation section
- semantic system backgrounds suitable for light/dark mode

### Implemented Inbox

- filters: Offen / Verarbeitet / Alle
- source types: image / PDF / text / voice
- upload / processing / review / partial / done / failed state model
- processing spinner
- failure copy
- proposal count
- capture menu entry points

### Implemented `Import prüfen`

This signature trust-boundary flow is interactive, not a static mockup.

- original source can be expanded/read
- four school-letter proposals are editable
- proposal inclusion can be toggled independently
- date/time/reminder fields use native `DatePicker`
- ambiguous member assignment is explicitly unresolved
- confirmation button is blocked while a required assignment is unresolved
- assigning Lina resolves the blocker
- selected proposals can be confirmed
- confirmation converts proposal data into canonical in-memory `PlanItem` values
- source is marked completed after confirmation

### Implemented Plan

- Agenda-first list
- day grouping
- household member filters
- event/task/deadline/payment/preparation rows
- task/preparation completion support
- subtle `Aus Import` provenance indicator

### Implemented Familie

- household summary
- Owner / Adult / Child role display
- adult full-access vs child-without-login distinction
- permission architecture messaging
- member accents and initials

## Build gate

A standalone Xcode project and shared scheme now exist:

- `prototype/FamilyLifePrototype.xcodeproj`
- scheme: `FamilyLifePrototype`
- provisional bundle id: `de.kamilunavo.familyprototype`
- iOS/iPadOS deployment target: 18.0
- target device families: iPhone + iPad

Dedicated CI workflow:

`.github/workflows/family-life-os-prototype-build.yml`

Build command uses an unsigned generic iOS Simulator destination.

### CI history

Run `32180375921` failed on one Swift type-inference issue in `ImportReviewView`: a ternary `foregroundStyle` mixed two concrete `ShapeStyle` types.

The code was corrected to use explicit `Color.primary` / `Color.orange`.

Run `32180561109` then completed **SUCCESS** on head `c0d19f94074c7288bb1838541638d2d49b329331`.

PR #4 was squash-merged only after the green simulator build.

Merged UI checkpoint:

`2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`

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
- sensitive permissions enforced server-side once backend is connected

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

Core stack direction:

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

The first review resolves an ambiguous child assignment and supports editing before confirmation.

Visual QA fixture requirements still include busy/calm/conflict Today, mixed Inbox states, failed analysis, partial processing, unresolved and ready Import Review, Plan agenda, Family list, Dark Mode, iPad split view, Dynamic Type and offline capture.

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
- `apps/011-family-life-os/prototype/README.md`

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

1. Do a dedicated visual/interaction QA pass of the green prototype using the locked fixture matrix.
2. Add proper SwiftUI previews for normal/busy/error/unresolved states and iPad regular width.
3. Refine adaptive iPad navigation/split-view behavior rather than merely relying on the shared tab shell.
4. Add Dark Mode, Dynamic Type and VoiceOver regression checks/adjustments.
5. Create the app-specific implementation repository once repository creation is available and move the prototype without history loss.
6. Then implement the Supabase schema + RLS and replace fixture persistence with repository interfaces.
7. Start real ingestion with the plain-text school-letter path first; add photo/PDF/OCR only after the data contract is proven.
8. Keep real AI extraction behind structured proposals and explicit review.
9. Update this state and the central App Factory state after every major pass.

## Handoff rule

Before continuing this app in a new chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE, UI_FIXTURES and the prototype README. Inspect current `main` and CI state before changing code. Do not reconstruct scope from memory.