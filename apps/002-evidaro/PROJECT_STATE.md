# Evidaro — Project State

Last updated: 2026-08-20
Status: ACTIVE — PASS 6 PRIVACY LOCK SOURCE GATE GREEN / FINAL DOC-ALIGNED GATE REQUIRED
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
6. Do not merge a major pass until the exact final documentation-aligned head has completed the full relevant gate successfully.

## Naming

`ProofVault` is retired as a public-name candidate because current market research found an iPhone/iPad app named `ProofVault: Document Vault` with a substantially overlapping document-vault feature set.

Current working public-name candidate: **Evidaro**.

`Evidaro` remains provisional until final App Store, web, trademark and domain due diligence is complete. Current web/trademark search found no relevant software/app conflict, but that is not treated as legal clearance.

## Product thesis

> Capture facts while they are fresh. Seal evidence you can verify later.

Evidaro is a local-first evidence-case app for real-world situations where a user may later need a trustworthy timeline and a clean proof pack.

Primary examples:
- rental handovers and property damage
- damaged deliveries
- vehicle condition / accident documentation
- contractor or service disputes
- insurance incidents
- warranty/claim evidence that is not primarily a purchase tracker
- workplace or administrative event records

## Core loop

**Create case -> Capture evidence -> Hash each item -> Review timeline -> Seal snapshot -> Build/share evidence pack**

A seal never rewrites previous evidence. Future additions create a newer snapshot while older seal hashes remain visible.

## Trust boundary

- no legal-admissibility claim
- no claim that a timestamp proves when the real-world event occurred
- no hidden edits to sealed manifest history
- hashes are integrity aids, not legal certification
- v1 stays local-first; no evidence upload to Kamilunavo servers
- OCR is derived metadata only; stored original bytes/hash remain the source of truth
- generated PDF previews are derived renderings, not replacements for originals
- privacy lock protects app access but does not change evidence hashes, seals or source bytes

## Pass 1 — FOUNDATION — GREEN / MERGED

PR #15 `Build portfolio app #002 Evidaro foundation` is merged to `main`.

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

PR #20 `Add Evidaro SwiftData persistence and hashed media intake` is merged to `main`.

Verified final gate:
- final PR head `cef51f701627661b58822656641b8ce1c9f2b3a0`
- workflow run `32329202541`
- build job `96306455813`
- persistence/media preflight — SUCCESS
- Xcode iOS Simulator build — SUCCESS
- merge commit `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`

Implemented:
- SwiftData-backed EvidenceCase / EvidenceItem / EvidenceSeal models
- persistent ModelContainer / ModelContext
- local private media directory in Application Support
- PhotosPicker image intake
- Files/PDF intake
- imported original bytes copied into app-private storage
- SHA-256 over original imported media bytes
- evidence-record hash includes original-media hash
- original filename/hash visible in timeline
- original stored file can be shared back out

Historical red attempts were not merged; the SwiftUI type-check bottleneck was resolved before the final green head.

## Pass 3 — CAMERA + PROCESS-RELAUNCH PERSISTENCE — GREEN / MERGED

PR #22 `Add Evidaro camera capture and relaunch persistence gate` is merged to `main`.

Verified final documentation-aligned gate:
- final PR head `1e9ff37129fc386ec278f0b3d2f5e58fa391ccfb`
- workflow run `32330580003`
- build job `96310288293`
- camera/persistence preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- process-relaunch persistence smoke — SUCCESS
- merge commit `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`

Post-merge handoff:
- PR #23 `Record Evidaro pass 3 merged checkpoint` — MERGED
- workflow run `32331162562`
- build job `96311916968`
- merge commit `0be5e5e08bdd045bbb0994c1da508d9a86ab6951`

Exact persisted integrity evidence across process restart:
- case ID: `11111111-1111-4111-8111-111111111111`
- media SHA-256: `5e647718ecb46672d74a0cfa0416a8af0d7bca687ed0349fd146e1191f197728`
- seal SHA-256: `f9799ea52f49197a71782d15f488545a5bd32cab7bd305e78e6aacc2b12450ff`

Physical iPhone camera hardware / permission-prompt UX remains a release spot-check; simulator CI does not prove physical camera behavior.

## Pass 4 — LOCAL DERIVED OCR — GREEN / MERGED

PR #24 `Add local derived OCR with integrity gate` is merged to `main`.

