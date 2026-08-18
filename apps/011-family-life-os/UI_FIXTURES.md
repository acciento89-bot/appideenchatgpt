# Family Life OS — UI Fixtures v0.1

Status: LOCKED FOR FIRST UI PROTOTYPE
Date: 2026-08-18

Purpose: give SwiftUI implementation deterministic, realistic sample data so visual decisions are tested against real family density rather than lorem ipsum.

## 1. Demo household

Household name: `Familie Berger`

Members:

| ID | Name | Role | Accent | Notes |
|---|---|---|---|---|
| adult-1 | Mara | Owner | indigo | primary demo user |
| adult-2 | Jonas | Adult | teal | second adult |
| child-1 | Lina | Child | orange | school-age child |
| child-2 | Ben | Child | purple | younger child |

Do not use color alone; every UI sample includes initials/avatar and/or name.

## 2. Today fixture — normal busy weekday

Reference date for screenshot fixtures: Tuesday, 18 August 2026.

### Attention

1. `Einverständniserklärung morgen fällig`
   - kind: deadline
   - child: Lina
   - due: 2026-08-19 23:59
   - source: `Klassenfahrt 6b.pdf`
   - status: open

2. `12 € für Theater-AG bis Donnerstag`
   - kind: payment
   - child: Lina
   - due: 2026-08-20 12:00
   - status: open

### Family brief

German fixture:

`Ab 15:30 wird es voller: Lina hat Zahnarzt, danach muss Ben vom Training abgeholt werden. Für morgen ist noch die Einverständniserklärung offen.`

English fixture:

`The afternoon gets busier from 3:30 PM: Lina has a dentist appointment, then Ben needs picking up from practice. Tomorrow's permission slip is still open.`

### Timeline

- 07:45 — `Schule` — Lina — event — all normal
- 08:00 — `Kita` — Ben — event
- 15:30–16:15 — `Zahnarzt` — Lina — Mara assigned — location `Praxis Dr. Klein`
- 17:00–18:00 — `Fußballtraining` — Ben — event
- 18:05 — `Ben abholen` — Jonas — task
- 19:30 — `Elternabend 6b` — Mara + Jonas — event — location `Klassenraum 2.14`

### Prepare tomorrow

- `Einverständniserklärung unterschreiben` — Mara + Jonas — due tonight
- `Lunchbox für Ausflug vorbereiten` — Lina — preparation

## 3. Today fixture — calm state

No attention items.

Timeline:

- 08:00 `Kita` — Ben
- 16:30 `Lina bei Oma` — Lina

Empty-calm copy:

`Heute ist alles im grünen Bereich.`

Do not show fake insights or productivity scores.

## 4. Today fixture — conflict state

- 16:00–16:45 `Zahnarzt Lina` — Mara assigned
- 16:15–17:00 `Elterngespräch Ben` — Mara assigned

Expected UI:

- subtle conflict indicator on both rows
- one attention item: `Mara hat zwei überlappende Termine`
- tap opens both items with reassignment action

## 5. Inbox fixture set

### inbox-001 — review required

Title: `Klassenfahrt 6b`
Source type: PDF
Created: today 19:42
Status: `Prüfen`
Proposal count: 4
Thumbnail: generic first-page document fixture

### inbox-002 — processing

Title: `Screenshot Elternchat`
Source type: image
Created: today 20:03
Status: `Wird analysiert`

### inbox-003 — completed

Title: `Zahnarzt Lina`
Source type: voice
Created: yesterday 18:12
Status: `Erledigt`
Proposal count: 1 confirmed

### inbox-004 — failure

Title: `Schulfest Foto`
Source type: image
Created: Monday 17:54
Status: `Analyse fehlgeschlagen`
Error presentation: `Text konnte nicht zuverlässig erkannt werden.`
Actions: retry / manual entry

### inbox-005 — partially confirmed

Title: `Theater-AG Info`
Source type: pasted text
Created: Sunday 21:10
Status: `Teilweise übernommen`
Proposal count: 3 total / 2 confirmed / 1 deferred

## 6. Signature source fixture — school letter

### Raw source text

`Liebe Eltern der Klasse 6b,`

`am Freitag, den 18. September 2026, findet unsere Klassenfahrt ins Freilichtmuseum statt. Wir treffen uns um 07:30 Uhr vor dem Haupteingang der Schule. Die Rückkehr ist gegen 17:00 Uhr geplant.`

`Bitte geben Sie die unterschriebene Einverständniserklärung spätestens bis zum 1. September bei der Klassenleitung ab.`

`Der Kostenbeitrag von 35,00 € ist bis zum 5. September zu bezahlen.`

`Die Kinder benötigen wetterfeste Kleidung, eine Trinkflasche und ein Lunchpaket.`

`Viele Grüße`
`Frau Neumann`

