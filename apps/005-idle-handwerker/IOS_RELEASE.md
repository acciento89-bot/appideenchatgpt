# iOS- und TestFlight-Release

## Produktdaten

| Feld | Wert |
|---|---|
| App-Name | Idle Handwerker |
| Bundle-ID | `de.kamilunavo.idlehandwerker` |
| Apple Team | `TKG684N5GL` |
| Marketing-Version | `1.0.0` |
| Mindestversion | iOS 16.0 |
| Gerätefamilie | iPhone |
| Ausrichtung | Portrait |
| Verschlüsselung | nur Apple-/Systemverschlüsselung, keine nicht-ausgenommene Verschlüsselung |

## Datenschutz für Build 1

Der aktuelle Build arbeitet vollständig lokal. Er enthält keine Werbung, Analyse-SDKs, Anmeldung, Cloud-Synchronisation oder In-App-Käufe und übermittelt keine Nutzerdaten. Das Godot-Export-Preset erklärt deshalb kein Tracking und keine erhobenen Datentypen. Die von Godot benötigten Required-Reason-API-Angaben für Dateizeitstempel, Systemstartzeit und freien Speicher werden beim Export in das Privacy Manifest geschrieben.

Diese Einordnung muss erneut geprüft werden, sobald Analytics, Crash-Reporting, Werbung, Käufe oder Cloud-Funktionen hinzukommen.

## Einmalige GitHub-Secrets

Der Workflow verwendet dieselben Repository-Secrets wie die anderen Kamilunavo-iOS-Builds:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

Die private `.p8`-Datei wird nur temporär auf dem macOS-Runner erzeugt und am Ende wieder gelöscht. Sie gehört niemals ins Repository.

## TestFlight starten

1. In GitHub **Actions → Idle Handwerker TestFlight → Run workflow** öffnen.
2. Eine bisher unbenutzte positive Buildnummer eintragen.
3. Beim ersten Lauf `App-Datensatz bei Bedarf anlegen` aktiviert lassen.
4. Der Workflow validiert Godot, erzeugt das native Xcode-Projekt, baut den Simulator-Gate, archiviert ohne lokale Zertifikate, signiert über App Store Connect und lädt die IPA hoch.
5. Nach der Verarbeitung in App Store Connect Export-Compliance, Altersfreigabe, Datenschutzangaben und interne Tester prüfen.

Jeder erneute Upload derselben Version braucht eine höhere Buildnummer.

## Lokaler Xcode-Export

Auf einem Mac mit Godot 4.7.1, installierten Export Templates und Xcode 26:

```bash
godot --headless --path . --export-release "iOS TestFlight" builds/ios/IdleHandwerker.zip
unzip builds/ios/IdleHandwerker.zip -d builds/ios/xcode
open builds/ios/xcode/*.xcodeproj
```

Signierungsdaten werden absichtlich nicht in `export_presets.cfg` gespeichert. Godots lokale Export-Credentials liegen unter `.godot/export_credentials.cfg` und sind ignoriert.
