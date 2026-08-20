from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype"
PROJECT = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/project.pbxproj"
WORKFLOW = ROOT / ".github/workflows/evidaro-prototype-build.yml"
STATE = ROOT / "apps/002-evidaro/PROJECT_STATE.md"
SPEC = ROOT / "apps/002-evidaro/PRODUCT_SPEC.md"
EN_STRINGS = APP / "en.lproj/Localizable.strings"
DE_STRINGS = APP / "de.lproj/Localizable.strings"
EN_INFO = APP / "en.lproj/InfoPlist.strings"
DE_INFO = APP / "de.lproj/InfoPlist.strings"

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
    EN_STRINGS,
    DE_STRINGS,
    EN_INFO,
    DE_INFO,
    PROJECT,
    WORKFLOW,
    STATE,
    SPEC,
]

for path in required_files:
    if not path.exists():
        raise SystemExit(f"Missing required Evidaro file: {path.relative_to(ROOT)}")

project_text = PROJECT.read_text()
lock_text = (APP / "AppLockController.swift").read_text()
localization_text = (APP / "Localization.swift").read_text()
models_text = (APP / "Models.swift").read_text()
store_text = (APP / "EvidenceStore.swift").read_text()
pack_text = (APP / "EvidencePackExporter.swift").read_text()
app_text = (APP / "EvidaroPrototypeApp.swift").read_text()
root_text = (APP / "RootView.swift").read_text()
detail_text = (APP / "CaseDetailView.swift").read_text()
add_text = (APP / "AddEvidenceView.swift").read_text()
workflow_text = WORKFLOW.read_text()
state_text = STATE.read_text()
spec_text = SPEC.read_text()
en_strings_text = EN_STRINGS.read_text()
de_strings_text = DE_STRINGS.read_text()
en_info_text = EN_INFO.read_text()
de_info_text = DE_INFO.read_text()

