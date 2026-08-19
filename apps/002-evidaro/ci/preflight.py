from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype"
PROJECT = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/project.pbxproj"
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
    STATE,
    SPEC,
]

for path in required_files:
    if not path.exists():
        raise SystemExit(f"Missing required Evidaro foundation file: {path.relative_to(ROOT)}")

project_text = PROJECT.read_text()
store_text = (APP / "EvidenceStore.swift").read_text()
state_text = STATE.read_text()
spec_text = SPEC.read_text()

checks = {
    "provisional bundle id": "de.kamilunavo.evidaro.prototype" in project_text,
    "iOS 17 deployment": "IPHONEOS_DEPLOYMENT_TARGET = 17.0" in project_text,
    "iPhone-only target": "TARGETED_DEVICE_FAMILY = 1" in project_text,
    "SHA-256 item hashing": "SHA256.hash" in store_text and "contentHash" in store_text,
    "snapshot sealing": "func seal(caseID:" in store_text and "manifestHash" in store_text,
    "shareable manifest": "EVIDARO EVIDENCE MANIFEST" in store_text,
    "ProofVault retired": "`ProofVault` is retired" in state_text,
    "legal guardrail": "not a law firm" in spec_text and "not legal certification" in state_text,
}

failed = [label for label, passed in checks.items() if not passed]
for label, passed in checks.items():
    print(("✓" if passed else "✗"), label)

if failed:
    raise SystemExit("Evidaro preflight failed: " + ", ".join(failed))

print("Evidaro foundation preflight passed")
