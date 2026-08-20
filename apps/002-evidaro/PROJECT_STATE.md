# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — PASS 7 GREEN / MERGED; PASS 8 OFFLINE VERIFIER IMPLEMENTED / FINAL EXACT-HEAD GATE PENDING
Portfolio slot: #002 (original working title: ProofVault)
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/prototype/`

## Handoff rule

This file is the authoritative state for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Inspect current `main`, open PRs and CI before code changes.
4. Update this file after every major product/release pass.
5. Do not call a workflow green if a relevant job failed or is still queued.
6. Do not merge a major pass until the exact final documentation-aligned head has completed the full relevant gate successfully.

## Naming

`ProofVault` is retired as a public-name candidate because current market research found an iPhone/iPad app named `ProofVault: Document Vault` with a substantially overlapping document-vault feature set.

Current internal/working name: **Evidaro**.

**Evidaro must no longer be treated as a release-cleared public name.** Updated 2026-08-20 web research found an existing public `Evidaro` project in the housing-conditions / housing-disrepair space with a surveyor-facing product direction. That is thematically too close to this app's property/evidence use cases to ignore. Final naming is therefore an explicit release blocker; no App Store identity, icon lock or StoreKit product naming should assume Evidaro is final.

No web/App Store search in this repository is legal trademark clearance.

## Product thesis

> Capture facts while they are fresh. Seal evidence you can verify later.

The app is a local-first evidence-case tool for real-world situations where a user may later need a factual timeline, preserved originals, integrity anchors and a clean proof pack.

Primary examples:
- rental handovers and property damage
- damaged deliveries
- vehicle condition / accident documentation
- contractor or service disputes
- insurance incidents
- warranty/claim evidence that is not primarily a purchase tracker
- workplace or administrative event records

## Core loop

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Build/share PDF or offline verification bundle -> Verify received bundle locally**

A seal never rewrites previous evidence. Future additions create a newer snapshot while older seal hashes remain visible.

## Trust boundary

- no legal-admissibility claim
- no claim that a timestamp independently proves when the real-world event occurred
- no claim that a self-contained offline bundle is a notarial signature or external trust anchor
- hashes are integrity aids, not legal certification
- `.evpack` verification proves internal consistency against the values recorded inside the bundle; a party that deliberately rewrites content and recomputes every unhashed trust anchor is outside what a self-contained unsigned v1 bundle can independently disprove
- v1 stays local-first; no evidence upload to Kamilunavo servers
- OCR is derived metadata only; stored original bytes/hash remain the source of truth
- generated PDF previews are derived renderings, not replacements for originals
- privacy lock protects app access but does not change evidence hashes, seals or source bytes
- localization changes presentation only; persisted enum raw values remain stable and hash-relevant data is never translated

## Pass 1 — FOUNDATION — GREEN / MERGED

PR #15 `Build portfolio app #002 Evidaro foundation` — MERGED.

Verified gate:
- workflow run `32312124275`
- build job `96257080572`
- foundation preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`

Implemented:
- native SwiftUI / iOS 17+ / iPhone first
- provisional bundle id `de.kamilunavo.evidaro.prototype`
- case dashboard + case creation
- evidence timeline
- note/source evidence capture
- SHA-256 content hash per evidence item
- repeatable snapshot sealing
- shareable text manifest
- dedicated Xcode project/shared scheme
- dedicated GitHub Actions simulator build gate

## Pass 2 — SWIFTDATA + HASHED MEDIA — GREEN / MERGED

PR #20 `Add Evidaro SwiftData persistence and hashed media intake` — MERGED.

Verified final gate:
- final PR head `cef51f701627661b58822656641b8ce1c9f2b3a0`
- workflow run `32329202541`
- build job `96306455813`
- persistence/media preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`

Implemented:
- SwiftData-backed case/evidence/seal models
- persistent ModelContainer / ModelContext
- private local media storage under Application Support
- PhotosPicker image intake
- Files/PDF intake
- original imported bytes copied into app-private storage
- separate SHA-256 over original media bytes
- evidence-record hash includes original-media hash
- original filename/hash displayed in timeline and manifest
- imported original can be shared back out

