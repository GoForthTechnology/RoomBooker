## Why

The current Sentry initialization happens late in the application lifecycle, inside the `_initialize` method of `AppInitializer`. This results in early startup crashes (e.g., during Firebase initialization or Google SDK setup) being invisible to Sentry. Moving Sentry initialization to the very top level of `main()` ensures maximum coverage of the application's runtime.

## What Changes

- Move `SentryFlutter.init` from `lib/main.dart`'s `_AppInitializerState` to the `main()` function.
- Update `main()` to be an `async` function to accommodate the asynchronous Sentry initialization.
- Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before `SentryFlutter.init`.
- Pass the Sentry initialization status or relevant logging service to the `AppInitializer` if necessary, or rely on the global Sentry state.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `architecture`: Update the application initialization flow to prioritize error reporting setup.

## Impact

- `lib/main.dart`: Significant refactoring of the `main()` function and `AppInitializer` state.
- Error Reporting: Improved visibility into early-stage application crashes.
- Startup Performance: Negligible impact, as Sentry initialization is lightweight.
