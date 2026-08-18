# Family Life OS — UI Fixtures v0.1

Status: LOCKED FOR FIRST UI PROTOTYPE
Date: 2026-08-18

Purpose: deterministic realistic sample data so SwiftUI visual decisions are tested against real family density rather than lorem ipsum.

## Demo household

Household: `Familie Berger`

| ID | Name | Role | Accent |
|---|---|---|---|
| adult-1 | Mara | Owner | indigo |
| adult-2 | Jonas | Adult | teal |
| child-1 | Lina | Child | orange |
| child-2 | Ben | Child | purple |

Color is never the sole person identifier.

## Today — normal busy weekday

Reference date: Tuesday, 18 August 2026.

Attention:

1. `Einverständniserklärung morgen fällig` — Lina — due 2026-08-19 — source `Klassenfahrt 6b.pdf`
2. `12 € für Theater-AG bis Donnerstag` — Lina — due 2026-08-20

Family brief DE:

`Ab 15:30 wird es voller: Lina hat Zahnarzt, danach muss Ben vom Training abgeholt werden. Für morgen ist noch die Einverständniserklärung offen.`

Family brief EN:

`The afternoon gets busier from 3:30 PM: Lina has a dentist appointment, then Ben needs picking up from practice. Tomorrow's permission slip is still open.`

Timeline:

- 07:45 `Schule` — Lina
- 08:00 `Kita` — Ben
- 15:30–16:15 `Zahnarzt` — Lina — Mara — `Praxis Dr. Klein`
- 17:00–18:00 `Fußballtraining` — Ben
- 18:05 `Ben abholen` — Jonas
- 19:30 `Elternabend 6b` — Mara + Jonas — `Klassenraum 2.14`

Prepare tomorrow:

- `Einverständniserklärung unterschreiben` — Mara + Jonas
- `Lunchbox für Ausflug vorbereiten` — Lina

## Today — calm state

No attention items.

- 08:00 `Kita` — Ben
- 16:30 `Lina bei Oma` — Lina

Copy: `Heute ist alles im grünen Bereich.`

Do not show fake productivity statistics.

## Today — conflict state

- 16:00–16:45 `Zahnarzt Lina` — Mara
- 16:15–17:00 `Elterngespräch Ben` — Mara

Expected:

- subtle conflict indicator
- attention item `Mara hat zwei überlappende Termine`
- tap opens both items with reassignment path

## Inbox fixtures

### inbox-001

`Klassenfahrt 6b` — PDF — today 19:42 — status `Prüfen` — 4 proposals.

### inbox-002

`Screenshot Elternchat` — image — today 20:03 — status `Wird analysiert`.

### inbox-003

`Zahnarzt Lina` — voice — yesterday 18:12 — status `Erledigt` — 1 confirmed proposal.

### inbox-004

`Schulfest Foto` — image — Monday 17:54 — status `Analyse fehlgeschlagen`.

Error: `Text konnte nicht zuverlässig erkannt werden.`
Actions: retry / manual entry.

### inbox-005

`Theater-AG Info` — pasted text — Sunday 21:10 — `Teilweise übernommen` — 3 total / 2 confirmed / 1 deferred.

## Signature source fixture — school letter

Raw source:

`Liebe Eltern der Klasse 6b,`

`am Freitag, den 18. September 2026, findet unsere Klassenfahrt ins Freilichtmuseum statt. Wir treffen uns um 07:30 Uhr vor dem Haupteingang der Schule. Die Rückkehr ist gegen 17:00 Uhr geplant.`

`Bitte geben Sie die unterschriebene Einverständniserklärung spätestens bis zum 1. September bei der Klassenleitung ab.`

`Der Kostenbeitrag von 35,00 € ist bis zum 5. September zu bezahlen.`

`Die Kinder benötigen wetterfeste Kleidung, eine Trinkflasche und ein Lunchpaket.`

`Viele Grüße`
`Frau Neumann`

### Expected proposal A — event

