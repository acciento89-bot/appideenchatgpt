# Rapport AI — Project State

Last updated: 2026-09-01

## Current checkpoint

- Native SwiftUI iPhone project created for iOS 17+.
- Working bundle id: `de.kamilunavo.rapportai`.
- Working product name: `Rapport AI`; public App Store name still requires availability/trademark review.
- Cross-trade product for craftspeople; not limited to SHK.
- Visual direction: deep technical blue, cyan highlights and safety orange without trade-specific branding.
- MVP scope: onboarding -> dictate/type -> generate -> edit -> save -> branded PDF share.
- Local persistence, Apple speech recognition and server-side AI boundary included.
- Company profile with optional logo and contact details is integrated into PDF export.
- StoreKit 2 monthly/annual Pro subscriptions only unlock after verified transactions.
- App icon and local StoreKit test configuration are included in the Xcode project.

## Next gates

1. Compile and UI regression validation on macOS/Xcode CI.
2. Connect and deploy the protected AI endpoint.
3. Create matching App Store Connect subscriptions and agreements.
4. Physical iPhone microphone/speech/PDF and purchase/restore QA in TestFlight.
5. App Store naming, metadata, screenshots and submission.
