# Kamilunavo Trace — Project State

Last updated: 2026-08-21
Status: TESTFLIGHT BUILD 1 UPLOADED — APPLE PROCESSING / LIFETIME PRO IAP + PHYSICAL QA PENDING
Portfolio slot: #002
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/`
Canonical branch: `main`

## Handoff rule

This file is the authoritative app-specific handoff for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Inspect current `main`, PR #29, PR #32, the Kamilunavo Trace release PR/branch, and their exact-head workflow conclusions.
4. Never call a queued workflow green and never merge a pass by bypassing a required integrity gate.
5. After any major release change, keep this file and `docs/APP_FACTORY_STATE.md` synchronized.

## Latest release checkpoint — 2026-08-21

- release PR #33 `Release Kamilunavo Trace with Lifetime Pro and TestFlight hardening` — GREEN / MERGED
- final tested release head `090b1471…`; static release run `32412043585`, unsigned iPhone Release/TestFlight validation run `32412043598`, and full simulator run `32412043953` — SUCCESS
- release merge on `main`: `69b8a1d99082ff804f2a532c636af3008d79546a`
- App Store Connect app record for `de.kamilunavo.trace` — EXISTS
- signed TestFlight Build 1 `0.1.0 (1)` upload — SUCCESS via protected One More Floor bridge
- bridge run `32445560808`; upload job `96665754912`; exact Apple result includes `Progress 100%: Upload succeeded.` and `** EXPORT SUCCEEDED **`
- Apple package processing / TestFlight visibility — PENDING external confirmation
- public identity: `Kamilunavo Trace`, bundle `de.kamilunavo.trace`
- Lifetime Pro: non-consumable `de.kamilunavo.trace.pro.lifetime`, local launch-price fixture `14.99`
- production App Icon: 1024×1024 RGB PNG, no alpha; enforced by release preflight
- App Store DE/EN metadata package + structured ASC JSON + release runbook are committed
- Kamilunavo website has `/trace`, `/trace/privacy` and Trace support coverage; website release-check PR #24 exercises TypeScript + production Next.js build
- `PrivacyInfo.xcprivacy` is bundled in the iOS target; tracking is disabled, tracking domains/data collection are empty, and app-owned `UserDefaults` use declares required-reason category `NSPrivacyAccessedAPICategoryUserDefaults` with Apple-approved reason `CA92.1`
- Pass 7 PR #29, Pass 8 PR #32 and Release PR #33 are all GREEN / MERGED
- App Store Connect app record exists and signed Build 1 has been uploaded successfully
- Lifetime Pro IAP creation/price readiness, Apple processing visibility and physical iPhone QA remain external release steps

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

## Pass 7 — DE/EN + accessibility + localized PDF — GREEN / MERGED

- PR #29 — MERGED
- final head `84ef850678551e7cb0f22004c05e070adabece9d`
- workflow `32383741929` / run #82 — SUCCESS
- merge `bf3ecf74887c08d52bbadf11a13174c83133b093`

## Pass 8 — offline-verifiable `.evpack` — GREEN / MERGED

- PR #32 — MERGED
- final exact head `d3af5d59abea850dd7724beb92e223a691172ba3`
- full simulator gate `32408185123` / run #98 — SUCCESS
- merge `e5c57335888a80e120fefea686b29f6ed8715b2f`
- valid/tamper/derived-OCR/process-relaunch checks all green

## Release pass — Kamilunavo Trace

Release PR #33 is GREEN / MERGED. Final release code is on `main` at merge `69b8a1d99082ff804f2a532c636af3008d79546a`. Its static, full simulator and unsigned iPhone Release gates all passed before merge.

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
- up to 3 cases
- evidence capture, originals, SHA-256, snapshot seals, OCR, privacy lock and text manifest remain usable
- received `.evpack` verification remains free

Lifetime Pro:
- unlimited cases
- PDF evidence-pack export
- `.evpack` export

### Release UI — IMPLEMENTED
- one consistent Lifetime Pro sheet
- purchase + restore actions
- Free/Pro status in Settings
- case-limit upsell at the fourth case
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

### App Store Connect / TestFlight — BUILD 1 UPLOADED
Runbooks/metadata:
- `apps/002-evidaro/APP_STORE_CONNECT_RELEASE.md`
- `apps/002-evidaro/APP_STORE_METADATA.md`
- `apps/002-evidaro/metadata/AppStoreConnectSetup.json`

Current Apple checkpoint:
- app record for bundle id `de.kamilunavo.trace` exists
- signed Build 1 `0.1.0 (1)` upload succeeded and Apple accepted the package for processing
- TestFlight visibility/processing is not yet externally confirmed

Still requires work in Apple's systems:
- create/configure non-consumable `de.kamilunavo.trace.pro.lifetime` if it does not yet exist
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

## Repository / automation checkpoint

Repository release work for Build 1 is complete: Pass 7, Pass 8 and Release PR #33 are merged, all required release gates are green, and the signed Build 1 upload succeeded through the protected bridge. Do not create another Build 1 upload unless Apple reports a processing/rejection problem that requires a new binary.

## External / user-device blockers

The following cannot honestly be marked complete from repository automation alone:
- App Store Connect Lifetime Pro IAP creation/price readiness
- Apple TestFlight processing/visibility after the successful signed upload
- physical iPhone camera/OCR/biometric/accessibility QA
- real sandbox/TestFlight purchase + restore/relaunch verification

These are release gates, not optional polish.
