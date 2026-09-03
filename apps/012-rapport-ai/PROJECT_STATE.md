# Rapport AI — Project State

Last updated: 2026-09-03

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
- PR #80 (cross-trade native MVP), PR #82 (TestFlight UI and continuous dictation) and PR #83 (Speech partial-reset handling) are merged.
- TestFlight Build 3 is uploaded and has been physically tested on an iPhone.
- User-confirmed Build 3 speech behavior:
  - dictated text survives short speech pauses;
  - new sentences append to the existing block;
  - delayed callbacks cannot overwrite newer text;
  - stopping and resuming retains prior text;
  - dictated content is no longer duplicated.
- The final duplicate-prevention fix is on `main` at `6dc36cfd3f4e80fd2b4bb0d66c5c20361942945c`.

## Backend status

- Supabase project `bqctetqraszsvknczjjr` is active in Frankfurt (`eu-central-1`).
- `generate-rapport` is deployed and active with explicit validation of the public Supabase client key.
- Two authenticated live probes returned real OpenAI-generated reports for SHK and general-handwork input.
- The app supplies only the public Supabase client key; no bearer JWT, privileged credential or OpenAI API key is committed or shipped.
- Build 5 exposed that Xcode's generated `Info.plist` omitted the custom backend keys, so the app silently used its local formatter and never contacted Supabase.
- The endpoint and public Supabase publishable key now ship as explicit client configuration; the silent local formatter has been removed.
- CI validates that the compiled iOS app binary actually contains the endpoint and publishable key marker.
- Build number is advanced to 6 for hosted-AI TestFlight validation.

## Next gates

1. Pass simulator/device CI for the corrected hosted-AI wiring and upload TestFlight Build 6.
2. Physically verify AI generation, editing, local save/history and PDF sharing on iPhone.
3. Create matching App Store Connect subscriptions and agreements.
4. Physically verify purchase, entitlement persistence and Restore in TestFlight.
5. Complete App Store naming, metadata, screenshots and submission.
