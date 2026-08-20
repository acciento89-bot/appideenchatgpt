from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype"
PROJECT = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/project.pbxproj"
SCHEME = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/xcshareddata/xcschemes/EvidaroPrototype.xcscheme"
WORKFLOW = ROOT / ".github/workflows/evidaro-prototype-build.yml"
TESTFLIGHT_WORKFLOW = ROOT / ".github/workflows/kamilunavo-trace-testflight.yml"
STATE = ROOT / "apps/002-evidaro/PROJECT_STATE.md"
SPEC = ROOT / "apps/002-evidaro/PRODUCT_SPEC.md"
EN_STRINGS = APP / "en.lproj/Localizable.strings"
DE_STRINGS = APP / "de.lproj/Localizable.strings"
EN_INFO = APP / "en.lproj/InfoPlist.strings"
DE_INFO = APP / "de.lproj/InfoPlist.strings"
ENTITLEMENT = APP / "EntitlementStore.swift"
PRO_VIEW = APP / "ProUpgradeView.swift"
STOREKIT = APP / "StoreKit/KamilunavoTrace.storekit"
ASSET_CATALOG = APP / "Assets.xcassets/Contents.json"
APP_ICON_CONTENTS = APP / "Assets.xcassets/AppIcon.appiconset/Contents.json"
APP_ICON = APP / "Assets.xcassets/AppIcon.appiconset/KamilunavoTrace-AppIcon-1024.png"

required_files = [
    APP / "EvidaroPrototypeApp.swift",
    APP / "AppLockController.swift",
    APP / "Localization.swift",
    APP / "Models.swift",
    APP / "EvidenceStore.swift",
    APP / "EvidencePackExporter.swift",
    APP / "RootView.swift",
    APP / "CaseDetailView.swift",
    APP / "AddEvidenceView.swift",
    ENTITLEMENT,
    PRO_VIEW,
    STOREKIT,
    ASSET_CATALOG,
    APP_ICON_CONTENTS,
    APP_ICON,
    EN_STRINGS,
    DE_STRINGS,
    EN_INFO,
    DE_INFO,
    PROJECT,
    SCHEME,
    WORKFLOW,
    TESTFLIGHT_WORKFLOW,
    STATE,
    SPEC,
]

for path in required_files:
    if not path.exists():
        raise SystemExit(f"Missing required Kamilunavo Trace file: {path.relative_to(ROOT)}")

project_text = PROJECT.read_text()
scheme_text = SCHEME.read_text()
lock_text = (APP / "AppLockController.swift").read_text()
localization_text = (APP / "Localization.swift").read_text()
models_text = (APP / "Models.swift").read_text()
store_text = (APP / "EvidenceStore.swift").read_text()
pack_text = (APP / "EvidencePackExporter.swift").read_text()
app_text = (APP / "EvidaroPrototypeApp.swift").read_text()
root_text = (APP / "RootView.swift").read_text()
detail_text = (APP / "CaseDetailView.swift").read_text()
add_text = (APP / "AddEvidenceView.swift").read_text()
entitlement_text = ENTITLEMENT.read_text()
pro_view_text = PRO_VIEW.read_text()
storekit_text = STOREKIT.read_text()
app_icon_contents_text = APP_ICON_CONTENTS.read_text()
workflow_text = WORKFLOW.read_text()
testflight_text = TESTFLIGHT_WORKFLOW.read_text()
state_text = STATE.read_text()
spec_text = SPEC.read_text()
en_strings_text = EN_STRINGS.read_text()
de_strings_text = DE_STRINGS.read_text()
en_info_text = EN_INFO.read_text()
de_info_text = DE_INFO.read_text()

