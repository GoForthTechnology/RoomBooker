## 1. Refactor Entry Point

- [x] 1.1 Update `main()` in `lib/main.dart` to be `Future<void> main()`.
- [x] 1.2 Move the Sentry configuration block from `_AppInitializerState._initialize` to `main()`.
- [x] 1.3 Ensure `SentryFlutter.init` is awaited in `main()` immediately after `WidgetsFlutterBinding.ensureInitialized()`.

## 2. Update App Initialization Logic

- [x] 2.1 Remove Sentry initialization code from `lib/main.dart`'s `_AppInitializerState._initialize`.
- [x] 2.2 Verify that `getLoggingService()` correctly provides `SentryLoggingService` when not in debug mode.

## 3. Validation

- [x] 3.1 Run `flutter analyze` to ensure code integrity.
- [x] 3.2 Run `flutter test` to verify application stability after refactoring.