- title `Klassenfahrt Freilichtmuseum`
- date 2026-09-18
- 07:30–17:00
- child initially unresolved
- meeting point `Haupteingang der Schule`
- required clarification `Welches Kind nimmt teil?`

Demo user assigns `Lina`.

### Proposal B — deadline/task

- `Einverständniserklärung abgeben`
- due 2026-09-01
- adult assignee suggestion
- Lina context after proposal A resolution

### Proposal C — payment

- `35 € Klassenfahrt bezahlen`
- due 2026-09-05
- 3500 minor units / EUR
- Mara + Jonas suggestion

### Proposal D — preparation

- `Lunchpaket und Trinkflasche vorbereiten`
- suggested 2026-09-17 19:00
- Lina + one adult suggestion
- note `Wetterfeste Kleidung`

### Review behavior

Initial confirmation CTA is disabled because proposal A has an unresolved required child assignment.

After assigning Lina: CTA `4 übernehmen`.

User edits proposal D reminder from 19:00 to 18:30 to prove editability.

Success: `4 Dinge übernommen`.

## Voice fixture

Raw:

`Trag bitte für Lina nächsten Dienstag um halb vier Zahnarzt bei Dr. Klein ein und erinner mich morgens nochmal.`

Expected:

- event `Zahnarzt`
- Lina
- relative date resolved from capture timestamp
- 15:30
- `Dr. Klein` remains plain provider/location text unless user verifies an address
- same-day 08:00 reminder suggestion

Never fabricate a street address.

## Screenshot/chat fixture

Raw:

`Kann jemand Ben morgen um 17:15 vom Fußball abholen? Training ist diesmal am Nebenplatz.`

Expected:

- task `Ben vom Fußball abholen`
- tomorrow 17:15
- unresolved adult assignee
- location `Nebenplatz`
- clarification `Wer übernimmt?`

## Plan agenda fixture

### 18 Aug

- 15:30 `Zahnarzt` — Lina / Mara
- 17:00 `Fußballtraining` — Ben
- 18:05 `Ben abholen` — Jonas
- 19:30 `Elternabend 6b` — Mara + Jonas

### 19 Aug

- deadline `Einverständniserklärung abgeben`
- 18:30 `Lunchbox vorbereiten` — Lina + Mara

### 20 Aug

- 12:00 `12 € Theater-AG bezahlen` — Mara + Jonas

### 18 Sep

- 07:30–17:00 `Klassenfahrt Freilichtmuseum` — Lina

## Family fixture

- Mara — Owner — MB — `Voller Zugriff`
- Jonas — Adult — JB — `Voller Zugriff`
- Lina — Child — LB — `Profil ohne eigenen Login`
- Ben — Child — BB — `Profil ohne eigenen Login`

## Error / edge fixtures

### No actions found

`Keine Termine oder Aufgaben erkannt.`

Actions: `Manuell hinzufügen`, `Als erledigt markieren`.

### Ambiguous date

`Elternabend am 05/09 um 18 Uhr.`

If locale/source does not make interpretation safe, user must choose rather than the model assuming.

### Duplicate import

Warn: `Dieses Dokument sieht einem bereits importierten Dokument sehr ähnlich.`

Actions: open existing / import anyway. Never silently discard.

### Offline capture

Status `Wartet auf Upload`.

Copy: `Wird synchronisiert, sobald du wieder online bist.`

## Screenshot validation set

1. Heute — normal busy
2. Heute — calm
3. Heute — conflict
4. Inbox — mixed statuses
5. Inbox — processing only
6. Import prüfen — unresolved child
7. Import prüfen — ready for 4 confirmations
8. Import prüfen — source expanded
9. Plan — agenda
10. Familie — four members
11. Dark Mode — Heute
12. Dark Mode — Import prüfen
13. iPad — Inbox split view
14. Dynamic Type accessibility size — Today
15. Offline pending source

If the UI only looks good in fixture #1, the design pass is not complete.