## Context

The application currently initializes Sentry asynchronously within the `AppInitializer` widget's `_initialize` method. This method also handles Firebase initialization and other setup tasks. If any of these early steps fail, Sentry may not be active yet, leading to unhandled and unlogged crashes.

## Goals / Non-Goals

**Goals:**
- Move Sentry initialization to the highest possible point in the app's entry point (`main()`).
- Ensure all startup errors (including Firebase and Google SDK initialization) are captured by Sentry.
- Simplify the `AppInitializer` logic by removing Sentry configuration from its flow.

**Non-Goals:**
- Changing Sentry options or DSN.
- Refactoring Firebase initialization (it remains inside `AppInitializer` but will now be covered by Sentry).

## Decisions

### 1. Async `main()` and `SentryFlutter.init`
- **Decision:** Change `void main()` to `Future<void> main()` and await `SentryFlutter.init`.
- **Rationale:** Sentry needs to be ready before any other part of the app starts. Initializing it in `main()` ensures it's the first thing set up after the basic Flutter binding.

### 2. Retain Firebase in `AppInitializer`
- **Decision:** Keep `Firebase.initializeApp` inside the `AppInitializer`'s `_initialize` method.
- **Rationale:** Firebase initialization depends on `DefaultFirebaseOptions` and typically takes longer. By keeping it in `AppInitializer`, we can continue to show the "Native-like splash screen" to the user while Firebase connects. Sentry will already be active and will catch any errors thrown during this Firebase setup.

### 3. Handle `kDebugMode` globally
- **Decision:** Move the `kDebugMode` check for Sentry initialization into `main()`.
- **Rationale:** Consistency. If we aren't using Sentry in debug mode, we should decide that at the entry point.

## Risks / Trade-offs

- **[Risk]** Delayed startup if `SentryFlutter.init` hangs → **Mitigation:** Sentry initialization is designed to be fast and non-blocking for the main event loop once the SDK is loaded. We will keep it awaited to ensure safety.
- **[Risk]** Redundant logging initialization → **Mitigation:** We will ensure `getLoggingService()` correctly returns the `SentryLoggingService` now that Sentry is guaranteed to be initialized.