## Pass 3 — CAMERA + PROCESS-RELAUNCH PERSISTENCE — GREEN / MERGED

PR #22 `Add Evidaro camera capture and relaunch persistence gate` — MERGED.

Verified gate:
- final PR head `1e9ff37129fc386ec278f0b3d2f5e58fa391ccfb`
- workflow run `32330580003`
- build job `96310288293`
- camera/persistence preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- process-relaunch persistence smoke — SUCCESS
- merge commit `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- post-merge handoff PR #23 — MERGED
- handoff merge commit `0be5e5e08bdd045bbb0994c1da508d9a86ab6951`

Exact persisted integrity evidence across process restart:
- case ID: `11111111-1111-4111-8111-111111111111`
- media SHA-256: `5e647718ecb46672d74a0cfa0416a8af0d7bca687ed0349fd146e1191f197728`
- seal SHA-256: `f9799ea52f49197a71782d15f488545a5bd32cab7bd305e78e6aacc2b12450ff`

Physical iPhone camera hardware / permission-prompt UX remains a release spot-check.

## Pass 4 — LOCAL DERIVED OCR — GREEN / MERGED

PR #24 `Add local derived OCR with integrity gate` — MERGED.

Final checkpoint:
- final head `12d2f3b66f442648dd60c9dca842adb00c677f8e`
- workflow run `32335559431` — SUCCESS
- merge commit `ad3876dbac044759223d0bdf7a1c095e461bc16b`

Implemented:
- Apple Vision `VNRecognizeTextRequest` for stored images and PDFs
- derived SwiftData fields for recognized text, recognition time, engine and page count
- original-media SHA-256 re-validation before OCR
- evidence-record/hash integrity guard before OCR result commit
- OCR excluded from original-media SHA-256, evidence-record SHA-256 and snapshot seals
- local-only OCR; no cloud OCR/upload
- timeline Recognize / Refresh UX with explicit derived-data labeling
- real simulator Vision fixture containing `EVIDARO 4827`
- OCR process-relaunch persistence verification

Exact OCR integrity evidence:
- recognized text before/after restart: `EVIDARO 4827`
- media SHA-256: `d94f8834fd845ea011f36f753c9ddb91d7dd1dbb24ac2e5b04d7b508d9724355`
- evidence-record SHA-256: `dee235dd17e24fdb04b6a215d4077e03acaea41872c681da55edd996bebaea42`
- pre-OCR seal unchanged after OCR/restart: `86fc0200ebf3c861c686c693cc42437c7ab8716d98f7b42ff158140f71aa4ed8`

Physical-device OCR remains a release spot-check. OCR text is never treated as authoritative evidence.

## Pass 5 — INTEGRITY-CHECKED PDF EVIDENCE PACK — GREEN / MERGED

PR #27 `Add integrity-checked PDF evidence packs` — MERGED.

Final checkpoint:
- final head `501b136cb5453b0f9037038cd227dfbaad672884`
- workflow run `32338976678` — SUCCESS
- merge commit `22f8b560c2529fb064feaa591b901acecf8da573`

Implemented:
- local multi-page A4 PDF evidence pack
- case identity, timeline metadata, full media/evidence-record SHA-256 values and seal history
- current manifest status
- labeled image previews and every page of imported PDFs
- OCR included only as clearly labeled derived metadata
- original-media hash verification before and after rendering
- evidence-record verification before export
- seal consistency guard
- export discarded if case/hash/seal anchors change during generation
- one-tap Build & share PDF UX
- process-relaunch PDF gate that requires parsed case/hash/seal/OCR/legal text and identical PDF SHA-256 across restart

Pass-5 runtime evidence subsequently exercised in the Pass-6 combined gate:
- generated pages: `4`
- PDF SHA-256 before/after restart: `2f901b49ce4eb6a8aca2cd5d94e6c7c9319a4f314ab746597ca51dac2f0846b2`

## Pass 6 — OPTIONAL DEVICE-AUTH PRIVACY LOCK — GREEN / MERGED

PR #28 `Add optional device-auth privacy lock` — MERGED.

Merge checkpoint:
- final PR head `a55f55ebe72280e411670f4757624914d0c1d6ed`
- merge commit `f6e68210c38b1a1715de2908dd70e1da6c6a476d`

Implemented:
- optional app-level lock using `LocalAuthentication`
- device-owner authentication supports Face ID, Touch ID or device passcode according to device configuration
- lock disabled by default
- successful device-owner authentication required before enabling
- app relocks when moving to background
- evidence-case UI hidden behind a dedicated locked-content gate while enabled
- Settings UI for enable/disable and local-data explanation
- `NSFaceIDUsageDescription` wired for Debug and Release generated Info.plist
- privacy-lock state separate from evidence bytes, hashes, OCR, seals and PDF export
- deterministic DEBUG authenticator for automated lifecycle/persistence smoke only

Verified source gate included:
- source head `565c30561aa60084acc89f7811bb545e3a340265`
- workflow run `32349658489`
- build job `96365827349`
- preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- combined persistence + OCR + PDF + privacy-lock process-relaunch gate — SUCCESS

Exact privacy-lock smoke evidence:
- `lock-prepared enabled=true locked=true preference=true`
- `lock-verified persisted=true unlocked=true disabled=true`

The automated smoke does not claim physical Face ID/Touch ID hardware prompt validation.

## Pass 7 — DE/EN + ACCESSIBILITY + LOCALIZED PDF — GREEN / MERGED

PR #29 `Add Evidaro DE/EN localization and accessibility hardening` — MERGED.

First complete source gate before final PDF-localization review:
- source head `ae6a3b8fbdf25eca08ac040ce614664f5fd718de`
- workflow run `32362074699` — SUCCESS
- build job `96403585360` — SUCCESS
- preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- combined persistence + OCR + PDF + privacy-lock + German localization runtime gate — SUCCESS

Final verified Pass-7 gate:
- final PR head `84ef850678551e7cb0f22004c05e070adabece9d`
- workflow run `32383741929` / run #82 — **SUCCESS**
- build job `96473002571` — **SUCCESS**
- preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- persistence + OCR + English PDF + German PDF + privacy lock + German localization process-relaunch gate — SUCCESS
- merge commit `bf3ecf74887c08d52bbadf11a13174c83133b093`

Implemented in Pass 7:
- explicit English and German app resources
- localized camera and Face ID usage descriptions
- hash-stable persisted case/evidence enum raw values with separate localized display names
- localized Home, case creation, evidence intake, case detail, OCR controls, privacy-lock settings and device-auth prompts
- Dynamic Type adaptive home stats and case action layouts
- VoiceOver headings, combined case-card semantics and explicit full-hash accessibility labels/values
- full DE/EN PDF localization including metadata, cover, fields, OCR labels, original-media previews, seal history, continuation labels, page footer and export errors
- German runtime resource smoke
- English PDF and German PDF process-relaunch checks; the German PDF must retain an identical PDF SHA-256 across process restart

Pass-7 completion:
- exact final head `84ef850678551e7cb0f22004c05e070adabece9d` passed the full gate and PR #29 was merged to `main` as `bf3ecf74887c08d52bbadf11a13174c83133b093`

## Pass 8 — OFFLINE-VERIFIABLE `.evpack` — SOURCE IMPLEMENTED / GATE PENDING

Pass-8 PR / branch:
- PR #32 `Add offline-verifiable evidence bundles` — OPEN/DRAFT
- branch `agent/002-evidaro-offline-verifier`
- synchronized with merged Pass 7 / `main` through merge commit `5ec036f849de4dc7a63ef6d9acd82e7d493bc268`
- final exact-head full macOS gate pending

Implemented source checkpoint before this state update:
- `c09186d72b09ccad041e0c708c2534853e020250` — verification bundle data model, codec, exporter/verifier and deterministic negative/derived-OCR smoke
- `9aac38f2d7c6161490a6ac6fb63703a696dee9a1` — app smoke runner wiring
- `9443855b387eab6cdbb3ce420a3b22c55c312ec8` — case-detail verification-bundle export/share UX
- `3264ad94dceb9688b9306757cfcd8b6e03ec9dba` — home import/offline verifier result UX
- `f403cdbaf2d6b4036175d91ced213718cc4961a6` — centralized DE/EN verifier copy
- `bdceced6ced31cc105b46b6a7098fe8536d88056` — localized verifier-result UI wiring
- `431a2ca11bbc1375861fd2fce577b6a787480f84` — combined workflow extended with bundle process-relaunch gate
- `f0c723ee24374e10787ba30ae4d5a8f053fe3be7` — preflight requires offline-verifier trust boundaries
- `fab5d956b97c0a7c18c2d14d0e50b31bd7cd6e91` — product spec v0.2 differentiation / trust boundary

Pass-8 format/design:
- single JSON-based `.evpack` v1; no server, ZIP dependency or blockchain required
- format identifier `de.kamilunavo.evidaro.evpack`
- carries stable raw case/evidence values, canonical timestamps, factual metadata, original SHA-256 values, original byte streams as Base64, record hashes, seal history and derived OCR metadata
- exporter re-validates record hashes and original bytes before packaging
- generated bundle self-verifies before write
- verifier recomputes embedded original-media SHA-256 values
- verifier recomputes evidence-record SHA-256 values from stable raw fields
- verifier verifies historical seals against the ordered evidence prefix represented by each seal's item count
- verifier reports green/red, case identity, item/seal counts, current manifest SHA-256, bundle SHA-256 and concrete integrity issues
- received bundle verification is local and does not import evidence into canonical case data

Pass-8 deterministic CI intent already wired:
1. export a valid bundle from the existing OCR fixture
2. require the valid bundle to verify with one item/one historical seal
3. deliberately append `TAMPERED` to the factual note without updating integrity anchors and require verification to fail
4. change only derived OCR text and require verification to remain valid
5. terminate the app process
6. re-open and verify the persisted original `.evpack`
7. require identical bundle SHA-256 before/after process relaunch

Pass-8 is **not green yet**. The branch now includes merged Pass 7; the combined Xcode/simulator gate must pass on the final documentation-aligned Pass-8 head before PR #32 can merge.

## Open physical/release checks

1. physical iPhone camera capture + permission UX
2. physical-device OCR spot check
3. physical Face ID/Touch ID/device-passcode lock UX
4. DE/EN localization review on device
5. VoiceOver navigation review
6. largest Dynamic Type review
7. physical-device `.evpack` export/share/import verification
8. final public name — **release blocker; Evidaro is not locked**
9. App Store icon / identity after final name
10. final monetization / StoreKit Pro entitlement
11. signed TestFlight / App Store record

## Monetization direction

Portfolio plan remains Freemium + Pro. Do not force a subscription.

Current direction:
- genuinely useful free tier
- do not cripple evidence capture
- likely limits should focus on active case count and/or advanced exports
- verification of a received `.evpack` should remain free because verification strengthens trust in the exchange format
- prefer one-time Lifetime Pro while the product remains local-first
- only consider subscription if recurring hosted costs become a real product dependency

## Next gates

1. Keep Pass-7 exact head frozen; merge PR #29 only after workflow `32369937142` concludes SUCCESS.
2. After Pass 7 merges, open the Pass-8 verifier branch as its own PR to `main`.
3. Run full preflight + Xcode Simulator build + all prior persistence/OCR/PDF/privacy/localization checks + new `.evpack` valid/tamper/derived-OCR/process-relaunch gate on the exact Pass-8 documentation-aligned head.
4. Fix any red result; do not weaken checks to make CI green.
5. Only after Pass 8 is green/merged begin final-name migration, App Store identity/icon, StoreKit Lifetime Pro and signed TestFlight work.
