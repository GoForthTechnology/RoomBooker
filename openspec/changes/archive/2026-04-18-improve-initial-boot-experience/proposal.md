## Why

The application currently suffers from a poor initial loading experience, particularly on web and when running as a PWA. Users encounter a prolonged white/blank screen while the app initializes (Firebase, SharedPreferences, etc.), and the subsequent loading spinner is reported to appear stretched or visually inconsistent. This negatively impacts user retention and the perceived quality of the application.

## What Changes

- **Web Splash Screen**: Implement a lightweight CSS/HTML splash screen in `web/index.html` that displays immediately upon page load.
- **Initialization Optimization**: Refactor `lib/main.dart` to move heavy async initializations to a state where a loading UI is already visible, or optimize the sequence to minimize time-to-first-frame.
- **Spinner Refinement**: Audit and fix the "stretched spinner" issue in `LandingScreen` and other initial views to ensure it follows Material Design standards and remains centered.
- **PWA Branding**: Enhance `web/manifest.json` and meta tags to ensure a smooth transition from the OS splash screen to the web app splash screen.

## Capabilities

### New Capabilities
- `boot-performance`: Defines requirements for app initialization speed and visual feedback during the boot process.

### Modified Capabilities
- `architecture`: Update to include constraints on the initialization sequence and splash screen implementation.

## Impact

- `web/index.html`: Addition of splash screen styles and HTML.
- `lib/main.dart`: Changes to the `main()` function and `MyApp` initialization.
- `lib/ui/screens/landing/landing.dart`: Adjustments to the redirect loading state.
- `web/manifest.json`: Potential updates for better PWA splash integration.