checks = {
    "provisional bundle id": "de.kamilunavo.evidaro.prototype" in project_text,
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
    "derived OCR fields": "recognizedText" in models_text and "recognizedTextAt" in models_text and "recognizedTextEngine" in models_text,
    "Apple Vision OCR": "import Vision" in store_text and "VNRecognizeTextRequest" in store_text and "Apple Vision on-device" in store_text,
    "image and PDF OCR": "contentType.conforms(to: .image)" in store_text and "contentType.conforms(to: .pdf)" in store_text and "PDFDocument" in store_text,
    "OCR off main recognition path": "Task.detached(priority: .userInitiated)" in store_text,
    "OCR integrity guard": "mediaIntegrityMismatch" in store_text and "evidenceChangedDuringRecognition" in store_text and "Recognized text is intentionally excluded" in store_text,
    "OCR timeline UX": "evidence.recognized_text" in detail_text and "evidence.ocr_trust" in detail_text,
    "snapshot sealing": "func seal(caseID:" in store_text and "manifestHash" in store_text,
    "shareable manifest": "EVIDARO EVIDENCE MANIFEST" in store_text,
    "PDF exporter compiled": "EvidencePackExporter.swift in Sources" in project_text,
    "PDF evidence pack renderer": "UIGraphicsPDFRenderer" in pack_text and "EVIDENCE PACK" in pack_text,
    "PDF original integrity guard": "verifyOriginalMedia" in pack_text and "originalIntegrityMismatch" in pack_text,
    "PDF record integrity guard": "recordIntegrityMismatch" in pack_text and "EvidenceHasher.itemHash" in pack_text,
    "PDF seal consistency guard": "currentSealMismatch" in pack_text and "currentSnapshotIsSealed" in pack_text,
    "PDF derived OCR labeling": "DERIVED OCR — NOT ORIGINAL EVIDENCE" in pack_text and "OCR is derived metadata" in pack_text,
    "PDF original media previews": "drawImagePreview" in pack_text and "drawPDFPagePreview" in pack_text,
    "PDF share UX": "pdf.build_share" in detail_text and "EvidencePackShareSheet" in detail_text,
    "privacy lock compiled": "AppLockController.swift in Sources" in project_text and "import LocalAuthentication" in lock_text,
    "Face ID usage string": "INFOPLIST_KEY_NSFaceIDUsageDescription" in project_text,
    "device-owner authentication policy": ".deviceOwnerAuthentication" in lock_text and "evaluatePolicy" in lock_text,
    "privacy lock preference": "evidaro.requireDeviceAuthentication" in lock_text and "UserDefaults" in lock_text,
    "background relock": "case .background" in app_text and "appLock.lockIfNeeded()" in app_text,
    "locked-content gate": "if appLock.needsUnlock" in app_text and "EvidaroLockedView" in app_text,
    "privacy lock settings UX": "privacy_lock.require_auth" in root_text and "privacy_lock.title" in root_text,
    "single app-owned store": "RootView(store: store, appLock: appLock)" in app_text and "@ObservedObject var store: EvidenceStore" in root_text,
    "relaunch smoke prepare": "preparePersistenceSmoke" in store_text and "prepared.txt" in app_text,
    "relaunch smoke verify": "verifyPersistenceSmoke" in store_text and "verified.txt" in app_text,
    "two-process simulator gate": "--evidaro-persistence-smoke prepare" in workflow_text and "simctl terminate" in workflow_text and "--evidaro-persistence-smoke verify" in workflow_text,
    "OCR runtime smoke": "prepareOCRSmoke" in store_text and "verifyOCRSmoke" in store_text and "ocr-prepare" in app_text and "ocr-verify" in app_text,
    "OCR process-relaunch gate": "--evidaro-persistence-smoke ocr-prepare" in workflow_text and "--evidaro-persistence-smoke ocr-verify" in workflow_text,
    "PDF pack runtime smoke": "pack-prepare" in app_text and "pack-verify" in app_text and "validateEvidencePack" in app_text,
    "PDF pack process-relaunch gate": "--evidaro-persistence-smoke pack-prepare" in workflow_text and "--evidaro-persistence-smoke pack-verify" in workflow_text,
    "privacy lock runtime smoke": "AppLockSmokeRunner" in lock_text and "lock-prepared" in lock_text and "lock-verified" in lock_text,
    "privacy lock process-relaunch gate": "--evidaro-app-lock-smoke prepare" in workflow_text and "--evidaro-app-lock-smoke verify" in workflow_text,
    "localization helper compiled": "Localization.swift in Sources" in project_text and "NSLocalizedString" in localization_text,
    "English localization resources": 'name = en; path = en.lproj/Localizable.strings' in project_text and '"home.cases" = "Cases";' in en_strings_text,
    "German localization resources": 'name = de; path = de.lproj/Localizable.strings' in project_text and '"home.cases" = "Fälle";' in de_strings_text,
    "German project region": "\n\t\t\t\tde," in project_text,
    "localized privacy prompts": '"NSCameraUsageDescription"' in en_info_text and '"NSFaceIDUsageDescription"' in en_info_text and '"NSCameraUsageDescription"' in de_info_text and '"NSFaceIDUsageDescription"' in de_info_text,
    "hash-stable localized case types": 'case property = "Property"' in models_text and "var localizedName: String" in models_text and 'L10n.string("case.kind.property")' in models_text,
    "hash-stable localized evidence types": 'case observation = "Observation"' in models_text and 'L10n.string("evidence.kind.observation")' in models_text,
    "Dynamic Type adaptive home": "dynamicTypeSize.isAccessibilitySize" in root_text and "ViewThatFits" in root_text,
    "Dynamic Type adaptive case actions": "ViewThatFits" in detail_text and "sealButton" in detail_text and "shareManifestButton" in detail_text,
    "VoiceOver headings": root_text.count("accessibilityHeading") >= 2 and detail_text.count("accessibilityHeading") >= 2,
    "VoiceOver hash semantics": "accessibility.hash_original" in detail_text and "accessibility.hash_record" in detail_text and "accessibilityValue" in detail_text,
    "localized intake UX": "media.take_photo" in add_text and "evidence.factual_note" in add_text and "localizedName" in add_text,
    "German localization runtime smoke": "--evidaro-localization-smoke" in workflow_text and 'AppleLanguages "(de)"' in workflow_text and "localization-verified language=de" in workflow_text and "verifyGermanLocalization" in lock_text,
    "ProofVault retired": "`ProofVault` is retired" in state_text,
    "legal guardrail": "not a law firm" in spec_text and "not legal certification" in state_text,
}

failed = [label for label, passed in checks.items() if not passed]
for label, passed in checks.items():
    print(("✓" if passed else "✗"), label)

if failed:
    raise SystemExit("Evidaro preflight failed: " + ", ".join(failed))

print("Evidaro camera/persistence/OCR/PDF-pack/privacy-lock/localization/accessibility preflight passed")
