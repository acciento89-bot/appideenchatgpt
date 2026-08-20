# Kamilunavo Trace — App Store Metadata

Prepared: 2026-08-20
Bundle ID: `de.kamilunavo.trace`
Primary category: Productivity
Platform: iPhone
Minimum iOS: 17.0

## URLs

- Marketing URL: `https://kamilunavo.com/trace`
- Support URL: `https://kamilunavo.com/support`
- Privacy Policy URL: `https://kamilunavo.com/trace/privacy`
- Standard Apple EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

The Kamilunavo website repository contains dedicated `/trace` and `/trace/privacy` routes plus Trace in the general support page. The Trace website release-check PR passed TypeScript + production Next.js build and was merged on 2026-08-20. Confirm production deployment before final App Store submission.

## German (Germany)

### Name
`Kamilunavo Trace`

### Subtitle
`Beweise prüfbar sichern`

### Promotional text
`Originale lokal bewahren, SHA-256-Integrität prüfen, Snapshots versiegeln und nachvollziehbare PDF- oder .evpack-Beweispakete exportieren.`

### Keywords
`beweise,dokumentation,schaden,miete,übergabe,versicherung,fotos,pdf,sha256,timeline`

### Description
Kamilunavo Trace hilft dir, reale Situationen strukturiert zu dokumentieren, solange die Details noch frisch sind. Erstelle für einen Schaden, eine Wohnungsübergabe, eine Lieferung, ein Fahrzeug, einen Handwerkerfall, eine Versicherung oder einen anderen Vorgang eine klare Beweis-Zeitleiste.

Fotos, PDFs, Dateien und Notizen bleiben als lokale Originale auf deinem iPhone erreichbar. Für gespeicherte Originaldaten berechnet Trace SHA-256-Integritätswerte. Beweisdatensätze erhalten zusätzlich eigene Hashwerte und du kannst den aktuellen Stand eines Falls als Snapshot versiegeln.

Funktionen:
• Beweisfälle mit strukturierter Timeline anlegen
• Fotos direkt mit der Kamera aufnehmen
• Bilder, Dateien und PDFs importieren
• Originaldateien lokal auf dem Gerät bewahren
• SHA-256 für Originale und Beweisdatensätze anzeigen
• wiederholbare Snapshot-Siegel für den aktuellen Stand erstellen
• Text aus Bildern und PDFs lokal mit Apple Vision erkennen
• App optional mit Face ID, Touch ID oder Gerätecode schützen
• empfangene .evpack-Dateien offline auf interne Konsistenz prüfen
• mit Trace Pro PDF-Beweispakete und .evpack-Dateien exportieren

Trace ist local-first. Version 1 benötigt kein Benutzerkonto und lädt deine Beweisfälle nicht in eine Kamilunavo-Cloud. OCR wird lokal auf dem Gerät erzeugt und bleibt als abgeleitete Information getrennt von den Originaldaten.

Hashes und Snapshot-Siegel helfen dabei, spätere Änderungen zu erkennen. Kamilunavo Trace ist kein Notar, keine Rechtsberatung und garantiert weder eine unabhängige Realwelt-Zeitbestätigung noch die Anerkennung als Beweismittel durch Gericht, Versicherung, Arbeitgeber oder Behörde.

Trace Pro ist als einmaliger In-App-Kauf erhältlich. Die kostenlose Version bleibt für Erfassung, lokale Integritätsfunktionen und die Prüfung empfangener .evpack-Dateien nutzbar.

### Review notes
Kamilunavo Trace is a local-first evidence documentation app. No account is required.

Core review path:
1. Create a case.
2. Add a note/photo/file.
3. Inspect original/evidence SHA-256 values.
4. Seal the current snapshot.
5. Use the top-left shield action on Home to verify a received `.evpack` file without purchasing Pro.
6. Open Settings -> Trace Pro to access purchase/restore.

Lifetime Pro product ID: `de.kamilunavo.trace.pro.lifetime`.

The app does not claim notarization or legal admissibility. OCR is derived locally and is explicitly excluded from original/evidence/seal identity.

## English (U.S.)

### Name
`Kamilunavo Trace`

### Subtitle
`Capture. Seal. Verify.`

### Promotional text
`Preserve originals locally, verify SHA-256 integrity, seal snapshots, and export clear PDF or offline-verifiable .evpack evidence packages.`

### Keywords
`evidence,documentation,damage,rental,handover,insurance,photos,pdf,sha256,timeline`

### Description
Kamilunavo Trace helps you document real-world situations while the details are still fresh. Create a clear evidence timeline for property handovers, damage, deliveries, vehicles, contractor work, insurance incidents, or other factual records.

