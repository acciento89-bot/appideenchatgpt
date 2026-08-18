# Family Life OS — Core UX / Screen Specification v0.2

Status: LOCKED FOR FIRST PROTOTYPE
Date: 2026-08-18
Public brand: not locked
Primary platform: iPhone, adaptive iPad
Minimum target direction: iOS/iPadOS 18+, with iOS 26+ visual enhancements gated by availability

## Product interaction principle

The app must reduce family administration. Every core screen has one question:

- **Heute:** What needs our attention now?
- **Inbox:** What came in and still needs processing?
- **Plan:** What is happening, when, and who owns it?
- **Familie:** Who is involved and what can they access?

The critical product loop is:

`Capture -> Understand -> Review -> Confirm -> Surface at the right time`

AI is not a destination or chat tab. AI works behind the workflow and produces reviewable structured proposals.

---

## 1. App shell

### iPhone navigation

Persistent system `TabView` with four top-level destinations:

1. **Heute** — `house.fill` or final validated equivalent
2. **Inbox** — `tray.fill`
3. **Plan** — `calendar`
4. **Familie** — `person.3.fill`

Rules:

- tabs are navigation only; no action button disguised as a tab
- each tab owns an independent `NavigationStack`
- selected tab preserves its navigation state when switching tabs
- settings/profile opens from a toolbar/account control, not as a fifth tab
- global capture is accessible from Heute and Inbox within one tap

### iPad navigation

Use an adaptive split layout rather than a stretched phone UI.

Preferred structure:

- compact width: same four-tab navigation as iPhone
- regular width: sidebar/top-level navigation + content + optional detail
- Inbox can use source list + selected source/review detail side by side
- Plan can use agenda/calendar list + selected item detail

---

## 2. Heute — primary home screen

### Purpose

Give the household a calm, actionable brief for the current day. It must not become a duplicate full calendar.

### Navigation bar

Leading/context:

- large title: **Heute**
- secondary greeting/date may appear beneath content header, not as a permanently giant hero

Trailing:

- household/member avatar button -> account/household/settings menu
- quick capture action -> capture menu

### Screen order

#### A. Attention section — conditional

Only visible when something genuinely requires attention.

Examples:

- `2 Dinge brauchen deine Freigabe`
- `Einverständniserklärung morgen fällig`
- `35 € für Klassenfahrt bis Freitag`

Presentation:

- one compact high-priority surface
- maximum 3 items before a `Alle anzeigen` action
- overdue/destructive status may use red
- upcoming attention uses orange or neutral emphasis, not red everywhere

No empty attention card when there is nothing urgent.

#### B. Family brief

A lightweight system-generated summary, not a chatbot bubble.

Example:

> Ruhiger Vormittag. Ab 15:30 sind drei Termine nah beieinander. Nicos Fußballtasche sollte heute Abend vorbereitet werden.

Rules:

- maximum roughly 2–3 lines in normal state
- factual, sourced from confirmed household data
- no invented advice
- tap reveals which confirmed items produced the summary
- if confidence is insufficient, omit the summary rather than hallucinate

#### C. Timeline: Jetzt / Später

Rows are chronological and visually lightweight.

Each row contains:

- time or `Ganztägig`
- event/task icon
- title
- assigned member avatar + name/initial when useful
- optional location or compact metadata
- completion/action affordance only if the item is actionable

Examples:

`15:30  Zahnarzt · Nico`
`17:00  Fußballtraining · Nico`
`18:15  Fiona abholen · Diana`

Rules:

- appointments and tasks share a timeline but retain distinct symbols/interaction
- no giant card per appointment
- member color is a leading marker/accent, never the sole identity
- overlapping events may show a subtle conflict indicator

#### D. Prepare for tomorrow — conditional

Shows preparation actions generated from confirmed events.

Example:

- `Lunchpaket für Klassenfahrt vorbereiten`
- `Versicherungskarte einpacken`

Only appears when actions exist.

### Empty state

Copy direction:

> Heute ist alles ruhig.
> Neue Infos kannst du über die Inbox oder direkt per Foto, Datei, Text oder Sprache hinzufügen.

