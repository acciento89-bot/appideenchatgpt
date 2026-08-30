# Idle Handwerker

Ein mobiles Idle-Game von Kamilunavo Games: Vom tropfenden Wasserhahn zum eigenen Handwerks-Imperium.

## Spielbarer Early-Access-Build

- zehn freischaltbare Auftragstypen mit Echtzeit-Fortschritt
- vier Einsatzgebiete mit Standortboni und eigener Auftragsauswahl
- Betriebsstufen, XP und steigende Belohnungen
- sichtbare Wiederholsperren pro Auftrag gegen das Spammen besonders lukrativer Arbeiten
- Werkzeug-, Transporter- und Büro-Upgrades
- drei Mitarbeitertypen mit passivem Einkommen
- fünf Teamränge mit Personal-Meilensteinen und moderatem Qualitätsbonus
- Offline-Einnahmen für bis zu acht Stunden
- gebremste Offline-Ökonomie mit 50 Prozent Effizienz und bewusstem Einsammeln
- lokaler Spielstand mit Autosave
- portraitoptimierte, responsive Godot-UI
- deutsch formatierte Preise und direktes Spiel-Feedback
- vollständig code-gezeichnete, animierte Werkstattszene
- animierter Handwerker mit jobabhängigen Arbeitseffekten
- prozedural erzeugte Soundeffekte und mobile Haptik
- Auftragsserien mit Bonusbelohnung und Bestwert
- fünf Tagesziele und achtzehn gestaffelte Karriere-Erfolge für längere Motivation
- neue Einsatzgebiete als bestätigte Betriebsneustarts mit zurückgesetzter operativer Wirtschaft
- vierstufiges Ingame-Tutorial für den ersten Start
- vollständig eigenes Premium-Menüsystem aus Godot-kompatiblen SVG-Skins
- Metallrahmen, Einlagen, Nieten, Glanzkanten und Medaillons ohne generierte Bilder
- zufällige Bonusereignisse: Express-Auftrag, Premium-Material und Kundenempfehlung
- sichtbarer Werkstattfortschritt durch Werkzeugwand, Digitalbüro, Fuhrpark und Teamhelme
- dynamische Auftragsboni für Lohn, Dauer und XP
- Firmenwert als zusätzlicher langfristiger Fortschrittsindikator
- intensivierte Serienfeiern mit wachsendem Partikeleffekt
- vier freischaltbare Stammkunden- und Wartungsverträge
- Reputation mit fünf Karriere-Rängen vom neuen Betrieb bis zum Industrie-Partner
- dauerhafte Vertragseinnahmen inklusive Offline-Fortschritt
- Empfehlungsevents bringen doppelte Reputation
- aktive Verträge werden auf der Werkstatt-Auftragstafel sichtbar
- dynamische Arbeitsqualität von 50 bis 100 Prozent
- Kundenbewertungen mit Sternen, Kommentaren und gespeichertem Verlauf
- Qualitätsbonus auf Lohn und Reputation
- vier mehrstufig gesperrte Großprojekte bis zur Klinik-Energiezentrale
- eigene Großprojekt-Darstellung in Auftragsbörse und Werkstattszene
- responsive Layoutanpassung für kleine und große iPhone-Portraitformate
- automatische Safe-Area-Abstände für Dynamic Island und Home Indicator
- gespeicherte Optionen für Sound, Haptik und reduzierte Bewegung
- Speichern beim App-Wechsel und beim Schließen
- scrollbare Release-Einstellungen mit Tutorial-Wiederholung, lokaler Datenschutzinfo und bestätigtem Spielstand-Reset
- eigener Rückkehrbildschirm im Werkstattdesign statt nativer Systemdialoge
- flüssige, optional deaktivierbare Menüübergänge
- automatischer UI-Smoke-Test über vier relevante Displaygrößen und alle Hauptbereiche
- natives iOS-Export-Preset mit eigenem App-Icon, Launch-Badge und Privacy-Manifest-Angaben
- manueller TestFlight-Workflow für Xcode 26 und App-Store-Connect-Cloud-Signierung

## Start

Benötigt wird Godot 4.3 oder neuer.

```bash
godot --editor project.godot
```

Oder direkt starten:

```bash
godot --path .
```

## Tests

```bash
godot --headless --path . --script tests/test_economy.gd
```

## iOS und TestFlight

Das Projekt ist für den nativen Godot-iOS-Export vorbereitet. Bundle-ID, Version, Datenschutzangaben und der manuell auslösbare Release-Ablauf sind in [IOS_RELEASE.md](IOS_RELEASE.md) dokumentiert.

## Produktstrategie

Die aktuelle Phase fokussiert bewusst auf Spielgefühl, Progression, Onboarding und Retention. Werbung und In-App-Käufe werden erst integriert, wenn die Kernschleife Spaß macht und stabil ist.

## Technische Ausrichtung

Das Projekt nutzt Godot und GDScript ohne Expo. Für den späteren iOS-Export kann die bewährte native Bridge-Struktur aus dem separaten Projekt `onemorefloor` als Referenz dienen, ohne dessen Code oder Produktidentität zu verändern.
# Build 8 – Langzeitspiel und Monetarisierung

- 8 Einsatzgebiete und 23 Aufträge bis zur Metropole
- 33 Karriere-Erfolge, 7 Tagesziele und deutlich langsamere Wirtschaft
- Meisterbrief/Prestige mit permanenten Meisterpunkten
- optionale Belohnungswerbung für 2× Ertrag, keine erzwungenen Unterbrecheranzeigen
- StoreKit-Produkte für Werbefrei, Starterpaket und Bonusmarken inklusive Transaktionsschutz

## Build 9 – SHK-Finaldesign

- vollständiges SHK-Farbsystem aus Technikblau, Wasser-Cyan und Heizungsorange
- eigene lesbare In-App-Dialoge für Standortwechsel und Spielstand-Reset
- überarbeitete Panels, Navigation, Buttons, Werkstattgrafik, App-Icon und Startgrafik
- native graue Systemdialoge entfernt; Kontrast und mobile Lesbarkeit verbessert

## Build 10 – Shop und Optionen getrennt

- Zahnrad statt `OPT`, eigener `SHOP`-Button im Header
- Shop vollständig aus den Spieleinstellungen entfernt und als eigenes SHK-Fenster umgesetzt
- Optionen und Shop besitzen jeweils dauerhaft sichtbare obere und untere Schließen-Aktionen

## Build 11 – Scroll-Interaktion

- Einträge in Optionen und Shop zeigen beim vertikalen Scrollen keinen falschen gedrückten Zustand mehr
- Touch-Fokus bleibt nicht mehr als scheinbare Auswahl auf einem Shop- oder Optionspunkt stehen

## Build 12 – echtes Touch-Scrolling

- Ziehen funktioniert nun über die gesamte Fläche der Karten in Optionen, Shop und Hauptansichten
- Buttons reichen Touch-Gesten an den umgebenden Scrollbereich weiter, bleiben aber normal antippbar
- Niedrigere Drag-Schwelle und neutrale Hover-/Pressed-Darstellung verhindern blockiertes Scrollen und kurzes Aufblitzen