### Expected extraction result

#### Proposal A

Type: `event`
Title: `Klassenfahrt Freilichtmuseum`
Date: 2026-09-18
Start: 07:30
End: 17:00
Assignee: unresolved child initially
Location: `Haupteingang der Schule` as meeting point
Required clarification: `Welches Kind nimmt teil?`

During demo review, user assigns `Lina`.

#### Proposal B

Type: `deadline/task`
Title: `Einverständniserklärung abgeben`
Due: 2026-09-01
Assignee suggestion: adult household members
Source person context: Lina after Proposal A is resolved

#### Proposal C

Type: `payment`
Title: `35 € Klassenfahrt bezahlen`
Due: 2026-09-05
Amount minor: 3500
Currency: EUR
Assignee: Mara + Jonas suggestion

#### Proposal D

Type: `preparation`
Title: `Lunchpaket und Trinkflasche vorbereiten`
Due suggestion: 2026-09-17 19:00
Assignee: Lina + one adult suggestion
Note: `Wetterfeste Kleidung`

### Review behavior

Initial CTA: disabled because Proposal A has required unresolved member assignment.

After assigning Lina:

CTA: `4 übernehmen`

User then edits Proposal D reminder from 19:00 to 18:30 to prove editability.

After confirmation:

Success: `4 Dinge übernommen`

## 7. Voice input fixture

Raw transcript:

`Trag bitte für Lina nächsten Dienstag um halb vier Zahnarzt bei Dr. Klein ein und erinner mich morgens nochmal.`

Expected proposal:

- kind: event
- title: `Zahnarzt`
- assignee: Lina
- start: relative date resolved against capture timestamp
- time: 15:30
- location: `Dr. Klein` only as plain location/provider text unless verified by user
- reminder suggestion: same day 08:00

Important: do not fabricate a street address from the doctor name.

## 8. Screenshot/chat fixture

Raw text represented in image:

`Kann jemand Ben morgen um 17:15 vom Fußball abholen? Training ist diesmal am Nebenplatz.`

Expected proposal:

- type: task
- title: `Ben vom Fußball abholen`
- due/time: tomorrow 17:15
- assignee: unresolved adult
- location: `Nebenplatz`

Required clarification: `Wer übernimmt?`

## 9. Plan fixture — agenda

### 18 Aug

- 15:30 `Zahnarzt` — Lina / Mara
- 17:00 `Fußballtraining` — Ben
- 18:05 `Ben abholen` — Jonas
- 19:30 `Elternabend 6b` — Mara + Jonas

### 19 Aug

- all-day/deadline `Einverständniserklärung abgeben` — Lina context
- 18:30 `Lunchbox vorbereiten` — Lina + Mara

### 20 Aug

- 12:00 `12 € Theater-AG bezahlen` — Mara + Jonas

### 18 Sep

- 07:30–17:00 `Klassenfahrt Freilichtmuseum` — Lina

## 10. Family fixture

### Mara

Role: Owner
Initials: MB
Access summary: `Voller Zugriff`

### Jonas

Role: Adult
Initials: JB
Access summary: `Voller Zugriff`

### Lina

Role: Child
Initials: LB
Access summary in MVP: `Profil ohne eigenen Login`

### Ben

Role: Child
Initials: BB
Access summary in MVP: `Profil ohne eigenen Login`

## 11. Error and edge fixtures

### No actions found

Source: image of school artwork without date/action content.

Result:

`Keine Termine oder Aufgaben erkannt.`

Actions:

- `Manuell hinzufügen`
- `Als erledigt markieren`

### Ambiguous date

Raw text:

`Elternabend am 05/09 um 18 Uhr.`

If locale/source does not make interpretation safe, Review screen must ask the user to choose the date rather than assume.

### Duplicate import

Same PDF imported twice.

System may warn:

`Dieses Dokument sieht einem bereits importierten Dokument sehr ähnlich.`

Actions:

- existing item öffnen
- trotzdem importieren

Do not silently discard.

### Offline capture

Source creates local pending item:

`Wartet auf Upload`

Copy:

`Wird synchronisiert, sobald du wieder online bist.`

## 12. Screenshot validation set

The first visual QA pass should capture at least these states:

1. Heute — normal busy day
2. Heute — calm/empty
3. Heute — schedule conflict
4. Inbox — mixed statuses
5. Inbox — processing only
6. Import prüfen — unresolved child assignment
7. Import prüfen — ready to confirm 4 proposals
8. Import prüfen — source expanded
9. Plan — agenda
10. Familie — four members
11. Dark Mode — Heute
12. Dark Mode — Import prüfen
13. iPad — Inbox split view
14. Dynamic Type accessibility size — Today timeline
15. Offline pending source

If the UI only looks good in fixture #1, the design pass is not complete.