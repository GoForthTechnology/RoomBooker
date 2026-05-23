## Why

Cold loading the PWA currently hangs on a white screen for a significant amount of time before the Flutter engine starts. This leads to a poor user experience as users have no indication that the app is loading. This change addresses issue #12 by adding a loading indicator during the initial boot phase.

## What Changes

- Add a loading spinner and/or a splash screen to `web/index.html`.
- Use CSS and simple HTML to ensure the loading indicator renders immediately before `flutter_bootstrap.js` completes.
- Ensure the splash screen is hidden or replaced once the Flutter app initializes.

## Capabilities

### New Capabilities
- `pwa-startup`: Defines the expected behavior during the web application's cold start phase, including visual feedback.

### Modified Capabilities
- (None)

## Impact

- `web/index.html`: Will be modified to include the splash screen HTML and CSS.
