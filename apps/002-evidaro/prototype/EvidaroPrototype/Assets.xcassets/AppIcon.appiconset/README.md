# Kamilunavo Trace App Icon

Build 8 replaces the fragile single-PNG AppIcon setup with three explicit iOS appearances:

- `KamilunavoTrace-AppIcon-1024.png` — bright blue/teal default artwork; the established filename is retained for release-preflight compatibility
- `KamilunavoTrace-AppIcon-Dark-1024.png` — explicit dark appearance that remains visibly blue
- `KamilunavoTrace-AppIcon-Tinted-1024.png` — explicit high-contrast grayscale artwork for iOS tinted mode

All three files are 1024 × 1024, 8-bit truecolor RGB PNGs with no alpha channel. Xcode `AppIcon` wiring is explicit for default, dark and tinted appearances.

`ci/icon_no_alpha.py` decodes the actual PNG pixels in release CI. It rejects missing appearance wiring, unexpected dimensions/color type, default/dark artwork that is too dark, insufficient bright foreground detail, and non-grayscale tinted artwork.

This supersedes the Build 6/7 approach. Build 6 changed only the main artwork; Build 7 added only the dark appearance. Physical iPhone QA still showed an effectively black icon, so Build 8 covers the remaining tinted appearance and uses three distinct artwork variants rather than relying on iOS-generated variants.
