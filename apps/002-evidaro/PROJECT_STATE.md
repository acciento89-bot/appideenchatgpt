# Kamilunavo Trace — Project State

Last updated: 2026-08-20
Status: ACTIVE — RELEASE SOURCE + PRIVACY MANIFEST READY; PASS 7/8 macOS GATES QUEUED; EXTERNAL APP STORE / PHYSICAL QA PENDING
Portfolio slot: #002
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/`
Release branch: `agent/002-kamilunavo-trace-release`

## Handoff rule

This file is the authoritative app-specific handoff for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Inspect current `main`, PR #29, PR #32, the Kamilunavo Trace release PR/branch, and their exact-head workflow conclusions.
4. Never call a queued workflow green and never merge a pass by bypassing a required integrity gate.
5. After any major release change, keep this file and `docs/APP_FACTORY_STATE.md` synchronized.

## Latest release checkpoint — 2026-08-20

- dependent release PR: #33 `Release Kamilunavo Trace with Lifetime Pro and TestFlight hardening`
- public identity: `Kamilunavo Trace`, bundle `de.kamilunavo.trace`
- Lifetime Pro: non-consumable `de.kamilunavo.trace.pro.lifetime`, local launch-price fixture `14.99`
- production App Icon: 1024×1024 RGB PNG, no alpha; enforced by release preflight
- App Store DE/EN metadata package + structured ASC JSON + release runbook are committed
- Kamilunavo website has `/trace`, `/trace/privacy` and Trace support coverage; website release-check PR #24 exercises TypeScript + production Next.js build
- `PrivacyInfo.xcprivacy` is bundled in the iOS target; tracking is disabled, tracking domains/data collection are empty, and app-owned `UserDefaults` use declares required-reason category `NSPrivacyAccessedAPICategoryUserDefaults` with Apple-approved reason `CA92.1`
- static release workflow run `32379763657` completed SUCCESS after App Icon, StoreKit, metadata and release-identity hardening; current PR head must still be inspected for the latest rerun after documentation-only updates
- Pass 7 PR #29 and Pass 8 PR #32 remain blocked only by their required macOS-26 exact-head runs; never bypass those gates
- App Store Connect app/IAP creation, signed TestFlight processing and physical iPhone QA remain external release steps

## Final public identity

Final release name selected for this product pass: **Kamilunavo Trace**.

Release identity:
- display name: `Kamilunavo Trace`
- bundle id: `de.kamilunavo.trace`
- category direction: Productivity
- iPhone / iOS 17+
- 1024×1024 production App Icon wired through `Assets.xcassets/AppIcon.appiconset`
- icon source committed as RGB PNG with no alpha channel

`ProofVault` is retired as a public-name candidate because an overlapping document-vault app already uses that name.

`Evidaro` is retired as the public release name because current public research found a thematically close housing-conditions / housing-disrepair Evidaro project. Historical internal paths, smoke flags, fixture strings and compatibility keys may retain `Evidaro` where renaming them would add migration/integrity risk without user benefit.

No web/App Store search in this repository is legal trademark clearance.

## Product thesis

> Capture facts while they are fresh. Preserve originals. Verify the chain later.

Kamilunavo Trace is a local-first evidence-case app for situations such as rental handovers, property defects, damaged deliveries, vehicle condition, contractor/service disputes, insurance incidents and other factual timelines.

Core chain:

**original bytes → original SHA-256 → evidence-record SHA-256 → snapshot seals → derived OCR → localized PDF + offline-verifiable `.evpack`**

## Trust boundary

- no legal-admissibility guarantee
- no notarization claim
- no claim that an app timestamp independently proves when a real-world event happened
- hashes/seals are integrity aids, not legal certification
- OCR is derived metadata and is excluded from original/evidence-record/seal identity
- PDF is a derived presentation and does not replace originals
- `.evpack` v1 verifies internal consistency of embedded originals, record hashes and recorded seals; it is not an external signature or independent timestamp authority
- v1 remains local-first; evidence is not uploaded to Kamilunavo servers
- received `.evpack` verification stays free and read-only

## Merged foundation checkpoints

### Pass 1 — foundation — GREEN / MERGED
- PR #15
- workflow `32312124275`
- merge `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`
- SwiftUI/iOS 17 foundation, cases, evidence timeline, item SHA-256, snapshot sealing, manifest, CI

### Pass 2 — SwiftData + hashed media — GREEN / MERGED
- PR #20
- final source head `cef51f701627661b58822656641b8ce1c9f2b3a0`
- workflow `32329202541`
- merge `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`
- SwiftData persistence, private media storage, Photos/Files/PDF intake, original SHA-256

### Pass 3 — camera + process relaunch — GREEN / MERGED
- PR #22
- final source head `1e9ff37129fc386ec278f0b3d2f5e58fa391ccfb`
- workflow `32330580003`
- merge `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`
- physical camera code path plus deterministic process-relaunch persistence gate
- persisted fixture media SHA-256 `5e647718ecb46672d74a0cfa0416a8af0d7bca687ed0349fd146e1191f197728`
- persisted fixture seal `f9799ea52f49197a71782d15f488545a5bd32cab7bd305e78e6aacc2b12450ff`

### Pass 4 — local derived OCR — GREEN / MERGED
- PR #24
- final source head `12d2f3b66f442648dd60c9dca842adb00c677f8e`
- workflow `32335559431`
- merge `ad3876dbac044759223d0bdf7a1c095e461bc16b`
- Apple Vision OCR for images/PDFs, local only, integrity guards, OCR excluded from evidence identity
- deterministic OCR fixture remains `EVIDARO 4827` intentionally as historical test data

### Pass 5 — integrity-checked PDF — GREEN / MERGED
- PR #27
- final source head `501b136cb5453b0f9037038cd227dfbaad672884`
- workflow `32338976678`
- merge `22f8b560c2529fb064feaa591b901acecf8da573`
- multi-page evidence PDF, original/evidence/seal revalidation, previews, OCR labeling, process-relaunch PDF SHA gate

### Pass 6 — optional device-auth privacy lock — GREEN / MERGED
- PR #28
- final PR head `a55f55ebe72280e411670f4757624914d0c1d6ed`
- merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`
- LocalAuthentication privacy lock, background relock, explicit enable authentication, deterministic lifecycle smoke

