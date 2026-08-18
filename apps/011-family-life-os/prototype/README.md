# Family Life OS — SwiftUI Vertical Slice Prototype

Temporary implementation location inside the App Factory repository.

The GitHub connector available in this session cannot create a new repository, so implementation starts here rather than blocking. As soon as repository creation is available, this prototype must move to an app-specific repository and this directory should become only a pointer/history artifact.

## Prototype goal

Prove the locked workflow with deterministic fixtures before connecting real AI:

`Heute -> Inbox -> Import prüfen -> resolve ambiguity -> confirm -> Plan/Heute -> source provenance`

## Technical target

- native SwiftUI
- iOS/iPadOS 18+
- iPhone-first, adaptive iPad later in the same pass
- Observation state model
- no backend dependency in this first fixture-driven UI slice
- no AI provider calls yet

## Build target

The prototype includes a standalone Xcode project under `FamilyLifePrototype.xcodeproj` with generated Info.plist settings and a provisional bundle identifier.

## Quality rules

- no silent AI confirmation
- no color-only member identity
- Dynamic Type-friendly layouts
- Dark Mode through semantic colors
- no decorative Liquid Glass content cards
- source remains reachable from import review

## Next after first green build

1. split/move to dedicated repository
2. add CI simulator build
3. add Supabase domain/repository implementations behind the existing UI/domain boundaries
4. replace fixture extraction with structured server-side extraction
5. add iPad split-view refinement and accessibility QA