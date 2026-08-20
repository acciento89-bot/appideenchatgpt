# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — PASS 3 CAMERA + PROCESS-RELAUNCH PERSISTENCE VALIDATION
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

## Pass 3 — current branch / validation required

Branch: `agent/002-evidaro-camera-persistence-smoke`

Implemented before CI validation:
- direct `Take photo` intake on camera-capable iPhones through the system camera controller
- captured photo bytes are stored through the same `EvidenceMediaDraft -> persistMedia -> SHA-256` path as imported media
- camera privacy usage description added to generated Info.plist settings for Debug and Release
- `EvidenceStore` ownership moved to the app root so the runtime test and UI exercise the same persistent container
- deterministic DEBUG-only persistence smoke fixture covering one case, one evidence item, stored media bytes, media SHA-256, evidence-record SHA-256 and one snapshot seal
- workflow now boots a real iPhone Simulator, installs the built app, launches `prepare`, terminates the process, launches `verify`, and requires the second process to recover and revalidate the persisted case/media/hashes/seal
- existing PhotosPicker and Files/PDF import behavior remains intact

Do **not** call Pass 3 green until all of these are SUCCESS on the same PR head:
1. Evidaro preflight
2. Xcode iOS Simulator build
3. process-relaunch persistence smoke across two app launches

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

1. Run the dedicated Evidaro workflow against Pass 3.
2. Fix any camera, SwiftData or simulator-relaunch failure before merge.
3. Merge only when preflight + compile + two-process persistence smoke are all green on the exact final PR head.
4. After merge, add on-device OCR while preserving the original media bytes/hash as the immutable source of truth.