checks = {
    # Release identity / icon
    "release bundle id": "PRODUCT_BUNDLE_IDENTIFIER = de.kamilunavo.trace;" in project_text,
    "release display name": 'INFOPLIST_KEY_CFBundleDisplayName = "Kamilunavo Trace";' in project_text and '.navigationTitle("Kamilunavo Trace")' in root_text,
    "legacy public bundle id retired": "de.kamilunavo.evidaro.prototype" not in project_text,
    "AppIcon wired": "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon" in project_text and "Assets.xcassets in Resources" in project_text,
    "1024 app icon present": APP_ICON.stat().st_size > 1000 and 'KamilunavoTrace-AppIcon-1024.png' in app_icon_contents_text,
    "release privacy prompts EN": "Kamilunavo Trace" in en_info_text and "Evidaro" not in en_info_text,
    "release privacy prompts DE": "Kamilunavo Trace" in de_info_text and "Evidaro" not in de_info_text,
    "public DE/EN brand": "Kamilunavo Trace" in en_strings_text and "Kamilunavo Trace" in de_strings_text,

    # Platform foundation
    "iOS 17 deployment": "IPHONEOS_DEPLOYMENT_TARGET = 17.0" in project_text,
    "iPhone-only target": "TARGETED_DEVICE_FAMILY = 1" in project_text,
    "SwiftData models": "import SwiftData" in models_text and models_text.count("@Model") >= 3,
    "persistent ModelContainer": "ModelContainer" in store_text and "ModelContext" in store_text,
    "SHA-256 item hashing": "SHA256.hash" in store_text and "contentHash" in store_text,
    "original media SHA-256": "mediaHash" in models_text and "sha256($0.data)" in store_text,
    "private media storage": "applicationSupportDirectory" in store_text and "EvidaroMedia" in store_text,
    "photo intake": "PhotosPicker" in add_text and "loadTransferable" in add_text,
    "file/PDF intake": ".fileImporter" in add_text and ".pdf" in add_text,
    "direct camera intake": "UIImagePickerController" in add_text and "sourceType = .camera" in add_text,
    "camera privacy string": "INFOPLIST_KEY_NSCameraUsageDescription" in project_text,

    # OCR / integrity / sealing
    "derived OCR fields": "recognizedText" in models_text and "recognizedTextAt" in models_text and "recognizedTextEngine" in models_text,
    "Apple Vision OCR": "import Vision" in store_text and "VNRecognizeTextRequest" in store_text and "Apple Vision on-device" in store_text,
    "image and PDF OCR": "contentType.conforms(to: .image)" in store_text and "contentType.conforms(to: .pdf)" in store_text and "PDFDocument" in store_text,
    "OCR off main recognition path": "Task.detached(priority: .userInitiated)" in store_text,
    "OCR integrity guard": "mediaIntegrityMismatch" in store_text and "evidenceChangedDuringRecognition" in store_text and "Recognized text is intentionally excluded" in store_text,
    "OCR timeline UX": "evidence.recognized_text" in detail_text and "evidence.ocr_trust" in detail_text,
    "snapshot sealing": "func seal(caseID:" in store_text and "manifestHash" in store_text,
    "shareable manifest": "EVIDARO EVIDENCE MANIFEST" in store_text,

    # PDF pack
    "PDF exporter compiled": "EvidencePackExporter.swift in Sources" in project_text,
    "PDF evidence pack renderer": "UIGraphicsPDFRenderer" in pack_text and 'L10n.string("pdf.heading.evidence_pack")' in pack_text,
    "PDF original integrity guard": "verifyOriginalMedia" in pack_text and "originalIntegrityMismatch" in pack_text,
    "PDF record integrity guard": "recordIntegrityMismatch" in pack_text and "EvidenceHasher.itemHash" in pack_text,
    "PDF seal consistency guard": "currentSealMismatch" in pack_text and "currentSnapshotIsSealed" in pack_text,
    "PDF derived OCR labeling": 'L10n.string("pdf.ocr.heading")' in pack_text and 'L10n.string("pdf.ocr.trust")' in pack_text,
    "PDF original media previews": "drawImagePreview" in pack_text and "drawPDFPagePreview" in pack_text,
    "PDF localized errors": 'L10n.string("pdf.error_missing_case")' in pack_text and 'L10n.format("pdf.error_record_integrity"' in pack_text,
    "PDF localized case/evidence display only": "evidenceCase.kind.localizedName" in pack_text and "item.kind.localizedName" in pack_text and 'case property = "Property"' in models_text and 'case observation = "Observation"' in models_text,
    "PDF full localized chrome": all(key in pack_text for key in [
        'pdf.preview.heading_image',
        'pdf.preview.heading_pdf',
        'pdf.seals.explanation',
        'pdf.seals.current_matches',
        'pdf.page',
        'pdf.continued',
    ]),
    "Trace PDF branding EN/DE": '"pdf.meta.title" = "Kamilunavo Trace Evidence Pack' in en_strings_text and '"pdf.meta.title" = "Kamilunavo Trace Beweispaket' in de_strings_text,

    # Offline verifier. The v1 format identifier intentionally remains stable for compatibility.
    "offline verification bundle format": 'formatIdentifier = "de.kamilunavo.evidaro.evpack"' in models_text and "EvidenceVerificationBundleDocument" in models_text and "currentVersion = 1" in models_text,
    "offline bundle carries originals": "mediaDataBase64" in models_text and "base64EncodedString()" in models_text and "Data(base64Encoded:" in models_text,
    "offline bundle record hash verification": "rawItemHash" in models_text and '"recordedAt=\\(recordedAtCanonical)"' in models_text and "bundle.issue_record_hash" in models_text,
    "offline bundle media hash verification": "EvidenceHasher.sha256(bytes) != expectedMediaHash" in models_text and "bundle.issue_media_hash" in models_text,
    "offline bundle historical seal verification": "Array(document.items.prefix(seal.itemCount))" in models_text and "expectedSeal == seal.manifestHash" in models_text,
    "offline bundle OCR excluded from integrity": "recognizedText" in models_text and "rawItemHash" in models_text and "derivedOCRAffectedIntegrity" in models_text,
    "offline bundle self-verifies before write": "EvidenceBundleVerifier.verify(data: data)" in models_text and "generatedBundleInvalid" in models_text and "data.write(to: url" in models_text,
    "offline bundle import verifier remains available": "showsVerificationImporter" in root_text and ".fileImporter" in root_text and "EvidenceBundleVerifier.verify(data: data)" in root_text and "VerificationResultView" in root_text,
    "offline bundle runtime smoke": "EvidenceBundleSmokeRunner" in models_text and "tamperAccepted" in models_text and "derivedOCRAffectedIntegrity" in models_text,
    "offline bundle tamper rejection": 'tampered.items[0].note += " TAMPERED"' in models_text and "guard !tamperedResult.isValid" in models_text,
    "offline bundle derived OCR tolerance": 'derivedOnly.items[0].recognizedText = "DERIVED OCR CHANGED FOR SMOKE"' in models_text and "guard derivedResult.isValid" in models_text,
    "offline bundle process-relaunch gate": "--evidaro-verification-bundle-smoke prepare" in workflow_text and "--evidaro-verification-bundle-smoke verify" in workflow_text and "BUNDLE_VERIFIED_HASH" in workflow_text,
    "offline bundle CI asserts trust boundary": "tamperRejected=true" in workflow_text and "derivedOCRIgnored=true" in workflow_text and 'test "${BUNDLE_VERIFIED_HASH}" = "${BUNDLE_PREPARED_HASH}"' in workflow_text,

    # Privacy lock / localization / accessibility
    "privacy lock compiled": "AppLockController.swift in Sources" in project_text and "import LocalAuthentication" in lock_text,
    "Face ID usage string": "INFOPLIST_KEY_NSFaceIDUsageDescription" in project_text,
    "device-owner authentication policy": ".deviceOwnerAuthentication" in lock_text and "evaluatePolicy" in lock_text,
    "privacy lock preference migration preserved": "evidaro.requireDeviceAuthentication" in lock_text and "UserDefaults" in lock_text,
    "background relock": "case .background" in app_text and "appLock.lockIfNeeded()" in app_text,
    "locked-content gate": "if appLock.needsUnlock" in app_text and "EvidaroLockedView" in app_text,
    "locked UI localized": 'Text("locked.title")' in app_text and 'Label("locked.unlock"' in app_text,
    "privacy lock settings UX": "privacy_lock.require_auth" in root_text and "privacy_lock.title" in root_text,
    "single app-owned store": "RootView(store: store, appLock: appLock)" in app_text and "@ObservedObject var store: EvidenceStore" in root_text,
    "English localization resources": 'name = en; path = en.lproj/Localizable.strings' in project_text and '"home.cases" = "Cases";' in en_strings_text,
    "German localization resources": 'name = de; path = de.lproj/Localizable.strings' in project_text and '"home.cases" = "Fälle";' in de_strings_text,
    "localized PDF resources EN/DE": '"pdf.preview.heading_pdf"' in en_strings_text and '"pdf.seals.current_matches"' in en_strings_text and '"pdf.preview.heading_pdf"' in de_strings_text and '"pdf.seals.current_matches"' in de_strings_text,
    "localized bundle resources EN/DE": '"bundle.verify_import" = "Verify evidence bundle";' in en_strings_text and '"bundle.verify_import" = "Beweispaket prüfen";' in de_strings_text,
    "German project region": "\n\t\t\t\tde," in project_text,
    "hash-stable localized case types": 'case property = "Property"' in models_text and "var localizedName: String" in models_text and 'L10n.string("case.kind.property")' in models_text,
    "hash-stable localized evidence types": 'case observation = "Observation"' in models_text and 'L10n.string("evidence.kind.observation")' in models_text,
    "Dynamic Type adaptive home": "dynamicTypeSize.isAccessibilitySize" in root_text and "ViewThatFits" in root_text,
    "Dynamic Type adaptive case actions": "ViewThatFits" in detail_text and "sealButton" in detail_text and "shareManifestButton" in detail_text,
    "VoiceOver headings": root_text.count("accessibilityHeading") >= 2 and detail_text.count("accessibilityHeading") >= 2,
    "VoiceOver hash semantics": "accessibility.hash_original" in detail_text and "accessibility.hash_record" in detail_text and "accessibilityValue" in detail_text,
    "German localization runtime smoke": "--evidaro-localization-smoke" in workflow_text and 'AppleLanguages "(de)"' in workflow_text and "bundle=localized camera=localized faceID=localized" in workflow_text and "verifyGermanLocalization" in lock_text,

    # Lifetime Pro / StoreKit 2
    "Lifetime Pro source compiled": "EntitlementStore.swift in Sources" in project_text and "ProUpgradeView.swift in Sources" in project_text,
    "Lifetime product id": 'lifetimeProductID = "de.kamilunavo.trace.pro.lifetime"' in entitlement_text and '"productID" : "de.kamilunavo.trace.pro.lifetime"' in storekit_text,
    "Lifetime non-consumable": '"type" : "NonConsumable"' in storekit_text and '"displayPrice" : "14.99"' in storekit_text,
    "StoreKit config attached to scheme": "KamilunavoTrace.storekit" in scheme_text,
    "verified current entitlements": "Transaction.currentEntitlements" in entitlement_text and "case .verified(let transaction)" in entitlement_text,
    "transaction updates recovery": "Transaction.updates" in entitlement_text and "Transaction.unfinished" in entitlement_text,
    "explicit restore only sync": "func restorePurchases" in entitlement_text and "try await AppStore.sync()" in entitlement_text,
    "three free cases": "freeActiveCaseLimit = 3" in entitlement_text and "canCreateCase(currentCount:" in entitlement_text,
    "case-limit paywall UX": "entitlement.canCreateCase(currentCount: store.cases.count)" in root_text and "pro.case_limit_title" in root_text,
    "rich exports gated by Pro": detail_text.count("guard entitlement.isPro else") >= 2 and "showsPro = true" in detail_text,
    "received bundle verification not Pro-gated": "private func importVerificationBundle" in root_text and "EvidenceBundleVerifier.verify(data: data)" in root_text,
    "Pro UI purchase + restore": "purchaseLifetime()" in pro_view_text and "restorePurchases()" in pro_view_text,
    "Pro resources EN/DE": '"pro.buy_lifetime"' in en_strings_text and '"pro.restore"' in en_strings_text and '"pro.buy_lifetime"' in de_strings_text and '"pro.restore"' in de_strings_text,

    # Regression/runtime gates
    "relaunch smoke prepare": "preparePersistenceSmoke" in store_text and "prepared.txt" in app_text,
    "relaunch smoke verify": "verifyPersistenceSmoke" in store_text and "verified.txt" in app_text,
    "two-process simulator gate": "--evidaro-persistence-smoke prepare" in workflow_text and "simctl terminate" in workflow_text and "--evidaro-persistence-smoke verify" in workflow_text,
    "OCR runtime smoke": "prepareOCRSmoke" in store_text and "verifyOCRSmoke" in store_text and "ocr-prepare" in app_text and "ocr-verify" in app_text,
    "OCR process-relaunch gate": "--evidaro-persistence-smoke ocr-prepare" in workflow_text and "--evidaro-persistence-smoke ocr-verify" in workflow_text,
    "PDF pack runtime smoke": "pack-prepare" in app_text and "pack-verify" in app_text and "validateEvidencePack" in app_text,
    "PDF pack process-relaunch gate": "--evidaro-persistence-smoke pack-prepare" in workflow_text and "--evidaro-persistence-smoke pack-verify" in workflow_text,
    "German PDF pack relaunch gate": '--evidaro-persistence-smoke pack-prepare -AppleLanguages "(de)"' in workflow_text and '--evidaro-persistence-smoke pack-verify -AppleLanguages "(de)"' in workflow_text and "GERMAN_PACK_VERIFIED_HASH" in workflow_text,
    "privacy lock runtime smoke": "AppLockSmokeRunner" in lock_text and "lock-prepared" in lock_text and "lock-verified" in lock_text,
    "privacy lock process-relaunch gate": "--evidaro-app-lock-smoke prepare" in workflow_text and "--evidaro-app-lock-smoke verify" in workflow_text,
    "Trace simulator bundle": 'BUNDLE_ID="de.kamilunavo.trace"' in workflow_text,

    # TestFlight pipeline
    "TestFlight workflow bundle": "BUNDLE_ID: 'de.kamilunavo.trace'" in testflight_text,
    "TestFlight release build": "-configuration Release" in testflight_text and "-sdk iphoneos" in testflight_text,
    "TestFlight validates display name": "CFBundleDisplayName" in testflight_text and "Kamilunavo Trace" in testflight_text,
    "ASC API key flow": "ASC_ISSUER_ID" in testflight_text and "ASC_KEY_ID" in testflight_text and "ASC_PRIVATE_KEY_B64" in testflight_text,
    "Apple cloud signing upload": "-exportArchive" in testflight_text and "-allowProvisioningUpdates" in testflight_text and "app-store-connect" in testflight_text,
    "PR cannot upload TestFlight": "PR validation only" in testflight_text and "github.event_name != 'pull_request'" in testflight_text,

    # Product/legal state
    "ProofVault retired": "`ProofVault` is retired" in state_text,
    "legal guardrail": "not a law firm" in spec_text and "not legal certification" in state_text,
}

failed = [label for label, passed in checks.items() if not passed]
for label, passed in checks.items():
    print(("✓" if passed else "✗"), label)

if failed:
    raise SystemExit("Kamilunavo Trace preflight failed: " + ", ".join(failed))

print("Kamilunavo Trace release preflight passed: identity/icon + persistence + OCR + PDF + offline verifier + privacy/accessibility + Lifetime Pro + TestFlight")
