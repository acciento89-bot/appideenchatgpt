# Family Life OS — Project State

Last updated: 2026-08-18
Status: FOUNDATION / VALIDATION
Internal portfolio slot: #011 candidate
Public brand/name: NOT LOCKED
Current branch: `agent/family-life-os-foundation`
Implementation repository: NOT CREATED YET

## Current product thesis

> Put family chaos in. Get an organized plan out.

Family Life OS is centered on a Family Inbox and an ingestion-to-action workflow, not on being another generic shared family calendar.

Primary loop:

**Capture -> Understand -> Review -> Act -> Follow up**

## Accepted decisions

- DACH-first product behavior, architecture extensible internationally.
- iPhone-first native SwiftUI client with intentional iPad adaptation.
- Shared backend is required from v1 because household collaboration is core.
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

## Canonical docs

- `apps/011-family-life-os/PRODUCT_SPEC.md`
- `apps/011-family-life-os/DESIGN_SYSTEM.md`
- `apps/011-family-life-os/PROJECT_STATE.md`

## Market validation guardrails

Current category is crowded. FamilyWall already has a broad all-in-one suite; newer products such as familymind and Nori are explicitly AI-first; Fami and other organizers cover calendar/tasks/meal/budget combinations.

Therefore the product may not claim uniqueness merely from AI, voice input, photo extraction, family calendar, chores or all-in-one positioning.

Differentiation remains the quality of the complete ingestion-to-action workflow and how little administration is required after information enters the inbox.

## First implementation slice

1. Household + sample members.
2. Today UI.
3. Inbox UI.
4. Import text/image.
5. Structured action proposals.
6. Review Import screen.
7. Confirm proposals into events/tasks.
8. Reflect confirmed actions on Today.

## Visual quality bar

- calm, premium, family-warm but not childish
- system-native typography and controls
- restrained color
- member accents used as identity, not decoration
- clear loading/error/offline states
- Dynamic Type, VoiceOver, Dark Mode, Reduce Motion/Transparency
- iPad layout adapts; no stretched iPhone design

## Open decisions

1. Brand/name shortlist and availability/trademark/domain validation.
2. Backend technology and EU hosting choice.
3. Minimum iOS/iPadOS deployment target.
4. Exact subscription pricing and AI quota after cost modeling.
5. Attachment storage and retention defaults.
6. Calendar sync/import scope.
7. Child login timing.
8. App icon and final visual identity.

## Immediate next steps

1. Update central `docs/APP_FACTORY_STATE.md` with #011 candidate and foundation state.
2. Perform naming pass with current App Store/web collision checks.
3. Select backend architecture.
4. Create app-specific repository when implementation begins and repository creation is available.
5. Scaffold native SwiftUI project.
6. Build real UI fixtures for Today, Inbox, Review Import, Plan and Family.
7. Run first simulator/iPad/Dynamic Type design review.
8. Update this state after every major pass.

## Handoff rule

Before continuing Family Life OS in another chat, read this file first, then PRODUCT_SPEC and DESIGN_SYSTEM. Do not reconstruct scope from memory.