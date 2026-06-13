## 1. roombooker_portal: lib fixes

- [x] 1.1 Fix `avoid_print` (5) in `packages/roombooker_portal/lib/main.dart`
      (lines 22, 27, 29, 46, 50) — replace with the project's
      logging/Sentry conventions or remove debug scaffolding.
- [x] 1.2 Fix `experimental_member_use` (1) in
      `packages/roombooker_portal/lib/main.dart:80` (`profilesSampleRate`)
      — add a documented `// ignore: experimental_member_use` suppression.
- [x] 1.3 Fix `unnecessary_import`/`unused_import` (2) in
      `packages/roombooker_portal/lib/ui/widgets/room_list_widget.dart`
      (lines 3, 7) — remove redundant imports covered by the
      `roombooker_core` barrel export.
- [x] 1.4 Fix `deprecated_member_use` (1) in
      `packages/roombooker_portal/lib/ui/widgets/room_list_widget.dart:44`
      — migrate `onReorder` to `onReorderItem`.

## 2. roombooker_portal: test fixes

- [x] 2.1 Fix `depend_on_referenced_packages` (2) for
      `packages/roombooker_portal/test/app_boot_test.dart` (lines 6, 7) —
      add missing packages to `dev_dependencies` in
      `packages/roombooker_portal/pubspec.yaml`.
- [x] 2.2 Fix `unnecessary_underscores` (2) in
      `packages/roombooker_portal/test/ui/screens/view_bookings/tap_to_reschedule_test.dart:102`
      — rename multi-underscore identifiers to a single `_`.

## 3. roombooker_core fixes

- [x] 3.1 Fix `deprecated_member_use` (1) in
      `packages/roombooker_core/lib/data/services/logging_service.dart:74`
      — migrate to the replacement API.
- [x] 3.2 Fix `unnecessary_library_name` (1) in
      `packages/roombooker_core/lib/roombooker_core.dart:1` — remove the
      `library` directive.

## 4. roombooker_kiosk: lib fixes

- [x] 4.1 Fix `unnecessary_underscores` (3) in
      `packages/roombooker_kiosk/lib/main.dart` (lines 33, 37, 44) —
      rename to single `_`.
- [x] 4.2 Fix `unused_element` (1) in
      `packages/roombooker_kiosk/lib/main.dart:60` — investigate intent;
      remove if dead, wire up only if removal drops intended
      functionality (flag if ambiguous).
- [x] 4.3 Fix `use_build_context_synchronously` (7) in
      `packages/roombooker_kiosk/lib/main.dart` (lines 187, 385, 388, 459,
      482, 489, 492) — add `mounted` checks after `await`s before using
      `BuildContext`.
- [x] 4.4 Fix `unused_field` (1) in
      `packages/roombooker_kiosk/lib/webview_stage.dart:13`
      (`_webViewController`) — remove if dead, wire up only if removal
      drops intended functionality (flag if ambiguous).
- [x] 4.5 Fix `unnecessary_nullable_for_final_variable_declarations` (1) in
      `packages/roombooker_kiosk/lib/display_orchestrator.dart:35` — drop
      the `?`.
- [x] 4.6 Fix `prefer_final_fields` (1) in
      `packages/roombooker_kiosk/lib/stage_ui.dart:11` (`_roomName`) — make
      final.

## 5. roombooker_kiosk: test fixes

- [x] 5.1 Fix `depend_on_referenced_packages` (3) for
      `packages/roombooker_kiosk/test/app_boot_test.dart` (lines 4, 11, 12)
      and (1) for `packages/roombooker_kiosk/test/widget_test.dart:3` —
      add missing packages to `dev_dependencies` in
      `packages/roombooker_kiosk/pubspec.yaml`.
- [x] 5.2 Fix `unused_import` (2) in
      `packages/roombooker_kiosk/test/app_boot_test.dart:10` and
      `packages/roombooker_kiosk/test/widget_test.dart:1` — remove.

## 6. Validation and CI

- [x] 6.1 Run `flutter analyze` across the workspace and confirm it exits 0
      (0 issues).
- [x] 6.2 Run `flutter test` for `roombooker_core`, `roombooker_portal`, and
      `roombooker_kiosk` and confirm all pass (no behavior changes).
- [x] 6.3 Remove `continue-on-error: true` and its TODO comment from the
      Analyze step in `.github/workflows/pr-checks.yml`.
