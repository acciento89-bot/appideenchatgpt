# Idle iOS provider isolation implementation plan

> **For agentic workers:** Execute inline with superpowers:executing-plans. No implementer agents.

**Goal:** Permit genuine iOS Duo validation without financial or ad operations.
**Architecture:** Explicit debug-only launch policy guarding the existing bridge entry points and transaction/reward callbacks. No alternative economy or entitlement implementation.
**Tech Stack:** Godot4.7.1 GDScript and existing pinned native plugins.
**Spec:** ../specs/2026-10-23-ios-provider-isolation.md

## Global constraints
Only apps/005-idle-handwerker and its existing validation workflow. iOS1.4.0(19); Android3 unchanged. No real purchase/restore/ad rewards. Preserve existing saved data. Root owns all native operations, heavy jobs serial, sole Duo retained.

## Review focus
Explicit launch flags after Godot argument separator must activate Debug guard. Ordinary Debug and Release must preserve existing provider paths. Direct callbacks cannot grant under QA. Pause/resume must not request ads. No entitlement writes. Existing fake SDK consent tests must remain valid.

## Task1: Guard and fake-provider regression
- [x] Write tests/test_provider_isolation.gd exercising real bridge lifecycle/public methods/event callbacks with fake StoreKit; observe RED nonzero calls/grants under explicit QA.
- [x] Add minimal policy and guards in scripts/monetization_bridge.gd, observing GREEN zero calls/grants; test ordinary Debug and release-policy positive controls.
- [x] Run existing full seven Godot suites plus new isolation test with isolated staging/user directory; normal CI also runs new test. Preserve pinned dependencies.
- [ ] Set only iOS export build19, update truthful iOS docs; source review and commit.

## Task2: Native acceptance and delivery
- [ ] Serial simulator Debug and device Release exports/builds; verify actual archive identity and shipping policy.
- [ ] Actual retained Duo staff-dispatch/save/cold/future/failure/fold/font acceptance before signing/upload/submission. These are not proven by source tests.

Pre-flight: Task1 produces debug policy consumed by Task2 launch; release policy must ignore launch flag. Spec resolves release behavior. No other shared interfaces.

Task1 evidence: observed five expected RED assertions, then explicitQA7checks and ordinaryDebug6checks GREEN; all seven existing suites exit0/no script errors. Existing headless plugin-resource cleanup warnings also occur in the original consent/UI suites; retained, not hidden or treated as native acceptance. Initial ordinary test fake omitted StoreKit pop_pending_event and therefore did not exercise polling; corrected only that fake protocol and reran both modes successfully. Stage isolates its user directory and retains pinned plugin/callback code. Native SDK side effects outside bridge initialization are not claimed absent from source tests.
