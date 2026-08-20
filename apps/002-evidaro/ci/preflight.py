from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype"
PROJECT = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/project.pbxproj"
WORKFLOW = ROOT / ".github/workflows/evidaro-prototype-build.yml"
STATE = ROOT / "apps/002-evidaro/PROJECT_STATE.md"
SPEC = ROOT / "apps/002-evidaro/PRODUCT_SPEC.md"

required_files = [
    APP / "EvidaroPrototypeApp.swift",
    APP / "Models.swift",
    APP / "EvidenceStore.swift",
    APP / "RootView.swift",
    APP / "CaseDetailView.swift",
    APP / "AddEvidenceView.swift",
    PROJECT,
    WORKFLOW,
    STATE,
    SPEC,
]

for path in required_files:
    if not path.exists():
        raise SystemExit(f"Missing required Evidaro file: {path.relative_to(ROOT)}")

project_text = PROJECT.read_text()
models_text = (APP / "Models.swift").read_text()
store_text = (APP / "EvidenceStore.swift").read_text()
app_text = (APP / "EvidaroPrototypeApp.swift").read_text()
root_text = (APP / "RootView.swift").read_text()
detail_text = (APP / "CaseDetailView.swift").read_text()
add_text = (APP / "AddEvidenceView.swift").read_text()
workflow_text = WORKFLOW.read_text()
state_text = STATE.read_text()
spec_text = SPEC.read_text()

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
    "OCR timeline UX": "Recognized text" in detail_text and "Derived locally with Apple Vision" in detail_text,
    "snapshot sealing": "func seal(caseID:" in store_text and "manifestHash" in store_text,
    "shareable manifest": "EVIDARO EVIDENCE MANIFEST" in store_text,
    "single app-owned store": "RootView(store: store)" in app_text and "@ObservedObject var store: EvidenceStore" in root_text,
    "relaunch smoke prepare": "preparePersistenceSmoke" in store_text and "prepared.txt" in app_text,
    "relaunch smoke verify": "verifyPersistenceSmoke" in store_text and "verified.txt" in app_text,
    "two-process simulator gate": "--evidaro-persistence-smoke prepare" in workflow_text and "simctl terminate" in workflow_text and "--evidaro-persistence-smoke verify" in workflow_text,
    "OCR runtime smoke": "prepareOCRSmoke" in store_text and "verifyOCRSmoke" in store_text and "ocr-prepare" in app_text and "ocr-verify" in app_text,
    "OCR process-relaunch gate": "--evidaro-persistence-smoke ocr-prepare" in workflow_text and "--evidaro-persistence-smoke ocr-verify" in workflow_text,
    "ProofVault retired": "`ProofVault` is retired" in state_text,
    "legal guardrail": "not a law firm" in spec_text and "not legal certification" in state_text,
}

failed = [label for label, passed in checks.items() if not passed]
for label, passed in checks.items():
    print(("✓" if passed else "✗"), label)

if failed:
    raise SystemExit("Evidaro preflight failed: " + ", ".join(failed))

print("Evidaro camera/persistence/OCR preflight passed")
