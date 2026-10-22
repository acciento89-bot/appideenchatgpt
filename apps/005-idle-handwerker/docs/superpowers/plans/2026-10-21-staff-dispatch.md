# Staff Dispatch Implementation Plan
> **For agentic workers:** Use superpowers:executing-plans inline. Root owns every compiler/test/UI/device operation; no child agents.
**Goal:** Add bounded staff dispatch planning and safe window-relative layout without replacing existing economy.
**Architecture:** Pure RefCounted DispatchBoard model plus GameState persistence/rollback integration and a focused game UI board helper; pure responsive geometry conversion.
**Tech Stack:** Godot4 GDScript, existing code-built Control UI, existing JSON game save.
**Spec:** ../specs/2026-10-21-staff-dispatch-design.md

## Global constraints
Product scope apps/005-idle-handwerker in isolated IdleHandwerker-PortfolioUpdate-20261021 checkout. Root additionally authorized only .github/workflows/idle-handwerker-validate.yml to run all four new suites after existing dependency import, preserving old suites and rejecting script errors even with exit0. Preserve identifiers/version/export workflows/IAP/ads/sfx. Root serial observedRED before production and actualGREEN before claims.3 concurrent tasks,8h offline cap,5 receipts. No synthetic hinge or native claims.

## Review focus
- Multiple employees of one type and tasks awaiting collection must obey resource limits.
- Clock jumps/negative/nonfinite elapsed and repeated collection must not create rewards.
- Save migration/failure/corruption must preserve original money, transactions and board.
- Specialization changes cannot rewrite running quotes; resets cannot discard outstanding rewards.
- Window position and safe-area intersection must support all edges and wide/short resize without clipping.

### Task1: Pure board and geometry
Files: scripts/dispatch_board.gd, scripts/responsive_geometry.gd, tests/test_dispatch_board.gd.
Interfaces: DispatchBoard.quote(order,type,pace,specialty)->Dictionary; set_specialization(type,specialty)->bool; assign(order,type,pace,employees,level)->String; advance(seconds)->void; collect(id)->Dictionary; to_payload()->Dictionary; static from_payload(payload)->DispatchBoard or null. Profiles dictionary, tasks array, history array, next_id integer. ResponsiveGeometry.insets(window:Rect2i,safe:Rect2i,logical:Vector2)->Vector4(left,top,right,bottom).
- [x] Author tests from exact spec, request root `godot --headless --path . --script tests/test_dispatch_board.gd` RED.
- [x] After RED implement validated pure model and coordinate intersection converter.
- [x] Root repeats GREEN;44checks passed.

### Task2: Durable GameState integration
Files: scripts/game_state.gd, tests/test_dispatch_integration.gd.
Interfaces: dispatch_board RefCounted; dispatch_assign(order,type,pace)->bool; dispatch_collect(id)->bool; dispatch_specialize(type,specialty)->bool; dispatch_available(type)->int.
- [x] First write integration regressions: old save without board, collect changes board+money once, disk failure rolls back, invalid/future board preserves bytes, existing manual/passive unaffected, reset blocked during work.
- [x] RootRED then implement serialization in existing save, atomic temp replacement, blocked-save flag on invalid archive/new board, rollback new mutations; process+offline advancement and reset guards.
- [x] RootGREEN22checks plus existing test_economy.gd; required-v9-field regression RED→GREEN.

### Task3: Actual UI board and resize
Files: scripts/dispatch_panel.gd, scripts/main.gd, tests/test_dispatch_ui.gd and extended tests/test_ui_smoke.gd.
- [x] Author source-grounded smoke regression before UI integration, request rootRED.
- [x] Add Firma board entry, independent scrollable panel with close actions, staff profile selectors, order/employee/pace quote selection, locked/resource messages, active progress/collect and recent receipts. Preserve modal editor state on timer updates.
- [x] Integrate tested window-relative safe insets and short/wide breakpoint; existing dialogs share safe modal bounds.
- [x] Root focused32checksGREEN and existing smokeGREEN in staged full engine.
- [ ] Root actual Firma-entry rendering and Android/iOS/Duo native flows (separate release acceptance).

### Task4: Handoff
- [ ] Self-review and independent root-dispatched review, request regressionRED for confirmed issues.
- [ ] Save source audit, factual metadata, nativeQA and evidence ledger under IdleHandwerkerUpdate; update plan actual checkboxes. Commit verified files only locally, report exactSHA and scope.

## Verified handoff state
Root staged exact script/test hashes with existing pinned complete plugins and existing callback patches outside product; isolated test user directory. Import and all six suites passed with no SCRIPT errors. Fresh independent review has no remainingP1/P2; schema9missing-boardP2 resolved with observedRED→GREEN. No native/export/Duo/store success inferred. Only additionally permitted workflow is existing idle-handwerker-validate.yml; four new suites retained alongside original economy/UI checks, explicit script-error and PASS receipt guards.
