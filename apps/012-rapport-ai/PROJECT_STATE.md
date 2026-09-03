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

- The `generate-rapport` Supabase Edge Function source exists in the repository.
- `RAPPORT_API_URL` is not configured in the Xcode project yet, so current builds use `LocalRapportFormatter` instead of the hosted AI path.
- A live probe on 2026-09-03 against the known Supabase project ref `bqctetqraszsvknczjjr` returned `404 Requested function was not found`; `generate-rapport` is not deployed there yet.

## Next gates

1. Connect and deploy the protected `generate-rapport` AI endpoint.
2. Configure the release app's `RAPPORT_API_URL`, validate the real hosted AI response and upload the next TestFlight build.
3. Physically verify AI generation, editing, local save/history and PDF sharing on iPhone.
4. Create matching App Store Connect subscriptions and agreements.
5. Physically verify purchase, entitlement persistence and Restore in TestFlight.
6. Complete App Store naming, metadata, screenshots and submission.