Photos, PDFs, files, and notes remain reachable as local originals on your iPhone. Trace calculates SHA-256 integrity values for stored original data. Evidence records receive their own hashes, and you can seal the current state of a case as a repeatable snapshot.

Features:
• create structured evidence cases and timelines
• capture photos directly with the camera
• import images, files, and PDFs
• preserve original files locally on the device
• inspect SHA-256 values for originals and evidence records
• create repeatable snapshot seals for the current case state
• recognize text from images and PDFs locally with Apple Vision
• optionally protect app access with Face ID, Touch ID, or device passcode
• verify received .evpack files offline for internal consistency
• export PDF evidence packs and .evpack files with Trace Pro

Trace is local-first. Version 1 requires no user account and does not upload your evidence cases to a Kamilunavo cloud. OCR is derived on the device and remains clearly separated from original data.

Hashes and snapshot seals can help detect later changes. Kamilunavo Trace is not a notary or legal-advice service and does not guarantee an independent real-world timestamp or acceptance by a court, insurer, employer, or authority.

Trace Pro is available as a one-time In-App Purchase. The free version remains useful for capture, local integrity features, and verification of received .evpack files.

## App Privacy direction

Based on the current v1 source boundary:
- no user account
- no advertising SDK
- no third-party analytics SDK
- no cross-app tracking
- evidence/case/photo/file/OCR data remain local unless the user explicitly shares an export through iOS
- StoreKit purchases are handled by Apple; the app reads verified transaction/entitlement state

Provisional App Store privacy answer: **Data Not Collected** by the developer from the app, subject to final App Store Connect review against Apple's current definitions. User evidence/photos stored only on the user's device are not transmitted to Kamilunavo and therefore are not developer-collected data merely because the app stores them locally.

Tracking: **No**.

## 2026 age-rating questionnaire direction

Answer from the actual v1 feature set, not from hypothetical future features:

- Unrestricted Web Access: **No**
- User-Generated Content / broad in-app distribution: **No** — users create/import local evidence, but Trace has no in-app feed, public distribution network or content discovery system
- Messaging and Chat: **No**
- Social Media capability: **No**
- Advertising: **No**
- Parental Controls: **No**
- Age Assurance: **No**
- Gambling / simulated gambling: **None**
- Contests: **None**
- Violence: **None**
- Profanity / crude humor: **None**
- Mature / suggestive themes: **None**
- Horror / fear themes: **None**
- Medical / treatment information: **None**
- Alcohol / tobacco / drugs: **None**
- Sexual content / nudity: **None**

Expected direction: Apple's lowest applicable global rating (normally **4+** for this feature/content profile). The rating calculated by the current App Store Connect questionnaire is authoritative; do not override it merely to match this document.

## Content Rights direction

Trace does not ship or stream a developer-curated third-party media/content catalog. Users may deliberately select their own local photos, PDFs and files for a private evidence case and may explicitly share exports through iOS.

App Store Connect direction:
- developer-supplied third-party content catalog: **No**
- user-selected local content access/import: **Yes**
- in-app public redistribution/feed: **No**
- developer claim: Kamilunavo owns or controls the app, app artwork, metadata and developer-supplied release assets; users remain responsible for having the right or permission to capture/import/share the materials they choose

If App Store Connect presents a broad content-rights confirmation because the app can access user-selected third-party materials, confirm only the rights/permissions that are actually true; do not claim Kamilunavo owns users' imported documents or photos.

## Export compliance

Release build setting: `ITSAppUsesNonExemptEncryption = NO`.

Trace uses SHA-256 hashing for integrity and system-provided Apple security/payment/authentication frameworks; it does not implement proprietary or non-standard encryption. Reconfirm the export-compliance answers against the actual submitted binary in App Store Connect.

## In-App Purchase

Reference name: `Kamilunavo Trace Lifetime Pro`
Product ID: `de.kamilunavo.trace.pro.lifetime`
Type: Non-Consumable
Launch price direction: `€14.99` in Germany, with Apple's equivalent tier pricing elsewhere.

German display name: `Kamilunavo Trace Pro – Lifetime`
German description: `Unbegrenzte Fälle sowie PDF- und .evpack-Exporte. Einmal zahlen.`

English display name: `Kamilunavo Trace Pro Lifetime`
English description: `Unlimited cases plus PDF and .evpack exports. Pay once.`

## Screenshot set to capture after TestFlight

Recommended 6.7-inch iPhone sequence:
1. Home with case list + Trace identity
2. Case timeline with original SHA-256
3. Snapshot seals / integrity model
4. Local OCR clearly labeled as derived
5. Offline `.evpack` verification result
6. Trace Pro Lifetime purchase screen

German and English screenshot sets should use the same feature order.
