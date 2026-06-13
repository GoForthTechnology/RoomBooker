## Why

`main` currently has 35 pre-existing `flutter analyze` issues across
`roombooker_core`, `roombooker_portal`, and `roombooker_kiosk`. Because of
this, the `pr-checks.yml` Analyze step was added with
`continue-on-error: true` as a temporary workaround (tracked as follow-up
task 1.2 in `adopt-pr-review-workflow`). This leaves static analysis
effectively non-blocking, so new issues can slip into PRs unnoticed.
Cleaning up the existing issues lets Analyze become a real blocking check.

## What Changes

- Fix all 35 existing `flutter analyze` issues so `flutter analyze` exits 0
  across the workspace, with no behavior changes:
  - `avoid_print` (5): replace `print` calls in
    `packages/roombooker_portal/lib/main.dart` with the project's existing
    logging/Sentry conventions, or remove if pure debug scaffolding.
  - `depend_on_referenced_packages` (6): add missing `dev_dependencies`
    (`mocktail`, `firebase_core_platform_interface`,
    `plugin_platform_interface`) to the `pubspec.yaml` of
    `roombooker_kiosk` and `roombooker_portal` test packages.
  - `unused_import` (2) and `unnecessary_import` (2): remove redundant
    imports in `roombooker_kiosk` test files and
    `packages/roombooker_portal/lib/ui/widgets/room_list_widget.dart`
    (already covered by the `roombooker_core` barrel export).
  - `unused_field` (1) and `unused_element` (1): remove (or wire up, if
    genuinely needed) `_webViewController` in
    `packages/roombooker_kiosk/lib/webview_stage.dart` and the unused
    element at `packages/roombooker_kiosk/lib/main.dart:60`.
  - `use_build_context_synchronously` (7): add `mounted` checks after
    `await`s before using `BuildContext` in
    `packages/roombooker_kiosk/lib/main.dart`.
  - `unnecessary_underscores` (5): rename multi-underscore identifiers to a
    single `_` in `packages/roombooker_kiosk/lib/main.dart` and a
    `roombooker_portal` test file.
  - `deprecated_member_use` (2): migrate
    `packages/roombooker_core/lib/data/services/logging_service.dart:74` and
    `packages/roombooker_portal/lib/ui/widgets/room_list_widget.dart:44`
    (`onReorder` -> `onReorderItem`) to non-deprecated APIs.
  - `experimental_member_use` (1): assess
    `packages/roombooker_portal/lib/main.dart:80` (`profilesSampleRate`) and
    either keep with a documented suppression or replace.
  - `unnecessary_nullable_for_final_variable_declarations` (1): drop the `?`
    in `packages/roombooker_kiosk/lib/display_orchestrator.dart:35`.
  - `prefer_final_fields` (1): make `_roomName` final in
    `packages/roombooker_kiosk/lib/stage_ui.dart:11`.
  - `unnecessary_library_name` (1): remove the library name directive from
    `packages/roombooker_core/lib/roombooker_core.dart:1`.
- Remove `continue-on-error: true` (and its TODO comment) from the Analyze
  step in `.github/workflows/pr-checks.yml`, completing follow-up task 1.2
  from `adopt-pr-review-workflow`, so static analysis becomes a blocking PR
  check.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `pr-review-workflow`: The "PR Checks CI Workflow" requirement is updated
  to explicitly state that the Analyze step blocks the workflow on failure
  (no `continue-on-error`).

## Impact

- `packages/roombooker_portal/lib/main.dart`
- `packages/roombooker_portal/lib/ui/widgets/room_list_widget.dart`
- `packages/roombooker_portal/test/app_boot_test.dart`
- `packages/roombooker_portal/test/ui/screens/view_bookings/tap_to_reschedule_test.dart`
- `packages/roombooker_portal/pubspec.yaml`
- `packages/roombooker_core/lib/data/services/logging_service.dart`
- `packages/roombooker_core/lib/roombooker_core.dart`
- `packages/roombooker_kiosk/lib/main.dart`
- `packages/roombooker_kiosk/lib/webview_stage.dart`
- `packages/roombooker_kiosk/lib/display_orchestrator.dart`
- `packages/roombooker_kiosk/lib/stage_ui.dart`
- `packages/roombooker_kiosk/test/app_boot_test.dart`
- `packages/roombooker_kiosk/test/widget_test.dart`
- `packages/roombooker_kiosk/pubspec.yaml`
- `.github/workflows/pr-checks.yml`
- No behavior changes intended; verified via existing `flutter test` suites.
