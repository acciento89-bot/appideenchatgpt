# Kamilunavo Trace — Project State

Last updated: 2026-08-22
Status: BUILD 9 DEVICE + APPLE IAP METADATA GREEN — APP STORE SUBMISSION ASSEMBLY NEXT
Portfolio slot: #002
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/`
Canonical branch: `main`

## Handoff rule

This file is the authoritative app-specific handoff for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Treat Build 9 as the current signed TestFlight release candidate.
4. The broad physical functionality baseline remains the completed Build 5 device QA because subsequent release work did not alter those functional paths; Build 9 additionally closes the AppIcon defect.
5. Never call a queued/in-progress workflow green and never bypass integrity/relaunch/device gates.
6. After any code change touching a passed physical gate, reopen and re-run that gate.
7. PR #37 is historical Build 2 documentation and must remain untouched unless explicitly requested.

## Current checkpoint — Build 9 signed TestFlight release candidate — GREEN

Kamilunavo Trace is currently at **0.1.0 (9)** for the accepted TestFlight candidate.

Canonical Build 9 Trace source:
`2e2d51a26b8c07cd4555deed8f1b1466af184e83`

Build 9 preserves the accepted Build 5 app/PDF behavior and fixes the Home Screen AppIcon defect that affected Builds 6–8.

### Build 9 AppIcon repair — GREEN

Root cause of the black/missing Home Screen icon was the damaged/truncated 1024×1024 AppIcon PNG itself, not merely Dark/Tinted asset assignment.

Build 9:

- replaces the damaged AppIcon binary with a valid 1024×1024 RGB PNG without alpha
- keeps the AppIcon asset catalog wired correctly
- adds a compiled-icon guard against blank/dark output
- verifies Xcode's generated 120×120 `AppIcon60x60@2x.png`
- was physically installed from TestFlight and the Home Screen icon was confirmed correct on a real iPhone

### Build 9 signed TestFlight / Apple processing — GREEN

- exact Trace source: `2e2d51a26b8c07cd4555deed8f1b1466af184e83`
- protected TestFlight upload run: `32565389329`
- independent App Store Connect processing check: `32565561318`
- Apple `processingState=VALID`
- temporary protected One More Floor bridge PR #138 — CLOSED WITHOUT MERGE

No bridge workflow belongs on One More Floor `main`.

## Reader-focused PDF v2 — GREEN / FROZEN

The accepted PDF design originated with the Build 5 release candidate and remains unchanged in Build 9.

Accepted visible structure:

- compact case/cover summary
- evidence metadata and original preview prioritized for the reader
- OCR shown once as clearly derived text
- technical hashes/seal data reduced to compact `Prüfdetails`
- no standalone Integritätsmodell page
- no standalone snapshot/seal page
- public branding is Kamilunavo Trace

The presentation does **not** change original evidence bytes, original-media SHA-256, evidence-record hashing, snapshot-seal semantics, OCR provenance, `.evpack`, StoreKit or the local-first trust boundary.

## Physical iPhone QA — FUNCTIONAL BASELINE GREEN

Detailed completed checkpoint: `apps/002-evidaro/BUILD5_DEVICE_QA.md`

User-confirmed on signed TestFlight builds across the release-candidate sequence:

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
- reader-focused PDF is visually accepted
- Build 9 Home Screen icon is physically confirmed correct

Situational/non-blocking spot-checks still noted in the detailed QA file:

- first camera permission prompt was not forcibly reset/re-requested during the completed device pass
- received `.evpack` verification while Pro is inactive/free remains an optional physical spot-check; product policy and automated gates require verification to remain free

## StoreKit / Lifetime Pro — DEVICE + APPLE METADATA GREEN

Product:
`de.kamilunavo.trace.pro.lifetime`

Type: non-consumable Lifetime Pro.
Apple IAP ID: `6803768784`.
Launch price baseline: Germany €14.99.

The signed TestFlight purchase → immediate Pro activation → relaunch entitlement recovery → Restore path was physically confirmed on the earlier Build 2 checkpoint. Later PDF/AppIcon work did not change StoreKit or entitlement logic, so that signed-device checkpoint remains valid until StoreKit code changes.

Apple-side App Review metadata is now complete for the Lifetime Pro item:

- real Trace Pro UI rendered from locked Build 9 source
- App Review screenshot artifact ID `9474287365`
- artifact digest `sha256:6368e7eedb6f421b903e7ce1038e23081436d7dac87225c32f87a9e7f85f08f8`
- App Store Connect screenshot ID `70780505-7af2-483e-95a4-c0fd1de03322`
- screenshot asset delivery state `COMPLETE`
- screenshot delivery error count `0`
- Lifetime Pro state `READY_TO_SUBMIT`
- upload run `32566608375`
- independent read-only verification run `32566871126` — SUCCESS
- temporary protected One More Floor bridge PR #141 — CLOSED WITHOUT MERGE

Implementation expectations remain:

- verified StoreKit 2 transactions only
- `Transaction.currentEntitlements` recovery
- transaction updates/unfinished recovery
- explicit Restore via `AppStore.sync()`
- Free: up to 3 cases
- Pro: unlimited cases + PDF export + `.evpack` export
- received `.evpack` verification remains free/read-only

## Final public identity

Final public release name: **Kamilunavo Trace**.

- display name: `Kamilunavo Trace`
- bundle id: `de.kamilunavo.trace`
- category direction: Productivity
- iPhone / iOS 17+
- public PDF metadata/filename/cover/header/footer use Kamilunavo Trace

`ProofVault` is retired as a public-name candidate. `Evidaro` is also retired as a public release name. Historical internal paths, compatibility keys and deterministic smoke fixtures such as `EVIDARO 4827` may retain old internal identifiers where renaming would add migration/integrity risk without user benefit.

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
- offline-verifiable `.evpack` — PR #32 — merge `e5c57335888a80e120fefea686b29f6ed8715b2f`
- public Kamilunavo Trace release identity — PR #33 — merge `69b8a1d99082ff804f2a532c636af3008d79546a`
- Build 5 physical release QA — PR #47 — merge `97fecc80327a39833fefae10273f7e06763dcebe`

## Remaining App Store submission assembly

Do **not** claim App Store submission complete until these live App Store Connect items are verified:

- Marketing, Support and Privacy URLs resolve in production
- DE/EN App Store version localizations are present
- required App Store screenshots are uploaded for the active localizations/device class
- Build `0.1.0 (9)` is selected/attached to the version intended for review
- App Privacy answers are complete and consistent with the privacy manifest/product behavior
- age rating is complete
- export-compliance state is complete
- Lifetime Pro is associated with the app version/review submission as required
- agreements/tax/banking have no blocking account state

Final **Submit for Review** is an explicit external release action and must not be performed without direct confirmation.

## Current next action

**Keep Build 9 frozen as the current release candidate. Verify and assemble the remaining live App Store Connect listing/submission fields. Do not create Build 10 unless a real release blocker requires an app-code change.**
