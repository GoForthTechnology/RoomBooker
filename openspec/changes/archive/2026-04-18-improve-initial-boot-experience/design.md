## Context

Currently, the application initialization sequence in `lib/main.dart` is fully blocking. It waits for `Firebase.initializeApp`, `FirebaseAppCheck.instance.activate`, and `SharedPreferences.getInstance()` before calling `runApp()`. On web platforms, these network-dependent operations cause a prolonged white screen. Furthermore, the PWA manifest doesn't align with the internal app styling, and some `CircularProgressIndicator` implementations may be stretching due to improper parent constraints.

## Goals / Non-Goals

**Goals:**
- Implement an immediate, zero-dependency HTML/CSS splash screen in `web/index.html`.
- Align PWA manifest colors and icons for a seamless "OS-to-App" transition.
- Standardize internal loading spinners to prevent stretching and ensure perfect centering.
- Optimize `main.dart` to minimize time-to-initial-render.

**Non-Goals:**
- Complex native splash screen configuration for Android/iOS (keeping focus on the reported Web/PWA issues).
- Redesigning the application's overall color palette or theme.

## Decisions

### 1. CSS-Only Splash Screen in `index.html`
- **Rationale**: CSS is rendered immediately by the browser without waiting for the Flutter engine or large JS bundles to load.
- **Implementation**: Inline a `<style>` block and a simple `<div>` structure containing a centered spinner and logo placeholder.
- **Alternative**: A secondary JavaScript-driven loader. Dismissed because it still depends on script execution which can be delayed.

### 2. Synchronization of Manifest and Splash Colors
- **Rationale**: Prevents a "color flash" when the PWA moves from the OS-level splash screen (defined in `manifest.json`) to the browser-level splash screen (defined in `index.html`).
- **Implementation**: Set `background_color` and `theme_color` in `web/manifest.json` to `#673ab7` (Deep Purple) to match the Flutter `ColorScheme.fromSeed` base.

### 3. Optimization of `main.dart` Boot Sequence
- **Rationale**: Moving heavy initializations to a state where the user already sees *some* Flutter-rendered UI reduces perceived latency.
- **Implementation**: Wrap the `MaterialApp` in a `FutureBuilder` or similar construct that handles the async initialization while showing a clean, centered spinner that matches the HTML splash screen.
- **Alternative**: Pre-initializing everything before `runApp`. Dismissed as it is the root cause of the current blank screen.

### 4. Constraint-Based Spinner Standardization
- **Rationale**: Centering a spinner inside a `Center` widget within a `Scaffold` should generally work, but parent constraints can sometimes cause stretching if not careful.
- **Implementation**: Ensure spinners are wrapped in a `SizedBox(width: 40, height: 40)` where appropriate, or verify that the parent provides correct alignment.

## Risks / Trade-offs

- **[Risk]** The transition from HTML splash to Flutter UI might feel abrupt if the centering is off by even a few pixels.
  - **Mitigation**: Use precise CSS Flexbox centering in `index.html` to match Flutter's `Center` widget layout exactly.
- **[Risk]** Reordering `main()` might lead to `No Firebase App` errors in downstream providers.
  - **Mitigation**: Use manual dependency injection or a robust loading state in `MyApp` to ensure providers are only initialized after their dependencies are ready.
