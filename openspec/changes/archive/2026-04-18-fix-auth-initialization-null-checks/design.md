## Context

The Sentry report pinpointed a crash during Google Sign-In initialization. This often happens if the `GoogleProvider` is misconfigured or if null values are asserted during the rapid state changes of authentication.

## Goals / Non-Goals

**Goals:**
- Eliminate `snapshot.data!` in `AppInitializer`.
- Eliminate `snapshot.data!` in `OrgStateProvider`.
- Eliminate `snapshot.data!` in `OrgSettingsScreen`.
- Add safe checks in `lib/auth.dart`.

## Decisions

### Safe Capture of Snapshot Data
Instead of `snapshot.data!`, we will use the "capture and check" pattern:
```dart
final data = snapshot.data;
if (data == null) return ...; // or error widget
```

### Safe Auth State Handling
In `lib/auth.dart`, we will explicitly check for `state.user != null` and `state.credential.user != null` before asserting or using them.

## Risks / Trade-offs

- **[Risk]** Blank screens → **Mitigation:** We will ensure appropriate loading or error states are shown if data is missing, rather than allowing the app to crash.
