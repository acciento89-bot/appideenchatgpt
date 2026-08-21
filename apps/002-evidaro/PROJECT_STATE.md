# Kamilunavo Trace — Project State

Last updated: 2026-08-21
Status: TESTFLIGHT BUILD 4 UPLOADED — APPLE PROCESSING / PHYSICAL PDF QA PENDING
Portfolio slot: #002
Repository: `acciento89-bot/appideenchatgpt`
Implementation path: `apps/002-evidaro/`
Canonical branch: `main`

## Handoff rule

This file is the authoritative app-specific handoff for portfolio app #002.

For future work:
1. Read `docs/APP_FACTORY_STATE.md` first.
2. Read this file second.
3. Treat the Build 4 checkpoint below as newer than the historical Build 1 release notes.
4. Never call a queued workflow green and never bypass the integrity/relaunch gates.
5. After any major release change, keep this file synchronized with the portfolio state.

## Current checkpoint — Build 4 premium PDF — 2026-08-21

Kamilunavo Trace is currently at **0.1.0 (4)**.

Build 3 was physically visible in TestFlight and fixed the public PDF branding from the retired `Evidaro` name to `Kamilunavo Trace`, but physical review showed that the document still looked too close to the original raw protocol layout.

A second, materially larger PDF presentation pass was therefore completed and promoted as Build 4.

### Premium PDF redesign — GREEN / MERGED

PR #41: `Redesign Kamilunavo Trace PDF as premium report`

- final head `b05487e2948fe19f6209bc57aca12c07367f959f`
- merge `e7faea033c84f00fc709075b34e3fec50c620b74`
- static release run `32491133740` — SUCCESS
- unsigned iPhone Release/TestFlight validation run `32491133742` — SUCCESS
- full simulator + process-relaunch integrity run `32491133908` — SUCCESS

Presentation changes include:

- dark premium Kamilunavo Trace hero cover
- snapshot-status pill
- compact evidence/timestamp summary cards
- dedicated case-ID and manifest-hash cards
- structured evidence metadata/note/file cards
- dedicated original-media and record-hash cards
- OCR shown as a visually separated derived-data section
- framed image/PDF previews with hash captions
- card-based seal history with current/historical states
- cleaner header/footer chrome and typography hierarchy

The redesign intentionally did **not** change evidence bytes, original-media SHA-256, evidence-record hashing, snapshot seals, OCR provenance semantics, `.evpack`, export verification, StoreKit or the local-first trust boundary.

PR #37 was left untouched during this work.

### Build 4 promotion — GREEN / MERGED

PR #42: `Promote Kamilunavo Trace premium PDF as Build 4`

- exact promoted head `91ab064561807e2117c9ef5b7bac0aeafb3cde73`
- static release run `32492123502` — SUCCESS
- unsigned iPhone Release/TestFlight validation run `32492123518` — SUCCESS
- full simulator + persistence/OCR/PDF/`.evpack`/privacy-lock relaunch run `32492123524` — SUCCESS
- merge `6e50c537540f657fdcc69e670c5cd4643e9fc622`

### Signed TestFlight Build 4 upload — SUCCESS

A temporary protected bridge in `acciento89-bot/onemorefloor` was used because the App Store Connect signing secrets are intentionally not stored in `appideenchatgpt`.

- bridge PR #125 — CLOSED WITHOUT MERGE
- bridge source `2b911fba6498d79aeee0e535bec785695930f42c`
- exact Trace source checked out by the bridge: `6e50c537540f657fdcc69e670c5cd4643e9fc622`
- bridge run `32493407604` — SUCCESS
- upload job `96806116034` — SUCCESS
- App Store Connect app record verified
- Build 4 confirmed absent before upload
- archive/export/upload completed successfully
- `Kamilunavo Trace 0.1.0 (4)` was handed to App Store Connect/TestFlight successfully

The temporary bridge PR/file must remain unmerged; no bridge workflow belongs on One More Floor `main`.

### Next physical gate

Do not create Build 5 merely because Build 4 is processing.

When Build 4 becomes visible in TestFlight:

1. Install/open **0.1.0 (4)** on the physical iPhone.
2. Generate a **fresh** PDF; an older Build 2/3 PDF will not change retroactively.
3. Confirm the premium redesign is visibly present, not just the corrected branding.
4. Confirm cover/header/footer say `Kamilunavo Trace` and no visible retired `Evidaro` branding remains.
5. Confirm evidence details, hashes, OCR, previews and seal history are complete and readable.
6. If the physical PDF looks good, record Build 4 PDF QA as passed before any further release promotion.

