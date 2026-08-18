# Family Life OS — Design System v0.1

Status: FOUNDATION
Date: 2026-08-18
Brand name: NOT LOCKED
Platform focus: iPhone first, adaptive iPad

## 1. Design objective

The interface must feel calm, trustworthy and premium enough for information families care about, without looking corporate or clinical.

The product should visually communicate:

- calm over chaos
- clarity over density
- family warmth without childish decoration
- trust over novelty
- action over administration

The design must not look like a generic SaaS dashboard squeezed onto an iPhone.

## 2. Apple-platform direction

Use native SwiftUI patterns and standard platform components as the default.

On iOS 26+, Liquid Glass belongs primarily to the functional/navigation layer. Do not apply glass indiscriminately to content cards. Standard materials/backgrounds should carry the content layer.

Principles:

- system tab/navigation behavior first
- native sheets and menus
- SF Symbols before custom iconography
- Dynamic Type
- accessibility contrast
- Reduce Motion / Reduce Transparency compatibility
- custom visual treatment only where it improves hierarchy

## 3. Information hierarchy

Every main screen should answer one primary question.

### Heute

"What does my family need to know or do now?"

### Inbox

"What came in, and what still needs to be understood or confirmed?"

### Plan

"What is happening and who is responsible?"

### Familie

"Who belongs to this household and what can they access?"

Avoid screens that simultaneously become calendar + inbox + chat + statistics + shopping + finance dashboards.

## 4. Navigation

### iPhone

System TabView with four persistent destinations:

- Heute — house / sun / checkmark family-oriented SF Symbol selected after visual tests
- Inbox — tray
- Plan — calendar
- Familie — person.3

Settings/account lives behind the family/account control.

A global quick-add/import action should be reachable in one tap without creating a fifth navigation destination.

### iPad

Use adaptive NavigationSplitView where appropriate. Do not scale up iPhone cards into oversized empty panels.

The iPad layout may show:

- sidebar: major sections / filters
- content: agenda/inbox list
- detail: selected event, task or source document

## 5. Visual character

Keywords:

- soft
- composed
- modern
- light
- capable
- human

Avoid:

- rainbow gradients everywhere
- cartoon family illustrations in the working UI
- excessive shadows
- neon colors
- giant dashboard statistics
- tiny text inside dense cards
- floating glass on every card
- emoji as primary navigation icons

## 6. Color system

Until branding is locked, use semantic system colors rather than hard-coding a final brand palette.

### Base

- system background
- secondary system background
- grouped background where native
- primary / secondary / tertiary label colors

### Family-member accents

Each PersonProfile gets one persistent accent. The accent is used for identity, not for painting entire screens.

Suggested semantic family accent set to validate visually:

- blue
- green
- orange
- purple
- pink
- teal
- indigo
- mint

Rules:

- never rely on color alone to identify a person
- include name/avatar/initial where ambiguity matters
- preserve contrast in light/dark mode
- use accents for chips, leading markers, avatars, calendar identity and selected filters

### Status colors

Use semantic meaning consistently:

- red: genuinely urgent/overdue/destructive
- orange: needs attention soon
- green: complete/confirmed
- blue: informational/normal action

Do not turn every due item red.

## 7. Typography

Use San Francisco through system text styles.

Preferred hierarchy:

- largeTitle/title: screen context sparingly
- title2/title3: section focus
- headline: card/item title
- body: primary descriptive text
- subheadline/footnote: supporting metadata

Rules:

- no fixed-size typography for core content when a semantic text style works
- support Dynamic Type
- avoid ultra-light weights
- do not use all caps for major navigation or section headings
- truncate only low-value metadata; essential dates/names should wrap or reflow

## 8. Spacing and layout tokens

Use a simple 4-point rhythm.

- 4: micro spacing
- 8: compact internal spacing
- 12: related controls
- 16: standard card/content padding
- 20: screen-side comfortable spacing when appropriate
- 24: section separation
- 32: major separation

Do not create a unique spacing value for every screen.

## 9. Shape system

Content surfaces:

- standard cards: approximately 16pt corner radius, adjusted only if platform conventions make another value more natural
- compact chips: capsule
- avatars: circle
- modal/sheet shape: system-defined

Keep related control shapes consistent.

On iOS 26+, glass-styled interactive controls should use native glass button/effect APIs and coherent shapes rather than custom blur recreations.

## 10. Elevation and materials

Content cards should generally use:

- system/grouped backgrounds
- subtle separation
- borders only when required for clarity
- minimal shadowing

Liquid Glass:

- navigation bars/tab bars/toolbars can receive native system appearance
- use glassProminent only for truly primary transient actions
- custom glass surfaces must be rare
- no glass as a decorative content-card background

## 11. Core component inventory

### MemberAvatar

Shows:

- image OR initials
- member accent
- optional small role/status marker

Variants:

- 24 compact
- 32 list
- 40 standard
- 56 profile

### MemberChip

For filters and assignments.

Contains:

- avatar/initial
- name
- selected state

### FamilyAgendaRow

For events/deadlines.

Structure:

- time / all-day marker
- member identity marker
- title
- optional location
- optional status/action metadata

Must remain readable with large Dynamic Type.

### FamilyTaskRow

Structure:

- completion control
- title
- responsible member
- due state
- source indicator when generated from inbox

Completion animation should be brief and optional under Reduce Motion.

### InboxSourceCard

Structure:

- source thumbnail/icon
- short title/source description
- processing/review status
- received timestamp
- number/type of proposed actions

States:

- importing
- processing
- needs review
- complete
- failed

### ProposalCard

Shows one AI-proposed action.

Structure:

- action type icon
- editable title
- date/time
- person assignment
- optional secondary fields
- include/exclude toggle or selection
- "derived from source" context

