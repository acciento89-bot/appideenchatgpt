# Kamilunavo Trace — App Store Connect / TestFlight Release Setup

This file defines the external Apple records required for the release branch. Repository code/config is not evidence that an App Store Connect record already exists.

## Release identity

- Public app name: **Kamilunavo Trace**
- Bundle ID: `de.kamilunavo.trace`
- Version: `0.1.0`
- Apple Team ID: `TKG684N5GL`
- Category direction: Productivity
- Platform: iPhone / iOS 17+

## Privacy manifest

The app target bundles `PrivacyInfo.xcprivacy`.

Current release declaration:

- `NSPrivacyTracking = false`
- no tracking domains
- no developer-collected app data declared for v1
- app-owned `UserDefaults` use is declared as `NSPrivacyAccessedAPICategoryUserDefaults`
- approved required-reason value: `CA92.1`

This matches Trace v1's local-only privacy boundary. Reconfirm the submitted binary and Apple's current App Privacy definitions before App Review submission.

## Export compliance

The generated Info.plist must contain:

- `ITSAppUsesNonExemptEncryption = NO`

Release rationale:

- Trace uses SHA-256 hashing for evidence integrity; hashing is not used to encrypt user content.
- Trace does not implement proprietary or non-standard encryption.
- Apple platform security functionality such as StoreKit and device-owner authentication is provided by system frameworks.

Apple's own guidance says `ITSAppUsesNonExemptEncryption` may be `NO` when the app does not use encryption or only uses forms that are exempt from export documentation requirements. The repository gate enforces the plist value, but the developer remains responsible for confirming the actual submitted binary and App Store Connect export-compliance answers.

## Lifetime Pro

Create exactly one non-consumable In-App Purchase:

- Product ID: `de.kamilunavo.trace.pro.lifetime`
- Reference name: `Kamilunavo Trace Lifetime Pro`
- Type: Non-Consumable
- Launch-price direction: **14.99 EUR** in the German storefront, with Apple price-tier/local pricing applied elsewhere

Suggested localization:

### German

- Display name: `Kamilunavo Trace Pro – Lifetime`
- Description: `Unbegrenzt aktive Fälle sowie unbegrenzte PDF- und Prüfpaket-Exporte. Einmal zahlen.`

### English

- Display name: `Kamilunavo Trace Pro Lifetime`
- Description: `Unlimited active cases and unlimited PDF / verification-bundle exports. Pay once.`

## Free / Pro product boundary

Free:

- up to 3 active evidence cases
- capture notes/photos/files
- original-media SHA-256
- evidence-record SHA-256
- snapshot seals
- local OCR
- Privacy Lock
- original sharing
- text manifest sharing
- verify received `.evpack` bundles

Lifetime Pro:

- unlimited active cases
- PDF evidence-pack export
- `.evpack` verification-bundle export

Do not turn received-bundle verification into a paid feature. A recipient must be able to validate a package without buying Pro.

## StoreKit truth boundary

Production entitlement code uses StoreKit 2 verified transactions:

- `Transaction.currentEntitlements` is the source of truth for recovered Lifetime access.
- `Transaction.updates` handles transaction updates while the app runs.
- `Transaction.unfinished` is consumed for crash/interruption recovery.
- `AppStore.sync()` is used only from the explicit Restore Purchases action.
- No persisted fake `isPro` boolean is used as the entitlement source of truth.

The local `KamilunavoTrace.storekit` file is for Xcode/local validation only. It does **not** create the real App Store Connect product.

## Required Apple-side records before signed purchase QA

Before the TestFlight purchase/restore gate can be called green:

1. register Bundle ID `de.kamilunavo.trace` in the Apple Developer account if it does not already exist;
2. create or update the App Store Connect app record for `Kamilunavo Trace` with that Bundle ID;
3. create the non-consumable `de.kamilunavo.trace.pro.lifetime` product;
4. complete required IAP localization, pricing and review metadata;
5. make sure Paid Applications / banking / tax agreements required for paid IAP are active;
6. confirm App Privacy and export-compliance answers against the submitted binary;
7. upload a signed build through `.github/workflows/kamilunavo-trace-testflight.yml`;
8. wait until Apple processes the build and the product is available to the TestFlight/sandbox purchase flow;
9. execute `PHYSICAL_QA.md` on the real iPhone.

Do not document the IAP as `READY`, `APPROVED`, or `TESTFLIGHT VERIFIED` merely because the local StoreKit configuration works.

## TestFlight workflow

Canonical workflow:

`.github/workflows/kamilunavo-trace-testflight.yml`

It validates an unsigned Release iPhone build on pull requests. On `main` / manual dispatch, when the repository has all three App Store Connect API secrets, it can use Apple cloud distribution signing and upload:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

The upload path must remain disabled on pull requests.

## Release evidence to record

After the first successful upload, add to `PROJECT_STATE.md`:

- exact commit SHA
- exact workflow run ID/job ID
- exact TestFlight build number
- `UPLOAD SUCCEEDED` evidence / relevant export result
- Apple processing visibility
- physical-device install result
- purchase/relaunch/restore result
- physical QA outcome and any screenshots saved by the tester
