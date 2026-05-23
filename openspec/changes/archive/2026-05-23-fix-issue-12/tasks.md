## 1. Web Startup UI Implementation

- [x] 1.1 Update `web/index.html` to include a loading spinner and 'Room Booker' branding using inline CSS and HTML.
- [x] 1.2 Ensure the splash screen styling makes it full screen, absolutely positioned, and covers any other elements.

## 2. Bootstrapping Integration

- [x] 2.1 Verify that `flutter_bootstrap.js` automatically hides or removes the splash screen once Flutter starts (or add logic if necessary).

## 3. Testing and Validation

- [x] 3.1 Run `flutter run -d chrome` to verify the splash screen appears immediately.
- [x] 3.2 Ensure the splash screen gracefully transitions to the application without flashing or lingering.
- [x] 3.3 Verify that navigating to a deep link correctly loads the specific page after the splash screen finishes.
