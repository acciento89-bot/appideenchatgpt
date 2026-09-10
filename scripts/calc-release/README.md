# Calc build 5 release

The existing `ASC_ISSUER_ID`, `ASC_KEY_ID` and `ASC_PRIVATE_KEY_B64` secrets in this repository provide the same Apple signing/upload route used by Rapport AI. No credential values are copied to the Calc repositories or stored in artifacts.

- `calc-build5-testflight.yml` archives the pinned SHK / AnlagenVolumen commits and uploads version 1.0 (5). The SHK release invokes its existing app-icon generator and selects the AppIcon catalog. Temporary API-key files are removed at job completion. The workflow checks Apple before uploading to avoid duplicate build numbers.
- `calc-store-screenshots.yml` runs the actual persisted workflows on a large iPhone and 13-inch iPad. Artifacts contain original PNG captures, with synthetic test data, rather than edited or generated product imagery.
- `metadata.json` contains German and English descriptions, subtitles, the existing standard EULA URL and app-specific reviewer steps.
- `prepare_review.py` requires a processed build 5 and correctly sized captures before replacing metadata/screenshots and selecting the build. All new screenshots must reach COMPLETE before obsolete screenshots are removed.
- `submit_review.py` rechecks the selected build, exact metadata/review notes and complete screenshots, then submits only the selected app version. It stops if the review package contains unexpected items.

Each workflow is scoped to the five listed Calc app IDs. Existing account contacts, prices, privacy information and automatic-release settings are retained. App Review acceptance is determined by Apple, separately from successful upload or submission.
