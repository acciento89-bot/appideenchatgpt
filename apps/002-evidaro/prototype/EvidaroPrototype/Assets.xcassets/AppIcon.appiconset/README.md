# Kamilunavo Trace App Icon

`KamilunavoTrace-AppIcon-1024.png` is the production App Store icon source.

Release requirements enforced by CI:
- 1024 × 1024 pixels
- 8-bit PNG
- truecolor RGB
- no alpha channel
- no transparent pixels
- wired as the Xcode `AppIcon` asset
- exact approved production asset SHA-256 is pinned by `ci/icon_no_alpha.py`

Build 5 device QA exposed a visual release bug: the previous dark-graphite icon passed all technical PNG checks but appeared effectively black on the physical iPhone Homescreen.

The corrected Build 6 visual uses a clearly visible blue/teal field, a white traced evidence path, integrity points, a document outline and a confirmed endpoint. No product-name text is embedded in the icon.
