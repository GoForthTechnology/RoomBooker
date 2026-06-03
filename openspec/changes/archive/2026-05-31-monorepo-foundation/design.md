## Context

The RoomBooker project currently exists as a single Flutter application. To scale into a suite of tools including a specialized hardware kiosk, we must move to a monorepo structure. This allows us to share code between the `portal` (current app) and the future `kiosk` app while keeping their binary footprints and permissions separate.

## Goals / Non-Goals

**Goals:**
- Migrate to a Flutter Workspace structure (`packages/` directory).
- Extract all domain entities and business logic into `roombooker_core`.
- Isolate the user-facing app into `roombooker_portal`.
- Update CI/CD to support the new structure.
- Maintain 100% test pass rate throughout the migration.

**Non-Goals:**
- Implementation of the Kiosk UI or native automation (Phase 2/3).
- Major refactoring of existing business logic (just moving it).
- Introduction of new dependencies (like Melos) unless absolutely necessary (preferring native Flutter workspace).

## Decisions

### 1. Workspace Tooling: Native Flutter Workspaces
- **Decision**: Use the built-in Flutter/Dart Workspace feature (introduced in Dart 3.5/Flutter 3.24) via the `workspace` property in `pubspec.yaml`.
- **Rationale**: Keeps the toolchain simple and avoids adding external dependencies like Melos.
- **Alternatives**: Melos (powerful but adds complexity for a 3-package monorepo).

### 2. Package Structure
- **roombooker_core**:
  - `lib/data/` (Entities, Repos, Services)
  - `lib/logic/`
  - `lib/utils/` (Generic helpers)
  - `lib/providers.dart`
- **roombooker_portal**:
  - `lib/ui/`
  - `lib/router.dart`
  - `lib/app_router_observer.dart`
  - `lib/main.dart`
  - `android/`, `ios/`, `web/`

### 3. CI/CD Path Mapping
- **Decision**: Update GitHub Actions to set the `working-directory` or explicitly pass paths to Flutter commands.
- **Rationale**: Ensures the existing pipeline continues to build the correct target.
- **Paths**:
  - Flutter Build: `packages/roombooker_portal`
  - Firebase Deploy: `packages/roombooker_portal` (web)
  - Pub Get: Root (workspace-aware)

## Risks / Trade-offs

- **[Risk] Path Breakage in CI/CD** → **Mitigation**: Use surgical updates to workflow files and verify with local `act` runs or a dry-run release tag.
- **[Risk] Import Spaghetti** → **Mitigation**: Perform a global regex-based find-and-replace for `package:room_booker/` to `package:roombooker_core/` where appropriate.
- **[Risk] Test Data Dependencies** → **Mitigation**: Move `test/` contents along with their respective logic (e.g., entity tests to `core`, UI tests to `portal`).
