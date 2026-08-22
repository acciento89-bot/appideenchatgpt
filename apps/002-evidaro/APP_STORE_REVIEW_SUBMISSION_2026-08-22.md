# Kamilunavo Trace — App Store Review Submission

Date: 2026-08-22
Status: SUBMITTED TO APPLE APP REVIEW

## Final release checkpoint

- Public app: Kamilunavo Trace
- App Store version: 1.0
- Bundle ID: `de.kamilunavo.trace`
- App Store Connect app ID: `6803765449`
- App Store version ID: `a895fc57-7ee4-40e6-9f19-2881323068ea`
- Apple-reported submitted build: `11`
- Build ID: `58473001-3b4a-402d-9ea7-63892d4a6021`
- Build processing state verified: `VALID`
- App price in Germany verified: Free
- Lifetime Pro product: `de.kamilunavo.trace.pro.lifetime`
- Lifetime Pro version ID: `8b715a31-6526-41bf-a7eb-226a629a5715`
- Lifetime Pro state before submission: `READY_FOR_REVIEW`
- App Privacy answers were manually published in App Store Connect on 2026-08-22.
- User confirmed that version 1.0 was added/submitted for Apple review.

## Protected bridge cleanup

Temporary CI bridge repository: `acciento89-bot/onemorefloor`

- PR #150: `CI: Kamilunavo Trace 1.0 Build 10 final submit`
- Bridge was used only because App Store Connect signing/API secrets are not stored in `appideenchatgpt`.
- Apple reported the final attached build as Build 11.
- PR #150 was closed without merge after submission.
- No Trace bridge workflow was merged to One More Floor `main`.

## Earlier blocker resolution

Final pre-submit blocker was App Store Connect App Privacy (`APP_DATA_USAGES_REQUIRED`). Apple does not expose publishing those answers through the public App Store Connect API. After the answers were manually published, the app version became reviewable.

Pricing had already been corrected and verified as Free before submission.

## Next action

Do not change or resubmit the release while Apple review is pending unless Apple reports a concrete issue. The next release action is to process Apple's review result and only reopen app code or metadata if the review identifies a real blocker.