Primary action: `Etwas hinzufügen`

Do not punish an empty day with fake statistics or placeholder cards.

---

## 3. Global capture menu

### Entry points

- Heute toolbar
- Inbox toolbar / prominent empty-state action
- system Share Extension for external content

### Capture options for MVP

1. **Foto aufnehmen**
2. **Foto/Screenshot wählen**
3. **Dokument/PDF importieren**
4. **Text einfügen**
5. **Sprechen**

Future, not MVP:

- monitored mailbox
- WhatsApp direct integration
- school-platform integrations

### Behavior

After source selection:

1. show immediate local preview
2. create a pending Inbox source
3. upload/parse asynchronously
4. show explicit processing state
5. when extraction completes, route to Review Import or show review badge in Inbox

Never trap the user behind a blocking spinner if upload/processing can continue asynchronously.

---

## 4. Inbox

### Purpose

One trustworthy place for raw incoming family information and its processing state.

### Navigation bar

Title: **Inbox**

Trailing:

- `+` / capture action
- filter/menu action when needed

### Filter model

Default filter: `Offen`

Secondary filters:

- Offen
- Verarbeitet
- Alle

Do not start with a complex multi-dimensional filter UI.

### Inbox row anatomy

Each source row contains:

- source-type thumbnail/icon
- generated or user-supplied title
- compact source metadata (`Foto · heute 19:42`, `PDF · Schule`, etc.)
- status
- proposal count if relevant

Statuses:

- `Wird hochgeladen`
- `Wird analysiert`
- `Prüfen` — strongest normal attention state
- `Teilweise übernommen`
- `Erledigt`
- `Analyse fehlgeschlagen`

Examples:

`Klassenfahrt 6b`  `PDF · heute`  `4 Vorschläge · Prüfen`
`WhatsApp Screenshot`  `Bild · gestern`  `2 Vorschläge · Prüfen`
`Zahnarzt`  `Sprache · Montag`  `Erledigt`

### Swipe/context actions

Safe actions only:

- archive
- retry failed analysis
- delete via destructive confirmation if source/provenance will be lost

No destructive swipe that silently deletes confirmed linked actions.

### Processing failure state

Show clear recovery:

> Die Datei wurde gespeichert, konnte aber nicht ausgewertet werden.

Actions:

- `Erneut versuchen`
- `Manuell erfassen`

Raw source remains available.

---

## 5. Review Import — signature screen

### Purpose

Turn uncertain machine extraction into reliable household data with minimal effort.

This screen is the product's trust boundary and must be exceptionally clear.

### Presentation

- presented as a modal/full-screen workflow on iPhone
- split source + proposals on iPad where space allows
- close/cancel never discards the raw source without confirmation

### Top bar

Leading: `Abbrechen` or close

Center/title: **Import prüfen**

Trailing: optional source menu

### A. Source preview

Compact, collapsible preview of original content.

For image/PDF:

- thumbnail/page preview
- tap -> full source viewer

For voice/text:

- transcript/original text preview

Keep source accessible throughout review; users must be able to compare extracted claims against the original.

### B. Extraction summary

Example:

> **4 Dinge erkannt**
> Bitte kurz prüfen, bevor sie in euren Familienplan übernommen werden.

No fake confidence percentage shown to normal users.

### C. Proposal cards

Each extracted proposal is independently includable and editable.

Common fields:

- include toggle/check
- type: Termin / Aufgabe / Frist / Zahlung / Vorbereitung
- title
- date
- time where relevant
- assigned person(s)
- reminder
- optional location
- optional note

Example 1:

**Termin**
`Klassenfahrt` 
`18. September · 07:30–17:00`
`Nico`

Example 2:

**Frist**
`Einverständniserklärung abgeben`
`1. September`
`Piotr + Diana`

Example 3:

**Zahlung**
`35 € Klassenfahrt bezahlen`
`bis 5. September`

Example 4:

**Vorbereitung**
`Lunchpaket vorbereiten`
`17. September · abends`

### D. Ambiguity handling

If a field is uncertain, mark the field itself rather than frightening the user with generic AI warnings.

