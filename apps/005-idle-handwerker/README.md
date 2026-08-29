# Idle Handwerker

Ein mobiles Idle-Game von Kamilunavo Games: Vom tropfenden Wasserhahn zum eigenen Handwerks-Imperium.

## Spielbarer MVP

- vier freischaltbare Auftragstypen mit Echtzeit-Fortschritt
- Betriebsstufen, XP und steigende Belohnungen
- Werkzeug-, Transporter- und Büro-Upgrades
- drei Mitarbeitertypen mit passivem Einkommen
- Offline-Einnahmen für bis zu acht Stunden
- lokaler Spielstand mit Autosave
- portraitoptimierte, responsive Godot-UI
- deutsch formatierte Preise und direktes Spiel-Feedback
- vollständig code-gezeichnete, animierte Werkstattszene
- animierter Handwerker mit jobabhängigen Arbeitseffekten
- prozedural erzeugte Soundeffekte und mobile Haptik
- Auftragsserien mit Bonusbelohnung und Bestwert

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

## Produktstrategie

Phase 1 fokussiert bewusst auf Spielgefühl, Progression, Balance und Retention. Werbung und In-App-Käufe werden erst integriert, wenn die Kernschleife Spaß macht und stabil ist.

## Technische Ausrichtung

Das Projekt nutzt Godot und GDScript ohne Expo. Für den späteren iOS-Export kann die bewährte native Bridge-Struktur aus dem separaten Projekt `onemorefloor` als Referenz dienen, ohne dessen Code oder Produktidentität zu verändern.