Final PR checkpoint:
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
- timeline `Recognize` / `Refresh` UX with explicit derived-data labeling
- real simulator Vision fixture containing `EVIDARO 4827`
- OCR process-relaunch persistence verification

Exact OCR integrity evidence:
- recognized text before/after restart: `EVIDARO 4827`
- media SHA-256: `d94f8834fd845ea011f36f753c9ddb91d7dd1dbb24ac2e5b04d7b508d9724355`
- evidence-record SHA-256: `dee235dd17e24fdb04b6a215d4077e03acaea41872c681da55edd996bebaea42`
- pre-OCR seal unchanged after OCR/restart: `86fc0200ebf3c861c686c693cc42437c7ab8716d98f7b42ff158140f71aa4ed8`

Physical-device OCR remains a release spot-check. OCR text is never treated as authoritative evidence.

## Pass 5 — INTEGRITY-CHECKED PDF EVIDENCE PACK — GREEN / MERGED

PR #27 `Add integrity-checked PDF evidence packs` is merged to `main`.

Final PR checkpoint:
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
- one-tap `Build & share PDF` UX
- process-relaunch PDF gate that requires parsed case/hash/seal/OCR/legal text and identical PDF SHA-256 across restart

Pass-5 runtime evidence subsequently exercised in the Pass-6 combined gate:
- generated pages: `4`
- PDF SHA-256 before/after restart: `2f901b49ce4eb6a8aca2cd5d94e6c7c9319a4f314ab746597ca51dac2f0846b2`

## Pass 6 — OPTIONAL DEVICE-AUTH PRIVACY LOCK — SOURCE GATE GREEN / OPEN PR

PR #28 `Add optional device-auth privacy lock` is open on branch `agent/002-evidaro-app-lock`.

Implemented:
- optional app-level lock using `LocalAuthentication`
- device-owner authentication allows Face ID, Touch ID or device passcode according to device configuration
- lock disabled by default
- successful device-owner authentication required before enabling
- app relocks when moving to background
- evidence-case UI hidden behind a dedicated locked-content gate while enabled
- Settings UI for enable/disable and local-data explanation
- `NSFaceIDUsageDescription` wired for Debug and Release generated Info.plist
- privacy-lock state is separate from evidence bytes, hashes, OCR, seals and PDF export
- deterministic DEBUG authenticator for automated lifecycle/persistence smoke only

First verified full source gate:
- source head `565c30561aa60084acc89f7811bb545e3a340265`
- workflow run `32349658489`
- build job `96365827349`
- Xcode 26.6 / build 17F113
- preflight — SUCCESS
- generic Xcode iOS Simulator build — SUCCESS
- combined persistence + OCR + PDF + privacy-lock process-relaunch gate — SUCCESS

Exact privacy-lock smoke evidence:
- process 1: `lock-prepared enabled=true locked=true preference=true`
- process 2: `lock-verified persisted=true unlocked=true disabled=true`

The automated privacy-lock smoke proves app state/lifecycle/persistence behavior using a deterministic DEBUG authenticator. It does **not** claim real Face ID/Touch ID hardware prompt validation. Physical device-owner-auth prompt UX remains a release spot-check.

Because this documentation commit advances PR #28 beyond the first green source head, the exact final documentation-aligned head must complete the same full preflight + Xcode + persistence + OCR + PDF + privacy-lock gate before merge.

## Open physical/release checks

1. physical iPhone camera capture + permission UX
2. physical-device OCR spot check
3. physical Face ID/Touch ID/device-passcode lock UX
4. DE/EN localization review on device
5. VoiceOver / Dynamic Type / accessibility review
6. App Store icon / identity and final naming due diligence
7. final monetization / StoreKit Pro entitlement
8. signed TestFlight / App Store record

## Monetization direction

Portfolio plan remains Freemium + Pro. Do not force a subscription. Current likely direction is a genuinely useful free tier plus one-time Lifetime Pro while the product remains local-first, unless recurring hosted costs later justify a subscription.

## Next gate

1. Run the complete Evidaro workflow on the exact documentation-aligned PR #28 head.
2. Merge PR #28 only if preflight + compile + persistence + Vision OCR + PDF evidence pack + privacy-lock process-relaunch checks are all green on that exact head.
3. Record the final merge checkpoint.
4. Start Pass 7: DE/EN localization plus VoiceOver / Dynamic Type / accessibility hardening while preserving all prior integrity gates.