Examples:

- `Welches Kind?` member selector highlighted
- `Uhrzeit unklar` -> editable empty time
- `5.9. oder 9.5.?` -> explicit date confirmation

The confirmation CTA is disabled only when a required unresolved field exists for an included proposal.

### E. Bottom confirmation area

Persistent safe-area action:

`4 übernehmen`

Secondary action:

`Später prüfen`

After confirmation:

- proposals become canonical household items
- source remains linked as provenance
- short success state: `4 Dinge übernommen`
- return to relevant destination, usually Inbox or Today

### Trust rules

- AI never silently creates canonical events/tasks from ambiguous source material
- user can edit every important extracted field
- original source is always reachable from a generated item
- generated items show a subtle `Aus Import` provenance detail, not an alarming permanent AI badge
- after user confirmation, items behave like normal household data

---

## 6. Plan

### Purpose

Full planning surface for calendar + tasks without overloading Today.

### Initial MVP view

Default: **Agenda**

Controls:

- date navigation
- member filter chips
- optional mode switch later: Agenda / Kalender

Agenda groups:

- Heute
- Morgen
- next relevant dates

Rows use same event/task visual language as Today.

### Calendar view

Can follow after the first vertical-slice prototype. It must not block validation of ingestion-to-action.

---

## 7. Familie

### Purpose

Household identity, membership and permissions.

### MVP

Household header:

- household name
- household avatar/monogram optional
- invite action

Member rows:

- avatar
- name
- role
- color accent
- invitation status

Roles direction:

- Owner
- Adult
- Child
- Guest/Caregiver

MVP may initially expose Owner/Adult fully and keep Child/Guest permission editing behind a coming-soon or limited implementation only if the backend model already supports them.

### Member detail

- display name
- avatar
- accent
- role
- access summary
- notification preferences later

Never expose sensitive household-wide content to a guest simply because they are a member record.

---

## 8. Source provenance flow

Confirmed event/task detail includes a secondary section:

`Quelle`

Example:

`Klassenfahrt 6b.pdf · importiert am 18.08.2026`

Tap opens the raw source viewer.

If the source is deleted later, the app must explain which linked data will lose its source evidence.

---

## 9. Loading / sync states

### Optimistic local interaction

- completing a task updates immediately
- edits appear immediately and sync in background
- capture creates local pending source immediately

### Sync indicator

Do not place permanent cloud-status chrome everywhere.

Only surface sync state when:

- offline changes are pending for material time
- upload failed
- conflict requires user attention

### Offline

Existing confirmed plan remains browsable from local cache.

Capture may queue uploads.

Clear copy:

`Wird synchronisiert, sobald du wieder online bist.`

---

## 10. Notifications

Notifications must be actionable and scarce.

Examples:

- `Nicos Einverständniserklärung ist morgen fällig.`
- `Für die Klassenfahrt morgen fehlt noch: Lunchpaket vorbereiten.`

Do not send generic engagement notifications such as `Schau mal wieder rein`.

Family member assignment and notification delivery are separate concepts; assigning an item does not automatically mean every member gets every reminder.

---

## 11. Accessibility / quality gates

Every prototype pass must validate:

- Dynamic Type through accessibility sizes
- VoiceOver labels/order
- sufficient color contrast
- no color-only person/status communication
- 44pt minimum practical touch targets
- Reduce Motion
- Reduce Transparency
- Light + Dark Mode
- German long strings
- iPhone compact width
- iPad regular width
- loading, empty, error and offline states

---

## 12. First vertical-slice prototype

The first executable product slice must demonstrate this exact scenario end to end:

1. Household exists with sample members.
2. User opens Heute.
3. User captures/imports a school letter as text or fixture.
4. Inbox item enters `Wird analysiert`.
5. Structured extraction returns 4 proposals.
6. User opens **Import prüfen**.
7. User edits one assignment/date.
8. User confirms selected proposals.
9. Event/task/deadline/preparation items appear in Plan.
10. Relevant items surface on Heute.
11. Each created item links back to its source.

If this flow is not excellent, additional modules are not allowed to mask the problem.