## Pass 7 — DE/EN + accessibility + localized PDF

PR #29: `Add Evidaro DE/EN localization and accessibility hardening`
Branch: `agent/002-evidaro-localization-accessibility`
Exact final head: `79c132f31ca2ce13046e5941f872087dfc7dad07`

Known green source checkpoint before the final documentation-aligned head:
- source head `ae6a3b8fbdf25eca08ac040ce614664f5fd718de`
- workflow `32362074699` — SUCCESS

Required exact-head gate:
- workflow `32369937142` / run #43
- job `96427918180`
- observed 2026-08-20: **QUEUED**, conclusion `null`

Do not merge PR #29 until that exact head completes the full preflight + simulator + persistence + OCR + English PDF + German PDF + privacy-lock + German localization gate successfully.

## Pass 8 — offline-verifiable `.evpack`

PR #32: `Add offline-verifiable evidence bundles`
Branch: `agent/002-evidaro-offline-verifier`
Current documented head before release branch: `d6b7a1f376b3cf8a73b6beae1fe8509b81b00be2`
Depends on PR #29.

Implemented:
- deterministic JSON `.evpack` v1
- original bytes embedded as Base64
- original-media SHA-256 verification
- evidence-record hash recomputation
- historical seal verification against evidence prefixes
- green/red local verifier with detailed issues
- read-only received-bundle verification
- deliberate factual-note tamper negative test
- derived-OCR-only mutation remains valid
- whole-bundle SHA-256 must remain identical after process relaunch

Required exact-head gate currently represented by workflow run `32373459509` / run #47, observed **QUEUED**, conclusion `null`.

Do not merge PR #32 before PR #29 is merged and Pass 8 has its own exact-head full gate green.

## Release pass — Kamilunavo Trace

Release branch is a clean descendant of Pass 8 and contains the release-only work below.

### Branding / identity — IMPLEMENTED
- public name `Kamilunavo Trace`
- bundle id `de.kamilunavo.trace`
- visible navigation/privacy/PDF/permission copy migrated to Kamilunavo Trace
- historical deterministic `EVIDARO 4827` OCR fixture intentionally preserved
- 1024×1024 no-alpha production icon committed and wired as `AppIcon`

