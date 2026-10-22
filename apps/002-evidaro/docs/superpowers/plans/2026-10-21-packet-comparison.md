# Evidence Packet Comparison Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Compare two internally verified same-case packets with factual categorized differences and Pro report sharing.
**Architecture:** New Foundation TracePacketComparison.swift wraps the unchanged existing verifier; native SwiftUI view handles explicit bounded imports and report UI. No persistence/schema change.
**Tech Stack:** Swift/Foundation/CryptoKit, existing SwiftUI/SwiftData/StoreKit app, no new dependencies.
**Spec:** apps/002-evidaro/docs/superpowers/specs/2026-10-21-packet-comparison-design.md

## Global Constraints
- Identity de.kamilunavo.trace / Apple6803765449; existing hashes/seals/verification/lock/Pro product unchanged.
- Root owns every compiler/native/device/signing/store action. No agent-local builds, transaction, push, version bump or other-app edit.
- Packet limit20MiB each, record/seal count10000 each and100000 cumulative seal-prefix entries and64MiB total manifest UTF8 verification byte work; explicit selection direction, no temporal/legal certification.
- Complete DE/EN interface and factual report; no new persistence or import mutation.

## Review Focus
- Rehashed but different records must be reported, never presented as independently authenticated history.
- Derived OCR and unhashed attachment metadata remain separate from original-record changes.
- Duplicate normalized UUIDs and nonfinite canonical timestamps block comparison even if original verifier passes.
- Read errors/cancelled providers/oversized data leave previous selection intact and release scoped access.
- Pro report export and AppLock containment retain original boundaries; source share-safe-area contract preserves camera exception.

### Task1: domain comparator
- [x] Write tests/main.swift and extraction runner using exact production verifier/hash code, not mocks/reimplemented algorithms.
- [x] Root runs bash apps/002-evidaro/scripts/test-packet-comparison.sh; require missing comparator RED.
- [x] Implement TracePacketComparison.swift verified snapshot loader/bounds/domain diff/report.
- [x] Root repeats complete comparator suite; require GREEN with unchanged verification tamper checks.

### Task2: native integration and safe-area correction
- [x] Write scoped share-sheet safe-area source regression test; root observes RED.
- [x] Implement TracePacketComparisonView.swift with two imports, swap/clear, localized categorized changes and Pro report share.
- [x] Add home navigation, surgical source registration and DE/EN keys; remove only the two audited share-control ignoresSafeArea modifiers.
- [x] Root runs source contract, core suite and generic native build serially; native file-picker/share/lock/Pro/Duo acceptance remains separate.
- [ ] Fresh source review, commit verified files, save ledger/metadata/native handoff; no push or release claim.

### Review correction: bound repeated manifest byte work
- [x] Root observes missing-byte-preflight API RED with cheap amplification regression.
- [x] Implement exact UTF8 current+all-seal manifest accounting before existing verifier; original crypto/verification implementation unchanged.
- [x] Root runs full suite and final native compilation; preserve pre-fix build receipt separately.
