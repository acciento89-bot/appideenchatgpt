# Kamilunavo Trace — Build 5 physical device QA

Date: 2026-08-21
Build: `0.1.0 (5)`
Source: `128da643cb8b5320546242ba511118d18a2edb07`
Status: GREEN — PHYSICAL RELEASE QA PASSED

This file records physical iPhone observations for signed TestFlight Build 5. The major release-critical device paths below were exercised successfully on the real device.

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
- [x] Original filename/reference is reachable from stored evidence.
- [x] Sharing/exporting the stored original returns an image that opens normally.

Situational permission note:

- [ ] The localized first-camera permission prompt was not re-forced from a reset permission state during this Build 5 pass. This remains a situational spot-check rather than a release blocker because the real camera path itself was physically proven.

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

## DE / EN / accessibility checkpoint

User-confirmed on the physical iPhone:

### German

- [x] Home, case creation, evidence intake, OCR, Privacy Lock, Pro and verifier are German.
- [x] Generated PDF uses German headings/fields.

### English

- [x] Home, case creation, evidence intake, OCR, Privacy Lock, Pro and verifier are English.
- [x] Generated PDF uses English headings/fields.

### Accessibility

- [x] VoiceOver can navigate Home without fragmented hash noise.
- [x] Case cards announce useful combined summaries.
- [x] Full hashes have explicit accessibility labels/values.
- [x] Largest Dynamic Type does not hide New Case / Seal / Manifest / export controls.
- [x] Pro sheet remains usable at largest Dynamic Type.

## `.evpack` round-trip checkpoint

User-confirmed on the physical iPhone:

- [x] `.evpack` exports from a Pro case.
- [x] The exported package can be saved/shared outside the app.
- [x] The untouched package can be re-imported using `Beweispaket prüfen` / `Verify evidence bundle`.
- [x] Untouched bundle verifies green and reports plausible case/item/seal counts.
- [x] Bundle/manifest hashes are visible in the verifier.

Optional/free-state spot-check:

- [ ] Re-verifying the same received bundle while Pro is inactive/free remains optional. Product policy and automated gates continue to require received-bundle verification to remain free.

## StoreKit checkpoint carried forward

The signed TestFlight Lifetime Pro purchase → entitlement recovery after relaunch → Restore path was physically confirmed on the earlier Build 2 checkpoint. Build 5's PDF redesign did not alter StoreKit implementation or entitlement logic, so that signed-device checkpoint remains the current StoreKit evidence unless StoreKit code changes again.

## Build 5 physical acceptance

Build 5 is accepted as the physical release candidate for the exercised app paths:

- [x] reader-facing PDF presentation
- [x] real camera capture and original-byte persistence
- [x] original filename/reference and share/export path
- [x] image/PDF OCR with integrity-anchor stability
- [x] Face ID / Privacy Lock behavior and persistence
- [x] DE/EN localization
- [x] VoiceOver and largest Dynamic Type
- [x] `.evpack` export/import verification
- [x] signed TestFlight Lifetime Pro purchase/relaunch/Restore evidence remains valid because StoreKit code was unchanged

Any future code change touching these areas must reopen the corresponding gate.

PR #37 is intentionally left untouched; this file is the final Build 5 device-QA checkpoint.
