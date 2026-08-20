# Kamilunavo Trace — Release dependency chain

This release branch is intentionally dependent on the two integrity passes below.

## Required order

1. PR #29 — DE/EN localization + accessibility + localized PDF
   - exact head `79c132f31ca2ce13046e5941f872087dfc7dad07`
   - workflow `32369937142`
   - merge only after exact-head SUCCESS

2. PR #32 — offline-verifiable `.evpack`
   - branch `agent/002-evidaro-offline-verifier`
   - currently documented head `d6b7a1f376b3cf8a73b6beae1fe8509b81b00be2`
   - depends on #29
   - merge only after its own exact-head full gate SUCCESS

3. Kamilunavo Trace release PR
   - branch `agent/002-kamilunavo-trace-release`
   - direct descendant of #32
   - must not merge while #29 or #32 is unmerged
   - after #29/#32 are on `main`, re-evaluate/retarget the release PR against clean `main`
   - require fast static release gate + full iOS Simulator integrity gate + unsigned Release-device build gate on the final release head

## Non-negotiable rule

Do not bypass, disable, `continue-on-error`, or weaken a required persistence/hash/OCR/PDF/privacy/localization/`.evpack`/StoreKit release gate merely to make the release green.
