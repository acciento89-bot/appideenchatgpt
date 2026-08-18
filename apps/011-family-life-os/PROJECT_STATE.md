# Family Life OS — Project State

Last updated: 2026-08-18
Status: EXECUTABLE UI + ADAPTIVE QUALITY PASS GREEN
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current canonical branch: `main`
Implementation repository: NOT CREATED YET — prototype temporarily lives in the central App Factory repo

## Current checkpoints

- Foundation PR: `#3` — MERGED
- Foundation merge commit: `cd86aa4980133020b05629f9930aff598d9f9b35`
- First executable UI PR: `#4` — MERGED
- First executable UI merge commit: `2c9ad0a3400321bc692cafaa9b492c30e9bbb8ec`
- First green prototype CI run: `32180561109`
- Adaptive UI / accessibility PR: `#5` — MERGED
- Adaptive UI / accessibility merge commit: `aa70b24ebb21d472c66ac13d790096510f65a309`
- Final green quality-pass CI run: `32182627951`
- Final quality-pass head before squash: `fc957da0e5f55adf6f5f71d5834a7905c6359e43`

## Product thesis

> Put family chaos in. Get an organized plan out.

The product is centered on a Family Inbox and an ingestion-to-action workflow, not on being another generic shared family calendar.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

`Import prüfen` is the signature trust boundary. AI/extraction output is proposal data only until the user explicitly confirms it.

## Accepted decisions

- DACH-first behavior, globally extensible architecture.
- Native SwiftUI client.
- iPhone first, with intentional iPad adaptation rather than a stretched phone UI.
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
- Family Pro recurring subscription remains provisional because AI/storage/sync create recurring cost.
- German + English localization architecture from first build.
- Child/guest permission architecture from day one.
- Real backend/AI integration must not weaken review-before-confirmation.

## Executable prototype location

Current temporary implementation:

`apps/011-family-life-os/prototype/`

Standalone project:

`apps/011-family-life-os/prototype/FamilyLifePrototype.xcodeproj`

Shared scheme:

`FamilyLifePrototype`

Provisional bundle id:

`de.kamilunavo.familyprototype`

Deployment target:

- iOS/iPadOS 18.0
- iPhone + iPad target families

Dedicated build workflow:

`.github/workflows/family-life-os-prototype-build.yml`

The connected GitHub tooling still does not expose repository creation. Move the implementation to an app-specific repository when repository creation becomes available; do not let the central prototype path become permanent architecture.

## Implemented product flow

### App shell

Compact width:

- native `TabView`
- Heute
- Inbox
- Plan
- Familie
- independent navigation stacks

Regular width / iPad:

- adaptive `NavigationSplitView`
- persistent sidebar for Heute / Inbox / Plan / Familie
- detail destination changes with sidebar selection
- content widths are constrained so large screens do not become oversized phone cards

### Heute

Implemented:

- conditional attention surface
- factual family brief
- chronological family timeline
- task completion control
- member identity via avatar/name + accent
- tomorrow/preparation section driven from plan data
- calm state
- real schedule-overlap detection for items sharing a family member
- conflict attention row
- conflict indicators on affected timeline rows
- semantic light/dark compatible backgrounds

Deterministic Today QA fixtures:

- busy / standard
- calm
- conflict
- Dark Mode
- Accessibility Dynamic Type

### Inbox

Implemented statuses:

- `Wartet auf Upload`
- `Wird hochgeladen`
- `Wird analysiert`
- `Prüfen`
- `Teilweise übernommen`
- `Erledigt`
- `Analyse fehlgeschlagen`

Implemented behavior:

- filters: Offen / Verarbeitet / Alle
- source types: image / PDF / text / voice
- offline queued copy: `Wird synchronisiert, sobald du wieder online bist.`
- processing spinner
- failure presentation
- proposal count
- capture menu entry points
- review/partial rows are interactive
- non-actionable processing/completed/error rows are not dead buttons
- empty filtered state uses a meaningful next action

### Import prüfen

This remains the critical trust-boundary screen.

Implemented:

- original source remains available throughout review
- compact-width stacked layout
- regular-width two-column source + proposal layout
- four school-letter proposals are editable
- proposal inclusion can be toggled independently
- native date/time/reminder editing
- ambiguous child assignment is explicitly unresolved
- unresolved required assignment blocks confirmation
- assigning Lina resolves the blocker
- source and proposal controls have VoiceOver labels/hints
- stable accessibility identifiers exist for critical review actions
- accessibility text sizes reflow date controls vertically
- confirmation converts accepted proposals into canonical in-memory `PlanItem` values
- source is marked completed after confirmation
- additional deterministic `readyImport` fixture verifies the unblocked state

### Plan

Implemented:

