# Phase 7 Geräte-QA

## Automatisch geprüft

- 320 × 568 – kompaktes iPhone-Layout
- 390 × 844 – aktuelles Standardformat
- 430 × 932 – großes iPhone-Layout
- 440 × 956 – maximales Portraitformat
- Aufbau aller fünf Hauptbereiche
- horizontale Inhaltsbreite
- korrekte Prüfung gegen Godots logische Viewportbreite bei `canvas_items`-Skalierung
- Sound-, Haptik- und Bewegungsoptionen im Savegame

## TestFlight-Checkliste

- Safe Area an Dynamic Island und Home Indicator
- Scrollverhalten in Firma, Aufträgen und Ziele
- Lesbarkeit langer deutscher Texte
- Haptik auf echtem Gerät
- Audio mit Stummmodus und Bluetooth
- App-Wechsel während eines laufenden Auftrags
- Offline-Ertrag nach 10 Minuten und nach 8 Stunden
- alter Spielstand nach Update auf Savegame-Version 5
- vollständiger Durchlauf von Tutorial bis erstem Vertrag
- Tutorial aus den Einstellungen erneut starten
- Spielstand-Reset abbrechen und anschließend bewusst bestätigen
- Spielstand bleibt nach App-Wechsel und erzwungenem Beenden erhalten
- EU-Einwilligungsformular erscheint vor der ersten möglichen Anzeigenanfrage
- „Nicht einwilligen“ verhindert keine Nutzung des Spiels
- Datenschutzoptionen lassen sich aus den Einstellungen erneut öffnen, wenn UMP sie verlangt
- Rewarded Ad für Einnahmenbonus vergibt die Belohnung genau einmal
- Rewarded Ad für Offline-Einnahmen verdoppelt nur den angezeigten Offline-Betrag
- Abbruch oder Ladefehler einer Anzeige vergibt keine Belohnung
- StoreKit-Sandboxkäufe für alle vier Produkt-IDs
- Werbefrei und Starterpaket können nicht mehrfach gekauft werden
- Bonusmarken werden nach bestätigtem Verbrauchskauf genau einmal gutgeschrieben
- „Käufe wiederherstellen“ stellt dauerhafte Käufe wieder her, aber keine verbrauchten Bonusmarken