Apple processing/TestFlight visibility of Build 4 is still an external confirmation gate until physically observed.

## Final public identity

Final public release name: **Kamilunavo Trace**.

- display name: `Kamilunavo Trace`
- bundle id: `de.kamilunavo.trace`
- category direction: Productivity
- iPhone / iOS 17+
- public PDF metadata/filename/cover/header/footer use Kamilunavo Trace

`ProofVault` is retired as a public-name candidate. `Evidaro` is also retired as the public release name. Historical internal paths, deterministic smoke fixtures such as `EVIDARO 4827`, and compatibility keys may retain old internal identifiers where changing them would add migration/integrity risk without user benefit.

No repository/web/App Store search is legal trademark clearance.

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

### Pass 1 — foundation — GREEN / MERGED
- PR #15
- merge `3dbeef6e786e9d2ad528d34b28f66c4ab3890856`

### Pass 2 — SwiftData + hashed media — GREEN / MERGED
- PR #20
- merge `8874d78af3a7d4139743e5b2e9017ecd709cbdd2`

### Pass 3 — camera + process relaunch — GREEN / MERGED
- PR #22
- merge `951c2f53ccbdda7ce01af0dac8f0a17c87fbe132`

### Pass 4 — local derived OCR — GREEN / MERGED
- PR #24
- merge `ad3876dbac044759223d0bdf7a1c095e461bc16b`
- deterministic OCR fixture `EVIDARO 4827` intentionally remains historical test data

### Pass 5 — integrity-checked PDF — GREEN / MERGED
- PR #27
- merge `22f8b560c2529fb064feaa591b901acecf8da573`

### Pass 6 — optional device-auth privacy lock — GREEN / MERGED
- PR #28
- merge `f6e68210c38b1a1715de2908dd70e1da6c6a476d`

## Pass 7 — DE/EN + accessibility + localized PDF — GREEN / MERGED

- PR #29
- merge `bf3ecf74887c08d52bbadf11a13174c83133b093`

## Pass 8 — offline-verifiable `.evpack` — GREEN / MERGED

- PR #32
- full simulator gate `32408185123` — SUCCESS
- merge `e5c57335888a80e120fefea686b29f6ed8715b2f`

## Release pass — Kamilunavo Trace

Release PR #33 is GREEN / MERGED.

- merge `69b8a1d99082ff804f2a532c636af3008d79546a`
- public name `Kamilunavo Trace`
- bundle `de.kamilunavo.trace`
- Lifetime Pro non-consumable `de.kamilunavo.trace.pro.lifetime`
- Free: up to 3 cases
- Pro: unlimited cases + PDF export + `.evpack` export
- received `.evpack` verification remains free
- production App Icon and privacy manifest are wired
- DE/EN metadata/runbooks are committed

Build 1 was the first signed TestFlight upload. Builds 2 and 3 were subsequent release/branding iterations. **Build 4 is now the current uploaded binary and supersedes the older Build 1 checkpoint for ongoing QA.**

## StoreKit / external Apple state

Repository implementation for Lifetime Pro remains in place:

- product id `de.kamilunavo.trace.pro.lifetime`
- non-consumable
- verified StoreKit 2 transactions only
- `Transaction.currentEntitlements` on launch/recreation
- transaction updates/unfinished recovery
- explicit Restore via `AppStore.sync()`

This PDF-focused Build 4 pass did not independently re-verify App Store Connect IAP pricing/agreement state. Check the current Apple-side state before claiming the IAP release gate complete.

## Physical iPhone QA

Checklist: `apps/002-evidaro/PHYSICAL_QA.md`

Relevant physical-device gates include:

- app icon/name
- camera permission + real capture
- image/PDF import
- Apple Vision OCR
- hash/seal stability through relaunch
- Face ID/Touch ID/passcode privacy lock
- DE/EN
- VoiceOver + largest Dynamic Type
- 3-case Free boundary
- real Lifetime purchase/relaunch/Restore
- premium Build 4 PDF export
- `.evpack` export/import verification and tamper rejection

## Current next action

**Wait for Build 4 TestFlight processing/visibility, install it, generate a fresh PDF and visually verify the premium report redesign on the physical iPhone.**
