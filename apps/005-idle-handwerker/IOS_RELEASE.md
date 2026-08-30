# iOS- und TestFlight-Release

## Produktdaten

| Feld | Wert |
|---|---|
| App-Name | Idle Handwerker |
| Bundle-ID | `de.kamilunavo.idlehandwerker` |
| Apple Team | `TKG684N5GL` |
| Marketing-Version | `1.3.0` |
| Mindestversion | iOS 16.0 |
| Gerätefamilie | iPhone |
| Ausrichtung | Portrait |
| Verschlüsselung | nur Apple-/Systemverschlüsselung, keine nicht-ausgenommene Verschlüsselung |

## Datenschutz und Monetarisierung ab Version 1.3

Spielstand und Einstellungen bleiben lokal; es gibt keine Anmeldung, Cloud-Synchronisation oder eigene Analytics. Die App integriert Google Mobile Ads ausschließlich für freiwillig ausgelöste Rewarded Ads (Einnahmenbonus und Verdopplung von Offline-Einnahmen). Banner und automatische Interstitials werden nicht verwendet. Anzeigenanfragen werden mit `npa=1` als nicht personalisiert angefordert. App Tracking Transparency und präzises Standorttracking werden nicht verwendet.

Google UMP aktualisiert beim Start den Einwilligungsstatus und zeigt erforderliche EU-Formulare vor Anzeigenanfragen. Die veröffentlichte AdMob-Mitteilung unterstützt Deutsch und Englisch sowie eine direkte Option „Nicht einwilligen“. Datenschutzentscheidungen können in den App-Einstellungen erneut geöffnet werden, wenn UMP dies regional verlangt.

StoreKit stellt vier Produkte bereit: Werbefrei, Starterpaket, 250 Bonusmarken und 1.200 Bonusmarken. Apple verarbeitet Zahlung und Transaktion; die App speichert nur die lokal benötigten Freischaltungen und Verbrauchsgüter. Wiederherstellbare Käufe können im Shop wiederhergestellt werden.

Datenschutz-URL: `https://kamilunavo.com/idle-handwerker/privacy`

## Einmalige GitHub-Secrets

Der Workflow verwendet dieselben Repository-Secrets wie die anderen Kamilunavo-iOS-Builds:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`
- `ADMOB_IOS_APP_ID`
- `ADMOB_REWARDED_BOOST_ID`
- `ADMOB_REWARDED_OFFLINE_ID`

Die private `.p8`-Datei wird nur temporär auf dem macOS-Runner erzeugt und am Ende wieder gelöscht. Sie gehört niemals ins Repository.

## TestFlight starten

1. In GitHub **Actions → Idle Handwerker TestFlight → Run workflow** öffnen.
2. Eine bisher unbenutzte positive Buildnummer eintragen.
3. Beim ersten Lauf `App-Datensatz bei Bedarf anlegen` aktiviert lassen.
4. Der Workflow validiert Godot, erzeugt das native Xcode-Projekt, baut einen unsignierten nativen iPhone-Release-Gate, archiviert ohne lokale Zertifikate, signiert über App Store Connect und lädt die IPA hoch.
5. Ein interner Testbuild verwendet Google-Testanzeigen. Für den Produktionskandidaten `production_ads` aktivieren und eine neue Buildnummer verwenden.
6. Nach der Verarbeitung in App Store Connect Export-Compliance, Altersfreigabe, Datenschutzangaben, StoreKit-Sandboxkäufe, Wiederherstellung und interne Tester prüfen.

Jeder erneute Upload derselben Version braucht eine höhere Buildnummer.

## Lokaler Xcode-Export

Auf einem Mac mit Godot 4.7.1, installierten Export Templates und Xcode 26:

```bash
godot --headless --path . --export-release "iOS TestFlight" builds/ios/IdleHandwerker.zip
unzip builds/ios/IdleHandwerker.zip -d builds/ios/xcode
open builds/ios/xcode/*.xcodeproj
```

Signierungsdaten werden absichtlich nicht in `export_presets.cfg` gespeichert. Godots lokale Export-Credentials liegen unter `.godot/export_credentials.cfg` und sind ignoriert.
