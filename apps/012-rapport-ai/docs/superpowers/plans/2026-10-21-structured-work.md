# Rapport structured work Implementation Plan
> **For agentic workers:** Use superpowers:executing-plans inline; root owns all compile/test/native workloads.
**Goal:** Add exact entered work lines, reusable blank templates, retained revisions and revision-bound customer acknowledgement to both native apps.
**Architecture:** Add pure value-domain functions and compatible archive codecs, then integrate existing stores/editors/PDF body rendering. Existing speech/AI/products/quotas remain unchanged.
**Tech Stack:** Swift/Foundation/SwiftUI/UIKit PDF; Kotlin/BigDecimal/Compose/Android PDF; Android min24.
**Spec:** ../specs/2026-10-21-structured-work-design.md

## Global Constraints
Identity de.kamilunavo.rapportai, Apple6807486805. Source pin6d59c9d32b2315eece8d674667536bc968a94181 not linked to live binary. Source iOS1.1(10), Android1.0.1(3) frozen. Existing AI backend request and monthly/annual products unchanged. Root serial RED/GREEN/native only; no worker device/build/sign/store/push/version action.

## Review Focus
- Existing ISO8601/SharedPreferences archives must keep IDs/dates/text through migration.
- Exact quantity/minute totals; units grouped explicitly; invalid text cannot preserve stale valid fields.
- Templates never carry prior customer facts, acknowledgement or snapshot IDs.
- Later edits never silently become acknowledged; snapshots stay independent and old original survives.
- Failed/corrupt/future/trailing storage cannot alter published state or original bytes.

### Task1: Pure domain and migration test harness
Create prototype/RapportAI/StructuredWork.swift and RapportArchive.swift; modify Models.swift only for compatible new fields/decoding. Test tests/StructuredWorkTests.swift; integration regressions live in HistorySafetyTests.swift and ExportSafetyTests.swift.
Interfaces to pin in tests: RapportWorkItem.labor(...)/quantity(...), RapportWorkTotals(items:), RapportWorkTemplate.instantiate(), RapportRevisionContent(draft:), RapportDraft.savingRevision(at:), RapportDraft.acknowledging(revisionID:name:note:at:), RapportArchive.load()/save(_:).
- [x] Write golden labor75+45=120min and quantities0.1+0.2=0.3 exactly; unlike units separate; invalid/nonfinite/negative/overprecision/overflow reject.
- [x] Write template independent IDs and blank quantities, revision copy/no-op/legacy-original retention, acknowledgement bound to old snapshot after edit.
- [x] Write complete legacy ISO8601 fixture ID/date/narrative preservation and corrupt/future/trailing/malformed/failed-write exact-byte guards.
- [x] Root observed RED command from repository root: swiftc apps/012-rapport-ai/prototype/RapportAI/Models.swift apps/012-rapport-ai/prototype/RapportAI/StructuredWork.swift apps/012-rapport-ai/prototype/RapportAI/RapportArchive.swift apps/012-rapport-ai/tests/StructuredWorkTests.swift -o /tmp/rapport-work-tests && /tmp/rapport-work-tests
- [x] Only after observedRED implement exact domain and compatible archive; root repeats GREEN.

### Task2: Swift native integration and actual PDF
Modify RapportStore.swift to return success/error and publish after save. Add structured editor/template/revision screens; integrate CreateRapportView/ReportDetailView; register exact project references and DE/EN resources. Preserve existing AI request/quota and SpeechTranscriber.
- [x] Error/corruption blocks edits with retry; text-backed form validation; immutable history and explicit acknowledgement dialogs.
- [ ] Build structured report appendix from actual entered values and selected revision; append to existing paginated PDF body. Root render/inspect long native PDFs and actual share.
- [ ] Root generic build plus native acceptance; fresh review and corrections with RED tests first.

### Task3: Android one-to-one source parity
Add pure Kotlin domain/codec tests matching Task1; update model/repository/view model and Compose create/history/detail/PDF integration after root observed GradleRED. API24-safe atomic adapter, durable SharedPreferences migration (retain original value until new save succeeds), never use existing silent getOrDefault(emptyList()) as corruption recovery.
- [ ] Root targeted RED→implementation→GREEN; entire existing entitlement/model suites plus assembleDebug.
- [ ] Native state/draft rotation, speech denial/offline, quota/Pro gates, exact long PDF and DE/EN share validation root serially.

### Task4: Handoff
- [ ] Fresh read-only review, source hashes, per-app ledger/ASO drafts/native steps, commits after root verification. No push/versions/store. Code readiness distinct from native/Duo/publication state.

## Execution evidence and current acceptance status
Root exclusively ran compilers. Foundation core RED→GREEN (core-green2.log); stale editor/history safety RED→GREEN (history-green.log); generic iOS native build succeeded (native-build1.log). Kotlin domain RED→GREEN; blank template quantity export RED then full suite+assemble GREEN (android-release.log,9tests0failures). Independent peer review P2 original notes export received: separate Swift ExportSafety RED observed, labelled current/revision original notes implemented; matching Android test authored and waiting root RED before correction. Final export regressions/full builds, commit and actual native PDF/Duo/device acceptance remain pending.

Selected final history scope is read-only inspection/share and explicit local acknowledgement; no restore action. Existing backend/service, speech, quota and billing implementations remain unchanged. New locale claims apply only to new workflow/export.

## Verified handoff boundary
Root final Android export correction full suite and assembleDebug passed (android-export-green.log,10tests0failures/errors,21sec). Generic iOS build after export correction succeeded (native-export-build.log); pure ExportSafety current/saved DEEN notes passed (export-green.log). Earlier core-green2/history-green remain actual evidence; root scheduled one final core/history rerun after commit. No claim of actual device/PDF/Duo acceptance. Independent peer P2 original-notes gap addressed on both platforms after separately observed RED. Branch is retained locally under explicit parent direction, no push/version/store action.