- Agenda-first list
- day grouping
- household member filter chips
- event/task/deadline/payment/preparation rows
- task/preparation completion support
- `Aus Import` provenance indicator
- empty filtered state
- 44pt practical completion target
- Agenda row reflow at accessibility Dynamic Type sizes

### Familie

Implemented:

- household summary
- Owner / Adult / Child role display
- adult full-access vs child-without-login distinction
- permission architecture messaging
- member accents and initials
- large-text member-row adaptation
- nonfunctional invite action explicitly disabled in prototype rather than pretending to work

## Accessibility / appearance baseline now implemented

Current UI pass includes:

- Dynamic Type-aware layouts
- dedicated accessibility-size reflow for dense rows/forms
- VoiceOver labels and hints for critical controls
- stable accessibility identifiers for important interaction points
- non-color-only family identity
- minimum practical touch targets on key controls
- Light/Dark semantic system surfaces
- Dark Mode previews
- accessibility-size previews
- regular-width previews
- meaningful empty states
- explicit offline/failure states

This is an implementation baseline, not a claim that full manual VoiceOver/device QA has already been completed. Physical-device and interactive accessibility QA remain future release gates.

## CI / compiler history

### First executable slice

Run `32180375921` failed on one Swift `foregroundStyle` type-inference issue in `ImportReviewView`.

Fix: explicit `Color.primary` / `Color.orange`.

Run `32180561109` completed **SUCCESS**. PR #4 merged only after green CI.

### Adaptive quality pass

Initial PR #5 run `32182317924` caught an iOS API mismatch in the new regular-width sidebar: the direct non-optional `List(selection:)` binding was not available for the targeted iOS API.

Fix: the sidebar now uses an explicit optional `Binding<AppSection?>` and writes resolved selection back to the non-optional app state.

Run `32182408384` completed **SUCCESS** after that functional fix.

Two non-functional preview warnings remained because `.previewDevice(...)` is ignored inside the modern `#Preview` macro.

Fix: iPad/regular-width previews now force `.environment(\.horizontalSizeClass, .regular)` instead. A ready-to-confirm Import Review preview was added at the same time.

Final run `32182627951` completed **SUCCESS** on head `fc957da0e5f55adf6f5f71d5834a7905c6359e43`.

App-code log check after the final run:

- no Swift compile warnings from the prototype source
- no remaining `previewDevice` warnings
- build ended with `BUILD SUCCEEDED`
- remaining runner/Xcode informational warnings are external to app source: AppIntents metadata skipped because the prototype does not link AppIntents, plus a GitHub Actions Node-version deprecation notice from `actions/checkout@v4`

PR #5 was squash-merged only after the final successful build.

Merged adaptive-quality checkpoint:

`aa70b24ebb21d472c66ac13d790096510f65a309`

## Signature fixture

Demo household: `Familie Berger` with Mara, Jonas, Lina and Ben.

The school-letter source produces exactly four proposals:

1. Klassenfahrt event
2. permission-slip deadline/task
3. 35 EUR payment reminder
4. lunchpack/preparation action

The initial state requires an ambiguous child assignment to be resolved. The user can edit proposals before confirmation. Confirmed items become PlanItems and retain source provenance.

## Brand state

Public name remains open and must not block implementation.

`Family Life OS` is an internal codename only. Do not use it as locked public positioning because competitor territory already overlaps with the `Family Life Operating System` phrase.

First-pass rejected naming directions:

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

Avoid cartoon-family, robot/AI-sparkle and generic house/checkmark identity.

Final public name requires current App Store/web + EUIPO/DPMA/domain checks before lock.

## Technical architecture direction

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

1. Implement the Supabase schema and RLS policies for households, members, source items, proposals and plan items.
2. Introduce repository/service interfaces so the current views stop depending directly on `DemoStore` as the eventual source of truth.
3. Prove the first real ingestion path with the plain-text school-letter fixture: source -> structured proposal records -> review -> transactional confirmation -> plan items.
4. Add authentication/household membership only to the minimum needed for secure shared data; do not expand onboarding scope prematurely.
5. Add photo/PDF/private Storage/OCR only after the text data contract is proven.
6. Add real AI extraction only behind validated structured output and the existing explicit review boundary.
7. Perform physical iPhone/iPad + manual VoiceOver/appearance QA before any TestFlight release claim.
8. Move to an app-specific repository when repository creation becomes available.
9. Update this state and the central App Factory state after every major pass.

## Handoff rule

Before continuing this app in a new chat, read this file first, then PRODUCT_SPEC, DESIGN_SYSTEM, UX_SCREEN_SPEC, BRAND_DIRECTION, TECH_ARCHITECTURE, UI_FIXTURES and the prototype README. Inspect current `main` and CI state before changing code. Continue from the Supabase/repository-interface next steps; do not reconstruct scope from chat memory.