## Why

Specific details from Sentry trace the crash to a null check occurring during the initialization of the Google Sign-In SDK (part of the Google Identity Services). This points to unsafe null assertions in the authentication flow or app initialization. Several high-risk assertions (`snapshot.data!`) have been identified in core widgets (`OrgStateProvider`, `OrgSettingsScreen`, `AppInitializer`) that could trigger during race conditions or slow network responses on Web.

## What Changes

- Fix unsafe `snapshot.data!` usage in `lib/main.dart`, `lib/ui/widgets/org_state_provider.dart`, and `lib/ui/screens/org_settings/org_settings_screen.dart`.
- Update `lib/auth.dart` to safely handle potential null values in authentication state change actions.
- Ensure `GoogleProvider` is initialized with a verified Client ID and check for null safety in the provider configuration.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `ui-ux`: Enhance stability during core application and authentication initialization.

## Impact

This change will prevent intermittent crashes during app startup and login, particularly on the Web platform. It addresses the specific `m.google.accounts.id.initialize` crash reported by Sentry.
