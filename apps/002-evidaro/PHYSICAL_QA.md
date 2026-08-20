# Kamilunavo Trace — Physical iPhone Release QA

This is the single physical-device gate for the first release-candidate TestFlight build.

Do not mark this gate green from simulator/CI evidence. Every item below must be exercised on a real iPhone using the signed TestFlight build.

## Build identity

Record before testing:

- App Store name: **Kamilunavo Trace**
- Bundle ID: `de.kamilunavo.trace`
- Version: `0.1.0`
- TestFlight build: `<record after upload>`
- Device / iOS: `<record on test>`
- Lifetime Pro product: `de.kamilunavo.trace.pro.lifetime`

## 1 — Fresh install / brand / icon

- [ ] Fresh TestFlight install succeeds.
- [ ] Home-screen icon is the production Trace icon, not a blank/default asset.
- [ ] Home-screen/app display name is `Kamilunavo Trace`.
- [ ] App launches without migration/store crash.
- [ ] English and German public UI contain no user-facing `Evidaro`/`ProofVault` branding.

## 2 — Free core must remain useful

On a clean/free entitlement:

- [ ] Create case 1.
- [ ] Create case 2.
- [ ] Create case 3.
- [ ] Add factual notes normally.
- [ ] Add existing photo normally.
- [ ] Import a PDF/file normally.
- [ ] Share an original file normally.
- [ ] Seal snapshot normally.
- [ ] Share text manifest normally.
- [ ] Run OCR normally.
- [ ] Enable Privacy Lock normally.
- [ ] Received `.evpack` verification remains available without Pro.
- [ ] Attempting case 4 opens Trace Pro instead of silently failing.
- [ ] Attempting PDF export on Free opens Trace Pro.
- [ ] Attempting `.evpack` export on Free opens Trace Pro.

Free is a real product. Do not approve a build where capture, hashes, seals, OCR, Privacy Lock or received-bundle verification are accidentally paywalled.

## 3 — Camera / original bytes

- [ ] First camera action shows the localized camera permission prompt.
- [ ] Allowing permission opens the physical camera.
- [ ] Captured photo appears in the case timeline.
- [ ] Original filename/reference is reachable.
- [ ] Original SHA-256 is visible.
- [ ] Sharing the stored original returns an openable image.
- [ ] Relaunch app; photo and hash are still present.

## 4 — OCR on real hardware

Test one camera image with clear text and one imported PDF.

- [ ] Image OCR returns plausible text.
- [ ] PDF OCR returns plausible text/page count.
- [ ] OCR is visibly labelled as derived data.
- [ ] Refresh OCR works.
- [ ] Original SHA-256 does not change after OCR refresh.
- [ ] Evidence-record SHA-256 does not change after OCR refresh.
- [ ] Pre-existing snapshot seal does not change after OCR refresh.
- [ ] Force quit/relaunch preserves derived OCR result and all integrity anchors.

## 5 — Privacy Lock / real device authentication

- [ ] Enabling Privacy Lock requests real device-owner authentication.
- [ ] Face ID / Touch ID / device passcode behavior matches the device configuration.
- [ ] Background the app; returning requires unlock.
- [ ] Cancel authentication; evidence UI remains hidden.
- [ ] Authenticate successfully; evidence UI becomes visible.
- [ ] Force quit/relaunch; enabled lock preference survives.
- [ ] Disable lock after authentication; disabled state survives relaunch.

## 6 — DE / EN / accessibility

### German

- [ ] Set device/app language to German.
- [ ] Camera prompt is German.
- [ ] Face ID/privacy prompt is German.
- [ ] Home, case creation, evidence intake, OCR, Privacy Lock, Pro and verifier are German.
- [ ] Generated PDF uses German headings/fields/legal boundary.

### English

- [ ] Set device/app language to English.
- [ ] Same surfaces are English.
- [ ] Generated PDF uses English headings/fields/legal boundary.

### Accessibility

- [ ] VoiceOver can navigate Home without fragmented hash noise.
- [ ] Case cards announce useful combined summaries.
- [ ] Full hashes have explicit accessibility labels/values.
- [ ] Largest Dynamic Type does not hide New Case / Seal / Manifest / export controls.
- [ ] Pro sheet remains usable at largest Dynamic Type.

## 7 — Lifetime Pro purchase

Use the actual TestFlight/App Store sandbox path, not only Xcode local StoreKit.

- [ ] Trace Pro sheet loads the App Store price.
- [ ] Product shown is Lifetime / one-time, not a subscription.
- [ ] Buy Lifetime Pro succeeds.
- [ ] Pro status changes to active without app restart.
- [ ] Case 4 can now be created.
- [ ] PDF evidence-pack export is unlocked.
- [ ] `.evpack` export is unlocked.
- [ ] Force quit/relaunch; Pro remains active from verified entitlement recovery.
- [ ] Reboot/relaunch spot-check; Pro remains active.

## 8 — Restore purchase

On a state/device where restore is meaningful:

- [ ] `Restore purchases` is visible without requiring another purchase.
- [ ] Restore invokes Apple flow and recovers Lifetime Pro.
- [ ] Restore does not create a fake local entitlement when Apple returns no verified Lifetime transaction.

## 9 — PDF evidence pack after Pro

Use a case with at least one image/PDF, OCR and a seal.

- [ ] PDF generates.
- [ ] PDF opens in share preview/Files.
- [ ] Public branding says Kamilunavo Trace.
- [ ] Case ID is correct.
- [ ] Original-media SHA-256 is present.
- [ ] Evidence-record SHA-256 is present.
- [ ] OCR is clearly marked derived.
- [ ] Snapshot seal history is present.
- [ ] Original image/PDF preview pages are readable.
- [ ] Legal/integrity boundary is present.

## 10 — `.evpack` round trip / tamper signal

- [ ] Export `.evpack` from a Pro case.
- [ ] Save/share it outside the app.
- [ ] Re-import the untouched bundle using `Beweispaket prüfen` / `Verify evidence bundle`.
- [ ] Untouched bundle is green and shows expected case/item/seal counts.
- [ ] Bundle/manifest hashes are visible and selectable.
- [ ] Verify the same received bundle while the app is in Free state if practical; verification must remain available.
- [ ] CI tamper-negative gate remains required; physical QA does not need manual binary editing unless a convenient fixture is provided.

## 11 — Persistence / destructive checks

- [ ] Create evidence, seal, OCR, then force quit.
- [ ] Relaunch: case/evidence/original/OCR/seal remain.
- [ ] Background/foreground cycles do not lose data.
- [ ] No duplicate demo fixture appears after normal relaunch.
- [ ] No unexpected evidence upload/account requirement appears; v1 remains local-first.

## 12 — Release acceptance

The physical gate is GREEN only when:

- [ ] all critical items above pass;
- [ ] purchase + relaunch + restore are proven on the signed TestFlight path;
- [ ] real camera and real device authentication are proven;
- [ ] DE/EN PDF and verifier are visually sane;
- [ ] VoiceOver and largest Dynamic Type have no release-blocking issue;
- [ ] no user-facing old public brand remains;
- [ ] screenshots of the important checkpoints are saved for release evidence.

If any critical item fails, record the exact build, screen/action, expected behavior and actual behavior in `PROJECT_STATE.md` before fixing it. Do not call the release candidate green until a newer exact build closes that regression.
