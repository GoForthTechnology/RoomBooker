## 1. Workspace Scaffolding

- [x] 1.1 Create `packages/roombooker_core` directory and initialize `pubspec.yaml`.
- [x] 1.2 Create `packages/roombooker_portal` directory and initialize `pubspec.yaml`.
- [x] 1.3 Convert root `pubspec.yaml` into a workspace configuration.

## 2. Core Package Extraction

- [x] 2.1 Move domain entities (`lib/data/entities/`) to `roombooker_core`.
- [x] 2.2 Move repositories and services (`lib/data/repos/`, `lib/data/services/`) to `roombooker_core`.
- [x] 2.3 Move logic classes (`lib/logic/`) to `roombooker_core`.
- [x] 2.4 Move shared providers (`lib/providers.dart`) to `roombooker_core`.
- [x] 2.5 Update `roombooker_core` exports and public API.

## 3. Portal Package Isolation

- [x] 3.1 Move UI components and screens (`lib/ui/`) to `roombooker_portal`.
- [x] 3.2 Move router and observers (`lib/router.dart`, `lib/app_router_observer.dart`) to `roombooker_portal`.
- [x] 3.3 Move entry point (`lib/main.dart`) and Firebase config (`lib/firebase_options.dart`) to `roombooker_portal`.
- [x] 3.4 Move native directories (`android/`, `ios/`, `web/`) to `roombooker_portal`.
- [x] 3.5 Add relative path dependency on `roombooker_core` in `roombooker_portal/pubspec.yaml`.

## 4. Refactoring and Alignment

- [x] 4.1 Perform global search-and-replace for internal imports (`package:room_booker/` to `package:roombooker_core/` or `package:roombooker_portal/`).
- [x] 4.2 Reorganize `test/` directory to match the new package structure.
- [x] 4.3 Run `flutter pub get` from the root workspace and verify all dependencies resolve.
- [x] 4.4 Verify all packages analyze cleanly (`flutter analyze`).
- [x] 4.5 Verify all unit and widget tests pass (`flutter test`).

## 5. CI/CD Update and Verification

- [x] 5.1 Update `.github/workflows/android-release.yml` with the new working directory and paths.
- [x] 5.2 Update `.github/workflows/firebase-hosting-merge.yml` with the new working directory and paths.
- [x] 5.3 Verify CI/CD changes with a manual `act` run (if environment supports it) or by inspecting workflow syntax.
- [x] 5.4 Document the new workspace developer guide in `GEMINI.md`.
