# Kamilunavo Trace — Project State

Last updated: 2026-08-21
Status: BUILD 5 PHYSICAL RELEASE QA GREEN — APP STORE SUBMISSION PREP NEXT
Portfolio slot: #002
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/`
Canonical branch: `main`

## Handoff rule

This file is the authoritative app-specific handoff for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Treat the Build 5 checkpoint below as the current release-candidate baseline.
4. Never call a queued/in-progress workflow green and never bypass integrity/relaunch/device gates.
5. After any code change touching a passed physical gate, reopen and re-run that gate.
6. PR #37 is historical Build 2 documentation and must remain untouched unless explicitly requested.

## Current checkpoint — Build 5 physical release candidate — GREEN

Kamilunavo Trace is currently at **0.1.0 (5)**.

Canonical Build 5 source:
`128da643cb8b5320546242ba511118d18a2edb07`

Build 5 contains the accepted reader-focused PDF redesign and has now passed the major real-iPhone release paths.

### Reader-focused PDF v2 — GREEN / MERGED

PR #45: `Rebuild Kamilunavo Trace PDF layout after physical QA`

The Build 4 document was physically rejected because it over-explained the integrity model, repeated seal/manifest material and created unnecessary pages/dead space. Build 5 replaces that presentation with a compact evidence report.

Accepted visible structure:

- compact case/cover summary
- evidence metadata and original preview prioritized for the reader
- OCR shown once as clearly derived text
- technical hashes/seal data reduced to compact `Prüfdetails`
- no standalone Integritätsmodell page
- no standalone snapshot/seal page
- public branding is Kamilunavo Trace

The redesign did **not** change original evidence bytes, original-media SHA-256, evidence-record hashing, snapshot-seal semantics, OCR provenance, `.evpack`, StoreKit or the local-first trust boundary.

### Build 5 promotion / signed TestFlight upload — SUCCESS

Build-number source commit:
`128da643cb8b5320546242ba511118d18a2edb07`

A temporary protected bridge in `acciento89-bot/onemorefloor` was used because the App Store Connect signing secrets are intentionally not stored in `appideenchatgpt`.

- temporary bridge PR #128 — CLOSED WITHOUT MERGE
- bridge run `32525159929`
- upload job `96905533457`
- signed archive/export completed
- App Store Connect upload reported `Upload succeeded`
- Apple accepted the package for processing

No bridge workflow belongs on One More Floor `main`.

## Physical iPhone QA — BUILD 5 GREEN

Detailed checkpoint: `apps/002-evidaro/BUILD5_DEVICE_QA.md`

User-confirmed on signed TestFlight Build 5:

- camera capture works on real hardware
- captured original persists through force quit/relaunch
- original SHA-256 remains stable
- original filename/reference is reachable
- stored original can be shared/exported and opened normally
- image OCR returns plausible text
- imported-PDF OCR returns plausible text/page count
- OCR refresh does not alter original SHA-256, evidence-record SHA-256 or an existing snapshot seal
- OCR and integrity anchors survive relaunch
- Privacy Lock uses real Face ID/device-owner authentication
- cancelled authentication keeps evidence hidden
- background/return requires unlock
- enabled/disabled Privacy Lock state persists correctly
- German and English public UI/PDF surfaces are sane
- VoiceOver navigation is usable
- largest Dynamic Type keeps critical controls usable
- `.evpack` exports, saves externally and re-imports successfully
- untouched `.evpack` verifies green with plausible counts and visible hashes
- reader-focused Build 5 PDF is visually accepted

Situational/non-blocking spot-checks still noted in the detailed QA file:

- first camera permission prompt was not forcibly reset/re-requested during this Build 5 pass
- received `.evpack` verification while Pro is inactive/free remains an optional physical spot-check; product policy and automated gates require verification to remain free

## StoreKit / Lifetime Pro checkpoint

Product:
`de.kamilunavo.trace.pro.lifetime`

Type: non-consumable Lifetime Pro.

The signed TestFlight purchase → immediate Pro activation → relaunch entitlement recovery → Restore path was physically confirmed on the earlier Build 2 checkpoint. The Build 5 PDF/layout work did not change StoreKit or entitlement logic, so that signed-device checkpoint remains valid until StoreKit code changes.

Implementation expectations remain:

- verified StoreKit 2 transactions only
- `Transaction.currentEntitlements` recovery
- transaction updates/unfinished recovery
- explicit Restore via `AppStore.sync()`
- Free: up to 3 cases
- Pro: unlimited cases + PDF export + `.evpack` export
- received `.evpack` verification remains free/read-only

Apple-side App Store submission metadata/review configuration is a separate release gate and must be checked before claiming App Store submission complete.

## Final public identity

Final public release name: **Kamilunavo Trace**.

- display name: `Kamilunavo Trace`
- bundle id: `de.kamilunavo.trace`
- category direction: Productivity
- iPhone / iOS 17+
- public PDF metadata/filename/cover/header/footer use Kamilunavo Trace

`ProofVault` and `Evidaro` are retired as public names. Historical internal paths, compatibility keys and deterministic smoke fixtures such as `EVIDARO 4827` may retain old internal identifiers where renaming would add migration/integrity risk without user benefit.

## Product thesis

> Capture facts while they are fresh. Preserve originals. Verify the chain later.

Core chain:

**original bytes → original SHA-256 → evidence-record SHA-256 → snapshot seals → derived OCR → localized PDF + offline-verifiable `.evpack`**

## Trust boundary

- no legal-admissibility guarantee
- no notarization claim
- no claim that an app timestamp independently proves when a real-world event happened
- hashes/seals are integrity aids, not legal certification
- OCR is derived metadata and excluded from original/evidence-record/seal identity
- PDF is a derived presentation and does not replace originals
- `.evpack` v1 verifies internal consistency of embedded originals, record hashes and recorded seals; it is not an external signature or independent timestamp authority
- v1 remains local-first; evidence is not uploaded to Kamilunavo servers
- received `.evpack` verification stays free and read-only

## Merged foundation checkpoints

- Foundation — PR #15 — merge `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`
- SwiftData + hashed media — PR #20 — merge `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`
- Camera + process relaunch — PR #22 — merge `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- Local derived OCR — PR #24 — merge `ad3876dbac044759223d0bdf7a1c095e461bc16b`
- Integrity-checked PDF foundation — PR #27 — merge `22f8b560c2529fb064feaa591b901acecf8da573`
- Device-auth Privacy Lock — PR #28 — merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`
- DE/EN + accessibility + localized PDF — PR #29 — merge `bf3ecf74887c08d52bbadf11a13174c83133b093`
- Offline-verifiable `.evpack` — PR #32 — merge `e5c57335888a80e120fefea686b29f6ed8715b2f`
- Public Kamilunavo Trace release pass — PR #33 — merge `69b8a1d99082ff804f2a532c636af3008d79546a`

## Current next action

**Treat Build 5 as the accepted physical release-candidate baseline. Do not change the app merely for more TestFlight churn. Next work should focus on App Store Connect submission readiness/metadata and only reopen app code if a real release blocker is found.**
