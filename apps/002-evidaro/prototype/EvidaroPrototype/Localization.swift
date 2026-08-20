import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        let localized = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        if localized != key {
            return localized
        }
        return bundleFallback[key] ?? key
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static var isGerman: Bool {
        let localization = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "en"
        return localization.lowercased().hasPrefix("de")
    }

    private static var bundleFallback: [String: String] {
        isGerman ? bundleGerman : bundleEnglish
    }

    private static let bundleEnglish: [String: String] = [
        "bundle.building": "Building verification bundle…",
        "bundle.build_share": "Build & share verification bundle",
        "bundle.export_failed": "Verification bundle export failed",
        "bundle.verify_import": "Verify evidence bundle",
        "bundle.verify_failed": "Evidence bundle could not be verified",
        "bundle.verify_title": "Verify Bundle",
        "bundle.result_valid": "Integrity checks passed",
        "bundle.result_invalid": "Integrity checks failed",
        "bundle.result_details": "Verification details",
        "bundle.result_case_id": "Case ID",
        "bundle.result_items": "Evidence items",
        "bundle.result_seals": "Verified seals",
        "bundle.result_manifest": "Current manifest SHA-256",
        "bundle.result_bundle_hash": "Bundle SHA-256",
        "bundle.result_issues": "Integrity issues",
        "bundle.result_boundary": "What this proves",
        "bundle.result_boundary_text": "This verifies the internal consistency of the exported original bytes, record hashes and recorded snapshot seals. It does not independently prove when a real-world event occurred or guarantee legal acceptance.",
        "bundle.error_missing_case": "The evidence case is no longer available.",
        "bundle.error_empty_case": "Add at least one evidence item before creating a verification bundle.",
        "bundle.error_missing_original": "The stored original for %@ is missing. The verification bundle was not created.",
        "bundle.error_original_integrity": "The stored original for %@ no longer matches its SHA-256 hash. The verification bundle was not created.",
        "bundle.error_record_integrity": "Evidence record integrity check failed for %@. The verification bundle was not created.",
        "bundle.error_generated_invalid": "The generated verification bundle did not pass its own integrity check.",
        "bundle.error_format": "This file is not a supported evidence verification bundle.",
        "bundle.error_version": "Verification bundle version %ld is not supported.",
        "bundle.error_unreadable": "The evidence verification bundle could not be read.",
        "bundle.issue_case_id": "The case ID is invalid.",
        "bundle.issue_case_type": "The case type is unknown.",
        "bundle.issue_order": "Evidence items are not in their canonical chronological order.",
        "bundle.issue_item_id": "Evidence item %@ has an invalid ID.",
        "bundle.issue_item_type": "Evidence item %@ has an unknown type.",
        "bundle.issue_record_hash": "Evidence record hash mismatch for %@.",
        "bundle.issue_media_missing": "Original bytes are missing for %@.",
        "bundle.issue_media_hash": "Original media SHA-256 mismatch for %@.",
        "bundle.issue_unhashed_media": "Evidence item %@ contains original bytes without a recorded media hash.",
        "bundle.issue_seal_count": "Snapshot seal %@ has an impossible item count.",
        "bundle.issue_seal_hash": "Snapshot seal hash mismatch for %@."
    ]

    private static let bundleGerman: [String: String] = [
        "bundle.building": "Verifizierungspaket wird erstellt…",
        "bundle.build_share": "Verifizierungspaket erstellen und teilen",
        "bundle.export_failed": "Export des Verifizierungspakets fehlgeschlagen",
        "bundle.verify_import": "Beweispaket prüfen",
        "bundle.verify_failed": "Beweispaket konnte nicht geprüft werden",
        "bundle.verify_title": "Paket prüfen",
        "bundle.result_valid": "Integritätsprüfungen bestanden",
        "bundle.result_invalid": "Integritätsprüfungen fehlgeschlagen",
        "bundle.result_details": "Prüfdetails",
        "bundle.result_case_id": "Fall-ID",
        "bundle.result_items": "Beweiselemente",
        "bundle.result_seals": "Verifizierte Siegel",
        "bundle.result_manifest": "Aktueller Manifest-SHA-256",
        "bundle.result_bundle_hash": "Paket-SHA-256",
        "bundle.result_issues": "Integritätsprobleme",
        "bundle.result_boundary": "Was diese Prüfung bestätigt",
        "bundle.result_boundary_text": "Diese Prüfung bestätigt die interne Konsistenz der exportierten Originaldaten, Datensatz-Hashes und aufgezeichneten Snapshot-Siegel. Sie beweist nicht unabhängig, wann ein reales Ereignis stattgefunden hat, und garantiert keine rechtliche Anerkennung.",
        "bundle.error_missing_case": "Der Beweisfall ist nicht mehr verfügbar.",
        "bundle.error_empty_case": "Füge mindestens ein Beweiselement hinzu, bevor du ein Verifizierungspaket erstellst.",
        "bundle.error_missing_original": "Das gespeicherte Original für %@ fehlt. Das Verifizierungspaket wurde nicht erstellt.",
        "bundle.error_original_integrity": "Das gespeicherte Original für %@ stimmt nicht mehr mit seinem SHA-256-Hash überein. Das Verifizierungspaket wurde nicht erstellt.",
        "bundle.error_record_integrity": "Integritätsprüfung des Beweisdatensatzes für %@ fehlgeschlagen. Das Verifizierungspaket wurde nicht erstellt.",
        "bundle.error_generated_invalid": "Das erzeugte Verifizierungspaket hat seine eigene Integritätsprüfung nicht bestanden.",
        "bundle.error_format": "Diese Datei ist kein unterstütztes Beweis-Verifizierungspaket.",
        "bundle.error_version": "Version %ld des Verifizierungspakets wird nicht unterstützt.",
        "bundle.error_unreadable": "Das Beweis-Verifizierungspaket konnte nicht gelesen werden.",
        "bundle.issue_case_id": "Die Fall-ID ist ungültig.",
        "bundle.issue_case_type": "Der Falltyp ist unbekannt.",
        "bundle.issue_order": "Die Beweiselemente stehen nicht in ihrer kanonischen zeitlichen Reihenfolge.",
        "bundle.issue_item_id": "Beweiselement %@ hat eine ungültige ID.",
        "bundle.issue_item_type": "Beweiselement %@ hat einen unbekannten Typ.",
        "bundle.issue_record_hash": "Beweisdatensatz-Hash stimmt für %@ nicht überein.",
        "bundle.issue_media_missing": "Originaldaten fehlen für %@.",
        "bundle.issue_media_hash": "Originalmedien-SHA-256 stimmt für %@ nicht überein.",
        "bundle.issue_unhashed_media": "Beweiselement %@ enthält Originaldaten ohne aufgezeichneten Medien-Hash.",
        "bundle.issue_seal_count": "Snapshot-Siegel %@ hat eine unmögliche Elementanzahl.",
        "bundle.issue_seal_hash": "Snapshot-Siegel-Hash stimmt für %@ nicht überein."
    ]
}
