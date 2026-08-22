# Kamilunavo Trace App Icon

`KamilunavoTrace-AppIcon-1024.png` is the production App Store icon source.

Release requirements enforced by CI:
- 1024 × 1024 pixels
- 8-bit PNG
- truecolor RGB
- no alpha channel
- no transparent pixels
- wired as the Xcode `AppIcon` asset
- default iOS appearance explicitly uses the approved production PNG
- dark iOS appearance explicitly uses the same approved production PNG instead of relying on automatic system generation

Build 5 device QA exposed a visual release bug: the previous dark-graphite icon passed all technical PNG checks but appeared effectively black on the physical iPhone Homescreen.

Build 6 replaced the artwork with a clearly visible blue/teal field, a white traced evidence path, integrity points, a document outline and a confirmed endpoint. Physical Build 6 QA still showed an effectively black Homescreen icon because the asset catalog only supplied the default appearance and allowed iOS to synthesize the dark appearance.

Build 7 therefore keeps the approved blue/teal artwork but explicitly supplies it for both the default and dark AppIcon appearances. Tinted appearance remains system-controlled by design. No product-name text is embedded in the icon.
