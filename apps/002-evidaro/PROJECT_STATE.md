# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — PASS 2 PERSISTENCE + MEDIA INTAKE
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

## Pass 2 — current branch

Branch: `agent/002-evidaro-persistence-media`

Implemented before CI validation:
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

Do **not** call Pass 2 green until its PR CI has completed successfully.

## Intentionally deferred after Pass 2

1. physical/runtime relaunch verification of SwiftData persistence
2. direct camera capture
3. on-device OCR
4. optional location/context metadata
5. PDF evidence-pack export
6. Face ID/privacy lock
7. DE/EN localization
8. accessibility / Dynamic Type hardening
9. App Store icon/identity
10. StoreKit Pro entitlement and final monetization
11. signed TestFlight / App Store record

## Monetization direction

Portfolio plan remains Freemium + Pro. Do not force a subscription. Current likely direction is a useful free tier plus one-time Pro unless later economics clearly require recurring cloud costs.

## Next gate

1. Compile Pass 2 on `macos-26` through the dedicated Evidaro workflow.
2. Fix all SwiftData/PhotosUI/fileImporter compiler issues before merge.
3. After green merge, add direct camera capture and a runtime persistence/relaunch smoke before OCR.