## 1. Web & PWA Configuration

- [x] 1.1 Update `web/manifest.json` `background_color` and `theme_color` to `#673ab7`.
- [x] 1.2 Implement a CSS Flexbox-centered splash screen in `web/index.html`.
- [x] 1.3 Verify and update PWA icons and meta tags in `web/index.html`.

## 2. Boot Sequence Refactoring

- [x] 2.1 Create an `AppInitializer` widget in `lib/main.dart` to handle async dependencies.
- [x] 2.2 Modify `main()` to call `runApp()` immediately with the initializer.
- [x] 2.3 Implement a "Flutter-native" splash screen that visually matches the HTML splash screen.

## 3. UI Consistency & Spinner Fixes

- [x] 3.1 Audit `LandingScreenView` for stretched spinners and apply fixed constraints.
- [x] 3.2 Standardize spinner usage across `ViewBookingsScreen` and `OrgSettingsScreen`.
- [x] 3.3 Ensure `CircularProgressIndicator` is always wrapped in `SizedBox` or `Center` to prevent distortion.

## 4. Verification & Testing

- [x] 4.1 Perform a cold start on web and verify the HTML splash appears within 500ms.
- [x] 4.2 Verify the transition from HTML splash to Flutter UI is seamless.
- [x] 4.3 Test the PWA launch experience on mobile/desktop to ensure no white flashes occur.
