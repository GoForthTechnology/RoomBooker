## Why

To support the expansion of RoomBooker into a multi-app ecosystem (Portal and Kiosk), we must decouple the core business logic from the specific UI implementations. Migrating to a Flutter Monorepo Workspace prevents code duplication, ensures data consistency across clients, and enables a phased rollout of the new Kiosk application without risking the stability of the primary Portal app.

## What Changes

- **Workspace Initialization**: Convert the project root into a Flutter Workspace using `pubspec.yaml`.
- **Core Extraction**: Create a new package `roombooker_core` to house all shared data entities, repositories, services, and business logic.
- **Portal Isolation**: Move the current application into a new package `roombooker_portal`. **BREAKING** (paths will change).
- **Dependency Management**: Update all `pubspec.yaml` files to use relative path dependencies.
- **CI/CD Alignment**: Surgically update GitHub Actions workflows (`android-release.yml`, `firebase-hosting-merge.yml`) to reflect the new directory structure.
- **Import Refactoring**: Update all import statements throughout the codebase to reflect the new package structure.

## Capabilities

### New Capabilities
- `monorepo-workspace`: Implementation of a unified Flutter workspace for multi-package management.
- `shared-domain-logic`: Definition of the core package containing all non-UI code.

### Modified Capabilities
- `architecture`: The project architecture is moving from a single-app model to a multi-client monorepo.

## Impact

- **File Structure**: Major reorganization of `lib/`, `test/`, and native folders (`android/`, `ios/`, `web/`).
- **Build System**: `build_runner` and code generation commands must be executed within specific package contexts or via a workspace-wide runner.
- **CI/CD**: GitHub Actions paths for triggers, builds, and artifact collection will be affected.
- **Developer Workflow**: Developers will now work within sub-packages rather than the root `lib/` directory.
