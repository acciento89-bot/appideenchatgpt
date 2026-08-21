from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype"
MODELS = (APP / "Models.swift").read_text()
STORE = (APP / "EvidenceStore.swift").read_text()
PACK = (APP / "EvidencePackExporter.swift").read_text()
APP_ENTRY = (APP / "EvidaroPrototypeApp.swift").read_text()
EN = (APP / "en.lproj/Localizable.strings").read_text()
DE = (APP / "de.lproj/Localizable.strings").read_text()
STATE = (ROOT / "apps/002-evidaro/PROJECT_STATE.md").read_text()
FACTORY = (ROOT / "docs/APP_FACTORY_STATE.md").read_text()
checks = {
"Trace evpack format": 'formatIdentifier = "de.kamilunavo.trace.evpack"' in MODELS,
"legacy evpack format retired": 'de.kamilunavo.evidaro.evpack' not in MODELS,
"Trace verification filename": 'Kamilunavo-Trace-' in MODELS and 'Verification.evpack' in MODELS,
"Trace text manifest": 'KAMILUNAVO TRACE EVIDENCE MANIFEST' in STORE,
"legacy public manifest retired": 'EVIDARO EVIDENCE MANIFEST' not in STORE,
"Trace PDF metadata": 'kCGPDFContextCreator as String: "Kamilunavo Trace"' in PACK,
"Trace PDF filename": 'Kamilunavo-Trace-' in PACK and 'Evidence-Pack.pdf' in PACK,
"Trace PDF smoke filename": 'Kamilunavo-Trace-' in APP_ENTRY,
"Free case wording EN": 'Free includes up to 3 cases.' in EN and '3 active cases' not in EN,
"Free case wording DE": 'Free enthält bis zu 3 Fälle.' in DE and '3 aktive Fälle' not in DE,
"Pass 7/8 merged app state": '## Pass 7 — DE/EN + accessibility + localized PDF — GREEN / MERGED' in STATE and '## Pass 8 — offline-verifiable `.evpack` — GREEN / MERGED' in STATE,
"Pass 8 final gate recorded": '32408185123' in STATE,
"portfolio release identity": '# Portfolio app #002 — Kamilunavo Trace' in FACTORY and 'Release pass — Kamilunavo Trace' in FACTORY and 'Release PR #33 — GREEN / MERGED' in FACTORY,
"Build 2 release checkpoint": 'TESTFLIGHT BUILD 2 VALID' in FACTORY and 'Build-2 hardening PR #36' in FACTORY and '62a79d823a6f719fb9b511d329d997aa31dea170' in STATE,
"real StoreKit checkpoint recorded": 'real Lifetime purchase — USER-CONFIRMED' in FACTORY and 'Restore purchases recovery — USER-CONFIRMED' in FACTORY,
}
failed=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("✓" if v else "✗"), k)
if failed: raise SystemExit("Kamilunavo Trace public identity preflight failed: " + ", ".join(failed))
print("Kamilunavo Trace public identity preflight passed")
