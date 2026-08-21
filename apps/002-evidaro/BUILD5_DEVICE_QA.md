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

## Next physical gate — Privacy Lock / device authentication

- [ ] Enabling Privacy Lock requests real device-owner authentication.
- [ ] Face ID / Touch ID / device passcode behavior matches the device configuration.
- [ ] Background the app; returning requires unlock.
- [ ] Cancel authentication; evidence UI remains hidden.
- [ ] Authenticate successfully; evidence UI becomes visible.
- [ ] Force quit/relaunch; enabled lock preference survives.
- [ ] Disable lock after authentication; disabled state survives relaunch.

## Other release gates

DE/EN, accessibility, `.evpack` round-trip and any remaining physical checks stay open unless separately recorded. The signed TestFlight Lifetime Pro purchase → entitlement recovery after relaunch → Restore path was already physically confirmed on the earlier Build 2 checkpoint; Build 5 PDF work did not alter StoreKit logic.

PR #37 is intentionally left untouched; this file is the newer Build 5 device-QA checkpoint.
