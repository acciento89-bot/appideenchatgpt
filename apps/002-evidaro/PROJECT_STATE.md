# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — PASS 3 GREEN / MERGED
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
5. Do not call a workflow green if a relevant job failed.

## Naming

`ProofVault` is retired as a public-name candidate because current market research found an iPhone/iPad app named `ProofVault: Document Vault` with a substantially overlapping document-vault feature set.

Current working public-name candidate: **Evidaro**.

`Evidaro` remains provisional until final App Store, web, trademark and domain due diligence is complete. Current web/trademark search found no relevant software/app conflict, but that is not treated as legal clearance.

## Product thesis

> Capture facts while they are fresh. Seal evidence you can verify later.

Evidaro is not another receipt/document filing cabinet. It is a local-first evidence-case app for real-world situations where a user may later need a trustworthy timeline and a clean proof pack.

Primary examples:
- rental handovers and property damage
- damaged deliveries
- vehicle condition / accident documentation
- contractor or service disputes
- insurance incidents
- warranty/claim evidence that is not primarily a purchase tracker
- workplace or administrative event records

## Core loop

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Share/export manifest**

A seal never rewrites previous evidence. Future additions create a newer snapshot while older seal hashes remain visible.

## Trust boundary

- no legal-admissibility claim
- no claim that a timestamp proves when the real-world event occurred
- no hidden edits to sealed manifest history
- hashes are integrity aids, not legal certification
- v1 stays local-first; no evidence upload to Kamilunavo servers

## Foundation pass 1 — GREEN / MERGED

PR #15 `Build portfolio app #002 Evidaro foundation` is merged to `main`.

Verified gate:
- workflow run `32312124275`
- build job `96257080572`
- foundation preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`

Foundation includes:
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

## Pass 2 — GREEN / MERGED

PR #20 `Add Evidaro SwiftData persistence and hashed media intake` is merged to `main`.

Implemented:
- SwiftData-backed EvidenceCase / EvidenceItem / EvidenceSeal models
- persistent ModelContainer / ModelContext instead of in-memory-only state
- local private media directory in Application Support
- PhotosPicker intake for existing images
- Files/PDF intake through fileImporter
- imported original bytes copied into app-private storage
- SHA-256 hash of original imported media bytes
- evidence record hash includes the original-media hash
- timeline surfaces original filename + original-media hash
- original imported file can be shared back out
- app-specific preflight expanded to gate persistence/media integrity
- `AddEvidenceView` split into smaller SwiftUI components to avoid Xcode 26.6 type-checker timeouts

Verified final gate:
- final PR head `cef51f701627661b58822656641b8ce1c9f2b3a0`
- workflow run `32329202541`
- build job `96306455813`
- persistence/media preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`

Earlier red attempts were not merged:
- run `32328781825` exposed a SwiftUI type-check timeout in `AddEvidenceView`
- run `32328949495` confirmed the same bottleneck after a smaller expression-only change
- the view was structurally decomposed; run `32329075367` passed, then the documentation-aligned final head also passed in run `32329202541`

## Pass 3 — GREEN / MERGED

PR #22 `Add Evidaro camera capture and relaunch persistence gate` is merged to `main`.

Implemented:
- direct `Take photo` intake on camera-capable iPhones through the system camera controller
- captured photo bytes use the same `EvidenceMediaDraft -> persistMedia -> SHA-256` path as imported media
- camera privacy usage description is present in generated Info.plist settings for Debug and Release
- `EvidenceStore` ownership moved to the app root so runtime validation and UI use the same persistent container
- deterministic DEBUG-only persistence fixture covers one case, one evidence item, stored media bytes, media SHA-256, evidence-record SHA-256 and one snapshot seal
- workflow boots an iPhone Simulator, installs the app, launches `prepare`, terminates that app process, launches `verify`, then requires the second process to recover and revalidate persisted case/media/hashes/seal
- existing PhotosPicker and Files/PDF import behavior remains intact

Verified source gate:
- source head `feb9fb7a58f1a254f5661164e3a2dabfebc9a0bb`
- workflow run `32330201515`
- build job `96309243631`
- Xcode 26.6 / build 17F113
- camera/persistence preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- targeted iPhone 17 Pro Simulator build — SUCCESS
- process 1 prepare — SUCCESS
- process termination — SUCCESS
- process 2 verify — SUCCESS

Verified final documentation-aligned gate:
- final PR head `1e9ff37129fc386ec278f0b3d2f5e58fa391ccfb`
- workflow run `32330580003`
- build job `96310288293`
- camera/persistence preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- process-relaunch persistence smoke — SUCCESS
- merge commit `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`

Exact persisted integrity evidence across process restart:
- case ID before/after: `11111111-1111-4111-8111-111111111111`
- media SHA-256 before/after: `5e647718ecb46672d74a0cfa0416a8af0d7bca687ed0349fd146e1191f197728`
- seal SHA-256 before/after: `f9799ea52f49197a71782d15f488545a5bd32cab7bd305e78e6aacc2b12450ff`

Boundary:
- the automated gate proves compile-time camera integration and simulator process-relaunch persistence for case + evidence + stored media bytes + hashes + seal
- it does **not** prove physical iPhone camera hardware, permission prompt UX or a real captured photo yet; that remains a device spot-check before release hardening

## Intentionally deferred after Pass 3

1. physical-device camera validation and camera-permission UX spot check
2. on-device OCR
3. optional location/context metadata
4. PDF evidence-pack export
5. Face ID/privacy lock
6. DE/EN localization
7. accessibility / Dynamic Type hardening
8. App Store icon/identity
9. StoreKit Pro entitlement and final monetization
10. signed TestFlight / App Store record

## Monetization direction

Portfolio plan remains Freemium + Pro. Do not force a subscription. Current likely direction is a useful free tier plus one-time Pro unless later economics clearly require recurring cloud costs.

## Next gate

1. Add on-device OCR as derived metadata only; never replace or rewrite the stored original media bytes/hash.
2. Preserve user-reviewable OCR output/provenance so extracted text cannot silently become the source of truth.
3. Keep physical-device camera capture/permission validation open until a signed device build is available.
4. After OCR/media stability, build the PDF evidence-pack export.
