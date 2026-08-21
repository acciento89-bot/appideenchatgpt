# Kamilunavo Trace — Build 5 physical device QA

Date: 2026-08-21
Build: `0.1.0 (5)`
Source: `128da643cb8b5320546242ba511118d18a2edb07`
Status: IN PROGRESS

This file records only physical iPhone observations for Build 5. It does not replace `PHYSICAL_QA.md`; unchecked areas remain open until explicitly exercised on the signed TestFlight build.

## Accepted Build 5 PDF

- [x] Fresh Build 5 PDF generated on the physical device.
- [x] Reader-focused three-page layout accepted by the user.
- [x] Standalone Integritätsmodell removed from the reader-facing report.
- [x] Standalone snapshot/seal page removed.
- [x] Original evidence is presented before derived OCR.
- [x] Technical hashes/seal data are reduced to compact Prüfdetails.
- [x] Public PDF branding is Kamilunavo Trace.

## Camera / original evidence checkpoint

User-confirmed on the physical iPhone:

- [x] Direct camera capture works in Build 5.
- [x] Captured photo appears in the case/evidence timeline.
- [x] Original SHA-256 is visible for the captured photo.
- [x] Force-quit/relaunch preserves the captured photo.
- [x] Force-quit/relaunch preserves the same original SHA-256.

Still open from the full camera checklist:

- [ ] Explicitly record first-install localized camera permission prompt if it is encountered on a reset permission state.
- [ ] Confirm original filename/reference is reachable.
- [ ] Share the stored original and confirm the exported image opens normally.

## OCR / derived-data integrity checkpoint

User-confirmed on the physical iPhone:

- [x] Image OCR returns plausible text.
- [x] PDF OCR returns plausible text and page count.
- [x] OCR is visibly identified as derived/recognized text rather than original evidence.
- [x] Refresh OCR works.
- [x] Original SHA-256 remains unchanged after OCR refresh.
- [x] Evidence-record SHA-256 remains unchanged after OCR refresh.
- [x] Existing snapshot seal remains unchanged after OCR refresh.
- [x] Force-quit/relaunch preserves OCR and all integrity anchors.

## Privacy Lock / device authentication checkpoint

User-confirmed on the physical iPhone:

- [x] Enabling Privacy Lock requests real device-owner authentication.
- [x] Face ID behavior matches the device configuration.
- [x] Backgrounding the app and returning requires unlock.
- [x] Cancelling authentication keeps the evidence UI hidden.
- [x] Successful authentication reveals the evidence UI.
- [x] Force-quit/relaunch preserves the enabled lock preference.
- [x] Disabling Privacy Lock after authentication survives relaunch.

## Next physical gate — DE / EN / accessibility

### German

- [ ] Home, case creation, evidence intake, OCR, Privacy Lock, Pro and verifier are German.
- [ ] Generated PDF uses German headings/fields.

### English

- [ ] Home, case creation, evidence intake, OCR, Privacy Lock, Pro and verifier are English.
- [ ] Generated PDF uses English headings/fields.

### Accessibility

- [ ] VoiceOver can navigate Home without fragmented hash noise.
- [ ] Case cards announce useful combined summaries.
- [ ] Full hashes have explicit accessibility labels/values.
- [ ] Largest Dynamic Type does not hide New Case / Seal / Manifest / export controls.
- [ ] Pro sheet remains usable at largest Dynamic Type.

## Other release gates

`.evpack` round-trip and any remaining physical checks stay open unless separately recorded. The signed TestFlight Lifetime Pro purchase → entitlement recovery after relaunch → Restore path was already physically confirmed on the earlier Build 2 checkpoint; Build 5 PDF work did not alter StoreKit logic.

PR #37 is intentionally left untouched; this file is the newer Build 5 device-QA checkpoint.
