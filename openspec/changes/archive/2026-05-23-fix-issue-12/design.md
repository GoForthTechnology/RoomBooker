## Context

The Flutter web application currently exhibits a significant cold start delay. When a user first loads the PWA, `flutter_bootstrap.js` must fetch the Flutter engine, main Dart bundle, and initialize them. During this time, the default behavior is a blank white screen. This leads to user confusion and potentially high bounce rates, as documented in Issue #12.

## Goals / Non-Goals

**Goals:**
- Provide immediate visual feedback to the user upon loading the web app.
- Add a loading spinner and 'Room Booker' branding to the splash screen.
- Ensure the splash screen gracefully disappears once the Flutter app is ready and paints its first frame.
- Keep the implementation simple, contained within `web/index.html` and minimal CSS.

**Non-Goals:**
- Optimizing the actual Flutter engine load size or bundle size.
- Implementing a splash screen for iOS/Android (handled natively, out of scope for this web-specific issue).

## Decisions

**1. CSS-based Splash Screen in `index.html`**
We will add a simple HTML `div` with a loading spinner styled via inline or internal CSS within `index.html`. 
*Rationale:* This is the fastest way to render a loading indicator before any JavaScript is parsed or executed. It has zero dependencies.
*Alternative:* Modifying `flutter_bootstrap.js` to create DOM elements dynamically. *Rejected* because doing it in HTML is declarative, simpler, and renders marginally faster.

**2. Removal of Splash Screen**
Flutter's default `flutter_bootstrap.js` in modern versions handles attaching the Flutter app to the DOM and automatically replaces or covers the `div` if configured correctly, or we can add a small script to hide the loading indicator once the `_flutter.buildRunner` promise resolves.

## Risks / Trade-offs

- **Risk:** Splash screen styles might conflict with the main app layout momentarily.
  - **Mitigation:** Ensure the splash screen is absolutely positioned, covers the full viewport with a solid background, and has a high z-index.
- **Risk:** Unnecessary code complexity in `index.html`.
  - **Mitigation:** Keep the CSS and HTML for the spinner as minimal as possible.
- **Risk:** Splash screen logic breaking URL routing and Deep Links.
  - **Mitigation:** The implementation will not use any JavaScript to alter the `window.location` object, nor will it intercept navigation events. It will be a purely declarative UI element that fades out when the Flutter app is ready.

## Migration Plan

- Update `web/index.html`.
- Test locally using `flutter run -d chrome`.
- Deploy to web hosting (Firebase Hosting).
