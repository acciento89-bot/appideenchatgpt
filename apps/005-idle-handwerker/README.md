# Idle Handwerker

Ein mobiles Idle-Game von Kamilunavo Games: Vom tropfenden Wasserhahn zum eigenen Handwerks-Imperium.

## Spielbarer Early-Access-Build

- zehn freischaltbare Auftragstypen mit Echtzeit-Fortschritt
- vier Einsatzgebiete mit Standortboni und eigener Auftragsauswahl
- Betriebsstufen, XP und steigende Belohnungen
- Werkzeug-, Transporter- und Büro-Upgrades
- drei Mitarbeitertypen mit passivem Einkommen
- Offline-Einnahmen für bis zu acht Stunden
- gebremste Offline-Ökonomie mit 50 Prozent Effizienz und bewusstem Einsammeln
- lokaler Spielstand mit Autosave
- portraitoptimierte, responsive Godot-UI
- deutsch formatierte Preise und direktes Spiel-Feedback
- vollständig code-gezeichnete, animierte Werkstattszene
- animierter Handwerker mit jobabhängigen Arbeitseffekten
- prozedural erzeugte Soundeffekte und mobile Haptik
- Auftragsserien mit Bonusbelohnung und Bestwert
- drei rotierende Tagesziele und vier dauerhafte Karriere-Erfolge
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
