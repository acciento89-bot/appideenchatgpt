# Evidaro Prototype

Portfolio app #002 foundation implementation.

## Open in Xcode

Open:

`apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj`

Shared scheme:

`EvidaroPrototype`

## Current prototype loop

1. Create a case.
2. Add factual evidence notes/context.
3. Each evidence item receives a SHA-256 hash.
4. Seal the current case snapshot.
5. Share the text manifest containing evidence hashes and the latest manifest hash.

## Current limitations

- in-memory only; persistence is the next gate
- photo/document evidence types currently capture note/context metadata only
- no legal-admissibility claim
- no App Store identity is locked yet; `Evidaro` is provisional

## CI

`.github/workflows/evidaro-prototype-build.yml` runs the app-specific static preflight and an iOS Simulator build on GitHub's supported `macos-26` runner label, matching the current KeepMeter iOS pipeline.
