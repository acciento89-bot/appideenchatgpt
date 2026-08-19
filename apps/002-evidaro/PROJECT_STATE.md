# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — FOUNDATION PASS 1
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

## Foundation pass 1

Target:
- native SwiftUI
- iOS 17+
- iPhone first
- local-first architecture
- provisional bundle id `de.kamilunavo.evidaro.prototype`
- version `0.1.0 (1)` for internal prototype only

Implemented in this pass:
- case dashboard
- case creation
- evidence timeline
- note/source evidence capture
- SHA-256 content hash per evidence item
- repeatable snapshot sealing
- shareable text manifest
- sample data for immediate UI/runtime inspection
- dedicated Xcode project + shared scheme
- dedicated GitHub Actions simulator build gate
- static preflight for identity/core integrity rules

## Intentionally deferred

1. SwiftData persistence/relaunch gate
2. camera/photo intake
3. Files/PDF intake
4. on-device OCR
5. immutable media-file hashing on disk
6. optional location/context metadata
7. PDF evidence-pack export
8. Face ID/privacy lock
9. DE/EN localization
10. accessibility / Dynamic Type hardening
11. App Store icon/identity
12. StoreKit Pro entitlement and final monetization
13. signed TestFlight / App Store record

## Monetization direction

Portfolio plan remains Freemium + Pro. Do not force a subscription. Current likely direction is a useful free tier plus one-time Pro unless later economics clearly require recurring cloud costs.

## Next gate

Foundation CI must be green before merge. After merge, next product pass is persistence + real media intake while preserving the evidence hash/seal semantics.