### Lifetime Pro / StoreKit 2 — IMPLEMENTED
Product id: `de.kamilunavo.trace.pro.lifetime`
Local StoreKit launch price fixture: `14.99`
Type: non-consumable
DE/EN StoreKit localization included.

Entitlement rules:
- only verified StoreKit 2 transactions unlock Pro
- `Transaction.currentEntitlements` is the source of truth on launch/recreation
- `Transaction.updates` handles live transactions
- `Transaction.unfinished` recovers interrupted purchase finishing
- `AppStore.sync()` is used only from explicit Restore
- revoked/refunded entitlement does not remain Pro

Free tier:
- up to 3 active cases
- evidence capture, originals, SHA-256, snapshot seals, OCR, privacy lock and text manifest remain usable
- received `.evpack` verification remains free

Lifetime Pro:
- unlimited active cases
- PDF evidence-pack export
- `.evpack` export

### Release UI — IMPLEMENTED
- one consistent Lifetime Pro sheet
- purchase + restore actions
- Free/Pro status in Settings
- case-limit upsell at the fourth active case
- PDF and `.evpack` export gates route to the same paywall
- verifier itself is not paywalled

### TestFlight pipeline — IMPLEMENTED
Workflow: `.github/workflows/kamilunavo-trace-testflight.yml`

It validates an unsigned Release iPhone build on PRs and, after promotion to `main`, is prepared to use repository App Store Connect credentials:
- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

Release upload path uses App Store Connect export, Apple cloud distribution signing and hard-fails when an attempted upload fails. PR validation never uploads to TestFlight.

### Fast release preflight — IMPLEMENTED
Workflow: `.github/workflows/kamilunavo-trace-static-release.yml`
Script: `apps/002-evidaro/ci/release_preflight.py`
Runner: `ubuntu-latest`

This gate exists specifically so release identity can be checked while macOS-26 runners are queued. It validates:
- bundle id / display name
- AppIcon project wiring
- icon manifest and actual PNG dimensions
- icon has no alpha channel
- StoreKit product id/type/14.99 local fixture/DE+EN localizations
- Pro source/project wiring
- TestFlight workflow boundaries
- ASC and physical-QA handoffs

### App Store Connect handoff — PREPARED
Runbooks/metadata:
- `apps/002-evidaro/APP_STORE_CONNECT_RELEASE.md`
- `apps/002-evidaro/APP_STORE_METADATA.md`
- `apps/002-evidaro/metadata/AppStoreConnectSetup.json`

Still requires work in Apple's systems because this repository cannot create/confirm the App Store record or IAP record by itself:
- create/confirm app record for bundle id `de.kamilunavo.trace`
- create non-consumable `de.kamilunavo.trace.pro.lifetime`
- set final territory price around the planned €14.99 launch point
- complete tax/banking/agreements if Apple requires them
- attach IAP to the first submitted version as required

### Physical iPhone QA — PREPARED, NOT YET PERFORMED
Checklist: `apps/002-evidaro/PHYSICAL_QA.md`

One consolidated physical-device pass covers:
- app icon/name
- camera permission + real capture
- image/PDF import
- Apple Vision OCR on device
- hash/seal stability through relaunch
- Face ID/Touch ID/passcode privacy lock
- DE/EN
- VoiceOver + largest Dynamic Type
- 3-case Free boundary
- real Lifetime purchase
- Pro recovery after relaunch
- Restore
- PDF export
- `.evpack` export/import verification and tamper rejection

## What can still be completed automatically

1. Keep the Kamilunavo Trace release PR and fast static release gate green.
2. Keep Pass 7/8 exact-head macOS jobs under observation; merge only after SUCCESS.
3. Once Pass 7 then Pass 8 are green/merged, retarget/rebase the release PR cleanly onto `main`, rerun static + full macOS + unsigned Release-device gates, and merge only when all required exact-head checks are green.
4. After release code is on `main`, the TestFlight workflow can upload only if the App Store record/bundle id and repository ASC secrets are valid.

## External / user-device blockers

The following cannot honestly be marked complete from repository automation alone:
- App Store Connect app-record creation/verification
- App Store Connect Lifetime Pro IAP creation/price readiness
- Apple's signed/TestFlight processing if the Apple record is absent
- physical iPhone camera/OCR/biometric/accessibility QA
- real sandbox/TestFlight purchase + restore/relaunch verification

These are release gates, not optional polish.
