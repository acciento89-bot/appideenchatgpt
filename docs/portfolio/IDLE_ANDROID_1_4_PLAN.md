# Idle Handwerker Android 1.4 delivery

Existing dispatch feature (PR99, source5eefa57) is already integrated. Android is first; iOS native validation/submission follows later. Preserve existing purchases, balances, staff and save data.

Observed release gap: Android AdMob is disabled, consent/optional rewarded entry only starts on iOS, Android has no own AdMob app. Android is publicly listed under de.kamilunavo.idlehandwerker. Create exactly one own Android app/its two rewarded placements, link the existing public listing and publish matching DE/EN UMP; do not duplicate the existing working iOS app/IDs.

1. Confirm actual Google version ceiling before selecting next counter; retain1.4.0 as the substantial dispatch update.
2. First capture RED safety tests for real bridge consent orchestration using fake SDK callbacks only: UNKNOWN/REQUIRED must not initialize/load/show; update required per session; valid status idempotent; revoked consent clears/prevents stale loaded ads; exact platform IDs and no test-ID fallback in release.
3. Apply the smallest cross-platform bridge correction, Android enablement and Android-specific own IDs. Keep iOS production workflow substitution and existing IAP semantics. SDK request permission follows the pinned UMP status API after a session update (NOT_REQUIRED or OBTAINED); no unknown-error bypass. Reference: https://developers.google.com/admob/android/reference/privacy/com/google/android/ump/ConsentInformation
4. Run Godot core/integration/UI/archive regressions and meaningful new fake-SDK tests. Add mandatory no-Billing-service/offline guards to native CI capture before any app launch; no real purchase, restoration or ad-reward transaction. Build/sign exact immutable Android source, perform serial native dispatch/cold/save/layout acceptance with synthetic fixture only if explicitly documented.
5. Read-only independent release review, integrate normal PR, submit Google candidate once with factual DE/EN listing and actual native original frames. Preserve already-running releases; no publication automation.

Reuse the owned isolated checkout on android/idle-dispatch-release3. At most one local virtual device, temporary Android finally-delete; retain shared Duo13DD2A7C-8220-45F5-93CA-9B283C432DEE shut down. Never upload fixture binaries/images. No secrets or customer data in artifacts.
