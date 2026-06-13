## Context

`main` has 35 `flutter analyze` issues across the three workspace packages
(`roombooker_core`, `roombooker_portal`, `roombooker_kiosk`). These are all
pre-existing lint findings, not introduced by this change. They were
catalogued via `flutter analyze` and grouped by lint rule in the proposal.
The `pr-checks.yml` Analyze step currently runs with
`continue-on-error: true` to avoid blocking PRs on these pre-existing issues.

## Goals / Non-Goals

**Goals:**
- `flutter analyze` exits 0 across the whole workspace.
- No behavior changes — all existing test suites continue to pass.
- Remove `continue-on-error: true` (and its TODO) from the Analyze step in
  `.github/workflows/pr-checks.yml`, making it a blocking PR check again.

**Non-Goals:**
- No new features or refactors beyond what's needed to satisfy the linter.
- No changes to lint rule configuration (`analysis_options.yaml`) — fix the
  code, not the rules, unless a rule is determined to be inappropriate for
  the project (see Open Questions).

## Decisions

- **`avoid_print` in `roombooker_portal/lib/main.dart`**: Replace `print`
  calls with the existing `sentry_flutter` / logging conventions already
  used elsewhere in the app (e.g. via `roombooker_core`'s logging service),
  or remove if the prints are leftover debug scaffolding with no production
  value.
- **`depend_on_referenced_packages`**: Add `mocktail`,
  `firebase_core_platform_interface`, and `plugin_platform_interface` as
  explicit `dev_dependencies` in the `pubspec.yaml` of whichever
  package(s) (`roombooker_kiosk`, `roombooker_portal`) reference them in
  tests, rather than relying on transitive resolution.
- **Unused/unnecessary imports**: Remove directly; for
  `room_list_widget.dart`, rely on the `roombooker_core` barrel export that
  already covers the removed imports.
- **`unused_field`/`unused_element` in kiosk**: Investigate
  `_webViewController` (`webview_stage.dart`) and the unused element at
  `main.dart:60` to confirm they're genuinely dead code (not partially-wired
  features). Remove if dead; wire up only if removing would silently drop
  intended functionality — if so, flag during implementation rather than
  guessing at the original intent.
- **`use_build_context_synchronously`**: Add `if (!mounted) return;` (or
  equivalent) checks after each flagged `await` in
  `roombooker_kiosk/lib/main.dart` before using `BuildContext`, following
  standard Flutter guidance.
- **`unnecessary_underscores`**: Rename `__`/`___`-style identifiers to a
  single `_` per the lint's expectation.
- **`deprecated_member_use`**:
  - `logging_service.dart:74` — migrate to the replacement API indicated by
    the deprecation message.
  - `room_list_widget.dart:44` — migrate `onReorder` to `onReorderItem` on
    the relevant reorderable widget.
- **`experimental_member_use` (`profilesSampleRate`)**: Sentry's
  `profilesSampleRate` is experimental but is the documented way to enable
  profiling. Keep it with a targeted
  `// ignore: experimental_member_use` (with a comment explaining why) rather
  than removing profiling, since removing it would be a behavior change.
- **`unnecessary_nullable_for_final_variable_declarations`,
  `prefer_final_fields`, `unnecessary_library_name`**: Mechanical fixes —
  drop the `?`, add `final`, remove the `library` directive, respectively.

## Risks / Trade-offs

- [Risk] Removing a `print` or an "unused" field/element could remove
  functionality that was partially relied upon.
  → Mitigation: review each case's surrounding code before removing; run
  the full test suite after each package's fixes; flag anything ambiguous
  during implementation instead of guessing.
- [Risk] Suppressing `experimental_member_use` with an inline ignore could
  mask a future breaking change in Sentry's API.
  → Mitigation: add a comment noting the suppression is intentional and
  tied to `profilesSampleRate`, so it's easy to revisit when upgrading
  `sentry_flutter`.

## Migration Plan

Not applicable — this is a non-behavioral lint cleanup. Once all fixes are
in place and `flutter analyze` exits 0, remove `continue-on-error: true`
(and its TODO comment) from the Analyze step in `.github/workflows/pr-checks.yml`
as the final task.