Uncertain data should be highlighted without making the entire card look like an error.

### AttentionBanner

Use only for high-value actionable states:

- 2 items need review
- sync failed
- permission required for a requested feature

Not for marketing.

### EmptyState

Must include:

- direct explanation
- one primary next action
- optional example

No huge decorative illustration required.

## 12. Screen blueprint — Heute

Suggested top-to-bottom composition:

1. compact date/greeting context
2. urgent/needs-review item only if present
3. "Heute" agenda
4. "Zu erledigen" tasks
5. "Demnächst" preparation/deadline preview
6. subtle quick import affordance

Do not show empty sections.

Example:

```
Dienstag, 18. August
Guten Abend

[ 2 Dinge brauchen deine Prüfung ]

Heute
07:30  Schule · Nico
16:00  Zahnarzt · Nico   Diana

Zu erledigen
○ Einverständniserklärung unterschreiben   bis heute
○ 35 € Klassenfahrt überweisen            bis Fr

Demnächst
Do · Sporttasche vorbereiten
Fr · Schulausflug
```

The UI should feel like an intelligent briefing, not a task database.

## 13. Screen blueprint — Inbox

Top area:

- title
- filter/status control if needed
- import action

List groups:

- Needs Review
- Processing
- Done / Recently handled

Each source item immediately communicates what happened.

Example:

```
Inbox

Braucht Prüfung
[ Elternbrief · Foto ]
4 Aktionen erkannt
Heute 18:42

Verarbeitet
[ WhatsApp-Screenshot ]
1 Termin übernommen
Gestern
```

## 14. Screen blueprint — Review Import

This is a critical conversion/quality screen.

Structure:

1. source preview with expand/open action
2. extraction summary
3. editable proposal cards
4. person assignment if needed
5. prominent confirmation action

Example:

```
4 Aktionen erkannt

✓ Klassenfahrt
  18. September · 07:30 · Nico

✓ Einverständniserklärung abgeben
  bis 1. September · Nico

✓ 35 € überweisen
  bis 5. September

✓ Lunchpaket vorbereiten
  17. September

[ 4 Aktionen übernehmen ]
```

If the model is unsure about a date/person, that exact field is marked "Bitte prüfen".

Do not display meaningless model confidence percentages to ordinary users.

## 15. Screen blueprint — Plan

Default: agenda/list.

Controls:

- date navigation
- family-member filter
- agenda/week switch when needed

Month view should not become mandatory for MVP.

Events/tasks generated from an inbox item should offer a small provenance affordance such as "Quelle anzeigen" in detail.

## 16. Screen blueprint — Family

Top:

- household name
- member stack

Member row:

- avatar
- name
- role
- invite/account status

Actions:

- add person
- invite adult
- later: guest access

Do not expose billing and technical account status in the main member list unless required.

## 17. Interaction principles

### Confirmation

AI-derived actions are proposals until confirmed.

### Destructive actions

Use explicit confirmation where deletion affects shared family data or source documents.

### Undo

Prefer reversible actions/undo for quick task completion or assignment changes where feasible.

### Loading

Never freeze the whole interface while AI processes a document. Import should become a visible InboxItem and processing can continue while the user navigates elsewhere.

### Error states

Explain what failed and preserve the user’s source.

Bad:

"Error 500"

Good:

"Der Brief konnte gerade nicht ausgewertet werden. Das Foto ist gespeichert. Erneut versuchen."

## 18. Motion and haptics

Motion should reinforce state changes, not decorate.

Use:

- subtle completion feedback
- source -> proposal transition
- optional matched transitions when they improve continuity

Avoid:

- bouncing cards
- constant shimmer
- celebratory confetti for routine adult actions

Respect Reduce Motion.

Use haptics sparingly for:

- successful multi-action confirmation
- destructive confirmation
- task completion if it remains pleasant under repeated use

## 19. Accessibility baseline

Required from first implementation pass:

- Dynamic Type
- VoiceOver labels/hints
- minimum practical touch target around platform guidance
- sufficient contrast
- non-color person identification
- Reduce Motion support
- Reduce Transparency compatibility
- meaningful button labels instead of icon-only ambiguity
- accessibility identifiers for critical UI tests

## 20. Content tone

German copy should be short, calm and practical.

Preferred:

- "4 Aktionen erkannt"
- "Bitte Datum prüfen"
- "Für Nico"
- "Morgen vorbereiten"
- "Quelle anzeigen"

Avoid:

- "Unsere revolutionäre KI hat magisch…"
- overuse of exclamation marks
- guilt-driven alerts
- infantilizing parent copy

## 21. First visual prototype scope

The first coded UI prototype should contain realistic fixture data for:

1. Today — normal day
2. Today — overloaded day + review needed
3. Inbox — processing/review/complete states
4. Review Import — school-letter example
5. Plan — agenda
6. Family — two adults + two children

Each screen must have:

- light mode preview
- dark mode preview
- at least one large Dynamic Type sanity check
- iPhone preview
- iPad adaptation where relevant

## 22. Design acceptance gates

A screen is not accepted merely because it looks attractive.

It must pass:

1. Can a first-time user identify the primary action within a few seconds?
2. Is the most important family information visually first?
3. Does it still work with long German text?
4. Does it remain usable in Dark Mode?
5. Does Dynamic Type break the hierarchy?
6. Is any AI action clearly distinguishable from confirmed data?
7. Can the user understand who an item belongs to without relying only on color?
8. Is the UI using Apple platform conventions rather than fighting them?
9. Is visual complexity lower than the organizational complexity it is trying to solve?

## 23. Next design pass

- brand/name exploration
- icon direction
- exact Today screen visual composition
- Inbox import interaction
- Review Import interaction states
- iPad split-view composition
- onboarding visual prototype
- paywall only after core product value is visually proven